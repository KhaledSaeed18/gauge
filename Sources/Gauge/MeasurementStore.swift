import AppKit

/// A committed measurement rectangle, stored in physical pixels relative to the
/// top-left of its display so it survives backing-scale changes just like guides.
struct Measurement: Identifiable {
    let id: UUID
    let displayID: UInt32
    var originPixels: CGPoint
    var sizePixels: CGSize

    var widthPixels: Int { Int(sizePixels.width.rounded()) }
    var heightPixels: Int { Int(sizePixels.height.rounded()) }

    /// Human-readable and clipboard-ready dimension string, e.g. `420 × 260`.
    var dimensionLabel: String { "\(widthPixels) × \(heightPixels)" }
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
