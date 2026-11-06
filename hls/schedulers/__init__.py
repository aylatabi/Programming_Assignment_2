"""All schedulers, by mode name. Each one follows the contract in hls/schedule.py:

    schedule(dag, limits=None, latency=None) -> Schedule

To add a scheduler: create hls/schedulers/<name>.py with a schedule()
function, import it here and add it to SCHEDULERS.
"""

from . import asap

SCHEDULERS = {
    "asap": asap.schedule,
    # "cons-asap": cons_asap.schedule,   # Ayla, Stage 2
    # "alap": alap.schedule,             # Fritz, Stage 2
    # "cons-alap": cons_alap.schedule,   # Fritz, Stage 2
    # "custom": custom.schedule,         # Fritz, Stage 2
}

ALL_MODES = ["asap", "cons-asap", "alap", "cons-alap", "custom"]
