import Foundation

/// Live numbers shown while the user edits a session (same math as the final plan).
struct PlanPreview: Equatable, Sendable {
    var carbsPerHour: Int
    var fluidsPerHourMl: Int
    var sodiumPerHourMg: Int
}

extension SessionViewModel {
    /// Preview metrics for the Plan screen, computed by `FuelingCalculator` itself; `nil` while the input is invalid.
    func planPreview(profile: UserProfile) -> PlanPreview? {
        var previewSetup = setup
        if previewSetup.intensityMode == .zoneBased,
           let minutes = previewSetup.resolvedDurationMinutes(),
           !previewSetup.zoneDistribution.isValid(sessionDurationMinutes: minutes) {
            previewSetup.zoneDistribution = previewSetup.zoneDistribution.scaled(toSessionMinutes: minutes)
        }
        guard let result = try? FuelingCalculator.calculate(
            FuelingCalculatorInput(profile: profile, setup: previewSetup)
        ) else { return nil }
        return PlanPreview(
            carbsPerHour: Int(result.carbsPerHour.midpoint.rounded()),
            fluidsPerHourMl: Int(result.fluidsPerHourMl.midpoint.rounded()),
            sodiumPerHourMg: Int(result.sodiumPerHourMg.midpoint.rounded())
        )
    }
}
