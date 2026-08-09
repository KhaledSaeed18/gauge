import AppKit
@preconcurrency import ScreenCaptureKit

/// How a sampled color is written to the clipboard.
enum ColorFormat: String, CaseIterable, Identifiable {
    case hex = "Hex"
    case rgb = "RGB"

    var id: Self { self }
}

/// Captures small regions of the screen for the color sampler and loupe using
/// ScreenCaptureKit. The legacy CoreGraphics capture APIs only return the desktop
/// wallpaper on macOS 15+/26, so this is the supported path that actually reads
/// the content of other apps' windows. Gauge's own overlay windows are excluded
/// from the capture so the loupe never captures the rulers or itself.
@MainActor
final class ScreenCaptureEngine {
    static let shared = ScreenCaptureEngine()

    private var shareableContent: SCShareableContent?

    /// Whether Screen Recording permission is currently granted.
    var hasAccess: Bool { CGPreflightScreenCaptureAccess() }

    /// Triggers the one-time Screen Recording permission prompt if needed.
    func requestAccess() { CGRequestScreenCaptureAccess() }

    /// Refreshes the cached list of displays/applications used to build filters.
    /// Call when entering a capture mode so newly launched apps are visible.
    func refresh() async {
        shareableContent = try? await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    /// Captures a square region centred on `centerPoints` (top-left display-local
    /// coordinates) of the given display, at native pixel resolution.
    func captureRegion(displayID: CGDirectDisplayID, centerPoints: CGPoint, regionPoints: CGFloat, scale: CGFloat) async -> CGImage? {
        guard let filter = await filter(for: displayID) else { return nil }
        let rect = CGRect(
            x: centerPoints.x - regionPoints / 2,
            y: centerPoints.y - regionPoints / 2,
            width: regionPoints,
            height: regionPoints
        )
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = rect
        configuration.width = max(1, Int((regionPoints * scale).rounded()))
        configuration.height = max(1, Int((regionPoints * scale).rounded()))
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true
        return try? await SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration)
    }

    private func filter(for displayID: CGDirectDisplayID) async -> SCContentFilter? {
        if shareableContent == nil { await refresh() }
        guard let content = shareableContent,
              let display = content.displays.first(where: { $0.displayID == displayID }) else { return nil }
        let gaugeApp = content.applications.first { $0.bundleIdentifier == Bundle.main.bundleIdentifier }
        if let gaugeApp {
            return SCContentFilter(display: display, excludingApplications: [gaugeApp], exceptingWindows: [])
        }
        return SCContentFilter(display: display, excludingWindows: [])
    }
}

extension CGImage {
    /// The sRGB color of the pixel at the image's center.
    var gaugeCenterColor: NSColor? {
        NSBitmapImageRep(cgImage: self).colorAt(x: width / 2, y: height / 2)?.usingColorSpace(.sRGB)
    }
}

extension NSColor {
    /// Uppercase `#RRGGBB` string in sRGB.
    var gaugeHexString: String {
        guard let color = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int((color.redComponent * 255).rounded())
        let g = Int((color.greenComponent * 255).rounded())
        let b = Int((color.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }

    /// `R, G, B` string (0–255) in sRGB.
    var gaugeRGBString: String {
        guard let color = usingColorSpace(.sRGB) else { return "0, 0, 0" }
        let r = Int((color.redComponent * 255).rounded())
        let g = Int((color.greenComponent * 255).rounded())
        let b = Int((color.blueComponent * 255).rounded())
        return "\(r), \(g), \(b)"
    }
}
