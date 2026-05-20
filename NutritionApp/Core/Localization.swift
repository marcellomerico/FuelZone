import Foundation
import SwiftUI

extension String {
    /// Localized string from `Localizable.strings` (EN/DE).
    init(localized key: String) {
        self = NSLocalizedString(key, tableName: nil, bundle: .main, value: key, comment: "")
    }
}

extension Text {
    /// SwiftUI text bound to a localization key.
    init(localized key: String) {
        self.init(LocalizedStringKey(key))
    }
}

enum L10n {
    static func string(_ key: String) -> String {
        String(localized: key)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: Locale.current, arguments: arguments)
    }
}
