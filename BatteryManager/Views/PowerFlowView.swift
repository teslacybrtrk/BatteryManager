import SwiftUI

struct CompactPowerFlowView: View {
    let appState: AppState
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Power Flow")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 0) {
                // Adapter Node
                CompactPowerNode(
                    icon: "powerplug.fill",
                    label: "Adapter",
                    sublabel: appState.isPluggedIn ? String(format: "%.1fW", appState.wattage) : "Off",
                    isActive: appState.isPluggedIn
                )

                // Flow Arrow: Adapter → Battery
                CompactFlowArrow(
                    isActive: appState.isCharging,
                    animationPhase: animationPhase
                )
                .frame(width: 40)

                // Battery Node
                CompactPowerNode(
                    icon: batteryIcon,
                    label: "Battery",
                    sublabel: "\(appState.batteryLevel)%",
                    isActive: true
                )

                // Flow Arrow: Battery → System
                CompactFlowArrow(
                    isActive: true,
                    animationPhase: animationPhase
                )
                .frame(width: 40)

                // System Node
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
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 1
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
    let animationPhase: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let midY = geometry.size.height / 2

            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: midY))
                    path.addLine(to: CGPoint(x: width, y: midY))
                }
                .stroke(isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1.5)

                if isActive {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 4, height: 4)
                        .position(x: width * animationPhase, y: midY)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 6))
                    .foregroundStyle(isActive ? .blue : .gray.opacity(0.5))
                    .position(x: width / 2, y: midY - 8)
            }
        }
    }
}
