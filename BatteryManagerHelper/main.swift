import Foundation

// MARK: - File Logger

/// Logs to /tmp/batterymanager-helper.log so messages aren't redacted by macOS privacy
private let helperLogPath = "/tmp/batterymanager-helper.log"
private let helperLogMaxSize: UInt64 = 512 * 1024  // 512 KB
private let helperLogTruncateKeep: Int = 200        // Keep last 200 lines after truncation

private func helperLog(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    NSLog("%{public}s", message)
    if let handle = FileHandle(forWritingAtPath: helperLogPath) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        let size = handle.offsetInFile
        handle.closeFile()
        if size > helperLogMaxSize {
            trimLogFile()
        }
    } else {
        FileManager.default.createFile(atPath: helperLogPath, contents: Data(line.utf8))
    }
}

private func trimLogFile() {
    guard let data = FileManager.default.contents(atPath: helperLogPath),
          let content = String(data: data, encoding: .utf8) else { return }
    let lines = content.components(separatedBy: "\n")
    let kept = lines.suffix(helperLogTruncateKeep).joined(separator: "\n")
    try? kept.write(toFile: helperLogPath, atomically: true, encoding: .utf8)
}

// MARK: - SMC Helper Delegate

final class SMCHelperDelegate: NSObject, NSXPCListenerDelegate, SMCHelperProtocol {
    private var connection: io_connect_t = 0
    private var smcConnected = false
    private let smcQueue = DispatchQueue(label: "com.batterymanager.helper.smc")

    // Key capabilities detected at startup
    private var useTahoeCharging = false  // CHTE (4-byte) vs CH0B+CH0C (1-byte)
    private var useTahoeAdapter = false   // CHIE vs CH0I
    private var hasCH0B = false
    private var hasCH0I = false

    override init() {
        super.init()
        var conn: io_connect_t = 0
        let result = SMCOpen(&conn)
        if result == kIOReturnSuccess {
            connection = conn
            smcConnected = true
            helperLog("[Helper] SMC connection opened successfully (SMCKeyData_t size: \(MemoryLayout<SMCKeyData_t>.size))")
            detectCapabilities()
        } else {
            helperLog("[Helper] Failed to open SMC: \(result)")
        }
    }

    deinit {
        if smcConnected {
            SMCClose(connection)
        }
    }

    /// Detect which SMC keys are available on this hardware
    private func detectCapabilities() {
        hasCH0B = canReadKey("CH0B")
        let hasCH0C = canReadKey("CH0C")
        let hasCHTE = canReadKey("CHTE")
        hasCH0I = canReadKey("CH0I")
        let hasCHIE = canReadKey("CHIE")

        if hasCHTE {
            useTahoeCharging = true
            helperLog("[Helper] Using Tahoe charging key (CHTE)")
        } else if hasCH0B && hasCH0C {
            useTahoeCharging = false
            helperLog("[Helper] Using pre-Tahoe charging keys (CH0B+CH0C)")
        } else {
            helperLog("[Helper] WARNING: No known charging keys found (CH0B=\(hasCH0B), CH0C=\(hasCH0C), CHTE=\(hasCHTE))")
        }

        if hasCHIE {
            useTahoeAdapter = true
            helperLog("[Helper] Using Tahoe adapter key (CHIE)")
        } else if hasCH0I {
            useTahoeAdapter = false
            helperLog("[Helper] Using pre-Tahoe adapter key (CH0I)")
        } else {
            helperLog("[Helper] WARNING: No known adapter keys found")
        }
    }

    private func canReadKey(_ key: String) -> Bool {
        var val = SMCVal_t()
        let result = SMCReadKey(connection, key, &val)
        let success = result == kIOReturnSuccess
        helperLog("[Helper] Key \(key) readable: \(success)")
        return success
    }

    // MARK: - SMC Write Helpers

