"""Bind same-type operations at different times to reusable physical units."""
from collections import defaultdict
from .ir import Design
from .scheduling import validate

def bind(d:Design,schedule:dict[str,int])->dict:
    validate(d,schedule)
    slot=defaultdict(list)
    for n in d.nodes:slot[(schedule[n.id],n.op)].append(n.id)
    # Deterministic binding across cycles: lowest available FU of the same type.
    allocation={}
    for (t,op),nodes in sorted(slot.items()):
        for unit,nid in enumerate(sorted(nodes)):
            allocation[nid]={'cycle':t,'op':op,'unit':unit,'physical_unit':f'{op}_{unit}'}
    total={op:1+max((x['unit'] for x in allocation.values() if x['op']==op),default=-1) for op in ('add','sub','mul')}
    muxes={}
    for op,count in total.items():
        for u in range(count):
            key=f'{op}_{u}'
            muxes[key]=[
              {'cycle':v['cycle'],'node':nid,'a':d.by_id[nid].args[0],'b':d.by_id[nid].args[1]}
              for nid,v in sorted(allocation.items(), key=lambda p:p[1]['cycle'])
              if v['physical_unit']==key
            ]
    registers=[{'name':n.id,'write_cycle':schedule[n.id],'source':allocation[n.id]['physical_unit']} for n in d.nodes]
    return {'schedule':schedule,'units':total,'assignment':allocation,'operand_muxes':muxes,'registers':registers}
