import XCTest
@testable import NutritionApp

final class FuelingCalculatorTests: XCTestCase {

    private let weightKg = 70.0

    private func profile(
        stomach: StomachSensitivity = .moderate,
        sweatRate: SweatRate = .moderate,
        saltiness: SweatSaltiness = .moderate
    ) -> UserProfile {
        UserProfile(
            weightKg: weightKg,
            stomachSensitivity: stomach,
            sweatRate: sweatRate,
            sweatSaltiness: saltiness
        )
    }

    private func setup(
        minutes: Int,
        intensityMode: IntensityMode = .simple,
        simple: SimpleIntensity = .moderate,
        zones: HeartRateZoneDistribution = .default,
        temperature: TemperatureLevel = .mild,
        conditions: WeatherCondition = .dry
    ) -> SessionSetup {
        SessionSetup(
            durationInputMode: .duration,
            durationMinutes: minutes,
            intensityMode: intensityMode,
            simpleIntensity: simple,
            zoneDistribution: zones,
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
                setup: setup(minutes: 300),
                availableSnacks: snacks
            )
        )

        XCTAssertEqual(result.sessionDurationMinutes, 300)
        XCTAssertEqual(result.timeline.count, 15)
        XCTAssertGreaterThan(result.totalCarbsGrams.midpoint, 200)
        XCTAssertGreaterThan(result.totalFluidsMl, 2000)
        XCTAssertFalse(result.timeline.allSatisfy { $0.portions.isEmpty })
    }

    func testZoneBased_100PercentZone2() throws {
        let zones = HeartRateZoneDistribution(
            zone1Percent: 0,
            zone2Percent: 100,
            zone3Percent: 0,
            zone4Percent: 0,
            zone5Percent: 0
        )
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(),
                setup: setup(minutes: 90, intensityMode: .zoneBased, zones: zones)
            )
        )

        // 70 kg × 0.6 g/kg/h (Z2) × 1.05 duration ≈ 44 g/h
        XCTAssertEqual(result.carbsPerHour.midpoint, 44, accuracy: 2)
        XCTAssertFalse(result.warningKeys.contains("warning.stomach_cap_applied"))
    }

    func testConservativeStomach_hotConditions() throws {
        let zones = HeartRateZoneDistribution(
            zone1Percent: 0,
            zone2Percent: 0,
            zone3Percent: 0,
            zone4Percent: 50,
            zone5Percent: 50
        )
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: profile(stomach: .conservative, sweatRate: .high),
                setup: setup(
                    minutes: 120,
                    intensityMode: .zoneBased,
                    zones: zones,
                    temperature: .hot,
                    conditions: .humid
                )
            )
        )

        XCTAssertTrue(result.warningKeys.contains("warning.stomach_cap_applied"))
        // Cap: 90 × 0.85 = 76.5 g/h (midpoint before range spread)
        XCTAssertEqual(result.carbsPerHour.midpoint, 76.5, accuracy: 0.5)
        // High sweat + hot + humid → elevated fluids
        XCTAssertGreaterThanOrEqual(result.fluidsPerHourMl.midpoint, 900)
    }

    func testZoneBased_intervalsHeavy_zone4zone5() throws {
        let heavy = HeartRateZoneDistribution(
            zone1Percent: 0,
            zone2Percent: 0,
            zone3Percent: 0,
            zone4Percent: 60,
            zone5Percent: 40
        )
        let zone2Only = HeartRateZoneDistribution(
            zone1Percent: 0,
            zone2Percent: 100,
            zone3Percent: 0,
            zone4Percent: 0,
            zone5Percent: 0
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

    // MARK: - Validation & snacks

    func testInvalidZoneDistributionThrows() {
        let invalid = HeartRateZoneDistribution(
            zone1Percent: 30,
            zone2Percent: 30,
            zone3Percent: 30,
            zone4Percent: 0,
            zone5Percent: 0
        )
        XCTAssertThrowsError(
            try FuelingCalculator.calculate(
                FuelingCalculatorInput(
                    profile: profile(),
                    setup: setup(minutes: 60, intensityMode: .zoneBased, zones: invalid)
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
