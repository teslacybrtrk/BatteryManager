import Foundation

struct AppSettings: Codable, Equatable {
    var chargeLimit: Int = 80
    var sailingLow: Int = 65
    var sailingHigh: Int = 80
    var heatProtectionEnabled: Bool = true
    var heatProtectionThreshold: Double = 40.0  // Celsius
    var stopChargingOnQuit: Bool = true
    var launchAtLogin: Bool = false
    var calibrationIntervalDays: Int = 90
    var lastCalibrationDate: Date? = nil
    var showBatteryPercentInMenuBar: Bool = true
    var preventSleepWhileCharging: Bool = false

    private static let key = "BatteryManagerSettings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.key)
        }
    }
}
