import SwiftUI

struct PowerFlowView: View {
    let appState: AppState
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        VStack(spacing: 16) {
            // Three-node diagram
            HStack(spacing: 0) {
                // Adapter Node
                PowerNode(
                    icon: "powerplug.fill",
                    label: "Adapter",
                    sublabel: appState.isPluggedIn ? String(format: "%.1fW", appState.wattage) : "Disconnected",
                    isActive: appState.isPluggedIn
                )

                // Flow Arrow: Adapter → Battery
                FlowArrow(
                    isActive: appState.isCharging,
                    isReversed: false,
                    animationPhase: animationPhase
                )
                .frame(width: 50)

                // Battery Node
                PowerNode(
                    icon: batteryIcon,
                    label: "Battery",
                    sublabel: "\(appState.batteryLevel)%",
                    isActive: true
                )

                // Flow Arrow: Battery → System
                FlowArrow(
                    isActive: true,
                    isReversed: false,
                    animationPhase: animationPhase
                )
                .frame(width: 50)

                // System Node
                PowerNode(
                    icon: "desktopcomputer",
                    label: "System",
                    sublabel: "Active",
                    isActive: true
                )
            }
            .padding(.horizontal)

            Divider()

            // Status Details
            VStack(spacing: 6) {
                HStack {
                    Text("Charging")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appState.isCharging ? "Yes" : "No")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(appState.isCharging ? .green : .secondary)
                }
                HStack {
                    Text("Power Source")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appState.isPluggedIn ? "AC Power" : "Battery")
                        .font(.system(size: 10, weight: .medium))
                }
                HStack {
                    Text("Mode")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appState.currentMode.displayName)
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .padding(.horizontal)
        }
        .padding()
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

struct PowerNode: View {
    let icon: String
    let label: String
    let sublabel: String
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isActive ? .blue : .gray)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isActive ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
                )
            Text(label)
                .font(.system(size: 9, weight: .medium))
            Text(sublabel)
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowArrow: View {
    let isActive: Bool
    let isReversed: Bool
    let animationPhase: CGFloat

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
                .stroke(isActive ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 2)

                // Animated dots
                if isActive {
                    let dotX = isReversed ? width * (1 - animationPhase) : width * animationPhase
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 5, height: 5)
                        .position(x: dotX, y: midY)
                }

                // Arrow head
                Image(systemName: isReversed ? "chevron.left" : "chevron.right")
                    .font(.system(size: 8))
                    .foregroundStyle(isActive ? .blue : .gray.opacity(0.5))
                    .position(x: width / 2, y: midY - 10)
            }
        }
    }
}
