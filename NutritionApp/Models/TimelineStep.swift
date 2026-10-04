import Foundation

struct TimelineStep: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var startMinute: Int
    var endMinute: Int
    var targetCarbsGrams: Double
    var targetSodiumMg: Double
    var targetFluidsMl: Int
    var portions: [SnackPortion]
    /// Plain water to drink at this stop (fluid not covered by drink snacks).
    var waterMl: Int
    var isUserModified: Bool

    init(
        id: UUID = UUID(),
        startMinute: Int,
        endMinute: Int,
        targetCarbsGrams: Double,
        targetSodiumMg: Double,
        targetFluidsMl: Int,
        portions: [SnackPortion] = [],
        waterMl: Int = 0,
        isUserModified: Bool = false
    ) {
        self.id = id
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.targetCarbsGrams = targetCarbsGrams
        self.targetSodiumMg = targetSodiumMg
        self.targetFluidsMl = targetFluidsMl
        self.portions = portions
        self.waterMl = waterMl
        self.isUserModified = isUserModified
    }

    var durationMinutes: Int { endMinute - startMinute }

    private enum CodingKeys: String, CodingKey {
        case id, startMinute, endMinute, targetCarbsGrams, targetSodiumMg, targetFluidsMl
        case portions, waterMl, isUserModified
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        startMinute = try c.decode(Int.self, forKey: .startMinute)
        endMinute = try c.decode(Int.self, forKey: .endMinute)
        targetCarbsGrams = try c.decode(Double.self, forKey: .targetCarbsGrams)
        targetSodiumMg = try c.decode(Double.self, forKey: .targetSodiumMg)
        targetFluidsMl = try c.decode(Int.self, forKey: .targetFluidsMl)
        portions = try c.decodeIfPresent([SnackPortion].self, forKey: .portions) ?? []
        waterMl = try c.decodeIfPresent(Int.self, forKey: .waterMl) ?? 0
        isUserModified = try c.decodeIfPresent(Bool.self, forKey: .isUserModified) ?? false
    }
}
