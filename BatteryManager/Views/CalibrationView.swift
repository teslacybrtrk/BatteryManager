import SwiftUI

struct CalibrationView: View {
    let appState: AppState
    let calibrationState: CalibrationState
    var onStart: (() -> Void)?
    var onCancel: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Text("Battery Calibration")
                .font(.system(size: 13, weight: .semibold))

            Text("Calibration performs a full discharge-charge cycle to help macOS recalibrate the battery level indicator.")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let lastDate = appState.settings.lastCalibrationDate {
                Text("Last calibrated: \(lastDate, style: .date)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // Current State
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(calibrationState.isRunning ? Color.orange : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(calibrationState.displayName)
                        .font(.system(size: 12, weight: .medium))
                }

                if calibrationState.isRunning {
                    ProgressView(value: calibrationProgress)
                        .tint(.purple)

                    Button("Cancel Calibration") {
                        onCancel?()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                } else {
                    Button("Start Calibration") {
                        onStart?()
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
        }
        .padding()
    }

    private var calibrationProgress: Double {
        switch calibrationState {
        case .idle: return 0
        case .dischargingTo: return 0.3
        case .chargingTo100: return 0.7
        case .complete: return 1.0
        }
    }
}
