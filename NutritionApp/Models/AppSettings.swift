import Foundation

/// User preferences synced across devices. Pro access is never stored here; it is derived from StoreKit.
struct AppSettings: Codable, Hashable, Sendable {
    var appearance: AppAppearance
    var language: AppLanguage
    var modifiedAt: Date

    init(
        appearance: AppAppearance = .system,
        language: AppLanguage = .system,
        modifiedAt: Date = .distantPast
    ) {
        self.appearance = appearance
        self.language = language
        self.modifiedAt = modifiedAt
    }

    private enum CodingKeys: String, CodingKey {
        case appearance, language, modifiedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appearance = try c.decodeIfPresent(AppAppearance.self, forKey: .appearance) ?? .system
        language = try c.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .distantPast
    }
}
