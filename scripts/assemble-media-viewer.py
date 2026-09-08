"""Combine the three native build artifacts into the web-rad-media contract."""
import hashlib
import json
import io
import pathlib
import os
import sys
import zipfile

source, output = map(pathlib.Path, sys.argv[1:3])
files = {}
with zipfile.ZipFile(source / 'windows-x86-64.zip') as z:
    for name in z.namelist():
        if not name.endswith('/'):
            path = pathlib.PurePosixPath(name)
            if path.is_absolute() or '..' in path.parts or path.parts[0] != 'windows-x86-64':
                raise ValueError(f'Invalid Windows path: {name}')
            files[name] = z.read(name)
for arch in ('macosx-x86-64', 'macosx-aarch64'):
    data = (source / f'{arch}.zip').read_bytes()
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        for member in ('Contents/MacOS/WebRad Viewer', 'Contents/app/WebRad Viewer.cfg',
                       'Contents/runtime/Contents/Home/lib/server/libjvm.dylib'):
            z.getinfo('WebRad Viewer.app/' + member)
        if z.testzip() is not None:
            raise ValueError(f'Corrupt Mac archive: {arch}')
    files[f'{arch}.zip'] = data
for required in ('WebRad Viewer.exe', 'app/WebRad Viewer.cfg', 'runtime/bin/server/jvm.dll'):
    if f'windows-x86-64/{required}' not in files:
        raise ValueError(f'Missing Windows file: {required}')
manifest = {'schema_version': 1, 'product': 'WebRad Viewer',
            'source_revision': os.environ.get('GITHUB_SHA', 'local'), 'files': {
    name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())}}
output.parent.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr('viewer-manifest.json', json.dumps(manifest, indent=2) + '\n')
    for name, data in files.items(): z.writestr(name, data)
output.with_suffix(output.suffix + '.sha256').write_text(
    hashlib.sha256(output.read_bytes()).hexdigest() + '  ' + output.name + '\n')
print(output)
