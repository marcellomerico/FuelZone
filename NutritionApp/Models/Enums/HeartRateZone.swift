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

    /// Carbohydrate need factor (g/kg/h baseline scaled by zone).
    var carbFactorPerKgPerHour: Double {
        switch self {
        case .zone1: 0.4
        case .zone2: 0.6
        case .zone3: 0.9
        case .zone4: 1.1
        case .zone5: 1.3
        }
    }

    /// Default percentage of max HR (lower, upper) for zone calculator.
    var defaultPercentRange: ClosedRange<Double> {
        switch self {
        case .zone1: 0.50...0.60
        case .zone2: 0.60...0.70
        case .zone3: 0.70...0.80
        case .zone4: 0.80...0.90
        case .zone5: 0.90...1.00
        }
    }
}
