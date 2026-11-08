# EC551 PA2 — combined-team demo plan (maximum 30 minutes)

**Prepared for integration; not a claim of completed board testing.** Ayla must connect a working board wrapper and real XDC. Keep all test inputs nonnegative and within chosen `WIDTH`.

| Time | Demonstration | Responsible | Objective evidence |
|---|---|---|---|
| 0–3 min | Architecture, 1-based DAG scheduling and 0-based hardware steps | Both | Show code map and pipeline |
| 3–7 min | Parser, validation errors, SSA export, DAG | Ayla | `--export-ssa`, `--export-dag`, console |
| 7–11 min | All five schedules; resource limits/dependencies | Both | JSON and `validate()`; Ayla must supply `cons-asap` |
| 11–14 min | Binding JSON, one reused adder, muxes, registers | Fritz | `binding.json`, `generated_datapath.v` |
| 14–17 min | Generated FSM, FU blocks, step/pause and self-checking HDL simulation | Both | `generated_system.v`, Icarus PASS **after actually run** |
| 17–20 min | Professor-directed live run #1: simple arithmetic, inputs/outputs | Both | User-provided equations, rebuild, board output |
| 20–23 min | Professor-directed live run #2: contention, limited adders | Both | Hardware stepping and resource selection |
| 23–26 min | Professor-directed live run #3: reassignment and SSA | Both | Correct final versions, outputs |
| 26–28 min | Rebuild / reprogram flow, timing and utilization | Both | Vivado bitstream + reports **after actual build** |
| 28–30 min | Questions / contingency | Both | Explain limitations and design tradeoffs |

**Note:** Depending on Vivado synthesis/programming time, preparing bitstreams for arbitrary professor-generated equations within three minutes may be difficult. Rehearse rebuild/reprogram timing and prepare an agreed demonstration mechanism with Professor Densmore. Do not substitute precompiled examples if live custom input is required without the professor's approval.

### Three reproducible sample inputs

1. `examples/fritz/professor_run_1.txt` with A=3,B=2: X=5, Y=8, Z=3, Q=6.
2. `examples/fritz/parallel_adders.txt` with A=2,B=3,C=4,D=5: X=5, Y=9, Z=14, Q=12. Compare ASAP (2 adders, 3 cycles) versus constrained ALAP (1 adder, 4 cycles).
3. `examples/fritz/reassignment.txt` with B=2,C=3,D=4,E=2: A=9, P=18, R=15.

For each live case: collect equations, validate, export SSA, graph, select schedule, emit RTL, run simulator, build/program, set board inputs, pulse start then step through cycles, select observed FU and final output, compare against independent calculator. Hardware steps require real board integration and testing.
