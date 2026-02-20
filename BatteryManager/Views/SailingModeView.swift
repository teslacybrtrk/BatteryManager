import SwiftUI

struct SailingModeView: View {
    let appState: AppState
    var onActivate: ((Int, Int) -> Void)?

    @State private var lowBound: Double = 65
    @State private var highBound: Double = 80
    @State private var isActive: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Sailing Mode")
                .font(.system(size: 13, weight: .semibold))

            Text("Maintain battery level within a range while on AC power")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 8) {
                HStack {
                    Text("Low: \(Int(lowBound))%")
                        .font(.system(size: 11))
                    Spacer()
                    Text("High: \(Int(highBound))%")
                        .font(.system(size: 11))
                }

                Slider(value: $lowBound, in: 20...Double(Int(highBound) - 5), step: 5)
                    .tint(.cyan)

                Slider(value: $highBound, in: Double(Int(lowBound) + 5)...100, step: 5)
                    .tint(.cyan)

                // Visual range indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 8)

                        let totalWidth = geometry.size.width
                        let lowOffset = (lowBound - 20) / 80 * totalWidth
                        let rangeWidth = (highBound - lowBound) / 80 * totalWidth

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.cyan.opacity(0.4))
                            .frame(width: rangeWidth, height: 8)
                            .offset(x: lowOffset)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 4)

            Toggle("Activate Sailing Mode", isOn: $isActive)
                .toggleStyle(.switch)
                .font(.system(size: 11))
                .onChange(of: isActive) { _, newValue in
                    if newValue {
                        onActivate?(Int(lowBound), Int(highBound))
                    }
                }
        }
        .padding()
        .onAppear {
            lowBound = Double(appState.settings.sailingLow)
            highBound = Double(appState.settings.sailingHigh)
            isActive = appState.currentMode == .sailing
        }
    }
}
