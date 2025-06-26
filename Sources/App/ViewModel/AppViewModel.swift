import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var lastScreenshotURL: URL?
    @Published var permissionsGranted = false
    @Published var recordAudio = false

    let screenManager = ScreenCaptureManager()

    init() {
        screenManager.delegate = self
    }

    func startRecording() {
        screenManager.startRecording(withAudio: recordAudio)
    }

    func stopRecording() {
        screenManager.stopRecording()
    }

    func takeScreenshot() {
        screenManager.takeScreenshot()
    }

    func requestPermissions() {
        PermissionManager.requestPermissions { [weak self] granted in
            self?.permissionsGranted = granted
        }
    }
}

extension AppViewModel: ScreenCaptureManagerDelegate {
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager) {
        isRecording = true
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?) {
        isRecording = false
        lastRecordingURL = url
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL) {
        lastScreenshotURL = url
    }

    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error) {
        isRecording = false
        print("ScreenCapture error: \(error)")
    }
}
