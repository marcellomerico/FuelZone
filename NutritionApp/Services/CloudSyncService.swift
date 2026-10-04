import CloudKit
import Foundation
import os

/// Syncs `SyncEnvelope`s with the user's private CloudKit database (custom zone, one record per item).
///
/// Every sync fetches all records of the zone, merges them last-writer-wins with the local items
/// (`SyncMerge`) and uploads whatever is newer locally. The data set is small (profile, settings,
/// snack library, sessions), so a full fetch keeps the logic simple and conflict-free.
actor CloudSyncService {
    enum SyncError: Error {
        case accountUnavailable
    }

    static let containerIdentifier = "iCloud.com.mmerico.FuelZone"
    private static let recordType = "FuelZoneItem"
    private static let zoneID = CKRecordZone.ID(zoneName: "FuelZone", ownerName: CKCurrentUserDefaultName)
    private static let logger = Logger(subsystem: "com.mmerico.FuelZone", category: "CloudSync")

    private let container: CKContainer
    private var zoneReady = false

    init(containerIdentifier: String = CloudSyncService.containerIdentifier) {
        container = CKContainer(identifier: containerIdentifier)
    }

    private var database: CKDatabase { container.privateCloudDatabase }

    func isAccountAvailable() async -> Bool {
        (try? await container.accountStatus()) == .available
    }

    /// Merges `local` with the server state. Returns the remote items that must be applied locally.
    func sync(local: [SyncEnvelope]) async throws -> [SyncEnvelope] {
        guard await isAccountAvailable() else { throw SyncError.accountUnavailable }
        try await ensureZone()

        let remoteRecords = try await fetchAllRecords()
        let remote = remoteRecords.values.compactMap(Self.envelope(from:))
        let outcome = SyncMerge.merge(local: local, remote: remote)

        if !outcome.toUpload.isEmpty {
            let records = outcome.toUpload.map { envelope -> CKRecord in
                let recordID = CKRecord.ID(recordName: envelope.key, zoneID: Self.zoneID)
                let record = remoteRecords[recordID] ?? CKRecord(recordType: Self.recordType, recordID: recordID)
                record["modifiedAt"] = envelope.modifiedAt as CKRecordValue
                record["deleted"] = (envelope.isDeleted ? 1 : 0) as CKRecordValue
                record["payload"] = envelope.payload as CKRecordValue?
                return record
            }
            let (saveResults, _) = try await database.modifyRecords(
                saving: records,
                deleting: [],
                savePolicy: .changedKeys,
                atomically: false
            )
            for case let (recordID, .failure(error)) in saveResults {
                Self.logger.error("Upload failed for \(recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        return outcome.toApplyLocally
    }

    private func ensureZone() async throws {
        guard !zoneReady else { return }
        do {
            _ = try await database.save(CKRecordZone(zoneID: Self.zoneID))
        } catch let error as CKError where error.code == .serverRecordChanged {
            // Zone already exists.
        }
        zoneReady = true
    }

    private func fetchAllRecords() async throws -> [CKRecord.ID: CKRecord] {
        var records: [CKRecord.ID: CKRecord] = [:]
        var token: CKServerChangeToken?
        var moreComing = true
        while moreComing {
            let changes = try await database.recordZoneChanges(inZoneWith: Self.zoneID, since: token)
            for (recordID, result) in changes.modificationResultsByID {
                if case .success(let modification) = result {
                    records[recordID] = modification.record
                }
            }
            for deletion in changes.deletions {
                records[deletion.recordID] = nil
            }
            token = changes.changeToken
            moreComing = changes.moreComing
        }
        return records
    }

    private static func envelope(from record: CKRecord) -> SyncEnvelope? {
        guard let modifiedAt = record["modifiedAt"] as? Date else { return nil }
        let deleted = (record["deleted"] as? Int ?? 0) == 1
        return SyncEnvelope(
            key: record.recordID.recordName,
            modifiedAt: modifiedAt,
            payload: deleted ? nil : record["payload"] as? Data
        )
    }
}
