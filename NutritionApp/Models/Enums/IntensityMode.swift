import Foundation

enum IntensityMode: String, Codable, CaseIterable, Identifiable {
    case simple
    case zoneBased

    var id: String { rawValue }
}
