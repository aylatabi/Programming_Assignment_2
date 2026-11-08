"""Scheduler registration for the shared HLS CLI.

Ayla: asap and cons-asap (cons-asap remains her integration responsibility).
Fritz: alap, cons-alap, custom. Each accepts the shared DAG and returns the
1-based Schedule defined in hls.schedule.
"""
from . import asap, alap, cons_alap, custom

SCHEDULERS = {
    'asap': asap.schedule,
    # 'cons-asap': cons_asap.schedule,   # Ayla's module, to be integrated later
    'alap': alap.schedule,
    'cons-alap': cons_alap.schedule,
    'custom': custom.schedule,
}
ALL_MODES = ['asap', 'cons-asap', 'alap', 'cons-alap', 'custom']
