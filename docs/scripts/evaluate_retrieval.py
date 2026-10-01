"""Deterministic, offline evidence-session retrieval. No LLM or API calls.
Scores use questions and source messages only; answer/evidence labels are used
after ranking. Do not interpret retrieval coverage as answer correctness.
"""
import collections, hashlib, json, math, random, re, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW, OUT = ROOT / 'data/raw', ROOT / 'data/processed'
OUT.mkdir(parents=True, exist_ok=True)
STOP = set('a an the and or but if in on at to from of for with by is are was were be been being i me my you your we our they their he she his her it its that this these those what which who when where why how do does did have has had can could would should tell about'.split())
def terms(text):
    return [t for t in re.findall(r"[a-z0-9]+", text.lower()) if t not in STOP]
def words(text):
    return len(text.split())
def save(name, obj):
    (OUT / name).write_text(json.dumps(obj, ensure_ascii=False, separators=(',', ':')))

class Index:
    def __init__(self, texts):
        self.n = len(texts)
        self.counts = [collections.Counter(terms(t)) for t in texts]
        self.lengths = [sum(c.values()) for c in self.counts]
        self.avg = sum(self.lengths) / self.n
        self.df = collections.Counter(t for c in self.counts for t in c)
    def rank(self, query):
        q = sorted(set(terms(query)))
        scores = []
        for j,c in enumerate(self.counts):
            score = sum(math.log(1 + (self.n-self.df[t]+.5)/(self.df[t]+.5)) *
                c[t]*2.5/(c[t]+1.5*(.25+.75*self.lengths[j]/max(self.avg,1)))
                for t in q if c[t])
            scores.append(score)
        # Equal scores favor original chronological order, not evidence position.
        return sorted(range(self.n), key=lambda j: (-scores[j],j))

results, questions, histories, excluded = [], [], [], []
duplicate_distractor_occurrences = 0
unique_sessions = {'LoCoMo': set(), 'LongMemEval-S': set()}
source_contents = {'LoCoMo': set(), 'LongMemEval-S': set()}
def evaluate(dataset, qid, cluster, category, query, ids, texts, gold, abstain, index):
    sizes = [words(t) for t in texts]
    valid = bool(gold) and gold.issubset(set(ids)) and not abstain
    positions = [(ids.index(g)+.5)/len(ids) for g in gold if g in ids]
    qrow = dict(dataset=dataset,question_id=qid,cluster=cluster,category=category,
        sessions=len(ids),history_words=sum(sizes),gold_sessions=len(gold),eligible=valid,
        abstention=abstain,earliest_evidence=min(positions) if positions else None,
        latest_evidence=max(positions) if positions else None)
    questions.append(qrow)
    if not valid:
        excluded.append(dict(dataset=dataset,question_id=qid,reason='unanswerable' if abstain else 'missing_or_unresolved_evidence'))
        return
    random_order = list(range(len(ids)))
    seed=int(hashlib.sha256((dataset+qid).encode()).hexdigest()[:16],16)
    random.Random(seed).shuffle(random_order)
    rankings={'BM25':index.rank(query),'Recent':list(reversed(range(len(ids)))),'Random':random_order}
    for strategy,ranking in rankings.items():
        for k in [1,3,5,10]:
            chosen=ranking[:k]; selected={ids[j] for j in chosen}; hits=len(selected & gold)
            results.append(dict(dataset=dataset,question_id=qid,cluster=cluster,category=category,
                strategy=strategy,k=k,actual_k=len(chosen),recall=hits/len(gold),
                any_hit=int(hits>0),all_hit=int(hits==len(gold)),gold_sessions=len(gold),
                selected_words=sum(sizes[j] for j in chosen),history_words=sum(sizes),
                retained_fraction=sum(sizes[j] for j in chosen)/max(sum(sizes),1),
                earliest_evidence=min(positions),latest_evidence=max(positions)))

start=time.time()
locomo=json.loads((RAW/'locomo10.json').read_text())
cats={1:'Multi-hop',2:'Temporal',3:'Open-domain',4:'Single-hop',5:'Adversarial'}
for c in locomo:
    cid=c['sample_id']; conv=c['conversation']
    keys=sorted((k for k in conv if re.fullmatch(r'session_\d+',k)),key=lambda k:int(k.split('_')[1]))
    ids=[k.split('_')[1] for k in keys]
    texts=[str(conv.get(k+'_date_time',''))+'\n'+'\n'.join(t.get('speaker','')+': '+t.get('text','') for t in conv[k]) for k in keys]
    ix=Index(texts)
    histories.append(dict(dataset='LoCoMo',history_id=cid,sessions=len(ids),turns=sum(len(conv[k]) for k in keys),words=sum(map(words,texts))))
    for sid,t in zip(ids,texts):
        unique_sessions['LoCoMo'].add(cid+':'+sid);source_contents['LoCoMo'].add(hashlib.sha256(t.encode()).hexdigest())
    for qi,q in enumerate(c['qa']):
        # Gold dialogue IDs D<session>:<turn>; multiple IDs can share one string.
        gold={m for e in q.get('evidence',[]) for m in re.findall(r'D(\d+):\d+',e)}
        evaluate('LoCoMo',f'{cid}:{qi}',cid,cats.get(q['category'],str(q['category'])),q['question'],ids,texts,gold,q['category']==5,ix)
