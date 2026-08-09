import AppKit
import SwiftUI

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let overlayManager: OverlayManager
    private let showSettings: () -> Void
    private let statusItem: NSStatusItem
    private let toggleItem = NSMenuItem()
    private let crosshairItem = NSMenuItem()
    private let measureItem = NSMenuItem()
    private let colorSamplerItem = NSMenuItem()
    private let clearMeasurementsItem = NSMenuItem(title: "Clear Measurements", action: #selector(clearMeasurements), keyEquivalent: "")
    private let guideModeItem = NSMenuItem()
    private let guideNumbersItem = NSMenuItem()
    private let removeGuidesItem = NSMenuItem(title: "Remove Guides...", action: #selector(openGuideRemoval), keyEquivalent: "")
    private var guideRemovalWindowController: GuideRemovalWindowController?

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
        menu.addItem(NSMenuItem.separator())

        crosshairItem.target = self
        crosshairItem.action = #selector(toggleCrosshair)
        menu.addItem(crosshairItem)
        measureItem.target = self
        measureItem.action = #selector(toggleMeasure)
        menu.addItem(measureItem)
        colorSamplerItem.target = self
        colorSamplerItem.action = #selector(toggleColorSampler)
        menu.addItem(colorSamplerItem)
        clearMeasurementsItem.target = self
        menu.addItem(clearMeasurementsItem)
        menu.addItem(NSMenuItem.separator())

        guideModeItem.target = self
        guideModeItem.action = #selector(toggleGuidePlacement)
        menu.addItem(guideModeItem)
        guideNumbersItem.target = self
        guideNumbersItem.action = #selector(toggleGuideNumbers)
        menu.addItem(guideNumbersItem)
        removeGuidesItem.target = self
        menu.addItem(removeGuidesItem)
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

    @objc private func toggleCrosshair() {
        overlayManager.toggleCrosshair()
        updateMenuTitles()
    }

    @objc private func toggleMeasure() {
        overlayManager.toggleMeasure()
        updateMenuTitles()
    }

    @objc private func toggleColorSampler() {
        overlayManager.toggleColorSampler()
        updateMenuTitles()
    }

    @objc private func clearMeasurements() { overlayManager.clearMeasurements() }

    @objc private func toggleGuidePlacement() {
        overlayManager.toggleGuidePlacement()
        updateMenuTitles()
    }

    @objc private func toggleGuideNumbers() {
        overlayManager.settings.showGuideNumbers.toggle()
        updateMenuTitles()
    }

    @objc private func clearGuides() { overlayManager.clearGuides() }

    @objc private func openGuideRemoval() {
        if guideRemovalWindowController == nil {
            guideRemovalWindowController = GuideRemovalWindowController(guideStore: overlayManager.guideStore)
        }
        guideRemovalWindowController?.show()
    }

    @objc private func openSettings() { showSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

    private func updateMenuTitles() {
        toggleItem.title = overlayManager.isVisible ? "Hide Rulers" : "Show Rulers"
        toggleItem.keyEquivalent = "r"
        toggleItem.keyEquivalentModifierMask = [.control, .option, .command]

        crosshairItem.title = overlayManager.interactionMode == .crosshair ? "Crosshair: On" : "Crosshair"
        crosshairItem.state = overlayManager.interactionMode == .crosshair ? .on : .off
        crosshairItem.keyEquivalent = "c"
        crosshairItem.keyEquivalentModifierMask = [.control, .option, .command]

        measureItem.title = overlayManager.interactionMode == .measure ? "Measure Distance: On" : "Measure Distance"
        measureItem.state = overlayManager.interactionMode == .measure ? .on : .off
        measureItem.keyEquivalent = "m"
        measureItem.keyEquivalentModifierMask = [.control, .option, .command]

        colorSamplerItem.title = overlayManager.interactionMode == .colorSampler ? "Color Sampler: On" : "Color Sampler"
        colorSamplerItem.state = overlayManager.interactionMode == .colorSampler ? .on : .off
        colorSamplerItem.keyEquivalent = "p"
        colorSamplerItem.keyEquivalentModifierMask = [.control, .option, .command]

        let measurementCount = overlayManager.measurementStore.count
        clearMeasurementsItem.title = measurementCount > 0 ? "Clear Measurements (\(measurementCount))" : "Clear Measurements"
        clearMeasurementsItem.isEnabled = measurementCount > 0

        guideModeItem.title = overlayManager.isGuidePlacementEnabled ? "Guide Placement: On" : "Guide Placement: Off"
        guideModeItem.keyEquivalent = "g"
        guideModeItem.keyEquivalentModifierMask = [.control, .option, .command]
        guideNumbersItem.title = overlayManager.settings.showGuideNumbers ? "Guide Numbers: On" : "Guide Numbers: Off"
        removeGuidesItem.isEnabled = !overlayManager.guideStore.guides.isEmpty
    }
}

@MainActor
private final class GuideRemovalWindowController: NSWindowController {
    init(guideStore: GuideStore) {
        let rootView = GuideRemovalPanelView(guideStore: guideStore)
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 360),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Remove Guides"
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

private struct GuideRemovalPanelView: View {
    @ObservedObject var guideStore: GuideStore
    @State private var selectedGuideIDs = Set<UUID>()

    private var numberedGuides: [NumberedGuide] { guideStore.numberedGuides() }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remove guides")
                .font(.headline)

            if numberedGuides.isEmpty {
                ContentUnavailableView("No guides", systemImage: "scope")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(numberedGuides) { guide in
                            Toggle(isOn: selectionBinding(for: guide.id)) {
                                HStack(spacing: 8) {
                                    Text(guide.name)
                                        .font(.system(.body, design: .monospaced).weight(.semibold))
                                        .frame(width: 34, alignment: .leading)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(guide.displayName)
                                            .lineLimit(1)
                                        Text(guide.positionLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .monospacedDigit()
                                    }
                                }
                            }
                            .toggleStyle(.checkbox)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            HStack {
                Button("Clear") { selectedGuideIDs.removeAll() }
                    .disabled(selectedGuideIDs.isEmpty)
                Spacer()
                Button("Remove Selected", role: .destructive) {
                    guideStore.remove(ids: selectedGuideIDs)
                    selectedGuideIDs.removeAll()
                }
                .disabled(selectedGuideIDs.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 340, height: 330)
        .onReceive(guideStore.$guides) { guides in
            selectedGuideIDs.formIntersection(Set(guides.map(\.id)))
        }
    }

    private func selectionBinding(for id: UUID) -> Binding<Bool> {
        Binding {
            selectedGuideIDs.contains(id)
        } set: { isSelected in
            if isSelected {
                selectedGuideIDs.insert(id)
            } else {
                selectedGuideIDs.remove(id)
            }
        }
    }
}

@MainActor
final class SettingsWindowController: NSWindowController {
    init(overlayManager: OverlayManager) {
        let rootView = SettingsView().environmentObject(overlayManager)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 540),
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
