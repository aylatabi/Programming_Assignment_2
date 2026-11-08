"""Constrained ASAP scheduler (list scheduling).

Walk cycles 1, 2, 3, ... In each cycle, an operation is ready when every
operation it depends on finished in an earlier cycle. Ready operations are
placed as early as possible, most urgent first (longest path to the end of
the DAG, then statement order), until that unit kind reaches its limit.
Anything that does not fit waits for the next cycle.

A unit kind with no limit given is unlimited, so with no limits at all this
gives the same result as plain ASAP.
"""

from __future__ import annotations

from collections import Counter

from ..dag import DAG
from ..schedule import Limits, Schedule


def schedule(dag: DAG, limits: Limits | None = None, latency: int | None = None) -> Schedule:
    if not limits:
        raise ValueError("cons-asap needs at least one --adders/--subs/--muls resource limit")
    if any(type(k) is not int or k < 1 for k in limits.values()):
        raise ValueError("resource limits must be positive integers")

    # Priority: length of the longest path from this node to the end of the DAG.
    tail: dict[int, int] = {}
    for n in dag.reverse_topological_order():
        tail[n] = 1 + max((tail[s] for s in dag.nodes[n].succs), default=0)

    cycle_of: dict[int, int] = {}
    waiting = set(range(len(dag.nodes)))
    cycle = 0
    while waiting:
        cycle += 1
        ready = [
            n for n in waiting
            if all(p in cycle_of and cycle_of[p] < cycle for p in dag.nodes[n].preds)
        ]
        ready.sort(key=lambda n: (-tail[n], n))
        used: Counter = Counter()
        for n in ready:
            unit = dag.nodes[n].unit
            limit = limits.get(unit)
            if limit is None or used[unit] < limit:
                cycle_of[n] = cycle
                used[unit] += 1
        waiting.difference_update(cycle_of)

    s = Schedule(mode="cons-asap", dag=dag, cycle_of=cycle_of,
                 limits=dict(limits), latency_bound=latency)
    if latency is not None and s.latency > latency:
        raise ValueError(f"cons-asap schedule needs {s.latency} cycles, bound is {latency}")
    return s
