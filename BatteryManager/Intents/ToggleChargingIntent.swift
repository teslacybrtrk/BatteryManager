import AppIntents
import AppKit

struct ToggleChargingIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Battery Charging"
    static var description = IntentDescription("Enable or disable battery charging")

    @Parameter(title: "Enable", description: "Whether to enable or disable charging")
    var enable: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("\(\.$enable) battery charging")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        await MainActor.run {
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                if enable {
                    delegate.chargingController?.enableCharging()
                } else {
                    delegate.chargingController?.disableCharging()
                }
            }
        }
        return .result(value: enable)
    }
}
