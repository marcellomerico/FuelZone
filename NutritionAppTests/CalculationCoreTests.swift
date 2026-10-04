import XCTest
@testable import NutritionApp

@MainActor
final class CalculationCoreTests: XCTestCase {

    private func builtIn() throws -> [Snack] {
        try DefaultSnackLoader.loadBuiltInSnacks()
    }

    private func snack(_ nameKey: String, in snacks: [Snack]) throws -> Snack {
        try XCTUnwrap(snacks.first { $0.nameKey == nameKey }, "Missing \(nameKey)")
    }

    private func plan(
        minutes: Int,
        intensity: SimpleIntensity = .moderate,
        stomach: StomachSensitivity = .moderate,
        snacks: [Snack]
    ) throws -> (FuelingResult, FuelPlanSummary) {
        let result = try FuelingCalculator.calculate(
            FuelingCalculatorInput(
                profile: UserProfile(stomachSensitivity: stomach),
                setup: SessionSetup(durationMinutes: minutes, simpleIntensity: intensity),
                availableSnacks: snacks
            )
        )
        return (result, FuelPlanSummary(result: result))
    }

    // MARK: - SnackComposer

    func testComposer_staysNearCarbTarget_acrossDurationsAndIntensities() throws {
        let snacks = try builtIn()
        for minutes in [45, 60, 90, 120, 180, 240, 300] {
            for intensity in SimpleIntensity.allCases {
                let (result, summary) = try plan(minutes: minutes, intensity: intensity, snacks: snacks)
                let target = result.carbsPerHour
                // One gel is a large share of a short session's total, so allow 25 % above the range.
                XCTAssertLessThanOrEqual(
                    summary.carbsPerHour, target.max * 1.25,
                    "\(minutes) min \(intensity): planned \(summary.carbsPerHour) g/h vs \(target)"
                )
                XCTAssertGreaterThanOrEqual(
                    summary.carbsPerHour, target.min * 0.75,
                    "\(minutes) min \(intensity): planned \(summary.carbsPerHour) g/h vs \(target)"
                )
            }
        }
    }

    func testComposer_fluidsMatchTarget() throws {
        let (result, summary) = try plan(minutes: 120, snacks: try builtIn())
        XCTAssertEqual(summary.fluidsPerHour, result.fluidsPerHourMl.midpoint, accuracy: 60)
    }

    func testComposer_sodiumIsNotWildlyOverPlanned() throws {
        let (result, summary) = try plan(minutes: 180, intensity: .hard, snacks: try builtIn())
        XCTAssertLessThanOrEqual(summary.sodiumPerHour, result.sodiumPerHourMg.max * 1.35)
    }

    func testComposer_withTypicalKit_hitsAllThreeTargets() throws {
        let all = try builtIn()
        let kit = [
            try snack("snack.gel.maurten160", in: all),
            try snack("snack.gel.gu.roctane", in: all),
            try snack("snack.drink.isotonic", in: all),
            try snack("snack.electrolyte.salt.tablet", in: all),
        ]
        let (result, summary) = try plan(minutes: 150, intensity: .hard, snacks: kit)
        XCTAssertTrue(summary.carbsWithinTarget(result.carbsPerHour), "carbs \(summary.carbsPerHour) vs \(result.carbsPerHour)")
        XCTAssertEqual(summary.fluidsPerHour, result.fluidsPerHourMl.midpoint, accuracy: 60)
        XCTAssertLessThanOrEqual(summary.sodiumPerHour, result.sodiumPerHourMg.max * 1.35)
        XCTAssertFalse(summary.packItems.isEmpty)
    }

    func testComposer_onlyWaterWhenNoSnacks() throws {
        let (result, summary) = try plan(minutes: 90, snacks: [])
        XCTAssertTrue(result.timeline.allSatisfy { $0.portions.isEmpty })
        XCTAssertGreaterThan(summary.waterMl, 0)
    }

    func testComposer_ignoresDisabledSnacks() throws {
        var snacks = try builtIn()
        for index in snacks.indices { snacks[index].isEnabled = false }
        let (result, _) = try plan(minutes: 120, snacks: snacks)
        XCTAssertTrue(result.timeline.allSatisfy { $0.portions.isEmpty })
    }

    func testComposer_preferredDrinkIsIsotonic() throws {
        let all = try builtIn()
        let drink = SnackComposer.preferredDrink(in: all)
        XCTAssertEqual(drink?.nameKey, "snack.drink.isotonic")
    }

    func testResult_snapshotsUsedSnacks() throws {
        let (result, _) = try plan(minutes: 120, snacks: try builtIn())
        let referenced = Set(result.timeline.flatMap(\.portions).map(\.snackID))
        XCTAssertEqual(Set(result.usedSnacks.map(\.id)), referenced)
    }

    func testShortSession_hasNoSnacks() throws {
        let (result, _) = try plan(minutes: 20, snacks: try builtIn())
        XCTAssertTrue(result.timeline.allSatisfy { $0.portions.isEmpty })
        XCTAssertTrue(result.warningKeys.contains("warning.session_too_short"))
    }

