# EC551 PA2 — Hardware Synthesis (shared repository; Fritz branch)

**Status:** Ayla's compiler front end/ASAP plus Fritz's ALAP/constrained ALAP/custom scheduling, resource binding, mux/register datapath and generated system RTL are integrated at the Python CLI level. A dedicated FPGA board wrapper, its constraints, Ayla's constrained ASAP and confirmed Vivado/FPGA tests are still required for the full Rev 2.0 assignment.

## Architecture

```text
Arithmetic text file
  -> hls/parser.py            Ayla: validate equations
  -> hls/ssa.py               Ayla: single-assignment renaming
  -> hls/dag.py               Ayla: operation dependency DAG
  -> hls/schedulers/          Ayla: ASAP; Fritz: ALAP, cons-ALAP, custom
  -> hls/fritz_bridge.py      Fritz: translate shared schedule to hardware step indices
  -> hls/fritz_impl/binding.py Fritz: bind operations to reusable physical units
  -> hls/fritz_impl/verilog.py Fritz: muxes, result registers, and reference FSM
  -> generated Verilog + testbench
  -> scripts/build_and_program.py -> Vivado -> FPGA (requires team board files)
```

## Source layout

- `hls/`: existing shared parser/SSA/DAG/CLI plus Fritz's scheduler and backend additions.
- `rtl/functional_units.v`: standalone reference 8/16-bit parameterized arithmetic blocks; swap with Ayla's when integrated.
- `examples/fritz/`: 3 source programs and checked-in **generated sample RTL** under `generated/`.
- `tests/parser/`: Ayla's parser fixtures (left unchanged).
- `tests/fritz/`: scheduling, binding, generation, exhaustive and randomized tests.
- `scripts/simulate_rtl.py`: real Icarus compile and testbench runner.
- `scripts/build_and_program.py`: one-command shared compiler → Vivado build/program script, contingent on board wrapper/XDC.
- `docs/FRITZ_BACKEND.md`: algorithms, I/O contract, ownership, and code walkthrough.
- `docs/DEMO_30_MINUTES.md`: 30-minute joint demonstration plan and three tests.
- `docs/EC551_Program2_Rev2.pdf`: assignment specification provided by the team.

## Requirements

- Python 3.10+ for compiler and tests; no third-party Python packages required.
- Optional for HDL verification: Icarus Verilog (`iverilog` and `vvp`) in `PATH`.
- Required for actual FPGA: Vivado with the correct supported device, connected board, Ayla's wrapper (`.v`) and pin constraints (`.xdc`).

## Quick start (from repository root)

```powershell
python -m hls examples/fritz/professor_run_1.txt --export-ssa --export-dag --schedule alap --emit-rtl --test-values A=3,B=2
python -m hls examples/fritz/parallel_adders.txt --schedule cons-alap --adders 1 --subs 1 --muls 1 --emit-rtl --test-values A=2,B=3,C=4,D=5
python -m hls examples/fritz/reassignment.txt --schedule custom --emit-rtl --test-values B=2,C=3,D=4,E=2
python -m unittest discover -s tests/fritz -v
```

Generated outputs are written to `out/<basename>_<mode>_rtl/`; look at `schedule.json`, `binding.json`, `generated_datapath.v`, `generated_system.v`, `functional_units.v`, and `testbench.v`.

## Verilog simulation

```powershell
python scripts/simulate_rtl.py out/parallel_adders_cons-alap_rtl
```

The testbench checks expected final outputs, `done`, and whether the datapath remains paused while `step_enable` is low. **A passing Python unit test does not imply the RTL has been compiled or simulated.**

## FPGA synthesis/programming (requires team-provided hardware files)

```powershell
python scripts/build_and_program.py --equations examples/fritz/professor_run_1.txt --scheduler custom --test-values A=3,B=2 --board-top PATH/TO/ayla_board_top.v --xdc PATH/TO/board.xdc --part YOUR_REAL_PART --top YOUR_BOARD_MODULE --dry-run
```

Inspect the generated `out/fpga_build/build_and_program.tcl`. Remove `--dry-run` to invoke Vivado (build-only); add `--program` to program the connected board. You may need `--vivado "C:/Xilinx/Vivado/2025.1/bin/vivado.bat"` and `--hw-device DEVICE_ID`. **Never invent an XDC or program an unverified hardware target.**

Full design documentation: [docs/FRITZ_BACKEND.md](docs/FRITZ_BACKEND.md)  
Full 30-minute demo plan: [docs/DEMO_30_MINUTES.md](docs/DEMO_30_MINUTES.md).

### Proven versus outstanding

- **Verified locally:** Python-level scheduler/SSA/reference-result tests and generation of RTL artifacts from the branch's real compiler; see test suite.
- **Not verified locally:** Compilation/simulation of generated Verilog with Icarus, Vivado timing/bitstream, physical FPGA pins, switch input, step button, unit selection and display.
- **Team integration:** Ayla owns constrained ASAP, final board wrapper, constraints, and merging. Fritz's reference FSM/functional units must be reconciled with her modules; do not duplicate unit definitions.

For AI-assisted portions, disclose AI use according to course instructions, and be ready to explain and defend every design decision during the demonstration.

## Automated GitHub verification (after push)

`.github/workflows/fritz-backend.yml` is configured to run on branch `fritz-pa2` and pull requests. It installs Icarus Verilog, runs Python tests, then **actually compiles and simulates** the three generated RTL demonstrations. Open GitHub → **Actions** → **Fritz PA2 backend checks** to see whether this workflow passed. A workflow file existing in the repo does not mean its checks have passed; verify the actual run logs.
