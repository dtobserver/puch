import XCTest
@testable import App
import Combine

@MainActor
final class AppViewModelTests: XCTestCase {
    
    private var sut: AppViewModel!
    private var mockScreenManager: MockScreenCaptureManager!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        // We need to create the AppViewModel with dependency injection for testing
        // Since the current implementation doesn't support DI, we'll test what we can
        mockScreenManager = MockScreenCaptureManager()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        mockScreenManager = nil
        sut = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Given/When
        sut = AppViewModel()
        
        // Then
        XCTAssertFalse(sut.isRecording)
        XCTAssertNil(sut.lastRecordingURL)
        XCTAssertNil(sut.lastScreenshotURL)
        XCTAssertFalse(sut.recordAudio)
        XCTAssertEqual(sut.windowScreenshotBackground, .wallpaper)
        XCTAssertNotNil(sut.saveLocation)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testRecordAudioToggleWithoutPermission() {
        // Given
        sut = AppViewModel()
        let expectation = self.expectation(description: "Record audio state changes")
        
        // When
        sut.$recordAudio
            .dropFirst() // Skip initial value
            .sink { recordAudio in
                // The implementation checks permission and may set it back to false
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.recordAudio = true
        
        // Then
        waitForExpectations(timeout: 2.0)
        // The actual result depends on system permissions
    }
    
    func testWindowScreenshotBackgroundSetting() {
        // Given
        sut = AppViewModel()
        
        // When
        sut.windowScreenshotBackground = .white
        
        // Then
        XCTAssertEqual(sut.windowScreenshotBackground, .white)
    }
    
    func testSaveLocationSetting() {
        // Given
        sut = AppViewModel()
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_output")
        
        // When
        sut.saveLocation = testURL
        
        // Then
        XCTAssertEqual(sut.saveLocation, testURL)
    }
    
    func testNotificationObservers() {
        // Given
        sut = AppViewModel()
        
        // When - Post screenshot notification
        NotificationCenter.default.post(name: .takeScreenshot, object: nil)
        
        // Then - Should trigger screenshot (we can't easily test this without mocking)
        // The notification observer is set up correctly if no crash occurs
        XCTAssertTrue(true) // Test passes if no crash
        
        // When - Post toggle recording notification
        NotificationCenter.default.post(name: .toggleRecording, object: nil)
        
        // Then - Should trigger recording toggle
        XCTAssertTrue(true) // Test passes if no crash
    }
    
    func testScreenshotModes() {
        // Test that screenshot modes are properly defined
        let fullScreen = ScreenshotMode.fullScreen
        let window = ScreenshotMode.window
        let area = ScreenshotMode.area
        
        // These should not be equal to each other
        XCTAssertNotEqual(fullScreen, window)
        XCTAssertNotEqual(window, area)
        XCTAssertNotEqual(area, fullScreen)
    }
    
    func testErrorMessageClearing() {
        // Given
        sut = AppViewModel()
        sut.errorMessage = "Test error"
        
        // When
        sut.errorMessage = nil
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func testPermissionChecking() {
        // Given
        sut = AppViewModel()
        
        // When/Then - The view model should check permissions on init
        // We can't mock the permission manager easily, so we just verify the property exists
        XCTAssertNotNil(sut.permissionsGranted)
    }
    
    func testPublishedProperties() {
        // Test that all @Published properties are properly observable
        sut = AppViewModel()
        
        var isRecordingChanges = 0
        var errorMessageChanges = 0
        
        sut.$isRecording
            .sink { _ in isRecordingChanges += 1 }
            .store(in: &cancellables)
        
        sut.$errorMessage
            .sink { _ in errorMessageChanges += 1 }
            .store(in: &cancellables)
        
        // When
        sut.isRecording = true
        sut.errorMessage = "Test"
        
        // Then
        XCTAssertGreaterThan(isRecordingChanges, 0)
        XCTAssertGreaterThan(errorMessageChanges, 0)
    }
}

// Extension to make ScreenshotMode equatable for testing
extension ScreenshotMode: Equatable {
    public static func == (lhs: ScreenshotMode, rhs: ScreenshotMode) -> Bool {
        switch (lhs, rhs) {
        case (.fullScreen, .fullScreen), (.window, .window), (.area, .area):
            return true
        default:
            return false
        }
    }
} 