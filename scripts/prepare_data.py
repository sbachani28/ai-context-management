"""Build a documented SQL research table from the archived catalog. No network calls."""
import json, sqlite3, pathlib, hashlib
ROOT = pathlib.Path(__file__).resolve().parents[1]
rawpath = ROOT/'data/raw/model_snapshot_raw.json'
raw = json.loads(rawpath.read_text())['data']
providers = {x['openrouter_model_namespace']:x['company'] for x in json.loads((ROOT/'data/raw/provider_registry.json').read_text())}
db = sqlite3.connect(ROOT/'data/processed/research.sqlite')
db.execute('DROP TABLE IF EXISTS model_listing')
db.execute('CREATE TABLE model_listing (model_id TEXT PRIMARY KEY, canonical_slug TEXT, company TEXT, context_tokens INTEGER, input_price REAL, output_price REAL, image_input INTEGER, text_output INTEGER, has_price_overrides INTEGER)')
def price(m, key):
    v=m.get('pricing',{}).get(key)
    return float(v)*1000000 if v is not None and float(v)>=0 else None
rows=[]
for m in raw:
    ns=m['id'].split('/')[0]
    if ns not in providers: continue
    a=m.get('architecture',{})
    rows.append((m['id'],m.get('canonical_slug') or m['id'],providers[ns],m.get('context_length'),price(m,'prompt'),price(m,'completion'),int('image' in a.get('input_modalities',[])),int(a.get('output_modalities',[])==['text']),int(bool(m.get('pricing',{}).get('overrides')))))
db.executemany('INSERT INTO model_listing VALUES (?,?,?,?,?,?,?,?,?)',rows)
db.commit()
query='''SELECT * FROM model_listing ORDER BY company, model_id'''
cursor=db.execute(query)
names=[d[0] for d in cursor.description]
data=[dict(zip(names,r)) for r in cursor.fetchall()]
(ROOT/'data/processed/models.json').write_text(json.dumps(data,indent=2))
manifest={'source':'https://openrouter.ai/api/v1/models','retrieved_at_utc':json.loads((ROOT/'data/raw/snapshot_summary.json').read_text())['observed_at_utc'],'raw_sha256':hashlib.sha256(rawpath.read_bytes()).hexdigest(),'raw_rows':len(raw),'selected_rows':len(rows),'companies':len(set(r[2] for r in rows)),'sql':query,'units':'Prices are USD per million tokens; observed routing base prices, not full invoices.','scope':'Single archived snapshot. No historical company-month panel yet.'}
(ROOT/'data/processed/manifest.json').write_text(json.dumps(manifest,indent=2))
db.close()
print(json.dumps(manifest,indent=2))
