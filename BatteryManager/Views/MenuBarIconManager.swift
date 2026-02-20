import Cocoa
import SwiftUI

final class MenuBarIconManager {
    private let appState: AppState
    private weak var statusItem: NSStatusItem?

    init(appState: AppState, statusItem: NSStatusItem) {
        self.appState = appState
        self.statusItem = statusItem
    }

    func updateIcon() {
        guard let button = statusItem?.button else { return }

        let symbolName = batterySymbolName()
        let config = NSImage.SymbolConfiguration(pointSize: 18, weight: .regular)
            .applying(.init(hierarchicalColor: .labelColor))

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "Battery Status")?.withSymbolConfiguration(config) {
            image.isTemplate = true
            button.image = image
        }

        // Optionally show percentage text
        if appState.settings.showBatteryPercentInMenuBar {
            button.title = " \(appState.batteryLevel)%"
            button.imagePosition = .imageLeading
        } else {
            button.title = ""
            button.imagePosition = .imageOnly
        }
    }

    private func batterySymbolName() -> String {
        let level = appState.batteryLevel
        let base: String

        if level > 75 {
            base = "battery.100percent"
        } else if level > 50 {
            base = "battery.75percent"
        } else if level > 25 {
            base = "battery.50percent"
        } else if level > 5 {
            base = "battery.25percent"
        } else {
            base = "battery.0percent"
        }

        // Add overlay based on mode
        switch appState.currentMode {
        case .normal where appState.isCharging:
            return "battery.100percent.bolt"
        case .discharge:
            return "minus.circle.fill"
        case .heatProtection:
            return "thermometer.sun.fill"
        case .calibration:
            return "arrow.triangle.2.circlepath"
        default:
            return base
        }
    }
}