print('LoCoMo complete',len(questions),len(results),flush=True)

lme=json.loads((RAW/'longmemeval_s_cleaned.json').read_text())
for qi,q in enumerate(lme):
    ids=q['haystack_session_ids']
    duplicate_distractor_occurrences += len(ids)-len(set(ids))
    sessions=q['haystack_sessions']; dates=q['haystack_dates']
    assert len(ids)==len(sessions)==len(dates)
    for sid in set(ids):
        copies=[sess for key,sess in zip(ids,sessions) if key==sid]
        assert all(x==copies[0] for x in copies), 'Duplicate IDs with different content'
        assert len(copies)==1 or sid not in q['answer_session_ids'], 'Duplicate gold session'
    texts=[date+'\n'+'\n'.join(t['role']+': '+t['content'] for t in sess) for date,sess in zip(dates,sessions)]
    qid=q['question_id'];abstain=qid.endswith('_abs')
    category='Abstention' if abstain else q['question_type'].replace('-',' ').title()
    histories.append(dict(dataset='LongMemEval-S',history_id=qid,sessions=len(ids),turns=sum(map(len,sessions)),words=sum(map(words,texts))))
    for sid,sess in zip(ids,sessions):
        unique_sessions['LongMemEval-S'].add(sid)
        # Strip question-specific timestamps and gold flags when deduplicating content.
        content='\n'.join(t['role']+': '+t['content'] for t in sess)
        source_contents['LongMemEval-S'].add(hashlib.sha256(content.encode()).hexdigest())
    evaluate('LongMemEval-S',qid,qid,category,q['question'],ids,texts,set(q['answer_session_ids']),abstain,Index(texts))
    if qi%100==0:print('LongMemEval',qi,flush=True)
del lme

# Published repository scores, not results of our own model evaluation.
ruler=[]
for line in (RAW/'ruler_readme.md').read_text().splitlines():
    line=line.lstrip('|')
    if not line.startswith('[') or '](' not in line:continue
    fields=line.split('|')
    if len(fields)<4:continue
    first=fields[0]
    label, tail=first.split('](',1)
    depth=1
    for end,char in enumerate(tail):
        depth += (char=='(')-(char==')')
        if depth==0:break
    assert depth==0
    name=(label[1:]+tail[end+1:]).strip()
    if not re.fullmatch(r'\d+(?:\.\d+)?[kKmM]',fields[1].strip()):continue
    claimed_s=fields[1].strip().upper();claimed=float(claimed_s[:-1])*(1000 if claimed_s[-1]=='K' else 1000000)
    for i,length in enumerate([4000,8000,16000,32000,64000,128000]):
        if i+3>=len(fields):continue
        value=re.sub('<[^>]+>','',fields[i+3]).strip()
        if not re.fullmatch(r'\d+(?:\.\d+)?',value):continue
        score=float(value);assert 0<=score<=100
        ruler.append(dict(model=name.replace('*',''),community_reported='*' in first,claimed_tokens=claimed,
            tested_tokens=length,score=score,beyond_claim=length>claimed,effective_label=fields[2].strip()))
assert len(ruler)>100 and len({r['model'] for r in ruler})>15
assert len({(r['model'],r['tested_tokens']) for r in ruler})==len(ruler)
assert all(0<=r['recall']<=1 and r['selected_words']<=r['history_words'] for r in results)
counts=[]
for dataset in ['LoCoMo','LongMemEval-S']:
    q=[r for r in questions if r['dataset']==dataset];h=[r for r in histories if r['dataset']==dataset]
    counts.append(dict(dataset=dataset,questions=len(q),eligible=sum(r['eligible'] for r in q),
        abstention=sum(r['abstention'] for r in q),excluded=sum(not r['eligible'] for r in q),histories=len(h),
        session_appearances=sum(r['sessions'] for r in h),turn_appearances=sum(r['turns'] for r in h),
        unique_session_ids=len(unique_sessions[dataset]),unique_session_contents=len(source_contents[dataset]),
        words_with_repeated_histories=sum(r['words'] for r in h)))
for name,obj in [('retrieval_runs.json',results),('question_inventory.json',questions),('history_inventory.json',histories),('retrieval_exclusions.json',excluded),('ruler_scores.json',ruler),('benchmark_counts.json',counts)]:save(name,obj)
save('experiment_manifest.json',dict(study='Offline session retrieval audit',strategies=['BM25','Recent','Random'],
    budgets=[1,3,5,10],bm25_k1=1.5,bm25_b=.75,stopwords=sorted(STOP),seed='SHA256(dataset + question ID), first 16 hex digits',
    duplicate_distractor_occurrences_retained=duplicate_distractor_occurrences,rows=len(results),question_records=len(questions),ruler_cells=len(ruler),ruler_models=len({r['model'] for r in ruler}),
    elapsed_seconds=round(time.time()-start,2),llm_calls=0,metric='Fraction of labeled evidence sessions retained; not answer accuracy',
    text_scope='Text messages, roles/speakers, session dates. Image contents are not processed.',
    source_revision_file='data/raw/benchmark_sources.json'))
print(json.dumps(counts,indent=2));print('Retrieval rows',len(results),'RULER cells',len(ruler),flush=True)
