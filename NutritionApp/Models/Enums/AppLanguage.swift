import Foundation

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english = "en"
    case german = "de"

    var id: String { rawValue }
}
