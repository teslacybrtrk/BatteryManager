import Foundation

enum ChargingMode: String, CaseIterable, Codable {
    case normal
    case topUp
    case sailing
    case discharge
    case calibration
    case heatProtection

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .topUp: return "Top Up"
        case .sailing: return "Sailing"
        case .discharge: return "Discharge"
        case .calibration: return "Calibration"
        case .heatProtection: return "Heat Protection"
        }
    }

    var description: String {
        switch self {
        case .normal: return "Charge to limit and stop"
        case .topUp: return "Temporarily charge to 100%"
        case .sailing: return "Maintain charge within a range"
        case .discharge: return "Drain battery on AC power"
        case .calibration: return "Full charge cycle for calibration"
        case .heatProtection: return "Reduced charging due to high temperature"
        }
    }

    var systemImage: String {
        switch self {
        case .normal: return "battery.75percent"
        case .topUp: return "battery.100percent.bolt"
        case .sailing: return "wind"
        case .discharge: return "battery.25percent"
        case .calibration: return "arrow.triangle.2.circlepath"
        case .heatProtection: return "thermometer.sun.fill"
        }
    }
}
