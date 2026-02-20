import Foundation

// MARK: - SMC Helper Delegate

final class SMCHelperDelegate: NSObject, NSXPCListenerDelegate, SMCHelperProtocol {
    private var connection: io_connect_t = 0
    private var smcConnected = false
    private let smcQueue = DispatchQueue(label: "com.batterymanager.helper.smc")

    override init() {
        super.init()
        var conn: io_connect_t = 0
        let result = SMCOpen(&conn)
        if result == kIOReturnSuccess {
            connection = conn
            smcConnected = true
            NSLog("[Helper] SMC connection opened successfully")
        } else {
            NSLog("[Helper] Failed to open SMC: \(result)")
        }
    }

    deinit {
        if smcConnected {
            SMCClose(connection)
        }
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
        reply("1.0.0")
    }

    func readBatteryChargeLevel(reply: @escaping (UInt8) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(0); return }
            var val = SMCVal_t()
            let result = SMCReadKey(connection, "BCLM", &val)
            if result == kIOReturnSuccess {
                reply(val.bytes.0)
            } else {
                reply(0)
            }
        }
    }

    func setBatteryChargeLimit(_ limit: UInt8, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            var writeVal = SMCVal_t()
            withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
                _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "BCLM") }
            }
            writeVal.dataSize = 1
            withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
                _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui8") }
            }
            writeVal.bytes.0 = limit
            let result = SMCWriteKey(connection, writeVal)
            reply(result == kIOReturnSuccess)
        }
    }

    func setChargingEnabled(_ enabled: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            var writeVal = SMCVal_t()
            withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
                _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "CH0B") }
            }
            writeVal.dataSize = 1
            withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
                _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui8") }
            }
            writeVal.bytes.0 = enabled ? 0 : 2
            let result = SMCWriteKey(connection, writeVal)
            reply(result == kIOReturnSuccess)
        }
    }

    func setChargeInhibit(_ inhibit: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            var writeVal = SMCVal_t()
            withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
                _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "CH0I") }
            }
            writeVal.dataSize = 1
            withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
                _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui8") }
            }
            writeVal.bytes.0 = inhibit ? 1 : 0
            let result = SMCWriteKey(connection, writeVal)
            reply(result == kIOReturnSuccess)
        }
    }

    func setForceCharging(_ force: Bool, reply: @escaping (Bool) -> Void) {
        smcQueue.sync {
            guard smcConnected else { reply(false); return }
            var writeVal = SMCVal_t()
            withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
                _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "BFCL") }
            }
            writeVal.dataSize = 1
            withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
                _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { strcpy($0, "ui8") }
            }
            writeVal.bytes.0 = force ? 1 : 0
            let result = SMCWriteKey(connection, writeVal)
            reply(result == kIOReturnSuccess)
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

NSLog("[Helper] BatteryManagerHelper started, listening on com.batterymanager.helper")
RunLoop.current.run()
