# EC551 PA2: Hardware Synthesis

A small high-level synthesis (HLS) tool and FPGA runtime. It reads arithmetic
equations, converts them to SSA form, builds a dependency DAG, schedules it
with one of five algorithms, and generates Verilog (datapath, control FSM,
functional units, testbench and a board top level) that runs on a
**Digilent Nexys4 DDR** board, stepped one clock cycle per button press.

Team: Ayla Tabi and Fritz.

## Status

| Part | What | Verified by |
|---|---|---|
| 1 | Equation parser and input validation | 33 parser fixture files (`tests/parser/`) |
| 2 | SSA conversion, `--export-ssa` | tests, manual check of reassignment |
| 3 | DAG, `--export-dag`; ASAP, constrained ASAP, ALAP, constrained ALAP, custom schedulers | randomized and exhaustive scheduler tests; every schedule passes `validate()` |
| 4 | Resource binding, mux/register datapath, FSM sequencer | generated `testbench.v` passes in Icarus for all 5 modes |
| 5 | Parameterized adder, subtractor, multiplier blocks | same |
| 6 | Generated system module, `testbench.v`, step button, unit selection | `tests/board/` simulates the board top level through its buttons and display |
| 7 | Nexys4 DDR constraints, build/program script, 7-segment display | built in Vivado 2024.1 and run on the board |
| 8 | This README and the 30-minute demo plan | below |

Run all tests: `python -m pytest -q` (29 tests; Verilog tests need Icarus Verilog).

## Repository layout

```text
hls/                     the synthesis tool (Python, no third-party packages)
  cli.py                 command line (python -m hls ...)
  parser.py              Part 1: read and validate equations
  ssa.py                 Part 2: SSA renaming
  dag.py                 Part 3: operation DAG, critical path, DOT export
  schedule.py            Schedule type, validate(), text/JSON output
  schedulers/            Part 3: asap, cons_asap, alap, cons_alap, custom
  fritz_bridge.py        hands a schedule to the hardware back end
  fritz_impl/
    binding.py           Part 4: operation -> physical unit binding
    verilog.py           Part 4/6: datapath (muxes, registers) and FSM
    board.py             Part 6/7: Nexys4 DDR top level (fpga_top.v)
    sim.py               testbench generator and reference evaluator
rtl/
  functional_units.v     Part 5: pa2_add, pa2_sub, pa2_mul (parameterized width)
  board_helpers.v        button debouncer, 8-digit 7-segment driver
  nexys4ddr.xdc          board pin constraints (same for every design)
scripts/
  simulate_rtl.py        compile and run testbench.v with Icarus
  build_and_program.py   one command: equations -> Verilog -> Vivado bitstream -> board
examples/fritz/          example equation files and committed generated output
tests/
  parser/                valid / invalid / warning equation files
  schedulers/            constrained ASAP tests
  fritz/                 scheduler, binding, RTL generation and simulation tests
  board/                 board top level simulated through buttons and display
docs/                    assignment PDF, work plan, back-end design notes
```

## Architecture

```text
equations.txt
  -> parser      validate: one operator (+ - *) per line, max 20 lines
  -> SSA         X = A + B; X = X + A   becomes   X_1 = A + B; X_2 = X_1 + A
  -> DAG         one node per operation, edges = data dependencies
  -> scheduler   assign every operation a cycle (1 operation = 1 cycle)
  -> binding     assign every operation a physical unit (add_0, add_1, mul_0, ...)
  -> Verilog     generated_datapath.v   muxes in front of each unit, one register per SSA value
                 generated_system.v     FSM: idle -> step 0..N-1 -> done, advances on step_enable
                 functional_units.v     the exact number of units the schedule needs
                 testbench.v            self-checking simulation with expected results
                 fpga_top.v             board wrapper: switches, buttons, 7-segment, LEDs
```

### Schedulers (`--schedule`)

| Mode | How it works | Limits |
|---|---|---|
| `asap` | each operation runs 1 cycle after its latest input | none |
| `cons-asap` | list scheduling: each cycle, place ready operations (longest remaining path first) until a unit type is full | `--adders/--subs/--muls` (at least one) |
| `alap` | work backwards from a deadline (`--latency`, default = critical path); each operation runs 1 cycle before its earliest user | none |
| `cons-alap` | backtracking search for the latest feasible placement; tries the smallest deadline first, so it finds the shortest schedule | `--adders/--subs/--muls` (at least one), optional `--latency` |
| `custom` | list scheduling that defaults to **one unit of each type used** (smallest hardware) and breaks ties by fanout | optional |

### Hardware

- **Datapath:** each physical unit has a mux on each input that picks its
  operands by the current step. Fewer units than operations means the muxes
  share each unit across cycles. Every SSA value has a register that is
  written at the end of its scheduled step.
- **Sequencer:** `start` latches the inputs and enters step 0; each
  `step_enable` pulse writes that step's registers and advances; after the
  last step `done` goes high. All mux selects and write enables are decoded
  from the step counter.
- **Functional units:** combinational, unsigned, `WIDTH` bits (default 8).
  Results wrap modulo 2^WIDTH (for example 20 x 20 shows as 144).

