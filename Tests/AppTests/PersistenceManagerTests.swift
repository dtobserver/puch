import XCTest
@testable import App
import Foundation

@MainActor
final class PersistenceManagerTests: XCTestCase {
    
    private var sut: PersistenceManager!
    private var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Use a test-specific UserDefaults suite to avoid interfering with real app data
        mockUserDefaults = UserDefaults(suiteName: "test.puch.settings")!
        mockUserDefaults.removePersistentDomain(forName: "test.puch.settings")
        sut = PersistenceManager.shared
    }
    
    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "test.puch.settings")
        mockUserDefaults = nil
        sut = nil
        super.tearDown()
    }
    
    func testDefaultSettings() {
        let defaultSettings = PersistenceManager.Settings.default
        
        XCTAssertEqual(defaultSettings.frameRate, 60)
        XCTAssertEqual(defaultSettings.windowScreenshotBackground, .wallpaper)
        XCTAssertEqual(defaultSettings.windowPadding, 50)
        XCTAssertNotNil(defaultSettings.outputDirectory)
    }
    
    func testSaveAndLoadSettings() {
        // Given
        let testURL = FileManager.default.temporaryDirectory.appendingPathComponent("test")
        let settings = PersistenceManager.Settings(
            outputDirectory: testURL,
            frameRate: 30,
            windowScreenshotBackground: .white,
            windowPadding: 100
        )
        
        // When
        sut.saveSettings(settings)
        let loadedSettings = sut.loadSettings()
        
        // Then
        XCTAssertNotNil(loadedSettings)
        XCTAssertEqual(loadedSettings?.outputDirectory, testURL)
        XCTAssertEqual(loadedSettings?.frameRate, 30)
        XCTAssertEqual(loadedSettings?.windowScreenshotBackground, .white)
        XCTAssertEqual(loadedSettings?.windowPadding, 100)
    }
    
    func testLoadSettingsWhenNoneExist() {
        // When
        let loadedSettings = sut.loadSettings()
        
        // Then
        XCTAssertNil(loadedSettings)
    }
    
    func testWindowScreenshotBackgroundCases() {
        let wallpaperCase = PersistenceManager.Settings.WindowScreenshotBackground.wallpaper
        let whiteCase = PersistenceManager.Settings.WindowScreenshotBackground.white
        let gradientCase = PersistenceManager.Settings.WindowScreenshotBackground.gradient
        
        XCTAssertEqual(wallpaperCase.rawValue, "wallpaper")
        XCTAssertEqual(whiteCase.rawValue, "white")
        XCTAssertEqual(gradientCase.rawValue, "gradient")
        
        // Test all cases are present
        XCTAssertEqual(PersistenceManager.Settings.WindowScreenshotBackground.allCases.count, 3)
    }
    
    func testSettingsEncoding() {
        // Given
        let settings = PersistenceManager.Settings.default
        
        // When
        let encoder = JSONEncoder()
        let data = try? encoder.encode(settings)
        
        // Then
        XCTAssertNotNil(data)
        
        // And decode back
        let decoder = JSONDecoder()
        let decodedSettings = try? decoder.decode(PersistenceManager.Settings.self, from: data!)
        
        XCTAssertNotNil(decodedSettings)
        XCTAssertEqual(decodedSettings?.frameRate, settings.frameRate)
        XCTAssertEqual(decodedSettings?.windowScreenshotBackground, settings.windowScreenshotBackground)
        XCTAssertEqual(decodedSettings?.windowPadding, settings.windowPadding)
    }
} 