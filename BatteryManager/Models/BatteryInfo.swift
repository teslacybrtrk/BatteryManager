import Foundation

struct BatteryInfo {
    var currentCapacity: Int = 0
    var maxCapacity: Int = 0
    var designCapacity: Int = 0
    var cycleCount: Int = 0
    var temperature: Double = 0.0  // Celsius
    var voltage: Double = 0.0      // Volts
    var amperage: Double = 0.0     // mA
    var isCharging: Bool = false
    var isPluggedIn: Bool = false
    var fullyCharged: Bool = false
    var timeToEmpty: Int? = nil    // Minutes
    var timeToFull: Int? = nil     // Minutes

    var healthPercent: Double {
        guard designCapacity > 0 else { return 100.0 }
        return (Double(maxCapacity) / Double(designCapacity)) * 100.0
    }

    var batteryLevel: Int {
        guard maxCapacity > 0 else { return 0 }
        return Int((Double(currentCapacity) / Double(maxCapacity)) * 100.0)
    }

    var wattage: Double {
        return (voltage * abs(amperage)) / 1000.0
    }
}
