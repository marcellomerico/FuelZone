import Foundation

/// One synced item (profile, settings, snack library or a session) as stored in CloudKit.
nonisolated struct SyncEnvelope: Equatable, Sendable {
    /// Stable record name, e.g. `profile`, `settings`, `library`, `session.<uuid>`.
    var key: String
    var modifiedAt: Date
    /// JSON payload; `nil` for a deletion marker (tombstone).
    var payload: Data?

    var isDeleted: Bool { payload == nil }
}

/// Last-writer-wins merge between local and remote items.
nonisolated enum SyncMerge {
    struct Outcome: Equatable, Sendable {
        /// Remote items that are newer than the local copy and must be applied locally.
        var toApplyLocally: [SyncEnvelope]
        /// Local items that are newer than (or missing on) the server and must be uploaded.
        var toUpload: [SyncEnvelope]
    }

    static func merge(local: [SyncEnvelope], remote: [SyncEnvelope]) -> Outcome {
        let localByKey = Dictionary(local.map { ($0.key, $0) }, uniquingKeysWith: newer)
        let remoteByKey = Dictionary(remote.map { ($0.key, $0) }, uniquingKeysWith: newer)
        var apply: [SyncEnvelope] = []
        var upload: [SyncEnvelope] = []

        for key in Set(localByKey.keys).union(remoteByKey.keys).sorted() {
            switch (localByKey[key], remoteByKey[key]) {
            case let (l?, r?):
                if l.modifiedAt > r.modifiedAt {
                    upload.append(l)
                } else if r.modifiedAt > l.modifiedAt {
                    apply.append(r)
                }
            case let (l?, nil):
                upload.append(l)
            case let (nil, r?):
                apply.append(r)
            case (nil, nil):
                break
            }
        }
        return Outcome(toApplyLocally: apply, toUpload: upload)
    }

    private static func newer(_ a: SyncEnvelope, _ b: SyncEnvelope) -> SyncEnvelope {
        a.modifiedAt >= b.modifiedAt ? a : b
    }
}
