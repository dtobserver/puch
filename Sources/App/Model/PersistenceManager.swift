import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private init() {}

    private let defaults = UserDefaults.standard

    struct Settings: Codable {
        var outputDirectory: URL
        var frameRate: Int
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
