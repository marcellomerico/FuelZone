import Foundation

/// Fluid intake during exercise.
///
/// Sweat rate is driven by metabolic heat production (intensity, body size) and by the environment
/// (Gagnon, Jay & Kenny 2013; ACSM Position Stand 2007: sweat rates ≈ 0.3–2.4 L/h). Intake should
/// limit losses rather than replace them completely: ACSM suggests ≈ 0.4–0.8 L/h, more for larger,
/// faster athletes in the heat. Drinking beyond sweat losses risks hyponatraemia (EAH consensus 2015),
/// so the plan is capped and flags very high estimated losses.
enum FluidGuidelines {
    /// Reference body mass for the size adjustment.
    static let referenceWeightKg = 70.0
    /// The size adjustment stays within ± 10 %.
    static let weightFactorRange = 0.9...1.1
    /// Planned intake never goes below / above these values.
    static let minimumMlPerHour = 300.0
    static let maximumMlPerHour = 1000.0

    struct Estimate: Equatable, Sendable {
        /// Recommended intake (ml/h), already capped.
        var mlPerHour: Int
        /// True when the uncapped estimate exceeded `maximumMlPerHour`.
        var wasCapped: Bool
    }

    static func estimate(profile: UserProfile, setup: SessionSetup, durationMinutes: Int) -> Estimate {
        let raw = Double(profile.sweatRate.baselineMlPerHour)
            * setup.temperature.fluidMultiplier
            * setup.conditions.fluidMultiplier
            * intensityFactor(setup: setup, durationMinutes: durationMinutes)
            * weightFactor(profile.weightKg)
        let clamped = min(max(raw, minimumMlPerHour), maximumMlPerHour)
        return Estimate(mlPerHour: Int((clamped / 10).rounded()) * 10, wasCapped: raw > maximumMlPerHour)
    }

    /// Harder sessions produce more heat and therefore more sweat.
    static func intensityFactor(setup: SessionSetup, durationMinutes: Int) -> Double {
        switch setup.intensityMode {
        case .simple:
            return setup.simpleIntensity.fluidFactor
        case .zoneBased:
            let distribution = setup.zoneDistribution
            let total = Double(distribution.totalMinutes)
            guard total > 0 else { return 1.0 }
            return HeartRateZone.allCases.reduce(0) { sum, zone in
                sum + Double(distribution.minutes(for: zone)) / total * zone.fluidFactor
            }
        }
    }

    /// Larger athletes produce more heat at the same pace; kept modest because size is only a proxy.
    static func weightFactor(_ weightKg: Double?) -> Double {
        guard let weightKg, weightKg > 0 else { return 1.0 }
        let factor = (weightKg / referenceWeightKg).squareRoot()
        return min(max(factor, weightFactorRange.lowerBound), weightFactorRange.upperBound)
    }
}

extension SimpleIntensity {
    /// Relative sweat production compared with a moderate session.
    var fluidFactor: Double {
        switch self {
        case .easy: 0.85
        case .moderate: 1.0
        case .hard: 1.15
        }
    }
}

extension HeartRateZone {
    var fluidFactor: Double {
        switch self {
        case .zone1: 0.8
        case .zone2: 0.9
        case .zone3: 1.0
        case .zone4: 1.1
        case .zone5: 1.2
        }
    }
}
