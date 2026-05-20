import Foundation

struct TimelineStep: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var startMinute: Int
    var endMinute: Int
    var targetCarbsGrams: Double
    var targetSodiumMg: Double
    var targetFluidsMl: Int
    var portions: [SnackPortion]
    var isUserModified: Bool

    init(
        id: UUID = UUID(),
        startMinute: Int,
        endMinute: Int,
        targetCarbsGrams: Double,
        targetSodiumMg: Double,
        targetFluidsMl: Int,
        portions: [SnackPortion] = [],
        isUserModified: Bool = false
    ) {
        self.id = id
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.targetCarbsGrams = targetCarbsGrams
        self.targetSodiumMg = targetSodiumMg
        self.targetFluidsMl = targetFluidsMl
        self.portions = portions
        self.isUserModified = isUserModified
    }

    var durationMinutes: Int { endMinute - startMinute }

    var labelKey: String { "timeline.step.range" }
}
