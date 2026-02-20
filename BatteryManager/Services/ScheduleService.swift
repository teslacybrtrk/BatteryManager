import Foundation

final class ScheduleService {
    private let appState: AppState
    private let chargingController: ChargingController
    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.batterymanager.schedule", qos: .utility)
    private(set) var schedules: [Schedule] = []
    private var isOverriding = false

    init(appState: AppState, chargingController: ChargingController) {
        self.appState = appState
        self.chargingController = chargingController
        loadSchedules()
    }

    func startEvaluating() {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: 60.0)
        timer?.setEventHandler { [weak self] in
            self?.evaluate()
        }
        timer?.resume()
    }

    func stopEvaluating() {
        timer?.cancel()
        timer = nil
    }

    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        saveSchedules()
    }

    func removeSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
        saveSchedules()
    }

    func toggleSchedule(id: UUID, enabled: Bool) {
        if let index = schedules.firstIndex(where: { $0.id == id }) {
            schedules[index].isEnabled = enabled
            saveSchedules()
        }
    }

    // MARK: - Private

    private func evaluate() {
        let activeSchedule = schedules.first { $0.isActiveNow() }

        if let schedule = activeSchedule {
            if !isOverriding {
                isOverriding = true
                chargingController.applyChargeLimit(schedule.targetPercent)
            }
        } else if isOverriding {
            isOverriding = false
            chargingController.applyChargeLimit(appState.settings.chargeLimit)
        }
    }

    private static let schedulesKey = "BatteryManagerSchedules"

    private func loadSchedules() {
        guard let data = UserDefaults.standard.data(forKey: Self.schedulesKey),
              let decoded = try? JSONDecoder().decode([Schedule].self, from: data) else {
            return
        }
        schedules = decoded
    }

    private func saveSchedules() {
        if let data = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(data, forKey: Self.schedulesKey)
        }
    }
}
