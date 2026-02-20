# BatteryManager

A native macOS menu bar app that gives you full control over your MacBook's battery charging. Set charge limits, schedule charging windows, monitor battery health, and more — all through a lightweight status bar popover. No third-party dependencies, just direct SMC access.

Requires macOS 14.5 or later (Apple Silicon).

## Download

**[Download the latest build](https://github.com/teslacybrtrk/BatteryManager/releases/latest/download/BatteryManager.zip)**

### Opening the app

We don't pay Apple $99/year for a Developer ID certificate, so macOS will show a warning the first time you open the app. Here's how to get past it:

1. Unzip `BatteryManager.zip`
2. Move `BatteryManager.app` to your Applications folder (or wherever you like)
3. **Right-click** (or Control-click) the app and select **Open**
4. If you see an **Open** button in the dialog, click it — you're done

If macOS blocks it without an Open button:

1. Open **System Settings → Privacy & Security**
2. Scroll down to the security section — you'll see a message about BatteryManager being blocked
3. Click **Open Anyway**, then confirm

You only need to do this once. After that, the app opens normally.

### Privileged helper

BatteryManager needs to write to SMC keys to control charging hardware. On first launch, the app will ask for your admin password to install a small privileged helper tool. This is a one-time setup — after that, the app works without `sudo`.

## Features

- **Charge limit** — set a maximum charge level (50–100%) to preserve battery longevity
- **Sailing mode** — maintain current charge level by toggling charging on/off
- **Scheduling** — create time-based charging windows (e.g., charge to 100% overnight before a trip)
- **Battery calibration** — guided full discharge/charge cycle for accurate capacity readings
- **Power flow visualization** — real-time view of power source, charge rate, and thermal state
- **Battery stats** — cycle count, health percentage, temperature, and voltage
- **MagSafe LED control** — customize the charging indicator LED behavior
- **Menu bar icon** — shows battery level at a glance, updates in real time
- **Auto-update** — checks GitHub Releases on launch and can update in-place
- **Siri Shortcuts** — set charge limits, toggle charging, and more via Shortcuts app

## Building from source

Open `BatteryManager.xcodeproj` in Xcode 15.4+, or build from the command line:

```bash
xcodebuild -project BatteryManager.xcodeproj -scheme BatteryManager -configuration Release build
```
