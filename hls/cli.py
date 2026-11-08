"""Command-line interface. Reads arguments and calls the other modules;
no parsing or synthesis logic lives here.

    python -m hls FILE                     parse, convert to SSA, print the SSA
    python -m hls FILE --check             only validate the file
    python -m hls FILE --export-ssa        also write out/<name>_ssa.txt
    python -m hls FILE --export-ssa PATH   also write the SSA to PATH
    python -m hls FILE --export-dag        also write out/<name>_dag.dot (Graphviz)
    python -m hls FILE --schedule MODE [--adders N] [--subs N] [--muls N] [--latency N]
                                           choose the scheduler (default asap)
    python -m hls FILE --export-schedule   also write out/<name>_<mode>_schedule.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import parser as hls_parser
from .dag import Unit, build_dag, format_dag, to_dot
from .schedule import format_schedule, schedule_to_json, validate
from .schedulers import ALL_MODES, SCHEDULERS
from .ssa import format_ssa, to_ssa

DEFAULT_OUT_DIR = Path("out")
_DEFAULT_EXPORT = object()  # marks "--export-ssa given without a path"


def build_arg_parser() -> argparse.ArgumentParser:
    ap = argparse.ArgumentParser(prog="python -m hls", description="EC551 PA2 high-level synthesis tool")
    ap.add_argument("file", help="equation file, one equation per line")
    ap.add_argument("--check", action="store_true", help="only validate the file, then stop")
    ap.add_argument(
        "--export-ssa",
        nargs="?",
        const=_DEFAULT_EXPORT,
        metavar="PATH",
        help=f"write the SSA form to PATH (default: {DEFAULT_OUT_DIR}/<name>_ssa.txt)",
    )
    ap.add_argument(
        "--export-dag",
        nargs="?",
        const=_DEFAULT_EXPORT,
        metavar="PATH",
        help=f"write the DAG as Graphviz DOT to PATH (default: {DEFAULT_OUT_DIR}/<name>_dag.dot)",
    )
    ap.add_argument("--schedule", choices=ALL_MODES, default="asap", help="scheduling mode (default: asap)")
    ap.add_argument("--adders", type=_positive, metavar="N", help="max adders per cycle")
    ap.add_argument("--subs", type=_positive, metavar="N", help="max subtractors per cycle")
    ap.add_argument("--muls", type=_positive, metavar="N", help="max multipliers per cycle")
    ap.add_argument("--latency", type=_positive, metavar="N", help="cycle bound (ALAP modes)")
    ap.add_argument(
        "--export-schedule",
        nargs="?",
        const=_DEFAULT_EXPORT,
        metavar="PATH",
        help=f"write the schedule as JSON to PATH (default: {DEFAULT_OUT_DIR}/<name>_<mode>_schedule.json)",
    )
    # Fritz-owned backend; default CLI behavior remains Ayla's original text output.
    ap.add_argument("--emit-rtl", action="store_true", help="write resource binding, datapath, FSM, modular functional units and testbench")
    ap.add_argument("--export-binding", action="store_true", help="write resource binding JSON for selected schedule")
    ap.add_argument("--width", type=_positive, default=8, help="unsigned RTL width (default: 8; max 64)")
    ap.add_argument("--test-values", default=None, metavar="A=3,B=2", help="input stimulus for the generated Verilog testbench")
    ap.add_argument("--out", type=Path, default=DEFAULT_OUT_DIR, help="directory for generated files")
    return ap


def _positive(text: str) -> int:
    try:
        value = int(text)
    except ValueError:
        raise argparse.ArgumentTypeError(f"'{text}' is not a whole number")
    if value < 1:
        raise argparse.ArgumentTypeError("must be at least 1")
    return value


def _export(requested, default: Path, text: str, what: str) -> None:
    """Write `text` if the flag was given: to its PATH, or to `default`."""
    if requested is None:
        return
    target = default if requested is _DEFAULT_EXPORT else Path(requested)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")
    print(f"{what} written to {target}")


def main(argv: list[str] | None = None) -> int:
    args = build_arg_parser().parse_args(argv)
    path = args.file

    # Read
    try:
        source = hls_parser.read_source(path)
    except OSError as e:
        print(f"{path}: error: cannot read file: {e.strerror}", file=sys.stderr)
        return 1
    except UnicodeDecodeError:
        print(f"{path}: error: file is not UTF-8 text", file=sys.stderr)
        return 1

    # Part 1: parse and validate
    result = hls_parser.parse_source(source)
    for d in result.diagnostics:
        print(hls_parser.format_diagnostic(path, d), file=sys.stderr)
    if not result.ok:
        print(f"{path}: {len(result.errors)} error(s); stopping.", file=sys.stderr)
        return 1
    if args.check:
        print(f"{path}: OK, {len(result.equations)} equations, inputs: {' '.join(result.inputs)}")
        return 0

    name, stem = Path(path).name, Path(path).stem

    # Part 2: SSA
    program = to_ssa(result)
    ssa_text = format_ssa(program, name)
    print(ssa_text)

    # Part 3: DAG
    dag = build_dag(program)
    print(format_dag(dag, name))

    _export(args.export_ssa, args.out / f"{stem}_ssa.txt", ssa_text, "SSA")
    _export(args.export_dag, args.out / f"{stem}_dag.dot", to_dot(dag, stem), "DAG")

    # Part 3: scheduling
    mode = args.schedule
    scheduler = SCHEDULERS.get(mode)
    if scheduler is None:
        print(f"error: scheduling mode '{mode}' is not implemented yet "
              f"(available: {', '.join(SCHEDULERS)})", file=sys.stderr)
        return 2

    limits = {
        unit: k
        for unit, k in ((Unit.ADDER, args.adders), (Unit.SUBTRACTOR, args.subs), (Unit.MULTIPLIER, args.muls))
        if k is not None
    }
    try:
        sched = scheduler(dag, limits or None, args.latency)
    except (ValueError, RuntimeError) as e:
        print(f"error: {e}", file=sys.stderr)
        return 2

    problems = validate(sched)
    if problems:
        # A scheduler produced an invalid schedule: a bug, not a user error.
        print(f"internal error: {mode} produced an invalid schedule:", file=sys.stderr)
        for p in problems:
            print(f"  - {p}", file=sys.stderr)
        return 1

    print(format_schedule(sched, name))
    schedule_json = json.dumps(schedule_to_json(sched, name), indent=2) + "\n"
    _export(args.export_schedule, args.out / f"{stem}_{mode}_schedule.json", schedule_json, "Schedule")

    if args.emit_rtl or args.export_binding:
        from .fritz_bridge import emit
        try:
            if not 1 <= args.width <= 64:
                raise ValueError('--width must be 1..64')
            target = args.out / f"{stem}_{mode}_rtl"
            details = emit(sched, target, width=args.width, test_values=args.test_values)
        except (ValueError, RuntimeError, OSError) as e:
            print(f"error: backend failed: {e}", file=sys.stderr)
            return 2
        print(f"RTL and binding artifacts written to {target}")
        print(f"  cycles: {details['latency']}; physical units: {details['units']}")
        print(f"  reference results (test values): {details['reference_outputs']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
