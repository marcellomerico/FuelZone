import XCTest

/// UI probes written during the code review (see docs/CODE_REVIEW.md).
/// Each test asserts the *correct* behavior, so a failing test documents a confirmed bug.
final class CodeReviewUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        completeOnboardingIfNeeded()
    }

    private func completeOnboardingIfNeeded() {
        let next = app.buttons["Continue"]
        guard next.waitForExistence(timeout: 3) else { return }
        while next.exists { next.tap() }
        // "Get started" also exists on the (hidden) history empty state.
        app.buttons.matching(identifier: "Get started").allElementsBoundByIndex
            .first(where: \.isHittable)?.tap()
    }

    private func tapTab(_ title: String) {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch.tap()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// "Repeat onboarding" should start again at the welcome step.
    func testRepeatOnboarding_startsAtWelcomeStep() {
        tapTab("Settings")
        let repeatButton = app.buttons["Repeat onboarding"]
        var swipes = 0
        while !repeatButton.isHittable && swipes < 10 {
            app.swipeUp()
            swipes += 1
        }
        // Run through onboarding once in this app session, then repeat it again.
        repeatButton.tap()
        completeOnboardingIfNeeded()
        XCTAssertTrue(repeatButton.waitForExistence(timeout: 3))
        repeatButton.tap()
        _ = app.staticTexts["You're ready!"].waitForExistence(timeout: 2)
        attachScreenshot("Repeat onboarding")
        XCTAssertTrue(app.staticTexts["Welcome to FuelZone"].exists, "Onboarding does not restart at step 1")
    }

    /// Typing "10,5" into a decimal field must keep the value 10.5.
    func testDecimalField_keepsTypedValue() {
        tapTab("Plan")
        app.buttons["Distance + pace"].tap()
        let distance = app.textFields.element(boundBy: 0)
        distance.tap()
        distance.typeText("10,5")
        let value = distance.value as? String ?? ""
        attachScreenshot("Decimal field after typing 10,5")
        print("[REVIEW] distance field shows: \(value)")
        XCTAssertTrue(["10,5", "10.5"].contains(value), "Field shows \(value) instead of 10,5")
    }

    /// Disabling a built-in snack must keep it visible so it can be re-enabled.
    func testDisablingSnack_keepsRowVisible() {
        tapTab("Snacks")
        let switches = app.switches
        XCTAssertTrue(switches.firstMatch.waitForExistence(timeout: 3))
        let before = switches.count
        let first = switches.element(boundBy: 0)
        let inner = first.switches.firstMatch
        if inner.exists { inner.tap() } else { first.tap() }
        sleep(1)
        let after = app.switches.count
        attachScreenshot("Snacks after disabling first snack")
        print("[REVIEW] snack switches before \(before), after \(after)")
        XCTAssertEqual(before, after, "Disabled snack disappeared from the library")
    }
}
