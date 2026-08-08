import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @EnvironmentObject private var overlayManager: OverlayManager
    @StateObject private var settings = RulerSettings.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @State private var showingResetConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                appearanceTab
                    .tabItem { Label("Appearance", systemImage: "paintpalette") }
                guidesTab
                    .tabItem { Label("Guides", systemImage: "scope") }
                startupTab
                    .tabItem { Label("Startup", systemImage: "power") }
                aboutTab
                    .tabItem { Label("About", systemImage: "info.circle") }
            }

            Divider()
            HStack {
                Button("Reset Settings...", role: .destructive) { showingResetConfirmation = true }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 560, height: 430)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
        .onChange(of: settings.thickness) { _, _ in overlayManager.rebuild() }
        .confirmationDialog(
            "Reset Gauge settings?",
            isPresented: $showingResetConfirmation
        ) {
            Button("Reset Settings", role: .destructive) { resetSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores ruler appearance, guide numbering, and startup behavior. Existing guide lines are kept.")
        }
    }

    private var appearanceTab: some View {
        Form {
            Section {
                Slider(value: $settings.thickness, in: 20...48, step: 1) {
                    Text("Ruler thickness")
                } minimumValueLabel: {
                    Text("20")
                } maximumValueLabel: {
                    Text("48")
                }
                Text("Thickness: \(Int(settings.thickness)) pt")
                    .foregroundStyle(.secondary)

                Slider(value: $settings.opacity, in: 0.08...0.65, step: 0.02) {
                    Text("Background opacity")
                }

                Picker("Vertical guide color", selection: $settings.verticalTint) {
                    ForEach(RulerTint.allCases) { tint in
                        Label {
                            Text(tint.rawValue)
                        } icon: {
                            TintSwatch(tint: tint)
                        }
                        .tag(tint)
                    }
                }

                Picker("Horizontal guide color", selection: $settings.horizontalTint) {
                    ForEach(RulerTint.allCases) { tint in
                        Label {
                            Text(tint.rawValue)
                        } icon: {
                            TintSwatch(tint: tint)
                        }
                        .tag(tint)
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("Vertical guide color controls the top ruler and vertical guides. Horizontal guide color controls the left ruler and horizontal guides.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var guidesTab: some View {
        Form {
            Section {
                Picker("Tick label interval", selection: $settings.unitStep) {
                    Text("50 px").tag(50)
                    Text("100 px").tag(100)
                    Text("200 px").tag(200)
                    Text("500 px").tag(500)
                }

                Toggle("Number guide lines", isOn: $settings.showGuideNumbers)
                Text("Guide numbers are assigned automatically by position for each display, with vertical and horizontal guides numbered separately.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Guides")
            } footer: {
                Text("Use Guide Placement from the menu bar, then click or drag on a ruler to add alignment guides.")
            }

            GuideRemovalSection(guideStore: overlayManager.guideStore)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var startupTab: some View {
        Form {
            Section {
                Toggle("Start Gauge at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }

                Toggle("Show rulers when Gauge starts", isOn: $settings.showRulersOnLaunch)

                LabeledContent("Global shortcut", value: "⌃⌥⌘R")

                if let loginError {
                    Text(loginError)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            } header: {
                Text("Startup")
            } footer: {
                Text("Start Gauge at login only opens the menu-bar app. Show rulers when Gauge starts controls whether the overlay appears immediately.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 14) {
                Image(systemName: "ruler")
                    .font(.system(size: 42, weight: .semibold))
                    .foregroundStyle(.red)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gauge")
                        .font(.largeTitle.weight(.semibold))
                    Text("Pixel-precise desktop alignment for macOS.")
                        .foregroundStyle(.secondary)
                }
            }

            Text("Gauge draws click-through rulers and persistent alignment guides over every display, so you can line up app windows, browser layouts, screenshots, and prototypes without switching tools.")
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: URL(string: "https://github.com/KhaledSaeed18/gauge")!) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                    Text("KhaledSaeed18/gauge")
                }
            }

            Spacer()
        }
        .padding(28)
    }

    private func resetSettings() {
        if launchAtLogin {
            setLaunchAtLogin(false)
        }
        settings.resetToDefaults()
        overlayManager.show()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
            loginError = nil
        } catch {
            launchAtLogin = !enabled
            loginError = "Could not update start-at-login: \(error.localizedDescription)"
        }
    }
}

private struct TintSwatch: View {
    let tint: RulerTint

    var body: some View {
        Circle()
            .fill(Color(nsColor: tint.color))
            .overlay {
                Circle()
                    .stroke(.secondary.opacity(0.35), lineWidth: 1)
            }
            .frame(width: 12, height: 12)
    }
}

private struct GuideRemovalSection: View {
    @ObservedObject var guideStore: GuideStore
    @State private var selectedGuideIDs = Set<UUID>()

    private var numberedGuides: [NumberedGuide] { guideStore.numberedGuides() }

    var body: some View {
        Section {
            if numberedGuides.isEmpty {
                Text("No guides to remove.")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Button("Select All") {
                        selectedGuideIDs = Set(numberedGuides.map(\.id))
                    }
                    .disabled(selectedGuideIDs.count == numberedGuides.count)

                    Button("Clear Selection") {
                        selectedGuideIDs.removeAll()
                    }
                    .disabled(selectedGuideIDs.isEmpty)

                    Spacer()

                    Button("Remove All Guides", role: .destructive) {
                        guideStore.clear()
                        selectedGuideIDs.removeAll()
                    }
                }

                ForEach(numberedGuides) { guide in
                    Toggle(isOn: selectionBinding(for: guide.id)) {
                        HStack(spacing: 10) {
                            Text(guide.name)
                                .font(.system(.body, design: .monospaced).weight(.semibold))
                                .frame(width: 34, alignment: .leading)
                            Text(guide.displayName)
                            Spacer()
                            Text(guide.positionLabel)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }

                Button("Remove Selected Guides", role: .destructive) {
                    guideStore.remove(ids: selectedGuideIDs)
                    selectedGuideIDs.removeAll()
                }
                .disabled(selectedGuideIDs.isEmpty)
            }
        } header: {
            Text("Remove Guides")
        } footer: {
            Text("Select one or more guide numbers, then remove only those guides.")
        }
        .onReceive(guideStore.$guides) { guides in
            selectedGuideIDs.formIntersection(Set(guides.map(\.id)))
        }
    }

    private func selectionBinding(for id: UUID) -> Binding<Bool> {
        Binding {
            selectedGuideIDs.contains(id)
        } set: { isSelected in
            if isSelected {
                selectedGuideIDs.insert(id)
            } else {
                selectedGuideIDs.remove(id)
            }
        }
    }
}
