"""Bake the bundled Kenney CC0 ship cargo and slimmer speargun receiver.
Run: blender -b -t 2 --python tools/build_ship_art.py
Source models and hashes: assets/manifest.json. Never imports model scripts.
"""
from pathlib import Path
import sys, json
sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_environment import bake, write_catalog, OUTPUT

bake('ship_cargo', 'KenneyCargo.glb', None, 900, 240, 80)
bake('harpoon', 'KenneySpeargun.glb', None, 1800, 500, 160)
p = OUTPUT / 'harpoon.json'
asset = json.loads(p.read_text())
asset['Kind'] = 'weapon'
# Preserve the imported authored geometry; give the receiver an ocean palette.
for level in ('Full', 'Lod', 'Far'):
    for rgb in asset[level]['Colors']:
        if rgb[0] > rgb[2] * 1.3 and rgb[1] > rgb[2] * 1.2:
            rgb[:] = [32, 133, 167]
p.write_text(json.dumps(asset, separators=(',', ':')))
write_catalog()
print('Ship props and harpoon catalog written.', flush=True)
