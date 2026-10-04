import Foundation

/// How aggressively carbohydrate targets may be pushed before stomach-cap limits apply.
enum StomachSensitivity: String, Codable, CaseIterable, Identifiable {
    case conservative
    case moderate
    case tolerant

    var id: String { rawValue }

    /// Multiplier applied to the per-hour carb ceiling (1.0 = baseline).
    var stomachCapMultiplier: Double {
        switch self {
        case .conservative: 0.85
        case .moderate: 1.0
        case .tolerant: 1.12
        }
    }

    /// Extra intake for long sessions: a trained gut can absorb up to ~100 g/h with
    /// multiple transportable carbohydrates (glucose + fructose).
    var longSessionBoost: Double {
        switch self {
        case .conservative, .moderate: 1.0
        case .tolerant: 1.1
        }
    }
}
