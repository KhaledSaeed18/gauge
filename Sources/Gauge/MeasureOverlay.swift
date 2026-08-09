import AppKit
import GaugeCore

/// The active pointer-driven inspection tool layered above the rulers.
enum InteractionMode {
    case none
    case crosshair
    case measure
    case colorSampler
    case loupe
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
        let frame = screen.gaugeGeometry.overlayFrame(in: screen.frame)
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
        let scale = screen.gaugeGeometry.scale
        for measurement in store.measurements(for: screen.gaugeDisplayID) {
            switch measurement.kind {
            case .line:
                OverlayDraw.line(
                    from: CGPoint(x: measurement.originPixels.x / scale, y: measurement.originPixels.y / scale),
                    to: CGPoint(x: measurement.endPixels.x / scale, y: measurement.endPixels.y / scale),
                    label: measurement.lineLabel,
                    accent: settings.measurementTint.color,
                    isLive: false,
                    scale: scale,
                    bounds: bounds,
                    context: context
                )
            case .box:
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
}

// MARK: - Interactive crosshair / measure panel

final class InteractivePanel: NSPanel {
    init(screen: NSScreen, mode: InteractionMode, settings: RulerSettings, store: MeasurementStore) {
        let frame = screen.gaugeGeometry.overlayFrame(in: screen.frame)
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
    private var dragIsLine = false
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
        dragIsLine = event.modifierFlags.contains(.option)
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
        if mode == .colorSampler {
            copyColorUnderPointer()
            return
        }
        guard mode == .measure, let origin = dragOrigin, let current = dragCurrent, let screen = targetScreen else {
            dragOrigin = nil
            dragCurrent = nil
            dragIsLine = false
            return
        }
        let scale = screen.gaugeGeometry.scale
        let isLine = dragIsLine
        dragOrigin = nil
        dragCurrent = nil
        dragIsLine = false

        if isLine {
            commitLine(from: origin, to: current, screen: screen, scale: scale)
            needsDisplay = true
            return
        }

        let rect = normalizedRect(origin, current)

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

    private func commitLine(from origin: NSPoint, to current: NSPoint, screen: NSScreen, scale: CGFloat) {
        let dx = (current.x - origin.x) * scale
        let dy = (current.y - origin.y) * scale
        guard hypot(dx, dy) >= 3 else { return }
        let measurement = store.add(
            displayID: screen.gaugeDisplayID,
            kind: .line,
            originPixels: CGPoint(x: (origin.x * scale).rounded(), y: (origin.y * scale).rounded()),
            sizePixels: CGSize(width: dx.rounded(), height: dy.rounded())
        )
        if settings.copyOnMeasure {
            MeasurementClipboard.copy(measurement.copyString(format: settings.measurementCopyFormat))
            flashCopy(measurement.lineLabel, at: current)
        }
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
        let scale = screen.gaugeGeometry.scale
        switch mode {
        case .crosshair:
            drawCrosshair(context: context, scale: scale)
        case .measure:
            drawMeasure(context: context, scale: scale)
        case .colorSampler:
            drawColorSampler(context: context, scale: scale)
        case .loupe:
            drawLoupe(context: context, scale: scale)
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

    private func copyColorUnderPointer() {
        guard let color = ScreenCapture.pointerColor() else { return }
        let text = settings.colorCopyFormat == .rgb ? color.gaugeRGBString : color.gaugeHexString
        MeasurementClipboard.copy(text)
        if let pointer { flashCopy(text, at: pointer) }
    }

    private func drawColorSampler(context: CGContext, scale: CGFloat) {
        guard let pointer else { return }
        guard let color = ScreenCapture.pointerColor() else {
            OverlayDraw.pill(
                "Enable Screen Recording for Gauge in System Settings",
                centeredAt: CGPoint(x: pointer.x + 8, y: pointer.y + 26),
                fill: .systemRed,
                weight: .bold,
                bounds: bounds
            )
            return
        }
        let swatch = CGRect(x: pointer.x + 16, y: pointer.y + 16, width: 26, height: 26)
        context.setFillColor(color.cgColor)
        context.fill(swatch)
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(1)
        context.stroke(swatch)
        OverlayDraw.pill(color.gaugeHexString, centeredAt: CGPoint(x: swatch.maxX + 42, y: swatch.minY + 8), fill: .black, weight: .bold, bounds: bounds)
        OverlayDraw.pill(color.gaugeRGBString, centeredAt: CGPoint(x: swatch.maxX + 42, y: swatch.minY + 30), fill: .black, bounds: bounds)
    }

    private func drawLoupe(context: CGContext, scale: CGFloat) {
        guard let pointer, let location = ScreenCapture.pointerLocation else { return }
        let regionPoints: CGFloat = 22
        let captureRect = CGRect(x: location.x - regionPoints / 2, y: location.y - regionPoints / 2, width: regionPoints, height: regionPoints)
        guard let image = ScreenCapture.image(in: captureRect) else {
            OverlayDraw.pill(
                "Enable Screen Recording for Gauge in System Settings",
                centeredAt: CGPoint(x: pointer.x + 8, y: pointer.y + 26),
                fill: .systemRed,
                weight: .bold,
                bounds: bounds
            )
            return
        }

        let loupeSize: CGFloat = 176
        var box = CGRect(x: pointer.x + 22, y: pointer.y + 22, width: loupeSize, height: loupeSize)
        box.origin.x = min(max(box.minX, 8), max(8, bounds.width - loupeSize - 8))
        box.origin.y = min(max(box.minY, 8), max(8, bounds.height - loupeSize - 8))

        let pixels = max(image.width, 1)
        let cell = loupeSize / CGFloat(pixels)
        let clip = NSBezierPath(roundedRect: box, xRadius: 8, yRadius: 8)

        NSGraphicsContext.saveGraphicsState()
        clip.addClip()
        // Magnified capture, nearest-neighbor, flipped to sit upright in this flipped view.
        context.interpolationQuality = .none
        context.saveGState()
        context.translateBy(x: box.minX, y: box.minY + box.height)
        context.scaleBy(x: 1, y: -1)
        context.draw(image, in: CGRect(x: 0, y: 0, width: box.width, height: box.height))
        context.restoreGState()

        if settings.loupeShowGrid && cell >= 4 {
            context.setLineWidth(1)
            context.setStrokeColor(NSColor.white.withAlphaComponent(0.16).cgColor)
            var index = 0
            while CGFloat(index) * cell <= loupeSize {
                let offset = CGFloat(index) * cell
                context.move(to: CGPoint(x: box.minX + offset, y: box.minY))
                context.addLine(to: CGPoint(x: box.minX + offset, y: box.maxY))
                context.move(to: CGPoint(x: box.minX, y: box.minY + offset))
                context.addLine(to: CGPoint(x: box.maxX, y: box.minY + offset))
                index += 1
            }
            context.strokePath()
        }
        NSGraphicsContext.restoreGraphicsState()

        // Highlight the exact pixel under the pointer (center cell).
        let centerIndex = pixels / 2
        let centerCell = CGRect(x: box.minX + CGFloat(centerIndex) * cell, y: box.minY + CGFloat(centerIndex) * cell, width: cell, height: cell)
        context.setLineWidth(1.5)
        context.setStrokeColor(NSColor.black.withAlphaComponent(0.75).cgColor)
        context.stroke(centerCell.insetBy(dx: -0.5, dy: -0.5))
        context.setStrokeColor(NSColor.white.cgColor)
        context.stroke(centerCell)

        context.setLineWidth(1)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        clip.stroke()

        let px = Int((pointer.x * scale).rounded())
        let py = Int((pointer.y * scale).rounded())
        var readout = "\(px), \(py)"
        if let color = ScreenCapture.pointerColor() { readout += "  ·  \(color.gaugeHexString)" }
        OverlayDraw.pill(readout, centeredAt: CGPoint(x: box.midX, y: box.maxY + 14), fill: .black, weight: .bold, bounds: bounds)
    }

    private func drawMeasure(context: CGContext, scale: CGFloat) {
        if let origin = dragOrigin, let current = dragCurrent, dragIsLine {
            let dx = (current.x - origin.x) * scale
            let dy = (current.y - origin.y) * scale
            let length = Int(hypot(dx, dy).rounded())
            let angle = Int((atan2(-dy, dx) * 180 / .pi).rounded())
            OverlayDraw.line(
                from: origin,
                to: current,
                label: "\(length) px · \(angle)°",
                accent: settings.measurementTint.color,
                isLive: true,
                scale: scale,
                bounds: bounds,
                context: context
            )
        } else if let origin = dragOrigin, let current = dragCurrent {
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
