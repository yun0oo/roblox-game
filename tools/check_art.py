"""Validate checked-in geometry, provenance, and asymmetric egg silhouette."""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT/'assets/manifest.json').read_text())
for source in manifest['sources']:
    assert source['license'] in ('CC0-1.0', 'CC-BY-3.0', 'BSD-3-Clause')
    if source['license'] == 'CC-BY-3.0':
        assert source['author'] and source['source'].startswith('https://poly.pizza/')
        assert (ROOT/'assets/source/PolyPizza.CC-BY-3.0.txt').is_file()
    if source['license'] == 'BSD-3-Clause':
        assert (ROOT/'assets/source/Aquarium.LICENSE.md').is_file()
    assert hashlib.sha256((ROOT/'assets/source'/source['file']).read_bytes()).hexdigest() == source['sha256']

assets = {}
for path in sorted((ROOT/'assets/generated').glob('*.json')):
    data = json.loads(path.read_text()); assets[path.stem] = data
    for name in (('Full', 'Lod', 'Far') if data['Kind'] == 'environment' else ('Full','Lod')):
        mesh = data[name]
        assert len(mesh['Faces']) == len(mesh['Colors']) > 0
        limit = (4500 if name == 'Full' else 2100) if data['Kind'] == 'licensed' else (2200 if name == 'Full' else (1200 if data['Kind'] == 'creature' else 800))
        if data['Kind'] == 'environment': limit = {'Full': 6500, 'Lod': 1500, 'Far': 600}[name]
        assert len(mesh['Faces']) <= limit, (path.stem, name, len(mesh['Faces']))
        if data['Kind'] == 'environment':
            assert len(mesh['Normals']) == len(mesh['Vertices'])
            assert any(s['file'] == data['Source'] for s in manifest['sources'])
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
print(f'Art: {len(assets)} models validated; licensed source hashes, scenery budgets and ovoid shape verified.')
