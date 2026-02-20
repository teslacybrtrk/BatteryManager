import Foundation

@Observable
final class BatteryViewModel {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var healthString: String {
        String(format: "%.1f%% %@", appState.healthPercent, appState.batteryHealthDescription)
    }

    var temperatureString: String {
        String(format: "%.1f\u{00B0}C", appState.temperature)
    }

    var timeRemainingString: String {
        if appState.isCharging, let ttf = appState.timeToFull {
            return formatMinutes(ttf)
        }
        if let tte = appState.timeToEmpty {
            return formatMinutes(tte)
        }
        return "N/A"
    }

    var cycleCountString: String {
        "\(appState.cycleCount) / 1000"
    }

    var voltageString: String {
        String(format: "%.2f V", appState.voltage)
    }

    var amperageString: String {
        String(format: "%.0f mA", appState.amperage)
    }

    var wattageString: String {
        String(format: "%.1f W", appState.wattage)
    }

    var capacityString: String {
        "\(appState.currentCapacity) / \(appState.maxCapacity) mAh"
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes <= 0 { return "Calculating..." }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}
