import Foundation

@Observable
final class StatsViewModel {
    private let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    var healthPercent: Double { appState.healthPercent }
    var healthDescription: String { appState.batteryHealthDescription }
    var cycleCount: Int { appState.cycleCount }
    var temperature: Double { appState.temperature }
    var voltage: Double { appState.voltage }
    var amperage: Double { appState.amperage }
    var wattage: Double { appState.wattage }
    var currentCapacity: Int { appState.currentCapacity }
    var maxCapacity: Int { appState.maxCapacity }
    var designCapacity: Int { appState.designCapacity }
}
