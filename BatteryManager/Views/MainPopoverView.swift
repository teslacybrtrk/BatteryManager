import SwiftUI

enum PopoverTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case stats = "Stats"
    case schedule = "Schedule"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .dashboard: return "battery.75percent"
        case .stats: return "chart.bar.fill"
        case .schedule: return "clock.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainPopoverView: View {
    let appState: AppState
    var updateChecker: UpdateChecker?
    var helperInstaller: HelperInstaller?
    var onLimitChanged: ((Int) -> Void)?
    var onModeChanged: ((ChargingMode) -> Void)?
    var onScheduleAction: ((ScheduleAction) -> Void)?
    var onHelperInstalled: (() -> Void)?
    var onHeightChanged: ((CGFloat) -> Void)?

    @State private var selectedTab: PopoverTab = .dashboard
    @State private var updateDismissed = false
    @State private var isHoveringDismiss = false

    static func heightForTab(_ tab: PopoverTab) -> CGFloat {
        switch tab {
        case .dashboard: return 520
        case .stats: return 480
        case .schedule: return 420
        case .settings: return 660
        }
    }

    var body: some View {
        ZStack {
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
                        .contentShape(Rectangle())
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
                VStack(spacing: 6) {
                    if checker.isDownloading {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundStyle(.orange)
                            ProgressView(value: checker.downloadProgress)
                                .tint(.orange)
                                .frame(maxWidth: .infinity)
                            Text("\(Int(checker.downloadProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .monospacedDigit()
                        }
                    } else {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Update Available")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("A new version is ready to install.")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button {
                                updateDismissed = true
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .frame(width: 20, height: 20)
                                    .background(
                                        Circle()
                                            .fill(isHoveringDismiss ? Color.primary.opacity(0.1) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                isHoveringDismiss = hovering
                            }
                        }

                        Button {
                            checker.performUpdate()
                        } label: {
                            Text("Install Update")
                                .font(.system(size: 11, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(.orange.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }

            // Content
            Group {
                switch selectedTab {
                case .dashboard:
                    dashboardTab
                case .stats:
                    StatsView(appState: appState)
                case .schedule:
                    ScheduleView(appState: appState, onAction: onScheduleAction)
                case .settings:
                    SettingsView(appState: appState, updateChecker: updateChecker, helperInstaller: helperInstaller)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } // end VStack

        // Helper install overlay
        if appState.needsHelperInstall, let installer = helperInstaller, !installer.isInstalled {
            helperInstallOverlay(installer: installer)
        }
        } // end ZStack
        .frame(width: 320, height: Self.heightForTab(selectedTab))
        .onChange(of: selectedTab) { _, newTab in
            onHeightChanged?(Self.heightForTab(newTab))
        }
        .onChange(of: helperInstaller?.isInstalled) { _, installed in
            if installed == true {
                appState.needsHelperInstall = false
                onHelperInstalled?()
            }
        }
    }

    @ViewBuilder
    private func helperInstallOverlay(installer: HelperInstaller) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)

                Text("One-Time Setup")
                    .font(.system(size: 16, weight: .bold))

                Text("BatteryManager needs to install a small helper tool to control your battery's charging hardware.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Label("Set and enforce charge limits", systemImage: "checkmark.circle.fill")
                    Label("Toggle charging on/off", systemImage: "checkmark.circle.fill")
                    Label("Enable sailing and discharge modes", systemImage: "checkmark.circle.fill")
                }
                .font(.system(size: 10))
                .foregroundStyle(.secondary)

                Text("You'll be asked for your admin password. This only needs to happen once.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                if let error = installer.installError {
                    Text(error)
                        .font(.system(size: 10))
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                Button {
                    installer.install()
                } label: {
                    HStack {
                        if installer.isInstalling {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "key.fill")
                        }
                        Text(installer.isInstalling ? "Installing..." : "Install Helper")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(installer.isInstalling)
                .padding(.horizontal, 32)

                Button("Skip (charging control won\u{2019}t work)") {
                    appState.needsHelperInstall = false
                }
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
            .padding(12)
        }
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

                Divider()
                    .padding(.horizontal)

                CompactPowerFlowView(appState: appState)
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
