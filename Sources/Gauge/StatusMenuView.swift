import SwiftUI

struct StatusMenuView: View {
    @EnvironmentObject private var overlayManager: OverlayManager
    @StateObject private var settings = RulerSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "ruler")
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Gauge").font(.headline)
                    Text("Desktop pixel rulers").font(.caption).foregroundStyle(.secondary)
                }
            }
            Divider()
            Toggle("Show rulers", isOn: Binding(get: { overlayManager.isVisible }, set: { $0 ? overlayManager.show() : overlayManager.hide() }))
            Text("⌃⌥⌘R toggles anywhere").font(.caption).foregroundStyle(.secondary)
            Divider()
            Button("Settings…") { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }
            Button("Quit Gauge") { NSApp.terminate(nil) }
        }
        .padding(14)
        .frame(width: 260)
    }
}
