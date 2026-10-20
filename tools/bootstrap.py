#!/usr/bin/env python3
"""Install the pinned Linux toolchain with TLS and SHA-256 verification."""
from pathlib import Path
import hashlib
import io
import json
import platform
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
if platform.system() != 'Linux' or platform.machine() != 'x86_64':
    raise SystemExit('This bootstrap targets Linux x86_64. On Windows/macOS, open the built place in Studio or install the matching native tools manually.')
target = ROOT / '.tools'
(target / 'bin').mkdir(parents=True, exist_ok=True)
(target / 'downloads').mkdir(exist_ok=True)
manifest = json.loads((ROOT / 'tools/toolchain.json').read_text())
for artifact in manifest['artifacts']:
    cache = target / 'downloads' / artifact['url'].rsplit('/', 1)[1]
    data = cache.read_bytes() if cache.exists() else b''
    if hashlib.sha256(data).hexdigest() != artifact['sha256']:
        print('Downloading ' + artifact['name'] + ' ' + artifact['version'], flush=True)
        with urllib.request.urlopen(artifact['url'], timeout=60) as response:
            data = response.read()
        if hashlib.sha256(data).hexdigest() != artifact['sha256']:
            raise SystemExit('Checksum mismatch: ' + artifact['name'])
        cache.write_bytes(data)
    if 'file' in artifact:
        (target / artifact['file']).write_bytes(data)
    else:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            for binary in artifact['binaries']:
                members = [name for name in archive.namelist() if Path(name).name == binary]
                if len(members) != 1:
                    raise SystemExit('Ambiguous or missing archive binary: ' + binary)
                destination = target / 'bin' / binary
                destination.write_bytes(archive.read(members[0]))
                destination.chmod(0o755)
    print('Verified ' + artifact['name'] + ' ' + artifact['version'], flush=True)
print('Installed in .tools/. Run: python3 tools/check.py')
