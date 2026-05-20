import Foundation

/// Min–max range for values that should not be shown as a single point estimate.
struct NutritionRange: Codable, Hashable, Sendable {
    let min: Double
    let max: Double

    var midpoint: Double { (min + max) / 2 }

    init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }

    static func centered(value: Double, spreadFraction: Double) -> NutritionRange {
        let spread = value * spreadFraction
        return NutritionRange(
            min: Swift.max(0, value - spread),
            max: value + spread
        )
    }

    func rounded(toPlaces places: Int) -> NutritionRange {
        let factor = pow(10.0, Double(places))
        return NutritionRange(
            min: (min * factor).rounded() / factor,
            max: (max * factor).rounded() / factor
        )
    }
}

extension NutritionRange: CustomStringConvertible {
    var description: String {
        if min == max {
            return String(format: "%.0f", min)
        }
        return String(format: "%.0f–%.0f", min, max)
    }
}
