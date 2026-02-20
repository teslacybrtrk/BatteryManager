import AppIntents
import AppKit

struct SetChargeLimitIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Battery Charge Limit"
    static var description = IntentDescription("Set the maximum battery charge percentage")

    @Parameter(title: "Limit", description: "Charge limit percentage (20-100)")
    var limit: Int

    static var parameterSummary: some ParameterSummary {
        Summary("Set charge limit to \(\.$limit)%")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        let clamped = max(20, min(100, limit))
        // Access the shared app delegate to apply the charge limit
        await MainActor.run {
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                delegate.chargingController?.applyChargeLimit(clamped)
            }
        }
        return .result(value: clamped)
    }
}
