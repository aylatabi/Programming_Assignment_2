"""The schedule format shared by every scheduler (Part 3).

A schedule says WHEN each operation runs, nothing more. Which physical
adder/subtractor/multiplier runs it (binding) is a separate later step.

Contract for every scheduler (see hls/schedulers/):

    def schedule(dag: DAG, limits: Limits | None = None,
                 latency: int | None = None) -> Schedule

    - limits:  max units of each kind per cycle, e.g. {Unit.ADDER: 1}.
               A kind that is missing is unlimited.
    - latency: a cycle bound (used by ALAP); None means "critical path".
    - Cycles are numbered from 1. Cycle 0 is reserved for loading inputs.
    - Every operation takes one cycle.
    - Run validate() on the result; it must return no problems.

Output:
    format_schedule(s)   table for the terminal, one row per cycle
    schedule_to_json(s)  dict for --export-schedule (json.dumps it)
"""

from __future__ import annotations

from dataclasses import dataclass, field

from .dag import DAG, Unit

Limits = dict[Unit, int]


@dataclass
class Schedule:
    mode: str                      # "asap", "alap", "cons-asap", "cons-alap", "custom"
    dag: DAG
    cycle_of: dict[int, int]       # node id -> cycle (1-based)
    limits: Limits = field(default_factory=dict)  # limits the scheduler was given
    latency_bound: int | None = None              # bound the scheduler was given, if any

    @property
    def latency(self) -> int:
        """Number of cycles the schedule takes."""
        return max(self.cycle_of.values(), default=0)

    def nodes_in_cycle(self, cycle: int) -> list[int]:
        return [n for n, c in sorted(self.cycle_of.items()) if c == cycle]

    def by_cycle(self) -> dict[int, list[int]]:
        """cycle -> node ids, for every cycle 1..latency (empty cycles included)."""
        return {c: self.nodes_in_cycle(c) for c in range(1, self.latency + 1)}

    def units_in_cycle(self, cycle: int) -> dict[Unit, int]:
        counts = {u: 0 for u in Unit}
        for n in self.nodes_in_cycle(cycle):
            counts[self.dag.nodes[n].unit] += 1
        return counts

    def units_needed(self) -> dict[Unit, int]:
        """Peak number of each unit kind used in any one cycle.
        This is how many of each unit the datapath must instantiate."""
        peak = {u: 0 for u in Unit}
        for c in range(1, self.latency + 1):
            for u, k in self.units_in_cycle(c).items():
                peak[u] = max(peak[u], k)
        return peak


def validate(s: Schedule) -> list[str]:
    """Check a schedule against its DAG. Returns a list of problems (empty = valid)."""
    problems: list[str] = []
    dag = s.dag

    for node in dag.nodes:
        if node.id not in s.cycle_of:
            problems.append(f"n{node.id} ({node.name}) is not scheduled")
    for n, c in s.cycle_of.items():
        if not 0 <= n < len(dag.nodes):
            problems.append(f"schedule has unknown node n{n}")
        elif c < 1:
            problems.append(f"n{n} ({dag.nodes[n].name}) is in cycle {c}; cycles start at 1")
    if problems:
        return problems

    for node in dag.nodes:
        for p in node.preds:
            if s.cycle_of[p] >= s.cycle_of[node.id]:
                problems.append(
                    f"n{node.id} ({node.name}) in cycle {s.cycle_of[node.id]} needs "
                    f"n{p} ({dag.nodes[p].name}), which is in cycle {s.cycle_of[p]}"
                )

    for c in range(1, s.latency + 1):
        for unit, used in s.units_in_cycle(c).items():
            limit = s.limits.get(unit)
            if limit is not None and used > limit:
                problems.append(f"cycle {c} uses {used} {unit.value}(s), limit is {limit}")

    if s.latency_bound is not None and s.latency > s.latency_bound:
        problems.append(f"schedule takes {s.latency} cycles, bound is {s.latency_bound}")

    return problems


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def _limits_text(limits: Limits) -> str:
    if not limits:
        return "none"
    return ", ".join(f"{k} {u.value}" for u, k in limits.items())


def format_schedule(s: Schedule, source_name: str | None = None) -> str:
    """Terminal table, one row per cycle."""
    needed = s.units_needed()
    lines = [
        f"# {s.mode.upper()} schedule" + (f" of {source_name}" if source_name else ""),
        f"# latency {s.latency} cycles; limits: {_limits_text(s.limits)}",
        "# units needed: " + ", ".join(f"{needed[u]} {u.value}" for u in Unit),
        "",
    ]
    for c, ids in s.by_cycle().items():
        ops = ",  ".join(f"n{i} {s.dag.nodes[i]}" for i in ids) or "(idle)"
        lines.append(f"cycle {c:>2}:  {ops}")
    return "\n".join(lines) + "\n"


def schedule_to_json(s: Schedule, source_name: str | None = None) -> dict:
    """JSON-ready dict. Self-contained: includes each operation's details."""
    dag = s.dag
    return {
        "source": source_name,
        "mode": s.mode,
        "latency": s.latency,
        "latency_bound": s.latency_bound,
        "limits": {u.value: k for u, k in s.limits.items()},
        "units_needed": {u.value: k for u, k in s.units_needed().items()},
        "inputs": dag.inputs,
        "outputs": dag.outputs,
        "operations": [
            {
                "node": n.id,
                "name": n.name,
                "op": n.op.value,
                "unit": n.unit.value,
                "left": str(n.left),
                "right": str(n.right),
                "preds": n.preds,
                "cycle": s.cycle_of[n.id],
                "is_output": n.is_output,
                "line": n.line,
            }
            for n in dag.nodes
        ],
        "cycles": {str(c): [dag.nodes[i].name for i in ids] for c, ids in s.by_cycle().items()},
    }
