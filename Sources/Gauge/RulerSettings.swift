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
    static let defaultThickness: CGFloat = 28
    static let defaultOpacity: Double = 0.28
    static let defaultUnitStep = 100
    static let defaultTint = RulerTint.red
    static let defaultIsVisible = true
    static let defaultShowRulersOnLaunch = true
    static let defaultShowGuideNumbers = false

    @Published var thickness: CGFloat { didSet { store("thickness", thickness); notify() } }
    @Published var opacity: Double { didSet { store("opacity", opacity); notify() } }
    @Published var unitStep: Int { didSet { store("unitStep", unitStep); notify() } }
    @Published var tint: RulerTint { didSet { UserDefaults.standard.set(tint.rawValue, forKey: "tint"); notify() } }
    @Published var isVisible: Bool { didSet { UserDefaults.standard.set(isVisible, forKey: "isVisible") } }
    @Published var showRulersOnLaunch: Bool { didSet { UserDefaults.standard.set(showRulersOnLaunch, forKey: "showRulersOnLaunch") } }
    @Published var showGuideNumbers: Bool { didSet { UserDefaults.standard.set(showGuideNumbers, forKey: "showGuideNumbers"); notify() } }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "appearanceVersion") < 2 {
            defaults.set(0.28, forKey: "opacity")
            defaults.set(RulerTint.red.rawValue, forKey: "tint")
            defaults.set(2, forKey: "appearanceVersion")
        }
        thickness = defaults.object(forKey: "thickness") as? CGFloat ?? Self.defaultThickness
        opacity = defaults.object(forKey: "opacity") as? Double ?? Self.defaultOpacity
        unitStep = defaults.object(forKey: "unitStep") as? Int ?? Self.defaultUnitStep
        tint = RulerTint(rawValue: defaults.string(forKey: "tint") ?? "") ?? Self.defaultTint
        isVisible = defaults.object(forKey: "isVisible") as? Bool ?? Self.defaultIsVisible
        showRulersOnLaunch = defaults.object(forKey: "showRulersOnLaunch") as? Bool ?? Self.defaultShowRulersOnLaunch
        showGuideNumbers = defaults.object(forKey: "showGuideNumbers") as? Bool ?? Self.defaultShowGuideNumbers
    }

    func resetToDefaults() {
        thickness = Self.defaultThickness
        opacity = Self.defaultOpacity
        unitStep = Self.defaultUnitStep
        tint = Self.defaultTint
        isVisible = Self.defaultIsVisible
        showRulersOnLaunch = Self.defaultShowRulersOnLaunch
        showGuideNumbers = Self.defaultShowGuideNumbers
    }

    private func store(_ key: String, _ value: CGFloat) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Double) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Int) { UserDefaults.standard.set(value, forKey: key) }
    private func notify() { NotificationCenter.default.post(name: Self.didChangeNotification, object: self) }
}
