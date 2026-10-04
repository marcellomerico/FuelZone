import Foundation

/// Public legal pages, served by GitHub Pages from `docs/privacy.md` and `docs/terms.md`
/// (Settings → Pages → Branch `main`, folder `/docs`).
enum AppLegalLinks {
    static let privacyPolicy = URL(string: "https://marcellomerico.github.io/FuelZone/privacy/")!
    static let termsOfUse = URL(string: "https://marcellomerico.github.io/FuelZone/terms/")!
    static let supportEmail = "support@fuelzone.app"
}
