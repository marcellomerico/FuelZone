import Combine
import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published private(set) var records: [SessionRecord] = []

    private var settings = AppSettings()
    private let store = DataStore.shared

    func configure(settings: AppSettings) { self.settings = settings }

    func reload() {
        records = store.load([SessionRecord].self, key: PersistenceKeys.sessionHistory) ?? []
        records.sort { $0.savedAt > $1.savedAt }
    }

    func updateSettings(_ settings: AppSettings) { self.settings = settings }

    func saveSession(setup: SessionSetup, result: FuelingResult, profile: UserProfile) {
        var list = records
        let record = SessionRecord(
            setup: setup,
            result: result,
            profileWeightKg: profile.weightKg
        )
        list.insert(record, at: 0)

        if !settings.hasAccess(to: .unlimitedHistory) {
            list = Array(list.prefix(AppConstants.freeHistorySessionLimit))
        }

        records = list
        store.save(list, key: PersistenceKeys.sessionHistory)
    }

    func delete(at offsets: IndexSet) {
        var list = records
        for index in offsets.sorted(by: >) {
            list.remove(at: index)
        }
        records = list
        store.save(list, key: PersistenceKeys.sessionHistory)
    }

    /// Persists timeline edits (e.g. snack swaps) on a saved session.
    func updateResult(recordID: UUID, result: FuelingResult) {
        guard let index = records.firstIndex(where: { $0.id == recordID }) else { return }
        records[index].result = result
        store.save(records, key: PersistenceKeys.sessionHistory)
    }
}
