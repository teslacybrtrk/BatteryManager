import SwiftUI

enum PopoverTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case stats = "Stats"
    case powerFlow = "Power Flow"
    case schedule = "Schedule"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "battery.75percent"
        case .stats: return "chart.bar.fill"
        case .powerFlow: return "arrow.left.arrow.right"
        case .schedule: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainPopoverView: View {
    let appState: AppState
    var updateChecker: UpdateChecker?
    var onLimitChanged: ((Int) -> Void)?
    var onModeChanged: ((ChargingMode) -> Void)?
    var onScheduleAction: ((ScheduleAction) -> Void)?

    @State private var selectedTab: PopoverTab = .dashboard
    @State private var updateDismissed = false
    @State private var isHoveringDismiss = false

    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(PopoverTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedTab == tab ? Color.accentColor.opacity(0.12) : Color.clear)
                        )
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            Divider()
                .padding(.horizontal)

            // Update banner
            if let checker = updateChecker, checker.updateAvailable, !updateDismissed {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.blue)

                    if checker.isDownloading {
                        ProgressView(value: checker.downloadProgress)
                            .frame(maxWidth: .infinity)
                        Text("\(Int(checker.downloadProgress * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    } else {
                        Text("Update available")
                            .font(.caption)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            updateDismissed = true
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .frame(width: 18, height: 18)
                                .background(
                                    Circle()
                                        .fill(isHoveringDismiss ? Color.primary.opacity(0.1) : Color.clear)
                                )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringDismiss = hovering
                        }

                        Button("Update") {
                            checker.performUpdate()
                        }
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue.opacity(0.08))
                )
                .padding(.horizontal, 8)
            }

            // Content
            Group {
                switch selectedTab {
                case .dashboard:
                    dashboardTab
                case .stats:
                    StatsView(appState: appState)
                case .powerFlow:
                    PowerFlowView(appState: appState)
                case .schedule:
                    ScheduleView(appState: appState, onAction: onScheduleAction)
                case .settings:
                    SettingsView(appState: appState, updateChecker: updateChecker)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 320, height: 420)
    }

    private var dashboardTab: some View {
        ScrollView {
            VStack(spacing: 12) {
                BatteryStatusView(appState: appState)

                Divider()
                    .padding(.horizontal)

                ChargeLimitView(
                    appState: appState,
                    onLimitChanged: onLimitChanged,
                    onModeChanged: onModeChanged
                )
            }
            .padding()
        }
    }
}

enum ScheduleAction {
    case add(Schedule)
    case remove(UUID)
    case toggle(UUID, Bool)
}
