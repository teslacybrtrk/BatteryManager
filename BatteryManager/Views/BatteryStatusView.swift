import SwiftUI

struct BatteryStatusView: View {
    let appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            // Battery Level Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: CGFloat(appState.batteryLevel) / 100.0)
                    .stroke(batteryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(appState.batteryLevel)%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))

                    if appState.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.yellow)
                    }
                }
            }

            // Status Badge
            HStack(spacing: 6) {
                Image(systemName: appState.currentMode.systemImage)
                    .font(.system(size: 11))
                Text(appState.currentMode.displayName)
                    .font(.system(size: 11, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modeColor.opacity(0.15))
            .foregroundStyle(modeColor)
            .clipShape(Capsule())

            // Quick Info Row
            HStack(spacing: 16) {
                InfoPill(icon: "powerplug.fill", value: appState.isPluggedIn ? "AC" : "Battery")
                InfoPill(icon: "thermometer.medium", value: String(format: "%.1f\u{00B0}C", appState.temperature))
                InfoPill(icon: "bolt.fill", value: String(format: "%.1fW", appState.wattage))
            }
        }
        .padding(.vertical, 8)
    }

    private var batteryColor: Color {
        let level = appState.batteryLevel
        if level > 60 { return .green }
        if level > 20 { return .yellow }
        return .red
    }

    private var modeColor: Color {
        switch appState.currentMode {
        case .normal: return .blue
        case .topUp: return .green
        case .sailing: return .cyan
        case .discharge: return .orange
        case .calibration: return .purple
        case .heatProtection: return .red
        }
    }
}

struct InfoPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(value)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(.secondary)
    }
}
