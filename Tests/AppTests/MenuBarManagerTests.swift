import XCTest
@testable import App
import Foundation

@MainActor
final class MenuBarManagerTests: XCTestCase {
    
    private var sut: MenuBarManager!
    private var notificationCenter: NotificationCenter!
    
    override func setUp() {
        super.setUp()
        notificationCenter = NotificationCenter()
        sut = MenuBarManager()
    }
    
    override func tearDown() {
        sut = nil
        notificationCenter = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // Then
        XCTAssertFalse(sut.showingSettings)
        XCTAssertFalse(sut.showingHistory)
    }
    
    func testOpenSettings() {
        // When
        sut.openSettings()
        
        // Then
        XCTAssertTrue(sut.showingSettings)
    }
    
    func testOpenHistory() {
        // When
        sut.openHistory()
        
        // Then
        XCTAssertTrue(sut.showingHistory)
    }
    
    func testStringFourCharCodeExtension() {
        // Given
        let testString = "test"
        
        // When
        let fourCharCode = testString.fourCharCodeValue
        
        // Then
        XCTAssertNotEqual(fourCharCode, 0)
        XCTAssertTrue(fourCharCode is UInt32)
    }
    
    func testFourCharCodeDifferentStrings() {
        // Given
        let string1 = "scsh"
        let string2 = "scrv"
        
        // When
        let code1 = string1.fourCharCodeValue
        let code2 = string2.fourCharCodeValue
        
        // Then
        XCTAssertNotEqual(code1, code2)
    }
    
    func testNotificationNames() {
        // Test that notification names are properly defined
        let screenshotNotification = Notification.Name.takeScreenshot
        let recordingNotification = Notification.Name.toggleRecording
        
        XCTAssertEqual(screenshotNotification.rawValue, "takeScreenshot")
        XCTAssertEqual(recordingNotification.rawValue, "toggleRecording")
    }
    
    func testHotKeyHandling() {
        // Test the static hotkey handling method
        var screenshotNotificationReceived = false
        var recordingNotificationReceived = false
        
        let observer1 = NotificationCenter.default.addObserver(
            forName: .takeScreenshot,
            object: nil,
            queue: .main
        ) { _ in
            screenshotNotificationReceived = true
        }
        
        let observer2 = NotificationCenter.default.addObserver(
            forName: .toggleRecording,
            object: nil,
            queue: .main
        ) { _ in
            recordingNotificationReceived = true
        }
        
        defer {
            NotificationCenter.default.removeObserver(observer1)
            NotificationCenter.default.removeObserver(observer2)
        }
        
        // When - Test screenshot hotkey (ID = 1)
        let screenshotHotKeyID = EventHotKeyID(signature: OSType("scsh".fourCharCodeValue), id: 1)
        MenuBarManager.handleHotKey(screenshotHotKeyID)
        
        // Then
        let expectation1 = expectation(description: "Screenshot notification received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(screenshotNotificationReceived)
            expectation1.fulfill()
        }
        
        // When - Test recording hotkey (ID = 2)
        let recordingHotKeyID = EventHotKeyID(signature: OSType("scrv".fourCharCodeValue), id: 2)
        MenuBarManager.handleHotKey(recordingHotKeyID)
        
        // Then
        let expectation2 = expectation(description: "Recording notification received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(recordingNotificationReceived)
            expectation2.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testInvalidHotKeyHandling() {
        // Test handling of invalid hotkey ID
        var notificationReceived = false
        
        let observer = NotificationCenter.default.addObserver(
            forName: .takeScreenshot,
            object: nil,
            queue: .main
        ) { _ in
            notificationReceived = true
        }
        
        defer {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // When - Test invalid hotkey (ID = 999)
        let invalidHotKeyID = EventHotKeyID(signature: OSType("test".fourCharCodeValue), id: 999)
        MenuBarManager.handleHotKey(invalidHotKeyID)
        
        // Then - Should not trigger any notification
        let expectation = expectation(description: "Wait for potential notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(notificationReceived)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testShowingSettingsToggle() {
        // Given
        XCTAssertFalse(sut.showingSettings)
        
        // When
        sut.showingSettings = true
        
        // Then
        XCTAssertTrue(sut.showingSettings)
        
        // When
        sut.showingSettings = false
        
        // Then
        XCTAssertFalse(sut.showingSettings)
    }
    
    func testShowingHistoryToggle() {
        // Given
        XCTAssertFalse(sut.showingHistory)
        
        // When
        sut.showingHistory = true
        
        // Then
        XCTAssertTrue(sut.showingHistory)
        
        // When
        sut.showingHistory = false
        
        // Then
        XCTAssertFalse(sut.showingHistory)
    }
} 
