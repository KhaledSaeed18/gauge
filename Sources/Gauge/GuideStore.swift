import AppKit
import SwiftUI

enum GuideOrientation: String, Codable {
    case vertical
    case horizontal
}

struct Guide: Codable, Identifiable {
    let id: UUID
    let displayID: UInt32
    let orientation: GuideOrientation
    var positionPixels: Int
}

struct NumberedGuide: Identifiable {
    let id: UUID
    let guide: Guide
    let number: Int
    let displayName: String

    var name: String {
        switch guide.orientation {
        case .vertical:
            return "V\(number)"
        case .horizontal:
            return "H\(number)"
        }
    }

    var positionLabel: String { "\(guide.positionPixels) px" }
}

@MainActor
final class GuideStore: ObservableObject {
    static let didChangeNotification = Notification.Name("GaugeGuidesDidChange")
    @Published private(set) var guides: [Guide]
    private let storageKey = "guides"

    init() {
        let data = UserDefaults.standard.data(forKey: storageKey)
        guides = (data.flatMap { try? JSONDecoder().decode([Guide].self, from: $0) }) ?? []
    }

    @discardableResult
    func add(orientation: GuideOrientation, positionPixels: Int, displayID: UInt32) -> UUID {
        let guide = Guide(id: UUID(), displayID: displayID, orientation: orientation, positionPixels: max(0, positionPixels))
        guides.append(guide)
        persist()
        return guide.id
    }

    func move(id: UUID, to positionPixels: Int) {
        guard let index = guides.firstIndex(where: { $0.id == id }) else { return }
        guides[index].positionPixels = max(0, positionPixels)
        persist()
    }

    func clear(displayID: UInt32? = nil) {
        if let displayID {
            guides.removeAll { $0.displayID == displayID }
        } else {
            guides.removeAll()
        }
        persist()
    }

    func remove(id: UUID) {
        guides.removeAll { $0.id == id }
        persist()
    }

    func remove(ids: Set<UUID>) {
        guides.removeAll { ids.contains($0.id) }
        persist()
    }

    func guides(for displayID: UInt32) -> [Guide] { guides.filter { $0.displayID == displayID } }

    func numberedGuides() -> [NumberedGuide] {
        let displayNames = Dictionary(uniqueKeysWithValues: NSScreen.screens.enumerated().map { index, screen in
            (screen.gaugeDisplayID, screen.localizedName.isEmpty ? "Display \(index + 1)" : screen.localizedName)
        })
        let currentDisplayIDs = NSScreen.screens.map(\.gaugeDisplayID)
        let knownDisplayIDs = Array(Set(guides.map(\.displayID))).sorted()
        let displayIDs = currentDisplayIDs + knownDisplayIDs
            .filter { !currentDisplayIDs.contains($0) }

        return displayIDs.flatMap { displayID in
            let displayGuides = guides.filter { $0.displayID == displayID }
            let displayName = displayNames[displayID] ?? "Display \(displayID)"
            let verticalGuides = displayGuides
                .filter { $0.orientation == .vertical }
                .sorted { $0.positionPixels < $1.positionPixels }
            let horizontalGuides = displayGuides
                .filter { $0.orientation == .horizontal }
                .sorted { $0.positionPixels < $1.positionPixels }

            return verticalGuides.enumerated().map { index, guide in
                NumberedGuide(id: guide.id, guide: guide, number: index + 1, displayName: displayName)
            } + horizontalGuides.enumerated().map { index, guide in
                NumberedGuide(id: guide.id, guide: guide, number: index + 1, displayName: displayName)
            }
        }
    }

    private func persist() {
        UserDefaults.standard.set(try? JSONEncoder().encode(guides), forKey: storageKey)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}

extension NSScreen {
    var gaugeDisplayID: UInt32 {
        (deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
    }

    var gaugeMenuBarInset: CGFloat {
        max(0, frame.maxY - visibleFrame.maxY)
    }
}