    private func writeKey1Byte(_ key: String, value: UInt8) -> Bool {
        var writeVal = SMCVal_t()
        withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
            _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, key) }
        }
        writeVal.dataSize = 1
        withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
            _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui8") }
        }
        writeVal.bytes.0 = value
        let result = SMCWriteKey(connection, writeVal)
        let success = result == kIOReturnSuccess
        helperLog("[Helper] Write \(key)=\(value) result: \(success) (code: \(String(format: "0x%08x", result)))")
        return success
    }

    private func writeKey4Bytes(_ key: String, b0: UInt8, b1: UInt8, b2: UInt8, b3: UInt8) -> Bool {
        var writeVal = SMCVal_t()
        withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
            _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, key) }
        }
        writeVal.dataSize = 4
        withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
            _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui32") }
        }
        writeVal.bytes.0 = b0
        writeVal.bytes.1 = b1
        writeVal.bytes.2 = b2
        writeVal.bytes.3 = b3
        let result = SMCWriteKey(connection, writeVal)
        let success = result == kIOReturnSuccess
        helperLog("[Helper] Write \(key)=[\(b0),\(b1),\(b2),\(b3)] result: \(success) (code: \(String(format: "0x%08x", result)))")
        return success
    }

    // MARK: - NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: SMCHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    // MARK: - SMCHelperProtocol

    func ping(reply: @escaping (Bool) -> Void) {
        reply(smcConnected)
    }

    func getVersion(reply: @escaping (String) -> Void) {
        reply("2.3.0")
    }

    func readBatteryChargeLevel(reply: @escaping (UInt8) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(0); return }
            // Try BUIC first (Apple Silicon), then BCLM (Intel)
            for key in ["BUIC", "BCLM"] {
                var val = SMCVal_t()
                let result = SMCReadKey(connection, key, &val)
                if result == kIOReturnSuccess {
                    reply(val.bytes.0)
                    return
                }
            }
            reply(0)
        }
    }

    func setBatteryChargeLimit(_ limit: UInt8, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            // BCLM doesn't work on Tahoe firmware; charge limiting is done
            // via software control (disabling charging at threshold) instead.
            // Try BCLM anyway for older firmware compatibility.
            let success = writeKey1Byte("BCLM", value: limit)
            reply(success)
        }
    }

    func setChargingEnabled(_ enabled: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }

            var anySuccess = false

            // Write ALL available charging keys for maximum compatibility
            if useTahoeCharging {
                let s: Bool
                if enabled {
                    s = writeKey4Bytes("CHTE", b0: 0x00, b1: 0x00, b2: 0x00, b3: 0x00)
                } else {
                    s = writeKey4Bytes("CHTE", b0: 0x01, b1: 0x00, b2: 0x00, b3: 0x00)
                }
                if s { anySuccess = true }
            }

            // Also write pre-Tahoe keys if available (some firmware responds to both)
            if hasCH0B {
                let value: UInt8 = enabled ? 0x00 : 0x02
                let s1 = writeKey1Byte("CH0B", value: value)
                let s2 = writeKey1Byte("CH0C", value: value)
                if s1 || s2 { anySuccess = true }
            }

            reply(anySuccess)
        }
    }

    func setChargeInhibit(_ inhibit: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }

            var anySuccess = false

            // Write ALL available adapter keys
            if useTahoeAdapter {
                let value: UInt8 = inhibit ? 0x08 : 0x00
                if writeKey1Byte("CHIE", value: value) { anySuccess = true }
            }

            if hasCH0I {
                let value: UInt8 = inhibit ? 0x01 : 0x00
                if writeKey1Byte("CH0I", value: value) { anySuccess = true }
            }

            reply(anySuccess)
        }
    }

    func setForceCharging(_ force: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            let success = writeKey1Byte("BFCL", value: force ? 1 : 0)
            reply(success)
        }
    }

    func readTemperatures(reply: @escaping ([Double]) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply([]); return }
            var temps: [Double] = []
            for key in ["TB0T", "TB1T", "TB2T"] {
                var val = SMCVal_t()
                let result = SMCReadKey(connection, key, &val)
                if result == kIOReturnSuccess {
                    let raw = (Int16(val.bytes.0) << 8) | Int16(val.bytes.1)
                    let temp = Double(raw) / 256.0
                    if temp > 0 {
                        temps.append(temp)
                    }
                }
            }
            reply(temps)
        }
    }
}

// MARK: - Main

let delegate = SMCHelperDelegate()
let listener = NSXPCListener(machServiceName: "com.batterymanager.helper")
listener.delegate = delegate
listener.resume()

helperLog("[Helper] BatteryManagerHelper started, listening on com.batterymanager.helper")
RunLoop.current.run()
