import Foundation

enum SMCKey: String {
    case batteryChargeLevelMax = "BCLM"  // Battery Charge Level Max
    case chargingControl = "CH0B"         // Charging on/off
    case chargingControl2 = "CH0C"        // Secondary charging control
    case chargeInhibit = "CH0I"           // Charge inhibit (force discharge)
    case batteryForceCharging = "BFCL"    // Force charging
    case temperature0 = "TB0T"            // Battery temperature sensor 0
    case temperature1 = "TB1T"            // Battery temperature sensor 1
    case temperature2 = "TB2T"            // Battery temperature sensor 2
    case adapterConnected = "BBIN"        // Adapter connected status
    case adapterWattage = "PDTR"          // Adapter wattage

    var fourCharCode: String { rawValue }
}
