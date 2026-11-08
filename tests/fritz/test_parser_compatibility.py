"""Regression: confirm Fritz branch changes did not break Ayla parser fixtures."""
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

class ExistingParserTests(unittest.TestCase):
    def test_existing_thirty_three_parser_fixtures(self):
        count = 0
        for category, code in [('valid',0),('invalid',1),('warnings',0)]:
            for path in sorted((ROOT/'tests'/'parser'/category).glob('*.txt')):
                with self.subTest(category=category, filename=path.name):
                    proc = subprocess.run([sys.executable,'-m','hls',str(path),'--check'],
                        cwd=ROOT,text=True,capture_output=True)
                    self.assertEqual(proc.returncode,code,proc.stderr)
                    count += 1
        self.assertEqual(count,33)
