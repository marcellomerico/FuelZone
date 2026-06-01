import Foundation

/// Public legal document URLs (host on GitHub Pages or your site before App Store submit).
enum AppLegalLinks {
    /// Enable GitHub Pages for the FuelZone repo → `docs/legal/privacy.md` or dedicated site.
    static let privacyPolicy = URL(string: "https://marcellomerico.github.io/FuelZone/privacy")!

    static let termsOfUse = URL(string: "https://marcellomerico.github.io/FuelZone/terms")!

    static let supportEmail = "support@fuelzone.app"
}
