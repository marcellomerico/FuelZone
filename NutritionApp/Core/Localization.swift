import Foundation
import SwiftUI

/// Resolves `Localizable.strings` for the app language chosen in Settings.
enum L10n {
    private(set) static var bundle: Bundle = .main
    /// Locale matching the in-app language (numbers and dates in formatted strings).
    private(set) static var locale: Locale = .current

    static func updateBundle(for language: AppLanguage) {
        bundle = bundle(for: language)
        switch language {
        case .system: locale = .current
        case .english: locale = Locale(identifier: "en")
        case .german: locale = Locale(identifier: "de")
        }
    }

    static func bundle(for language: AppLanguage) -> Bundle {
        let code: String
        switch language {
        case .system:
            code = Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            code = "en"
        case .german:
            code = "de"
        }
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let localized = Bundle(path: path) else {
            return .main
        }
        return localized
    }

    static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: locale, arguments: arguments)
    }
}

extension String {
    /// Localized string from `Localizable.strings` using the active app language bundle.
    init(localized key: String) {
        self = L10n.string(key)
    }
}

extension Text {
    /// SwiftUI text bound to a localization key (respects `\.locale` and bundle-backed keys).
    init(localized key: String) {
        self.init(LocalizedStringKey(key))
    }
}
