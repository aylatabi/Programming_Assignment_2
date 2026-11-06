"""ASAP scheduler: every operation runs in the earliest cycle after all the
operations it depends on. No resource limits, so latency = critical path.

Template for the other schedulers: take the DAG (+ limits / latency),
decide a cycle for each node id, return a Schedule.
"""

from __future__ import annotations

from ..dag import DAG
from ..schedule import Limits, Schedule


def schedule(dag: DAG, limits: Limits | None = None, latency: int | None = None) -> Schedule:
    if limits:
        raise ValueError("ASAP is unconstrained; use cons-asap for resource limits")
    if latency is not None:
        raise ValueError("ASAP does not take a latency bound")

    cycle_of: dict[int, int] = {}
    for n in dag.topological_order():
        # Predecessors come earlier in topological order, so they are already placed.
        preds = dag.nodes[n].preds
        cycle_of[n] = 1 + max((cycle_of[p] for p in preds), default=0)

    return Schedule(mode="asap", dag=dag, cycle_of=cycle_of)
