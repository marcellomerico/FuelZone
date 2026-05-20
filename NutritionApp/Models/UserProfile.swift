import Foundation

struct UserProfile: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var displayName: String?
    var weightKg: Double?
    var primarySport: SportType
    var stomachSensitivity: StomachSensitivity
    var sweatRate: SweatRate
    var sweatSaltiness: SweatSaltiness
    var maxHeartRate: Int?
    var zoneThresholds: HeartRateZoneThresholds?
    var hasCompletedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String? = nil,
        weightKg: Double? = nil,
        primarySport: SportType = .running,
        stomachSensitivity: StomachSensitivity = .moderate,
        sweatRate: SweatRate = .moderate,
        sweatSaltiness: SweatSaltiness = .moderate,
        maxHeartRate: Int? = nil,
        zoneThresholds: HeartRateZoneThresholds? = nil,
        hasCompletedOnboarding: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.weightKg = weightKg
        self.primarySport = primarySport
        self.stomachSensitivity = stomachSensitivity
        self.sweatRate = sweatRate
        self.sweatSaltiness = sweatSaltiness
        self.maxHeartRate = maxHeartRate
        self.zoneThresholds = zoneThresholds
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    mutating func refreshZoneThresholdsFromMaxHR() {
        guard let maxHeartRate else { return }
        zoneThresholds = HeartRateZoneThresholds.standard(maxHeartRate: maxHeartRate)
    }
}
