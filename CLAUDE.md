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

## Key Technical Details

- The app requires elevated privileges to write SMC keys (controlling charging hardware).
- App sandbox is enabled in entitlements but SMC access may require running with root or disabling sandbox for full functionality.
- No third-party dependencies. Only system frameworks: IOKit, SwiftUI, AppKit.
- Tests are placeholder stubs — no real test coverage yet.
