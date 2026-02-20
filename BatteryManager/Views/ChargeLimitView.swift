import SwiftUI

struct ChargeLimitView: View {
    let appState: AppState
    var onLimitChanged: ((Int) -> Void)?
    var onModeChanged: ((ChargingMode) -> Void)?

    @State private var sliderValue: Double = 80

    var body: some View {
        VStack(spacing: 12) {
            // Charge Limit Slider
            VStack(spacing: 6) {
                HStack {
                    Text("Charge Limit")
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(Int(sliderValue))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                }

                Slider(value: $sliderValue, in: 20...100, step: 5) {
                    Text("Charge Limit")
                } onEditingChanged: { editing in
                    if !editing {
                        onLimitChanged?(Int(sliderValue))
                    }
                }
                .tint(.blue)

                HStack {
                    Text("20%")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("80%")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Quick Mode Buttons
            VStack(spacing: 6) {
                Text("Quick Actions")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    ModeButton(title: "Top Up", icon: "battery.100percent.bolt", isActive: appState.currentMode == .topUp) {
                        onModeChanged?(.topUp)
                    }
                    ModeButton(title: "Sailing", icon: "wind", isActive: appState.currentMode == .sailing) {
                        onModeChanged?(.sailing)
                    }
                    ModeButton(title: "Discharge", icon: "battery.25percent", isActive: appState.currentMode == .discharge) {
                        onModeChanged?(.discharge)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            sliderValue = Double(appState.chargeLimit)
        }
        .onChange(of: appState.chargeLimit) { _, newValue in
            sliderValue = Double(newValue)
        }
    }
}

struct ModeButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
            .foregroundStyle(isActive ? Color.accentColor : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
