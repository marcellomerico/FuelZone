import XCTest
@testable import NutritionApp

final class ExerciseCarbGuidelinesTests: XCTestCase {

    func testBaseCarbs_durationTiers() {
        XCTAssertEqual(ExerciseCarbGuidelines.baseCarbsPerHour(durationMinutes: 25), 0)
        XCTAssertEqual(ExerciseCarbGuidelines.baseCarbsPerHour(durationMinutes: 45), 30)
        XCTAssertEqual(ExerciseCarbGuidelines.baseCarbsPerHour(durationMinutes: 90), 60)
        XCTAssertEqual(ExerciseCarbGuidelines.baseCarbsPerHour(durationMinutes: 180), 90)
    }

    func testRecommendedCarbs_scalesWithIntensity() {
        let full = ExerciseCarbGuidelines.recommendedCarbsPerHour(
            durationMinutes: 90,
            intensityScale: 1.0
        )
        let easy = ExerciseCarbGuidelines.recommendedCarbsPerHour(
            durationMinutes: 90,
            intensityScale: 0.70
        )
        XCTAssertEqual(full, 60, accuracy: 0.01)
        XCTAssertEqual(easy, 42, accuracy: 0.01)
        XCTAssertLessThan(easy, full)
    }

    func testMultipleTransportableWarning() {
        XCTAssertFalse(
            ExerciseCarbGuidelines.needsMultipleTransportableCarbsWarning(
                durationMinutes: 120,
                carbsPerHour: 60
            )
        )
        XCTAssertTrue(
            ExerciseCarbGuidelines.needsMultipleTransportableCarbsWarning(
                durationMinutes: 180,
                carbsPerHour: 85
            )
        )
    }
}
