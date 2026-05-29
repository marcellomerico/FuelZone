import Foundation

struct Snack: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    /// Localization key for built-in snacks (e.g. `snack.gel.maurten160`).
    var nameKey: String?
    var nameEN: String?
    var nameDE: String?
    var category: SnackCategory
    /// Stored as g per 100 g (`per100g`) or g per portion (`perServing`).
    var carbsPerServing: Double
    /// Stored as mg per 100 g (`per100g`) or mg per portion (`perServing`).
    var sodiumMgPerServing: Double
    var nutritionBasis: SnackNutritionBasis
    /// Typical portion weight in grams when `nutritionBasis` is `.per100g` (e.g. 330 ml cola ≈ 330 g).
    var defaultPortionGrams: Double?
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
        nutritionBasis: SnackNutritionBasis = .perServing,
        defaultPortionGrams: Double? = nil,
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
        self.nutritionBasis = nutritionBasis
        self.defaultPortionGrams = defaultPortionGrams
        self.unitKey = unitKey
        self.defaultServingSize = defaultServingSize
        self.isBuiltIn = isBuiltIn
        self.barcode = barcode
        self.isEnabled = isEnabled
    }

    enum CodingKeys: String, CodingKey {
        case id, nameKey, nameEN, nameDE, category
        case carbsPerServing, sodiumMgPerServing, nutritionBasis, defaultPortionGrams
        case unitKey, defaultServingSize, isBuiltIn, barcode, isEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        nameKey = try c.decodeIfPresent(String.self, forKey: .nameKey)
        nameEN = try c.decodeIfPresent(String.self, forKey: .nameEN)
        nameDE = try c.decodeIfPresent(String.self, forKey: .nameDE)
        category = try c.decode(SnackCategory.self, forKey: .category)
        carbsPerServing = try c.decode(Double.self, forKey: .carbsPerServing)
        sodiumMgPerServing = try c.decode(Double.self, forKey: .sodiumMgPerServing)
        nutritionBasis = try c.decodeIfPresent(SnackNutritionBasis.self, forKey: .nutritionBasis) ?? .perServing
        defaultPortionGrams = try c.decodeIfPresent(Double.self, forKey: .defaultPortionGrams)
        unitKey = try c.decode(String.self, forKey: .unitKey)
        defaultServingSize = try c.decodeIfPresent(Double.self, forKey: .defaultServingSize) ?? 1
        isBuiltIn = try c.decodeIfPresent(Bool.self, forKey: .isBuiltIn) ?? false
        barcode = try c.decodeIfPresent(String.self, forKey: .barcode)
        isEnabled = try c.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
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
    let nutritionBasis: SnackNutritionBasis?
    let defaultPortionGrams: Double?
    let unitKey: String
    let defaultServingSize: Double

    func toSnack() -> Snack {
        Snack(
            id: id,
            nameKey: nameKey,
            category: category,
            carbsPerServing: carbsPerServing,
            sodiumMgPerServing: sodiumMgPerServing,
            nutritionBasis: nutritionBasis ?? .perServing,
            defaultPortionGrams: defaultPortionGrams,
            unitKey: unitKey,
            defaultServingSize: defaultServingSize,
            isBuiltIn: true
        )
    }
}
