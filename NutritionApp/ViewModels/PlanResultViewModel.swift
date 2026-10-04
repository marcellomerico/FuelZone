import Combine
import Foundation

/// Shows one saved plan (fresh result or history entry). Snack swaps are written back to the store.
@MainActor
final class PlanResultViewModel: ObservableObject {
    let recordID: UUID
    let store: UserDataStore
    private let isProProvider: () -> Bool
    private var cancellable: AnyCancellable?

    @Published var swapContext: SnackSwapContext?
    @Published var showProPaywall = false

    init(recordID: UUID, store: UserDataStore, isPro: @escaping () -> Bool) {
        self.recordID = recordID
        self.store = store
        isProProvider = isPro
        cancellable = store.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    var record: SessionRecord? { store.session(id: recordID) }
    var result: FuelingResult? { record?.result }
    var canSwapSnacks: Bool { isProProvider() }

    var summary: FuelPlanSummary? {
        result.map { FuelPlanSummary(result: $0, fallbackSnacks: store.allSnacks) }
    }

    func snack(for portion: SnackPortion) -> Snack? {
        result?.usedSnacks.first { $0.id == portion.snackID } ?? store.snack(id: portion.snackID)
    }

    /// Snacks offered when swapping: the kit first, then everything else.
    var swapCandidates: [Snack] {
        let kit = store.kitSnacks
        let kitIDs = Set(kit.map(\.id))
        return kit + store.allSnacks.filter { !kitIDs.contains($0.id) }
    }

    func requestSwap(stepID: UUID, portionID: UUID) {
        if canSwapSnacks {
            swapContext = SnackSwapContext(stepID: stepID, portionID: portionID)
        } else {
            showProPaywall = true
        }
    }

    func swap(stepID: UUID, portionID: UUID, to snack: Snack) {
        guard canSwapSnacks else {
            showProPaywall = true
            return
        }
        guard let result,
              let updated = FuelPlanEditor.swap(
                  in: result, stepID: stepID, portionID: portionID, to: snack,
                  lookup: { [store] in store.snack(id: $0) }
              ) else { return }
        store.updateSession(id: recordID) { $0.result = updated }
    }

    func rename(to title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSession(id: recordID) { $0.title = trimmed.isEmpty ? nil : trimmed }
    }

    func warningMessages() -> [String] {
        result?.warningKeys.map { L10n.string($0) } ?? []
    }
}
