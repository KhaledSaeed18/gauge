import AppKit
import Carbon.HIToolbox
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
        hotKeyManager.register([
            HotKeyManager.Binding(id: 1, keyCode: kVK_ANSI_R) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggle() }
            },
            HotKeyManager.Binding(id: 2, keyCode: kVK_ANSI_C) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggleCrosshair() }
            },
            HotKeyManager.Binding(id: 3, keyCode: kVK_ANSI_M) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggleMeasure() }
            }
        ])
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
    }
}
