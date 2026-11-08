"""Normalized DAG interface between Ayla's front end and Fritz's back end.

All operations are single-cycle, non-pipelined, unsigned modulo 2**width.
Input and constant operand references are available at cycle zero.
"""
from __future__ import annotations
from dataclasses import dataclass
from collections import defaultdict, deque
import json
import re
from pathlib import Path

_OPS = {'add','sub','mul'}
_NAME = re.compile(r'^[A-Za-z_][A-Za-z_0-9]*$')

@dataclass(frozen=True)
class Node:
    id: str
    op: str
    args: tuple[str | int, str | int]

@dataclass
class Design:
    width: int
    inputs: list[str]
    nodes: list[Node]
    outputs: dict[str,str|int]
    def __post_init__(self):
        if not isinstance(self.width,int) or not 1<=self.width<=64:
            raise ValueError('width must be an integer from 1 to 64')
        if len(self.inputs)!=len(set(self.inputs)):
            raise ValueError('duplicate input identifiers')
        for a in self.inputs:
            self._name(a)
        ids=[n.id for n in self.nodes]
        if len(ids)!=len(set(ids)):
            raise ValueError('duplicate node identifiers')
        for n in self.nodes:
            self._name(n.id)
            if n.op not in _OPS:
                raise ValueError(f'unsupported operation {n.op!r} in {n.id}')
            if len(n.args)!=2:
                raise ValueError(f'{n.id} needs exactly two operands')
        all_names=self.inputs+ids
        if len(all_names)!=len(set(all_names)):
            raise ValueError('input and node identifiers overlap')
        known=set(all_names)
        for n in self.nodes:
            for a in n.args:
                if isinstance(a,bool) or not isinstance(a,(str,int)):
                    raise ValueError(f'bad operand {a!r}')
                if isinstance(a,str) and a not in known:
                    raise ValueError(f'unknown operand {a!r} in {n.id}')
        if not self.outputs:
            raise ValueError('at least one output is required')
        for key,ref in self.outputs.items():
            self._name(key)
            if isinstance(ref,str) and ref not in known:
                raise ValueError(f'unknown output reference {ref!r}')
            if isinstance(ref,bool) or not isinstance(ref,(int,str)):
                raise ValueError('output references must be names or integer constants')
        if set(self.outputs)&set(all_names):
            # Output ports can be aliased to inputs/node names in Verilog only if names differ.
            raise ValueError('output port names must be distinct from input/node identifiers')
        self.topological_order()  # Reject cycles at load time.
    @staticmethod
    def _name(n):
        if not isinstance(n,str) or not _NAME.fullmatch(n) or n in ('clk','rst','start','busy','done','step') or n.startswith('_'):
            raise ValueError(f'invalid/reserved identifier {n!r}')
    @property
    def by_id(self):return {n.id:n for n in self.nodes}
    def dependencies(self):
        ids=self.by_id
        return {n.id:tuple(x for x in n.args if isinstance(x,str) and x in ids) for n in self.nodes}
    def successors(self):
        result={n.id:[] for n in self.nodes}
        for v,deps in self.dependencies().items():
            for p in deps:
                if v not in result[p]:result[p].append(v)
        return result
    def topological_order(self):
        deps=self.dependencies(); succ=self.successors()
        indeg={n:len(set(ds)) for n,ds in deps.items()}
        q=deque(x.id for x in self.nodes if indeg[x.id]==0)
        out=[]
        while q:
            p=q.popleft();out.append(p)
            for s in succ[p]:
                indeg[s]-=1
                if indeg[s]==0:q.append(s)
        if len(out)!=len(self.nodes):raise ValueError('DAG has a dependency cycle')
        return out
    @classmethod
    def from_file(cls,path):
        raw=json.loads(Path(path).read_text(encoding='utf8'))
        try:
            return cls(raw['width'],list(raw['inputs']),
              [Node(x['id'],x['op'],tuple(x['args'])) for x in raw['nodes']],
              dict(raw['outputs']))
        except (TypeError,KeyError) as exc:
            raise ValueError(f'invalid IR JSON format: {exc}') from exc
    def to_json(self):
        return {'width':self.width,'inputs':self.inputs,'nodes':[{'id':n.id,'op':n.op,'args':list(n.args)} for n in self.nodes],'outputs':self.outputs}
