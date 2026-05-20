import Foundation

struct FuelingResult: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var sessionDurationMinutes: Int
    var carbsPerHour: NutritionRange
    var totalCarbsGrams: NutritionRange
    var fluidsPerHourMl: NutritionRange
    var totalFluidsMl: Int
    var sodiumPerHourMg: NutritionRange
    var totalSodiumMg: Int
    var timeline: [TimelineStep]
    /// Localization keys for advisory messages (e.g. stomach cap applied).
    var warningKeys: [String]

    init(
        id: UUID = UUID(),
        sessionDurationMinutes: Int,
        carbsPerHour: NutritionRange,
        totalCarbsGrams: NutritionRange,
        fluidsPerHourMl: NutritionRange,
        totalFluidsMl: Int,
        sodiumPerHourMg: NutritionRange,
        totalSodiumMg: Int,
        timeline: [TimelineStep],
        warningKeys: [String] = []
    ) {
        self.id = id
        self.sessionDurationMinutes = sessionDurationMinutes
        self.carbsPerHour = carbsPerHour
        self.totalCarbsGrams = totalCarbsGrams
        self.fluidsPerHourMl = fluidsPerHourMl
        self.totalFluidsMl = totalFluidsMl
        self.sodiumPerHourMg = sodiumPerHourMg
        self.totalSodiumMg = totalSodiumMg
        self.timeline = timeline
        self.warningKeys = warningKeys
    }
}
