import SwiftUI

enum RulerTint: String, CaseIterable, Identifiable {
    case red = "Red"
    case orange = "Orange"
    case yellow = "Yellow"
    case green = "Green"
    case mint = "Mint"
    case cyan = "Cyan"
    case blue = "Blue"
    case purple = "Purple"
    case pink = "Pink"
    case white = "White"

    var id: Self { self }
    var color: NSColor {
        switch self {
        case .red:
            return .systemRed
        case .orange:
            return .systemOrange
        case .yellow:
            return .systemYellow
        case .green:
            return .systemGreen
        case .mint:
            return .systemMint
        case .cyan:
            return .systemCyan
        case .blue:
            return .systemBlue
        case .purple:
            return .systemPurple
        case .pink:
            return .systemPink
        case .white:
            return .white
        }
    }
}

@MainActor
final class RulerSettings: ObservableObject {
    static let didChangeNotification = Notification.Name("GaugeRulerSettingsDidChange")
    static let shared = RulerSettings()
    static let defaultThickness: CGFloat = 28
    static let defaultOpacity: Double = 0.28
    static let defaultUnitStep = 100
    static let defaultHorizontalTint = RulerTint.red
    static let defaultVerticalTint = RulerTint.blue
    static let defaultIsVisible = true
    static let defaultShowRulersOnLaunch = true
    static let defaultShowGuideNumbers = false
    static let defaultShowSettingDescriptions = true
    static let defaultCopyOnMeasure = true
    static let defaultShowMeasurementLabels = true
    static let defaultShowMeasurementPosition = false
    static let defaultShowMeasurementAspectRatio = false
    static let defaultMeasurementTint = RulerTint.green
    static let defaultShowCrosshairReadout = true
    static let defaultCrosshairTint = RulerTint.cyan
    static let defaultMeasurementCopyFormat = MeasurementFormat.dimensions
    static let defaultColorCopyFormat = ColorFormat.hex
    static let defaultLoupeShowGrid = true

    @Published var thickness: CGFloat { didSet { store("thickness", thickness); notify() } }
    @Published var opacity: Double { didSet { store("opacity", opacity); notify() } }
    @Published var unitStep: Int { didSet { store("unitStep", unitStep); notify() } }
    @Published var horizontalTint: RulerTint { didSet { UserDefaults.standard.set(horizontalTint.rawValue, forKey: "horizontalTint"); notify() } }
    @Published var verticalTint: RulerTint { didSet { UserDefaults.standard.set(verticalTint.rawValue, forKey: "verticalTint"); notify() } }
    @Published var isVisible: Bool { didSet { UserDefaults.standard.set(isVisible, forKey: "isVisible") } }
    @Published var showRulersOnLaunch: Bool { didSet { UserDefaults.standard.set(showRulersOnLaunch, forKey: "showRulersOnLaunch") } }
    @Published var showGuideNumbers: Bool { didSet { UserDefaults.standard.set(showGuideNumbers, forKey: "showGuideNumbers"); notify() } }
    @Published var showSettingDescriptions: Bool { didSet { UserDefaults.standard.set(showSettingDescriptions, forKey: "showSettingDescriptions") } }
    @Published var copyOnMeasure: Bool { didSet { UserDefaults.standard.set(copyOnMeasure, forKey: "copyOnMeasure") } }
    @Published var showMeasurementLabels: Bool { didSet { UserDefaults.standard.set(showMeasurementLabels, forKey: "showMeasurementLabels"); notify() } }
    @Published var showMeasurementPosition: Bool { didSet { UserDefaults.standard.set(showMeasurementPosition, forKey: "showMeasurementPosition"); notify() } }
    @Published var showMeasurementAspectRatio: Bool { didSet { UserDefaults.standard.set(showMeasurementAspectRatio, forKey: "showMeasurementAspectRatio"); notify() } }
    @Published var measurementTint: RulerTint { didSet { UserDefaults.standard.set(measurementTint.rawValue, forKey: "measurementTint"); notify() } }
    @Published var showCrosshairReadout: Bool { didSet { UserDefaults.standard.set(showCrosshairReadout, forKey: "showCrosshairReadout"); notify() } }
    @Published var crosshairTint: RulerTint { didSet { UserDefaults.standard.set(crosshairTint.rawValue, forKey: "crosshairTint"); notify() } }
    @Published var measurementCopyFormat: MeasurementFormat { didSet { UserDefaults.standard.set(measurementCopyFormat.rawValue, forKey: "measurementCopyFormat") } }
    @Published var colorCopyFormat: ColorFormat { didSet { UserDefaults.standard.set(colorCopyFormat.rawValue, forKey: "colorCopyFormat") } }
    @Published var loupeShowGrid: Bool { didSet { UserDefaults.standard.set(loupeShowGrid, forKey: "loupeShowGrid"); notify() } }

