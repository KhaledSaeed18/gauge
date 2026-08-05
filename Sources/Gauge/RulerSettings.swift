import SwiftUI

enum RulerTint: String, CaseIterable, Identifiable {
    case red = "Red"
    case blue = "Blue"

    var id: Self { self }
    var color: NSColor { self == .red ? .systemRed : .systemBlue }
}

@MainActor
final class RulerSettings: ObservableObject {
    static let didChangeNotification = Notification.Name("GaugeRulerSettingsDidChange")
    static let shared = RulerSettings()

    @Published var thickness: CGFloat { didSet { store("thickness", thickness); notify() } }
    @Published var opacity: Double { didSet { store("opacity", opacity); notify() } }
    @Published var unitStep: Int { didSet { store("unitStep", unitStep); notify() } }
    @Published var tint: RulerTint { didSet { UserDefaults.standard.set(tint.rawValue, forKey: "tint"); notify() } }
    @Published var isVisible: Bool { didSet { UserDefaults.standard.set(isVisible, forKey: "isVisible") } }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "appearanceVersion") < 2 {
            defaults.set(0.28, forKey: "opacity")
            defaults.set(RulerTint.red.rawValue, forKey: "tint")
            defaults.set(2, forKey: "appearanceVersion")
        }
        thickness = defaults.object(forKey: "thickness") as? CGFloat ?? 28
        opacity = defaults.object(forKey: "opacity") as? Double ?? 0.28
        unitStep = defaults.object(forKey: "unitStep") as? Int ?? 100
        tint = RulerTint(rawValue: defaults.string(forKey: "tint") ?? "") ?? .red
        isVisible = defaults.object(forKey: "isVisible") as? Bool ?? true
    }

    private func store(_ key: String, _ value: CGFloat) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Double) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Int) { UserDefaults.standard.set(value, forKey: key) }
    private func notify() { NotificationCenter.default.post(name: Self.didChangeNotification, object: self) }
}
