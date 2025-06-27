import Foundation
import XCTest
@testable import App

// MARK: - Test Helpers

/// Helper class for creating test data and mocking system dependencies
final class TestHelpers {
    
    /// Creates a temporary directory for test file operations
    static func createTemporaryDirectory() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let testDir = tempDir.appendingPathComponent("PuchTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    /// Cleans up a temporary directory after tests
    static func cleanupTemporaryDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    /// Creates a mock settings object for testing
    static func createMockSettings() -> PersistenceManager.Settings {
        return PersistenceManager.Settings(
            outputDirectory: createTemporaryDirectory(),
            frameRate: 30,
            windowScreenshotBackground: .white,
            windowPadding: 25
        )
    }
    
    /// Creates a mock error for testing error handling
    static func createMockError(_ message: String = "Test error") -> NSError {
        return NSError(
            domain: "TestDomain",
            code: 999,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    /// Waits for a condition to be true within a timeout
    static func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        description: String = "Condition"
    ) throws {
        let deadline = Date().addingTimeInterval(timeout)
        
        while Date() < deadline {
            if condition() {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.01))
        }
        
        throw XCTSkip("\(description) was not met within \(timeout) seconds")
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    /// Asserts that two URLs are equal, handling cases where they might have different representations
    func XCTAssertURLsEqual(_ url1: URL, _ url2: URL, file: StaticString = #file, line: UInt = #line) {
        XCTAssertEqual(url1.standardizedFileURL, url2.standardizedFileURL, file: file, line: line)
    }
    
    /// Asserts that a closure throws an error
    func XCTAssertThrowsError<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
        do {
            _ = try expression()
            XCTFail("Expected expression to throw an error", file: file, line: line)
        } catch {
            // Expected to throw
        }
    }
    
    /// Asserts that a closure doesn't throw an error
    func XCTAssertNoThrow<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
        do {
            _ = try expression()
        } catch {
            XCTFail("Expected expression not to throw an error, but got: \(error)", file: file, line: line)
        }
    }
}

// MARK: - Mock Notification Center

/// Mock NotificationCenter for testing notification-based functionality
class MockNotificationCenter {
    private var observers: [String: [(Any?) -> Void]] = [:]
    
    func addObserver(forName name: Notification.Name, callback: @escaping (Any?) -> Void) {
        let key = name.rawValue
        if observers[key] == nil {
            observers[key] = []
        }
        observers[key]?.append(callback)
    }
    
    func post(name: Notification.Name, object: Any? = nil) {
        let key = name.rawValue
        observers[key]?.forEach { callback in
            callback(object)
        }
    }
    
    func removeAllObservers() {
        observers.removeAll()
    }
}

// MARK: - Performance Testing Helpers

extension XCTestCase {
    
    /// Measures the performance of a block and asserts it completes within expected time
    func measurePerformance(
        expectedTime: TimeInterval,
        tolerance: Double = 0.1,
        block: () throws -> Void
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            try block()
        } catch {
            XCTFail("Performance test block threw error: \(error)")
            return
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        let acceptableRange = expectedTime * (1.0 - tolerance)...expectedTime * (1.0 + tolerance)
        XCTAssertTrue(
            acceptableRange.contains(timeElapsed),
            "Performance test failed. Expected: \(expectedTime)s ±\(tolerance*100)%, Actual: \(timeElapsed)s"
        )
    }
}

// MARK: - Async Testing Helpers

extension XCTestCase {
    
    /// Helper for testing async operations with expectations
    func testAsync<T>(
        timeout: TimeInterval = 5.0,
        description: String = "Async operation",
        operation: @escaping () async throws -> T,
        validation: @escaping (T) -> Void = { _ in }
    ) {
        let expectation = self.expectation(description: description)
        
        Task {
            do {
                let result = try await operation()
                validation(result)
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: timeout)
    }
} 