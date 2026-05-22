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
        builtInSnacks.filter { !libraryState.disabledBuiltInIDs.contains($0.id) } + libraryState.customSnacks
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

    var canAddCustom: Bool { settings.hasAccess(to: .barcodeScanner) }
    var canScanBarcode: Bool { settings.hasAccess(to: .barcodeScanner) }

    func requestBarcodeScan() {
        if canScanBarcode {
            showBarcodeScanner = true
        } else {
            showProPaywall = true
        }
    }

    func requestAddCustomSnack() {
        if canAddCustom {
            // caller presents AddCustomSnack sheet
        } else {
            showProPaywall = true
        }
    }

    func addCustomSnack(_ snack: Snack) {
        guard canAddCustom else {
            showProPaywall = true
            return
        }
        var custom = snack
        custom.isBuiltIn = false
        libraryState.customSnacks.append(custom)
        persist()
        objectWillChange.send()
    }

    func persist() {
        store.save(libraryState, key: PersistenceKeys.snackLibraryState)
    }
}
