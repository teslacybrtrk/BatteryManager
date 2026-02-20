import AppIntents
import AppKit

struct GetBatteryInfoIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Battery Info"
    static var description = IntentDescription("Get current battery status information")

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let info = await MainActor.run { () -> String in
            guard let delegate = NSApplication.shared.delegate as? AppDelegate else {
                return "Battery info unavailable"
            }
            let state = delegate.appState
            return "Battery: \(state.batteryLevel)%, Health: \(String(format: "%.1f", state.healthPercent))%, " +
                   "Charging: \(state.isCharging ? "Yes" : "No"), " +
                   "Temperature: \(String(format: "%.1f", state.temperature))\u{00B0}C, " +
                   "Mode: \(state.currentMode.displayName)"
        }
        return .result(value: info)
    }
}
