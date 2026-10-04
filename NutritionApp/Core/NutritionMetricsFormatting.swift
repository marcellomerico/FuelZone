import Foundation

enum NutritionMetricsFormatting {
    static func snackQuantityLine(quantity: Double, name: String) -> String {
        L10n.format("metrics.snack.quantity", quantityText(quantity), name)
    }

    /// "1", "½", "1½" instead of "1.0" / "0.5".
    static func quantityText(_ quantity: Double) -> String {
        let whole = Int(quantity)
        let hasHalf = abs(quantity - Double(whole) - 0.5) < 0.01
        switch (whole, hasHalf) {
        case (0, true): return "½"
        case (_, true): return "\(whole)½"
        default: return "\(Int(quantity.rounded()))"
        }
    }

    /// "1 GU Roctane Gel" or "150 ml Isotonic drink" for a timeline entry.
    static func portionLine(portion: SnackPortion, snack: Snack) -> String {
        if snack.fluidMlPerDefaultPortion != nil {
            let ml = Int(snack.fluidMl(forQuantity: portion.quantity).rounded())
            return L10n.format("metrics.portion.drink", "\(ml)", snack.localizedName)
        }
        return snackQuantityLine(quantity: portion.quantity, name: snack.localizedName)
    }
}