## Requirements

- Python 3.10 or newer.
- For simulation: [Icarus Verilog](https://bleyer.org/icarus/) (`iverilog`, `vvp`) on `PATH`.
- For the board: Vivado (tested with 2024.1) and a Nexys4 DDR (`xc7a100tcsg324-1`).
- Optional: `pytest` for the test runner.

## Running the tool

```bash
python -m hls examples/fritz/professor_run_1.txt --schedule cons-asap --adders 1 --export-ssa --export-dag --emit-rtl --test-values A=3,B=2
```

The terminal shows the SSA form, the DAG and the schedule. Files are written
under `out/`:

| File | Contents |
|---|---|
| `<name>_ssa.txt` | SSA form (`--export-ssa`) |
| `<name>_dag.dot` | DAG in Graphviz DOT (`--export-dag`); paste into any Graphviz viewer |
| `<name>_<mode>_rtl/schedule.json`, `binding.json` | schedule and unit binding |
| `<name>_<mode>_rtl/*.v` | all Verilog, including `testbench.v` and `fpga_top.v` |

Main options: `--schedule {asap,cons-asap,alap,cons-alap,custom}`,
`--adders N --subs N --muls N`, `--latency N`, `--width N` (default 8),
`--test-values A=3,B=2` (inputs for the testbench; also prints the expected
results), `--check` (validate only), `--out DIR`. Run `python -m hls -h` for all.

Input format: one equation per line, `dest = operand op operand`, with
`op` one of `+ - *`. Operands are variable names or non-negative integers.
`#` starts a comment. At most 20 equations. Mistakes are reported with the
line, column and a caret.

### Simulation

```bash
python scripts/simulate_rtl.py out/professor_run_1_cons-asap_rtl
```

Prints `PASS: all generated test vectors passed`. The testbench checks every
unit's output in every step, that the design pauses when not stepped, and the
final outputs.

## FPGA (Nexys4 DDR)

### Option 1: Vivado project (used for the demo)

1. Generate the Verilog and copy it to a fixed folder, so the project's file
   links never change (PowerShell):
   ```powershell
   python -m hls examples/fritz/parallel_adders.txt --schedule cons-asap --adders 1 --emit-rtl --test-values A=2,B=3,C=4,D=5
   New-Item -ItemType Directory -Force out\vivado_rtl; Copy-Item out\parallel_adders_cons-asap_rtl\*.v out\vivado_rtl\ -Force
   ```
2. Create an RTL project for part `xc7a100tcsg324-1` outside the repository.
3. Add sources with **"Copy sources into project" unticked**:
   - design: `fpga_top.v`, `generated_system.v`, `generated_datapath.v`, `functional_units.v`, `board_helpers.v` from `out\vivado_rtl\`
   - constraints: `rtl\nexys4ddr.xdc`
   - simulation: `out\vivado_rtl\testbench.v` (set its type to SystemVerilog; top `tb_generated_system`)
4. Set `fpga_top` as top. **Generate Bitstream**, then **Hardware Manager → Program Device**.
5. For new equations, repeat step 1 and click **Reload** in Vivado.

Useful views: **Open Elaborated Design → Schematic** shows the muxes,
registers and units; **Run Behavioral Simulation → Run All** shows the
testbench waveform and PASS message; the utilization report shows the
hardware used.

### Option 2: one command

```bash
python scripts/build_and_program.py --equations examples/fritz/professor_run_1.txt --scheduler cons-asap --test-values A=3,B=2 --vivado C:/Xilinx/Vivado/2024.1/bin/vivado.bat --program
```

Generates the Verilog, runs Vivado in batch mode with `rtl/nexys4ddr.xdc`,
writes `out/fpga_build/fpga_top.bit` plus timing and utilization reports, and
programs the board. Leave out `--program` to only build; add `--dry-run` to
only write the Vivado TCL script. Use `--out DIR` to keep several builds.

### Board controls

| Control | Function |
|---|---|
| `SW7–SW0` | value to load into an input |
| `BTNL` / `BTNR` | previous / next input |
| `BTNU` | load the switch value into the current input |
| `BTND` | start: latch the inputs and begin cycle 1 |
| `BTNC` | step: one clock cycle |
| `CPU_RESETN` | reset everything |
| `SW15–SW10` | what the display shows (binary, `SW10` = 1): units first, then outputs, then inputs; the numbered list is at the top of the generated `fpga_top.v` |

**Display (decimal):** `[selection] [cycle] [value]`. For about 3 seconds
after `BTNL`, `BTNR` or `BTNU` it shows `[input number] [blank] [stored value]`
instead. Cycle `00` means not started.

**LEDs:** `LED7–0` value of the current input, `LED12–8` its number,
`LED13` busy, `LED14` done, `LED15` the selection is past the end of the list.

### Example: `parallel_adders.txt`, constrained ASAP with 1 adder

`X=A+B, Y=C+D, Z=X+Y, Q=Z-A` with A=2, B=3, C=4, D=5. Load the four inputs,
press `BTND`, keep `SW15–SW10` at 0 (the adder) and press `BTNC`: the same
adder shows 5, 9, 14 in cycles 1–3; the subtractor (selection 1) shows 12 in
cycle 4. Outputs X, Y, Z, Q (selections 2–5) are 5, 9, 14, 12. Plain ASAP needs
2 adders and 3 cycles for the same equations.

## 30-minute demo plan

### Before the demo (setup, not counted)

- Board connected and programmed with `parallel_adders` (constrained ASAP, 1 adder).
- Vivado project open (Option 1 above); terminal open in the repository.
- `python -m pytest -q` already run once and passing.
- Three empty files `demo1.txt`, `demo2.txt`, `demo3.txt` in the repository root.

### Plan

| Time | What | Shows (assignment part) |
|---|---|---|
| 0:00–2:00 | Architecture: the pipeline diagram above and the repository layout | overview |
| 2:00–4:00 | **Ask the professor for all three sets of equations and input values.** Type them into `demo1–3.txt`, run `--check` on each, and start the three Vivado batch builds in a second terminal (command below) | 1, 7 |
| 4:00–7:00 | Parser and SSA: show an error message on a bad file (`tests/parser/invalid/too_many_operands.txt`), then `--export-ssa` on `examples/fritz/reassignment.txt` (X assigned three times) | 1, 2 |
| 7:00–11:00 | DAG and the five schedulers on `examples/fritz/wide.txt`: ASAP needs 3 adders, ALAP 2, constrained modes 1 adder in 4 cycles; show `--export-dag` | 3 |
| 11:00–14:00 | Generated hardware in Vivado: schematic of `generated_datapath` (muxes, registers, units), `binding.json`, the FSM in `generated_system.v` | 4, 5, 6 |
| 14:00–16:00 | Behavioral simulation in Vivado: waveform of `step`, the muxes and unit outputs; PASS message | 6 |
| 16:00–18:00 | Board walkthrough with the programmed `parallel_adders`: load inputs, step, the one adder showing 5 → 9 → 14, unit selection, outputs | 6, 7 |
| 18:00–22:00 | **Live run 1** (`demo1`) | all |
| 22:00–26:00 | **Live run 2** (`demo2`) | all |
| 26:00–29:00 | **Live run 3** (`demo3`) | all |
| 29:00–30:00 | Questions | |

Commands for 7:00–11:00:
```bash
python -m hls examples/fritz/wide.txt --schedule asap --export-dag
python -m hls examples/fritz/wide.txt --schedule alap
python -m hls examples/fritz/wide.txt --schedule cons-asap --adders 1 --muls 1
python -m hls examples/fritz/wide.txt --schedule cons-alap --adders 1 --muls 1
python -m hls examples/fritz/wide.txt --schedule custom
```

### Starting the three builds at 2:00

The professor picks the scheduler and limits for each run; in the build script
the constrained modes default to one unit of each type. In a second terminal,
run the three builds one after another (replace the schedulers and the
`--test-values` with the professor's choices):

```powershell
$v = "C:/Xilinx/Vivado/2024.1/bin/vivado.bat"
python scripts/build_and_program.py --equations demo1.txt --scheduler cons-asap --test-values A=1,B=2 --vivado $v --out out/run1; python scripts/build_and_program.py --equations demo2.txt --scheduler cons-alap --test-values A=1,B=2 --vivado $v --out out/run2; python scripts/build_and_program.py --equations demo3.txt --scheduler custom --test-values A=1,B=2 --vivado $v --out out/run3
```

Each build takes a few minutes and runs while the other parts are shown; all
three should be done by about 16:00. Each prints the expected results
(`reference results`) and writes `out/runN/fpga_top.bit`.

### Each live run (4 minutes)

1. Show the run's SSA, DAG and schedule in the terminal output (30 s).
2. Simulate: `python scripts/simulate_rtl.py out/runN/generated/demoN_<mode>_rtl` → PASS (30 s).
3. **Hardware Manager → Program Device** with `out/runN/fpga_top.bit` (30 s).
4. Load the professor's inputs, press `BTND`, step with `BTNC` while selecting
   units with `SW15–SW10` (selection list at the top of
   `out/runN/generated/demoN_<mode>_rtl/fpga_top.v`) (2 min).
5. Compare the outputs with the expected results and a hand calculation (30 s).

**If a build is not finished in time:** do the run's simulation first and
come back to the board after the next run. **If equations come one at a time
instead:** use the Vivado project (Option 1, step 5); the bitstream takes a
few minutes, during which the schedule, schematic and simulation are shown.

## Known limitations

- Values are unsigned and `WIDTH` bits wide (default 8); results wrap
  modulo 2^WIDTH, and the display shows the last 4 decimal digits.
- The board loads inputs from 8 switches, so each input is 0–255.
- One register per SSA value (registers are not shared between values whose
  lifetimes do not overlap).
- `custom` often matches `cons-asap` when both use the same limits; it differs
  in its default (one unit per type) and its fanout tie-break.
- On our board, `LED9` does not light (hardware); the display's input view
  shows the input number instead.

More detail on the back end: [docs/FRITZ_BACKEND.md](docs/FRITZ_BACKEND.md).
