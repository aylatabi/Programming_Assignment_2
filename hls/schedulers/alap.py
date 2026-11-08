"""Fritz: unconstrained as-late-as-possible scheduling under a latency bound.

Cycles are 1-based; each operation occupies one cycle. With no explicit
latency bound, ALAP uses the critical-path length.
"""
from __future__ import annotations
from ..dag import DAG
from ..schedule import Limits, Schedule


def schedule(dag: DAG, limits: Limits | None = None, latency: int | None = None) -> Schedule:
    if limits:
        raise ValueError('ALAP is unconstrained; use cons-alap for resource limits')
    base = dag.critical_path_length()
    if latency is None:
        latency = base
    if latency < base:
        raise ValueError(f'ALAP latency bound {latency} is smaller than critical path {base}')
    cycle_of: dict[int, int] = {}
    for idx in dag.reverse_topological_order():
        succs = dag.nodes[idx].succs
        cycle_of[idx] = min((cycle_of[s] - 1 for s in succs), default=latency)
    return Schedule('alap', dag, cycle_of, latency_bound=latency)
