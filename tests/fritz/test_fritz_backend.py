"""Independent-ish regression tests for Fritz modules on the team's real DAG API.
Run from repository root: python -m unittest discover -s tests/fritz -v
"""
from __future__ import annotations
import itertools
import json
import random
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

from hls.parser import parse_source
from hls.ssa import to_ssa
from hls.dag import Unit, build_dag
from hls.schedule import validate
from hls.schedulers import SCHEDULERS
from hls.fritz_bridge import adapt, emit, parse_values
from hls.fritz_impl.binding import bind
from hls.fritz_impl.sim import evaluate

ROOT = Path(__file__).resolve().parents[2]
CAP = {Unit.ADDER:1, Unit.SUBTRACTOR:1, Unit.MULTIPLIER:1}


def build(text):
    parsed = parse_source(text)
    assert parsed.ok, parsed.errors
    return build_dag(to_ssa(parsed))


def expected_python(text: str, inputs: dict[str,int], width: int=8) -> dict[str,int]:
    """Sequential mathematical reference independent of backend binding/evaluator."""
    from hls.parser import Var, Const
    parsed = parse_source(text)
    assert parsed.ok
    vals = dict(inputs)
    mask = (1 << width) - 1
    for eq in parsed.equations:
        a = eq.left.value if isinstance(eq.left, Const) else vals[eq.left.name]
        b = eq.right.value if isinstance(eq.right, Const) else vals[eq.right.name]
        vals[eq.dest] = {'+': lambda: a+b, '-': lambda: a-b, '*':lambda:a*b}[eq.op.value]() & mask
    return {'out_' + v: vals[v] for v in {e.dest for e in parsed.equations}}


