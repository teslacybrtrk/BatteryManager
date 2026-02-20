import Foundation
import IOKit

final class SMCService {
    private var connection: io_connect_t = 0
    private let queue = DispatchQueue(label: "com.batterymanager.smc", qos: .utility)
    private(set) var isConnected: Bool = false

    init() {
        let result = SMCOpen(&connection)
        isConnected = (result == kIOReturnSuccess)
        if !isConnected {
            print("[SMCService] Failed to open SMC connection: \(result)")
        }
    }

    deinit {
        if isConnected {
            SMCClose(connection)
        }
    }

    // MARK: - Generic Read/Write

    func readKey(_ key: SMCKey) -> SMCVal_t? {
        queue.sync {
            guard isConnected else { return nil }
            var val = SMCVal_t()
            let result = SMCReadKey(connection, key.rawValue, &val)
            guard result == kIOReturnSuccess else {
                print("[SMCService] Failed to read key \(key.rawValue): \(result)")
                return nil
            }
            return val
        }
    }

    func writeKey(_ key: SMCKey, dataType: String, size: UInt32, byte0: UInt8) -> Bool {
        queue.sync {
            guard isConnected else { return false }
            var writeVal = SMCVal_t()
            withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
                _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                    strcpy(reboundPtr, key.rawValue)
                }
            }
            writeVal.dataSize = size
            withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
                _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                    strcpy(reboundPtr, dataType)
                }
            }
            writeVal.bytes.0 = byte0
            let result = SMCWriteKey(connection, writeVal)
            if result != kIOReturnSuccess {
                print("[SMCService] Failed to write key \(key.rawValue): \(result)")
                return false
            }
            return true
        }
    }

    // MARK: - Battery Specific

    func readBatteryChargeLevel() -> UInt8? {
        guard let val = readKey(.batteryChargeLevelMax) else { return nil }
        return val.bytes.0
    }

    func setBatteryChargeLimit(_ limit: UInt8) -> Bool {
        return writeKey(.batteryChargeLevelMax, dataType: "ui8", size: 1, byte0: limit)
    }

    func setChargingEnabled(_ enabled: Bool) -> Bool {
        return writeKey(.chargingControl, dataType: "ui8", size: 1, byte0: enabled ? 0 : 2)
    }

    func setChargeInhibit(_ inhibit: Bool) -> Bool {
        return writeKey(.chargeInhibit, dataType: "ui8", size: 1, byte0: inhibit ? 1 : 0)
    }

    func setForceCharging(_ force: Bool) -> Bool {
        return writeKey(.batteryForceCharging, dataType: "ui8", size: 1, byte0: force ? 1 : 0)
    }

    // MARK: - Temperature

    func readBatteryTemperature() -> Double? {
        // Try all temperature sensors, return the highest
        let keys: [SMCKey] = [.temperature0, .temperature1, .temperature2]
        var maxTemp: Double? = nil

        for key in keys {
            if let val = readKey(key) {
                // sp78 format: signed 7.8 fixed point
                let raw = (Int16(val.bytes.0) << 8) | Int16(val.bytes.1)
                let temp = Double(raw) / 256.0
                if temp > 0 {
                    if let current = maxTemp {
                        maxTemp = max(current, temp)
                    } else {
                        maxTemp = temp
                    }
                }
            }
        }
        return maxTemp
    }
}
