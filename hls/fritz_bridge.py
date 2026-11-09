"""Fritz's hand-off from Ayla's shared DAG/Schedule into resource-bound RTL.

Ayla's parser, SSA, and DAG remain the only front end. This adapter keeps
Fritz's RTL internals independent of their naming and cycle-number convention.
Source cycles are 1-based; the datapath step counter is 0-based.
"""
from __future__ import annotations
import json
from pathlib import Path
from .dag import DAG
from .parser import Const, Var
from .schedule import Schedule, validate, schedule_to_json
from .fritz_impl.ir import Design, Node
from .fritz_impl.binding import bind
from .fritz_impl.verilog import datapath, system
from .fritz_impl.board import fpga_top
from .fritz_impl.sim import testbench, evaluate

_OP = {'+': 'add', '-': 'sub', '*': 'mul'}


def adapt(schedule: Schedule, width: int) -> tuple[Design, dict[str, int]]:
    """Translate native DAG operands and schedule; retain one node per SSA op."""
    problems = validate(schedule)
    if problems:
        raise ValueError('cannot emit RTL for invalid schedule:\n' + '\n'.join(problems))
    dag = schedule.dag
    def operand(x):
        if isinstance(x, Const):
            return x.value
        if not isinstance(x, Var):
            raise ValueError(f'unsupported operand: {x!r}')
        return x.name if x.name in dag.by_name else 'in_' + x.name
    design = Design(width=width,
        inputs=['in_' + name for name in dag.inputs],
        nodes=[Node(n.name, _OP[n.op.value], (operand(n.left), operand(n.right))) for n in dag.nodes],
        outputs={'out_' + name: last for name, last in dag.outputs.items()})
    zero_based = {dag.nodes[idx].name: cycle - 1 for idx, cycle in schedule.cycle_of.items()}
    return design, zero_based


def parse_values(text: str | None, dag: DAG) -> dict[str, int]:
    """Translate --test-values A=3,B=2 into input stimulus names."""
    values = {name: 0 for name in dag.inputs}
    if not text:
        return {'in_' + name: v for name, v in values.items()}
    for entry in text.split(','):
        if '=' not in entry:
            raise ValueError('test values must be comma separated, e.g. A=3,B=2')
        name, raw = (x.strip() for x in entry.split('=', 1))
        if name not in values:
            raise ValueError(f'unknown primary input in test values: {name!r}')
        value = int(raw, 0) if raw.lower().startswith(('0x','0b','0o')) else int(raw)
        if value < 0:
            raise ValueError('test values must be nonnegative')
        values[name] = value
    return {'in_' + k: v for k,v in values.items()}


def emit(schedule: Schedule, target: Path, width: int = 8, test_values: str | None = None) -> dict:
    """Generate all backend artifacts and return their paths / reference results."""
    design, scheduled = adapt(schedule, width)
    inputs = parse_values(test_values, schedule.dag)
    if any(v >= 2 ** width for v in inputs.values()):
        raise ValueError(f'test input must fit in {width} unsigned bits')
    target.mkdir(parents=True, exist_ok=True)
    binding = bind(design, scheduled)
    paths = {
        'generated_datapath.v': datapath(design, scheduled),
        'generated_system.v': system(design, scheduled),
        'testbench.v': testbench(design, scheduled, extra_vectors=[inputs]),
        'binding.json': json.dumps(binding, indent=2) + '\n',
        'schedule.json': json.dumps(schedule_to_json(schedule), indent=2) + '\n',
        'normalized_ir.json': json.dumps(design.to_json(), indent=2) + '\n',
    }
    paths['fpga_top.v'] = fpga_top(design, scheduled)
    rtl = Path(__file__).resolve().parents[1] / 'rtl'
    paths['functional_units.v'] = (rtl / 'functional_units.v').read_text(encoding='utf-8')
    paths['board_helpers.v'] = (rtl / 'board_helpers.v').read_text(encoding='utf-8')
    for filename, data in paths.items():
        (target / filename).write_text(data, encoding='utf-8')
    return {
        'directory': str(target), 'latency': schedule.latency,
        'units': binding['units'],
        'reference_outputs': evaluate(design, scheduled, inputs),
        'files': list(paths),
    }
