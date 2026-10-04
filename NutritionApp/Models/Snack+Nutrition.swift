import Foundation

extension Snack {
    /// Grams represented by one “unit” when `nutritionBasis` is `.per100g`.
    var effectivePortionGrams: Double {
        defaultPortionGrams ?? Self.millilitersByUnitKey[unitKey] ?? 100
    }

    /// Carbs for one default portion (one unit × `defaultServingSize`).
    var carbsPerDefaultPortion: Double {
        carbs(forQuantity: 1)
    }

    /// Sodium (mg) for one default portion.
    var sodiumMgPerDefaultPortion: Double {
        sodiumMg(forQuantity: 1)
    }

    /// Fluid volume (ml) of one default portion; `nil` for anything that is not a drink.
    /// Drinks are assumed to weigh ≈ 1 g per ml.
    var fluidMlPerDefaultPortion: Double? {
        guard category == .drink else { return nil }
        let ml = Self.millilitersByUnitKey[unitKey] ?? defaultPortionGrams
        guard let ml, ml > 0 else { return nil }
        return ml * defaultServingSize
    }

    func carbs(forQuantity quantity: Double) -> Double {
        let amount = max(quantity, 0)
        switch nutritionBasis {
        case .perServing:
            return carbsPerServing * defaultServingSize * amount
        case .per100g:
            return carbsPerServing * effectivePortionGrams * amount / 100
        }
    }

    func sodiumMg(forQuantity quantity: Double) -> Double {
        let amount = max(quantity, 0)
        switch nutritionBasis {
        case .perServing:
            return sodiumMgPerServing * defaultServingSize * amount
        case .per100g:
            return sodiumMgPerServing * effectivePortionGrams * amount / 100
        }
    }

    func fluidMl(forQuantity quantity: Double) -> Double {
        (fluidMlPerDefaultPortion ?? 0) * max(quantity, 0)
    }

    /// Human-readable nutrition line for lists (includes basis).
    var nutritionSummaryLine: String {
        switch nutritionBasis {
        case .per100g:
            return L10n.format(
                "snack.nutrition.summary.per100g",
                String(format: "%.1f", carbsPerServing),
                String(format: "%.1f", sodiumMgPerServing),
                "\(Int(effectivePortionGrams))",
                "\(Int(carbsPerDefaultPortion.rounded()))",
                "\(Int(sodiumMgPerDefaultPortion.rounded()))"
            )
        case .perServing:
            return L10n.format(
                "snack.nutrition.summary.perServing",
                "\(Int(carbsPerDefaultPortion.rounded()))",
                "\(Int(sodiumMgPerDefaultPortion.rounded()))",
                localizedUnit
            )
        }
    }

    private static let millilitersByUnitKey: [String: Double] = [
        "unit.ml500": 500,
        "unit.ml330": 330,
        "unit.ml250": 250,
    ]
}
