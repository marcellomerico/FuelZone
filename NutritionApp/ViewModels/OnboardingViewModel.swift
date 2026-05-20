import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var stepIndex = 0
    @Published var primarySport: SportType = .running
    @Published var stomachSensitivity: StomachSensitivity = .moderate
    @Published var sweatRate: SweatRate = .moderate
    @Published var sweatSaltiness: SweatSaltiness = .moderate
    @Published var displayName = ""
    @Published var weightText = ""
    @Published var maxHeartRateText = ""

    let totalSteps = 7

    func configure(profile: UserProfile) {
        primarySport = profile.primarySport
        stomachSensitivity = profile.stomachSensitivity
        sweatRate = profile.sweatRate
        sweatSaltiness = profile.sweatSaltiness
        displayName = profile.displayName ?? ""
        if let w = profile.weightKg { weightText = String(format: "%.0f", w) }
        if let hr = profile.maxHeartRate { maxHeartRateText = "\(hr)" }
    }

    func next() { stepIndex = min(stepIndex + 1, totalSteps - 1) }
    func back() { stepIndex = max(stepIndex - 1, 0) }

    func buildProfile() -> UserProfile {
        var profile = UserProfile(
            displayName: displayName.isEmpty ? nil : displayName,
            weightKg: Double(weightText.replacingOccurrences(of: ",", with: ".")),
            primarySport: primarySport,
            stomachSensitivity: stomachSensitivity,
            sweatRate: sweatRate,
            sweatSaltiness: sweatSaltiness,
            maxHeartRate: Int(maxHeartRateText),
            hasCompletedOnboarding: true
        )
        profile.refreshZoneThresholdsFromMaxHR()
        return profile
    }
}