class SchedulingTests(unittest.TestCase):
    def test_alap_dependency_and_horizon(self):
        dag = build('X=A+B\nY=X+A\nZ=X-B\nQ=B*Z\n')
        plain = SCHEDULERS['alap'](dag)
        self.assertEqual(plain.latency, 3)
        self.assertFalse(validate(plain))
        extended = SCHEDULERS['alap'](dag, latency=7)
        self.assertEqual(extended.latency, 7)
        self.assertEqual(extended.cycle_of[0], 5)
        self.assertFalse(validate(extended))

    def test_unfeasible_alap_latency(self):
        dag = build('X=A+B\nY=X+A\nZ=Y*B\n')
        with self.assertRaisesRegex(ValueError, 'critical path'):
            SCHEDULERS['alap'](dag, latency=2)

    def test_unconstrained_alap_refuses_limits(self):
        dag=build('X=A+B')
        with self.assertRaises(ValueError):
            SCHEDULERS['alap'](dag,CAP)

    def test_constrained_alap_serial_adders(self):
        dag = build('X=A+B\nY=C+D\nZ=X+Y\n')
        sched = SCHEDULERS['cons-alap'](dag,CAP)
        self.assertEqual(sched.latency,3)
        self.assertEqual(sched.units_needed()[Unit.ADDER],1)
        self.assertFalse(validate(sched))

    def test_constrained_alap_rejects_unfeasible_bound(self):
        dag = build('X=A+B\nY=C+D\nZ=X+Y\n')
        with self.assertRaisesRegex(ValueError,'no feasible'):
            SCHEDULERS['cons-alap'](dag,CAP,latency=2)

    def test_constrained_alap_later_horizon(self):
        dag = build('X=A+B\nY=C+D\nZ=X+Y\n')
        s = SCHEDULERS['cons-alap'](dag,CAP,latency=6)
        self.assertEqual(s.latency,6)
        self.assertFalse(validate(s))

    def test_custom_critical_path_priority(self):
        dag = build('X=A+B\nY=C+D\nZ=X*B\nQ=Z+A\n')
        s = SCHEDULERS['custom'](dag)
        self.assertFalse(validate(s))
        self.assertEqual(s.cycle_of[0],1)
        self.assertEqual(s.units_needed()[Unit.ADDER],1)

    def test_custom_deadline(self):
        dag = build('X=A+B\nY=C+D\nZ=X+Y\n')
        with self.assertRaisesRegex(ValueError,'needs'):
            SCHEDULERS['custom'](dag,CAP,latency=2)

    def test_all_modes_preserve_dependencies_randomized(self):
        rng = random.Random(551)
        for case in range(50):
            names = ['P','Q','R','S','T','U']
            lines = []
            for i,name in enumerate(names):
                choices = ['A','B'] + names[:i]
                a,b = rng.choice(choices),rng.choice(choices)
                lines.append(f'{name}={a}{rng.choice(["+","-","*"])}{b}')
            dag = build('\n'.join(lines))
            for mode in ('asap','alap','cons-alap','custom'):
                args = {} if mode in ('asap','alap') else {'limits':CAP}
                s = SCHEDULERS[mode](dag,**args)
                self.assertFalse(validate(s), (case,mode,validate(s)))

    def test_twenty_independent_adders_cap_one(self):
        text = "\n".join(f"P{i}=A+B" for i in range(20))
        dag = build(text)
        result = SCHEDULERS['cons-alap'](dag, CAP)
        self.assertEqual(result.latency, 20)
        self.assertFalse(validate(result))
        self.assertEqual(result.units_needed()[Unit.ADDER],1)

    def test_constrained_alap_exhaustive_comparison_small_dags(self):
        rng = random.Random(5511)
        for case in range(10):
            names = ['P','Q','R','S']
            lines = []
            for i,name in enumerate(names):
                choices=['A','B'] + names[:i]
                lines.append(f'{name}={rng.choice(choices)}{rng.choice(["+","-","*"])}{rng.choice(choices)}')
            dag=build('\n'.join(lines))
            for horizon in range(dag.critical_path_length(),5):
                possible=False
                for times in itertools.product(range(1,horizon+1), repeat=len(dag.nodes)):
                    from hls.schedule import Schedule
                    trial=Schedule('cons-alap',dag,dict(enumerate(times)),CAP,latency_bound=horizon)
                    if not validate(trial):
                        possible=True;break
                try:
                    result=SCHEDULERS['cons-alap'](dag,CAP,latency=horizon)
                except ValueError:
                    self.assertFalse(possible,(case,horizon,lines))
                else:
                    self.assertTrue(possible,(case,horizon,lines))
                    self.assertFalse(validate(result))


