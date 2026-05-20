import Foundation

enum WeatherCondition: String, Codable, CaseIterable, Identifiable {
    case dry
    case humid
    case windy

    var id: String { rawValue }

    var fluidMultiplier: Double {
        switch self {
        case .dry: 1.0
        case .humid: 1.05
        case .windy: 1.1
        }
    }
}
