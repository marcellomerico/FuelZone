import Foundation

/// Easy / moderate / hard slider when zone-based mode is not used.
enum SimpleIntensity: String, Codable, CaseIterable, Identifiable {
    case easy
    case moderate
    case hard

    var id: String { rawValue }

    /// Scales duration-based g/h targets down for easier sessions (Jeukendrup: lower absolute intensity).
    var intensityScale: Double {
        switch self {
        case .easy: 0.70
        case .moderate: 0.85
        case .hard: 1.0
        }
    }
}
