"""Fritz: critical-path-priority, resource-aware ready-list scheduler.

Heuristic: schedule ready operations by longest remaining path, then fanout,
then original statement order. By default cap each active unit type to one,
so a small shared datapath is favored over unconstrained parallelism.
No claim of globally optimal scheduling is made.
"""
from __future__ import annotations
from collections import Counter
from ..dag import DAG, Unit
from ..schedule import Limits, Schedule


def schedule(dag: DAG, limits: Limits | None = None, latency: int | None = None) -> Schedule:
    given = dict(limits or {})
    if any(type(n) is not int or n < 1 for n in given.values()):
        raise ValueError('resource limits must be positive integers')
    default_limits = {u: 1 for u in Unit if dag.count_by_unit()[u]}
    cap = {**default_limits, **given}
    tail = {}
    for idx in dag.reverse_topological_order():
        tail[idx] = 1 + max((tail[s] for s in dag.nodes[idx].succs), default=0)
    unscheduled = set(dag.topological_order())
    cycle_of: dict[int, int] = {}
    cycle = 1
    while unscheduled:
        ready = [i for i in unscheduled if all(p in cycle_of and cycle_of[p] < cycle for p in dag.nodes[i].preds)]
        ready.sort(key=lambda i: (-tail[i], -len(dag.nodes[i].succs), i))
        usage = Counter()
        selected = []
        for i in ready:
            unit = dag.nodes[i].unit
            if usage[unit] < cap[unit]:
                cycle_of[i] = cycle
                selected.append(i)
                usage[unit] += 1
        if not selected:
            raise RuntimeError('custom scheduler made no progress')
        unscheduled.difference_update(selected)
        cycle += 1
    if latency is not None and cycle - 1 > latency:
        raise ValueError(f'custom schedule needs {cycle - 1} cycles, bound is {latency}')
    return Schedule('custom', dag, cycle_of, cap, latency_bound=latency)
