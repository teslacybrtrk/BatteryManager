import AppIntents
import AppKit

struct StartSailingModeIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sailing Mode"
    static var description = IntentDescription("Activate sailing mode to maintain battery within a range")

    @Parameter(title: "Low Bound", default: 65)
    var lowBound: Int?

    @Parameter(title: "High Bound", default: 80)
    var highBound: Int?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        await MainActor.run {
            if let delegate = NSApplication.shared.delegate as? AppDelegate {
                let low = lowBound ?? delegate.appState.settings.sailingLow
                let high = highBound ?? delegate.appState.settings.sailingHigh
                delegate.appState.settings.sailingLow = low
                delegate.appState.settings.sailingHigh = high
                delegate.appState.settings.save()
                delegate.chargingController?.setMode(.sailing)
            }
        }
        let low = lowBound ?? 65
        let high = highBound ?? 80
        return .result(value: "Sailing mode activated: \(low)%-\(high)%")
    }
}
