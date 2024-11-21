import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBarItem()
        setupPopover()
        
        // Register for appearance changes
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(updateMenuBarIcon),
            name: NSNotification.Name("AppleInterfaceThemeChangedNotification"),
            object: nil
        )
    }
    
    func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            updateMenuBarIcon()
            button.action = #selector(togglePopover(_:))
            button.target = self
        } else {
            print("Failed to create status item button")
        }
    }
    
    @objc func updateMenuBarIcon() {
        if let button = statusItem?.button {
            if let image = NSImage(named: "MenuBarIcon") {
                image.isTemplate = true  // This is crucial for automatic color adaptation
                button.image = image
                print("Custom icon set successfully")
            } else {
                print("Failed to load custom icon, using fallback")
                button.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Star")
            }
        }
    }
    
    func setupPopover() {
        let contentView = ContentView()
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 200, height: 100)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(sender)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
}
