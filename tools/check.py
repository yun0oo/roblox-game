#!/usr/bin/env python3
"""Offline checks for domain/services and Rojo artifacts. Does not simulate Studio."""
from pathlib import Path
import json
import os
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENV = dict(os.environ)
CLOUD_BIN = Path('/workspace/shared/roblox-cloud/bin')
if CLOUD_BIN.is_dir():
    ENV['PATH'] = str(CLOUD_BIN) + os.pathsep + ENV.get('PATH', '')
LOCAL_BIN = ROOT / '.tools/bin'
if LOCAL_BIN.is_dir():
    ENV['PATH'] = str(LOCAL_BIN) + os.pathsep + ENV.get('PATH', '')


def run(*args):
    print('+ ' + ' '.join(map(str, args)), flush=True)
    subprocess.run(list(map(str, args)), cwd=ROOT, env=ENV, check=True)


for tool in ('luau', 'luau-compile', 'luau-analyze', 'luau-lsp', 'rojo'):
    if not shutil.which(tool, path=ENV.get('PATH')):
        raise SystemExit(f'Missing {tool}: install the pinned tools described in README.md')

sources = sorted((ROOT / 'src').rglob('*.luau'))
run('luau-compile', '--null', *[str(p.relative_to(ROOT)) for p in sources])
run('luau-analyze', 'src/shared/Rules.luau', 'src/shared/Config.luau', 'tests/rules.spec.luau', 'tests/progression.spec.luau')
run('luau', 'tests/rules.spec.luau')
run('luau', 'tests/progression.spec.luau')
run('python3', 'tools/check_art.py')
for suite in ('services', 'startup'):
    module_sources = []
    if suite == 'services':
        for name in ('World', 'EggSystem', 'HarpoonSystem', 'DataSystem', 'GuardianSystem', 'EventSystem'):
            body = (ROOT / 'src/server' / (name + '.luau')).read_text()
            module_sources.append(f'local {name} = (function()\n{body}\nend)()\n')
    else:
        for path in sources:
            if path.parent.name == 'client' or path.name.endswith('.server.luau'):
                continue
            module_sources.append(f'factories["{path.stem}"] = function()\n{path.read_text()}\nend\n')
    harness = (ROOT / f'tests/{suite}.spec.luau').read_text().replace('--[[ MODULES ]]', '\n'.join(module_sources))
    harness = harness.replace('--[[ MAIN ]]', (ROOT / 'src/server/Main.server.luau').read_text())
    with tempfile.NamedTemporaryFile(mode='w', suffix='.luau', prefix='.runtime-', dir=ROOT / 'tests', delete=False) as generated:
        generated.write(harness)
        generated_path = Path(generated.name)
    try:
        run('luau', str(generated_path.relative_to(ROOT)))
    finally:
        generated_path.unlink()

tree = json.loads((ROOT / 'default.project.json').read_text())['tree']
assert tree['Players']['$properties']['CharacterAutoLoads'] is True
assert tree['Workspace']['Arrivee']['$className'] == 'SpawnLocation'
# Runtime scripts cannot write this Studio-only property. The built place must
# already allow avatars/eggs to reach the bottom of the deepest configured floor.
assert tree['Workspace']['$properties']['FallenPartsDestroyHeight'] <= -2246

build = ROOT / 'build'
build.mkdir(exist_ok=True)
run('rojo', 'build', 'default.project.json', '--output', 'build/UnderwaterEgg.rbxlx')
run('rojo', 'build', 'default.project.json', '--output', 'build/UnderwaterEgg.rbxl')
run('rojo', 'sourcemap', 'default.project.json', '--output', 'build/sourcemap.json')
definitions = ROOT / '.tools/globalTypes.d.luau'
if not definitions.is_file():
    definitions = CLOUD_BIN.parent / 'globalTypes.d.luau'
if not definitions.is_file():
    raise SystemExit('Missing Roblox API definitions. Run python3 tools/bootstrap.py')
run('luau-lsp', 'analyze', '--platform=roblox', '--definitions=' + str(definitions),
    '--sourcemap=build/sourcemap.json', *[str(p.relative_to(ROOT)) for p in sources])
document = ET.parse(build / 'UnderwaterEgg.rbxlx').getroot()
scripts = [item for item in document.iter('Item') if item.get('class') in ('Script', 'LocalScript', 'ModuleScript')]
assert len(scripts) == len(sources), f'Expected {len(sources)} scripts, got {len(scripts)}'
bundled = {node.text.strip() for node in document.iter() if node.get('name') == 'Source' and node.text}
for source in sources:
    assert source.read_text().strip() in bundled, f'Source missing from build: {source}'
assert (build / 'UnderwaterEgg.rbxl').read_bytes().startswith(b'<roblox!')
with zipfile.ZipFile(build / 'UnderwaterEgg-project.zip', 'w', zipfile.ZIP_DEFLATED) as package:
    for entry in ('README.md', '.gitignore', 'default.project.json', 'src', 'tests', 'tools', 'assets', 'docs', '.github'):
        path = ROOT / entry
        paths = [path] if path.is_file() else sorted(path.rglob('*'))
        for source in paths:
            if source.is_file() and '__pycache__' not in source.parts and not source.name.startswith('.runtime-'):
                package.write(source, 'UnderwaterEgg/' + source.relative_to(ROOT).as_posix())
    for name in ('UnderwaterEgg.rbxl', 'UnderwaterEgg.rbxlx'):
        package.write(build / name, 'UnderwaterEgg/build/' + name)
print(f'PASS: {len(sources)} Luau sources compiled; rules/services passed; both place files verified.')
print('Export: build/UnderwaterEgg-project.zip (sources, docs, tests, and place files)')
print('Roblox Studio multiplayer, rendering, and live DataStore checks remain manual.')
