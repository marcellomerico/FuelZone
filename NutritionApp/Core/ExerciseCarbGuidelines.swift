import Foundation

/// Evidence-based carbohydrate targets during exercise (Jeukendrup 2014; Burke et al. 2011).
/// Values are absolute grams per hour — not scaled by body weight.
enum ExerciseCarbGuidelines {
    /// Sessions under ~75 min: ~30 g/h (mouth rinse / small amounts often sufficient).
    static let shortSessionUpperMinutes = 75
    /// Sessions under ~2.5 h: ~60 g/h (single transportable CHO oxidation ceiling).
    static let mediumSessionUpperMinutes = 150

    static let minimumIntensityScale = 0.65
    static let maximumIntensityScale = 1.0

    enum DurationTier: String, Sendable {
        case underMinimum
        case short
        case medium
        case long

        var localizationKey: String {
            switch self {
            case .underMinimum: "methodology.tier.underMinimum"
            case .short: "methodology.tier.short"
            case .medium: "methodology.tier.medium"
            case .long: "methodology.tier.long"
            }
        }
    }

    static func durationTier(for minutes: Int) -> DurationTier {
        switch minutes {
        case ..<AppConstants.minimumFuelingSessionMinutes:
            return .underMinimum
        case ..<shortSessionUpperMinutes:
            return .short
        case ..<mediumSessionUpperMinutes:
            return .medium
        default:
            return .long
        }
    }

    /// Base target (g/h) from session duration before intensity scaling.
    static func baseCarbsPerHour(durationMinutes: Int) -> Double {
        switch durationTier(for: durationMinutes) {
        case .underMinimum:
            return 0
        case .short:
            return 30
        case .medium:
            return 60
        case .long:
            return 90
        }
    }

    static func intensityScale(simpleIntensity: SimpleIntensity) -> Double {
        simpleIntensity.intensityScale
    }

    static func intensityScale(
        zoneDistribution: HeartRateZoneDistribution,
        sessionDurationMinutes: Int
    ) -> Double {
        zoneDistribution.weightedIntensityScale(sessionDurationMinutes: sessionDurationMinutes)
    }

    /// Recommended carbohydrate intake (g/h) before stomach sensitivity cap.
    static func recommendedCarbsPerHour(
        durationMinutes: Int,
        intensityScale: Double
    ) -> Double {
        guard durationMinutes >= AppConstants.minimumFuelingSessionMinutes else {
            return min(15, baseCarbsPerHour(durationMinutes: durationMinutes))
        }

        let base = baseCarbsPerHour(durationMinutes: durationMinutes)
        let clampedScale = min(maximumIntensityScale, max(minimumIntensityScale, intensityScale))
        return base * clampedScale
    }

    static func needsMultipleTransportableCarbsWarning(
        durationMinutes: Int,
        carbsPerHour: Double
    ) -> Bool {
        durationMinutes >= mediumSessionUpperMinutes
            && carbsPerHour >= 75
    }
}
