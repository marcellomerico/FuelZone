import Foundation

/// What the planned snacks actually deliver, as opposed to the targets.
struct FuelPlanSummary: Equatable, Sendable {
    struct PackItem: Identifiable, Equatable, Sendable {
        var snack: Snack
        /// Number of default portions (e.g. 2 gels, 0.9 of a 500 ml bottle).
        var quantity: Double
        var id: UUID { snack.id }

        /// Whole units to pack (a partly used bottle still has to be carried).
        var unitsToPack: Int { max(1, Int(quantity.rounded(.up))) }
        var fluidMl: Double { snack.fluidMl(forQuantity: quantity) }
        var carbs: Double { snack.carbs(forQuantity: quantity) }
        var sodiumMg: Double { snack.sodiumMg(forQuantity: quantity) }
    }

    var packItems: [PackItem]
    var waterMl: Int
    var totalCarbs: Double
    var totalSodiumMg: Double
    var totalFluidsMl: Double
    var sessionMinutes: Int

    var carbsPerHour: Double { perHour(totalCarbs) }
    var sodiumPerHour: Double { perHour(totalSodiumMg) }
    var fluidsPerHour: Double { perHour(totalFluidsMl) }

    private func perHour(_ total: Double) -> Double {
        guard sessionMinutes > 0 else { return 0 }
        return total / (Double(sessionMinutes) / 60)
    }

    init(result: FuelingResult, fallbackSnacks: [Snack] = []) {
        var catalog: [UUID: Snack] = [:]
        for snack in fallbackSnacks { catalog[snack.id] = snack }
        for snack in result.usedSnacks { catalog[snack.id] = snack }

        var quantities: [UUID: Double] = [:]
        var order: [UUID] = []
        for portion in result.timeline.flatMap(\.portions) where catalog[portion.snackID] != nil {
            if quantities[portion.snackID] == nil { order.append(portion.snackID) }
            quantities[portion.snackID, default: 0] += portion.quantity
        }

        packItems = order.compactMap { id in
            guard let snack = catalog[id], let quantity = quantities[id] else { return nil }
            return PackItem(snack: snack, quantity: quantity)
        }
        waterMl = result.timeline.reduce(0) { $0 + $1.waterMl }
        totalCarbs = packItems.reduce(0) { $0 + $1.carbs }
        totalSodiumMg = packItems.reduce(0) { $0 + $1.sodiumMg }
        totalFluidsMl = packItems.reduce(Double(waterMl)) { $0 + $1.fluidMl }
        sessionMinutes = result.sessionDurationMinutes
    }

    /// Whether the planned carbs land inside the recommended hourly range (with a small rounding margin).
    func carbsWithinTarget(_ range: NutritionRange) -> Bool {
        carbsPerHour >= range.min * 0.9 && carbsPerHour <= range.max * 1.1
    }
}
