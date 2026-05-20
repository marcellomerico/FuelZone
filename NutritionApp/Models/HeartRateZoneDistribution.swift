import Foundation

/// Percentage of session time spent in each HR zone (must sum to 100).
struct HeartRateZoneDistribution: Codable, Hashable, Sendable {
    var zone1Percent: Double
    var zone2Percent: Double
    var zone3Percent: Double
    var zone4Percent: Double
    var zone5Percent: Double

    static let `default` = HeartRateZoneDistribution(
        zone1Percent: 10,
        zone2Percent: 50,
        zone3Percent: 25,
        zone4Percent: 10,
        zone5Percent: 5
    )

    var totalPercent: Double {
        zone1Percent + zone2Percent + zone3Percent + zone4Percent + zone5Percent
    }

    var isValid: Bool {
        abs(totalPercent - 100) < 0.5
    }

    func percent(for zone: HeartRateZone) -> Double {
        switch zone {
        case .zone1: zone1Percent
        case .zone2: zone2Percent
        case .zone3: zone3Percent
        case .zone4: zone4Percent
        case .zone5: zone5Percent
        }
    }

    /// Weighted carbohydrate factor (g/kg/h) from zone mix.
    var weightedCarbFactorPerKgPerHour: Double {
        HeartRateZone.allCases.reduce(0) { partial, zone in
            partial + (percent(for: zone) / 100) * zone.carbFactorPerKgPerHour
        }
    }
}

/// BPM boundaries per zone, derived from max heart rate.
struct HeartRateZoneThresholds: Codable, Hashable, Sendable {
    let maxHeartRate: Int
    let zone1Upper: Int
    let zone2Upper: Int
    let zone3Upper: Int
    let zone4Upper: Int

    static func standard(maxHeartRate: Int) -> HeartRateZoneThresholds {
        HeartRateZoneThresholds(
            maxHeartRate: maxHeartRate,
            zone1Upper: Int(Double(maxHeartRate) * 0.60),
            zone2Upper: Int(Double(maxHeartRate) * 0.70),
            zone3Upper: Int(Double(maxHeartRate) * 0.80),
            zone4Upper: Int(Double(maxHeartRate) * 0.90)
        )
    }

    func range(for zone: HeartRateZone) -> ClosedRange<Int> {
        switch zone {
        case .zone1:
            let lower = Int(Double(maxHeartRate) * 0.50)
            return lower...zone1Upper
        case .zone2:
            return (zone1Upper + 1)...zone2Upper
        case .zone3:
            return (zone2Upper + 1)...zone3Upper
        case .zone4:
            return (zone3Upper + 1)...zone4Upper
        case .zone5:
            return (zone4Upper + 1)...maxHeartRate
        }
    }
}
