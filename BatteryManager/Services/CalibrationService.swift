import Foundation

final class CalibrationService {
    private let appState: AppState
    private let smcService: SMCService
    private(set) var state: CalibrationState = .idle

    init(appState: AppState, smcService: SMCService) {
        self.appState = appState
        self.smcService = smcService
    }

    func startCalibration(drainTo: Int = 15) {
        state = .dischargingTo(percent: drainTo)
        DispatchQueue.main.async { [weak self] in
            self?.appState.currentMode = .calibration
        }
    }

    func cancelCalibration() {
        state = .idle
        // Re-enable charging
        _ = smcService.setChargingEnabled(true)
        _ = smcService.setChargeInhibit(false)
        DispatchQueue.main.async { [weak self] in
            self?.appState.currentMode = .normal
        }
    }

    func tick(currentLevel: Int) {
        switch state {
        case .idle, .complete:
            return

        case .dischargingTo(let target):
            // Force discharge
            _ = smcService.setChargingEnabled(false)
            _ = smcService.setChargeInhibit(true)

            if currentLevel <= target {
                // Transition to charging phase
                state = .chargingTo100
                _ = smcService.setChargeInhibit(false)
                _ = smcService.setBatteryChargeLimit(100)
                _ = smcService.setChargingEnabled(true)
            }

        case .chargingTo100:
            _ = smcService.setBatteryChargeLimit(100)
            _ = smcService.setChargingEnabled(true)

            if currentLevel >= 100 || appState.fullyCharged {
                // Calibration complete
                let completionDate = Date()
                state = .complete(date: completionDate)

                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.appState.settings.lastCalibrationDate = completionDate
                    self.appState.settings.save()
                    self.appState.currentMode = .normal
                }

                // Restore normal charge limit
                let normalLimit: UInt8 = appState.settings.chargeLimit <= 80 ? 80 : 100
                _ = smcService.setBatteryChargeLimit(normalLimit)
            }
        }
    }
}
