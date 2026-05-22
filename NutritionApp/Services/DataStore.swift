import Foundation

/// Local persistence with iCloud Key-Value Store and CloudKit private database.
final class DataStore: @unchecked Sendable {
    static let shared = DataStore()

    private let defaults = UserDefaults.standard
    private let cloud = NSUbiquitousKeyValueStore.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cloudDidChangeExternally),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )
        cloud.synchronize()
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        if let data = cloud.data(forKey: key) ?? defaults.data(forKey: key) {
            return try? decoder.decode(T.self, from: data)
        }
        return nil
    }

    func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
        cloud.set(data, forKey: key)
        cloud.synchronize()
        Task {
            await self.saveToCloudKit(value, key: key)
        }
    }

    func remove(key: String) {
        defaults.removeObject(forKey: key)
        cloud.removeObject(forKey: key)
        cloud.synchronize()
    }

    /// Pulls latest records from CloudKit into local storage.
    func syncFromCloudKit() async {
        guard await CloudKitDataStore.shared.isAccountAvailable() else { return }
        await syncKey(UserProfile.self, key: PersistenceKeys.userProfile)
        await syncKey(AppSettings.self, key: PersistenceKeys.appSettings)
        await syncKey([SessionRecord].self, key: PersistenceKeys.sessionHistory)
        await syncKey(SnackLibraryState.self, key: PersistenceKeys.snackLibraryState)
        await MainActor.run {
            NotificationCenter.default.post(name: .dataStoreDidSyncFromCloud, object: nil)
        }
    }

    private func syncKey<T: Codable>(_ type: T.Type, key: String) async {
        guard let value = await CloudKitDataStore.shared.load(type, key: key),
              let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
        cloud.set(data, forKey: key)
        cloud.synchronize()
    }

    private func saveToCloudKit<T: Encodable>(_ value: T, key: String) async {
        guard await CloudKitDataStore.shared.isAccountAvailable() else { return }
        try? await CloudKitDataStore.shared.save(value, key: key)
    }

    @objc private func cloudDidChangeExternally(_ notification: Notification) {
        NotificationCenter.default.post(name: .dataStoreDidSyncFromCloud, object: nil)
    }
}

extension Notification.Name {
    static let dataStoreDidSyncFromCloud = Notification.Name("fuelzone.dataStoreDidSyncFromCloud")
}
