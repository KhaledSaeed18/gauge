import AppKit
import SwiftUI

@MainActor
final class OverlayManager: NSObject, ObservableObject {
    @Published private(set) var isVisible = false
    @Published private(set) var isGuidePlacementEnabled = false
    let settings = RulerSettings.shared
    let guideStore = GuideStore()
    private var panels: [RulerPanel] = []
    private var guideInputPanels: [GuideInputPanel] = []
    private var screenObserver: NSObjectProtocol?

    override init() {
        super.init()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.rebuild() }
        }
    }

    func show() {
        settings.isVisible = true
        rebuild()
        isVisible = true
    }

    func hide() {
        settings.isVisible = false
        panels.forEach { $0.orderOut(nil) }
        guideInputPanels.forEach { $0.orderOut(nil) }
        isVisible = false
    }

    func toggle() { isVisible ? hide() : show() }

    func rebuild() {
        panels.forEach { $0.orderOut(nil) }
        guideInputPanels.forEach { $0.orderOut(nil) }
        panels = NSScreen.screens.map { RulerPanel(screen: $0, settings: settings, guideStore: guideStore) }
        guard settings.isVisible else { return }
        panels.forEach { $0.orderFrontRegardless() }
        refreshGuideInputs()
        isVisible = true
    }

    func toggleGuidePlacement() {
        isGuidePlacementEnabled.toggle()
        refreshGuideInputs()
    }

    func clearGuides() { guideStore.clear() }

    private func refreshGuideInputs() {
        guideInputPanels.forEach { $0.orderOut(nil) }
        guideInputPanels = []
        guard settings.isVisible, isGuidePlacementEnabled else { return }
        guideInputPanels = NSScreen.screens.flatMap { screen in
            GuideInputPanel.makePanels(screen: screen, thickness: settings.thickness, guideStore: guideStore)
        }
        guideInputPanels.forEach { $0.orderFrontRegardless() }
    }
}

private final class RulerPanel: NSPanel {
    init(screen: NSScreen, settings: RulerSettings, guideStore: GuideStore) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setFrame(screen.frame, display: false)
        // Stay above applications while leaving the macOS menu bar usable.
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        animationBehavior = .none
        contentView = RulerOverlayView(frame: NSRect(origin: .zero, size: screen.frame.size), screen: screen, settings: settings, guideStore: guideStore)
    }
}

private final class GuideInputPanel: NSPanel {
    static func makePanels(screen: NSScreen, thickness: CGFloat, guideStore: GuideStore) -> [GuideInputPanel] {
        let inset = screen.gaugeMenuBarInset
        let topFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - inset - thickness,
            width: screen.frame.width,
            height: thickness
        )
        let leftFrame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: thickness,
            height: screen.frame.height - inset
        )
        return [
            GuideInputPanel(frame: topFrame, orientation: .vertical, screen: screen, guideStore: guideStore),
            GuideInputPanel(frame: leftFrame, orientation: .horizontal, screen: screen, guideStore: guideStore)
        ]
    }

    private init(frame: NSRect, orientation: GuideOrientation, screen: NSScreen, guideStore: GuideStore) {
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        setFrame(frame, display: false)
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        contentView = GuideInputView(frame: NSRect(origin: .zero, size: frame.size), orientation: orientation, screen: screen, guideStore: guideStore)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

@MainActor
private final class GuideInputView: NSView {
    private let orientation: GuideOrientation
    private weak var targetScreen: NSScreen?
    private let guideStore: GuideStore
    private var activeGuideID: UUID?

    init(frame frameRect: NSRect, orientation: GuideOrientation, screen: NSScreen, guideStore: GuideStore) {
        self.orientation = orientation
        targetScreen = screen
        self.guideStore = guideStore
        super.init(frame: frameRect)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func mouseDown(with event: NSEvent) {
        guard let targetScreen else { return }
        activeGuideID = guideStore.add(
            orientation: orientation,
            positionPixels: pixelPosition(for: convert(event.locationInWindow, from: nil), scale: targetScreen.backingScaleFactor),
            displayID: targetScreen.gaugeDisplayID
        )
    }

    override func mouseDragged(with event: NSEvent) { moveActiveGuide(with: event) }
    override func mouseUp(with event: NSEvent) { moveActiveGuide(with: event); activeGuideID = nil }

    private func moveActiveGuide(with event: NSEvent) {
        guard let activeGuideID, let targetScreen else { return }
        guideStore.move(
            id: activeGuideID,
            to: pixelPosition(for: convert(event.locationInWindow, from: nil), scale: targetScreen.backingScaleFactor)
        )
    }

    private func pixelPosition(for point: NSPoint, scale: CGFloat) -> Int {
        let coordinate = orientation == .vertical ? point.x : point.y
        return Int((coordinate * scale).rounded())
    }
}
