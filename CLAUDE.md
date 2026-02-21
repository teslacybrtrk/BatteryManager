# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BatteryManager is a native macOS menu bar app (Swift/C) that controls battery charging limits via direct SMC (System Management Controller) access. It runs as an LSUIElement (no dock icon) with a popover UI accessed from the status bar.

## Build & Run

This is an Xcode project (no SPM). Open `BatteryManager.xcodeproj` in Xcode 15.4+.

```bash
# Build
xcodebuild -project BatteryManager.xcodeproj -scheme BatteryManager -configuration Debug build

# Run tests
xcodebuild -project BatteryManager.xcodeproj -scheme BatteryManager test

# Clean
xcodebuild -project BatteryManager.xcodeproj -scheme BatteryManager clean
```

Target: macOS 14.5+ (Sonoma). Requires IOKit framework (linked in project).

## Architecture

```
ContentView (SwiftUI) + AppDelegate (NSAppKit menu bar/popover)
        ↓
BatteryManager class (monitoring loop, charge logic)
        ↓
SMCKit (C wrapper via bridging header)
        ↓
IOKit / AppleSMC kernel driver
```

- **BatteryManagerApp.swift** — App entry point + `BatteryManager` class with core logic. Monitors battery every 60s on a background dispatch queue. Reads charge via `BCLM` SMC key, toggles charging via `CH0B` SMC key.
- **ContentView.swift** — SwiftUI view with battery level display, charging status, and charge limit slider (50-100%). Polls power source info every 5s via `IOPSCopyPowerSourcesInfo`.
- **AppDelegate.swift** — Creates `NSStatusItem` menu bar icon with `NSPopover` for the UI. Handles theme changes.
- **SMCKit.c/.h** — C functions (`SMCOpen`, `SMCClose`, `SMCReadKey`, `SMCWriteKey`) wrapping `IOConnectCallStructMethod` for direct SMC communication.
- **BatteryManager-Bridging-Header.h** — Exposes SMCKit C API to Swift.

## Release & Updates

Releases are **fully automated** via GitHub Actions (`.github/workflows/build-and-release.yml`):

- Every push/merge to `main` triggers a build
- The workflow builds, ad-hoc signs, zips, and creates/updates the `latest` GitHub Release
- **Do NOT tell the user to build locally, create zips, or manually create releases** — just merge PRs and the CI handles everything
- End users update via the in-app "Check for Updates" button in Settings, which checks the GitHub Releases API
- After updating, users are prompted to reinstall the helper if the helper version is outdated

## Privileged Helper Tool

The app uses a privileged XPC helper (`BatteryManagerHelper`) installed to `/Library/PrivilegedHelperTools/` for SMC write access. The app can read SMC without root, but writing (charging control) requires the helper.

- Helper version is checked on launch via XPC `getVersion()` call
- If the helper is missing or outdated (< required version in `AppDelegate.requiredHelperVersion`), the user is prompted to install/reinstall
- On M3+ Macs with macOS Sequoia (Tahoe firmware), uses `CHTE` (4-byte) and `CHIE` keys instead of deprecated `CH0B`/`CH0C`/`CH0I`
- Key detection happens at helper startup via read probing

## Key Technical Details

- The app requires a privileged helper tool (installed via admin password prompt) to write SMC keys.
- No third-party dependencies. Only system frameworks: IOKit, SwiftUI, AppKit.
- On Apple Silicon, IOKit's `MaxCapacity`/`CurrentCapacity` return percentages, not mAh. Use `AppleRawMaxCapacity`/`AppleRawCurrentCapacity` for actual mAh values.
- `@Observable` properties are NOT thread-safe — always snapshot state on main thread before dispatching to background queues.
- Tests are placeholder stubs — no real test coverage yet.
