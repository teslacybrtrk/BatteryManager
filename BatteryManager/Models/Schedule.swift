import Foundation

struct Schedule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var startHour: Int       // 0-23
    var startMinute: Int     // 0-59
    var endHour: Int         // 0-23
    var endMinute: Int       // 0-59
    var targetPercent: Int   // 20-100
    var repeatDays: Set<Int> // 1=Sun, 2=Mon, ..., 7=Sat
    var isEnabled: Bool = true

    var startTimeString: String {
        String(format: "%02d:%02d", startHour, startMinute)
    }

    var endTimeString: String {
        String(format: "%02d:%02d", endHour, endMinute)
    }

    var repeatDaysString: String {
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays.isEmpty { return "Once" }
        let names = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return repeatDays.sorted().compactMap { $0 < names.count ? names[$0] : nil }.joined(separator: ", ")
    }

    func isActiveNow() -> Bool {
        guard isEnabled else { return false }
        let now = Calendar.current.dateComponents([.hour, .minute, .weekday], from: Date())
        guard let hour = now.hour, let minute = now.minute, let weekday = now.weekday else { return false }

        if !repeatDays.isEmpty && !repeatDays.contains(weekday) { return false }

        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        if startMinutes <= endMinutes {
            return currentMinutes >= startMinutes && currentMinutes < endMinutes
        } else {
            // Overnight schedule (e.g., 23:00 - 07:00)
            return currentMinutes >= startMinutes || currentMinutes < endMinutes
        }
    }
}
