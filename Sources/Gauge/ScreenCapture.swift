import AppKit

/// Thin wrapper around the CoreGraphics screen-capture APIs used by the color
/// sampler and the loupe. Isolated here so the capture backend can be swapped
/// (e.g. for ScreenCaptureKit) without touching the overlay views.
///
/// All capture requires the macOS Screen Recording permission; the capture calls
/// return `nil` until the user grants it.
enum ScreenCapture {
    /// The current cursor position in top-left CoreGraphics global coordinates.
    static var pointerLocation: CGPoint? { CGEvent(source: nil)?.location }

    /// Captures an on-screen region (top-left global coordinates) at native resolution.
    static func image(in rect: CGRect) -> CGImage? {
        CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming])
    }

    /// The sRGB color of the single pixel under the pointer, or `nil` if capture is unavailable.
    static func pointerColor() -> NSColor? {
        guard let location = pointerLocation,
              let image = image(in: CGRect(x: location.x, y: location.y, width: 1, height: 1)) else { return nil }
        return NSBitmapImageRep(cgImage: image).colorAt(x: 0, y: 0)?.usingColorSpace(.sRGB)
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
