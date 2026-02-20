import SwiftUI

@main
struct BatteryManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appState: appDelegate.appState)
        }
    }
}
