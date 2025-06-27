import Foundation
@testable import App

@MainActor
class MockScreenCaptureManager: ScreenCaptureManager {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var takeScreenshotCalled = false
    var lastScreenshotMode: ScreenshotMode?
    var shouldFailRecording = false
    var shouldFailScreenshot = false
    var mockRecordingURL: URL?
    var mockScreenshotURL: URL?
    
    override func startRecording(withAudio: Bool = false) {
        startRecordingCalled = true
        
        if shouldFailRecording {
            delegate?.screenCaptureManager(self, didFail: NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock recording failure"]))
        } else {
            delegate?.screenCaptureManagerDidStartRecording(self)
        }
    }
    
    override func stopRecording() {
        stopRecordingCalled = true
        delegate?.screenCaptureManager(self, didFinishRecordingTo: mockRecordingURL)
    }
    
    override func takeScreenshot(mode: ScreenshotMode = .fullScreen) {
        takeScreenshotCalled = true
        lastScreenshotMode = mode
        
        if shouldFailScreenshot {
            delegate?.screenCaptureManager(self, didFail: NSError(domain: "MockError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock screenshot failure"]))
        } else {
            let url = mockScreenshotURL ?? FileManager.default.temporaryDirectory.appendingPathComponent("mock_screenshot.png")
            delegate?.screenCaptureManager(self, didTakeScreenshot: url)
        }
    }
    
    func reset() {
        startRecordingCalled = false
        stopRecordingCalled = false
        takeScreenshotCalled = false
        lastScreenshotMode = nil
        shouldFailRecording = false
        shouldFailScreenshot = false
        mockRecordingURL = nil
        mockScreenshotURL = nil
    }
} 
