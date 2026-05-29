import Foundation

extension SessionViewModel {
    /// Live preview metrics for the Plan screen (uses existing fueling guidelines).
    func planPreviewMetrics(profile: UserProfile) -> (carbsPerHour: Int, gelCount: Int, sodiumPerHour: Int) {
        let minutes = setup.resolvedDurationMinutes() ?? 90
        let intensityScale: Double
        if setup.intensityMode == .simple {
            intensityScale = ExerciseCarbGuidelines.intensityScale(simpleIntensity: setup.simpleIntensity)
        } else {
            intensityScale = ExerciseCarbGuidelines.intensityScale(
                zoneDistribution: setup.zoneDistribution,
                sessionDurationMinutes: minutes
            )
        }

        var carbsPerHour = ExerciseCarbGuidelines.recommendedCarbsPerHour(
            durationMinutes: minutes,
            intensityScale: intensityScale
        )

        let cap = AppConstants.maxCarbsPerHour * profile.stomachSensitivity.stomachCapMultiplier
        if carbsPerHour > cap { carbsPerHour = cap }

        let fluidsPerHour = Int(
            (
                Double(profile.sweatRate.baselineMlPerHour)
                    * setup.temperature.fluidMultiplier
                    * setup.conditions.fluidMultiplier
            ).rounded()
        )
        let sodiumPerHour = Double(fluidsPerHour) / 1000.0 * Double(profile.sweatSaltiness.sodiumMgPerLiter)

        let gelCount = carbsPerHour > 0 ? max(1, Int((carbsPerHour / 22.0).rounded())) : 0

        return (
            carbsPerHour: Int(carbsPerHour.rounded()),
            gelCount: gelCount,
            sodiumPerHour: Int(sodiumPerHour.rounded())
        )
    }
}
