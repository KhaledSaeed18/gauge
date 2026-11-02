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
    private let loupeItem = NSMenuItem()
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
        loupeItem.target = self
        loupeItem.action = #selector(toggleLoupe)
        menu.addItem(loupeItem)
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

    @objc private func toggleLoupe() {
        overlayManager.toggleLoupe()
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

        loupeItem.title = overlayManager.interactionMode == .loupe ? "Loupe: On" : "Loupe"
        loupeItem.state = overlayManager.interactionMode == .loupe ? .on : .off
        loupeItem.keyEquivalent = "z"
        loupeItem.keyEquivalentModifierMask = [.control, .option, .command]

        let measurementCount = overlayManager.measurementStore.count
        clearMeasurementsItem.title = measurementCount > 0 ? "Clear Measurements (\(measurementCount))" : "Clear Measurements"
        clearMeasurementsItem.isEnabled = measurementCount > 0

        guideModeItem.title = overlayManager.isGuidePlacementEnabled ? "Guide Placement: On" : "Guide Placement: Off"
        guideModeItem.keyEquivalent = "g"
        guideModeItem.keyEquivalentModifierMask = [.control, .option, .command]
        guideNumbersItem.title = overlayManager.settings.showGuideNumbers ? "Guide Numbers: On" : "Guide Numbers: Off"

        let guideCount = overlayManager.guideStore.guides.count
        removeGuidesItem.title = guideCount > 0 ? "Remove Guides... (\(guideCount))" : "Remove Guides..."
        removeGuidesItem.isEnabled = guideCount > 0
    }
}

@MainActor
private final class GuideRemovalWindowController: NSWindowController {
    init(guideStore: GuideStore) {
        let rootView = GuideRemovalPanelView(guideStore: guideStore)
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        window.title = "Remove Guides"
        window.isReleasedWhenClosed = false
        // Panels hide when their app deactivates by default. Gauge is opened from
        // the menu bar while another app is active, so the panel vanished at once.
        window.hidesOnDeactivate = false
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func show() { window?.gaugePresent() }
}

private struct GuideRemovalPanelView: View {
    @ObservedObject var guideStore: GuideStore
    @ObservedObject private var settings = RulerSettings.shared
    @State private var selectedGuideIDs = Set<UUID>()

    private var numberedGuides: [NumberedGuide] { guideStore.numberedGuides() }
    private var allSelected: Bool { !numberedGuides.isEmpty && selectedGuideIDs.count == numberedGuides.count }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Remove Guides")
                    .font(.headline)
                Spacer()
                Text(countLabel)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            if numberedGuides.isEmpty {
                ContentUnavailableView(
                    "No guides",
                    systemImage: "scope",
                    description: Text("Click or drag a ruler to add guides.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Button(allSelected ? "Deselect All" : "Select All") { toggleSelectAll() }
                        .controlSize(.small)
                    Spacer()
                    Text("\(selectedGuideIDs.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(numberedGuides) { guide in
                            GuideRow(
                                guide: guide,
                                color: color(for: guide),
                                isSelected: selectedGuideIDs.contains(guide.id)
                            ) { toggle(guide.id) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }

            Divider()

            HStack {
                Button("Remove All", role: .destructive) {
                    guideStore.clear()
                    selectedGuideIDs.removeAll()
                }
                .disabled(numberedGuides.isEmpty)
                Spacer()
                Button("Remove Selected", role: .destructive) {
                    guideStore.remove(ids: selectedGuideIDs)
                    selectedGuideIDs.removeAll()
                }
                .disabled(selectedGuideIDs.isEmpty)
            }
            .padding(16)
        }
        .frame(width: 360, height: 440)
        .onReceive(guideStore.$guides) { guides in
            selectedGuideIDs.formIntersection(Set(guides.map(\.id)))
        }
    }

    private var countLabel: String {
        let count = numberedGuides.count
        return count == 1 ? "1 guide" : "\(count) guides"
    }

    private func color(for guide: NumberedGuide) -> Color {
        Color(nsColor: guide.guide.orientation == .vertical ? settings.verticalTint.color : settings.horizontalTint.color)
    }

    private func toggle(_ id: UUID) {
        if selectedGuideIDs.contains(id) {
            selectedGuideIDs.remove(id)
        } else {
            selectedGuideIDs.insert(id)
        }
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedGuideIDs.removeAll()
        } else {
            selectedGuideIDs = Set(numberedGuides.map(\.id))
        }
    }
}

private struct GuideRow: View {
    let guide: NumberedGuide
    let color: Color
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                Text(guide.name)
                    .font(.system(.caption, design: .monospaced).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(color))

                VStack(alignment: .leading, spacing: 1) {
                    Text(guide.displayName)
                        .lineLimit(1)
                    Text(guide.positionLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.14) : Color.primary.opacity(0.05))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    func show() { window?.gaugePresent() }
}

extension NSWindow {
    /// Brings a Gauge window forward from the menu bar: restores it from the Dock,
    /// opens it on the display under the pointer when it was closed elsewhere, and
    /// activates Gauge so the window takes keyboard focus.
    func gaugePresent() {
        if isMiniaturized { deminiaturize(nil) }
        if !isVisible,
           let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }),
           screen != self.screen {
            let visible = screen.visibleFrame
            setFrameOrigin(NSPoint(x: visible.midX - frame.width / 2, y: visible.midY - frame.height / 2))
        }
        NSApp.activate()
        makeKeyAndOrderFront(nil)
    }
}
