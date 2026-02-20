import Foundation

@Observable
final class ScheduleViewModel {
    private let scheduleService: ScheduleService

    init(scheduleService: ScheduleService) {
        self.scheduleService = scheduleService
    }

    var schedules: [Schedule] {
        scheduleService.schedules
    }

    func addSchedule(_ schedule: Schedule) {
        scheduleService.addSchedule(schedule)
    }

    func removeSchedule(id: UUID) {
        scheduleService.removeSchedule(id: id)
    }

    func toggleSchedule(id: UUID, enabled: Bool) {
        scheduleService.toggleSchedule(id: id, enabled: enabled)
    }
}
