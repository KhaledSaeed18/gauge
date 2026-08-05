import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var overlayManager: OverlayManager
    @StateObject private var settings = RulerSettings.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Appearance") {
                Slider(value: $settings.thickness, in: 20...48, step: 1) { Text("Ruler thickness") } minimumValueLabel: { Text("20") } maximumValueLabel: { Text("48") }
                Text("Thickness: \(Int(settings.thickness)) pt").foregroundStyle(.secondary)
                Slider(value: $settings.opacity, in: 0.08...0.65, step: 0.02) { Text("Background opacity") }
                Picker("Ruler color", selection: $settings.tint) {
                    ForEach(RulerTint.allCases) { Text($0.rawValue).tag($0) }
                }
                Picker("Label every", selection: $settings.unitStep) {
                    Text("50 px").tag(50)
                    Text("100 px").tag(100)
                    Text("200 px").tag(200)
                    Text("500 px").tag(500)
                }
            }
            Section("Behavior") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                LabeledContent("Global shortcut", value: "⌃⌥⌘R")
                Text("The ruler windows ignore mouse clicks and remain visible over apps, browser windows, and full-screen spaces.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let loginError { Text(loginError).foregroundStyle(.red).font(.caption) }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 460, height: 330)
        .onChange(of: settings.thickness) { _, _ in overlayManager.rebuild() }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            launchAtLogin = !enabled
            loginError = "Could not update launch-at-login: \(error.localizedDescription)"
        }
    }
}