    // MARK: - Stomach sensitivity

    func testTolerantStomach_allowsMoreInLongSessions() throws {
        let moderate = try plan(minutes: 240, intensity: .hard, stomach: .moderate, snacks: []).0
        let tolerant = try plan(minutes: 240, intensity: .hard, stomach: .tolerant, snacks: []).0
        let conservative = try plan(minutes: 240, intensity: .hard, stomach: .conservative, snacks: []).0
        XCTAssertEqual(moderate.carbsPerHour.midpoint, 90, accuracy: 1)
        XCTAssertEqual(tolerant.carbsPerHour.midpoint, 99, accuracy: 1)
        XCTAssertEqual(conservative.carbsPerHour.midpoint, 76.5, accuracy: 1)
    }

    func testTolerantStomach_noChangeInShortSessions() throws {
        let moderate = try plan(minutes: 90, stomach: .moderate, snacks: []).0
        let tolerant = try plan(minutes: 90, stomach: .tolerant, snacks: []).0
        XCTAssertEqual(moderate.carbsPerHour, tolerant.carbsPerHour)
    }

    // MARK: - Limits & validation

    func testCalculator_rejectsDurationsOutsideRange() {
        for minutes in [0, 5, 1441, 100_000] {
            XCTAssertThrowsError(
                try FuelingCalculator.calculate(
                    FuelingCalculatorInput(profile: UserProfile(), setup: SessionSetup(durationMinutes: minutes))
                ),
                "\(minutes) min should be rejected"
            )
        }
    }

    func testInputParsing() {
        XCTAssertEqual(InputParsing.decimal("10,5"), 10.5)
        XCTAssertEqual(InputParsing.decimal(" 7.25 "), 7.25)
        XCTAssertNil(InputParsing.decimal("abc"))
        XCTAssertEqual(InputParsing.weightKg("70"), 70)
        XCTAssertNil(InputParsing.weightKg("-5"))
        XCTAssertNil(InputParsing.weightKg("900"))
        XCTAssertEqual(InputParsing.maxHeartRate("188"), 188)
        XCTAssertNil(InputParsing.maxHeartRate("30"))
        XCTAssertNil(InputParsing.nonNegative("-1"))
    }

    func testPlanPreview_matchesCalculator() throws {
        let vm = SessionViewModel()
        vm.setup = SessionSetup(durationMinutes: 150, simpleIntensity: .hard)
        let preview = try XCTUnwrap(vm.planPreview(profile: UserProfile()))
        let result = try FuelingCalculator.calculate(FuelingCalculatorInput(profile: UserProfile(), setup: vm.setup))
        XCTAssertEqual(Double(preview.carbsPerHour), result.carbsPerHour.midpoint, accuracy: 1)
        XCTAssertEqual(Double(preview.fluidsPerHourMl), result.fluidsPerHourMl.midpoint, accuracy: 1)
    }

    func testPlanPreview_nilForInvalidDuration() {
        let vm = SessionViewModel()
        vm.setup = SessionSetup(durationMinutes: 2)
        XCTAssertNil(vm.planPreview(profile: UserProfile()))
    }

    // MARK: - Open Food Facts

    func testServingAmountParsing() {
        XCTAssertEqual(OpenFoodFactsClient.servingAmount(from: "1 bar (40 g)")?.amount, 40)
        XCTAssertEqual(OpenFoodFactsClient.servingAmount(from: "40g")?.amount, 40)
        XCTAssertEqual(OpenFoodFactsClient.servingAmount(from: "2 x 25 g")?.amount, 50)
        XCTAssertEqual(OpenFoodFactsClient.servingAmount(from: "30,5 g")?.amount, 30.5)
        let bottle = OpenFoodFactsClient.servingAmount(from: "1 bottle (500 ml)")
        XCTAssertEqual(bottle?.amount, 500)
        XCTAssertEqual(bottle?.isLiquid, true)
        XCTAssertEqual(OpenFoodFactsClient.servingAmount(from: "33 cl")?.amount, 330)
        XCTAssertNil(OpenFoodFactsClient.servingAmount(from: "1 piece"))
    }

    // MARK: - Backwards compatibility

    func testDecodesResultSavedBeforeRedesign() throws {
        let legacy = """
        {"id":"\(UUID().uuidString)","sessionDurationMinutes":60,
         "carbsPerHour":{"min":28,"max":32},"totalCarbsGrams":{"min":28,"max":32},
         "fluidsPerHourMl":{"min":540,"max":660},"totalFluidsMl":600,
         "sodiumPerHourMg":{"min":270,"max":330},"totalSodiumMg":300,
         "timeline":[{"id":"\(UUID().uuidString)","startMinute":0,"endMinute":20,"targetCarbsGrams":10,
           "targetSodiumMg":100,"targetFluidsMl":200,"portions":[],"isUserModified":false}],
         "warningKeys":[]}
        """
        let result = try JSONDecoder().decode(FuelingResult.self, from: Data(legacy.utf8))
        XCTAssertEqual(result.timeline.first?.waterMl, 0)
        XCTAssertTrue(result.usedSnacks.isEmpty)
    }
}
