import SwiftUI

struct CompactPowerFlowView: View {
    let appState: AppState

    // Total cycle: 3s left segment + 3s right segment = 6s
    private let segmentDuration: Double = 3.0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Power Flow")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let cycleDuration = segmentDuration * 2
                let phase = time.truncatingRemainder(dividingBy: cycleDuration)
                let glowPulse = 0.5 + 0.5 * sin(time * 3.0) // smooth pulse

                let leftProgress: CGFloat? = phase < segmentDuration
                    ? CGFloat(phase / segmentDuration)
                    : nil

                let rightProgress: CGFloat? = phase >= segmentDuration
                    ? CGFloat((phase - segmentDuration) / segmentDuration)
                    : nil

                HStack(spacing: 0) {
                    CompactPowerNode(
                        icon: "powerplug.fill",
                        label: "Adapter",
                        sublabel: appState.isPluggedIn ? String(format: "%.1fW", appState.wattage) : "Off",
                        isActive: appState.isPluggedIn
                    )

                    FlowSegment(
                        isActive: appState.isCharging,
                        dotProgress: appState.isCharging ? leftProgress : nil,
                        glowIntensity: glowPulse
                    )
                    .frame(width: 40)

                    CompactPowerNode(
                        icon: batteryIcon,
                        label: "Battery",
                        sublabel: "\(appState.batteryLevel)%",
                        isActive: true
                    )

                    FlowSegment(
                        isActive: true,
                        dotProgress: rightProgress,
                        glowIntensity: glowPulse
                    )
                    .frame(width: 40)

                    CompactPowerNode(
                        icon: "desktopcomputer",
                        label: "System",
                        sublabel: "Active",
                        isActive: true
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var batteryIcon: String {
        let level = appState.batteryLevel
        if level > 75 { return "battery.100percent" }
        if level > 50 { return "battery.75percent" }
        if level > 25 { return "battery.50percent" }
        return "battery.25percent"
    }
}

struct CompactPowerNode: View {
    let icon: String
    let label: String
    let sublabel: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isActive ? .blue : .gray)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
            Text(label)
                .font(.system(size: 8, weight: .medium))
            Text(sublabel)
                .font(.system(size: 7))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowSegment: View {
    let isActive: Bool
    let dotProgress: CGFloat?
    let glowIntensity: Double

    var body: some View {
        Canvas { context, size in
            let midY = size.height / 2
            let width = size.width

            // Draw the line
            var linePath = Path()
            linePath.move(to: CGPoint(x: 0, y: midY))
            linePath.addLine(to: CGPoint(x: width, y: midY))
            context.stroke(
                linePath,
                with: .color(isActive ? Color.blue.opacity(0.25) : Color.gray.opacity(0.15)),
                lineWidth: 1.5
            )

            // Draw chevron
            let chevronX = width / 2
            let chevronY = midY - 8
            var chevron = Path()
            chevron.move(to: CGPoint(x: chevronX - 2, y: chevronY - 3))
            chevron.addLine(to: CGPoint(x: chevronX + 2, y: chevronY))
            chevron.addLine(to: CGPoint(x: chevronX - 2, y: chevronY + 3))
            context.stroke(
                chevron,
                with: .color(isActive ? Color.blue.opacity(0.6) : Color.gray.opacity(0.3)),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round)
            )

            // Draw the glowing dot
            if isActive, let progress = dotProgress {
                let dotX = width * min(max(progress, 0), 1)
                let dotCenter = CGPoint(x: dotX, y: midY)

                // Outer glow
                let glowRect = CGRect(x: dotX - 7, y: midY - 7, width: 14, height: 14)
                context.fill(
                    Circle().path(in: glowRect),
                    with: .color(Color.blue.opacity(0.2 * glowIntensity))
                )

                // Inner glow
                let innerGlowRect = CGRect(x: dotX - 5, y: midY - 5, width: 10, height: 10)
                context.fill(
                    Circle().path(in: innerGlowRect),
                    with: .color(Color.blue.opacity(0.35 * glowIntensity))
                )

                // Core dot
                let dotRect = CGRect(x: dotX - 2.5, y: midY - 2.5, width: 5, height: 5)
                context.fill(
                    Circle().path(in: dotRect),
                    with: .color(Color.blue)
                )

                _ = dotCenter // suppress unused warning
            }
        }
    }
}
