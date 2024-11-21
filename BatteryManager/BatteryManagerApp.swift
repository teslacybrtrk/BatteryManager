import SwiftUI
import Foundation
import IOKit.ps

@main
struct BatteryManagerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class BatteryManager {
    private var shouldRun = false
    private let chargeLimit: Double
    private var smcConnection: io_connect_t = 0
    
    init(chargeLimit: Double) {
        self.chargeLimit = chargeLimit
        let result = SMCOpen(&smcConnection)
        if result != kIOReturnSuccess {
            print("Failed to open SMC connection")
        }
    }
    
    deinit {
        SMCClose(smcConnection)
    }
    
    func startMonitoring() {
        shouldRun = true
        DispatchQueue.global(qos: .background).async {
            while self.shouldRun {
                self.checkAndAdjustCharging()
                Thread.sleep(forTimeInterval: 60) // Check every minute
            }
        }
    }
    
    func stopMonitoring() {
        shouldRun = false
    }
    
    private func checkAndAdjustCharging() {
        let currentCharge = getCurrentBatteryCharge()
        if currentCharge >= chargeLimit {
            disableCharging()
        } else {
            enableCharging()
        }
    }
    
    private func getCurrentBatteryCharge() -> Double {
        var batteryInfo = SMCVal_t()
        let key = "BCLM"
        withUnsafeMutablePointer(to: &batteryInfo.key) { keyPtr in
            _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                strcpy(reboundPtr, key)
            }
        }
        
        let result = SMCReadKey(smcConnection, key, &batteryInfo)
        if result == kIOReturnSuccess {
            return Double(batteryInfo.bytes.0)  // Access the first element of the array
        }
        return 0
    }
    
    private func disableCharging() {
        var writeVal = SMCVal_t()
        let key = "CH0B"
        withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
            _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                strcpy(reboundPtr, key)
            }
        }
        writeVal.dataSize = 1
        withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
            _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                strcpy(reboundPtr, "ui8")
            }
        }
        writeVal.bytes.0 = 0  // Disable charging
        
        let result = SMCWriteKey(smcConnection, writeVal)
        if result != kIOReturnSuccess {
            print("Failed to disable charging")
        }
    }
    
    private func enableCharging() {
        var writeVal = SMCVal_t()
        let key = "CH0B"
        withUnsafeMutablePointer(to: &writeVal.key) { keyPtr in
            _ = keyPtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                strcpy(reboundPtr, key)
            }
        }
        writeVal.dataSize = 1
        withUnsafeMutablePointer(to: &writeVal.dataType) { typePtr in
            _ = typePtr.withMemoryRebound(to: Int8.self, capacity: 5) { reboundPtr in
                strcpy(reboundPtr, "ui8")
            }
        }
        writeVal.bytes.0 = 1  // Enable charging
        
        let result = SMCWriteKey(smcConnection, writeVal)
        if result != kIOReturnSuccess {
            print("Failed to enable charging")
        }
    }
}