class RTLTests(unittest.TestCase):
    def test_binding_reuses_single_adder(self):
        dag=build('X=A+B\nY=C+D\nZ=X+Y')
        sched=SCHEDULERS['cons-alap'](dag,CAP)
        d,s=adapt(sched,8)
        b=bind(d,s)
        self.assertEqual(b['units']['add'],1)
        self.assertEqual(len(b['operand_muxes']['add_0']),3)
        self.assertEqual(len(b['registers']),3)

    def test_unconstrained_parallel_adders(self):
        dag=build('X=A+B\nY=C+D\nZ=X+Y')
        d,s=adapt(SCHEDULERS['asap'](dag),8)
        self.assertEqual(bind(d,s)['units']['add'],2)

    def test_reference_results_for_all_modes(self):
        text='X=A+B\nY=X+A\nZ=X-B\nQ=B*Z'
        dag=build(text)
        expected={'out_X':5,'out_Y':8,'out_Z':3,'out_Q':6}
        for mode in ('asap','alap','cons-alap','custom'):
            sch=SCHEDULERS[mode](dag,**({} if mode in ('asap','alap') else {'limits':CAP}))
            d,s=adapt(sch,8)
            self.assertEqual(evaluate(d,s,{'in_A':3,'in_B':2}),expected)

    def test_ssa_reassignment(self):
        text='A=B+C\nA=A+D\nP=A*E\nR=P-C'
        dag=build(text)
        for mode in ('asap','alap','cons-alap','custom'):
            s=SCHEDULERS[mode](dag,**({} if mode in ('asap','alap') else {'limits':CAP}))
            d,t=adapt(s,8)
            values={'B':2,'C':3,'D':4,'E':2}
            self.assertEqual(evaluate(d,t,{'in_'+k:v for k,v in values.items()}), expected_python(text,values))

    def test_emit_contains_hw_structure(self):
        dag=build('X=A+B\nY=C+D\nZ=X+Y')
        s=SCHEDULERS['cons-alap'](dag,CAP)
        with tempfile.TemporaryDirectory() as td:
            result=emit(s,Path(td),width=8,test_values='A=2,B=3,C=4,D=5')
            self.assertEqual(result['units']['add'],1)
            self.assertEqual(result['reference_outputs']['out_Z'],14)
            rtl=(Path(td)/'generated_datapath.v').read_text()
            self.assertIn('mux_add_0_a',rtl)
            self.assertIn('pa2_add',rtl)
            self.assertIn('case (step)',rtl)
            top=(Path(td)/'generated_system.v').read_text()
            self.assertIn('input wire step_enable',top)
            self.assertIn('busy && step_enable',top)
            tb=(Path(td)/'testbench.v').read_text()
            self.assertIn('PASS: all generated test vectors passed',tb)
            self.assertIn('advanced while paused',tb)
            self.assertIn('step 0:',tb)

    def test_generates_no_unused_multiplier(self):
        dag=build('X=A+B\nY=X-A')
        with tempfile.TemporaryDirectory() as td:
            res=emit(SCHEDULERS['custom'](dag),Path(td),width=8)
            self.assertEqual(res['units']['mul'],0)

    def test_reject_out_of_range_inputs(self):
        dag=build('X=A+B')
        with tempfile.TemporaryDirectory() as td:
            with self.assertRaisesRegex(ValueError,'fit'):
                emit(SCHEDULERS['asap'](dag),Path(td),width=8,test_values='A=300,B=2')

    def test_cli_end_to_end_all_new_schedulers(self):
        for mode in ('alap','cons-alap','custom'):
            with tempfile.TemporaryDirectory() as td:
                cmd=[sys.executable,'-m','hls','examples/fritz/professor_run_1.txt','--schedule',mode,
                     '--emit-rtl','--export-ssa','--test-values','A=3,B=2','--out',td]
                if mode=='cons-alap': cmd += ['--adders','1','--subs','1','--muls','1']
                r=subprocess.run(cmd,cwd=ROOT,capture_output=True,text=True)
                self.assertEqual(r.returncode,0, r.stderr)
                self.assertTrue((Path(td)/f'professor_run_1_{mode}_rtl'/'generated_system.v').is_file())
                self.assertTrue((Path(td)/'professor_run_1_ssa.txt').is_file())

    def test_parser_negative_inputs(self):
        dag=build('X=A+B')
        with self.assertRaises(ValueError):parse_values('A=-3,B=2',dag)

    def test_all_three_demos(self):
        data=[('professor_run_1.txt',{'A':3,'B':2}),
              ('parallel_adders.txt',{'A':2,'B':3,'C':4,'D':5}),
              ('reassignment.txt',{'B':2,'C':3,'D':4,'E':2})]
        for name,inputs in data:
            text=(ROOT/'examples'/'fritz'/name).read_text()
            dag=build(text)
            for mode in ('asap','alap','cons-alap','custom'):
                sch=SCHEDULERS[mode](dag,**({} if mode in ('asap','alap') else {'limits':CAP}))
                d,s=adapt(sch,8)
                self.assertEqual(evaluate(d,s,{'in_'+k:v for k,v in inputs.items()}),
                                 expected_python(text,inputs), (name,mode))

if __name__=='__main__':unittest.main()
