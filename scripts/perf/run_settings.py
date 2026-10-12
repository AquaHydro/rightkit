#!/usr/bin/env python3
"""Isolated Release settings baseline/working-tree probe and production-window preview.

python3 scripts/perf/run_settings.py --baseline 0470610 --rounds 20
python3 scripts/perf/run_settings.py --interactive --variant working
python3 scripts/perf/run_settings.py --variant working --e2e --inactive --rounds 1 --output .build/settings-e2e

Builds only in .build/settings-performance, uses private preferences and in-memory
SharedStore, never runs RightKit's app delegate/agent/extension or installed config.
The baseline is extracted from git, not maintained as a duplicate source tree.
Measured time ends at layout/display return, not compositor presentation. Both
variants use a real SwiftUI Window including the production toolbar.
"""
import argparse
import io
import hashlib
import json
import os
import signal
import plistlib
import re
import shutil
import statistics
import subprocess
import tarfile
import uuid
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--baseline', default='HEAD')
parser.add_argument('--rounds', type=int, default=20)
parser.add_argument('--variant', choices=['both', 'baseline', 'working'], default='both')
parser.add_argument('--interactive', action='store_true')
parser.add_argument('--inactive', action='store_true', help='E2E opening requests remain inactive (working e2e only)')
parser.add_argument('--e2e', action='store_true', help='Verify real window lifecycle and deterministic import component integration (working variant only)')
parser.add_argument('--build-only', action='store_true')
parser.add_argument('--no-build', action='store_true')
parser.add_argument('--output', type=Path, default=ROOT / '.build/settings-performance')
args = parser.parse_args()
if args.rounds < 1:
    parser.error('--rounds must be positive')
if args.interactive and args.variant == 'both':
    args.variant = 'working'
if args.inactive and not args.e2e:
    parser.error('--inactive requires --e2e')
if args.e2e and (args.interactive or args.variant != 'working'):
    parser.error('--e2e requires --variant working and non-interactive execution')
output = args.output.resolve()
output.mkdir(parents=True, exist_ok=True)
baseline = subprocess.check_output(['git', 'rev-parse', args.baseline], cwd=ROOT, text=True).strip()
variants = ['baseline', 'working'] if args.variant == 'both' else [args.variant]
paths = ['Packages/RightKitCore', 'RightKit/Views/Settings', 'RightKit/Views/WelcomeView.swift',
         'RightKit/App/AppModel.swift', 'RightKit/App/WindowOpener.swift',
         'RightKit/Services/Alerts.swift', 'RightKit/Services/TemplateLibrary.swift',
         'RightKit/Engine', 'RightKit/Resources/Assets.xcassets']

def instrument(path, text):
    if path.name == 'SettingsView.swift':
        needle = '@AppStorage("settingsTab")'
        if needle not in text:
            raise RuntimeError('SettingsView settingsTab storage interface changed')
        text = text.replace(needle, '@AppStorage("settingsTab", store: ProbeMetric.defaults)')
        # Observe the real production tab instead of replacing its state model.
        text = text.replace('.id(model.settings.language)',
                            '.onChange(of: tab, initial: true) { _, value in ProbeMetric.displayedTab = value.rawValue }\n        .id(model.settings.language)', 1)
    if path.name in ['GeneralPane.swift', 'NewFilePane.swift', 'OpenInPane.swift', 'FoldersPane.swift', 'ToolboxPane.swift']:
        text = text.replace('var body: some View {',
                            'var body: some View {\n        let _ = ProbeMetric.mark("' + path.stem + '")', 1)
    if args.e2e and path.name == 'NewFilePane.swift':
        # Bypass only the two modal input panels. Run the unchanged production
        # import Task, cancellation catches, commit and defer cleanup below them.
        text = text.replace('let _ = ProbeMetric.mark("NewFilePane")',
                            'let _ = ProbeMetric.mark("NewFilePane")\n        let _ = { ProbeMetric.startTemplateImport = { addTemplate() } }()')
        start = text.index('        let panel = NSOpenPanel()', text.index('private func addTemplate()'))
        end = text.index('        guard activity.importTask == nil', start)
        text = text[:start] + '        let url = ProbeMetric.importSource\n        let name = "E2E fixture"\n' + text[end:]
        text = text.replace('TemplateLibrary.importTemplate(from: url, name: name)',
                            'TemplateLibrary.importTemplate(from: url, name: name, into: TemplateLibrary.directory, _beforeReturningForTesting: { await ProbeMetric.pauseImport() })')
    if args.e2e and path.name == 'WindowOpener.swift':
        # Exercise production SwiftUI presentation when activation is refused.
        text = text.replace('Alerts.bringToFront()', '/* isolated non-activating opening request */')
    # Only wrap existing render-time queries, no substitute values or cache changes.
    replacements = {
        'NSWorkspace.shared.icon(forFile: path)': 'ProbeMetric.measure("fileIcon") { NSWorkspace.shared.icon(forFile: path) }',
        'NSWorkspace.shared.icon(for: UTType(filenameExtension: fileExtension) ?? .data)': 'ProbeMetric.measure("typeIcon") { NSWorkspace.shared.icon(for: UTType(filenameExtension: fileExtension) ?? .data) }',
        'FolderStore.refreshed(entry)': 'ProbeMetric.measure("folderRefresh") { FolderStore.refreshed(entry) }',
        'FolderStore.state(refreshed)': 'ProbeMetric.measure("folderState") { FolderStore.state(refreshed) }',
        'FolderStore.displayName(refreshed)': 'ProbeMetric.measure("folderName") { FolderStore.displayName(refreshed) }',
        'OpenToolDetector.appURL(tool.bundleID)': 'ProbeMetric.measure("appURL") { OpenToolDetector.appURL(tool.bundleID) }',
    }
    if 'Views/Settings' in str(path):
        for needle, replacement in replacements.items():
            text = text.replace(needle, replacement)
        text = text.replace('let exists = state == .available',
                            'let _ = ProbeMetric.recordFolder(refreshed.path, state: state)\n        let exists = state == .available')
    return text

