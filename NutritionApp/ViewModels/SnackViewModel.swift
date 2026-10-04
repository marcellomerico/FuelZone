import Combine
import Foundation

/// Snack screen state: “My kit”, catalog filtering, custom snacks and barcode scanning.
@MainActor
final class SnackViewModel: ObservableObject {
    // A nonisolated deinit avoids the isolated-deinit back-deployment shim, which crashes on iOS < 26
    // (swift_task_deinitOnExecutorMainActorBackDeploy) when the object is released on the main thread.
    nonisolated deinit {}

    @Published var selectedCategory: SnackCategory?
    @Published var searchText = ""
    @Published var showProPaywall = false
    @Published var showBarcodeScanner = false
    @Published var showAddSnack = false
    @Published var snackBeingEdited: Snack?
    @Published private(set) var isProcessingBarcode = false

    let store: UserDataStore
    var isProProvider: () -> Bool = { false }
    private var cancellable: AnyCancellable?

    init(store: UserDataStore) {
        self.store = store
        cancellable = store.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
    }

    var loadError: String? {
        store.snackLoadFailed ? L10n.string("error.snacksLoadFailed") : nil
    }

    var kitSnacks: [Snack] { store.kitSnacks }

    /// Catalog filtered by category and search text. Snacks stay visible whether or not they are in the kit.
    var catalogSnacks: [Snack] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return store.allSnacks.filter { snack in
            (selectedCategory == nil || snack.category == selectedCategory)
                && (query.isEmpty || snack.localizedName.localizedCaseInsensitiveContains(query))
        }
    }

    func isInKit(_ snack: Snack) -> Bool { store.isInKit(snack.id) }

    func toggleKit(_ snack: Snack) {
        store.setInKit(snack.id, !store.isInKit(snack.id))
    }

    var canManageCustomSnacks: Bool { isProProvider() }

    func requestAddCustomSnack() {
        if canManageCustomSnacks {
            showAddSnack = true
        } else {
            showProPaywall = true
        }
    }

    func requestBarcodeScan() {
        if canManageCustomSnacks {
            showBarcodeScanner = true
        } else {
            showProPaywall = true
        }
    }

    func requestEdit(_ snack: Snack) {
        guard !snack.isBuiltIn else { return }
        if canManageCustomSnacks {
            snackBeingEdited = snack
        } else {
            showProPaywall = true
        }
    }

    func saveCustomSnack(_ snack: Snack, isNew: Bool) {
        guard canManageCustomSnacks else {
            showProPaywall = true
            return
        }
        if isNew {
            store.addCustomSnack(snack)
        } else {
            store.updateCustomSnack(snack)
        }
    }

    func deleteCustomSnack(_ snack: Snack) {
        guard canManageCustomSnacks, !snack.isBuiltIn else { return }
        store.deleteCustomSnack(id: snack.id)
    }

    enum BarcodeOutcome: Equatable {
        case added(Snack)
        case alreadyInLibrary(Snack)
        case failed(String)
        case ignored
    }

    /// Looks up a scanned barcode once; repeated callbacks while a lookup runs are ignored.
    func handleScannedBarcode(_ code: String) async -> BarcodeOutcome {
        guard canManageCustomSnacks, !isProcessingBarcode else { return .ignored }
        let barcode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = store.customSnack(withBarcode: barcode) {
            return .alreadyInLibrary(existing)
        }
        isProcessingBarcode = true
        defer { isProcessingBarcode = false }
        do {
            let product = try await OpenFoodFactsClient.fetchProduct(barcode: barcode)
            let snack = Snack(
                nameEN: product.nameEN,
                nameDE: product.nameDE,
                category: product.isLiquid ? .drink : .other,
                carbsPerServing: product.carbsPerServing,
                sodiumMgPerServing: product.sodiumMgPerServing,
                nutritionBasis: product.nutritionBasis,
                defaultPortionGrams: product.defaultPortionGrams,
                unitKey: product.isLiquid ? "unit.bottle" : "unit.piece",
                isBuiltIn: false,
                barcode: product.barcode
            )
            store.addCustomSnack(snack)
            return .added(snack)
        } catch OpenFoodFactsClient.ClientError.missingNutrition {
            return .failed(L10n.string("error.barcodeNoNutrition"))
        } catch {
            return .failed(L10n.string("error.barcodeNotFound"))
        }
    }
}
