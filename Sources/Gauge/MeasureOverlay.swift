import AppKit

/// The active pointer-driven inspection tool layered above the rulers.
enum InteractionMode {
    case none
    case crosshair
    case measure
}

// MARK: - Clipboard

enum MeasurementClipboard {
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

// MARK: - Shared rendering

@MainActor
private enum OverlayDraw {
    /// Draws a filled, rounded label with centered text, clamped inside `bounds`.
    static func pill(
        _ text: String,
        centeredAt point: CGPoint,
        fill: NSColor,
        textColor: NSColor = .white,
        weight: NSFont.Weight = .semibold,
        bounds: CGRect
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11, weight: weight),
            .foregroundColor: textColor
        ]
        let label = NSAttributedString(string: text, attributes: attributes)
        let size = label.size()
        let width = size.width + 12
        let height = size.height + 6
        let x = min(max(point.x - width / 2, 4), max(4, bounds.width - width - 4))
        let y = min(max(point.y - height / 2, 4), max(4, bounds.height - height - 4))
        let rect = CGRect(x: x, y: y, width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        NSColor.black.withAlphaComponent(0.28).setStroke()
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        fill.withAlphaComponent(0.95).setFill()
        path.fill()
        path.lineWidth = 1
        path.stroke()
        label.draw(at: CGPoint(x: rect.minX + 6, y: rect.minY + 3))
        NSGraphicsContext.restoreGraphicsState()
    }

    /// Renders a measurement rectangle with dimension arrows and a `W × H` badge.
    static func measurement(
        rect: CGRect,
        widthLabel: String,
        heightLabel: String,
        dimensionLabel: String,
        positionLabel: String?,
        aspectLabel: String?,
        accent: NSColor,
        showLabels: Bool,
        isLive: Bool,
        scale: CGFloat,
        bounds: CGRect,
        context: CGContext
    ) {
        let fillAlpha: CGFloat = isLive ? 0.14 : 0.09
        context.setFillColor(accent.withAlphaComponent(fillAlpha).cgColor)
        context.fill(rect)

        context.setLineWidth(1 / scale)
        context.setStrokeColor(accent.withAlphaComponent(isLive ? 0.95 : 0.8).cgColor)
        if isLive {
            context.setLineDash(phase: 0, lengths: [])
        } else {
            context.setLineDash(phase: 0, lengths: [4, 3])
        }
        context.stroke(rect.insetBy(dx: 0.5 / scale, dy: 0.5 / scale))
        context.setLineDash(phase: 0, lengths: [])

        // Corner accents to make the exact pixel bounds obvious.
        let tick: CGFloat = 6
        context.setLineWidth(1.5 / scale)
        context.setStrokeColor(accent.withAlphaComponent(0.95).cgColor)
        for corner in [rect.origin,
                       CGPoint(x: rect.maxX, y: rect.minY),
                       CGPoint(x: rect.minX, y: rect.maxY),
                       CGPoint(x: rect.maxX, y: rect.maxY)] {
            let dx: CGFloat = corner.x == rect.minX ? tick : -tick
            let dy: CGFloat = corner.y == rect.minY ? tick : -tick
            context.move(to: CGPoint(x: corner.x, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x + dx, y: corner.y))
            context.move(to: CGPoint(x: corner.x, y: corner.y))
            context.addLine(to: CGPoint(x: corner.x, y: corner.y + dy))
        }
        context.strokePath()

        // Dimension badges: width along the top edge, height along the left edge.
        if showLabels {
            if rect.width > 1 {
                pill(widthLabel, centeredAt: CGPoint(x: rect.midX, y: rect.minY - 12), fill: accent, bounds: bounds)
            }
            if rect.height > 1 {
                pill(heightLabel, centeredAt: CGPoint(x: rect.minX - 20, y: rect.midY), fill: accent, bounds: bounds)
            }
            if isLive {
                pill(dimensionLabel, centeredAt: CGPoint(x: rect.maxX + 34, y: rect.maxY + 16), fill: .black, textColor: .white, weight: .bold, bounds: bounds)
            }
        }
        if let positionLabel {
            pill(positionLabel, centeredAt: CGPoint(x: rect.minX + 28, y: rect.minY + 12), fill: .black, textColor: .white, bounds: bounds)
        }
        if let aspectLabel {
            pill(aspectLabel, centeredAt: CGPoint(x: rect.midX, y: rect.midY), fill: accent, bounds: bounds)
        }
    }

