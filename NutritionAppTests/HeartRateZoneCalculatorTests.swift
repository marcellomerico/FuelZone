import XCTest
@testable import NutritionApp

final class HeartRateZoneCalculatorTests: XCTestCase {
    func testThresholds_validMaxHR() {
        let t = HeartRateZoneCalculator.thresholds(maxHeartRate: 190)
        XCTAssertNotNil(t)
        XCTAssertEqual(t?.maxHeartRate, 190)
        XCTAssertEqual(t?.zone2Upper, 133)
    }

    func testThresholds_invalidMaxHR() {
        XCTAssertNil(HeartRateZoneCalculator.thresholds(maxHeartRate: 90))
        XCTAssertNil(HeartRateZoneCalculator.thresholds(maxHeartRate: 250))
    }

    func testDefaultDistributionMatchesSessionDuration() {
        let d = HeartRateZoneDistribution.default(forSessionMinutes: 60)
        XCTAssertTrue(d.isValid(sessionDurationMinutes: 60))
        XCTAssertEqual(d.totalMinutes, 60)
    }
}
