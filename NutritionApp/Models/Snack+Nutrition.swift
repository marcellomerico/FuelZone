import Foundation

extension Snack {
    /// Grams represented by one “unit” when `nutritionBasis` is `.per100g`.
    var effectivePortionGrams: Double {
        switch nutritionBasis {
        case .per100g:
            defaultPortionGrams ?? inferredPortionGramsFromUnit ?? 100
        case .perServing:
            defaultPortionGrams ?? inferredPortionGramsFromUnit ?? 100
        }
    }

    /// Carbs for one default portion (one unit × `defaultServingSize`).
    var carbsPerDefaultPortion: Double {
        carbs(forQuantity: defaultServingSize)
    }

    /// Sodium (mg) for one default portion.
    var sodiumMgPerDefaultPortion: Double {
        sodiumMg(forQuantity: defaultServingSize)
    }

    func carbs(forQuantity quantity: Double) -> Double {
        let amount = max(quantity, 0)
        switch nutritionBasis {
        case .perServing:
            return carbsPerServing * defaultServingSize * amount
        case .per100g:
            let grams = effectivePortionGrams * amount
            return carbsPerServing * grams / 100
        }
    }

    func sodiumMg(forQuantity quantity: Double) -> Double {
        let amount = max(quantity, 0)
        switch nutritionBasis {
        case .perServing:
            return sodiumMgPerServing * defaultServingSize * amount
        case .per100g:
            let grams = effectivePortionGrams * amount
            return sodiumMgPerServing * grams / 100
        }
    }

    /// Human-readable nutrition line for lists (includes basis).
    var nutritionSummaryLine: String {
        switch nutritionBasis {
        case .per100g:
            let portionCarbs = Int(carbsPerDefaultPortion.rounded())
            let portionSodium = Int(sodiumMgPerDefaultPortion.rounded())
            return L10n.format(
                "snack.nutrition.summary.per100g",
                String(format: "%.1f", carbsPerServing),
                String(format: "%.1f", sodiumMgPerServing),
                "\(Int(effectivePortionGrams))",
                "\(portionCarbs)",
                "\(portionSodium)"
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

    private var inferredPortionGramsFromUnit: Double? {
        switch unitKey {
        case "unit.ml500": 500
        case "unit.ml330": 330
        case "unit.ml250": 250
        case "unit.gel", "unit.bar", "unit.waffle", "unit.tablet", "unit.capsule", "unit.pack",
             "unit.slice", "unit.scoop", "unit.piece", "unit.handful", "unit.tbsp":
            nil
        default:
            nil
        }
    }
}
