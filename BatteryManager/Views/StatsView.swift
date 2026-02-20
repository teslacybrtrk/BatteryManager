import SwiftUI

struct StatsView: View {
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Health Section
                VStack(spacing: 6) {
                    SectionHeader(title: "Battery Health")

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.1f%%", appState.healthPercent))
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(healthColor)
                            Text(appState.batteryHealthDescription)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        CircularProgressView(progress: appState.healthPercent / 100.0, color: healthColor)
                            .frame(width: 50, height: 50)
                    }
                }

                Divider()

                // Detailed Stats
                VStack(spacing: 6) {
                    SectionHeader(title: "Details")

                    StatRow(label: "Cycle Count", value: "\(appState.cycleCount) / 1000")
                    StatRow(label: "Temperature", value: String(format: "%.1f\u{00B0}C", appState.temperature),
                            valueColor: temperatureColor)
                    StatRow(label: "Voltage", value: String(format: "%.2f V", appState.voltage))
                    StatRow(label: "Amperage", value: String(format: "%.0f mA", appState.amperage))
                    StatRow(label: "Power", value: String(format: "%.1f W", appState.wattage))
                }

                Divider()

                // Capacity
                VStack(spacing: 6) {
                    SectionHeader(title: "Capacity")

                    StatRow(label: "Current", value: "\(appState.currentCapacity) mAh")
                    StatRow(label: "Maximum", value: "\(appState.maxCapacity) mAh")
                    StatRow(label: "Design", value: "\(appState.designCapacity) mAh")

                    // Capacity bar
                    GeometryReader { geometry in
                        let totalWidth = geometry.size.width
                        let maxRatio = appState.designCapacity > 0 ? CGFloat(appState.maxCapacity) / CGFloat(appState.designCapacity) : 1.0
                        let currentRatio = appState.maxCapacity > 0 ? CGFloat(appState.currentCapacity) / CGFloat(appState.maxCapacity) : 0

                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 12)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: totalWidth * min(maxRatio, 1.0), height: 12)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.blue)
                                .frame(width: totalWidth * min(maxRatio, 1.0) * currentRatio, height: 12)
                        }
                    }
                    .frame(height: 12)
                }

                // Time remaining
                if let timeToEmpty = appState.timeToEmpty, !appState.isPluggedIn {
                    Divider()
                    StatRow(label: "Time Remaining", value: formatMinutes(timeToEmpty))
                }
                if let timeToFull = appState.timeToFull, appState.isCharging {
                    Divider()
                    StatRow(label: "Time to Full", value: formatMinutes(timeToFull))
                }
            }
            .padding()
        }
    }

    private var healthColor: Color {
        let health = appState.healthPercent
        if health >= 90 { return .green }
        if health >= 80 { return .yellow }
        return .red
    }

    private var temperatureColor: Color {
        if appState.temperature >= 40 { return .red }
        if appState.temperature >= 35 { return .orange }
        return .primary
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes <= 0 { return "Calculating..." }
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(valueColor)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
