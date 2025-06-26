import Foundation
import SwiftUI
import Carbon

class MenuBarManager: ObservableObject {
    @Published var showingSettings = false
    @Published var showingHistory = false
    
    private var screenshotHotKey: EventHotKeyRef?
    private var recordingHotKey: EventHotKeyRef?
    
    private let screenshotHotKeyID = EventHotKeyID(signature: OSType("scsh".fourCharCodeValue), id: 1)
    private let recordingHotKeyID = EventHotKeyID(signature: OSType("scrv".fourCharCodeValue), id: 2)
    
    init() {
        setupGlobalHotkeys()
    }
    
    deinit {
        removeGlobalHotkeys()
    }
    
    func openSettings() {
        showingSettings = true
        if let url = URL(string: "puch://settings") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openHistory() {
        showingHistory = true
        if let url = URL(string: "puch://history") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func setupGlobalHotkeys() {
        // Setup global hotkeys for screenshot (Cmd+Shift+3) and recording (Cmd+Shift+5)
        let screenshotKeyCode = UInt32(kVK_ANSI_3)
        let recordingKeyCode = UInt32(kVK_ANSI_5)
        let modifiers = UInt32(cmdKey | shiftKey)
        
        RegisterEventHotKey(screenshotKeyCode, modifiers, screenshotHotKeyID, GetApplicationEventTarget(), 0, &screenshotHotKey)
        RegisterEventHotKey(recordingKeyCode, modifiers, recordingHotKeyID, GetApplicationEventTarget(), 0, &recordingHotKey)
        
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent, OSType(kEventParamDirectObject), OSType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            
            Task { @MainActor in
                MenuBarManager.handleHotKey(hotKeyID)
            }
            
            return noErr
        }, 1, &eventType, nil, nil)
    }
    
    private func removeGlobalHotkeys() {
        if let screenshotHotKey = screenshotHotKey {
            UnregisterEventHotKey(screenshotHotKey)
        }
        if let recordingHotKey = recordingHotKey {
            UnregisterEventHotKey(recordingHotKey)
        }
    }
    
    static func handleHotKey(_ hotKeyID: EventHotKeyID) {
        // This will be handled by the shared AppViewModel instance
        // We'll use notifications to communicate
        if hotKeyID.id == 1 {
            NotificationCenter.default.post(name: .takeScreenshot, object: nil)
        } else if hotKeyID.id == 2 {
            NotificationCenter.default.post(name: .toggleRecording, object: nil)
        }
    }
}

// String extension for FourCharCode conversion
extension String {
    var fourCharCodeValue: UInt32 {
        var result: UInt32 = 0
        if let data = self.data(using: .macOSRoman) {
            data.withUnsafeBytes { bytes in
                for i in 0..<min(4, bytes.count) {
                    result = result << 8 + UInt32(bytes[i])
                }
            }
        }
        return result
    }
}

// Notification names
extension Notification.Name {
    static let takeScreenshot = Notification.Name("takeScreenshot")
    static let toggleRecording = Notification.Name("toggleRecording")
} 