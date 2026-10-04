import XCTest

/// Walks through every screen and attaches screenshots for design reviews.
/// Opt-in: set `TEST_RUNNER_UI_MODE=light|dark` (and optionally `TEST_RUNNER_UI_LANG=de|en`).
final class UIReviewScreenshots: XCTestCase {
    private var app: XCUIApplication!
    private var mode = "light"
    private var counter = 0

    override func setUpWithError() throws {
        guard let requestedMode = ProcessInfo.processInfo.environment["UI_MODE"] else {
            throw XCTSkip("Set TEST_RUNNER_UI_MODE=light|dark to capture review screenshots.")
        }
        continueAfterFailure = true
        mode = requestedMode
        let language = ProcessInfo.processInfo.environment["UI_LANG"] ?? "de"
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", language == "de" ? "de_DE" : "en_US"]
        app.launchArguments += ["-FZForceAppearance", mode]
        app.launch()
    }

    private func shot(_ name: String) {
        counter += 1
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = String(format: "%@_%02d_%@", mode, counter, name)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func shotScrolling(_ name: String, pages: Int) {
        shot("\(name)_1")
        guard pages > 1 else { return }
        for page in 2...pages {
            app.swipeUp(velocity: .slow)
            shot("\(name)_\(page)")
        }
    }

    private func tab(_ index: Int) {
        app.tabBars.buttons.element(boundBy: index).tap()
        sleep(1)
    }

    /// Closes the frontmost sheet via its close/done/cancel button.
    private func closeSheet() {
        app.swipeDown(velocity: .fast)
        for label in ["Schließen", "Close", "Fertig", "Done", "Abbrechen", "Cancel"] {
            let candidate = app.buttons[label]
            if candidate.exists && candidate.isHittable {
                candidate.tap()
                sleep(1)
                return
            }
        }
        app.swipeDown(velocity: .fast)
        sleep(1)
    }

    private func button(containing texts: String...) -> XCUIElement {
        let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: texts.map { NSPredicate(format: "label CONTAINS[c] %@", $0) })
        return app.buttons.matching(predicate).firstMatch
    }

    func testCaptureAllScreens() {
        let primary = app.buttons["onboarding.primary"]
        if primary.waitForExistence(timeout: 4) {
            for step in 1...4 {
                shot("onboarding_\(step)")
                primary.tap()
                sleep(1)
            }
        }

        tab(0)
        shotScrolling("plan", pages: 2)
        app.swipeDown(velocity: .fast)

        let conditions = button(containing: "Trocken", "Dry")
        if conditions.exists {
            conditions.tap()
            sleep(1)
            shot("plan_conditions")
            closeSheet()
        }

        let zones = button(containing: "Zonen", "Zones")
        if zones.exists {
            zones.tap()
            sleep(2)
            shotScrolling("paywall", pages: 2)
            closeSheet()
        }

        app.buttons["plan.create"].tap()
        sleep(2)
        shotScrolling("result", pages: 5)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        tab(1)
        shot("history")

        tab(2)
        shotScrolling("snacks", pages: 3)

        tab(3)
        shotScrolling("settings", pages: 2)

        let debugToggle = app.switches.firstMatch
        if debugToggle.exists {
            if (debugToggle.value as? String) != "1" {
                debugToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            }
            app.swipeDown(velocity: .fast)
            let profile = button(containing: "Profil", "profile")
            if profile.exists {
                profile.tap()
                sleep(1)
                shotScrolling("profile_pro", pages: 3)
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
            tab(0)
            let zonesPro = button(containing: "Zonen", "Zones")
            if zonesPro.exists {
                zonesPro.tap()
                sleep(1)
                shotScrolling("plan_zones", pages: 2)
                app.swipeDown(velocity: .fast)
                button(containing: "Einfach", "Simple").tap()
            }
            tab(2)
            button(containing: "eigenen Snack", "custom snack").tap()
            let manual = button(containing: "Manuell", "manually")
            if manual.waitForExistence(timeout: 2) {
                manual.tap()
                sleep(1)
                shot("snack_editor")
                closeSheet()
            }
            tab(3)
            let toggleAgain = app.switches.firstMatch
            var swipes = 0
            while !toggleAgain.isHittable && swipes < 4 { app.swipeUp(); swipes += 1 }
            if toggleAgain.exists, (toggleAgain.value as? String) == "1" {
                toggleAgain.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
            }
        }

        let methodology = button(containing: "Methodik", "methodology")
        var swipes = 0
        while !methodology.isHittable && swipes < 6 { app.swipeUp(); swipes += 1 }
        if methodology.exists {
            methodology.tap()
            sleep(1)
            shotScrolling("methodology", pages: 2)
        }
    }
}
