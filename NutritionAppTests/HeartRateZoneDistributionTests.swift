import XCTest
@testable import NutritionApp

final class HeartRateZoneDistributionTests: XCTestCase {

    func testIsValid_requiresExactSessionMinutes() {
        let distribution = HeartRateZoneDistribution(
            zone1Minutes: 10,
            zone2Minutes: 40,
            zone3Minutes: 20,
            zone4Minutes: 10,
            zone5Minutes: 10
        )
        XCTAssertTrue(distribution.isValid(sessionDurationMinutes: 90))
        XCTAssertFalse(distribution.isValid(sessionDurationMinutes: 91))
        XCTAssertFalse(distribution.isValid(sessionDurationMinutes: 89))
    }

    func testThresholdsValidation() {
        let valid = HeartRateZoneThresholds.standard(maxHeartRate: 190)
        XCTAssertTrue(valid.isValid())

        var invalid = valid
        invalid.zone2Upper = 100
        XCTAssertFalse(invalid.isValid())
    }
}
