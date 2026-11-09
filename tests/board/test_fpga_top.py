"""Board-level simulation of the generated Nexys4 DDR top level (fpga_top.v).

Generates RTL for the professor example, then runs tb_fpga_top_professor.v in
Icarus: it loads inputs with the switches and buttons, steps the design, and
reads the 7-segment display digit by digit.
Run from repository root: python -m pytest tests/board -q
"""
from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from hls.cli import main as hls_main

ROOT = Path(__file__).resolve().parents[2]
TB = Path(__file__).with_name("tb_fpga_top_professor.v")
RTL_FILES = ["fpga_top.v", "board_helpers.v", "generated_system.v",
             "generated_datapath.v", "functional_units.v"]


@unittest.skipUnless(shutil.which("iverilog") and shutil.which("vvp"), "Icarus Verilog not installed")
class FpgaTopSimulation(unittest.TestCase):
    def test_professor_example_on_board_wrapper(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            rc = hls_main([str(ROOT / "examples/fritz/professor_run_1.txt"),
                           "--schedule", "cons-asap", "--adders", "1",
                           "--emit-rtl", "--out", str(out)])
            self.assertEqual(rc, 0)
            rtl = out / "professor_run_1_cons-asap_rtl"
            vvp = out / "tb.vvp"
            build = subprocess.run(
                ["iverilog", "-g2005", "-s", "tb_fpga_top", "-o", str(vvp), str(TB),
                 *(str(rtl / f) for f in RTL_FILES)],
                capture_output=True, text=True)
            self.assertEqual(build.returncode, 0, build.stderr)
            run = subprocess.run(["vvp", "-n", str(vvp)], capture_output=True, text=True, timeout=120)
            self.assertIn("PASS: fpga_top board test", run.stdout, run.stdout)


if __name__ == "__main__":
    unittest.main()
