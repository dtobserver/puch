# Puch App Test Suite

This directory contains comprehensive unit and integration tests for the Puch screen capture application.

## Test Coverage

The test suite covers the following components:

### 1. Model Layer Tests

#### PersistenceManager Tests (`PersistenceManagerTests.swift`)
- Settings saving and loading
- Default settings validation
- JSON encoding/decoding
- Settings persistence across app launches
- WindowScreenshotBackground enum cases

#### PermissionManager Tests (`PermissionManagerTests.swift`)
- Screen recording permission requests
- Microphone permission requests
- Permission status checking
- Legacy permission method compatibility
- Async permission handling

#### ScreenCaptureManager Tests (`ScreenCaptureManagerTests.swift`)
- Screen recording start/stop functionality
- Screenshot capture in different modes (fullscreen, window, area)
- Delegate pattern implementation
- Window background settings
- Output directory configuration

#### AudioCaptureManager Tests (`AudioCaptureManagerTests.swift`)
- Audio capture start/stop functionality
- Delegate pattern implementation
- AVCaptureSession management
- Error handling

#### MenuBarManager Tests (`MenuBarManagerTests.swift`)
- Global hotkey registration
- Notification system integration
- Settings and history view management
- FourCharCode string extension

### 2. ViewModel Tests

#### AppViewModel Tests (`AppViewModelTests.swift`)
- App state management
- Published properties observability
- Settings synchronization
- Error handling
- Notification observers
- Recording and screenshot functionality

### 3. Integration Tests (`IntegrationTests.swift`)
- Component interaction testing
- End-to-end workflow validation
- Settings persistence integration
- Notification system integration
- Data flow between components

### 4. Mock Objects and Test Helpers

#### Mock Objects
- `MockScreenCaptureManager`: Simulates screen capture operations
- `MockAudioCaptureManagerDelegate`: Tests audio capture callbacks
- `MockScreenCaptureManagerDelegate`: Tests screen capture callbacks
- `MockNotificationCenter`: Tests notification handling

#### Test Helpers (`TestHelpers.swift`)
- Temporary directory management
- Mock data creation
- Async testing utilities
- Performance measurement helpers
- Custom XCTest assertions

## Running Tests

### Using Xcode
1. Open the project in Xcode
2. Select the test target
3. Press `Cmd+U` to run all tests
4. Use the Test Navigator to run specific test classes or methods

### Using Command Line
```bash
# Run all tests
swift test

# Run tests with verbose output
swift test --verbose

# Run specific test
swift test --filter PersistenceManagerTests

# Run tests with coverage
swift test --enable-code-coverage
```

### Using Swift Package Manager
```bash
# From project root
swift package test

# With parallel execution
swift package test --parallel
```

## Test Organization

### Naming Conventions
- Test files: `[ComponentName]Tests.swift`
- Test methods: `test[FunctionalityDescription]()`
- Mock objects: `Mock[ComponentName]`

### Test Structure
Each test follows the Given-When-Then pattern:
```swift
func testExample() {
    // Given - Set up test conditions
    let manager = PersistenceManager.shared
    let settings = PersistenceManager.Settings.default
    
    // When - Execute the functionality
    manager.saveSettings(settings)
    let loaded = manager.loadSettings()
    
    // Then - Verify the results
    XCTAssertNotNil(loaded)
    XCTAssertEqual(loaded?.frameRate, settings.frameRate)
}
```

## Test Configuration

### Test Target Dependencies
The test target depends on:
- XCTest framework
- The main App target
- AVFoundation (for audio/video testing)
- Combine (for reactive testing)

### System Requirements
- macOS 13.0+
- Xcode 15.0+
- Swift 6.1+

## Coverage Areas

### ✅ Fully Covered
- Settings persistence and loading
- Permission checking and requesting
- App state management
- Notification system
- Error handling
- Mock object interactions

### ⚠️ Partially Covered
- Actual screen capture operations (requires system permissions)
- Audio capture functionality (requires microphone access)
- Global hotkey registration (requires accessibility permissions)

### ❌ Not Covered
- UI interaction tests (requires UI testing framework)
- System integration tests (requires full app environment)
- Performance tests under load

## Mocking Strategy

Due to the nature of screen capture and audio functionality requiring system permissions, the test suite uses extensive mocking:

1. **MockScreenCaptureManager**: Simulates screen capture without actual recording
2. **MockAudioCaptureManagerDelegate**: Tests audio capture callbacks
3. **Test UserDefaults**: Isolated storage for settings tests
4. **Temporary Directories**: Safe file system operations

## CI/CD Integration

The tests are designed to run in CI environments:
- No system permissions required for core logic tests
- Temporary file operations are cleaned up
- No external dependencies
- Fast execution (< 30 seconds for full suite)

## Troubleshooting

### Common Issues

1. **Permission Dialogs**: Some tests may trigger system permission dialogs
   - Solution: Run tests in an environment with pre-granted permissions

2. **File System Access**: Tests create temporary files
   - Solution: Ensure test runner has file system access

3. **Async Test Timeouts**: Some async tests may timeout
   - Solution: Increase timeout values in test configuration

### Debug Tips

1. Use `print()` statements in test methods for debugging
2. Set breakpoints in both test code and app code
3. Use XCTest's `measure` blocks for performance testing
4. Check test logs for detailed failure information

## Contributing to Tests

When adding new functionality:

1. **Write tests first** (TDD approach)
2. **Cover both success and failure cases**
3. **Use descriptive test names**
4. **Follow the existing patterns**
5. **Add mock objects as needed**
6. **Update this README** if adding new test categories

### Test Quality Guidelines

- Each test should be independent and repeatable
- Tests should run quickly (< 1 second each)
- Use meaningful assertions with custom messages
- Clean up any resources created during tests
- Mock external dependencies

## Future Improvements

- [ ] Add UI tests for SwiftUI views
- [ ] Add performance benchmarks
- [ ] Add stress tests for concurrent operations
- [ ] Add integration tests with actual system permissions
- [ ] Add snapshot tests for UI components
- [ ] Add accessibility tests 
