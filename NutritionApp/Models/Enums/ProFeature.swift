import Foundation

/// Features gated behind FuelZone Pro subscription.
enum ProFeature: String, Codable, CaseIterable, Identifiable {
    case zoneBasedIntensity
    case barcodeScanner
    case snackTimelineSwap
    case unlimitedHistory

    var id: String { rawValue }
}
