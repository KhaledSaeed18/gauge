import AppKit
import SwiftUI

@main
struct GaugeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let overlayManager = OverlayManager()
    private let hotKeyManager = HotKeyManager()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        settingsWindowController = SettingsWindowController(overlayManager: overlayManager)
        statusBarController = StatusBarController(
            overlayManager: overlayManager,
            showSettings: { [weak self] in self?.settingsWindowController?.show() }
        )
        if overlayManager.settings.showRulersOnLaunch {
            overlayManager.show()
        }
        hotKeyManager.registerToggle { [weak overlayManager] in
            DispatchQueue.main.async { overlayManager?.toggle() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
    }
}
