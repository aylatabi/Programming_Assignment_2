#!/usr/bin/env python3
"""Compile and run the generated self-checking Verilog testbench with Icarus.

Exit non-zero on missing simulator, compile failure or $fatal in simulation.
Usage: python scripts/simulate_rtl.py examples/fritz/generated/parallel_adders_cons-alap_rtl
"""
from __future__ import annotations
import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def main():
    p = argparse.ArgumentParser(description='Icarus simulation of generated HLS RTL')
    p.add_argument('rtl_dir', type=Path)
    p.add_argument('--iverilog', default='iverilog')
    p.add_argument('--vvp', default='vvp')
    a = p.parse_args()
    compiler = shutil.which(a.iverilog)
    runner = shutil.which(a.vvp)
    if not compiler or not runner:
        print('ERROR: Icarus Verilog (iverilog and vvp) must be installed and on PATH.',file=sys.stderr)
        return 2
    required = [a.rtl_dir / x for x in ('functional_units.v','generated_datapath.v','generated_system.v','testbench.v')]
    missing = [str(f) for f in required if not f.is_file()]
    if missing:
        p.error('RTL files missing: ' + ', '.join(missing))
    output = a.rtl_dir / 'simulation.vvp'
    cmd=[compiler, '-g2012', '-s', 'tb_generated_system', '-o', str(output), *map(str,required)]
    print('Compiling:', ' '.join(cmd),flush=True)
    c=subprocess.run(cmd,check=False)
    if c.returncode:
        return c.returncode
    print('Running testbench...',flush=True)
    r=subprocess.run([runner,str(output)],check=False)
    return r.returncode

if __name__ == '__main__':
    raise SystemExit(main())
