import XCTest
@testable import NutritionApp

final class NutritionAppTests: XCTestCase {
    func testDefaultSnacksLoadFromBundle() throws {
        let snacks = try DefaultSnackLoader.loadBuiltInSnacks()
        XCTAssertGreaterThanOrEqual(snacks.count, 20)
        XCTAssertTrue(snacks.allSatisfy(\.isBuiltIn))
    }

    func testEnglishLocalizationKeysResolve() {
        guard let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            XCTFail("Missing en.lproj bundle")
            return
        }
        XCTAssertEqual(bundle.localizedString(forKey: "onboarding.tagline", value: nil, table: nil),
                         "Fuel that fits your session.")
        XCTAssertEqual(bundle.localizedString(forKey: "snack.gel.maurten320", value: nil, table: nil),
                         "Maurten Gel 320")
    }

    func testGermanLocalizationKeysResolve() {
        guard let path = Bundle.main.path(forResource: "de", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            XCTFail("Missing de.lproj bundle")
            return
        }
        XCTAssertEqual(bundle.localizedString(forKey: "onboarding.tagline", value: nil, table: nil),
                         "Versorgung, die zu deiner Einheit passt.")
    }
}
