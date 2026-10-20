"""Validate checked-in geometry, provenance, and asymmetric egg silhouette."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT/'assets/manifest.json').read_text())
for source in manifest['sources']:
    assert source['license'] == 'CC0-1.0'
    assert hashlib.sha256((ROOT/'assets/source'/source['file']).read_bytes()).hexdigest() == source['sha256']

assets = {}
for path in sorted((ROOT/'assets/generated').glob('*.json')):
    data = json.loads(path.read_text()); assets[path.stem] = data
    for name in ('Full','Lod'):
        mesh = data[name]
        assert len(mesh['Faces']) == len(mesh['Colors']) > 0
        limit = (4500 if name == 'Full' else 2100) if data['Kind'] == 'licensed' else (2200 if name == 'Full' else (1200 if data['Kind'] == 'creature' else 800))
        assert len(mesh['Faces']) <= limit
        assert all(math.isfinite(x) for p in mesh['Vertices'] for x in p)
        assert all(0 <= x <= 255 for c in mesh['Colors'] for x in c)
        for face in mesh['Faces']:
            assert len(face)==3 and len(set(face))==3
            assert all(1 <= i <= len(mesh['Vertices']) for i in face)
        assert all(x > 0 for x in mesh['Bounds'])
    assert len(data['Full']['Faces']) >= len(data['Lod']['Faces'])
assert {'egg','fish','harpoon','kraken','leviathan','dragon','scylla','charybdis'} <= assets.keys()
egg = assets['egg']['Full']['Vertices']
lower = max(abs(p[0]) for p in egg if -.4 < p[1] < -.2)
upper = max(abs(p[0]) for p in egg if .2 < p[1] < .4)
assert lower > upper * 1.08, 'Egg must have a broad bottom and a tapered top'
assert abs(assets['egg']['Full']['Bounds'][1]-1.25) < .02
print(f'Art: {len(assets)} models validated; CC0 source hashes and ovoid shape verified.')
