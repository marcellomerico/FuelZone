import XCTest

/// End-to-end flows on a clean install (German UI).
final class FlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE", "-FZResetData", "YES"]
        app.launch()
    }

    private func completeOnboarding() {
        let primary = app.buttons["onboarding.primary"]
        XCTAssertTrue(primary.waitForExistence(timeout: 5), "Onboarding should appear on a clean install")
        for _ in 0..<4 { primary.tap() }
        XCTAssertTrue(app.buttons["plan.create"].waitForExistence(timeout: 3))
    }

    private func tab(_ index: Int) {
        app.tabBars.buttons.element(boundBy: index).tap()
    }

    /// Scrolls slowly until the element is hittable.
    private func scrollTo(_ element: XCUIElement, maxSwipes: Int = 12) {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            app.swipeUp(velocity: .slow)
            swipes += 1
        }
    }

    /// Taps a text field until it has keyboard focus, then types.
    private func type(_ text: String, into field: XCUIElement) {
        field.tap()
        if !app.keyboards.firstMatch.waitForExistence(timeout: 2) {
            field.tap()
            _ = app.keyboards.firstMatch.waitForExistence(timeout: 2)
        }
        field.typeText(text)
    }

    private func button(containing text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }

    func testOnboarding_plan_result_history_delete() {
        completeOnboarding()

        app.buttons["plan.create"].tap()
        XCTAssertTrue(app.staticTexts["Packliste"].waitForExistence(timeout: 3), "Result shows the pack list")
        XCTAssertTrue(app.staticTexts["Fuel Track"].exists, "Result shows the Fuel Track")

        tab(1)
        let card = button(containing: "Laufen · 1:30")
        XCTAssertTrue(card.waitForExistence(timeout: 3), "The plan is saved to the history")
        card.swipeLeft()
        button(containing: "Löschen").tap()
        XCTAssertTrue(app.staticTexts["Erste Einheit planen"].waitForExistence(timeout: 3) || app.buttons["Erste Einheit planen"].exists)
    }

    func testRepeatOnboarding_startsAtFirstStep() {
        completeOnboarding()
        tab(3)
        let repeatButton = button(containing: "Onboarding wiederholen")
        scrollTo(repeatButton)
        repeatButton.tap()
        XCTAssertTrue(app.staticTexts["Gramm pro Stunde statt Bauchgefühl"].waitForExistence(timeout: 3), "Restarts at the welcome step")
    }

    func testKitToggle_keepsSnackInCatalog() {
        completeOnboarding()
        tab(2)
        let add = app.buttons["Maurten Gel 100 zum Kit hinzufügen"]
        scrollTo(add)
        add.tap()
        let remove = app.buttons["Maurten Gel 100 aus dem Kit entfernen"].firstMatch
        XCTAssertTrue(remove.waitForExistence(timeout: 2))
        remove.tap()
        XCTAssertTrue(app.buttons["Maurten Gel 100 zum Kit hinzufügen"].waitForExistence(timeout: 2), "Snack stays visible after leaving the kit")
    }

    func testDistanceAndPace_computesDuration() {
        completeOnboarding()
        button(containing: "Pace").tap()
        let distance = app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "Distanz")).firstMatch
        XCTAssertTrue(distance.waitForExistence(timeout: 2))
        type("21,1", into: distance)
        let pace = app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "Pace")).firstMatch
        type("5,5", into: pace)
        let duration = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "1:56")).firstMatch
        XCTAssertTrue(duration.waitForExistence(timeout: 2), "21.1 km at 5:30/km ≈ 1:56")
    }

    func testZonesWithoutPro_showsPaywall() {
        completeOnboarding()
        button(containing: "Zonen").tap()
        XCTAssertTrue(app.staticTexts["FuelZone Pro"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.links["Datenschutz"].exists || button(containing: "Datenschutz").exists, "Paywall links to the privacy policy")
        app.buttons["Schließen"].tap()
        XCTAssertTrue(app.buttons["plan.create"].waitForExistence(timeout: 2))
    }
}
