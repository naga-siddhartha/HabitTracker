# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

HabitTracker (display name "Habits") is a native Apple platform habit tracking app built with Swift, SwiftUI, and SwiftData. It targets iOS 17.6+, macOS 14.0+, and visionOS 26.2+. The project is a single Xcode project (`HabitTracker.xcodeproj`) with four targets: the main app, unit tests, UI tests, and a widget extension. There are zero third-party dependencies — all frameworks are Apple-provided.

### Build & Run (requires macOS + Xcode)

Building, running, and executing XCTest-based tests require **macOS with Xcode** (the project uses `.xcodeproj`, not `Package.swift`). These operations **cannot** be performed on Linux.

On macOS:
- **Build:** `xcodebuild -project HabitTracker.xcodeproj -scheme HabitTracker -sdk iphonesimulator build`
- **Unit tests:** `xcodebuild -project HabitTracker.xcodeproj -scheme HabitTracker -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' test`
- **UI tests:** Same command; UI tests are in `HabitTrackerUITests/`

### Lint (works on Linux)

SwiftLint is used for linting and runs on Linux with the Swift toolchain installed:

```bash
export LINUX_SOURCEKIT_LIB_PATH=$HOME/.local/share/swiftly/toolchains/$(swiftly use --print-location 2>/dev/null | xargs -I{} basename {})/usr/lib
swiftlint lint
```

If `swiftly` is not available, set `LINUX_SOURCEKIT_LIB_PATH` to the directory containing `libsourcekitdInProc.so` from the installed Swift toolchain.

### Syntax Validation (works on Linux)

Individual Swift files can be syntax-checked on Linux using:
```bash
swiftc -parse <file.swift>
```
This validates syntax only — it does not resolve Apple framework imports.

### Key Gotchas

- **No `Package.swift`**: `swift build` / `swift test` will not work. The project is Xcode-only.
- **SwiftLint requires `LINUX_SOURCEKIT_LIB_PATH`**: On Linux, you must export this env var pointing to the Swift toolchain's `lib/` directory, or SwiftLint will crash with a `libsourcekitdInProc.so` error.
- **All data is local**: SwiftData with no CloudKit — there are no network calls, APIs, or external services.
- **No CI config**: No GitHub Actions, Fastlane, or CI/CD configuration exists in the repo.
