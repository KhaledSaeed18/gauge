import AppKit

/// How a measurement is rendered when copied to the clipboard.
enum MeasurementFormat: String, CaseIterable, Identifiable {
    case dimensions = "Dimensions"
    case plain = "Plain"
    case withUnits = "With units"
    case css = "CSS"
    case withPosition = "With position"

    var id: Self { self }

    func string(width: Int, height: Int, x: Int, y: Int) -> String {
        switch self {
        case .dimensions: return "\(width) × \(height)"
        case .plain: return "\(width)x\(height)"
        case .withUnits: return "\(width)px × \(height)px"
        case .css: return "width: \(width)px; height: \(height)px;"
        case .withPosition: return "\(width) × \(height) @ \(x), \(y)"
        }
    }

    /// A representative sample used to preview the format in Settings.
    var example: String { string(width: 320, height: 200, x: 100, y: 50) }
}

/// Reduces `width:height` to its simplest integer ratio, e.g. `320, 200` → `8:5`.
func reducedRatio(width: Int, height: Int) -> String {
    guard width > 0, height > 0 else { return "—" }
    var a = width, b = height
    while b != 0 { (a, b) = (b, a % b) }
    let divisor = max(a, 1)
    return "\(width / divisor):\(height / divisor)"
}

/// A committed measurement rectangle, stored in physical pixels relative to the
/// top-left of its display so it survives backing-scale changes just like guides.
struct Measurement: Identifiable {
    let id: UUID
    let displayID: UInt32
    var originPixels: CGPoint
    var sizePixels: CGSize

    var widthPixels: Int { Int(sizePixels.width.rounded()) }
    var heightPixels: Int { Int(sizePixels.height.rounded()) }
    var xPixels: Int { Int(originPixels.x.rounded()) }
    var yPixels: Int { Int(originPixels.y.rounded()) }

    /// Human-readable dimension string shown on screen, e.g. `420 × 260`.
    var dimensionLabel: String { "\(widthPixels) × \(heightPixels)" }

    /// Simplest integer aspect ratio, e.g. `8:5`.
    var aspectRatioLabel: String { reducedRatio(width: widthPixels, height: heightPixels) }

    /// Clipboard string for the given format.
    func copyString(format: MeasurementFormat) -> String {
        format.string(width: widthPixels, height: heightPixels, x: xPixels, y: yPixels)
    }
}

@MainActor
final class MeasurementStore: ObservableObject {
    static let didChangeNotification = Notification.Name("GaugeMeasurementsDidChange")
    @Published private(set) var measurements: [Measurement] = []

    var isEmpty: Bool { measurements.isEmpty }
    var count: Int { measurements.count }

    @discardableResult
    func add(displayID: UInt32, originPixels: CGPoint, sizePixels: CGSize) -> Measurement {
        let measurement = Measurement(
            id: UUID(),
            displayID: displayID,
            originPixels: originPixels,
            sizePixels: sizePixels
        )
        measurements.append(measurement)
        notify()
        return measurement
    }

    func measurements(for displayID: UInt32) -> [Measurement] {
        measurements.filter { $0.displayID == displayID }
    }

    /// The most recently committed measurement, used for clipboard copy.
    var latest: Measurement? { measurements.last }

    func removeLast() {
        guard !measurements.isEmpty else { return }
        measurements.removeLast()
        notify()
    }

    func remove(id: UUID) {
        measurements.removeAll { $0.id == id }
        notify()
    }

    func clear(displayID: UInt32? = nil) {
        if let displayID {
            measurements.removeAll { $0.displayID == displayID }
        } else {
            measurements.removeAll()
        }
        notify()
    }

    private func notify() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
