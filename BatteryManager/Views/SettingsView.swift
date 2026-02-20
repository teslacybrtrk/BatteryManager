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

                    SettingsToggleWithInfo(
                        title: "Launch at Login",
                        info: "Automatically start BatteryManager when you log in to your Mac.",
                        isOn: Binding(
                            get: { appState.settings.launchAtLogin },
                            set: { newValue in
                                appState.settings.launchAtLogin = newValue
                                appState.settings.save()
                                setLaunchAtLogin(newValue)
                            }
                        )
                    )

                    SettingsToggleWithInfo(
                        title: "Re-enable Charging on Quit",
                        info: "When you quit BatteryManager, charging will be restored to normal so your battery charges fully.",
                        isOn: Binding(
                            get: { appState.settings.stopChargingOnQuit },
                            set: { newValue in
                                appState.settings.stopChargingOnQuit = newValue
                                appState.settings.save()
                            }
                        )
                    )

                    SettingsToggleWithInfo(
                        title: "Show Battery % in Menu Bar",
                        info: "Display the current battery percentage next to the menu bar icon.",
                        isOn: Binding(
                            get: { appState.settings.showBatteryPercentInMenuBar },
                            set: { newValue in
                                appState.settings.showBatteryPercentInMenuBar = newValue
                                appState.settings.save()
                            }
                        )
                    )

                    SettingsToggleWithInfo(
                        title: "Prevent Sleep While Charging",
                        info: "Keep your Mac awake while it\u{2019}s charging to ensure charge limits and schedules work correctly.",
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
                    HStack {
                        SectionHeader(title: "Heat Protection")
                        InfoButton(text: "Automatically pauses charging when the battery temperature exceeds the threshold to prevent heat damage.")
                    }

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
                    HStack {
                        SectionHeader(title: "Sailing Mode Defaults")
                        InfoButton(text: "Sailing mode maintains your battery between a low and high bound by toggling charging on and off automatically.")
                    }

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

                // About & Updates (merged)
                VStack(spacing: 8) {
                    SectionHeader(title: "About")

                    if let checker = updateChecker {
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

                        if let lastCheck = checker.lastCheckDate {
                            HStack {
                                Text("Last checked")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                Spacer()
                                Text(Self.formatCheckDate(lastCheck))
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        if checker.updateAvailable {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 11))
                                Text("Update available — switch to Dashboard to install")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.orange)
                                Spacer()
                            }
                        }

                        if let error = checker.checkError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 10))
                                Text(error)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }

                    Divider()

                    HStack {
                        Text("BatteryManager")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("Build \(String(BuildInfo.commitSHA.prefix(7)))")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

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
                    .padding(.top, 2)
                }
            }
            .padding()
        }
    }

    private static func formatCheckDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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

struct SettingsToggleWithInfo: View {
    let title: String
    let info: String
    @Binding var isOn: Bool

    @State private var showingInfo = false

    var body: some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 11))

            Button {
                showingInfo.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)
            .popover(isPresented: $showingInfo, arrowEdge: .trailing) {
                Text(info)
                    .font(.system(size: 11))
                    .padding(8)
                    .frame(width: 200)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

struct InfoButton: View {
    let text: String
    @State private var showingInfo = false

    var body: some View {
        Button {
            showingInfo.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingInfo, arrowEdge: .trailing) {
            Text(text)
                .font(.system(size: 11))
                .padding(8)
                .frame(width: 200)
        }
    }
}
