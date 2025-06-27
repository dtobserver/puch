import Foundation
import AVFoundation
import CoreGraphics

class PermissionManager {
    static func requestScreenRecordingPermission(completion: @escaping @Sendable (Bool) -> Void) {
        // Check screen recording permission first
        let screenGranted = CGPreflightScreenCaptureAccess()
        
        if screenGranted {
            DispatchQueue.main.async {
                completion(true)
            }
        } else {
            // Need to request screen permission
            let screenPermissionGranted = CGRequestScreenCaptureAccess()
            DispatchQueue.main.async {
                completion(screenPermissionGranted)
            }
        }
    }
    
    static func requestMicrophonePermission(completion: @escaping @Sendable (Bool) -> Void) {
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch audioStatus {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    
    // Legacy method for backwards compatibility - now only requests screen recording
    static func requestPermissions(completion: @escaping @Sendable (Bool) -> Void) {
        requestScreenRecordingPermission(completion: completion)
    }
    
    static func checkPermissionsStatus() -> (screen: Bool, audio: Bool) {
        let screenGranted = CGPreflightScreenCaptureAccess()
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let audioGranted = audioStatus == .authorized
        
        return (screen: screenGranted, audio: audioGranted)
    }
    
    static func requestScreenRecordingPermission() -> Bool {
        // First check if already granted to avoid showing dialog unnecessarily
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        
        // Only request if not already granted
        return CGRequestScreenCaptureAccess()
    }
    
    static func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    static func hasMicrophonePermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
}
