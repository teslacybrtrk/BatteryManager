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
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 30.0)
        timer?.setEventHandler { [weak self] in
            self?.evaluateAndAct()
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
        if success {
            DispatchQueue.main.async { [weak self] in
                self?.appState.isChargingEnabled = false
            }
        }
    }

    func setMode(_ mode: ChargingMode) {
        DispatchQueue.main.async { [weak self] in
            self?.appState.currentMode = mode
        }
        // Immediately evaluate
        queue.async { [weak self] in
            self?.evaluateAndAct()
        }
    }

    func applyChargeLimit(_ limit: Int) {
        let clamped = max(20, min(100, limit))
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.appState.chargeLimit = clamped
            self.appState.settings.chargeLimit = clamped
            self.appState.settings.save()
        }
        // Set BCLM - Apple Silicon only supports 80 or 100
        let bclmValue: UInt8 = clamped <= 80 ? 80 : 100
        _ = smcService.setBatteryChargeLimit(bclmValue)
        // Immediately evaluate
        queue.async { [weak self] in
            self?.evaluateAndAct()
        }
    }

    // MARK: - Core Control Loop

    private func evaluateAndAct() {
        let level = appState.batteryLevel
        let limit = appState.chargeLimit
        let mode = appState.currentMode

        // Check for heat protection override
        if appState.settings.heatProtectionEnabled, let thermal = thermalService {
            if thermal.isOverheating(threshold: appState.settings.heatProtectionThreshold) {
                handleHeatProtection()
                return
            }
        }

        switch mode {
        case .normal:
            handleNormalMode(level: level, limit: limit)
        case .topUp:
            handleTopUp(level: level)
        case .sailing:
            handleSailingMode(level: level)
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

    private func handleNormalMode(level: Int, limit: Int) {
        if level >= limit {
            disableCharging()
            powerAssertionService?.allowSleep()
        } else {
            enableCharging()
            if appState.settings.preventSleepWhileCharging {
                powerAssertionService?.preventSleep(reason: "Charging to limit")
            }
        }
    }

    private func handleTopUp(level: Int) {
        // Temporarily charge to 100%
        _ = smcService.setBatteryChargeLimit(100)
        enableCharging()

        if level >= 100 || appState.fullyCharged {
            // Revert to normal mode
            let normalLimit: UInt8 = appState.settings.chargeLimit <= 80 ? 80 : 100
            _ = smcService.setBatteryChargeLimit(normalLimit)
            setMode(.normal)
        }
    }

    private func handleSailingMode(level: Int) {
        let low = appState.settings.sailingLow
        let high = appState.settings.sailingHigh

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
