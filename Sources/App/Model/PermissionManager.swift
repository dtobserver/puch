import Foundation
import AVFoundation
import CoreGraphics

class PermissionManager {
    static func requestPermissions(completion: @escaping @Sendable (Bool) -> Void) {
        // Check screen recording permission first
        let screenGranted = CGPreflightScreenCaptureAccess()
        
        if screenGranted {
            // Screen permission already granted, check audio
            checkAudioPermission { audioGranted in
                DispatchQueue.main.async {
                    completion(audioGranted)
                }
            }
        } else {
            // Need to request screen permission
            let screenPermissionGranted = CGRequestScreenCaptureAccess()
            if screenPermissionGranted {
                checkAudioPermission { audioGranted in
                    DispatchQueue.main.async {
                        completion(audioGranted)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private static func checkAudioPermission(completion: @escaping @Sendable (Bool) -> Void) {
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
}
