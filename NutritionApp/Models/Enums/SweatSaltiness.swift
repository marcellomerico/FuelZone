import Foundation

enum SweatSaltiness: String, Codable, CaseIterable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    /// Sodium concentration in mg per liter of recommended fluid.
    var sodiumMgPerLiter: Int {
        switch self {
        case .low: 300
        case .moderate: 500
        case .high: 700
        }
    }
}
