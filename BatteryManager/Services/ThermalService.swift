import Foundation

final class ThermalService {
    private let smcService: SMCService

    init(smcService: SMCService) {
        self.smcService = smcService
    }

    func readMaxTemperature() -> Double? {
        return smcService.readBatteryTemperature()
    }

    func isOverheating(threshold: Double) -> Bool {
        guard let temp = readMaxTemperature() else { return false }
        return temp >= threshold
    }
}
