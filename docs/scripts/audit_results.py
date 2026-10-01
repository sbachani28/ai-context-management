"""Independent consistency checks for the saved research outputs."""
from pathlib import Path
import collections, json, math, re
root=Path(__file__).resolve().parents[1]
def read(name):return json.loads((root/'data/processed'/name).read_text())
runs=read('retrieval_runs.json');questions=read('question_inventory.json')
assert len(questions)==2486 and sum(q['eligible'] for q in questions)==2006
assert len(runs)==24072
keys={(r['dataset'],r['question_id'],r['strategy'],r['k']) for r in runs}
assert len(keys)==len(runs)
groups=collections.defaultdict(list)
for r in runs:
    assert 0<=r['recall']<=1 and 0<=r['retained_fraction']<=1
    assert r['all_hit']<=r['any_hit']
    groups[(r['dataset'],r['question_id'],r['strategy'])].append(r)
for rows in groups.values():
    rows.sort(key=lambda r:r['k'])
    assert [r['k'] for r in rows]==[1,3,5,10]
    for a,b in zip(rows,rows[1:]):
        assert a['recall']<=b['recall'] and a['selected_words']<=b['selected_words']
# Reconstruct the recency score from raw LoCoMo annotations independently.
lookup={(r['question_id'],r['k']):r['recall'] for r in runs if r['dataset']=='LoCoMo' and r['strategy']=='Recent'}
checked=0
for c in json.loads((root/'data/raw/locomo10.json').read_text()):
    ids=sorted([int(k.split('_')[1]) for k in c['conversation'] if re.fullmatch(r'session_\d+',k)],reverse=True)
    for qi,q in enumerate(c['qa']):
        gold={int(m) for e in q.get('evidence',[]) for m in re.findall(r'D(\d+):\d+',e)}
        for k in [1,3,5,10]:
            key=(f"{c['sample_id']}:{qi}",k)
            if key in lookup:
                assert math.isclose(lookup[key],len(gold&set(ids[:k]))/len(gold))
                checked+=1
# Cross-check R's aggregate recall values against Python means.
for aggregate in read('retrieval_curves.json'):
    values=[r['recall'] for r in runs if all(r[k]==aggregate[k] for k in ['dataset','strategy','k'])]
    assert math.isclose(sum(values)/len(values),aggregate['recall'],abs_tol=1e-7)
clusters=read('cluster_effects.json')
for effect in read('retrieval_effects.json'):
    selected=[c for c in clusters if c['dataset']==effect['dataset']]
    assert math.isclose(sum(c['total'] for c in selected)/sum(c['n'] for c in selected),effect['gain'],abs_tol=1e-7)
    for c in selected: assert math.isclose(c['total']/c['n'],c['gain'],abs_tol=1e-7)
print(f'Passed: {len(runs):,} scored rows; monotonic budgets; {checked:,} raw-source recency checks; 24 R aggregate checks.')