for variant in variants:
    directory = output / variant
    app = directory / 'SettingsProbe.app'
    executable = app / 'Contents/MacOS/SettingsProbe'
    manifest_path = directory / 'build.json'
    if args.no_build:
        if not executable.exists():
            raise SystemExit(f'Missing {executable}; build first')
        if not manifest_path.exists():
            raise SystemExit(f'Missing build manifest {manifest_path}; rebuild once')
        manifest = json.loads(manifest_path.read_text())
        if manifest.get('e2e', False) != args.e2e:
            raise SystemExit('Probe mode changed; rebuild before --no-build')
        if manifest['driver_sha256'] != hashlib.sha256((ROOT / 'scripts/perf/settings_probe.swift').read_bytes()).hexdigest():
            raise SystemExit('Probe driver changed; rebuild before --no-build')
        if variant == 'baseline' and manifest['baseline_commit'] != baseline:
            raise SystemExit('Baseline commit changed; rebuild before --no-build')
        if variant == 'working':
            for name, expected in manifest['source_sha256'].items():
                path = ROOT / name
                if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
                    raise SystemExit(f'Working source changed: {name}; rebuild before --no-build')
        continue
    source = directory / 'sources'
    if source.exists():
        shutil.rmtree(source)
    source.mkdir(parents=True)
    if variant == 'baseline':
        archive = subprocess.check_output(['git', 'archive', baseline, *paths], cwd=ROOT)
        with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
            tar.extractall(source, filter='data')
    else:
        for name in paths:
            src, dest = ROOT / name, source / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            if src.is_dir():
                shutil.copytree(src, dest)
            else:
                shutil.copy2(src, dest)
    subprocess.run(['swift', 'build', '-c', 'release', '--package-path', str(source / 'Packages/RightKitCore'),
                    '--scratch-path', str(directory / 'core')], check=True, cwd=ROOT)
    objects = list((directory / 'core').rglob('RightKitCore.o'))
    if len(objects) != 1:
        raise RuntimeError(f'Expected one Release core object: {objects}')
    products = objects[0].parent
    sources = [source / name for name in paths if name.endswith('.swift')]
    sources += sorted((source / 'RightKit/Views/Settings').glob('*.swift'))
    sources += sorted((source / 'RightKit/Engine').glob('*.swift'))
    source_hashes = {str(path.relative_to(source)): hashlib.sha256(path.read_bytes()).hexdigest() for path in sources}
    for path in sources:
        path.write_text(instrument(path, path.read_text()))
    executable.parent.mkdir(parents=True, exist_ok=True)
    resources = app / 'Contents/Resources'
    resources.mkdir(exist_ok=True)
    identity = 'app.rightkit.settings-probe.' + variant
    (app / 'Contents/Info.plist').write_bytes(plistlib.dumps({
        'CFBundleIdentifier': identity, 'CFBundleName': 'RightKit Settings Probe',
        'CFBundleExecutable': executable.name, 'CFBundlePackageType': 'APPL',
        'RKAppBundleID': identity, 'RKAppGroup': identity, 'RKURLScheme': 'rightkit-settings-probe',
        'LSUIElement': True,
    }))
    shutil.copytree(products / 'RightKitCore_RightKitCore.bundle',
                    resources / 'RightKitCore_RightKitCore.bundle', dirs_exist_ok=True)
    subprocess.run(['xcrun', 'actool', '--compile', str(resources), '--platform', 'macosx',
                    '--minimum-deployment-target', '26.0',
                    str(source / 'RightKit/Resources/Assets.xcassets')], check=True, cwd=ROOT)
    subprocess.run(['xcrun', 'swiftc', '-O', '-parse-as-library', '-D', 'APP_STORE',
                    '-I', str(products), *map(str, sources),
                    str(ROOT / 'scripts/perf/settings_probe.swift'), str(objects[0]),
                    '-o', str(executable)], check=True, cwd=ROOT)
    subprocess.run(['codesign', '--force', '--sign', '-', str(app)], check=True)
    manifest_path.write_text(json.dumps({'baseline_commit': baseline, 'variant': variant, 'e2e': args.e2e,
                                       'source_sha256': source_hashes,
                                       'driver_sha256': hashlib.sha256((ROOT / 'scripts/perf/settings_probe.swift').read_bytes()).hexdigest()}, indent=2))

