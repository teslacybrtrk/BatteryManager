import Foundation
import Combine

@Observable
final class AppState {
    // MARK: - Battery Info
    var hasInitialReading: Bool = false
    var batteryLevel: Int = 0
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var temperature: Double = 0.0
    var cycleCount: Int = 0
    var maxCapacity: Int = 0
    var designCapacity: Int = 0
    var currentCapacity: Int = 0
    var voltage: Double = 0.0
    var amperage: Double = 0.0
    var fullyCharged: Bool = false
    var timeToEmpty: Int? = nil
    var timeToFull: Int? = nil
    var healthPercent: Double = 0.0
    var wattage: Double = 0.0

    // MARK: - Charging Control
    var chargeLimit: Int = 80
    var isChargingEnabled: Bool = true
    var currentMode: ChargingMode = .normal

    // MARK: - Settings
    var settings: AppSettings = AppSettings.load()

    // MARK: - Status
    var smcConnected: Bool = false
    var needsHelperInstall: Bool = false
    var lastError: String? = nil

    // MARK: - Computed
    var batteryHealthDescription: String {
        let health = healthPercent
        if health <= 0 { return "Unknown" }
        if health >= 90 { return "Good" }
        if health >= 80 { return "Fair" }
        if health >= 70 { return "Poor" }
        return "Service Recommended"
    }
}
