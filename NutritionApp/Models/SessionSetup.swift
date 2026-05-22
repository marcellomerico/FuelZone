import Foundation

/// User input for a single planned training session.
struct SessionSetup: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var sport: SportType
    var durationInputMode: DurationInputMode
    var durationMinutes: Int?
    var distanceKm: Double?
    var paceMinutesPerKm: Double?
    var intensityMode: IntensityMode
    var simpleIntensity: SimpleIntensity
    var zoneDistribution: HeartRateZoneDistribution
    var temperature: TemperatureLevel
    var conditions: WeatherCondition
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sport: SportType = .running,
        durationInputMode: DurationInputMode = .duration,
        durationMinutes: Int? = 90,
        distanceKm: Double? = nil,
        paceMinutesPerKm: Double? = nil,
        intensityMode: IntensityMode = .simple,
        simpleIntensity: SimpleIntensity = .moderate,
        zoneDistribution: HeartRateZoneDistribution = .default(forSessionMinutes: 90),
        temperature: TemperatureLevel = .mild,
        conditions: WeatherCondition = .dry,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sport = sport
        self.durationInputMode = durationInputMode
        self.durationMinutes = durationMinutes
        self.distanceKm = distanceKm
        self.paceMinutesPerKm = paceMinutesPerKm
        self.intensityMode = intensityMode
        self.simpleIntensity = simpleIntensity
        self.zoneDistribution = zoneDistribution
        self.temperature = temperature
        self.conditions = conditions
        self.createdAt = createdAt
    }

    /// Resolved session length in minutes (computed from distance/pace or distance/time when needed).
    func resolvedDurationMinutes() -> Int? {
        switch durationInputMode {
        case .duration:
            return durationMinutes
        case .distanceAndPace:
            guard let distanceKm, let paceMinutesPerKm, paceMinutesPerKm > 0 else { return nil }
            return Int((distanceKm * paceMinutesPerKm).rounded())
        case .distanceAndTime:
            return durationMinutes
        }
    }
}
