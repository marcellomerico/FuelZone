import Foundation

/// Derives HR zone thresholds and default time-in-zone mix from max heart rate.
enum HeartRateZoneCalculator {
    static let validMaxHRRange = 100...220

    static func thresholds(maxHeartRate: Int) -> HeartRateZoneThresholds? {
        guard validMaxHRRange.contains(maxHeartRate) else { return nil }
        return HeartRateZoneThresholds.standard(maxHeartRate: maxHeartRate)
    }

    /// Standard endurance mix when the user taps "Calculate zones".
    static func defaultDistribution(sessionMinutes: Int) -> HeartRateZoneDistribution {
        HeartRateZoneDistribution.default(forSessionMinutes: sessionMinutes)
    }

    static func bpmLabel(for zone: HeartRateZone, thresholds: HeartRateZoneThresholds) -> String {
        let range = thresholds.range(for: zone)
        return L10n.format("session.zone.bpmRange", "\(range.lowerBound)", "\(range.upperBound)")
    }
}
