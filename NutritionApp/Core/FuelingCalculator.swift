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
    static func calculate(_ input: FuelingCalculatorInput) throws -> FuelingResult {
        guard let durationMinutes = input.setup.resolvedDurationMinutes(),
              AppConstants.sessionMinutesRange.contains(durationMinutes) else {
            throw FuelingCalculatorError.invalidDuration
        }

        if input.setup.intensityMode == .zoneBased,
           !input.setup.zoneDistribution.isValid(sessionDurationMinutes: durationMinutes) {
            throw FuelingCalculatorError.invalidZoneDistribution
        }

        var warningKeys: [String] = []

        var rawCarbsPerHour = carbsPerHour(setup: input.setup, durationMinutes: durationMinutes)
        if durationMinutes >= ExerciseCarbGuidelines.mediumSessionUpperMinutes {
            rawCarbsPerHour *= input.profile.stomachSensitivity.longSessionBoost
        }

        let (carbsPerHour, stomachCapped) = applyStomachCap(
            rawCarbsPerHour: rawCarbsPerHour,
            sensitivity: input.profile.stomachSensitivity
        )
        if stomachCapped {
            warningKeys.append("warning.stomach_cap_applied")
        }

        if ExerciseCarbGuidelines.needsMultipleTransportableCarbsWarning(
            durationMinutes: durationMinutes,
            carbsPerHour: carbsPerHour
        ) {
            warningKeys.append("warning.multiple_transportable_carbs")
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

        if durationMinutes >= AppConstants.minimumFuelingSessionMinutes {
            SnackComposer.compose(steps: &timeline, availableSnacks: input.availableSnacks)
        }
        let usedIDs = Set(timeline.flatMap(\.portions).map(\.snackID))
        let usedSnacks = input.availableSnacks.filter { usedIDs.contains($0.id) }

        return FuelingResult(
            sessionDurationMinutes: durationMinutes,
            carbsPerHour: carbsRange,
            totalCarbsGrams: totalCarbs,
            fluidsPerHourMl: fluidsRange,
            totalFluidsMl: totalFluids,
            sodiumPerHourMg: sodiumRange,
            totalSodiumMg: totalSodium,
            timeline: timeline,
            warningKeys: warningKeys,
            usedSnacks: usedSnacks
        )
    }

    // MARK: - Carbohydrates

    private static func carbsPerHour(setup: SessionSetup, durationMinutes: Int) -> Double {
        let intensityScale: Double
        switch setup.intensityMode {
        case .simple:
            intensityScale = ExerciseCarbGuidelines.intensityScale(simpleIntensity: setup.simpleIntensity)
        case .zoneBased:
            intensityScale = ExerciseCarbGuidelines.intensityScale(
                zoneDistribution: setup.zoneDistribution,
                sessionDurationMinutes: durationMinutes
            )
        }

        return ExerciseCarbGuidelines.recommendedCarbsPerHour(
            durationMinutes: durationMinutes,
            intensityScale: intensityScale
        )
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
}
