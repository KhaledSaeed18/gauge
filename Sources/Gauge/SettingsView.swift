import SwiftUI
import ServiceManagement

private enum SettingsSection: String, CaseIterable, Identifiable {
    case appearance, guides, measure, crosshair, startup, about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: return "Appearance"
        case .guides: return "Guides"
        case .measure: return "Measure"
        case .crosshair: return "Crosshair"
        case .startup: return "Startup"
        case .about: return "About"
        }
    }

    var symbol: String {
        switch self {
        case .appearance: return "paintpalette"
        case .guides: return "scope"
        case .measure: return "ruler"
        case .crosshair: return "plus.viewfinder"
        case .startup: return "power"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var overlayManager: OverlayManager
    @StateObject private var settings = RulerSettings.shared
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?
    @State private var showingResetConfirmation = false
    @State private var selection: SettingsSection? = .appearance

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(SettingsSection.allCases) { section in
                        Label(section.title, systemImage: section.symbol)
                            .tag(section)
                    }
                }
                .listStyle(.sidebar)
                .frame(width: 200)

                Divider()

                detail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()
            HStack {
                Button("Reset Settings...", role: .destructive) { showingResetConfirmation = true }
                Spacer()
                Toggle("Show setting descriptions", isOn: $settings.showSettingDescriptions)
                    .toggleStyle(.checkbox)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 720, height: 540)
        .onAppear { launchAtLogin = SMAppService.mainApp.status == .enabled }
        .onChange(of: settings.thickness) { _, _ in overlayManager.rebuild() }
        .confirmationDialog(
            "Reset Gauge settings?",
            isPresented: $showingResetConfirmation
        ) {
            Button("Reset Settings", role: .destructive) { resetSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This restores ruler appearance, guide numbering, measure, and startup behavior. Existing guide lines and measurements are kept.")
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection ?? .appearance {
        case .appearance: appearanceTab
        case .guides: guidesTab
        case .measure: measureTab
        case .crosshair: crosshairTab
        case .startup: startupTab
        case .about: aboutTab
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
                settingHint("Changes how wide the top and left ruler bands appear on screen.")

                Slider(value: $settings.opacity, in: 0.08...0.65, step: 0.02) {
                    Text("Background opacity")
                }
                settingHint("Adjusts the translucent ruler background without changing tick or guide strength.")

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
                settingHint("Applies to vertical guide lines, V badges, and the top ruler used to place them.")

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
                settingHint("Applies to horizontal guide lines, H badges, and the left ruler used to place them.")
            } header: {
                Text("Appearance")
            } footer: {
                Text("Tune how the overlay reads against different apps, screenshots, and browser pages.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var guidesTab: some View {
        Form {
            Section {
                Picker("Tick label interval", selection: $settings.unitStep) {
                    Text("100 px").tag(100)
                    Text("200 px").tag(200)
                    Text("500 px").tag(500)
                }
                settingHint("Controls how often pixel numbers appear on the rulers. Tick marks still stay dense.")

                Toggle("Number guide lines", isOn: $settings.showGuideNumbers)
                settingHint("Shows V and H badges beside placed guides, numbered automatically by position.")
            } header: {
                Text("Guides")
            } footer: {
                Text("Use Guide Placement from the menu bar, then click or drag on a ruler to add alignment guides.")
            }

            GuideAddSection(guideStore: overlayManager.guideStore)
            GuideRemovalSection(guideStore: overlayManager.guideStore)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var measureTab: some View {
        Form {
            Section {
                LabeledContent("Start measuring", value: "⌃⌥⌘M")
                settingHint("Click and drag anywhere on screen to measure any region in physical pixels. Hold Option while dragging to measure a straight line with its length and angle.")

                Toggle("Copy dimensions after measuring", isOn: $settings.copyOnMeasure)
                settingHint("When you finish drawing a measurement, it is copied to the clipboard automatically.")

                Picker("Copy format", selection: $settings.measurementCopyFormat) {
                    ForEach(MeasurementFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                settingHint("Clipboard format for measurements (⌘C and auto-copy). Example: \(settings.measurementCopyFormat.example)")

                Toggle("Show dimension labels", isOn: $settings.showMeasurementLabels)
                settingHint("Shows width and height badges on measurements left on screen. Turn off for a cleaner look; the box you are actively drawing always shows them.")

                Toggle("Show position", isOn: $settings.showMeasurementPosition)
                settingHint("Adds an x, y badge at each measurement's top-left corner so you can see where it sits, not just how big it is.")

                Toggle("Show aspect ratio", isOn: $settings.showMeasurementAspectRatio)
                settingHint("Adds a simplified ratio badge (for example 8:5) at the center of each measurement.")

                Picker("Measurement color", selection: $settings.measurementTint) {
                    ForEach(RulerTint.allCases) { tint in
                        Label {
                            Text(tint.rawValue)
                        } icon: {
                            TintSwatch(tint: tint)
                        }
                        .tag(tint)
                    }
                }
                settingHint("Color of the measurement boxes, corner marks, and dimension badges.")
            } header: {
                Text("Measure Distance")
            } footer: {
                Text("Each box you draw stays on screen until you clear it. In a session: click a held box to remove just that one, ⌘C copies the last measurement, Delete removes it, and Esc exits. Use Clear Measurements in the menu bar to remove every held box.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var crosshairTab: some View {
        Form {
            Section {
                LabeledContent("Toggle crosshair", value: "⌃⌥⌘C")
                settingHint("Runs full-screen lines through the pointer so you can see what lines up across the whole display.")

                Toggle("Show coordinate readout", isOn: $settings.showCrosshairReadout)
                settingHint("Displays the live x, y pixel position beside the pointer while the crosshair is active.")

                Picker("Crosshair color", selection: $settings.crosshairTint) {
                    ForEach(RulerTint.allCases) { tint in
                        Label {
                            Text(tint.rawValue)
                        } icon: {
                            TintSwatch(tint: tint)
                        }
                        .tag(tint)
                    }
                }
                settingHint("Color of the full-screen crosshair lines.")
            } header: {
                Text("Crosshair")
            } footer: {
                Text("Move the pointer to align the crosshair with any element edge. Press Esc or toggle it off from the menu bar when you are done.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var startupTab: some View {
        Form {
            Section {
                Toggle("Start Gauge at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in setLaunchAtLogin(enabled) }
                settingHint("Opens Gauge in the menu bar when you sign in to macOS.")

                Toggle("Show rulers when Gauge starts", isOn: $settings.showRulersOnLaunch)
                settingHint("Shows the overlay immediately when Gauge opens. Turn off to start hidden.")

                LabeledContent("Global shortcut", value: "⌃⌥⌘R")
                settingHint("Toggles ruler visibility from anywhere, even when another app is active.")

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

    @ViewBuilder
    private func settingHint(_ text: String) -> some View {
        if settings.showSettingDescriptions {
            SettingHint(text)
        }
    }
}

private struct SettingHint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
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

private struct GuideAddSection: View {
    @ObservedObject var guideStore: GuideStore
    @State private var orientation: GuideOrientation = .vertical
    @State private var displayID: UInt32 = 0
    @State private var position: Int = 100

    private var displays: [(id: UInt32, name: String)] {
        NSScreen.screens.enumerated().map { index, screen in
            (screen.gaugeDisplayID, screen.localizedName.isEmpty ? "Display \(index + 1)" : screen.localizedName)
        }
    }

    private var resolvedDisplayID: UInt32 {
        displays.contains { $0.id == displayID } ? displayID : (displays.first?.id ?? 0)
    }

    var body: some View {
        Section {
            Picker("Orientation", selection: $orientation) {
                Text("Vertical").tag(GuideOrientation.vertical)
                Text("Horizontal").tag(GuideOrientation.horizontal)
            }

            if displays.count > 1 {
                Picker("Display", selection: $displayID) {
                    ForEach(displays, id: \.id) { display in
                        Text(display.name).tag(display.id)
                    }
                }
            }

            HStack {
                Text("Position")
                Spacer()
                TextField("px", value: $position, format: .number)
                    .labelsHidden()
                    .frame(width: 64)
                    .multilineTextAlignment(.trailing)
                Stepper("", value: $position, in: 0...100_000)
                    .labelsHidden()
                Text("px").foregroundStyle(.secondary)
            }

            Button("Add Guide") {
                guideStore.add(orientation: orientation, positionPixels: max(0, position), displayID: resolvedDisplayID)
            }
        } header: {
            Text("Add Guide")
        } footer: {
            Text("Place a guide at an exact pixel position without dragging on a ruler.")
        }
        .onAppear { if displayID == 0 { displayID = displays.first?.id ?? 0 } }
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
                    HStack(spacing: 10) {
                        Toggle(isOn: selectionBinding(for: guide.id)) { EmptyView() }
                            .labelsHidden()
                            .toggleStyle(.checkbox)
                        Text(guide.name)
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                            .frame(width: 34, alignment: .leading)
                        Text(guide.displayName)
                            .lineLimit(1)
                        Spacer()
                        Stepper(value: positionBinding(for: guide.id, fallback: guide.guide.positionPixels), in: 0...100_000) {
                            Text("\(currentPosition(for: guide.id, fallback: guide.guide.positionPixels)) px")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .fixedSize()
                    }
                }

                Button("Remove Selected Guides", role: .destructive) {
                    guideStore.remove(ids: selectedGuideIDs)
                    selectedGuideIDs.removeAll()
                }
                .disabled(selectedGuideIDs.isEmpty)
            }
        } header: {
            Text("Manage Guides")
        } footer: {
            Text("Adjust a guide's exact pixel position with the stepper, or select guides and remove them.")
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

    private func currentPosition(for id: UUID, fallback: Int) -> Int {
        guideStore.guides.first { $0.id == id }?.positionPixels ?? fallback
    }

    private func positionBinding(for id: UUID, fallback: Int) -> Binding<Int> {
        Binding {
            currentPosition(for: id, fallback: fallback)
        } set: { newValue in
            guideStore.move(id: id, to: max(0, newValue))
        }
    }
}
