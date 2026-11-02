import AppKit
import Carbon.HIToolbox

// Gauge is a plain AppKit app. A SwiftUI `App` needs at least one scene, and the
// placeholder `Settings { EmptyView() }` it used to declare opened as a blank
// "Gauge Settings" window at launch and stole ⌘, from the real Settings window.
@main
@MainActor
enum GaugeMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
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
        NSApp.mainMenu = makeMainMenu()
        statusBarController = StatusBarController(
            overlayManager: overlayManager,
            showSettings: { [weak self] in self?.showSettings() }
        )
        // Always apply the launch preference, so a visibility left over from the
        // last session cannot resurface the rulers on the next screen change.
        if overlayManager.settings.showRulersOnLaunch {
            overlayManager.show()
        } else {
            overlayManager.hide()
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
            },
            HotKeyManager.Binding(id: 4, keyCode: kVK_ANSI_P) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggleColorSampler() }
            },
            HotKeyManager.Binding(id: 5, keyCode: kVK_ANSI_Z) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggleLoupe() }
            },
            HotKeyManager.Binding(id: 6, keyCode: kVK_ANSI_G) { [weak overlayManager] in
                DispatchQueue.main.async { overlayManager?.toggleGuidePlacement() }
            }
        ])
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager.unregister()
    }

    @objc func showSettings() { settingsWindowController?.show() }

    /// The menu bar shown while a Gauge window is key. It carries the standard
    /// key equivalents (⌘, ⌘W ⌘M ⌘Q and text editing) for the Settings and
    /// Remove Guides windows.
    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()

        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About Gauge", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        let settingsItem = appMenu.addItem(withTitle: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide Gauge", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit Gauge", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        addSubmenu(appMenu, titled: "Gauge", to: mainMenu)

        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        addSubmenu(editMenu, titled: "Edit", to: mainMenu)

        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        addSubmenu(windowMenu, titled: "Window", to: mainMenu)
        NSApp.windowsMenu = windowMenu

        return mainMenu
    }

    private func addSubmenu(_ submenu: NSMenu, titled title: String, to menu: NSMenu) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = submenu
        menu.addItem(item)
    }
}
