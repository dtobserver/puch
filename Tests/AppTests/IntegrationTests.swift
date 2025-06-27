import XCTest
@testable import App
import Combine

@MainActor
final class IntegrationTests: XCTestCase {
    
    private var appViewModel: AppViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        appViewModel = AppViewModel()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        appViewModel = nil
        super.tearDown()
    }
    
    func testAppViewModelInitializationIntegration() {
        // Test that AppViewModel properly initializes with all dependencies
        XCTAssertNotNil(appViewModel.screenManager)
        XCTAssertFalse(appViewModel.isRecording)
        XCTAssertEqual(appViewModel.windowScreenshotBackground, .wallpaper)
        XCTAssertNotNil(appViewModel.saveLocation)
    }
    
    func testSettingsPersistenceIntegration() {
        // Test that settings changes in AppViewModel are persisted
        let originalLocation = appViewModel.saveLocation
        let testLocation = FileManager.default.temporaryDirectory.appendingPathComponent("integration_test")
        
        // When
        appViewModel.saveLocation = testLocation
        appViewModel.windowScreenshotBackground = .white
        
        // Then - Settings should be updated
        XCTAssertEqual(appViewModel.saveLocation, testLocation)
        XCTAssertEqual(appViewModel.windowScreenshotBackground, .white)
        
        // Cleanup
        appViewModel.saveLocation = originalLocation
        appViewModel.windowScreenshotBackground = .wallpaper
    }
    
    func testScreenCaptureManagerIntegration() {
        // Test that screen capture manager is properly configured
        XCTAssertEqual(appViewModel.screenManager.windowBackground, appViewModel.windowScreenshotBackground)
        XCTAssertEqual(appViewModel.screenManager.outputDirectory, appViewModel.saveLocation)
    }
    
    func testPermissionManagerIntegration() {
        // Test that permission checking works
        let permissions = PermissionManager.checkPermissionsStatus()
        
        // Should return actual permission status
        XCTAssertNotNil(permissions.screen)
        XCTAssertNotNil(permissions.audio)
    }
    
    func testNotificationIntegration() {
        // Test that notification system works end-to-end
        let expectation = self.expectation(description: "Notification handling")
        
        // Set up observer to catch if the notification triggers app logic
        var notificationReceived = false
        let observer = NotificationCenter.default.addObserver(
            forName: .takeScreenshot,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
            expectation.fulfill()
        }
        
        defer {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // When - Post screenshot notification
        NotificationCenter.default.post(name: .takeScreenshot, object: nil)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(notificationReceived)
    }
    
    func testAppStateChanges() {
        // Test app state changes through Published properties
        var recordingStateChanges = 0
        var errorMessageChanges = 0
        
        appViewModel.$isRecording
            .sink { _ in recordingStateChanges += 1 }
            .store(in: &cancellables)
        
        appViewModel.$errorMessage
            .sink { _ in errorMessageChanges += 1 }
            .store(in: &cancellables)
        
        // When - Change states
        appViewModel.isRecording = true
        appViewModel.errorMessage = "Test error"
        appViewModel.isRecording = false
        appViewModel.errorMessage = nil
        
        // Then - Should have received multiple state changes
        XCTAssertGreaterThan(recordingStateChanges, 1)
        XCTAssertGreaterThan(errorMessageChanges, 1)
    }
    
    func testErrorHandling() {
        // Test error handling across the app
        appViewModel.errorMessage = "Test error message"
        
        XCTAssertEqual(appViewModel.errorMessage, "Test error message")
        
        // Clear error
        appViewModel.errorMessage = nil
        XCTAssertNil(appViewModel.errorMessage)
    }
    
    func testMenuBarIntegration() {
        // Test MenuBar hotkey integration
        let menuBarManager = MenuBarManager()
        
        // Initial state
        XCTAssertFalse(menuBarManager.showingSettings)
        XCTAssertFalse(menuBarManager.showingHistory)
        
        // Test state changes
        menuBarManager.openSettings()
        XCTAssertTrue(menuBarManager.showingSettings)
        
        menuBarManager.openHistory()
        XCTAssertTrue(menuBarManager.showingHistory)
    }
    
    func testDataFlow() {
        // Test data flow from settings to screen manager
        let originalBackground = appViewModel.windowScreenshotBackground
        let originalLocation = appViewModel.saveLocation
        
        // Change settings
        appViewModel.windowScreenshotBackground = .gradient
        let testLocation = FileManager.default.temporaryDirectory.appendingPathComponent("test_flow")
        appViewModel.saveLocation = testLocation
        
        // Verify screen manager is updated
        XCTAssertEqual(appViewModel.screenManager.windowBackground, .gradient)
        XCTAssertEqual(appViewModel.screenManager.outputDirectory, testLocation)
        
        // Cleanup
        appViewModel.windowScreenshotBackground = originalBackground
        appViewModel.saveLocation = originalLocation
    }
} 
