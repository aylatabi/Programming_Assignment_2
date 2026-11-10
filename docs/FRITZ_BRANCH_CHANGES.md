# Fritz backend overlay — merge notes (historical)

> Historical: these notes were written before `fritz-pa2` was merged into `main`. The merge is done; see the [README](../README.md) for the current state.

The update ZIP is a **file overlay**, not a replacement or new Git repository. It is created against the user-uploaded `Programming_Assignment_2-fritz-pa2.zip` snapshot.

## Original files touched (minimal)

1. `hls/cli.py`: adds `--emit-rtl`, `--export-binding`, `--width`, `--test-values`, and invokes the backend after validating schedules; existing parsing, SSA, DAG and plain ASAP workflow remains unchanged.
2. `hls/schedulers/__init__.py`: registers Fritz's `alap`, `cons-alap`, `custom`. Leaves Ayla's `cons-asap` slot intentionally unimplemented for her to fill.
3. `.gitignore`: excludes transient generated `out/`, Vivado and simulation artifacts; committed examples under `examples/fritz/generated` remain tracked.

**No changes** to Ayla's `hls/parser.py`, `hls/ssa.py`, `hls/dag.py`, `hls/schedule.py`, or `hls/schedulers/asap.py`.

## New files or directories

- `README.md`
- `hls/schedulers/alap.py`, `cons_alap.py`, `custom.py`
- `hls/fritz_bridge.py`
- `hls/fritz_impl/` (validated internal IR, resource binder, RTL and testbench generator)
- `rtl/functional_units.v` reference FU implementations; reconcile with teammate's actual units
- `scripts/build_and_program.py` and `scripts/simulate_rtl.py`
- `tests/fritz/`
- `examples/fritz/` source equations, generated example RTL, schedule, binding JSON
- `docs/FRITZ_BACKEND.md`, `docs/DEMO_30_MINUTES.md`, this file and verification notes
- `.github/workflows/fritz-backend.yml` — proposed GitHub CI that installs Icarus and runs HDL simulations on the push; **not executed locally**.

## Merge guidance

Ayla should merge only after checking naming/interfaces of physical input/output ports, combinational FU timing and FPGA step control. Some source branches may have advanced beyond the snapshot; do not blindly overwrite her newer changes. Preserve her implementations for parser, SSA, DAG and constrained ASAP.
