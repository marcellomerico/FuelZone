import Foundation

/// How carbohydrate and sodium values are stored for a snack.
enum SnackNutritionBasis: String, Codable, CaseIterable, Identifiable {
    /// Values are per 100 g of product; use `defaultPortionGrams` for a typical portion.
    case per100g
    /// Values are per branded / defined portion (e.g. one gel).
    case perServing

    var id: String { rawValue }

    var localizationKey: String {
        switch self {
        case .per100g: "snack.nutrition.per100g"
        case .perServing: "snack.nutrition.perServing"
        }
    }
}
