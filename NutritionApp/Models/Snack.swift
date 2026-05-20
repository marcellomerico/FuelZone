import Foundation

struct Snack: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    /// Localization key for built-in snacks (e.g. `snack.gel.standard`).
    var nameKey: String?
    var nameEN: String?
    var nameDE: String?
    var category: SnackCategory
    var carbsPerServing: Double
    var sodiumMgPerServing: Double
    /// Localization key for serving unit (e.g. `unit.gel`).
    var unitKey: String
    var defaultServingSize: Double
    var isBuiltIn: Bool
    var barcode: String?
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        nameKey: String? = nil,
        nameEN: String? = nil,
        nameDE: String? = nil,
        category: SnackCategory,
        carbsPerServing: Double,
        sodiumMgPerServing: Double,
        unitKey: String,
        defaultServingSize: Double = 1,
        isBuiltIn: Bool = false,
        barcode: String? = nil,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.nameKey = nameKey
        self.nameEN = nameEN
        self.nameDE = nameDE
        self.category = category
        self.carbsPerServing = carbsPerServing
        self.sodiumMgPerServing = sodiumMgPerServing
        self.unitKey = unitKey
        self.defaultServingSize = defaultServingSize
        self.isBuiltIn = isBuiltIn
        self.barcode = barcode
        self.isEnabled = isEnabled
    }

    var displayNameKey: String? {
        if let nameKey { return nameKey }
        return nil
    }
}

/// JSON container for bundled default snacks.
struct DefaultSnacksFile: Codable {
    let version: Int
    let snacks: [DefaultSnackDTO]
}

struct DefaultSnackDTO: Codable {
    let id: UUID
    let nameKey: String
    let category: SnackCategory
    let carbsPerServing: Double
    let sodiumMgPerServing: Double
    let unitKey: String
    let defaultServingSize: Double

    func toSnack() -> Snack {
        Snack(
            id: id,
            nameKey: nameKey,
            category: category,
            carbsPerServing: carbsPerServing,
            sodiumMgPerServing: sodiumMgPerServing,
            unitKey: unitKey,
            defaultServingSize: defaultServingSize,
            isBuiltIn: true
        )
    }
}
