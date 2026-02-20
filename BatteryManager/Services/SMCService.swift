import Foundation
import IOKit

final class SMCService {
    private var connection: io_connect_t = 0
    private let queue = DispatchQueue(label: "com.batterymanager.smc", qos: .utility)
    private(set) var isConnected: Bool = false
    private(set) var useXPC: Bool = false
    private var xpcConnection: NSXPCConnection?

    init() {
        // Try XPC first (privileged helper)
        if connectViaXPC() {
            useXPC = true
            isConnected = true
            print("[SMCService] Connected via XPC helper")
        } else {
            // Fall back to direct SMC access
            let result = SMCOpen(&connection)
            isConnected = (result == kIOReturnSuccess)
            if isConnected {
                print("[SMCService] Connected via direct SMC access")
            } else {
                print("[SMCService] Failed to open SMC connection: \(result)")
            }
        }
    }

    deinit {
        if useXPC {
            xpcConnection?.invalidate()
        } else if isConnected {
            SMCClose(connection)
        }
    }

    // MARK: - XPC Connection

    private func connectViaXPC() -> Bool {
        let conn = NSXPCConnection(machServiceName: "com.batterymanager.helper", options: .privileged)
        conn.remoteObjectInterface = NSXPCInterface(with: SMCHelperProtocol.self)
        conn.interruptionHandler = { [weak self] in
            print("[SMCService] XPC connection interrupted, attempting reconnect...")
            self?.reconnectXPC()
        }
        conn.invalidationHandler = { [weak self] in
            print("[SMCService] XPC connection invalidated")
            self?.xpcConnection = nil
        }
        conn.resume()

        // Synchronous ping with 3-second timeout
        let semaphore = DispatchSemaphore(value: 0)
        var pingSuccess = false

        let proxy = conn.remoteObjectProxyWithErrorHandler { _ in
            semaphore.signal()
        } as! SMCHelperProtocol

        proxy.ping { success in
            pingSuccess = success
            semaphore.signal()
        }

        let result = semaphore.wait(timeout: .now() + 3)
        if result == .timedOut || !pingSuccess {
            conn.invalidate()
            return false
        }

        xpcConnection = conn
        return true
    }

    private func reconnectXPC() {
        xpcConnection?.invalidate()
        xpcConnection = nil
        if connectViaXPC() {
            useXPC = true
            isConnected = true
        } else {
            useXPC = false
            isConnected = false
        }
    }

    private func xpcProxy() -> SMCHelperProtocol? {
        guard let conn = xpcConnection else { return nil }
        return conn.remoteObjectProxyWithErrorHandler { error in
            print("[SMCService] XPC proxy error: \(error)")
        } as? SMCHelperProtocol
    }

    // MARK: - Generic Read/Write

    func readKey(_ key: SMCKey) -> SMCVal_t? {
        queue.sync {
            guard isConnected, !useXPC else { return nil }
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
            guard isConnected, !useXPC else { return false }
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
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result: UInt8 = 0
            xpcProxy()?.readBatteryChargeLevel { level in
                result = level
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : nil
        }
        guard let val = readKey(.batteryChargeLevelMax) else { return nil }
        return val.bytes.0
    }

    func setBatteryChargeLimit(_ limit: UInt8) -> Bool {
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            xpcProxy()?.setBatteryChargeLimit(limit) { success in
                result = success
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : false
        }
        return writeKey(.batteryChargeLevelMax, dataType: "ui8", size: 1, byte0: limit)
    }

    func setChargingEnabled(_ enabled: Bool) -> Bool {
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            xpcProxy()?.setChargingEnabled(enabled) { success in
                result = success
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : false
        }
        return writeKey(.chargingControl, dataType: "ui8", size: 1, byte0: enabled ? 0 : 2)
    }

    func setChargeInhibit(_ inhibit: Bool) -> Bool {
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            xpcProxy()?.setChargeInhibit(inhibit) { success in
                result = success
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : false
        }
        return writeKey(.chargeInhibit, dataType: "ui8", size: 1, byte0: inhibit ? 1 : 0)
    }

    func setForceCharging(_ force: Bool) -> Bool {
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            xpcProxy()?.setForceCharging(force) { success in
                result = success
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : false
        }
        return writeKey(.batteryForceCharging, dataType: "ui8", size: 1, byte0: force ? 1 : 0)
    }

    // MARK: - Temperature

    func readBatteryTemperature() -> Double? {
        if useXPC {
            let semaphore = DispatchSemaphore(value: 0)
            var result: Double?
            xpcProxy()?.readTemperatures { temps in
                result = temps.max()
                semaphore.signal()
            }
            return semaphore.wait(timeout: .now() + 5) == .success ? result : nil
        }

        // Direct: try all temperature sensors, return the highest
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
