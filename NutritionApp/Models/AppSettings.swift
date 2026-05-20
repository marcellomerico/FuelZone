import Foundation

struct AppSettings: Codable, Hashable, Sendable {
    var appearance: AppAppearance
    var language: AppLanguage
    var isProSubscriber: Bool

    init(
        appearance: AppAppearance = .system,
        language: AppLanguage = .system,
        isProSubscriber: Bool = false
    ) {
        self.appearance = appearance
        self.language = language
        self.isProSubscriber = isProSubscriber
    }

    func hasAccess(to feature: ProFeature) -> Bool {
        isProSubscriber
    }
}
