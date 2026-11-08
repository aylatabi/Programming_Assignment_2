"""Independent Python register-cycle evaluator and step-by-step Verilog testbench."""
from __future__ import annotations
from random import Random
from .ir import Design
from .scheduling import validate, latency


def trace(d: Design, schedule: dict[str,int], inputs: dict[str,int]):
    """Cycle traces with old-value reads and nonblocking-like commit at the edge."""
    validate(d, schedule)
    mask = (1 << d.width) - 1
    values = {name: inputs[name] & mask for name in d.inputs}
    for cycle in range(latency(schedule)):
        snapshot = values.copy()
        writes = {}
        for node in d.nodes:
            if schedule[node.id] != cycle:
                continue
            def operand(x):
                return (x if isinstance(x, int) else snapshot[x]) & mask
            left, right = (operand(x) for x in node.args)
            output = {'add': lambda:left+right,'sub':lambda:left-right,'mul':lambda:left*right}[node.op]() & mask
            writes[node.id] = output
        values.update(writes)
        yield cycle, snapshot, writes, values.copy()


def evaluate(d: Design, schedule: dict[str,int], inputs: dict[str,int]) -> dict[str,int]:
    mask = (1 << d.width) - 1
    vals = {name: inputs[name] & mask for name in d.inputs}
    for _,_,_, snapshot in trace(d, schedule, inputs):
        vals = snapshot
    return {name: (ref if isinstance(ref, int) else vals[ref]) & mask for name, ref in d.outputs.items()}


def testbench(d: Design, schedule: dict[str,int], num_vectors:int=12, seed:int=551,
              extra_vectors:list[dict[str,int]]|None=None) -> str:
    """Self-checking testbench verifying each step pulse, each FU and final outputs.

    All expected values are calculated at generation time from Python reference
    arithmetic. This still requires an independent HDL simulator to prove RTL.
    """
    from .binding import bind
    from .verilog import outs_units, step_width
    b = bind(d, schedule)
    w, steps = d.width, latency(schedule)
    sw = step_width(steps)
    mask = (1 << w) - 1
    rng=Random(seed)
    patterns = list(extra_vectors or []) + [{x:0 for x in d.inputs},{x:mask for x in d.inputs}]
    for pat in patterns:
        if set(pat) != set(d.inputs):
            raise ValueError('test vector must supply every input')
    patterns.extend({x:rng.randrange(mask+1) for x in d.inputs} for _ in range(max(0,num_vectors-2)))
    s = ['`timescale 1ns/1ps','module tb_generated_system;',
         '  reg clk=0; always #5 clk=~clk;',
         '  reg rst=1, start=0, step_enable=0;',
         '  wire busy, done;',f'  wire [{sw-1}:0] step_debug;']
    for inp in d.inputs: s.append(f'  reg [{w-1}:0] {inp}=0;')
    for o in d.outputs: s.append(f'  wire [{w-1}:0] {o};')
    for fu in outs_units(b): s.append(f'  wire [{w-1}:0] {fu};')
    ports = ['clk','rst','start','step_enable','busy','done','step_debug',*d.inputs,*d.outputs,*outs_units(b)]
    s.append('  generated_system dut ('+', '.join(f'.{p}({p})' for p in ports)+');')
    s.extend(['  initial begin','    repeat (2) @(negedge clk); rst=0;'])
    for j,pat in enumerate(patterns):
        s += [f'    // Independent reference vector {j}', '    @(negedge clk);']
        for a,value in pat.items():s.append(f"    {a} = {w}'d{value};")
        s += ['    start=1;', '    @(negedge clk); start=0;',
              '    repeat (2) @(negedge clk);']
        if steps:
            s += [f"    if (!busy || done || step_debug !== {sw}'d0) $fatal(1,\"Vector {j}: controller advanced without enable\");"]
            for t, snapshot, writes, after in trace(d,schedule,pat):
                s += [f'    // Actual scheduled cycle {t+1}; step counter {t}',
                      '    step_enable=1;', '    #1;']
                # Check actual FU outputs selected by the current step before the clock edge.
                for node_name, value in writes.items():
                    unit=b['assignment'][node_name]['physical_unit']
                    s.append(f"    if (fu_{unit}_out !== {w}'d{value}) $fatal(1,\"Vector {j} step {t}: {unit} mismatch\");")
                s += ['    @(negedge clk); step_enable=0;']
                if t == steps-1:
                    s.append(f'    if (busy || !done) $fatal(1,"Vector {j}: done/busy incorrect at completion");')
                else:
                    s.append(f"    if (!busy || done || step_debug !== {sw}'d{t+1}) $fatal(1,\"Vector {j}: incorrect step advance\");")
                # Keep enable low for two cycles and verify the controller stays put.
                s += ['    repeat (2) @(negedge clk);']
                if t != steps-1:
                    s.append(f"    if (!busy || step_debug !== {sw}'d{t+1}) $fatal(1,\"Vector {j}: advanced while paused\");")
        else:
            s.append(f'    if (busy || !done) $fatal(1,"Vector {j}: passthrough did not finish");')
        for o,value in evaluate(d,schedule,pat).items():
            s.append(f"    if ({o} !== {w}'d{value}) $fatal(1,\"Vector {j}: {o} got %0d expected {value}\", {o});")
    s += ['    $display("PASS: all generated test vectors passed");','$finish;',
          '  end','endmodule','']
    return '\n'.join(s)
