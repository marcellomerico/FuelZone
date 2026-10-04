import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    // A nonisolated deinit avoids the isolated-deinit back-deployment shim, which crashes on iOS < 26
    // (swift_task_deinitOnExecutorMainActorBackDeploy) when the object is released on the main thread.
    nonisolated deinit {}

    @Published var stepIndex = 0
    @Published var primarySport: SportType = .running
    @Published var stomachSensitivity: StomachSensitivity = .moderate
    @Published var sweatRate: SweatRate = .moderate
    @Published var sweatSaltiness: SweatSaltiness = .moderate
    @Published var displayName = ""
    @Published var weightText = ""
    @Published var maxHeartRateText = ""

    let totalSteps = 4

    /// Starts over at the first step, pre-filled from the current profile.
    func reset(from profile: UserProfile) {
        stepIndex = 0
        primarySport = profile.primarySport
        stomachSensitivity = profile.stomachSensitivity
        sweatRate = profile.sweatRate
        sweatSaltiness = profile.sweatSaltiness
        displayName = profile.displayName ?? ""
        weightText = profile.weightKg.map { String(format: "%.0f", $0) } ?? ""
        maxHeartRateText = profile.maxHeartRate.map(String.init) ?? ""
    }

    func next() { stepIndex = min(stepIndex + 1, totalSteps - 1) }
    func back() { stepIndex = max(stepIndex - 1, 0) }

    var isLastStep: Bool { stepIndex == totalSteps - 1 }

    /// Whether the optional fields contain something that cannot be used (shown as a hint, never blocks).
    var hasInvalidOptionalInput: Bool {
        (!weightText.trimmingCharacters(in: .whitespaces).isEmpty && InputParsing.weightKg(weightText) == nil)
            || (!maxHeartRateText.trimmingCharacters(in: .whitespaces).isEmpty && InputParsing.maxHeartRate(maxHeartRateText) == nil)
    }

    /// Writes the onboarding answers into an existing profile, keeping its identity and custom HR zones.
    func apply(to profile: inout UserProfile) {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.displayName = trimmedName.isEmpty ? nil : trimmedName
        profile.primarySport = primarySport
        profile.stomachSensitivity = stomachSensitivity
        profile.sweatRate = sweatRate
        profile.sweatSaltiness = sweatSaltiness
        profile.weightKg = InputParsing.weightKg(weightText)

        let maxHR = InputParsing.maxHeartRate(maxHeartRateText)
        if maxHR != profile.maxHeartRate {
            profile.maxHeartRate = maxHR
            profile.zoneThresholds = maxHR.map(HeartRateZoneThresholds.standard(maxHeartRate:))
        }
    }

    /// A fresh profile from the answers (used by tests and first launch).
    func buildProfile() -> UserProfile {
        var profile = UserProfile()
        apply(to: &profile)
        profile.hasCompletedOnboarding = true
        return profile
    }
}
