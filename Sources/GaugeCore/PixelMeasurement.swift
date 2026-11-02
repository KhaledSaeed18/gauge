import CoreGraphics
import Foundation

/// How a measurement is rendered when copied to the clipboard.
public enum MeasurementFormat: String, CaseIterable, Identifiable, Sendable {
    case dimensions = "Dimensions"
    case plain = "Plain"
    case withUnits = "With units"
    case css = "CSS"
    case withPosition = "With position"

    public var id: Self { self }

    public func string(width: Int, height: Int, x: Int, y: Int) -> String {
        switch self {
        case .dimensions: return "\(width) × \(height)"
        case .plain: return "\(width)x\(height)"
        case .withUnits: return "\(width)px × \(height)px"
        case .css: return "width: \(width)px; height: \(height)px;"
        case .withPosition: return "\(width) × \(height) @ \(x), \(y)"
        }
    }

    /// A representative sample used to preview the format in Settings.
    public var example: String { string(width: 320, height: 200, x: 100, y: 50) }
}

/// Reduces `width:height` to its simplest integer ratio, e.g. `320, 200` → `8:5`.
/// A hand-drawn box rarely reduces to anything readable (`790, 526` is `395:263`),
/// so once either term passes `maxTerm` the ratio is shown as a decimal of the
/// longer side to the shorter one instead, e.g. `1.50:1` or `1:1.50`.
public func reducedRatio(width: Int, height: Int, maxTerm: Int = 32) -> String {
    guard width > 0, height > 0 else { return "—" }
    var a = width, b = height
    while b != 0 { (a, b) = (b, a % b) }
    let divisor = max(a, 1)
    let (w, h) = (width / divisor, height / divisor)
    guard max(w, h) > maxTerm else { return "\(w):\(h)" }
    let decimal = String(format: "%.2f", Double(max(width, height)) / Double(min(width, height)))
    return width >= height ? "\(decimal):1" : "1:\(decimal)"
}

/// Whether a measurement is an axis-aligned box or a free two-point line.
public enum MeasurementKind: Sendable {
    case box
    case line
}

/// A committed measurement, stored in physical pixels relative to the top-left of
/// its display so it survives backing-scale changes just like guides. A box uses a
/// positive size; a line uses `originPixels` as its start and `sizePixels` as the
/// signed delta to its end point.
public struct PixelMeasurement: Identifiable, Sendable {
    public let id: UUID
    public let displayID: UInt32
    public let kind: MeasurementKind
    public var originPixels: CGPoint
    public var sizePixels: CGSize

    public init(id: UUID = UUID(), displayID: UInt32, kind: MeasurementKind, originPixels: CGPoint, sizePixels: CGSize) {
        self.id = id
        self.displayID = displayID
        self.kind = kind
        self.originPixels = originPixels
        self.sizePixels = sizePixels
    }

    public var widthPixels: Int { Int(sizePixels.width.rounded()) }
    public var heightPixels: Int { Int(sizePixels.height.rounded()) }
    public var xPixels: Int { Int(originPixels.x.rounded()) }
    public var yPixels: Int { Int(originPixels.y.rounded()) }

    /// Line endpoint (start + signed delta).
    public var endPixels: CGPoint { CGPoint(x: originPixels.x + sizePixels.width, y: originPixels.y + sizePixels.height) }

    /// Line length in pixels.
    public var lengthPixels: Int { Int(hypot(sizePixels.width, sizePixels.height).rounded()) }

    /// Line angle in degrees, measured counter-clockwise from the positive x-axis
    /// (up is positive, matching how people read angles on screen).
    public var angleDegrees: Int {
        // Negating a zero height gives -0.0, and atan2(-0.0, negative) is -π, so a
        // line drawn straight left read as -180°. Flip the sign only when non-zero.
        let rise = sizePixels.height == 0 ? 0 : -sizePixels.height
        return Int((atan2(rise, sizePixels.width) * 180 / .pi).rounded())
    }

    /// Human-readable dimension string shown on screen, e.g. `420 × 260`.
    public var dimensionLabel: String { "\(widthPixels) × \(heightPixels)" }

    /// Human-readable line string, e.g. `312 px · 34°`.
    public var lineLabel: String { "\(lengthPixels) px · \(angleDegrees)°" }

    /// Simplest integer aspect ratio, e.g. `8:5`.
    public var aspectRatioLabel: String { reducedRatio(width: widthPixels, height: heightPixels) }

    /// Clipboard string for the given format (lines always copy length and angle).
    public func copyString(format: MeasurementFormat) -> String {
        switch kind {
        case .line: return lineLabel
        case .box: return format.string(width: widthPixels, height: heightPixels, x: xPixels, y: yPixels)
        }
    }
}

