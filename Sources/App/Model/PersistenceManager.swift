import Foundation

@MainActor
final class PersistenceManager: Sendable {
    static let shared = PersistenceManager()
    private init() {}

    private let defaults = UserDefaults.standard

    struct Settings: Codable, Sendable {
        enum WindowScreenshotBackground: String, Codable, CaseIterable, Sendable {
            case desktop
            case white
            case gradient
        }

        var outputDirectory: URL
        var frameRate: Int
        var windowScreenshotBackground: WindowScreenshotBackground

        static var `default`: Settings {
            Settings(
                outputDirectory: FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory,
                frameRate: 60,
                windowScreenshotBackground: .desktop
            )
        }
    }

    func saveSettings(_ settings: Settings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: "settings")
        }
    }

    func loadSettings() -> Settings? {
        guard let data = defaults.data(forKey: "settings") else { return nil }
        return try? JSONDecoder().decode(Settings.self, from: data)
    }
}
