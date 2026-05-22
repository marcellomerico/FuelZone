import Foundation

/// Minutes spent in each HR zone during the session (must sum to session duration).
struct HeartRateZoneDistribution: Codable, Hashable, Sendable {
    var zone1Minutes: Int
    var zone2Minutes: Int
    var zone3Minutes: Int
    var zone4Minutes: Int
    var zone5Minutes: Int

    static func `default`(forSessionMinutes total: Int) -> HeartRateZoneDistribution {
        distribution(fromPercents: [10, 50, 25, 10, 5], sessionMinutes: total)
    }

    var totalMinutes: Int {
        zone1Minutes + zone2Minutes + zone3Minutes + zone4Minutes + zone5Minutes
    }

    func isValid(sessionDurationMinutes: Int) -> Bool {
        guard sessionDurationMinutes > 0 else { return false }
        return totalMinutes == sessionDurationMinutes
    }

    func minutes(for zone: HeartRateZone) -> Int {
        switch zone {
        case .zone1: zone1Minutes
        case .zone2: zone2Minutes
        case .zone3: zone3Minutes
        case .zone4: zone4Minutes
        case .zone5: zone5Minutes
        }
    }

    /// Weighted intensity scale (0.65–1.0) from planned time in each zone.
    func weightedIntensityScale(sessionDurationMinutes: Int) -> Double {
        guard sessionDurationMinutes > 0, totalMinutes > 0 else { return ExerciseCarbGuidelines.maximumIntensityScale }
        let total = Double(totalMinutes)
        return HeartRateZone.allCases.reduce(0) { partial, zone in
            partial + (Double(minutes(for: zone)) / total) * zone.intensityScale
        }
    }

    /// Keeps the zone mix ratio and adjusts minute counts to a new session length.
    func scaled(toSessionMinutes newTotal: Int) -> HeartRateZoneDistribution {
        guard newTotal > 0 else { return self }
        let oldTotal = totalMinutes
        guard oldTotal > 0 else { return Self.default(forSessionMinutes: newTotal) }

        let raw = [
            Double(zone1Minutes),
            Double(zone2Minutes),
            Double(zone3Minutes),
            Double(zone4Minutes),
            Double(zone5Minutes)
        ]
        var minutes = raw.map { Int(($0 / Double(oldTotal) * Double(newTotal)).rounded()) }
        let delta = newTotal - minutes.reduce(0, +)
        if delta != 0 {
            let index = minutes.indices.max(by: { minutes[$0] < minutes[$1] }) ?? 1
            minutes[index] += delta
        }
        return HeartRateZoneDistribution(
            zone1Minutes: minutes[0],
            zone2Minutes: minutes[1],
            zone3Minutes: minutes[2],
            zone4Minutes: minutes[3],
            zone5Minutes: minutes[4]
        )
    }

    // MARK: - Codable (legacy percent keys)

    private enum CodingKeys: String, CodingKey {
        case zone1Minutes, zone2Minutes, zone3Minutes, zone4Minutes, zone5Minutes
        case zone1Percent, zone2Percent, zone3Percent, zone4Percent, zone5Percent
    }

