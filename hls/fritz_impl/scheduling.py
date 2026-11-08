"""Minimal validation for the internal 0-based binding/RTL representation.

This is not a second scheduling implementation. The public scheduling interface
remains hls.schedule.Schedule (with cycles starting at 1).
"""
from collections import Counter
from .ir import Design


def latency(schedule: dict[str, int]) -> int:
    return max(schedule.values(), default=-1) + 1


def validate(d: Design, s: dict[str, int], resources=None, deadline=None):
    if set(s) != set(d.by_id):
        raise ValueError('missing or extra scheduled nodes')
    for name, deps in d.dependencies().items():
        t = s[name]
        if type(t) is not int or t < 0:
            raise ValueError(f'{name}: invalid cycle {t!r}')
        for dep in deps:
            if s[dep] >= t:
                raise ValueError(f'{name}: dependence on {dep} not respected')
    if resources:
        for t in set(s.values()):
            counts = Counter(d.by_id[n].op for n in s if s[n] == t)
            if any(counts[op] > limit for op, limit in resources.items()):
                raise ValueError(f'cycle {t}: resource count exceeded')
    if deadline is not None and latency(s) > deadline:
        raise ValueError('schedule exceeds latency bound')
    return True
