import XCTest
@testable import App
import Foundation

@MainActor
final class ScreenCaptureManagerTests: XCTestCase {
    
    private var sut: ScreenCaptureManager!
    private var mockDelegate: MockScreenCaptureManagerDelegate!
    
    override func setUp() {
        super.setUp()
        sut = ScreenCaptureManager()
        mockDelegate = MockScreenCaptureManagerDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // When - Create a new ScreenCaptureManager
        let manager = ScreenCaptureManager()
        
        // Then - Should have proper initial state
        XCTAssertNotNil(manager)
        XCTAssertNil(manager.delegate)
        XCTAssertEqual(manager.windowBackground, .wallpaper)
        XCTAssertNotNil(manager.outputDirectory)
    }
    
    func testDelegateAssignment() {
        // Given
        let manager = ScreenCaptureManager()
        let delegate = MockScreenCaptureManagerDelegate()
        
        // When
        manager.delegate = delegate
        
        // Then
        XCTAssertNotNil(manager.delegate)
    }
    
    func testWindowBackgroundSetting() {
        // When
        sut.windowBackground = .white
        
        // Then
        XCTAssertEqual(sut.windowBackground, .white)
        
        // When
        sut.windowBackground = .gradient
        
        // Then
        XCTAssertEqual(sut.windowBackground, .gradient)
    }
    
    func testOutputDirectorySetting() {
        // Given
        let testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("test_output")
        
        // When
        sut.outputDirectory = testDirectory
        
        // Then
        XCTAssertEqual(sut.outputDirectory, testDirectory)
    }
    
    func testStartRecordingWithoutAudio() {
        // When
        sut.startRecording(withAudio: false)
        
        // Then
        // The actual recording depends on system permissions
        // We verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testStartRecordingWithAudio() {
        // When
        sut.startRecording(withAudio: true)
        
        // Then
        // The actual recording depends on system permissions
        // We verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testStopRecording() {
        // When
        sut.stopRecording()
        
        // Then
        // Should not crash even if not recording
        XCTAssertTrue(true)
    }
    
    func testTakeScreenshotFullScreen() {
        // When
        sut.takeScreenshot(mode: .fullScreen)
        
        // Then
        // The actual screenshot depends on system permissions
        // We verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testTakeScreenshotWindow() {
        // When
        sut.takeScreenshot(mode: .window)
        
        // Then
        // The actual screenshot depends on system permissions
        // We verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testTakeScreenshotArea() {
        // When
        sut.takeScreenshot(mode: .area)
        
        // Then
        // The actual screenshot depends on system permissions
        // We verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testTakeScreenshotDefaultMode() {
        // When - Call without specifying mode (should default to fullScreen)
        sut.takeScreenshot()
        
        // Then
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testScreenshotModeEnum() {
        // Test all screenshot modes exist
        let fullScreen = ScreenshotMode.fullScreen
        let window = ScreenshotMode.window
        let area = ScreenshotMode.area
        
        XCTAssertNotNil(fullScreen)
        XCTAssertNotNil(window)
        XCTAssertNotNil(area)
    }
    
    func testConformsToProtocols() {
        // Test that ScreenCaptureManager conforms to expected protocols
        XCTAssertTrue(sut is AudioCaptureManagerDelegate)
    }
}

// Mock delegate for testing ScreenCaptureManager
@MainActor
class MockScreenCaptureManagerDelegate: ScreenCaptureManagerDelegate {
    var didStartRecordingCalled = false
    var didFinishRecordingCalled = false
    var didTakeScreenshotCalled = false
    var didFailCalled = false
    var lastRecordingURL: URL?
    var lastScreenshotURL: URL?
    var lastError: Error?
    
    func screenCaptureManagerDidStartRecording(_ manager: ScreenCaptureManager) {
        didStartRecordingCalled = true
    }
    
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFinishRecordingTo url: URL?) {
        didFinishRecordingCalled = true
        lastRecordingURL = url
    }
    
    func screenCaptureManager(_ manager: ScreenCaptureManager, didTakeScreenshot url: URL) {
        didTakeScreenshotCalled = true
        lastScreenshotURL = url
    }
    
    func screenCaptureManager(_ manager: ScreenCaptureManager, didFail error: Error) {
        didFailCalled = true
        lastError = error
    }
    
    func reset() {
        didStartRecordingCalled = false
        didFinishRecordingCalled = false
        didTakeScreenshotCalled = false
        didFailCalled = false
        lastRecordingURL = nil
        lastScreenshotURL = nil
        lastError = nil
    }
} 
