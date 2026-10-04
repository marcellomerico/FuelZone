import Foundation
import os

/// Local source of truth: one JSON file per data set in Application Support.
nonisolated struct FileStore: Sendable {
    enum File: String, CaseIterable, Sendable {
        case profile = "profile.json"
        case settings = "settings.json"
        case history = "history.json"
        case library = "snack-library.json"
        case tombstones = "tombstones.json"
    }

    let directory: URL
    private static let logger = Logger(subsystem: "com.mmerico.FuelZone", category: "FileStore")

    static func applicationSupport() -> FileStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return FileStore(directory: base.appendingPathComponent("FuelZone", isDirectory: true))
    }

    func url(for file: File) -> URL {
        directory.appendingPathComponent(file.rawValue)
    }

    func exists(_ file: File) -> Bool {
        FileManager.default.fileExists(atPath: url(for: file).path)
    }

    func load<T: Decodable>(_ type: T.Type, from file: File) -> T? {
        let fileURL = url(for: file)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder.fuelZone.decode(T.self, from: data)
        } catch {
            Self.logger.error("Failed to load \(file.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func save<T: Encodable>(_ value: T, to file: File) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder.fuelZone.encode(value)
            try data.write(to: url(for: file), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            Self.logger.error("Failed to save \(file.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}

extension JSONEncoder {
    nonisolated static var fuelZone: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .deferredToDate
        return encoder
    }
}

extension JSONDecoder {
    nonisolated static var fuelZone: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .deferredToDate
        return decoder
    }
}

/// One-time import of data written by versions that stored JSON blobs in UserDefaults / iCloud KVS.
nonisolated enum LegacyStoreMigration {
    static let migratedFlag = "fuelzone.migratedToFileStore.v1"
    static let legacyKeys: [FileStore.File: String] = [
        .profile: "fuelzone.userProfile",
        .settings: "fuelzone.appSettings",
        .history: "fuelzone.sessionHistory",
        .library: "fuelzone.snackLibraryState",
    ]

    static func migrateIfNeeded(into store: FileStore, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: migratedFlag) else { return }
        for (file, key) in legacyKeys where !store.exists(file) {
            guard let data = defaults.data(forKey: key) else { continue }
            do {
                try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
                try data.write(to: store.url(for: file), options: .atomic)
            } catch {
                Logger(subsystem: "com.mmerico.FuelZone", category: "Migration")
                    .error("Legacy migration failed for \(key, privacy: .public)")
                return
            }
        }
        defaults.set(true, forKey: migratedFlag)
    }
}
