import XCTest

/// Walks through every screen and attaches screenshots for the UI review.
/// Appearance via env `UI_MODE` (`light` / `dark`), passed as `TEST_RUNNER_UI_MODE`.
final class UIReviewScreenshots: XCTestCase {
    private var app: XCUIApplication!
    private var mode = "light"
    private var counter = 0

    override func setUpWithError() throws {
        // Screenshot tool for design reviews, not a regression test: runs only when UI_MODE is set.
        guard let requestedMode = ProcessInfo.processInfo.environment["UI_MODE"] else {
            throw XCTSkip("Set TEST_RUNNER_UI_MODE=light|dark to capture review screenshots.")
        }
        continueAfterFailure = true
        mode = requestedMode
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    private func shot(_ name: String) {
        counter += 1
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "%@_%02d_%@", mode, counter, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func shotScrolling(_ name: String, pages: Int = 4) {
        shot("\(name)_1")
        for page in 2...pages {
            app.swipeUp(velocity: .slow)
            shot("\(name)_\(page)")
        }
        for _ in 1..<pages { app.swipeDown(velocity: .fast) }
    }

    private func tapTab(_ title: String) {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch.tap()
    }

    private func tapHittable(_ label: String) {
        app.buttons.matching(identifier: label).allElementsBoundByIndex
            .first(where: \.isHittable)?.tap()
    }

    private func scrollTo(_ element: XCUIElement, maxSwipes: Int = 10) {
        var swipes = 0
        while !element.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }

    private func back() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.exists { backButton.tap() }
    }

    private func dismissSheet() {
        app.swipeDown(velocity: .fast)
        sleep(1)
    }

    func testCaptureSettingsTopAndProScreens() {
        tapTab("Settings")
        tapHittable(mode == "dark" ? "Dark" : "Light")
        sleep(1)
        shot("pro_settings_top_1")
        app.swipeUp(velocity: .slow)
        shot("pro_settings_top_2")

        // The debug toggle has no accessibility label; it is the only switch in Settings.
        let proSwitch = app.switches.firstMatch
        scrollTo(proSwitch)
        if (proSwitch.value as? String) != "1" {
            proSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
        sleep(1)
        print("[REVIEW] pro switch value: \(String(describing: proSwitch.value))")

        tapTab("Plan")
        tapHittable("Heart rate zones")
        sleep(1)
        shotScrolling("pro_plan_zones", pages: 4)
        tapHittable("Simple")

        tapTab("Snacks")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Add custom snack")).firstMatch.tap()
        sleep(1)
        shotScrolling("pro_snack_editor", pages: 2)
        dismissSheet()

        tapTab("Settings")
        for _ in 0..<8 { app.swipeDown(velocity: .fast) }
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Your profile")).firstMatch.tap()
        sleep(1)
        for _ in 0..<4 { app.swipeUp(velocity: .fast) }
        shot("pro_profile_hr_1")
        app.swipeUp(velocity: .slow)
        shot("pro_profile_hr_2")
        back()

        tapTab("Settings")
        scrollTo(proSwitch)
        if (proSwitch.value as? String) == "1" {
            proSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        }
    }

    func testCaptureAllScreens() {
        // Onboarding (fresh install)
        let next = app.buttons["Continue"]
        if next.waitForExistence(timeout: 3) {
            var step = 1
            shot("onboarding_step\(step)")
            while next.exists {
                next.tap()
                step += 1
                shot("onboarding_step\(step)")
            }
            tapHittable("Get started")
        }

        // Appearance
        tapTab("Settings")
        tapHittable(mode == "dark" ? "Dark" : "Light")
        sleep(1)

        // Make sure Pro is off for the free-tier screens
        let proSwitch = app.switches["Debug: simulate Pro"]
        func setPro(_ on: Bool) {
            tapTab("Settings")
            scrollTo(proSwitch)
            guard proSwitch.exists else { return }
            let isOn = (proSwitch.value as? String) == "1"
            if isOn != on {
                let inner = proSwitch.switches.firstMatch
                if inner.exists { inner.tap() } else { proSwitch.tap() }
            }
            for _ in 0..<6 { app.swipeDown(velocity: .fast) }
        }
        setPro(false)
        shotScrolling("settings", pages: 5)

        // Plan (free)
        tapTab("Plan")
        shotScrolling("plan_free", pages: 4)

        // Paywall via zone mode
        tapHittable("Heart rate zones")
        sleep(1)
        shot("paywall")
        app.swipeUp(velocity: .slow)
        shot("paywall_expanded")
        dismissSheet()
        dismissSheet()

        // Results
        tapTab("Plan")
        let calculate = app.buttons["Calculate plan"]
        scrollTo(calculate)
        calculate.tap()
        sleep(1)
        shotScrolling("results", pages: 6)
        back()

        // History
        tapTab("History")
        shot("history_list")
        let firstRecord = app.scrollViews.buttons.firstMatch
        if firstRecord.exists {
            firstRecord.tap()
            sleep(1)
            shotScrolling("history_detail", pages: 4)
            back()
        }

        // Snacks (free)
        tapTab("Snacks")
        shotScrolling("snacks", pages: 3)

        // Pro screens
        setPro(true)
        tapTab("Plan")
        tapHittable("Heart rate zones")
        sleep(1)
        shotScrolling("plan_zones", pages: 4)
        tapHittable("Simple")

        tapTab("Snacks")
        tapHittable("Add custom snack")
        sleep(1)
        shotScrolling("snack_editor", pages: 2)
        dismissSheet()

        tapTab("Settings")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Your profile")).firstMatch.tap()
        sleep(1)
        shotScrolling("profile", pages: 5)
        back()

        let methodology = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Science & methodology")).firstMatch
        scrollTo(methodology)
        methodology.tap()
        sleep(1)
        shotScrolling("methodology", pages: 5)
        back()

        setPro(false)
    }
}
