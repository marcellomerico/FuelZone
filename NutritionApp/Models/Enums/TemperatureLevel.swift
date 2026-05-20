import Foundation

enum TemperatureLevel: String, Codable, CaseIterable, Identifiable {
    case cool
    case mild
    case warm
    case hot

    var id: String { rawValue }

    /// Fluid multiplier applied on top of sweat-rate baseline.
    var fluidMultiplier: Double {
        switch self {
        case .cool: 0.9
        case .mild: 1.0
        case .warm: 1.15
        case .hot: 1.3
        }
    }
}
