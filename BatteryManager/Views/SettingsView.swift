import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
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

                // About
                VStack(spacing: 4) {
                    SectionHeader(title: "About")
                    Text("BatteryManager v1.0")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)

                    Button("Quit BatteryManager") {
                        NSApplication.shared.terminate(nil)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
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
