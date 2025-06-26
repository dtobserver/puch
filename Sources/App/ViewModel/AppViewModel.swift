import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var lastRecordingURL: URL?
    @Published var lastScreenshotURL: URL?

    let screenManager = ScreenCaptureManager()

    init() {
        screenManager.delegate = self
    }

    func startRecording() {
        screenManager.startRecording()
    }

    func stopRecording() {
        screenManager.stopRecording()
    }

    func takeScreenshot() {
        screenManager.takeScreenshot()
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
