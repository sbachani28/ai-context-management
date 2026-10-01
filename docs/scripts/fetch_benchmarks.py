"""Re-download the pinned public benchmark files and verify their hashes."""
from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[1]/'data/raw'
for row in json.loads((root/'benchmark_sources.json').read_text()):
    dest=root/row['file']
    if not dest.exists():
        subprocess.run(['curl','--fail','--location','--retry','2',row['url'],'-o',str(dest)],check=True)
    assert hashlib.sha256(dest.read_bytes()).hexdigest()==row['sha256'],f'Hash mismatch: {dest}'
    print('Verified',row['file'])
