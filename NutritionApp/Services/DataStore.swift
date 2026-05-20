import Foundation

/// Local + iCloud Key-Value persistence (MVP sync across devices with same Apple ID).
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
    }

    func remove(key: String) {
        defaults.removeObject(forKey: key)
        cloud.removeObject(forKey: key)
        cloud.synchronize()
    }

    @objc private func cloudDidChangeExternally(_ notification: Notification) {
        NotificationCenter.default.post(name: .dataStoreDidSyncFromCloud, object: nil)
    }
}

extension Notification.Name {
    static let dataStoreDidSyncFromCloud = Notification.Name("fuelzone.dataStoreDidSyncFromCloud")
}
