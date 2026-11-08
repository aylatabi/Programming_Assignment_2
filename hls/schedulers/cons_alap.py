"""Fritz: exact reverse topological constrained ALAP (bounded backtracking).

For a specified latency, search for a valid schedule and prefer the latest
feasible cycle for each operation. Without a latency, find the minimum feasible
horizon and place operations late within that horizon. Missing resource types
are unconstrained. 20-statement input limit bounds typical search sizes; a
finite node-expansion guard prevents silently hanging on pathological cases.
"""
from __future__ import annotations
from collections import Counter, defaultdict
from math import ceil
from ..dag import DAG, Unit
from ..schedule import Limits, Schedule

SEARCH_STATES = 1_000_000


def schedule(dag: DAG, limits: Limits | None = None, latency: int | None = None) -> Schedule:
    if not limits:
        raise ValueError('cons-alap needs at least one --adders/--subs/--muls resource limit')
    if any(type(n) is not int or n < 1 for n in limits.values()):
        raise ValueError('resource limits must be positive integers')
    n = len(dag.nodes)
    cp = dag.critical_path_length()
    if latency is not None and latency < cp:
        raise ValueError(f'latency bound {latency} is smaller than critical path {cp}')
    if n == 0:
        return Schedule('cons-alap', dag, {}, dict(limits), latency_bound=latency)
    capacity = {u: limits.get(u, max(1, dag.count_by_unit()[u])) for u in Unit}
    asap = dag.asap_levels()
    order = dag.reverse_topological_order()
    # Capacity lower bound avoids exploring obviously impossible horizons.
    counts = dag.count_by_unit()
    lower = max([cp, *[ceil(counts[u] / capacity[u]) for u in Unit]])
    if latency is not None and latency < lower:
        raise ValueError(f'no feasible constrained ALAP schedule within {latency} cycles (resource lower bound {lower})')
    horizons = [latency] if latency is not None else range(lower, n + 1)
    expansions = [0]

    for horizon in horizons:
        result: dict[int, int] = {}
        occupation: dict[int, Counter] = defaultdict(Counter)

        def place(i: int) -> bool:
            expansions[0] += 1
            if expansions[0] > SEARCH_STATES:
                raise RuntimeError('constrained ALAP search limit reached; try a tighter --latency or a simpler DAG')
            if i == len(order):
                return True
            idx = order[i]
            node = dag.nodes[idx]
            latest = min((result[s] - 1 for s in node.succs), default=horizon)
            earliest = asap[idx]
            for cycle in range(latest, earliest - 1, -1):
                if occupation[cycle][node.unit] >= capacity[node.unit]:
                    continue
                result[idx] = cycle
                occupation[cycle][node.unit] += 1
                if place(i + 1):
                    return True
                occupation[cycle][node.unit] -= 1
                del result[idx]
            return False

        if place(0):
            return Schedule('cons-alap', dag, result, dict(limits), latency_bound=latency)
    raise ValueError(f'no feasible constrained ALAP schedule within {latency} cycles')
