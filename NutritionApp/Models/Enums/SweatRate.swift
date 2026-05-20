import Foundation

enum SweatRate: String, Codable, CaseIterable, Identifiable {
    case low
    case moderate
    case high

    var id: String { rawValue }

    /// Baseline fluid intake in ml/h before temperature adjustments.
    var baselineMlPerHour: Int {
        switch self {
        case .low: 400
        case .moderate: 600
        case .high: 800
        }
    }
}
