# Local build without Xcode

Verified environment: arm64, Command Line Tools Swift 6.2.3 / macOS 26.2 SDK. An existing `/Applications/LaunchNext.app` is required for compiled resources:

```sh
python3 scripts/local-build/build.py
```

Output: `build/local/LaunchNext.app`. This script does **not** install the app or push Git changes.

The CLT lacks SwiftDataMacros. `expand-models.py` generates explicit PersistentModel/Observable implementations for this project's two models into ignored build intermediates. The normal `FolderInfo.swift` and Xcode build retain their original macros. A compiler-local VFS overlay hides the CLT's duplicate SwiftBridging module declaration. Nothing in the system toolchain is edited.

This local build reuses compiled assets and updater resources from `/Applications/LaunchNext.app`, replaces the executable, copies repository localizations, and applies an ad-hoc signature. It is a local arm64 build, not an upstream notarized release.

Validation performed on 2026-10-21: save/update/reopen for both models, nullable pinned-app array, reading a SQLite backup of the existing store, and checking all existing layout fields survived. The fork's current optional `pinnedAppPaths` differs from the installed older schema; migration was tested only on a copy before installation. Keep the original application and data backups for rollback.

Re-run the isolated persistence smoke test after building:

```sh
xcrun swiftc -vfsoverlay build/local/toolchain-overlay.json \
  -module-cache-path build/local/module-cache -swift-version 5 \
  -module-name LaunchNext -parse-as-library build/local/Models.swift \
  scripts/local-build/model-check.swift -o build/local/model-check
# Use a fresh disposable store path for every test run.
build/local/model-check /tmp/launchnext-test-new.store write
build/local/model-check /tmp/launchnext-test-new.store verify
```

SDK compatibility: the local build omits only the macOS 27 `preferredImageVisibility = .visible` menu preference from a temporary copy of `RightClickMenu.swift`. The menu images remain assigned; AppKit chooses whether to display them. The normal Xcode source retains that API. Long SwiftUI event modifier chains were split into computed properties without changing their order to support the CLT compiler.

Installation verification included matching the installed executable to the built app, strict signature checks, two-line label display, and preservation of existing layout data. Keep application, settings and data backups outside the repository before replacing an installed copy. A ZIP of the local app is also saved to `build/local/LaunchNext-local.zip` to avoid cloud-sync FinderInfo changes to loose app bundles.
