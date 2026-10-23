"""Bake twelve CC0 Kenney Nature/Pirate/Castle/Space pack meshes.
Run: blender -b -t 2 --python tools/build_modern_art.py
Source originals, palette textures and pinned hashes: assets/manifest.json.
"""
from pathlib import Path
import sys, json
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_environment import bake, write_catalog, OUTPUT
ITEMS = [
    ('modern_cave', 'rock', 600, 150, 60, 'Sandstone'),
    ('modern_rock', 'rock', 500, 100, 40, 'Sandstone'),
    ('modern_pinnacle', 'rock', 700, 140, 50, 'Slate'),
    ('modern_cliff', 'rock', 500, 100, 40, 'Sandstone'),
    ('modern_crystals_a', None, 1200, 240, 80, 'SmoothPlastic'),
    ('modern_crystals_b', None, 1200, 240, 80, 'SmoothPlastic'),
    ('modern_wreck', None, 2600, 650, 220, 'Wood'),
    ('modern_barrel', None, 700, 140, 60, 'Wood'),
    ('modern_cannon', None, 1000, 180, 70, 'Metal'),
    ('modern_arch', None, 1200, 180, 60, 'Sandstone'),
    ('modern_pillar', None, 800, 140, 50, 'Marble'),
    ('modern_stairs', None, 600, 120, 40, 'Sandstone'),
]
for key, mode, full, lod, far, mat in ITEMS:
    bake(key, 'Kenney_' + key + '.glb', mode, full, lod, far)
    p = OUTPUT / (key + '.json'); asset = json.loads(p.read_text()); asset['Material'] = mat
    if key.startswith('modern_crystals_'):
        gem = (68, 214, 255) if key.endswith('_a') else (184, 128, 255)
        stone = (43, 78, 116) if key.endswith('_a') else (53, 67, 107)
        for quality in ('Full', 'Lod', 'Far'):
            for rgb in asset[quality]['Colors']:
                target = gem if rgb[1] > rgb[0] + 25 else stone
                light = sum(rgb) / 3 / 205
                rgb[:] = [round(max(0, min(255, c * light))) for c in target]
    p.write_text(json.dumps(asset, separators=(',', ':')))
write_catalog()
print('Modern pack catalog written.', flush=True)
