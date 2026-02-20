import AppIntents

struct BatteryShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: SetChargeLimitIntent(),
            phrases: [
                "Set charge limit in \(.applicationName)",
                "Change battery limit with \(.applicationName)"
            ],
            shortTitle: "Set Charge Limit",
            systemImageName: "battery.75percent"
        )
        AppShortcut(
            intent: GetBatteryInfoIntent(),
            phrases: [
                "Get battery info from \(.applicationName)",
                "Check battery status with \(.applicationName)"
            ],
            shortTitle: "Get Battery Info",
            systemImageName: "battery.100percent"
        )
        AppShortcut(
            intent: ToggleChargingIntent(),
            phrases: [
                "Toggle charging in \(.applicationName)",
                "Switch charging with \(.applicationName)"
            ],
            shortTitle: "Toggle Charging",
            systemImageName: "bolt.fill"
        )
        AppShortcut(
            intent: StartSailingModeIntent(),
            phrases: [
                "Start sailing mode in \(.applicationName)",
                "Activate sailing mode with \(.applicationName)"
            ],
            shortTitle: "Start Sailing Mode",
            systemImageName: "wind"
        )
    }
}
