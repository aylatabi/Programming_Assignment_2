# Fritz's EC551 PA2 backend: architecture and integration contract

This document refers to the source in this repository (the extracted `fritz-pa2` branch), not the separate prototype ZIP. It adds Fritz's assignments while preserving Ayla's existing parser, SSA, DAG and ASAP scheduler.

## Ownership and file map

| Requirement | Implementation | Test / evidence |
|---|---|---|
| Part 3: ALAP | `hls/schedulers/alap.py` | `tests/fritz/test_fritz_backend.py` |
| Part 3: constrained ALAP | `hls/schedulers/cons_alap.py` | Exhaustive small-graph feasibility comparisons |
| Part 3: custom | `hls/schedulers/custom.py` | Critical-path priority / resource-limit tests |
| Part 4: resource binding | `hls/fritz_impl/binding.py` + `hls/fritz_bridge.py` | `binding.json` in generated example |
| Part 4: mux/register generator | `hls/fritz_impl/verilog.py` | `generated_datapath.v` in examples |
| Part 6: generated system RTL | `hls/fritz_impl/verilog.py`, `rtl/functional_units.v` | `generated_system.v`, `testbench.v` |
| Part 7: build/program script | `scripts/build_and_program.py` | `--dry-run` TCL generation; Vivado/FPGA NOT locally verified |

Ayla-owned, **not implemented here**: `cons-asap`, final board wrapper and XDC constraints, integration of teammate-specific FSM and Part 5 arithmetic blocks.

## Pipeline, actual call flow

1. `hls/__main__.py` enters `hls/cli.py`.
2. `hls/parser.py` reads a text file and validates equations; `hls/ssa.py` renames repeated assignments.
3. `hls/dag.py` creates one operation node per SSA statement; `preds`/`succs` represent dependencies.
4. `hls/schedulers/<mode>.py` returns `hls.schedule.Schedule` with **1-based cycle indices**. `hls.schedule.validate` independently checks dependencies, limits, and latency bound.
5. With `--emit-rtl`, `hls/fritz_bridge.py` translates the shared DAG into an internal RTL representation (`hls/fritz_impl/ir.py`) and shifts schedule cycles to **0-based step indices**. This is an adapter, NOT a competing parser.
6. `hls/fritz_impl/binding.py` assigns each scheduled operation to one physical FU of the same type, reusing a unit on different cycles. The peak simultaneous count becomes the exact instance count. JSON describes each unit, mux selection per cycle, and result-register write cycle.
7. `hls/fritz_impl/verilog.py` emits `generated_datapath.v` (operand muxes, FU instances, SSA result registers, write enables) and `generated_system.v` (input latches, `busy`, `done`, step counter, `start`, `step_enable`). It also exposes one port per actual FU for Ayla's output-selection display.
8. `hls/fritz_impl/sim.py` supplies a Python reference evaluator and generates `testbench.v`, with deterministic test stimuli, predicted outputs and checks for paused stepping.
9. `scripts/build_and_program.py` first calls **the shared HLS CLI** to regenerate the design, then writes a Vivado batch TCL build/program sequence. Requires Ayla's real board wrapper and board-specific XDC. It does not guess pin mappings.

## Timing and hardware semantics

- The source schedule uses cycles **1, 2, 3, ...**; hardware `step` uses **0, 1, 2, ...**.
- All add/sub/mul operations are modeled as **combinational one-cycle functional units**, with results written into an SSA result register **on the active clock edge** of their scheduled cycle. No same-cycle data forwarding is allowed.
- The datapath uses unsigned arithmetic **modulo `2^WIDTH`** (truncates on overflow; subtraction wraps if a negative result is attempted). Use nonnegative in-range examples to comply with the assignment's testing assumption.
- `start` samples all primary inputs into internal input registers. `busy=1` indicates active schedule; `step_enable` is a **one-clock synchronous pulse** that advances by exactly one scheduled cycle. The board wrapper must synchronize and debounce mechanical buttons, or single presses may cause multiple steps.
- `done` asserts when the final step is taken; `busy` then deasserts. Outputs remain registered until overwritten by a later run. FU output ports show current mux results, not necessarily the final stored output.
- This implementation provides a **generated reference FSM**. If Ayla generates a different FSM, replace or adapt the controller while keeping the `step`/`write_en` datapath contract.

## Algorithms and what they guarantee

**ALAP:** determine the graph's critical-path length, select requested bound or the critical-path length, then walk the DAG from sinks to sources and place each op in the latest cycle before every successor. With a loose bound, idle cycles may appear earlier; this is expected.

**Constrained ALAP:** resource-capacity-aware reverse-topological backtracking, preferring later cycles. If no bound is given, search horizons from the critical path upward to find the **minimum feasible horizon** (subject to an explicit expansion limit of 1,000,000 search states). If a bound is supplied, either find a valid schedule or return a clear infeasibility/search-limit error. This is exact *if it finishes without hitting the search guard*.

**Custom:** forward ready-list scheduling prioritized by remaining critical path, then successor fanout, then node ID, subject to capacities. The default is one of each used unit type, favoring sharing. It guarantees a valid schedule, **not globally optimal latency**.

## Run examples (PowerShell, repository root)

```powershell
python -m hls examples/fritz/professor_run_1.txt --schedule alap --emit-rtl --export-ssa --test-values A=3,B=2
python -m hls examples/fritz/parallel_adders.txt --schedule cons-alap --adders 1 --subs 1 --muls 1 --emit-rtl --test-values A=2,B=3,C=4,D=5
python -m hls examples/fritz/reassignment.txt --schedule custom --emit-rtl --test-values B=2,C=3,D=4,E=2
python -m unittest discover -s tests/fritz -v
python scripts/simulate_rtl.py out/parallel_adders_cons-alap_rtl
```

Last command requires Icarus Verilog installed; it is a separate required verification step, not a Python-level check.

## Ayla's integration tasks

1. Add/import Ayla's `cons-asap` scheduler into `hls/schedulers/__init__.py` (the placeholder remains commented on purpose).
2. Decide whether her FSM generator replaces Fritz's reference controller. Either way, preserve the active-cycle `step` and `write_en` handshake to the generated datapath.
3. Use her actual `pa2_add/pa2_sub/pa2_mul` equivalents or ensure names/interfaces match the included `rtl/functional_units.v`. Do not compile duplicate module definitions.
4. Connect `generated_system` inputs, outputs, `start`, `step_enable`, `busy`, `done`, and selected `fu_*_out` port(s) in her top-level FPGA wrapper.
5. Connect a debounced one-cycle pulse to `step_enable`. Use switches for chosen primary inputs; hardcode any others for demonstration if necessary. Add a unit-output selector and display encoding using the actual board's resources.
6. Provide real FPGA `.xdc`, part number and `--top` before running the build/program script.
7. Run Icarus simulation, Vivado synthesis/implementation, program the board, and demonstrate three on-demand professor equation runs. The user must **not claim physical verification** until those actions are completed.

## Controlling scope

The professor's Rev 2.0 requires an integrated HLS-to-FPGA system; this branch delivers Fritz's assigned backend, but it does not independently satisfy Ayla's assigned components or hardware demonstration.
