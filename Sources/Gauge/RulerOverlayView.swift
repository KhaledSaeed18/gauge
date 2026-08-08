import AppKit

@MainActor
final class RulerOverlayView: NSView {
    private weak var targetScreen: NSScreen?
    private let settings: RulerSettings
    private let guideStore: GuideStore
    private var settingsObserver: NSObjectProtocol?
    private var guideObserver: NSObjectProtocol?

    init(frame frameRect: NSRect, screen: NSScreen, settings: RulerSettings, guideStore: GuideStore) {
        targetScreen = screen
        self.settings = settings
        self.guideStore = guideStore
        super.init(frame: frameRect)
        wantsLayer = true
        settingsObserver = NotificationCenter.default.addObserver(
            forName: RulerSettings.didChangeNotification, object: settings, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
        guideObserver = NotificationCenter.default.addObserver(
            forName: GuideStore.didChangeNotification, object: guideStore, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.needsDisplay = true }
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let screen = targetScreen, let context = NSGraphicsContext.current?.cgContext else { return }
        let scale = screen.backingScaleFactor
        let thickness = settings.thickness
        // Keep the system menu bar unobstructed on the primary display.
        let topInset = max(0, screen.frame.maxY - screen.visibleFrame.maxY)
        let top = NSRect(x: 0, y: topInset, width: bounds.width, height: thickness)
        let left = NSRect(x: 0, y: topInset, width: thickness, height: bounds.height - topInset)

        let horizontalAccent = settings.horizontalTint.color
        let verticalAccent = settings.verticalTint.color
        context.setFillColor(verticalAccent.withAlphaComponent(settings.opacity).cgColor)
        context.fill(top)
        context.setFillColor(horizontalAccent.withAlphaComponent(settings.opacity).cgColor)
        context.fill(left)
        context.setLineWidth(1 / scale)
        context.setStrokeColor(verticalAccent.withAlphaComponent(0.65).cgColor)
        context.move(to: CGPoint(x: 0, y: topInset + thickness - 0.5 / scale))
        context.addLine(to: CGPoint(x: bounds.width, y: topInset + thickness - 0.5 / scale))
        context.strokePath()
        context.setStrokeColor(horizontalAccent.withAlphaComponent(0.65).cgColor)
        context.move(to: CGPoint(x: thickness - 0.5 / scale, y: topInset))
        context.addLine(to: CGPoint(x: thickness - 0.5 / scale, y: bounds.height))
        context.strokePath()

        drawHorizontal(context: context, scale: scale, thickness: thickness, topInset: topInset, accent: verticalAccent)
        drawVertical(context: context, scale: scale, thickness: thickness, topInset: topInset, accent: horizontalAccent)
        drawGuides(
            context: context,
            scale: scale,
            thickness: thickness,
            topInset: topInset,
            horizontalAccent: horizontalAccent,
            verticalAccent: verticalAccent,
            displayID: screen.gaugeDisplayID
        )
        drawOriginBadge(context: context, thickness: thickness, topInset: topInset, horizontalAccent: horizontalAccent, verticalAccent: verticalAccent)
    }

    private func drawHorizontal(context: CGContext, scale: CGFloat, thickness: CGFloat, topInset: CGFloat, accent: NSColor) {
        let pixelWidth = Int((bounds.width * scale).rounded(.down))
        for pixel in stride(from: 0, through: pixelWidth, by: 10) {
            let x = CGFloat(pixel) / scale
            let major = pixel % settings.unitStep == 0
            let medium = pixel % 50 == 0
            let length: CGFloat = major ? thickness * 0.58 : (medium ? thickness * 0.38 : thickness * 0.22)
            context.setStrokeColor((major ? accent : NSColor.white.withAlphaComponent(0.72)).cgColor)
            context.setLineWidth(1 / scale)
            context.move(to: CGPoint(x: x + 0.5 / scale, y: topInset + thickness))
            context.addLine(to: CGPoint(x: x + 0.5 / scale, y: topInset + thickness - length))
            context.strokePath()
            if major && pixel > 0 { drawLabel("\(pixel)", at: CGPoint(x: x + 4, y: topInset + 3), vertical: false, accent: accent) }
        }
    }

    private func drawVertical(context: CGContext, scale: CGFloat, thickness: CGFloat, topInset: CGFloat, accent: NSColor) {
        let pixelHeight = Int(((bounds.height - topInset) * scale).rounded(.down))
        for pixel in stride(from: 0, through: pixelHeight, by: 10) {
            let y = topInset + CGFloat(pixel) / scale
            let major = pixel % settings.unitStep == 0
            let medium = pixel % 50 == 0
            let length: CGFloat = major ? thickness * 0.58 : (medium ? thickness * 0.38 : thickness * 0.22)
            context.setStrokeColor((major ? accent : NSColor.white.withAlphaComponent(0.72)).cgColor)
            context.setLineWidth(1 / scale)
            context.move(to: CGPoint(x: thickness, y: y + 0.5 / scale))
            context.addLine(to: CGPoint(x: thickness - length, y: y + 0.5 / scale))
            context.strokePath()
            if major && pixel > 0 { drawLabel("\(pixel)", at: CGPoint(x: 3, y: y + 4), vertical: true, accent: accent) }
        }
    }

    private func drawLabel(_ text: String, at point: CGPoint, vertical: Bool, accent: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: accent
        ]
        let label = NSAttributedString(string: text, attributes: attributes)
        let size = label.size()
        NSGraphicsContext.saveGraphicsState()
        if vertical {
            NSGraphicsContext.current?.cgContext.translateBy(x: point.x, y: point.y + size.width)
            NSGraphicsContext.current?.cgContext.rotate(by: -.pi / 2)
            label.draw(at: .zero)
        } else {
            label.draw(at: point)
        }
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawGuides(context: CGContext, scale: CGFloat, thickness: CGFloat, topInset: CGFloat, horizontalAccent: NSColor, verticalAccent: NSColor, displayID: UInt32) {
        context.setLineWidth(1 / scale)
        let guides = guideStore.guides(for: displayID)
        let verticalGuides = guides
            .filter { $0.orientation == .vertical }
            .sorted { $0.positionPixels < $1.positionPixels }
        let horizontalGuides = guides
            .filter { $0.orientation == .horizontal }
            .sorted { $0.positionPixels < $1.positionPixels }

        for (index, guide) in verticalGuides.enumerated() {
            let position = CGFloat(guide.positionPixels) / scale
            context.setStrokeColor(verticalAccent.withAlphaComponent(0.9).cgColor)
            context.move(to: CGPoint(x: position + 0.5 / scale, y: topInset))
            context.addLine(to: CGPoint(x: position + 0.5 / scale, y: bounds.height))
            context.strokePath()
            if settings.showGuideNumbers {
                drawGuideBadge(
                    "V\(index + 1)",
                    at: CGPoint(x: position + 6, y: topInset + thickness + 6),
                    accent: verticalAccent
                )
            }
        }

        for (index, guide) in horizontalGuides.enumerated() {
            let position = CGFloat(guide.positionPixels) / scale
            context.setStrokeColor(horizontalAccent.withAlphaComponent(0.9).cgColor)
            context.move(to: CGPoint(x: 0, y: topInset + position + 0.5 / scale))
            context.addLine(to: CGPoint(x: bounds.width, y: topInset + position + 0.5 / scale))
            context.strokePath()
            if settings.showGuideNumbers {
                drawGuideBadge(
                    "H\(index + 1)",
                    at: CGPoint(x: thickness + 6, y: topInset + position + 6),
                    accent: horizontalAccent
                )
            }
        }
    }

    private func drawGuideBadge(_ text: String, at point: CGPoint, accent: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let label = NSAttributedString(string: text, attributes: attributes)
        let size = label.size()
        let width = size.width + 10
        let height = size.height + 5
        let x = min(max(point.x, 4), max(4, bounds.width - width - 4))
        let y = min(max(point.y, 4), max(4, bounds.height - height - 4))
        let rect = CGRect(x: x, y: y, width: width, height: height)

        NSGraphicsContext.saveGraphicsState()
        accent.withAlphaComponent(0.92).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
        label.draw(at: CGPoint(x: rect.minX + 5, y: rect.minY + 2))
        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawOriginBadge(context: CGContext, thickness: CGFloat, topInset: CGFloat, horizontalAccent: NSColor, verticalAccent: NSColor) {
        let side = min(thickness, 28)
        let rect = CGRect(x: 0, y: topInset, width: side, height: side)
        context.setFillColor(NSColor.black.withAlphaComponent(0.42).cgColor)
        context.fill(rect)
        context.setFillColor(verticalAccent.withAlphaComponent(0.95).cgColor)
        context.fill(CGRect(x: 0, y: topInset, width: side, height: 3))
        context.setFillColor(horizontalAccent.withAlphaComponent(0.95).cgColor)
        context.fill(CGRect(x: 0, y: topInset, width: 3, height: side))
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.9).cgColor)
        context.setLineWidth(1.15)

        let rulerRect = CGRect(
            x: side * 0.21,
            y: topInset + side * 0.34,
            width: side * 0.62,
            height: side * 0.28
        )
        NSBezierPath(roundedRect: rulerRect, xRadius: 2, yRadius: 2).stroke()

        for index in 1...5 {
            let x = rulerRect.minX + rulerRect.width * CGFloat(index) / 6
            let tickHeight = index.isMultiple(of: 2) ? rulerRect.height * 0.58 : rulerRect.height * 0.38
            context.move(to: CGPoint(x: x, y: rulerRect.minY + 1.8))
            context.addLine(to: CGPoint(x: x, y: rulerRect.minY + 1.8 + tickHeight))
        }
        context.strokePath()
    }
}
