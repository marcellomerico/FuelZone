import CloudKit
import Foundation

/// Private CloudKit database sync for JSON-encoded app blobs.
actor CloudKitDataStore {
    static let shared = CloudKitDataStore()

    private let container = CKContainer(identifier: "iCloud.com.mmerico.FuelZone")
    private let recordType = "FuelZoneBlob"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var database: CKDatabase { container.privateCloudDatabase }

    func save<T: Encodable>(_ value: T, key: String) async throws {
        let recordID = CKRecord.ID(recordName: key)
        let record: CKRecord
        if let existing = try? await database.record(for: recordID) {
            record = existing
        } else {
            record = CKRecord(recordType: recordType, recordID: recordID)
        }
        record["payload"] = try encoder.encode(value) as CKRecordValue
        _ = try await database.save(record)
    }

    func load<T: Decodable>(_ type: T.Type, key: String) async -> T? {
        let recordID = CKRecord.ID(recordName: key)
        guard let record = try? await database.record(for: recordID),
              let data = record["payload"] as? Data else {
            return nil
        }
        return try? decoder.decode(T.self, from: data)
    }

    func isAccountAvailable() async -> Bool {
        do {
            let status = try await container.accountStatus()
            return status == .available
        } catch {
            return false
        }
    }
}
