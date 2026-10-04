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
    /// Snapshot of every snack referenced by the timeline, so saved plans stay readable
    /// after a snack is edited, removed from the kit or deleted.
    var usedSnacks: [Snack]

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
        warningKeys: [String] = [],
        usedSnacks: [Snack] = []
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
        self.usedSnacks = usedSnacks
    }

    private enum CodingKeys: String, CodingKey {
        case id, sessionDurationMinutes, carbsPerHour, totalCarbsGrams, fluidsPerHourMl, totalFluidsMl
        case sodiumPerHourMg, totalSodiumMg, timeline, warningKeys, usedSnacks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        sessionDurationMinutes = try c.decode(Int.self, forKey: .sessionDurationMinutes)
        carbsPerHour = try c.decode(NutritionRange.self, forKey: .carbsPerHour)
        totalCarbsGrams = try c.decode(NutritionRange.self, forKey: .totalCarbsGrams)
        fluidsPerHourMl = try c.decode(NutritionRange.self, forKey: .fluidsPerHourMl)
        totalFluidsMl = try c.decode(Int.self, forKey: .totalFluidsMl)
        sodiumPerHourMg = try c.decode(NutritionRange.self, forKey: .sodiumPerHourMg)
        totalSodiumMg = try c.decode(Int.self, forKey: .totalSodiumMg)
        timeline = try c.decode([TimelineStep].self, forKey: .timeline)
        warningKeys = try c.decodeIfPresent([String].self, forKey: .warningKeys) ?? []
        usedSnacks = try c.decodeIfPresent([Snack].self, forKey: .usedSnacks) ?? []
    }
}
