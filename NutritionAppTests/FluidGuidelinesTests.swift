import XCTest
@testable import NutritionApp

@MainActor
final class FluidGuidelinesTests: XCTestCase {
    private func fluids(
        intensity: SimpleIntensity = .moderate,
        temperature: TemperatureLevel = .mild,
        conditions: WeatherCondition = .dry,
        sweat: SweatRate = .moderate,
        weight: Double? = nil
    ) -> FluidGuidelines.Estimate {
        FluidGuidelines.estimate(
            profile: UserProfile(weightKg: weight, sweatRate: sweat),
            setup: SessionSetup(durationMinutes: 120, simpleIntensity: intensity, temperature: temperature, conditions: conditions),
            durationMinutes: 120
        )
    }

    func testHarderSessionsNeedMoreFluid() {
        let easy = fluids(intensity: .easy).mlPerHour
        let moderate = fluids(intensity: .moderate).mlPerHour
        let hard = fluids(intensity: .hard).mlPerHour
        XCTAssertLessThan(easy, moderate)
        XCTAssertLessThan(moderate, hard)
        XCTAssertEqual(moderate, 600)
    }

    func testHeatNeedsMoreFluid() {
        XCTAssertGreaterThan(fluids(temperature: .hot).mlPerHour, fluids(temperature: .mild).mlPerHour)
    }

    func testIntakeIsCappedToAvoidOverdrinking() {
        let extreme = fluids(intensity: .hard, temperature: .hot, conditions: .windy, sweat: .high, weight: 95)
        XCTAssertEqual(extreme.mlPerHour, Int(FluidGuidelines.maximumMlPerHour))
        XCTAssertTrue(extreme.wasCapped)
        let small = fluids(intensity: .easy, temperature: .cool, sweat: .low, weight: 45)
        XCTAssertGreaterThanOrEqual(small.mlPerHour, Int(FluidGuidelines.minimumMlPerHour))
    }

    func testBodyWeightAdjustmentIsModest() {
        XCTAssertEqual(FluidGuidelines.weightFactor(nil), 1.0)
        XCTAssertEqual(FluidGuidelines.weightFactor(70), 1.0, accuracy: 0.001)
        XCTAssertEqual(FluidGuidelines.weightFactor(40), 0.9)
        XCTAssertEqual(FluidGuidelines.weightFactor(120), 1.1)
    }

    func testZoneMixScalesFluid() {
        var setup = SessionSetup(durationMinutes: 60, intensityMode: .zoneBased)
        setup.zoneDistribution = HeartRateZoneDistribution(zone1Minutes: 60, zone2Minutes: 0, zone3Minutes: 0, zone4Minutes: 0, zone5Minutes: 0)
        let easy = FluidGuidelines.intensityFactor(setup: setup, durationMinutes: 60)
        setup.zoneDistribution = HeartRateZoneDistribution(zone1Minutes: 0, zone2Minutes: 0, zone3Minutes: 0, zone4Minutes: 30, zone5Minutes: 30)
        let hard = FluidGuidelines.intensityFactor(setup: setup, durationMinutes: 60)
        XCTAssertLessThan(easy, hard)
    }

    func testCalculatorWarnsWhenFluidIsCapped() throws {
        let result = try FuelingCalculator.calculate(FuelingCalculatorInput(
            profile: UserProfile(weightKg: 90, sweatRate: .high),
            setup: SessionSetup(durationMinutes: 180, simpleIntensity: .hard, temperature: .hot, conditions: .windy)
        ))
        XCTAssertTrue(result.warningKeys.contains("warning.fluid_cap"))
        XCTAssertEqual(result.fluidsPerHourMl.midpoint, 1000, accuracy: 1)
    }

    func testSodiumFollowsFluid() throws {
        let easy = try FuelingCalculator.calculate(FuelingCalculatorInput(profile: UserProfile(), setup: SessionSetup(durationMinutes: 120, simpleIntensity: .easy)))
        let hard = try FuelingCalculator.calculate(FuelingCalculatorInput(profile: UserProfile(), setup: SessionSetup(durationMinutes: 120, simpleIntensity: .hard)))
        XCTAssertLessThan(easy.sodiumPerHourMg.midpoint, hard.sodiumPerHourMg.midpoint)
    }

    // MARK: - Onboarding for existing users

    func testExistingUsersSeeNewOnboardingOnce() {
        let defaults = TestStores.freshDefaults()
        let profile = UserProfile(hasCompletedOnboarding: true)
        XCTAssertTrue(AppState.needsOnboarding(profile: profile, defaults: defaults), "Users of the old version see the new onboarding once")
        defaults.set(AppState.currentOnboardingVersion, forKey: AppState.onboardingVersionKey)
        XCTAssertFalse(AppState.needsOnboarding(profile: profile, defaults: defaults))
        XCTAssertTrue(AppState.needsOnboarding(profile: UserProfile(), defaults: defaults), "New profiles always need it")
    }

    func testSettingChangeClearsValidationError() {
        let vm = SessionViewModel(store: TestStores.make())
        vm.setup.durationInputMode = .distanceAndTime
        vm.setup.distanceKm = nil
        XCTAssertNil(vm.calculatePlan())
        XCTAssertNotNil(vm.errorMessage)
        vm.setup.durationInputMode = .duration
        XCTAssertNil(vm.errorMessage)
    }
}
