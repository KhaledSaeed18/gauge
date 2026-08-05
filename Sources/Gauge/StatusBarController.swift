import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let overlayManager: OverlayManager
    private let showSettings: () -> Void
    private let statusItem: NSStatusItem
    private let toggleItem = NSMenuItem()
    private let guideModeItem = NSMenuItem()

    init(overlayManager: OverlayManager, showSettings: @escaping () -> Void) {
        self.overlayManager = overlayManager
        self.showSettings = showSettings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        let menu = NSMenu()
        menu.delegate = self
        toggleItem.target = self
        toggleItem.action = #selector(toggleRulers)
        menu.addItem(toggleItem)
        guideModeItem.target = self
        guideModeItem.action = #selector(toggleGuidePlacement)
        menu.addItem(guideModeItem)
        let clearGuidesItem = NSMenuItem(title: "Clear All Guides", action: #selector(clearGuides), keyEquivalent: "")
        clearGuidesItem.target = self
        menu.addItem(clearGuidesItem)
        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(title: "Quit Gauge", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "ruler", accessibilityDescription: "Gauge")
            button.image?.isTemplate = true
            button.toolTip = "Gauge — pixel rulers"
        }
        updateMenuTitles()
    }

    func menuWillOpen(_ menu: NSMenu) { updateMenuTitles() }

    @objc private func toggleRulers() {
        overlayManager.toggle()
        updateMenuTitles()
    }

    @objc private func toggleGuidePlacement() {
        overlayManager.toggleGuidePlacement()
        updateMenuTitles()
    }

    @objc private func clearGuides() { overlayManager.clearGuides() }

    @objc private func openSettings() { showSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

    private func updateMenuTitles() {
        toggleItem.title = overlayManager.isVisible ? "Hide Rulers" : "Show Rulers"
        toggleItem.keyEquivalent = "r"
        toggleItem.keyEquivalentModifierMask = [.control, .option, .command]
        guideModeItem.title = overlayManager.isGuidePlacementEnabled ? "Guide Placement: On" : "Guide Placement: Off"
        guideModeItem.keyEquivalent = "g"
        guideModeItem.keyEquivalentModifierMask = [.control, .option, .command]
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    init(overlayManager: OverlayManager) {
        let rootView = SettingsView().environmentObject(overlayManager)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 470, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Gauge Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
