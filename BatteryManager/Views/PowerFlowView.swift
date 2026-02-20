import SwiftUI

struct CompactPowerFlowView: View {
    let appState: AppState
    @State private var dotPhase: CGFloat = 0
    @State private var glowPhase: CGFloat = 0.4

    // The dot takes 3s per segment. Phase 0→1 = left arrow, 1→2 = right arrow.
    private let cycleDuration: Double = 6.0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Power Flow")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 0) {
                CompactPowerNode(
                    icon: "powerplug.fill",
                    label: "Adapter",
                    sublabel: appState.isPluggedIn ? String(format: "%.1fW", appState.wattage) : "Off",
                    isActive: appState.isPluggedIn
                )

                CompactFlowArrow(
                    isActive: appState.isCharging,
                    dotProgress: dotPhase <= 1 ? dotPhase : nil,
                    glowOpacity: glowPhase
                )
                .frame(width: 40)

                CompactPowerNode(
                    icon: batteryIcon,
                    label: "Battery",
                    sublabel: "\(appState.batteryLevel)%",
                    isActive: true
                )

                CompactFlowArrow(
                    isActive: true,
                    dotProgress: dotPhase > 1 ? dotPhase - 1 : nil,
                    glowOpacity: glowPhase
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
        .padding(.horizontal, 4)
        .onAppear {
            // Sequential dot: 0→1 left side, 1→2 right side
            withAnimation(.linear(duration: cycleDuration).repeatForever(autoreverses: false)) {
                dotPhase = 2
            }
            // Glow pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                glowPhase = 1.0
            }
        }
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

struct CompactFlowArrow: View {
    let isActive: Bool
    let dotProgress: CGFloat?  // nil = no dot shown on this segment
    let glowOpacity: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let midY = geometry.size.height / 2

            ZStack {
                // Line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: width, y: midY))
                }
                .stroke(isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)

                // Animated dot with glow
                if isActive, let progress = dotProgress {
                    let dotX = width * min(max(progress, 0), 1)

                    // Glow
                    Circle()
                        .fill(Color.blue.opacity(0.3 * glowOpacity))
                        .frame(width: 12, height: 12)
                        .blur(radius: 3)
                        .position(x: dotX, y: midY)

                    // Dot
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                        .shadow(color: .blue.opacity(0.6 * glowOpacity), radius: 3)
                        .position(x: dotX, y: midY)
                }

                // Arrow head
                Image(systemName: "chevron.right")
                    .font(.system(size: 6))
                    .foregroundStyle(isActive ? .blue : .gray.opacity(0.5))
                    .position(x: width / 2, y: midY - 8)
            }
        }
    }
}
