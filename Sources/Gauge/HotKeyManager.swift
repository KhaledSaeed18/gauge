import Carbon.HIToolbox

final class HotKeyManager {
    struct Binding {
        let id: UInt32
        let keyCode: Int
        let action: () -> Void
    }

    private var hotKeyRefs: [EventHotKeyRef?] = []
    private var handlerRef: EventHandlerRef?
    private var actions: [UInt32: () -> Void] = [:]

    /// Registers one or more global hot keys, all using the ⌃⌥⌘ modifier set.
    func register(_ bindings: [Binding]) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
            Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().actions[id.id]?()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &handlerRef)

        let modifiers = UInt32(controlKey | optionKey | cmdKey)
        for binding in bindings {
            actions[binding.id] = binding.action
            var ref: EventHotKeyRef?
            let identifier = EventHotKeyID(signature: OSType(0x4755_4155), id: binding.id) // "GUAU"
            RegisterEventHotKey(UInt32(binding.keyCode), modifiers, identifier, GetEventDispatcherTarget(), 0, &ref)
            hotKeyRefs.append(ref)
        }
    }

    func unregister() {
        for ref in hotKeyRefs where ref != nil {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        if let handlerRef { RemoveEventHandler(handlerRef) }
        handlerRef = nil
        actions.removeAll()
    }
}
