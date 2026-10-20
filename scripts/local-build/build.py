#!/usr/bin/env python3
"""Build locally with Command Line Tools, reusing installed compiled assets."""
import pathlib, subprocess, shutil, json, sys
root = pathlib.Path(__file__).resolve().parents[2]
out = root / 'build/local'
out.mkdir(parents=True, exist_ok=True)
def run(args):
    subprocess.run([str(x) for x in args], cwd=root, check=True)
# Keep duplicate-module workaround local to this compiler invocation.
(out/'empty.modulemap').write_text('')
(out/'toolchain-overlay.json').write_text(json.dumps({'version': 0, 'roots': [
    {'type':'file', 'name':'/Library/Developer/CommandLineTools/usr/include/swift/module.modulemap',
     'external-contents': str(out/'empty.modulemap')}
]}))
run([sys.executable, root/'scripts/local-build/expand-models.py'])
sdk = subprocess.check_output(['xcrun', '--show-sdk-path'], text=True).strip()
common = ['-vfsoverlay', str(out/'toolchain-overlay.json'), '-module-cache-path', str(out/'module-cache'), '-sdk', sdk, '-target', 'arm64-apple-macosx26.0', '-swift-version', '5', '-O']
for module in ['LaunchNextContextMenuCore', 'LaunchNextWallpaperCore']:
    run(['xcrun', 'swiftc', *common, '-parse-as-library', '-emit-library', '-static', '-emit-module', '-module-name', module, '-emit-module-path', out / (module + '.swiftmodule'), *sorted((root/module).glob('*.swift')), '-o', out / ('lib'+module+'.a')])
framework = root/'LaunchNext/ThirdParty/OpenMultitouchSupport/Framework'
objects = []
for source in sorted(framework.rglob('*.m')):
    obj = out/(source.stem+'.o')
    run(['xcrun', 'clang', '-isysroot', sdk, '-target', 'arm64-apple-macosx26.0', '-fobjc-arc', '-fmodules', '-O2', '-I', framework, '-c', source, '-o', obj])
    objects.append(obj)
# The 26.2 SDK predates the optional macOS 27 menu image preference.
# Keep normal image assignment; AppKit chooses visibility on this local build.
menu = (root/'LaunchNext/RightClickMenu.swift').read_text()
new_api = """                if #available(macOS 27.0, *) {
                    item.preferredImageVisibility = .visible
                }
"""
assert menu.count(new_api) == 1
(out/'RightClickMenu.swift').write_text(menu.replace(new_api, ''))
run(['xcrun', 'swiftc', *common, '-parse-as-library', '-module-name', 'LaunchNext', '-whole-module-optimization', '-num-threads', '4', '-Xfrontend', '-solver-expression-time-threshold=120', '-Xfrontend', '-solver-memory-threshold', '-Xfrontend', '2147483648', '-default-isolation', 'MainActor', '-enable-upcoming-feature', 'NonisolatedNonsendingByDefault', '-enable-upcoming-feature', 'InferIsolatedConformances', '-enable-upcoming-feature', 'MemberImportVisibility', '-I', out, '-I', framework, '-F', '/System/Library/PrivateFrameworks', '-framework', 'MultitouchSupport', *[out/p.name if p.name in ['FolderInfo.swift', 'RightClickMenu.swift'] else p for p in sorted((root/'LaunchNext').rglob('*.swift'))], *objects, out/'libLaunchNextContextMenuCore.a', out/'libLaunchNextWallpaperCore.a', '-o', out/'LaunchNext'])
app = out/'LaunchNext.app'
if app.exists():
    shutil.rmtree(app)
run(['ditto', '/Applications/LaunchNext.app', app])
shutil.copy2(out/'LaunchNext', app/'Contents/MacOS/LaunchNext')
for loc in root.glob('*.lproj'):
    shutil.copytree(loc, app/'Contents/Resources'/loc.name, dirs_exist_ok=True)
run(['xattr', '-cr', app])
run(['codesign', '--force', '--deep', '--sign', '-', app])
run(['codesign', '--verify', '--deep', '--strict', app])
run(['ditto', '-c', '-k', '--keepParent', app, out/'LaunchNext-local.zip'])
print(app)