if not args.build_only:
    # Build both first, then run serially to avoid compiler/process contention.
    if not args.interactive:
        (output / 'summary.json').unlink(missing_ok=True)
    for variant in variants:
        if not args.interactive:
            (output / (variant + '.json')).unlink(missing_ok=True)
        executable = output / variant / 'SettingsProbe.app/Contents/MacOS/SettingsProbe'
        command = [str(executable), '--output', str(output / (variant + '.json')),
                   '--rounds', str(args.rounds), '--suite', 'app.rightkit.settings-probe.' + uuid.uuid4().hex]
        if args.e2e:
            command.append('--e2e')
        if args.inactive:
            command.append('--diagnose-inactive')
        if args.interactive:
            subprocess.run(['open', '-n', str(executable.parents[2]), '--args', *command[1:], '--interactive'], check=True)
            print(executable.parents[2])
        else:
            with (output / (variant + '.log')).open('w') as log:
                process = subprocess.Popen(['/usr/bin/time', '-l', *command], stdout=log,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    status = process.wait(timeout=max(90, args.rounds * 4))
                except (subprocess.TimeoutExpired, KeyboardInterrupt):
                    os.killpg(process.pid, signal.SIGTERM)
                    try:
                        process.wait(timeout=5)
                    except subprocess.TimeoutExpired:
                        os.killpg(process.pid, signal.SIGKILL)
                        process.wait()
                    raise
                if status:
                    raise SystemExit(f'{variant} exited {status}; inspect {output / (variant + chr(46) + "log")}')
    if not args.interactive:
        summary = {'baseline_commit': baseline, 'rounds_per_page': args.rounds, 'variants': {}}
        for variant in variants:
            data = json.loads((output / (variant + '.json')).read_text())
            if data.get('succeeded') is not True:
                raise SystemExit(f'{variant} failed checks; inspect {output / (variant + chr(46) + "json")}')
            pages = {}
            for tab in ['general', 'newFile', 'openIn', 'folders', 'toolbox']:
                first = [s for s in data['samples'] if s['tab'] == tab and s['round'] == 0]
                hot = [s for s in data['samples'] if s['tab'] == tab and s['round'] > 0]
                pages[tab] = {'first_ms': first[0]['layout_display_ms'] if first else None,
                              'hot_p50_ms': statistics.median(s['layout_display_ms'] for s in hot),
                              'hot_query_p50_ms': statistics.median(sum(s['query_ms'].values()) for s in hot)}
            rss = re.search(r'(\d+)  maximum resident set size', (output / (variant + '.log')).read_text())
            summary['variants'][variant] = {'pages': pages, 'assertions': data['assertions'],
                                              'max_rss_mib': int(rss[1]) / 1024**2 if rss else None,
                                              'window_content_size': data['window_content_size']}
        (output / 'summary.json').write_text(json.dumps(summary, indent=2))
        print(json.dumps(summary, indent=2))
