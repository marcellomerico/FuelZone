import Combine
import Foundation
import os

/// Single source of truth for all persisted user data (profile, settings, history, snack library).
///
/// Every mutation stamps `modifiedAt`, writes the matching JSON file and schedules an iCloud sync.
@MainActor
final class UserDataStore: ObservableObject {
    // A nonisolated deinit avoids the isolated-deinit back-deployment shim, which crashes on iOS < 26
    // (swift_task_deinitOnExecutorMainActorBackDeploy) when the object is released on the main thread.
    nonisolated deinit {}

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case unavailable
        case failed
    }

    @Published private(set) var profile: UserProfile
    @Published private(set) var settings: AppSettings
    /// All saved sessions, newest first. Never truncated; the free tier only limits what is shown.
    @Published private(set) var history: [SessionRecord]
    @Published private(set) var library: SnackLibrary
    @Published private(set) var builtInSnacks: [Snack]
    @Published private(set) var snackLoadFailed = false
    @Published private(set) var syncStatus: SyncStatus = .idle

    private let files: FileStore
    private let syncService: CloudSyncService?
    private var tombstones: [String: Date]
    private var syncTask: Task<Void, Never>?
    private static let logger = Logger(subsystem: "com.mmerico.FuelZone", category: "UserDataStore")

    init(
        files: FileStore = .applicationSupport(),
        syncService: CloudSyncService? = CloudSyncService(),
        defaults: UserDefaults = .standard
    ) {
        self.files = files
        self.syncService = syncService
        LegacyStoreMigration.migrateIfNeeded(into: files, defaults: defaults)

        let builtIns = (try? DefaultSnackLoader.loadBuiltInSnacks()) ?? []
        builtInSnacks = builtIns
        snackLoadFailed = builtIns.isEmpty

        profile = files.load(UserProfile.self, from: .profile) ?? UserProfile(createdAt: .now, updatedAt: .distantPast)
        settings = files.load(AppSettings.self, from: .settings) ?? AppSettings()
        history = (files.load([SessionRecord].self, from: .history) ?? []).sorted { $0.savedAt > $1.savedAt }
        tombstones = files.load([String: Date].self, from: .tombstones) ?? [:]

        if var stored = files.load(SnackLibrary.self, from: .library) {
            if let disabled = stored.legacyDisabledBuiltInIDs {
                stored.kitSnackIDs.formUnion(builtIns.map(\.id).filter { !disabled.contains($0) })
                stored.legacyDisabledBuiltInIDs = nil
                files.save(stored, to: .library)
            }
            library = stored
        } else {
            let starter = builtIns.filter { snack in
                snack.nameKey.map(SnackLibrary.starterKitNameKeys.contains) ?? false
            }
            library = SnackLibrary(kitSnackIDs: Set(starter.map(\.id)))
        }
    }

    // MARK: - Profile & settings

    func updateProfile(_ change: (inout UserProfile) -> Void) {
        var updated = profile
        change(&updated)
        updated.updatedAt = .now
        profile = updated
        files.save(updated, to: .profile)
        scheduleSync()
    }

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        var updated = settings
        change(&updated)
        guard updated != settings else { return }
        updated.modifiedAt = .now
        settings = updated
        files.save(updated, to: .settings)
        scheduleSync()
    }

    // MARK: - History

    func session(id: UUID) -> SessionRecord? {
        history.first { $0.id == id }
    }

    /// Sessions the user can see: everything for Pro, the newest `freeHistorySessionLimit` otherwise.
    func visibleHistory(isPro: Bool) -> [SessionRecord] {
        isPro ? history : Array(history.prefix(AppConstants.freeHistorySessionLimit))
    }

    @discardableResult
    func addSession(setup: SessionSetup, result: FuelingResult, title: String? = nil) -> SessionRecord {
        let record = SessionRecord(title: title, setup: setup, result: result, profileWeightKg: profile.weightKg)
        history.insert(record, at: 0)
        persistHistory()
        return record
    }

    func updateSession(id: UUID, _ change: (inout SessionRecord) -> Void) {
        guard let index = history.firstIndex(where: { $0.id == id }) else { return }
        change(&history[index])
        history[index].modifiedAt = .now
        persistHistory()
    }

    func deleteSession(id: UUID) {
        guard history.contains(where: { $0.id == id }) else { return }
        history.removeAll { $0.id == id }
        tombstones[Self.sessionKey(id)] = .now
        files.save(tombstones, to: .tombstones)
        persistHistory()
    }

    private func persistHistory() {
        files.save(history, to: .history)
        scheduleSync()
    }

    // MARK: - Snacks

    /// Built-in and custom snacks, sorted by category, then name.
    var allSnacks: [Snack] {
        (builtInSnacks + library.customSnacks).sorted { lhs, rhs in
            if lhs.category != rhs.category { return lhs.category.sortOrder < rhs.category.sortOrder }
            return lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
        }
    }

    /// Snacks in “My kit” — the only ones the planner uses.
    var kitSnacks: [Snack] {
        allSnacks.filter { library.kitSnackIDs.contains($0.id) }
    }

    func snack(id: UUID) -> Snack? {
        builtInSnacks.first { $0.id == id } ?? library.customSnacks.first { $0.id == id }
    }

    func isInKit(_ snackID: UUID) -> Bool {
        library.kitSnackIDs.contains(snackID)
    }

    func setInKit(_ snackID: UUID, _ inKit: Bool) {
        updateLibrary { library in
            if inKit {
                library.kitSnackIDs.insert(snackID)
            } else {
                library.kitSnackIDs.remove(snackID)
            }
        }
    }

    func addCustomSnack(_ snack: Snack) {
        var custom = snack
        custom.isBuiltIn = false
        custom.isEnabled = true
        updateLibrary { library in
            library.customSnacks.removeAll { $0.id == custom.id }
            library.customSnacks.append(custom)
            library.kitSnackIDs.insert(custom.id)
        }
    }

    func updateCustomSnack(_ snack: Snack) {
        guard library.customSnacks.contains(where: { $0.id == snack.id }) else { return }
        var updated = snack
        updated.isBuiltIn = false
        updateLibrary { library in
            if let index = library.customSnacks.firstIndex(where: { $0.id == updated.id }) {
                library.customSnacks[index] = updated
            }
        }
    }

    func deleteCustomSnack(id: UUID) {
        updateLibrary { library in
            library.customSnacks.removeAll { $0.id == id }
            library.kitSnackIDs.remove(id)
        }
        SnackPhotoStore.delete(snackID: id)
    }

    /// Whether a scanned barcode is already in the library (prevents duplicates).
    func customSnack(withBarcode barcode: String) -> Snack? {
        library.customSnacks.first { $0.barcode == barcode }
    }

    private func updateLibrary(_ change: (inout SnackLibrary) -> Void) {
        var updated = library
        change(&updated)
        updated.modifiedAt = .now
        library = updated
        files.save(updated, to: .library)
        scheduleSync()
    }

    // MARK: - iCloud sync

    func scheduleSync(after delay: Duration = .seconds(2)) {
        guard syncService != nil else { return }
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            await self?.syncNow()
        }
    }

    func syncNow() async {
        guard let syncService, syncStatus != .syncing else { return }
        syncStatus = .syncing
        do {
            let remote = try await syncService.sync(local: localEnvelopes())
            apply(remote)
            syncStatus = .synced(.now)
        } catch CloudSyncService.SyncError.accountUnavailable {
            syncStatus = .unavailable
        } catch {
            Self.logger.error("Sync failed: \(error.localizedDescription, privacy: .public)")
            syncStatus = .failed
        }
    }

    static func sessionKey(_ id: UUID) -> String { "session.\(id.uuidString)" }

    func localEnvelopes() -> [SyncEnvelope] {
        let encoder = JSONEncoder.fuelZone
        var envelopes: [SyncEnvelope] = []
        if let data = try? encoder.encode(profile) {
            envelopes.append(SyncEnvelope(key: "profile", modifiedAt: profile.updatedAt, payload: data))
        }
        if let data = try? encoder.encode(settings) {
            envelopes.append(SyncEnvelope(key: "settings", modifiedAt: settings.modifiedAt, payload: data))
        }
        if let data = try? encoder.encode(library) {
            envelopes.append(SyncEnvelope(key: "library", modifiedAt: library.modifiedAt, payload: data))
        }
        for record in history {
            if let data = try? encoder.encode(record) {
                envelopes.append(SyncEnvelope(key: Self.sessionKey(record.id), modifiedAt: record.modifiedAt, payload: data))
            }
        }
        for (key, deletedAt) in tombstones {
            envelopes.append(SyncEnvelope(key: key, modifiedAt: deletedAt, payload: nil))
        }
        return envelopes
    }

    /// Applies newer remote items. Exposed for tests.
    func apply(_ remote: [SyncEnvelope]) {
        let decoder = JSONDecoder.fuelZone
        var historyChanged = false
        for envelope in remote {
            switch envelope.key {
            case "profile":
                if let data = envelope.payload, let value = try? decoder.decode(UserProfile.self, from: data) {
                    profile = value
                    files.save(value, to: .profile)
                }
            case "settings":
                if let data = envelope.payload, let value = try? decoder.decode(AppSettings.self, from: data) {
                    settings = value
                    files.save(value, to: .settings)
                }
            case "library":
                if let data = envelope.payload, let value = try? decoder.decode(SnackLibrary.self, from: data) {
                    library = value
                    files.save(value, to: .library)
                }
            default:
                guard envelope.key.hasPrefix("session.") else { continue }
                historyChanged = true
                if let data = envelope.payload, let record = try? decoder.decode(SessionRecord.self, from: data) {
                    tombstones[envelope.key] = nil
                    if let index = history.firstIndex(where: { $0.id == record.id }) {
                        history[index] = record
                    } else {
                        history.append(record)
                    }
                } else {
                    tombstones[envelope.key] = envelope.modifiedAt
                    history.removeAll { Self.sessionKey($0.id) == envelope.key }
                }
            }
        }
        if historyChanged {
            history.sort { $0.savedAt > $1.savedAt }
            files.save(history, to: .history)
            files.save(tombstones, to: .tombstones)
        }
    }
}
