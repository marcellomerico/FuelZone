import Foundation

enum SportType: String, Codable, CaseIterable, Identifiable {
    case running
    case cycling
    case triathlon
    case hiking
    case other

    var id: String { rawValue }

    var systemImageName: String {
        switch self {
        case .running: "figure.run"
        case .cycling: "bicycle"
        case .triathlon: "figure.pool.swim"
        case .hiking: "figure.hiking"
        case .other: "sportscourt"
        }
    }
}
