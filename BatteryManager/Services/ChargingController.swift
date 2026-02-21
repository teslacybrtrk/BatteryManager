import Foundation

final class ChargingController {
    private let appState: AppState
    private let smcService: SMCService
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.batterymanager.charging", qos: .utility)

    var thermalService: ThermalService?
    var calibrationService: CalibrationService?
    var powerAssertionService: PowerAssertionService?
    var magSafeLEDService: MagSafeLEDService?

    init(appState: AppState, smcService: SMCService) {
        self.appState = appState
        self.smcService = smcService
    }

    func startControlLoop() {
        // Cancel any existing timer to prevent duplicates
        timer?.cancel()
        timer = nil

        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now() + 5.0, repeating: 30.0)
        timer?.setEventHandler { [weak self] in
            self?.safeEvaluate()
        }
        timer?.resume()
    }

    func stopControlLoop() {
        timer?.cancel()
        timer = nil
    }

    func enableCharging() {
        let success = smcService.setChargingEnabled(true)
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.appState.isChargingEnabled = true
            }
        }
    }

    func disableCharging() {
        let success = smcService.setChargingEnabled(false)
        appLog("[ChargingController] disableCharging() result: \(success)")
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.appState.isChargingEnabled = false
            }
        } else {
            appLog("[ChargingController] WARNING: Failed to disable charging via SMC")
        }
    }

    func setMode(_ mode: ChargingMode) {
        DispatchQueue.main.async { [weak self] in
            self?.appState.currentMode = mode
            self?.safeEvaluate()
        }
    }

    func applyChargeLimit(_ limit: Int) {
        let clamped = max(20, min(100, limit))
        // Set BCLM - Apple Silicon only supports 80 or 100
        let bclmValue: UInt8 = clamped <= 80 ? 80 : 100
        _ = smcService.setBatteryChargeLimit(bclmValue)
        // Update state on main thread, then evaluate with correct values
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.appState.chargeLimit = clamped
            self.appState.settings.chargeLimit = clamped
            self.appState.settings.save()
            // Snapshot state on main thread before dispatching
            self.safeEvaluate()
        }
    }

    // MARK: - Core Control Loop

    /// Snapshot state on the main thread, then dispatch evaluation to background queue.
    /// Can be called from any thread — if on main, snapshots directly; otherwise dispatches to main first.
    private func safeEvaluate() {
        let doSnapshot = { [weak self] in
            guard let self else { return }
            guard self.appState.hasInitialReading else { return }
            let level = self.appState.batteryLevel
            let limit = self.appState.chargeLimit
            let mode = self.appState.currentMode
            let heatEnabled = self.appState.settings.heatProtectionEnabled
            let heatThreshold = self.appState.settings.heatProtectionThreshold
            let sailingLow = self.appState.settings.sailingLow
            let sailingHigh = self.appState.settings.sailingHigh
            let preventSleep = self.appState.settings.preventSleepWhileCharging
            let fullyCharged = self.appState.fullyCharged
            let chargeLimit = self.appState.settings.chargeLimit
            self.queue.async {
                self.evaluateAndAct(
                    level: level, limit: limit, mode: mode,
                    heatEnabled: heatEnabled, heatThreshold: heatThreshold,
                    sailingLow: sailingLow, sailingHigh: sailingHigh,
                    preventSleep: preventSleep, fullyCharged: fullyCharged,
                    chargeLimit: chargeLimit
                )
            }
        }
        if Thread.isMainThread {
            doSnapshot()
        } else {
            DispatchQueue.main.async { doSnapshot() }
        }
    }

    private func evaluateAndAct(
        level: Int, limit: Int, mode: ChargingMode,
        heatEnabled: Bool, heatThreshold: Double,
        sailingLow: Int, sailingHigh: Int,
        preventSleep: Bool, fullyCharged: Bool,
        chargeLimit: Int
    ) {

        // Check for heat protection override
        if heatEnabled, let thermal = thermalService {
            if thermal.isOverheating(threshold: heatThreshold) {
                handleHeatProtection()
                return
            }
        }

        switch mode {
        case .normal:
            handleNormalMode(level: level, limit: limit, preventSleep: preventSleep)
        case .topUp:
            handleTopUp(level: level, fullyCharged: fullyCharged, chargeLimit: chargeLimit)
        case .sailing:
            handleSailingMode(level: level, sailingLow: sailingLow, sailingHigh: sailingHigh)
        case .discharge:
            handleDischarge()
        case .calibration:
            handleCalibration(level: level)
        case .heatProtection:
            handleHeatProtection()
        }

        // Update MagSafe LED
        magSafeLEDService?.updateLED(for: appState)
    }

    private func handleNormalMode(level: Int, limit: Int, preventSleep: Bool) {
        if level >= limit {
            disableCharging()
            _ = smcService.setChargeInhibit(true)
            powerAssertionService?.allowSleep()
            appLog("[ChargingController] Battery \(level)% >= limit \(limit)%, charging disabled + inhibited")
        } else {
            _ = smcService.setChargeInhibit(false)
            enableCharging()
            if preventSleep {
                powerAssertionService?.preventSleep(reason: "Charging to limit")
            }
            appLog("[ChargingController] Battery \(level)% < limit \(limit)%, charging enabled")
        }
    }

    private func handleTopUp(level: Int, fullyCharged: Bool, chargeLimit: Int) {
        // Temporarily charge to 100%
        _ = smcService.setBatteryChargeLimit(100)
        enableCharging()

        if level >= 100 || fullyCharged {
            // Revert to normal mode
            let normalLimit: UInt8 = chargeLimit <= 80 ? 80 : 100
            _ = smcService.setBatteryChargeLimit(normalLimit)
            setMode(.normal)
        }
    }

    private func handleSailingMode(level: Int, sailingLow: Int, sailingHigh: Int) {
        let low = sailingLow
        let high = sailingHigh

        if level < low {
            enableCharging()
        } else if level > high {
            forceDischarge()
        } else {
            // In range - disable charging, stop discharge
            disableCharging()
            _ = smcService.setChargeInhibit(false)
        }
    }

    private func handleDischarge() {
        forceDischarge()
    }

    private func handleCalibration(level: Int) {
        calibrationService?.tick(currentLevel: level)
    }

    private func handleHeatProtection() {
        disableCharging()
        if appState.currentMode != .heatProtection {
            DispatchQueue.main.async { [weak self] in
                self?.appState.currentMode = .heatProtection
            }
        }
    }

    private func forceDischarge() {
        disableCharging()
        _ = smcService.setChargeInhibit(true)
    }

    // MARK: - Cleanup

    func restoreDefaults() {
        enableCharging()
        _ = smcService.setChargeInhibit(false)
        _ = smcService.setBatteryChargeLimit(100)
        powerAssertionService?.allowSleep()
    }
}