    /// Renders a two-point line with end caps and a length/angle badge.
    static func line(
        from start: CGPoint,
        to end: CGPoint,
        label: String,
        accent: NSColor,
        isLive: Bool,
        scale: CGFloat,
        bounds: CGRect,
        context: CGContext
    ) {
        context.setLineWidth((isLive ? 1.5 : 1) / scale)
        context.setStrokeColor(accent.withAlphaComponent(isLive ? 0.95 : 0.8).cgColor)
        if !isLive { context.setLineDash(phase: 0, lengths: [4, 3]) }
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        let radius: CGFloat = 3
        context.setFillColor(accent.cgColor)
        for point in [start, end] {
            context.fillEllipse(in: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        }

        let mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
        pill(label, centeredAt: CGPoint(x: mid.x, y: mid.y - 12), fill: accent, weight: .bold, bounds: bounds)
    }
}

// MARK: - Held-measurement HUD (click-through)

/// A click-through panel that keeps committed measurements visible on screen
/// regardless of which interaction mode is active.
final class MeasurementHUDPanel: NSPanel {
    init(screen: NSScreen, settings: RulerSettings, store: MeasurementStore) {
        let inset = screen.gaugeMenuBarInset
        let frame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: screen.frame.height - inset
        )
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        setFrame(frame, display: false)
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        isMovable = false
        animationBehavior = .none
        contentView = MeasurementHUDView(
            frame: NSRect(origin: .zero, size: frame.size),
            screen: screen,
            settings: settings,
            store: store
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

@MainActor
private final class MeasurementHUDView: NSView {
    private weak var targetScreen: NSScreen?
    private let settings: RulerSettings
    private let store: MeasurementStore
    private var storeObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?

    init(frame frameRect: NSRect, screen: NSScreen, settings: RulerSettings, store: MeasurementStore) {
        targetScreen = screen
        self.settings = settings
        self.store = store
        super.init(frame: frameRect)
        wantsLayer = true
        storeObserver = NotificationCenter.default.addObserver(
            forName: MeasurementStore.didChangeNotification, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
        settingsObserver = NotificationCenter.default.addObserver(
            forName: RulerSettings.didChangeNotification, object: settings, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let screen = targetScreen, let context = NSGraphicsContext.current?.cgContext else { return }
        let scale = screen.backingScaleFactor
        for measurement in store.measurements(for: screen.gaugeDisplayID) {
            let rect = CGRect(
                x: measurement.originPixels.x / scale,
                y: measurement.originPixels.y / scale,
                width: measurement.sizePixels.width / scale,
                height: measurement.sizePixels.height / scale
            )
            OverlayDraw.measurement(
                rect: rect,
                widthLabel: "\(measurement.widthPixels)",
                heightLabel: "\(measurement.heightPixels)",
                dimensionLabel: measurement.dimensionLabel,
                positionLabel: settings.showMeasurementPosition ? "\(measurement.xPixels), \(measurement.yPixels)" : nil,
                aspectLabel: settings.showMeasurementAspectRatio ? measurement.aspectRatioLabel : nil,
                accent: settings.measurementTint.color,
                showLabels: settings.showMeasurementLabels,
                isLive: false,
                scale: scale,
                bounds: bounds,
                context: context
            )
        }
    }
}

// MARK: - Interactive crosshair / measure panel

final class InteractivePanel: NSPanel {
    init(screen: NSScreen, mode: InteractionMode, settings: RulerSettings, store: MeasurementStore) {
        let inset = screen.gaugeMenuBarInset
        let frame = NSRect(
            x: screen.frame.minX,
            y: screen.frame.minY,
            width: screen.frame.width,
            height: screen.frame.height - inset
        )
        super.init(contentRect: frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        setFrame(frame, display: false)
        level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        isMovable = false
        animationBehavior = .none
        acceptsMouseMovedEvents = true
        contentView = InteractiveView(
            frame: NSRect(origin: .zero, size: frame.size),
            mode: mode,
            screen: screen,
            settings: settings,
            store: store
        )
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

@MainActor
private final class InteractiveView: NSView {
    private let mode: InteractionMode
    private weak var targetScreen: NSScreen?
    private let settings: RulerSettings
    private let store: MeasurementStore
    private var trackingArea: NSTrackingArea?

    private var pointer: NSPoint?
    private var dragOrigin: NSPoint?
    private var dragCurrent: NSPoint?
    private var copyFlash: (point: NSPoint, text: String)?
    private var settingsObserver: NSObjectProtocol?

    init(frame frameRect: NSRect, mode: InteractionMode, screen: NSScreen, settings: RulerSettings, store: MeasurementStore) {
        self.mode = mode
        targetScreen = screen
        self.settings = settings
        self.store = store
        super.init(frame: frameRect)
        wantsLayer = true
        settingsObserver = NotificationCenter.default.addObserver(
            forName: RulerSettings.didChangeNotification, object: settings, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isFlipped: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .crosshair)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea { removeTrackingArea(trackingArea) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    // MARK: Pointer tracking

    override func mouseEntered(with event: NSEvent) { updatePointer(with: event) }
    override func mouseMoved(with event: NSEvent) { updatePointer(with: event) }

    override func mouseExited(with event: NSEvent) {
        pointer = nil
        needsDisplay = true
    }

    private func updatePointer(with event: NSEvent) {
        pointer = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    // MARK: Measure gesture

    override func mouseDown(with event: NSEvent) {
        guard mode == .measure else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragOrigin = point
        dragCurrent = point
        pointer = point
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard mode == .measure, dragOrigin != nil else { return }
        let point = convert(event.locationInWindow, from: nil)
        dragCurrent = point
        pointer = point
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard mode == .measure, let origin = dragOrigin, let current = dragCurrent, let screen = targetScreen else {
            dragOrigin = nil
            dragCurrent = nil
            return
        }
        let scale = screen.backingScaleFactor
        let rect = normalizedRect(origin, current)
        dragOrigin = nil
        dragCurrent = nil

        // A near-zero box is a click, not a drag: remove a held measurement under the pointer.
        guard rect.width * scale >= 2, rect.height * scale >= 2 else {
            let clickPixels = CGPoint(x: current.x * scale, y: current.y * scale)
            if let hit = store.measurements(for: screen.gaugeDisplayID)
                .last(where: { CGRect(origin: $0.originPixels, size: $0.sizePixels).contains(clickPixels) }) {
                store.remove(id: hit.id)
            }
            needsDisplay = true
            return
        }

        let measurement = store.add(
            displayID: screen.gaugeDisplayID,
            originPixels: CGPoint(x: (rect.minX * scale).rounded(), y: (rect.minY * scale).rounded()),
            sizePixels: CGSize(width: (rect.width * scale).rounded(), height: (rect.height * scale).rounded())
        )
        if settings.copyOnMeasure {
            MeasurementClipboard.copy(measurement.copyString(format: settings.measurementCopyFormat))
            flashCopy(measurement.dimensionLabel, at: CGPoint(x: rect.maxX, y: rect.maxY))
        }
        needsDisplay = true
    }

    private func flashCopy(_ text: String, at point: NSPoint) {
        copyFlash = (point, "Copied \(text)")
        needsDisplay = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak self] in
            self?.copyFlash = nil
            self?.needsDisplay = true
        }
    }

    private func normalizedRect(_ a: NSPoint, _ b: NSPoint) -> CGRect {
        CGRect(
            x: min(a.x, b.x),
            y: min(a.y, b.y),
            width: abs(a.x - b.x),
            height: abs(a.y - b.y)
        )
    }

    // MARK: Drawing

    override func draw(_ dirtyRect: NSRect) {
        guard let screen = targetScreen, let context = NSGraphicsContext.current?.cgContext else { return }
        let scale = screen.backingScaleFactor
        switch mode {
        case .crosshair:
            drawCrosshair(context: context, scale: scale)
        case .measure:
            drawMeasure(context: context, scale: scale)
        case .none:
            break
        }
        if let copyFlash {
            OverlayDraw.pill(copyFlash.text, centeredAt: CGPoint(x: copyFlash.point.x, y: copyFlash.point.y + 34), fill: .systemGreen, weight: .bold, bounds: bounds)
        }
    }

    private func drawCrosshair(context: CGContext, scale: CGFloat) {
        guard let pointer else { return }
        let accent = settings.crosshairTint.color
        context.setLineWidth(1 / scale)
        context.setStrokeColor(accent.withAlphaComponent(0.9).cgColor)

        context.move(to: CGPoint(x: pointer.x + 0.5 / scale, y: 0))
        context.addLine(to: CGPoint(x: pointer.x + 0.5 / scale, y: bounds.height))
        context.strokePath()

        context.move(to: CGPoint(x: 0, y: pointer.y + 0.5 / scale))
        context.addLine(to: CGPoint(x: bounds.width, y: pointer.y + 0.5 / scale))
        context.strokePath()

        if settings.showCrosshairReadout {
            let px = Int((pointer.x * scale).rounded())
            let py = Int((pointer.y * scale).rounded())
            OverlayDraw.pill(
                "\(px), \(py)",
                centeredAt: CGPoint(x: pointer.x + 46, y: pointer.y + 18),
                fill: .black,
                weight: .bold,
                bounds: bounds
            )
        }
    }

    private func drawMeasure(context: CGContext, scale: CGFloat) {
        if let origin = dragOrigin, let current = dragCurrent {
            let rect = normalizedRect(origin, current)
            let widthPx = Int((rect.width * scale).rounded())
            let heightPx = Int((rect.height * scale).rounded())
            let xPx = Int((rect.minX * scale).rounded())
            let yPx = Int((rect.minY * scale).rounded())
            OverlayDraw.measurement(
                rect: rect,
                widthLabel: "\(widthPx)",
                heightLabel: "\(heightPx)",
                dimensionLabel: "\(widthPx) × \(heightPx)",
                positionLabel: settings.showMeasurementPosition ? "\(xPx), \(yPx)" : nil,
                aspectLabel: settings.showMeasurementAspectRatio ? reducedRatio(width: widthPx, height: heightPx) : nil,
                accent: settings.measurementTint.color,
                showLabels: true,
                isLive: true,
                scale: scale,
                bounds: bounds,
                context: context
            )
        } else if let pointer {
            // Faint crosshair marks the start point before a drag begins.
            context.setLineWidth(1 / scale)
            context.setStrokeColor(settings.measurementTint.color.withAlphaComponent(0.45).cgColor)
            context.move(to: CGPoint(x: pointer.x + 0.5 / scale, y: 0))
            context.addLine(to: CGPoint(x: pointer.x + 0.5 / scale, y: bounds.height))
            context.strokePath()
            context.move(to: CGPoint(x: 0, y: pointer.y + 0.5 / scale))
            context.addLine(to: CGPoint(x: bounds.width, y: pointer.y + 0.5 / scale))
            context.strokePath()
        }
    }
}
