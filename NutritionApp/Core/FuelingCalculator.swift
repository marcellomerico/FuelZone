import Foundation

struct FuelingCalculatorInput: Sendable {
    var profile: UserProfile
    var setup: SessionSetup
    var availableSnacks: [Snack]

    init(
        profile: UserProfile,
        setup: SessionSetup,
        availableSnacks: [Snack] = []
    ) {
        self.profile = profile
        self.setup = setup
        self.availableSnacks = availableSnacks
    }
}

/// Pure fueling math — no SwiftUI dependencies.
enum FuelingCalculator {
    private static let defaultWeightKg = 70.0
    private static let simpleBaselineCarbsPerKgPerHour = 0.6

    static func calculate(_ input: FuelingCalculatorInput) throws -> FuelingResult {
        guard let durationMinutes = input.setup.resolvedDurationMinutes(), durationMinutes > 0 else {
            throw FuelingCalculatorError.invalidDuration
        }

        if input.setup.intensityMode == .zoneBased, !input.setup.zoneDistribution.isValid {
            throw FuelingCalculatorError.invalidZoneDistribution
        }

        var warningKeys: [String] = []
        let weightKg = resolvedWeight(from: input.profile, warnings: &warningKeys)

        let rawCarbsPerHour = carbsPerHour(
            weightKg: weightKg,
            setup: input.setup,
            durationMinutes: durationMinutes
        )

        let (carbsPerHour, stomachCapped) = applyStomachCap(
            rawCarbsPerHour: rawCarbsPerHour,
            sensitivity: input.profile.stomachSensitivity
        )
        if stomachCapped {
            warningKeys.append("warning.stomach_cap_applied")
        }

        let carbsRange: NutritionRange
        if durationMinutes < AppConstants.minimumFuelingSessionMinutes {
            warningKeys.append("warning.session_too_short")
            carbsRange = NutritionRange(min: 0, max: 15)
        } else {
            carbsRange = NutritionRange
                .centered(value: carbsPerHour, spreadFraction: AppConstants.carbRangeSpread)
                .rounded(toPlaces: 0)
        }

        let hours = Double(durationMinutes) / 60.0
        let totalCarbs = NutritionRange
            .centered(value: carbsPerHour * hours, spreadFraction: AppConstants.carbRangeSpread)
            .rounded(toPlaces: 0)

        let fluidsPerHour = fluidsPerHourMl(
            sweatRate: input.profile.sweatRate,
            temperature: input.setup.temperature,
            conditions: input.setup.conditions
        )
        let fluidsRange = NutritionRange
            .centered(value: Double(fluidsPerHour), spreadFraction: AppConstants.fluidRangeSpread)
            .rounded(toPlaces: 0)
        let totalFluids = Int((Double(fluidsPerHour) * hours).rounded())

        let sodiumPerHour = Double(fluidsPerHour) / 1000.0 * Double(input.profile.sweatSaltiness.sodiumMgPerLiter)
        let sodiumRange = NutritionRange
            .centered(value: sodiumPerHour, spreadFraction: AppConstants.sodiumRangeSpread)
            .rounded(toPlaces: 0)
        let totalSodium = Int((sodiumPerHour * hours).rounded())

        var timeline = buildTimeline(
            durationMinutes: durationMinutes,
            carbsPerHour: carbsPerHour,
            sodiumPerHour: sodiumPerHour,
            fluidsPerHour: fluidsPerHour
        )

        if !input.availableSnacks.isEmpty {
            SnackComposer.compose(steps: &timeline, availableSnacks: input.availableSnacks)
        }

        return FuelingResult(
            sessionDurationMinutes: durationMinutes,
            carbsPerHour: carbsRange,
            totalCarbsGrams: totalCarbs,
            fluidsPerHourMl: fluidsRange,
            totalFluidsMl: totalFluids,
            sodiumPerHourMg: sodiumRange,
            totalSodiumMg: totalSodium,
            timeline: timeline,
            warningKeys: warningKeys
        )
    }

    // MARK: - Carbohydrates

    private static func carbsPerHour(
        weightKg: Double,
        setup: SessionSetup,
        durationMinutes: Int
    ) -> Double {
        let intensityFactor: Double
        switch setup.intensityMode {
        case .simple:
            intensityFactor = simpleBaselineCarbsPerKgPerHour * setup.simpleIntensity.carbMultiplier
        case .zoneBased:
            intensityFactor = setup.zoneDistribution.weightedCarbFactorPerKgPerHour
        }

        let base = weightKg * intensityFactor * durationMultiplier(minutes: durationMinutes)

        if durationMinutes < AppConstants.minimumFuelingSessionMinutes {
            return min(base, 15)
        }

        return base
    }

    private static func durationMultiplier(minutes: Int) -> Double {
        switch minutes {
        case ..<30:
            return 0.5
        case 30..<90:
            return 1.0
        case 90..<180:
            return 1.05
        default:
            return 1.1
        }
    }

    private static func applyStomachCap(
        rawCarbsPerHour: Double,
        sensitivity: StomachSensitivity
    ) -> (value: Double, capped: Bool) {
        let ceiling = AppConstants.maxCarbsPerHour * sensitivity.stomachCapMultiplier
        if rawCarbsPerHour > ceiling {
            return (ceiling, true)
        }
        return (rawCarbsPerHour, false)
    }

    // MARK: - Fluids & sodium

    private static func fluidsPerHourMl(
        sweatRate: SweatRate,
        temperature: TemperatureLevel,
        conditions: WeatherCondition
    ) -> Int {
        let value = Double(sweatRate.baselineMlPerHour)
            * temperature.fluidMultiplier
            * conditions.fluidMultiplier
        return Int(value.rounded())
    }

    // MARK: - Timeline

    private static func buildTimeline(
        durationMinutes: Int,
        carbsPerHour: Double,
        sodiumPerHour: Double,
        fluidsPerHour: Int
    ) -> [TimelineStep] {
        let step = AppConstants.timelineStepMinutes
        var steps: [TimelineStep] = []
        var start = 0

        while start < durationMinutes {
            let end = min(start + step, durationMinutes)
            let fraction = Double(end - start) / 60.0

            steps.append(
                TimelineStep(
                    startMinute: start,
                    endMinute: end,
                    targetCarbsGrams: carbsPerHour * fraction,
                    targetSodiumMg: sodiumPerHour * fraction,
                    targetFluidsMl: Int((Double(fluidsPerHour) * fraction).rounded())
                )
            )
            start = end
        }

        return steps
    }

    private static func resolvedWeight(
        from profile: UserProfile,
        warnings: inout [String]
    ) -> Double {
        if let weightKg = profile.weightKg, weightKg > 0 {
            return weightKg
        }
        warnings.append("warning.default_weight_used")
        return defaultWeightKg
    }
}
