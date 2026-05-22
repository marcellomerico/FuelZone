import Foundation

enum NutritionMetricsFormatting {
    static func stepTargets(carbs: Double, fluidsMl: Int, sodiumMg: Double) -> String {
        L10n.format(
            "metrics.step.targets",
            "\(Int(carbs))",
            "\(fluidsMl)",
            "\(Int(sodiumMg))"
        )
    }

    static func snackQuantityLine(quantity: Double, name: String) -> String {
        L10n.format("metrics.snack.quantity", String(format: "%.1f", quantity), name)
    }

    static func snackMacros(carbs: Int, sodium: Int) -> String {
        L10n.format("metrics.snack.macros", "\(carbs)", "\(sodium)")
    }

    static func snackPlanTotals(carbs: Int, sodium: Int, fluids: Int) -> String {
        L10n.format("metrics.plan.totals", "\(carbs)", "\(sodium)", "\(fluids)")
    }

    static func historyDuration(minutes: Int) -> String {
        L10n.format("history.duration", "\(minutes)")
    }

    static func carbsPerHour(value: Int) -> String {
        L10n.format("history.carbsPerHour", "\(value)")
    }
}
