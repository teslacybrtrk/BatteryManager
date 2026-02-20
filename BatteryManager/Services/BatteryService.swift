import Foundation
import IOKit
import IOKit.ps

final class BatteryService {
    private let appState: AppState
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.batterymanager.battery", qos: .utility)

    init(appState: AppState) {
        self.appState = appState
    }

    func startMonitoring() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 5.0)
        timer?.setEventHandler { [weak self] in
            self?.updateBatteryInfo()
        }
        timer?.resume()
    }

    func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }

    func fetchBatteryInfo() -> BatteryInfo {
        var info = BatteryInfo()

        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != IO_OBJECT_NULL else { return info }
        defer { IOObjectRelease(service) }

        func getInt(_ key: String) -> Int? {
            if let value = IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
                return value
            }
            return nil
        }

        func getBool(_ key: String) -> Bool {
            return (IORegistryEntryCreateCFProperty(service, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Bool) ?? false
        }

        info.cycleCount = getInt("CycleCount") ?? 0
        info.maxCapacity = getInt("MaxCapacity") ?? 0
        info.designCapacity = getInt("DesignCapacity") ?? 0
        info.currentCapacity = getInt("CurrentCapacity") ?? 0
        info.voltage = Double(getInt("Voltage") ?? 0) / 1000.0
        info.amperage = Double(getInt("Amperage") ?? 0)
        info.isCharging = getBool("IsCharging")
        info.isPluggedIn = getBool("ExternalConnected")
        info.fullyCharged = getBool("FullyCharged")

        // Temperature is in centi-degrees Celsius (divide by 100)
        if let rawTemp = getInt("Temperature") {
            info.temperature = Double(rawTemp) / 100.0
        }

        if let tte = getInt("TimeRemaining"), !info.isPluggedIn {
            info.timeToEmpty = tte
        }
        if let ttf = getInt("TimeRemaining"), info.isCharging {
            info.timeToFull = ttf
        }

        return info
    }

    func fetchHardwareBatteryPercentage() -> Int {
        let info = fetchBatteryInfo()
        return info.batteryLevel
    }

    // Also fetch from IOPSCopyPowerSourcesInfo for compatibility
    func fetchPowerSourceInfo() -> (level: Int, isCharging: Bool, isPluggedIn: Bool) {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let desc = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return (0, false, false)
        }

        let level = desc[kIOPSCurrentCapacityKey] as? Int ?? 0
        let isCharging = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue
        let pluggedIn = (desc[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue

        return (level, isCharging, pluggedIn)
    }

    // MARK: - Private

    private func updateBatteryInfo() {
        let info = fetchBatteryInfo()

        DispatchQueue.main.async { [weak self] in
            guard let state = self?.appState else { return }
            state.batteryLevel = info.batteryLevel
            state.isCharging = info.isCharging
            state.isPluggedIn = info.isPluggedIn
            state.temperature = info.temperature
            state.cycleCount = info.cycleCount
            state.maxCapacity = info.maxCapacity
            state.designCapacity = info.designCapacity
            state.currentCapacity = info.currentCapacity
            state.voltage = info.voltage
            state.amperage = info.amperage
            state.fullyCharged = info.fullyCharged
            state.timeToEmpty = info.timeToEmpty
            state.timeToFull = info.timeToFull
            state.healthPercent = info.healthPercent
            state.wattage = info.wattage
        }
    }
}
