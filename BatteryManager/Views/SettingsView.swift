import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let appState: AppState
    var updateChecker: UpdateChecker?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // SMC Warning
                if !appState.smcConnected {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("SMC not connected. Charging control is unavailable. Run with elevated privileges.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.orange.opacity(0.1))
                    )
                }

                // General
                VStack(spacing: 6) {
                    SectionHeader(title: "General")

                    SettingsToggle(
                        title: "Launch at Login",
                        isOn: Binding(
                            get: { appState.settings.launchAtLogin },
                            set: { newValue in
                                appState.settings.launchAtLogin = newValue
                                appState.settings.save()
                                setLaunchAtLogin(newValue)
                            }
                        )
                    )

                    SettingsToggle(
                        title: "Re-enable Charging on Quit",
                        isOn: Binding(
                            get: { appState.settings.stopChargingOnQuit },
                            set: { newValue in
                                appState.settings.stopChargingOnQuit = newValue
                                appState.settings.save()
                            }
                        )
                    )

                    SettingsToggle(
                        title: "Show Battery % in Menu Bar",
                        isOn: Binding(
                            get: { appState.settings.showBatteryPercentInMenuBar },
                            set: { newValue in
                                appState.settings.showBatteryPercentInMenuBar = newValue
                                appState.settings.save()
                            }
                        )
                    )

                    SettingsToggle(
                        title: "Prevent Sleep While Charging",
                        isOn: Binding(
                            get: { appState.settings.preventSleepWhileCharging },
                            set: { newValue in
                                appState.settings.preventSleepWhileCharging = newValue
                                appState.settings.save()
                            }
                        )
                    )
                }

                Divider()

                // Heat Protection
                VStack(spacing: 6) {
                    SectionHeader(title: "Heat Protection")

                    SettingsToggle(
                        title: "Enable Heat Protection",
                        isOn: Binding(
                            get: { appState.settings.heatProtectionEnabled },
                            set: { newValue in
                                appState.settings.heatProtectionEnabled = newValue
                                appState.settings.save()
                            }
                        )
                    )

                    if appState.settings.heatProtectionEnabled {
                        HStack {
                            Text("Threshold")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f\u{00B0}C", appState.settings.heatProtectionThreshold))
                                .font(.system(size: 11, weight: .medium))
                        }

                        Slider(
                            value: Binding(
                                get: { appState.settings.heatProtectionThreshold },
                                set: { newValue in
                                    appState.settings.heatProtectionThreshold = newValue
                                    appState.settings.save()
                                }
                            ),
                            in: 30...50,
                            step: 1
                        )
                        .tint(.orange)
                    }
                }

                Divider()

                // Sailing Mode Defaults
                VStack(spacing: 6) {
                    SectionHeader(title: "Sailing Mode Defaults")

                    HStack {
                        Text("Low Bound")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(appState.settings.sailingLow)%")
                            .font(.system(size: 11, weight: .medium))
                    }

                    Slider(
                        value: Binding(
                            get: { Double(appState.settings.sailingLow) },
                            set: { newValue in
                                appState.settings.sailingLow = Int(newValue)
                                appState.settings.save()
                            }
                        ),
                        in: 20...Double(appState.settings.sailingHigh - 5),
                        step: 5
                    )
                    .tint(.cyan)

                    HStack {
                        Text("High Bound")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(appState.settings.sailingHigh)%")
                            .font(.system(size: 11, weight: .medium))
                    }

                    Slider(
                        value: Binding(
                            get: { Double(appState.settings.sailingHigh) },
                            set: { newValue in
                                appState.settings.sailingHigh = Int(newValue)
                                appState.settings.save()
                            }
                        ),
                        in: Double(appState.settings.sailingLow + 5)...100,
                        step: 5
                    )
                    .tint(.cyan)
                }

                Divider()

                // Updates
                if let checker = updateChecker {
                    VStack(spacing: 6) {
                        SectionHeader(title: "Updates")

                        HStack {
                            Text("Current Build")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(BuildInfo.commitSHA.prefix(7)))
                                .font(.system(size: 11, design: .monospaced))
                        }

                        if let lastCheck = checker.lastCheckDate {
                            HStack {
                                Text("Last Checked")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(lastCheck, style: .relative)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if checker.updateAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 11))
                                Text("Update available")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.blue)
                            }
                        }

                        Button {
                            checker.checkForUpdate()
                        } label: {
                            HStack(spacing: 4) {
                                if checker.isChecking {
                                    ProgressView()
                                        .controlSize(.small)
                                        .scaleEffect(0.7)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Check for Updates")
                            }
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.bordered)
                        .disabled(checker.isChecking)
                    }

                    Divider()
                }

                // About
                VStack(spacing: 6) {
                    SectionHeader(title: "About")
                    Text("BatteryManager")
                        .font(.system(size: 11, weight: .medium))
                    Text("Build \(String(BuildInfo.commitSHA.prefix(7)))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Button {
                        NSApplication.shared.terminate(nil)
                    } label: {
                        HStack {
                            Image(systemName: "power")
                            Text("Quit BatteryManager")
                        }
                        .font(.system(size: 11))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .padding(.top, 4)
                }
            }
            .padding()
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("[Settings] Failed to set launch at login: \(error)")
        }
    }
}

struct SettingsToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .toggleStyle(.switch)
            .font(.system(size: 11))
    }
}
