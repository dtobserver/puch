import Foundation
import AVFoundation
import CoreGraphics

class PermissionManager {
    static func requestPermissions(completion: @escaping (Bool) -> Void) {
        var audioGranted = false
        let group = DispatchGroup()
        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            audioGranted = granted
            group.leave()
        }
        let screenGranted = CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
        group.notify(queue: .main) {
            completion(audioGranted && screenGranted)
        }
    }
}
