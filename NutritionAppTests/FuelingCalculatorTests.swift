import XCTest
@testable import NutritionApp

final class FuelingCalculatorTests: XCTestCase {

    private func profile(
        stomach: StomachSensitivity = .moderate,
        sweatRate: SweatRate = .moderate,
        saltiness: SweatSaltiness = .moderate
    ) -> UserProfile {
        UserProfile(
            weightKg: 70,
            stomachSensitivity: stomach,
            sweatRate: sweatRate,
            sweatSaltiness: saltiness
        )
    }

    private func setup(
        minutes: Int,
        intensityMode: IntensityMode = .simple,
        simple: SimpleIntensity = .moderate,
        zones: HeartRateZoneDistribution? = nil,
        temperature: TemperatureLevel = .mild,
        conditions: WeatherCondition = .dry
    ) -> SessionSetup {
        SessionSetup(
            durationInputMode: .duration,
            durationMinutes: minutes,
            intensityMode: intensityMode,
            simpleIntensity: simple,
            zoneDistribution: zones ?? .default(forSessionMinutes: minutes),
            temperature: temperature,
            conditions: conditions
        )
    }

    // MARK: - Required scenarios

    func testShortSession_under30Minutes() throws {
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: profile(), setup: setup(minutes: 25))
        )

        XCTAssertEqual(result.sessionDurationMinutes, 25)
        XCTAssertTrue(result.warningKeys.contains("warning.session_too_short"))
        XCTAssertLessThanOrEqual(result.carbsPerHour.max, 15)
        XCTAssertLessThanOrEqual(result.timeline.count, 2)
    }

    func testUltraSession_5hours() throws {
        let snacks = try DefaultSnackLoader.loadBuiltInSnacks()
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 300, simple: .hard),
                availableSnacks: snacks
            )
        )

        XCTAssertEqual(result.sessionDurationMinutes, 300)
        XCTAssertEqual(result.timeline.count, 15)
        // 90 g/h tier × 1.0 intensity (hard)
        XCTAssertEqual(result.carbsPerHour.midpoint, 90, accuracy: 2)
        XCTAssertGreaterThan(result.totalCarbsGrams.midpoint, 400)
        XCTAssertGreaterThan(result.totalFluidsMl, 2000)
        XCTAssertFalse(result.timeline.allSatisfy { $0.portions.isEmpty })
        XCTAssertTrue(result.warningKeys.contains("warning.multiple_transportable_carbs"))
    }

    func testZoneBased_moderate90Minutes() throws {
        let zones = HeartRateZoneDistribution(
            zone1Minutes: 0,
            zone2Minutes: 90,
            zone3Minutes: 0,
            zone4Minutes: 0,
            zone5Minutes: 0
        )
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 90, intensityMode: .zoneBased, zones: zones)
            )
        )

        // 60 g/h base × 0.85 (zone 2) ≈ 51 g/h
        XCTAssertEqual(result.carbsPerHour.midpoint, 51, accuracy: 2)
        XCTAssertFalse(result.warningKeys.contains("warning.stomach_cap_applied"))
    }

    func testConservativeStomach_ultraSession() throws {
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(stomach: .conservative),
                setup: setup(minutes: 300, simple: .hard)
            )
        )

        XCTAssertTrue(result.warningKeys.contains("warning.stomach_cap_applied"))
        // Cap: 90 × 0.85 = 76.5 g/h
        XCTAssertEqual(result.carbsPerHour.midpoint, 76.5, accuracy: 0.5)
    }

    func testZoneBased_intervalsHeavy_zone4zone5() throws {
        let heavy = HeartRateZoneDistribution(
            zone1Minutes: 0,
            zone2Minutes: 0,
            zone3Minutes: 0,
            zone4Minutes: 54,
            zone5Minutes: 36
        )
        let zone2Only = HeartRateZoneDistribution(
            zone1Minutes: 0,
            zone2Minutes: 90,
            zone3Minutes: 0,
            zone4Minutes: 0,
            zone5Minutes: 0
        )

        let heavyResult = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 90, intensityMode: .zoneBased, zones: heavy)
            )
        )
        let easyResult = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 90, intensityMode: .zoneBased, zones: zone2Only)
            )
        )

        XCTAssertGreaterThan(
            heavyResult.carbsPerHour.midpoint,
            easyResult.carbsPerHour.midpoint
        )
    }

    func testWeightDoesNotChangeCarbTarget() throws {
        let light = UserProfile(weightKg: 55, stomachSensitivity: .moderate)
        let heavy = UserProfile(weightKg: 95, stomachSensitivity: .moderate)
        let session = setup(minutes: 90, simple: .moderate)

        let lightResult = try FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: light, setup: session)
        )
        let heavyResult = try FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: heavy, setup: session)
        )

        XCTAssertEqual(
            lightResult.carbsPerHour.midpoint,
            heavyResult.carbsPerHour.midpoint,
            accuracy: 0.01
        )
    }

    // MARK: - Validation & snacks

    func testInvalidZoneDistributionThrows() {
        // Zone minutes must sum to session duration (90 min), not 60.
        let invalid = HeartRateZoneDistribution(
            zone1Minutes: 20,
            zone2Minutes: 20,
            zone3Minutes: 20,
            zone4Minutes: 0,
            zone5Minutes: 0
        )
        XCTAssertThrowsError(
            try FuelingCalculator.calculate(
                FuelingCalculatorInput(
                    profile: profile(),
                    setup: setup(minutes: 90, intensityMode: .zoneBased, zones: invalid)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FuelingCalculatorError, .invalidZoneDistribution)
        }
    }

    func testSnackComposer_matchesCarbTargetsWithinTolerance() throws {
        let snacks = try DefaultSnackLoader.loadBuiltInSnacks()
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 60),
                availableSnacks: snacks
            )
        )

        for step in result.timeline {
            let stepCarbs = step.portions.compactMap { portion -> Double? in
                guard let snack = snacks.first(where: { $0.id == portion.snackID }) else { return nil }
                return portion.totalCarbs(for: snack)
            }.reduce(0, +)

            XCTAssertGreaterThanOrEqual(stepCarbs, step.targetCarbsGrams * 0.7)
        }
    }

    func testSodiumDerivedFromFluidAndSaltiness() throws {
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(saltiness: .moderate),
                setup: setup(minutes: 60)
            )
        )

        let expectedPerHour = Double(result.fluidsPerHourMl.midpoint) / 1000.0 * 500.0
        XCTAssertEqual(result.sodiumPerHourMg.midpoint, expectedPerHour, accuracy: 5)
    }
}
