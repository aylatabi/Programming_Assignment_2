"""Data-flow DAG of an SSA program (Part 3).

One node per SSA statement (= one arithmetic operation). An edge u -> v
means v reads the value that u produces. Input variables and constants are
leaves: they are not operation nodes and have no node id; they appear only
as operands.

Node ids are 0, 1, 2, ... in program order. SSA guarantees every value is
defined before it is used, so program order is already a topological order:
every edge goes from a lower id to a higher id.

Schedulers walk the graph with:
    dag.nodes                     all nodes, in topological order
    node.preds / node.succs       ids of the nodes it depends on / that depend on it
    dag.topological_order()       ids, sources first        (ASAP)
    dag.reverse_topological_order() ids, sinks first        (ALAP)
    dag.asap_levels()             earliest cycle of each node, unconstrained
    dag.critical_path_length()    minimum number of cycles

Main entry point: build_dag(ssa_program) -> DAG
"""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum

from .parser import Const, Op, Operand, Var
from .ssa import SSAProgram


class Unit(Enum):
    """Kind of functional unit an operation needs."""

    ADDER = "adder"
    SUBTRACTOR = "subtractor"
    MULTIPLIER = "multiplier"


UNIT_FOR_OP = {Op.ADD: Unit.ADDER, Op.SUB: Unit.SUBTRACTOR, Op.MUL: Unit.MULTIPLIER}


@dataclass
class Node:
    """One operation: name = left op right.

    id         -- index in DAG.nodes (topological order)
    name       -- the SSA value it produces, e.g. X_2
    unit       -- functional-unit kind it needs
    left/right -- operands: Var (SSA value or input name) or Const
    preds      -- ids of nodes whose results this node reads (no duplicates)
    succs      -- ids of nodes that read this node's result
    is_output  -- True if this is the final version of a variable
    line       -- source line of the original equation
    """

    id: int
    name: str
    op: Op
    unit: Unit
    left: Operand
    right: Operand
    line: int
    preds: list[int] = field(default_factory=list)
    succs: list[int] = field(default_factory=list)
    is_output: bool = False

    def __str__(self) -> str:
        return f"{self.name} = {self.left} {self.op.value} {self.right}"


@dataclass
class DAG:
    nodes: list[Node] = field(default_factory=list)
    inputs: list[str] = field(default_factory=list)   # leaf variables (unversioned)
    outputs: dict[str, str] = field(default_factory=dict)  # variable -> final SSA name
    by_name: dict[str, int] = field(default_factory=dict)  # SSA name -> node id

    # -- structure -----------------------------------------------------------

    def node(self, name_or_id: str | int) -> Node:
        if isinstance(name_or_id, int):
            return self.nodes[name_or_id]
        return self.nodes[self.by_name[name_or_id]]

    def edges(self) -> list[tuple[int, int]]:
        return [(p, n.id) for n in self.nodes for p in n.preds]

    def sources(self) -> list[int]:
        """Nodes that read only inputs and constants."""
        return [n.id for n in self.nodes if not n.preds]

    def sinks(self) -> list[int]:
        """Nodes whose result no other node reads."""
        return [n.id for n in self.nodes if not n.succs]

    def topological_order(self) -> list[int]:
        return [n.id for n in self.nodes]

    def reverse_topological_order(self) -> list[int]:
        return [n.id for n in reversed(self.nodes)]

    def count_by_unit(self) -> dict[Unit, int]:
        counts = {u: 0 for u in Unit}
        for n in self.nodes:
            counts[n.unit] += 1
        return counts

    # -- timing (every operation takes one cycle) ----------------------------

    def asap_levels(self) -> list[int]:
        """Earliest cycle of each node, starting at 1, with no resource limits."""
        level = [0] * len(self.nodes)
        for n in self.nodes:
            level[n.id] = 1 + max((level[p] for p in n.preds), default=0)
        return level

    def critical_path_length(self) -> int:
        """Length of the longest dependency chain = minimum number of cycles."""
        return max(self.asap_levels(), default=0)


def build_dag(program: SSAProgram) -> DAG:
    """Build the data-flow DAG of an SSA program."""
    dag = DAG(inputs=list(program.inputs), outputs=dict(program.outputs))
    final_names = set(program.outputs.values())

    for i, s in enumerate(program.statements):
        node = Node(
            id=i,
            name=s.dest,
            op=s.op,
            unit=UNIT_FOR_OP[s.op],
            left=s.left,
            right=s.right,
            line=s.line,
            is_output=s.dest in final_names,
        )
        for operand in (s.left, s.right):
            if isinstance(operand, Var) and operand.name in dag.by_name:
                pred = dag.by_name[operand.name]
                if pred not in node.preds:  # X_2 = X_1 * X_1 is one edge, not two
                    node.preds.append(pred)
                    dag.nodes[pred].succs.append(i)
            # Otherwise it is an input or a constant: a leaf, no edge.

        dag.by_name[s.dest] = i
        dag.nodes.append(node)

    return dag


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def _ids(ids: list[int]) -> str:
    return " ".join(f"n{i}" for i in ids) or "-"


def format_dag(dag: DAG, source_name: str | None = None) -> str:
    """Human-readable listing of the DAG."""
    counts = dag.count_by_unit()
    lines = [
        "# DAG" + (f" of {source_name}" if source_name else ""),
        f"# {len(dag.nodes)} operations ("
        + ", ".join(f"{counts[u]} {u.value}" for u in Unit)
        + f"), {len(dag.edges())} edges, critical path {dag.critical_path_length()} cycles",
        f"# leaves: inputs {' '.join(dag.inputs) or '(none)'}; constants are leaves too",
        "",
    ]
    width = max((len(str(n)) for n in dag.nodes), default=0)
    for n in dag.nodes:
        out = "  output" if n.is_output else ""
        lines.append(
            f"n{n.id:<3}{str(n):<{width}}   {n.unit.value:<10}  "
            f"preds: {_ids(n.preds):<10}  succs: {_ids(n.succs)}{out}"
        )
    return "\n".join(lines) + "\n"


def to_dot(dag: DAG, title: str = "dag") -> str:
    """Graphviz DOT text. View with:  dot -Tpng FILE.dot -o FILE.png
    (or paste into an online Graphviz viewer)."""
    symbol = {Op.ADD: "+", Op.SUB: "-", Op.MUL: "*"}
    out = [f'digraph "{title}" {{', "  rankdir=TB;", "  node [fontname=Helvetica];"]

    for name in dag.inputs:
        out.append(f'  "in_{name}" [label="{name}", shape=box, style=rounded];')

    consts: set[int] = set()
    for n in dag.nodes:
        label = f"{symbol[n.op]}\\n{n.name}"
        style = ", peripheries=2" if n.is_output else ""
        out.append(f'  n{n.id} [label="{label}", shape=circle{style}];')
        for operand in (n.left, n.right):
            if isinstance(operand, Const):
                consts.add(operand.value)
                src = f'"const_{operand.value}"'
            elif operand.name in dag.by_name:
                src = f"n{dag.by_name[operand.name]}"
            else:
                src = f'"in_{operand.name}"'
            out.append(f"  {src} -> n{n.id};")

    for value in sorted(consts):
        out.append(f'  "const_{value}" [label="{value}", shape=plaintext];')

    out.append("}")
    return "\n".join(out) + "\n"
