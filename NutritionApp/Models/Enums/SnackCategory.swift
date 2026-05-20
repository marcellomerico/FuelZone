import Foundation

enum SnackCategory: String, Codable, CaseIterable, Identifiable {
    case gel
    case drink
    case solid
    case electrolyte
    case other

    var id: String { rawValue }

    var systemImageName: String {
        switch self {
        case .gel: "bolt.fill"
        case .drink: "drop.fill"
        case .solid: "fork.knife"
        case .electrolyte: "pill.fill"
        case .other: "takeoutbag.and.cup.and.straw.fill"
        }
    }
}
