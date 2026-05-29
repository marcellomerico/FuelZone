import Combine
import Foundation

@MainActor
final class SnackViewModel: ObservableObject {
    @Published private(set) var builtInSnacks: [Snack] = []
    @Published private(set) var libraryState = SnackLibraryState()
    @Published var selectedCategory: SnackCategory?
    @Published var loadError: String?
    @Published var showProPaywall = false
    @Published var showBarcodeScanner = false
    @Published var snackBeingEdited: Snack?

    private var settings = AppSettings()
    private let store = DataStore.shared

    init() {
        reload()
    }

    func configure(settings: AppSettings) { self.settings = settings }

    func reload() {
        do {
            builtInSnacks = try DefaultSnackLoader.loadBuiltInSnacks()
            loadError = nil
        } catch {
            builtInSnacks = []
            loadError = String(localized: "error.snacksLoadFailed")
        }
        if let state = store.load(SnackLibraryState.self, key: PersistenceKeys.snackLibraryState) {
            libraryState = state
        }
    }

    func allSnacks() -> [Snack] {
        var snacks = builtInSnacks.filter { !libraryState.disabledBuiltInIDs.contains($0.id) }
        if canManageCustomSnacks {
            snacks.append(contentsOf: libraryState.customSnacks)
        }
        return sortedSnacks(snacks)
    }

    private func sortedSnacks(_ snacks: [Snack]) -> [Snack] {
        snacks.sorted { lhs, rhs in
            if lhs.category != rhs.category {
                return lhs.category.sortOrder < rhs.category.sortOrder
            }
            return lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
        }
    }

    func enabledSnacks() -> [Snack] {
        allSnacks().filter(\.isEnabled)
    }

    func filteredSnacks() -> [Snack] {
        let snacks = allSnacks()
        guard let selectedCategory else { return snacks }
        return snacks.filter { $0.category == selectedCategory }
    }

    func isEnabled(_ snack: Snack) -> Bool {
        snack.isEnabled && !libraryState.disabledBuiltInIDs.contains(snack.id)
    }

    func setEnabled(_ snack: Snack, enabled: Bool) {
        if snack.isBuiltIn {
            if enabled {
                libraryState.disabledBuiltInIDs.remove(snack.id)
            } else {
                libraryState.disabledBuiltInIDs.insert(snack.id)
            }
        } else if let index = libraryState.customSnacks.firstIndex(where: { $0.id == snack.id }) {
            libraryState.customSnacks[index].isEnabled = enabled
        }
        persist()
    }

    var canManageCustomSnacks: Bool { settings.hasAccess(to: .customSnacks) }
    var canAddCustom: Bool { canManageCustomSnacks }
    var canEditCustom: Bool { canManageCustomSnacks }
    var canScanBarcode: Bool { settings.hasAccess(to: .barcodeScanner) }

    func requestBarcodeScan() {
        if canScanBarcode {
            showBarcodeScanner = true
        } else {
            showProPaywall = true
        }
    }

    @discardableResult
    func requestAddCustomSnack() -> Bool {
        guard canAddCustom else {
            showProPaywall = true
            return false
        }
        return true
    }

    func addCustomSnack(_ snack: Snack) {
        guard canManageCustomSnacks else {
            showProPaywall = true
            return
        }
        var custom = snack
        custom.isBuiltIn = false
        libraryState.customSnacks.append(custom)
        persist()
        objectWillChange.send()
    }

    func updateCustomSnack(_ snack: Snack) {
        guard canEditCustom else {
            showProPaywall = true
            return
        }
        guard let index = libraryState.customSnacks.firstIndex(where: { $0.id == snack.id }) else { return }
        var updated = snack
        updated.isBuiltIn = false
        libraryState.customSnacks[index] = updated
        persist()
        objectWillChange.send()
    }

    func deleteCustomSnack(_ snack: Snack) {
        guard canEditCustom else {
            showProPaywall = true
            return
        }
        guard !snack.isBuiltIn else { return }
        libraryState.customSnacks.removeAll { $0.id == snack.id }
        SnackPhotoStore.delete(snackID: snack.id)
        persist()
        objectWillChange.send()
    }

    func persist() {
        store.save(libraryState, key: PersistenceKeys.snackLibraryState)
    }
}
