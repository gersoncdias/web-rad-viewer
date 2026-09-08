"""Exercise packaging orchestration without native JDKs (also runs with Bash 3.2)."""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parent.parent
BASH = os.environ.get('TEST_BASH', shutil.which('bash'))


class NativePackagingTest(unittest.TestCase):
    def run_build(self, system, machine, missing_archive=False):
        with tempfile.TemporaryDirectory(prefix='webrad packaging ') as directory:
            root = Path(directory)
            scripts = root / 'scripts'
            scripts.mkdir()
            shutil.copy(ROOT / 'scripts/build-media-viewer.sh', scripts)
            resources = root / 'weasis-distributions/script'
            resources.mkdir(parents=True)
            shutil.copy(ROOT / 'weasis-distributions/script/launch-options.sh', resources)
            (resources / 'resources/windows').mkdir(parents=True)
            (resources / 'resources/windows/Weasis.ico').write_bytes(b'fixture')
            # Deliberately no macOS icon: this was the failing branch under Bash 3.2.
            for name in ('LICENSE', '3rd-party-licenses.md'):
                (root / name).write_text('fixture license')
            payload = root / 'input/bin-dist/weasis/bundle'
            payload.mkdir(parents=True)
            (root / 'input/bin-dist/Licence.txt').write_text('fixture license')
            props = root / 'input/build/script'
            props.mkdir(parents=True)
            (props / 'build.properties').write_text('weasis.version=4.7.4-SNAPSHOT\n')
            commands = root / 'commands'
            commands.mkdir()
            (commands / 'python').symlink_to(sys.executable)
            stubs = {
                'uname': f'#!/bin/sh\ncase "$1" in -s) echo {system};; -m) echo {machine};; esac\n',
                'jpackage': '''#!/usr/bin/env python3
import pathlib, sys
p = pathlib.Path(sys.argv[sys.argv.index('--dest') + 1])
for name in ['WebRad Viewer.app/Contents/MacOS/WebRad Viewer', 'WebRad Viewer/WebRad Viewer.exe']:
    f = p / name
    f.parent.mkdir(parents=True, exist_ok=True)
    f.write_text('fixture')
''',
                'ditto': '''#!/usr/bin/env python3
import os, sys, zipfile
if not os.environ.get('TEST_MISSING_ARCHIVE'):
    with zipfile.ZipFile(sys.argv[-1], 'w') as z:
        z.writestr('WebRad Viewer.app/Contents/MacOS/WebRad Viewer', 'fixture')
''',
            }
            for name, data in stubs.items():
                command = commands / name
                command.write_text(data)
                command.chmod(0o755)
            env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ['PATH'])
            if missing_archive:
                env['TEST_MISSING_ARCHIVE'] = '1'
            output = root / 'native-output'
            result = subprocess.run([BASH, str(scripts / 'build-media-viewer.sh'),
                                     str(root / 'input'), str(output)], env=env,
                                    text=True, capture_output=True)
            if missing_archive:
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                return
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            arch = ('windows-x86-64' if system.startswith('MINGW') else
                    'macosx-aarch64' if machine == 'arm64' else 'macosx-x86-64')
            archive = output / f'{arch}.zip'
            self.assertTrue(archive.is_file(), result.stdout + result.stderr)
            with zipfile.ZipFile(archive) as z:
                self.assertIsNone(z.testzip())

    def test_mac_intel_without_icon(self):
        self.run_build('Darwin', 'x86_64')

    def test_mac_arm_without_icon(self):
        self.run_build('Darwin', 'arm64')

    def test_windows_with_icon(self):
        self.run_build('MINGW64_NT', 'x86_64')

    def test_missing_mac_archive_fails_during_build(self):
        self.run_build('Darwin', 'arm64', missing_archive=True)


if __name__ == '__main__':
    unittest.main()
