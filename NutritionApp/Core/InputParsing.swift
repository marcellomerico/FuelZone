import Foundation

/// Parses and validates free-text numeric input from forms (accepts "," or "." as decimal separator).
enum InputParsing {
    static let weightKgRange = 30.0...250.0
    static let distanceKmRange = 0.1...1000.0
    static let paceMinutesPerKmRange = 1.0...60.0

    static func decimal(_ text: String) -> Double? {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard !normalized.isEmpty, let value = Double(normalized), value.isFinite else { return nil }
        return value
    }

    static func integer(_ text: String) -> Int? {
        Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    /// Body weight in kg, or `nil` when empty or outside a plausible range.
    static func weightKg(_ text: String) -> Double? {
        guard let value = decimal(text), weightKgRange.contains(value) else { return nil }
        return value
    }

    /// Maximum heart rate in bpm, or `nil` when empty or outside `HeartRateZoneCalculator.validMaxHRRange`.
    static func maxHeartRate(_ text: String) -> Int? {
        guard let value = integer(text), HeartRateZoneCalculator.validMaxHRRange.contains(value) else { return nil }
        return value
    }

    /// Non-negative amount (carbs, sodium, portion size); `nil` when empty, negative or not a number.
    static func nonNegative(_ text: String) -> Double? {
        guard let value = decimal(text), value >= 0 else { return nil }
        return value
    }
}
