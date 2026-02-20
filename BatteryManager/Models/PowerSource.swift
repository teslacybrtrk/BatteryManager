import Foundation

struct PowerSource {
    var type: PowerSourceType
    var currentCapacity: Int
    var maxCapacity: Int
    var isCharging: Bool
    var timeToEmpty: Int?
    var timeToFull: Int?
    var adapterWattage: Int?

    enum PowerSourceType: String {
        case battery = "Battery"
        case ac = "AC Power"
        case unknown = "Unknown"
    }
}
