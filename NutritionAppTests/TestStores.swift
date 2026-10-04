import Foundation
@testable import NutritionApp

/// Isolated data stores for tests: temporary directory, no iCloud, private UserDefaults suite.
@MainActor
enum TestStores {
    static func make(defaults: UserDefaults? = nil) -> UserDataStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FuelZoneTests-\(UUID().uuidString)", isDirectory: true)
        return UserDataStore(
            files: FileStore(directory: directory),
            syncService: nil,
            defaults: defaults ?? freshDefaults()
        )
    }

    static func freshDefaults() -> UserDefaults {
        let name = "FuelZoneTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