    private init() {
        let defaults = UserDefaults.standard
        if defaults.integer(forKey: "appearanceVersion") < 2 {
            defaults.set(0.28, forKey: "opacity")
            defaults.set(RulerTint.red.rawValue, forKey: "tint")
            defaults.set(2, forKey: "appearanceVersion")
        }
        let legacyTint = RulerTint(rawValue: defaults.string(forKey: "tint") ?? "")
        thickness = defaults.object(forKey: "thickness") as? CGFloat ?? Self.defaultThickness
        opacity = defaults.object(forKey: "opacity") as? Double ?? Self.defaultOpacity
        unitStep = Self.normalizedUnitStep(defaults.object(forKey: "unitStep") as? Int ?? Self.defaultUnitStep)
        horizontalTint = RulerTint(rawValue: defaults.string(forKey: "horizontalTint") ?? "") ?? legacyTint ?? Self.defaultHorizontalTint
        verticalTint = RulerTint(rawValue: defaults.string(forKey: "verticalTint") ?? "") ?? legacyTint ?? Self.defaultVerticalTint
        isVisible = defaults.object(forKey: "isVisible") as? Bool ?? Self.defaultIsVisible
        showRulersOnLaunch = defaults.object(forKey: "showRulersOnLaunch") as? Bool ?? Self.defaultShowRulersOnLaunch
        showGuideNumbers = defaults.object(forKey: "showGuideNumbers") as? Bool ?? Self.defaultShowGuideNumbers
        showSettingDescriptions = defaults.object(forKey: "showSettingDescriptions") as? Bool ?? Self.defaultShowSettingDescriptions
        copyOnMeasure = defaults.object(forKey: "copyOnMeasure") as? Bool ?? Self.defaultCopyOnMeasure
        showMeasurementLabels = defaults.object(forKey: "showMeasurementLabels") as? Bool ?? Self.defaultShowMeasurementLabels
        showMeasurementPosition = defaults.object(forKey: "showMeasurementPosition") as? Bool ?? Self.defaultShowMeasurementPosition
        showMeasurementAspectRatio = defaults.object(forKey: "showMeasurementAspectRatio") as? Bool ?? Self.defaultShowMeasurementAspectRatio
        measurementTint = RulerTint(rawValue: defaults.string(forKey: "measurementTint") ?? "") ?? Self.defaultMeasurementTint
        showCrosshairReadout = defaults.object(forKey: "showCrosshairReadout") as? Bool ?? Self.defaultShowCrosshairReadout
        crosshairTint = RulerTint(rawValue: defaults.string(forKey: "crosshairTint") ?? "") ?? Self.defaultCrosshairTint
        measurementCopyFormat = MeasurementFormat(rawValue: defaults.string(forKey: "measurementCopyFormat") ?? "") ?? Self.defaultMeasurementCopyFormat
        colorCopyFormat = ColorFormat(rawValue: defaults.string(forKey: "colorCopyFormat") ?? "") ?? Self.defaultColorCopyFormat
        loupeShowGrid = defaults.object(forKey: "loupeShowGrid") as? Bool ?? Self.defaultLoupeShowGrid
    }

    func resetToDefaults() {
        thickness = Self.defaultThickness
        opacity = Self.defaultOpacity
        unitStep = Self.defaultUnitStep
        horizontalTint = Self.defaultHorizontalTint
        verticalTint = Self.defaultVerticalTint
        isVisible = Self.defaultIsVisible
        showRulersOnLaunch = Self.defaultShowRulersOnLaunch
        showGuideNumbers = Self.defaultShowGuideNumbers
        showSettingDescriptions = Self.defaultShowSettingDescriptions
        copyOnMeasure = Self.defaultCopyOnMeasure
        showMeasurementLabels = Self.defaultShowMeasurementLabels
        showMeasurementPosition = Self.defaultShowMeasurementPosition
        showMeasurementAspectRatio = Self.defaultShowMeasurementAspectRatio
        measurementTint = Self.defaultMeasurementTint
        showCrosshairReadout = Self.defaultShowCrosshairReadout
        crosshairTint = Self.defaultCrosshairTint
        measurementCopyFormat = Self.defaultMeasurementCopyFormat
        colorCopyFormat = Self.defaultColorCopyFormat
        loupeShowGrid = Self.defaultLoupeShowGrid
    }

    private func store(_ key: String, _ value: CGFloat) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Double) { UserDefaults.standard.set(value, forKey: key) }
    private func store(_ key: String, _ value: Int) { UserDefaults.standard.set(value, forKey: key) }
    private static func normalizedUnitStep(_ value: Int) -> Int {
        [100, 200, 500].contains(value) ? value : Self.defaultUnitStep
    }
    private func notify() { NotificationCenter.default.post(name: Self.didChangeNotification, object: self) }
}
