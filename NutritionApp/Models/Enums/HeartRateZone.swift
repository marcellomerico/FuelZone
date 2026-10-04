import Foundation

enum HeartRateZone: Int, Codable, CaseIterable, Identifiable, Comparable {
    case zone1 = 1
    case zone2 = 2
    case zone3 = 3
    case zone4 = 4
    case zone5 = 5

    var id: Int { rawValue }

    static func < (lhs: HeartRateZone, rhs: HeartRateZone) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Relative intensity factor (0.65–1.0) applied to duration-based g/h targets.
    var intensityScale: Double {
        switch self {
        case .zone1: 0.65
        case .zone2: 0.85
        case .zone3: 0.95
        case .zone4: 1.0
        case .zone5: 1.0
        }
    }
}
