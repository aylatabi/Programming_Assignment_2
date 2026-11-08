"""Tests for the constrained ASAP scheduler.
Run from repository root: python -m pytest tests/schedulers -q
"""
from __future__ import annotations

import random
import unittest

from hls.dag import Unit, build_dag
from hls.parser import parse_source
from hls.schedule import validate
from hls.schedulers import SCHEDULERS

cons_asap = SCHEDULERS["cons-asap"]
asap = SCHEDULERS["asap"]


def build(text):
    parsed = parse_source(text)
    assert parsed.ok, parsed.errors
    from hls.ssa import to_ssa
    return build_dag(to_ssa(parsed))


class ConsAsapTests(unittest.TestCase):
    def test_one_adder_serialises_parallel_adds(self):
        dag = build("X=A+B\nY=C+D\nZ=X+Y\nQ=Z-A\n")
        s = cons_asap(dag, {Unit.ADDER: 1})
        self.assertEqual(validate(s), [])
        self.assertEqual(s.latency, 4)
        self.assertEqual(s.units_needed()[Unit.ADDER], 1)

    def test_generous_limits_match_asap(self):
        dag = build("X=A+B\nY=X+A\nZ=X-B\nQ=B*Z\n")
        s = cons_asap(dag, {Unit.ADDER: 5, Unit.SUBTRACTOR: 5, Unit.MULTIPLIER: 5})
        self.assertEqual(s.cycle_of, asap(dag).cycle_of)

    def test_critical_path_goes_first(self):
        # P starts a 3-long chain; R is a lone add. With 1 adder P must go in cycle 1.
        dag = build("R=E+F\nP=A+B\nS=P*C\nT=S*D\n")
        s = cons_asap(dag, {Unit.ADDER: 1})
        names = {dag.nodes[n].name: c for n, c in s.cycle_of.items()}
        self.assertEqual(names["P_1"], 1)
        self.assertEqual(s.latency, 3)

    def test_needs_a_limit(self):
        with self.assertRaises(ValueError):
            cons_asap(build("X=A+B\n"), None)

    def test_latency_bound_too_small(self):
        with self.assertRaises(ValueError):
            cons_asap(build("X=A+B\nY=C+D\nZ=E+F\n"), {Unit.ADDER: 1}, 2)

    def test_random_dags_are_valid(self):
        rng = random.Random(551)
        ops = "+-*"
        for _ in range(200):
            names, lines = ["A", "B", "C", "D"], []
            for i in range(rng.randint(1, 20)):
                lhs = rng.choice(["X", "Y", "Z", "W", f"T{i}"])
                lines.append(f"{lhs}={rng.choice(names)}{rng.choice(ops)}{rng.choice(names)}")
                names.append(lhs)
            dag = build("\n".join(lines) + "\n")
            limits = {u: rng.randint(1, 3) for u in Unit}
            s = cons_asap(dag, limits)
            self.assertEqual(validate(s), [], lines)


if __name__ == "__main__":
    unittest.main()
