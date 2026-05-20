import Foundation

/// Easy / moderate / hard slider when zone-based mode is not used.
enum SimpleIntensity: String, Codable, CaseIterable, Identifiable {
    case easy
    case moderate
    case hard

    var id: String { rawValue }

    /// Maps to an approximate blended zone mix for carb g/kg/h calculations.
    var carbMultiplier: Double {
        switch self {
        case .easy: 0.75
        case .moderate: 1.0
        case .hard: 1.25
        }
    }
}
