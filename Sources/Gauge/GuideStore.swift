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

    func guides(for displayID: UInt32) -> [Guide] { guides.filter { $0.displayID == displayID } }

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
