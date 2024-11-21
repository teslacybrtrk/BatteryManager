import SwiftUI

struct ContentView: View {
    @State private var chargeLimit: Double = 100
    @State private var currentBatteryLevel: Double = 0
    @State private var isCharging: Bool = false
    @State private var batteryManager: BatteryManager?
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Battery Manager")
                .font(.headline)
            
            HStack {
                Text("Current Battery Level: \(Int(currentBatteryLevel))%")
                Text(isCharging ? "Charging" : "Not Charging")
            }
            
            Text("Charge Limit: \(Int(chargeLimit))%")
            Slider(value: $chargeLimit, in: 50...100, step: 1)
                .padding()
            
            Button("Apply Charge Limit") {
                applyChargeLimit()
            }
        }
        .padding()
        .frame(width: 300, height: 200)
        .onReceive(timer) { _ in
            updateBatteryStatus()
        }
    }
    
    func updateBatteryStatus() {
        let powerSource = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(powerSource).takeRetainedValue() as [CFTypeRef]
        
        if let source = sources.first,
           let description = IOPSGetPowerSourceDescription(powerSource, source).takeUnretainedValue() as? [String: Any] {
            currentBatteryLevel = description[kIOPSCurrentCapacityKey] as? Double ?? 0
            isCharging = (description[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        }
    }
    
    func applyChargeLimit() {
        batteryManager?.stopMonitoring()
        batteryManager = BatteryManager(chargeLimit: chargeLimit)
        batteryManager?.startMonitoring()
    }
}
