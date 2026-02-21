import Foundation

/// In-memory log buffer for debugging. Captures print-style messages.
final class AppLogger {
    static let shared = AppLogger()

    private var entries: [String] = []
    private let queue = DispatchQueue(label: "com.batterymanager.logger")
    private let maxEntries = 200

    private init() {}

    func log(_ message: String) {
        let timestamp = Self.formatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        queue.async { [weak self] in
            guard let self else { return }
            self.entries.append(entry)
            if self.entries.count > self.maxEntries {
                self.entries.removeFirst(self.entries.count - self.maxEntries)
            }
        }
    }

    func getEntries() -> [String] {
        queue.sync { entries }
    }

    func allText() -> String {
        getEntries().joined(separator: "\n")
    }

    func clear() {
        queue.async { [weak self] in
            self?.entries.removeAll()
        }
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}

/// Drop-in replacement for print() that also logs to AppLogger
func appLog(_ message: String) {
    print(message)
    AppLogger.shared.log(message)
}
