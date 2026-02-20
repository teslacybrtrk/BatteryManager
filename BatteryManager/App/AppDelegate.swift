import Cocoa
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?

    // Shared state
    let appState = AppState()

    // Services
    private(set) var smcService: SMCService?
    private(set) var batteryService: BatteryService?
    private(set) var chargingController: ChargingController?
    private(set) var thermalService: ThermalService?
    private(set) var clamshellService: ClamshellService?
    private(set) var calibrationService: CalibrationService?
    private(set) var scheduleService: ScheduleService?
    private(set) var powerAssertionService: PowerAssertionService?
    private(set) var magSafeLEDService: MagSafeLEDService?
    private(set) var updateChecker: UpdateChecker?
    private(set) var helperInstaller: HelperInstaller?

    // UI
    private var menuBarIconManager: MenuBarIconManager?
    private var iconUpdateTimer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        initializeServices()
        setupMenuBarItem()
        setupPopover()
        startMonitoring()

        // Register for appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updateMenuBarIcon),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )

        // Register for fast user switching
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidBecomeActive),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidResignActive),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if appState.settings.stopChargingOnQuit {
            chargingController?.restoreDefaults()
        }
        batteryService?.stopMonitoring()
        chargingController?.stopControlLoop()
        scheduleService?.stopEvaluating()
        powerAssertionService?.allowSleep()
    }

    // MARK: - Initialization

    private func initializeServices() {
        // Core services
        let smc = SMCService()
        smcService = smc
        appState.smcConnected = smc.isConnected

        batteryService = BatteryService(appState: appState)

        let controller = ChargingController(appState: appState, smcService: smc)
        chargingController = controller

        // Advanced services
        let thermal = ThermalService(smcService: smc)
        thermalService = thermal
        controller.thermalService = thermal

        clamshellService = ClamshellService()

        let calibration = CalibrationService(appState: appState, smcService: smc)
        calibrationService = calibration
        controller.calibrationService = calibration

        let powerAssertion = PowerAssertionService()
        powerAssertionService = powerAssertion
        controller.powerAssertionService = powerAssertion

        let magSafe = MagSafeLEDService(smcService: smc)
        magSafeLEDService = magSafe
        controller.magSafeLEDService = magSafe

        let schedule = ScheduleService(appState: appState, chargingController: controller)
        scheduleService = schedule

        // Update checker
        let checker = UpdateChecker()
        updateChecker = checker
        checker.startPeriodicChecks()

        // Helper installer
        let installer = HelperInstaller()
        helperInstaller = installer

        // Check if helper is needed — direct SMC read access works without root,
        // but writing (charging control) requires the privileged XPC helper
        if !smc.useXPC {
            appState.needsHelperInstall = true
            installer.checkIfInstalled()
        }

        // Apply saved settings
        appState.chargeLimit = appState.settings.chargeLimit
    }

    private func startMonitoring() {
        batteryService?.startMonitoring()
        chargingController?.startControlLoop()
        scheduleService?.startEvaluating()

        // Apply initial charge limit
        chargingController?.applyChargeLimit(appState.settings.chargeLimit)

        // Menu bar icon update timer (cancel old one first to prevent duplicates)
        iconUpdateTimer?.invalidate()
        iconUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateMenuBarIcon()
        }
    }

    // MARK: - Menu Bar

    func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        if let statusItem {
            menuBarIconManager = MenuBarIconManager(appState: appState, statusItem: statusItem)
            updateMenuBarIcon()
        }
    }

    @objc func updateMenuBarIcon() {
        menuBarIconManager?.updateIcon()
    }

    func setupPopover() {
        let mainView = MainPopoverView(
            appState: appState,
            updateChecker: updateChecker,
            helperInstaller: helperInstaller,
            onLimitChanged: { [weak self] limit in
                self?.chargingController?.applyChargeLimit(limit)
            },
            onModeChanged: { [weak self] mode in
                self?.handleModeChange(mode)
            },
            onScheduleAction: { [weak self] action in
                self?.handleScheduleAction(action)
            },
            onHelperInstalled: { [weak self] in
                self?.reconnectAfterHelperInstall()
            },
            onHeightChanged: { [weak self] (height: CGFloat) in
                guard let popover = self?.popover else { return }
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    popover.contentSize = NSSize(width: 320, height: height)
                }
            }
        )

        let initialHeight = MainPopoverView.heightForTab(.dashboard)
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: initialHeight)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: mainView)
    }

    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                // Activate the app so the popover can receive focus
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Mode Handling

    private func handleModeChange(_ mode: ChargingMode) {
        if appState.currentMode == mode {
            // Toggle off - return to normal
            chargingController?.setMode(.normal)
        } else {
            chargingController?.setMode(mode)
        }
    }

    private func handleScheduleAction(_ action: ScheduleAction) {
        switch action {
        case .add(let schedule):
            scheduleService?.addSchedule(schedule)
        case .remove(let id):
            scheduleService?.removeSchedule(id: id)
        case .toggle(let id, let enabled):
            scheduleService?.toggleSchedule(id: id, enabled: enabled)
        }
    }

    // MARK: - Helper Install

    private func reconnectAfterHelperInstall() {
        smcService?.reconnect()
        appState.smcConnected = smcService?.isConnected ?? false

        if appState.smcConnected {
            // Re-apply the charge limit now that we can actually write to SMC
            chargingController?.applyChargeLimit(appState.settings.chargeLimit)
            print("[AppDelegate] Helper installed, SMC reconnected, charge limit re-applied")
        } else {
            print("[AppDelegate] Helper installed but SMC still not connected")
        }
    }

    // MARK: - Session Notifications

    @objc private func sessionDidBecomeActive() {
        startMonitoring()
    }

    @objc private func sessionDidResignActive() {
        batteryService?.stopMonitoring()
        chargingController?.stopControlLoop()
        scheduleService?.stopEvaluating()
        iconUpdateTimer?.invalidate()
        iconUpdateTimer = nil
    }
}
