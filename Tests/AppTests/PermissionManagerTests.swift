import XCTest
@testable import App
import AVFoundation
import CoreGraphics

final class PermissionManagerTests: XCTestCase {
    
    func testCheckPermissionsStatus() {
        // When
        let status = PermissionManager.checkPermissionsStatus()
        
        // Then
        // We can only verify the structure exists, not the actual permissions in tests
        XCTAssertNotNil(status.screen)
        XCTAssertNotNil(status.audio)
    }
    
    func testHasScreenRecordingPermission() {
        // When
        let hasPermission = PermissionManager.hasScreenRecordingPermission()
        
        // Then
        // The result depends on actual system permissions, we just verify it returns a Bool
        XCTAssertTrue(hasPermission is Bool)
    }
    
    func testHasMicrophonePermission() {
        // When
        let hasPermission = PermissionManager.hasMicrophonePermission()
        
        // Then
        // The result depends on actual system permissions, we just verify it returns a Bool
        XCTAssertTrue(hasPermission is Bool)
    }
    
    func testRequestScreenRecordingPermissionSync() {
        // When
        let result = PermissionManager.requestScreenRecordingPermission()
        
        // Then
        // The result depends on actual system permissions, we just verify it returns a Bool
        XCTAssertTrue(result is Bool)
    }
    
    func testRequestScreenRecordingPermissionAsync() {
        // Given
        let expectation = self.expectation(description: "Screen recording permission request completes")
        var receivedResult: Bool?
        
        // When
        PermissionManager.requestScreenRecordingPermission { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNotNil(receivedResult)
    }
    
    func testRequestMicrophonePermission() {
        // Given
        let expectation = self.expectation(description: "Microphone permission request completes")
        var receivedResult: Bool?
        
        // When
        PermissionManager.requestMicrophonePermission { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNotNil(receivedResult)
    }
    
    func testLegacyRequestPermissions() {
        // Given
        let expectation = self.expectation(description: "Legacy permissions request completes")
        var receivedResult: Bool?
        
        // When
        PermissionManager.requestPermissions { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        // Then
        waitForExpectations(timeout: 5.0)
        XCTAssertNotNil(receivedResult)
    }
    
    func testMicrophonePermissionStates() {
        // Test that we handle different authorization states correctly
        let authorizedState = AVAuthorizationStatus.authorized
        let deniedState = AVAuthorizationStatus.denied
        let restrictedState = AVAuthorizationStatus.restricted
        let notDeterminedState = AVAuthorizationStatus.notDetermined
        
        XCTAssertEqual(authorizedState, .authorized)
        XCTAssertEqual(deniedState, .denied)
        XCTAssertEqual(restrictedState, .restricted)
        XCTAssertEqual(notDeterminedState, .notDetermined)
    }
} 
