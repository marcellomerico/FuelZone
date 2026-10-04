import XCTest
@testable import NutritionApp

/// Regression probes written during the code review (see docs/CODE_REVIEW.md).
/// Each test asserts the *correct* behavior, so a failing test documents a confirmed bug.
final class CodeReviewFindingsTests: XCTestCase {

    private func plannedCarbsPerHour(_ result: FuelingResult, snacks: [Snack]) -> Double {
        let total = result.timeline.flatMap(\.portions).reduce(0.0) { sum, portion in
            guard let snack = snacks.first(where: { $0.id == portion.snackID }) else { return sum }
            return sum + portion.totalCarbs(for: snack)
        }
        return total / (Double(result.sessionDurationMinutes) / 60)
    }

    private func plannedFluidsPerHour(_ result: FuelingResult, snacks: [Snack]) -> Double {
        let ml: [String: Double] = ["unit.ml500": 500, "unit.ml330": 330, "unit.ml250": 250]
        let total = result.timeline.flatMap(\.portions).reduce(0.0) { sum, portion in
            guard let snack = snacks.first(where: { $0.id == portion.snackID }),
                  snack.category == .drink else { return sum }
            return sum + (ml[snack.unitKey] ?? 0) * portion.quantity
        }
        return total / (Double(result.sessionDurationMinutes) / 60)
    }

    // MARK: - SnackComposer

    /// Planned snacks should not exceed the carb target by more than ~30 %.
    func testSnackComposer_doesNotGrosslyOvershootCarbTarget() throws {
        let snacks = try DefaultSnackLoader.loadBuiltInSnacks()
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: UserProfile(),
                setup: SessionSetup(durationMinutes: 120, simpleIntensity: .moderate),
                availableSnacks: snacks
            )
        )
        let planned = plannedCarbsPerHour(result, snacks: snacks)
        print("[REVIEW] 120 min moderate: target \(result.carbsPerHour) g/h, planned \(Int(planned)) g/h, fluids planned \(Int(plannedFluidsPerHour(result, snacks: snacks))) ml/h vs target \(result.fluidsPerHourMl)")
        XCTAssertLessThanOrEqual(planned, result.carbsPerHour.max * 1.3)
    }

    /// `bestCarbSnack` intends to allow max. 2 portions of the same snack per step.
    func testSnackComposer_limitsSameSnackToTwoPortionsPerStep() throws {
        let smallGel = Snack(category: .gel, carbsPerServing: 8, sodiumMgPerServing: 200, unitKey: "unit.gel")
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: UserProfile(),
                setup: SessionSetup(durationMinutes: 180, simpleIntensity: .hard),
                availableSnacks: [smallGel]
            )
        )
        let maxPerStep = result.timeline.map { $0.portions.filter { $0.snackID == smallGel.id }.count }.max() ?? 0
        print("[REVIEW] same snack portions in one step: \(maxPerStep)")
        XCTAssertLessThanOrEqual(maxPerStep, 2)
    }

    // MARK: - Stomach sensitivity

    /// "Tolerant" should differ from "moderate" — otherwise the option has no effect.
    func testTolerantStomach_changesResultComparedToModerate() throws {
        let setup = SessionSetup(durationMinutes: 240, simpleIntensity: .hard)
        let moderate = try FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: UserProfile(stomachSensitivity: .moderate), setup: setup)
        )
        let tolerant = try FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: UserProfile(stomachSensitivity: .tolerant), setup: setup)
        )
        print("[REVIEW] moderate \(moderate.carbsPerHour) vs tolerant \(tolerant.carbsPerHour)")
        XCTAssertNotEqual(moderate.carbsPerHour, tolerant.carbsPerHour)
    }

    // MARK: - SessionViewModel

    /// After a failed calculation the previous result must not be reused (would be saved to history again).
    @MainActor
    func testCalculatePlan_failedCalculationClearsLastResult() {
        let vm = SessionViewModel(store: TestStores.make())
        vm.setup = SessionSetup(durationMinutes: 90)
        vm.calculatePlan()
        XCTAssertNotNil(vm.lastResult)

        vm.setup.durationMinutes = nil
        vm.calculatePlan()
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.lastResult, "Stale result is still present after a failed calculation")
    }

    /// No upper bound on duration: a typo creates thousands of timeline steps.
    func testCalculator_rejectsAbsurdDuration() {
        XCTAssertThrowsError(
            try FuelingCalculator.calculate(
                FuelingCalculatorInput(profile: UserProfile(), setup: SessionSetup(durationMinutes: 100_000))
            )
        )
    }

    // MARK: - Snack library

    /// A disabled built-in snack must stay visible in the library so the user can re-enable it.
    @MainActor
    func testDisabledBuiltInSnack_staysVisibleInLibrary() throws {
        let vm = SnackViewModel(store: TestStores.make())
        let snack = try XCTUnwrap(vm.catalogSnacks.first(where: \.isBuiltIn))
        if vm.isInKit(snack) { vm.toggleKit(snack) }
        XCTAssertFalse(vm.isInKit(snack))
        XCTAssertTrue(vm.catalogSnacks.contains { $0.id == snack.id }, "Snack outside the kit disappears from the catalog")
    }

    // MARK: - Onboarding

    @MainActor
    func testOnboarding_buildProfileRejectsInvalidMaxHeartRate() {
        let vm = OnboardingViewModel()
        vm.maxHeartRateText = "30"
        vm.weightText = "-5"
        let profile = vm.buildProfile()
        XCTAssertNil(profile.maxHeartRate, "Invalid max HR 30 accepted")
        XCTAssertNil(profile.weightKg, "Negative weight accepted")
    }

    // MARK: - Localization

    /// `String(localized:)` with a literal must follow the in-app language (custom L10n bundle).
    @MainActor
    func testStringLocalized_literalFollowsInAppLanguage() {
        L10n.updateBundle(for: .german)
        defer { L10n.updateBundle(for: .system) }
        let viaLiteral = String(localized: "onboarding.tagline")
        let viaKey = L10n.string("onboarding.tagline")
        print("[REVIEW] literal: \(viaLiteral) | L10n: \(viaKey)")
        XCTAssertEqual(viaLiteral, viaKey)
    }

    // MARK: - Open Food Facts parsing

    /// "1 bar (40 g)" must be parsed as 40 g, not 140 g.
    func testOpenFoodFacts_servingSizeWithLeadingCount() async throws {
        MockURLProtocol.responseJSON = """
        {"status":1,"product":{"product_name":"Test Bar","serving_size":"1 bar (40 g)",
         "nutriments":{"carbohydrates_100g":60,"sodium_100g":0.2}}}
        """
        URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self) }

        let product = try await OpenFoodFactsClient.fetchProduct(barcode: "4000000000000")
        print("[REVIEW] parsed portion grams: \(String(describing: product.defaultPortionGrams))")
        XCTAssertEqual(product.defaultPortionGrams, 40)
    }
}

final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseJSON = "{}"

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host?.contains("openfoodfacts") == true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(Self.responseJSON.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
