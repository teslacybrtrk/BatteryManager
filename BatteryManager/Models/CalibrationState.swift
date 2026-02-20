import Foundation

enum CalibrationState: Codable, Equatable {
    case idle
    case dischargingTo(percent: Int)
    case chargingTo100
    case complete(date: Date)

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .dischargingTo(let percent): return "Discharging to \(percent)%"
        case .chargingTo100: return "Charging to 100%"
        case .complete: return "Complete"
        }
    }

    var isRunning: Bool {
        switch self {
        case .idle, .complete: return false
        case .dischargingTo, .chargingTo100: return true
        }
    }
}
