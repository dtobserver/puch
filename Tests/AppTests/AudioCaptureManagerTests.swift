import XCTest
@testable import App
import AVFoundation

final class AudioCaptureManagerTests: XCTestCase {
    
    private var sut: AudioCaptureManager!
    private var mockDelegate: MockAudioCaptureManagerDelegate!
    
    override func setUp() {
        super.setUp()
        sut = AudioCaptureManager()
        mockDelegate = MockAudioCaptureManagerDelegate()
        sut.delegate = mockDelegate
    }
    
    override func tearDown() {
        sut.stopCapturing()
        sut = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialState() {
        // When - Create a new AudioCaptureManager
        let manager = AudioCaptureManager()
        
        // Then - Should not crash and should have proper initial state
        XCTAssertNotNil(manager)
        XCTAssertNil(manager.delegate)
    }
    
    func testDelegateAssignment() {
        // Given
        let manager = AudioCaptureManager()
        let delegate = MockAudioCaptureManagerDelegate()
        
        // When
        manager.delegate = delegate
        
        // Then
        XCTAssertNotNil(manager.delegate)
    }
    
    func testStartCapturing() {
        // When
        sut.startCapturing()
        
        // Then
        // We can't easily test the actual capturing without system permissions
        // But we can verify the method doesn't crash
        XCTAssertTrue(true)
    }
    
    func testStopCapturing() {
        // Given
        sut.startCapturing()
        
        // When
        sut.stopCapturing()
        
        // Then
        // Should not crash
        XCTAssertTrue(true)
    }
    
    func testStopCapturingWithoutStarting() {
        // When - Stop capturing without starting
        sut.stopCapturing()
        
        // Then - Should not crash
        XCTAssertTrue(true)
    }
    
    func testMultipleStartStopCycles() {
        // When/Then - Multiple start/stop cycles should not crash
        for _ in 0..<3 {
            sut.startCapturing()
            sut.stopCapturing()
        }
        
        XCTAssertTrue(true)
    }
    
    func testCaptureOutputProtocol() {
        // Test that AudioCaptureManager conforms to AVCaptureAudioDataOutputSampleBufferDelegate
        XCTAssertTrue(sut is AVCaptureAudioDataOutputSampleBufferDelegate)
    }
}

// Mock delegate for testing
class MockAudioCaptureManagerDelegate: AudioCaptureManagerDelegate {
    var didOutputCalled = false
    var didFailCalled = false
    var lastSampleBuffer: CMSampleBuffer?
    var lastError: Error?
    
    func audioCaptureManager(_ manager: AudioCaptureManager, didOutput sampleBuffer: CMSampleBuffer) {
        didOutputCalled = true
        lastSampleBuffer = sampleBuffer
    }
    
    func audioCaptureManager(_ manager: AudioCaptureManager, didFail error: Error) {
        didFailCalled = true
        lastError = error
    }
    
    func reset() {
        didOutputCalled = false
        didFailCalled = false
        lastSampleBuffer = nil
        lastError = nil
    }
} 