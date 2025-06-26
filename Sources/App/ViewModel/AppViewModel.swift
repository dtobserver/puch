import Foundation
import Combine

class AppViewModel: ObservableObject {
    @Published var isRecording = false
    let screenManager = ScreenCaptureManager()

    func startRecording() {
        isRecording = true
        screenManager.startRecording()
    }

    func stopRecording() {
        isRecording = false
        screenManager.stopRecording()
    }

    func takeScreenshot() {
        screenManager.takeScreenshot()
    }
}