    init(
        zone1Minutes: Int,
        zone2Minutes: Int,
        zone3Minutes: Int,
        zone4Minutes: Int,
        zone5Minutes: Int
    ) {
        self.zone1Minutes = max(0, zone1Minutes)
        self.zone2Minutes = max(0, zone2Minutes)
        self.zone3Minutes = max(0, zone3Minutes)
        self.zone4Minutes = max(0, zone4Minutes)
        self.zone5Minutes = max(0, zone5Minutes)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if container.contains(.zone1Minutes) {
            zone1Minutes = try container.decode(Int.self, forKey: .zone1Minutes)
            zone2Minutes = try container.decode(Int.self, forKey: .zone2Minutes)
            zone3Minutes = try container.decode(Int.self, forKey: .zone3Minutes)
            zone4Minutes = try container.decode(Int.self, forKey: .zone4Minutes)
            zone5Minutes = try container.decode(Int.self, forKey: .zone5Minutes)
        } else {
            let percents = [
                try container.decode(Double.self, forKey: .zone1Percent),
                try container.decode(Double.self, forKey: .zone2Percent),
                try container.decode(Double.self, forKey: .zone3Percent),
                try container.decode(Double.self, forKey: .zone4Percent),
                try container.decode(Double.self, forKey: .zone5Percent)
            ]
            let migrated = Self.distribution(
                fromPercents: percents.map { Int($0.rounded()) },
                sessionMinutes: 90
            )
            zone1Minutes = migrated.zone1Minutes
            zone2Minutes = migrated.zone2Minutes
            zone3Minutes = migrated.zone3Minutes
            zone4Minutes = migrated.zone4Minutes
            zone5Minutes = migrated.zone5Minutes
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(zone1Minutes, forKey: .zone1Minutes)
        try container.encode(zone2Minutes, forKey: .zone2Minutes)
        try container.encode(zone3Minutes, forKey: .zone3Minutes)
        try container.encode(zone4Minutes, forKey: .zone4Minutes)
        try container.encode(zone5Minutes, forKey: .zone5Minutes)
    }

    private static func distribution(fromPercents percents: [Int], sessionMinutes: Int) -> HeartRateZoneDistribution {
        guard percents.count == 5, sessionMinutes > 0 else {
            return HeartRateZoneDistribution(zone1Minutes: 0, zone2Minutes: 0, zone3Minutes: 0, zone4Minutes: 0, zone5Minutes: 0)
        }
        var minutes = percents.map { Int((Double($0) / 100 * Double(sessionMinutes)).rounded()) }
        let delta = sessionMinutes - minutes.reduce(0, +)
        if delta != 0 {
            let index = minutes.indices.max(by: { minutes[$0] < minutes[$1] }) ?? 1
            minutes[index] += delta
        }
        return HeartRateZoneDistribution(
            zone1Minutes: minutes[0],
            zone2Minutes: minutes[1],
            zone3Minutes: minutes[2],
            zone4Minutes: minutes[3],
            zone5Minutes: minutes[4]
        )
    }
}

/// BPM upper limits per zone (editable in profile). Zone 5 ends at maxHeartRate.
struct HeartRateZoneThresholds: Codable, Hashable, Sendable {
    var maxHeartRate: Int
    var zone1Upper: Int
    var zone2Upper: Int
    var zone3Upper: Int
    var zone4Upper: Int

    static func standard(maxHeartRate: Int) -> HeartRateZoneThresholds {
        HeartRateZoneThresholds(
            maxHeartRate: maxHeartRate,
            zone1Upper: Int(Double(maxHeartRate) * 0.60),
            zone2Upper: Int(Double(maxHeartRate) * 0.70),
            zone3Upper: Int(Double(maxHeartRate) * 0.80),
            zone4Upper: Int(Double(maxHeartRate) * 0.90)
        )
    }

    /// Zone lower bounds follow the standard % of max HR model.
    func lowerBound(for zone: HeartRateZone) -> Int {
        switch zone {
        case .zone1: Int(Double(maxHeartRate) * 0.50)
        case .zone2: zone1Upper + 1
        case .zone3: zone2Upper + 1
        case .zone4: zone3Upper + 1
        case .zone5: zone4Upper + 1
        }
    }

    func range(for zone: HeartRateZone) -> ClosedRange<Int> {
        switch zone {
        case .zone1:
            return lowerBound(for: .zone1)...zone1Upper
        case .zone2:
            return lowerBound(for: .zone2)...zone2Upper
        case .zone3:
            return lowerBound(for: .zone3)...zone3Upper
        case .zone4:
            return lowerBound(for: .zone4)...zone4Upper
        case .zone5:
            return lowerBound(for: .zone5)...maxHeartRate
        }
    }

    func isValid() -> Bool {
        guard HeartRateZoneCalculator.validMaxHRRange.contains(maxHeartRate) else { return false }
        let bounds = [zone1Upper, zone2Upper, zone3Upper, zone4Upper]
        guard bounds.allSatisfy({ $0 > 0 && $0 < maxHeartRate }) else { return false }
        return zone1Upper < zone2Upper
            && zone2Upper < zone3Upper
            && zone3Upper < zone4Upper
            && zone4Upper < maxHeartRate
    }
}
