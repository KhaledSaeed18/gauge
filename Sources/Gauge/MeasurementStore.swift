import AppKit
import GaugeCore

@MainActor
final class MeasurementStore: ObservableObject {
    static let didChangeNotification = Notification.Name("GaugeMeasurementsDidChange")
    @Published private(set) var measurements: [PixelMeasurement] = []

    var isEmpty: Bool { measurements.isEmpty }
    var count: Int { measurements.count }

    @discardableResult
    func add(displayID: UInt32, kind: MeasurementKind = .box, originPixels: CGPoint, sizePixels: CGSize) -> PixelMeasurement {
        let measurement = PixelMeasurement(
            id: UUID(),
            displayID: displayID,
            kind: kind,
            originPixels: originPixels,
            sizePixels: sizePixels
        )
        measurements.append(measurement)
        notify()
        return measurement
    }

    func measurements(for displayID: UInt32) -> [PixelMeasurement] {
        measurements.filter { $0.displayID == displayID }
    }

    /// The most recently committed measurement, used for clipboard copy.
    var latest: PixelMeasurement? { measurements.last }

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
