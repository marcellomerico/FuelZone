import Combine
import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var setup = SessionSetup()
    @Published var isCalculating = false
    @Published var errorMessage: String?
    @Published private(set) var lastResult: FuelingResult?

    private var profile = UserProfile()
    private var settings = AppSettings()
    private weak var snackViewModel: SnackViewModel?
    private weak var resultsViewModel: ResultsViewModel?

    var zoneTotalPercent: Double { setup.zoneDistribution.totalPercent }
    var isZoneDistributionValid: Bool { setup.zoneDistribution.isValid }

    func configure(
        profile: UserProfile,
        settings: AppSettings,
        snacks: SnackViewModel,
        results: ResultsViewModel? = nil
    ) {
        self.profile = profile
        self.settings = settings
        snackViewModel = snacks
        resultsViewModel = results
        setup.sport = profile.primarySport
    }

    func bind(results: ResultsViewModel) {
        resultsViewModel = results
    }

    func updateProfile(_ profile: UserProfile) { self.profile = profile }
    func updateSettings(_ settings: AppSettings) { self.settings = settings }

    var canUseZoneMode: Bool {
        settings.hasAccess(to: .zoneBasedIntensity)
    }

    func calculatePlan() {
        errorMessage = nil
        isCalculating = true
        defer { isCalculating = false }

        if setup.intensityMode == .zoneBased, !canUseZoneMode {
            setup.intensityMode = .simple
        }

        if setup.intensityMode == .zoneBased, !isZoneDistributionValid {
            errorMessage = String(localized: "error.invalidZoneDistribution")
            return
        }

        let snacks = snackViewModel?.enabledSnacks() ?? []
        do {
            let result = try FuelingCalculator.calculate(
                FuelingCalculatorInput(
                    profile: profile,
                    setup: setup,
                    availableSnacks: snacks
                )
            )
            lastResult = result
            resultsViewModel?.setResult(result, setup: setup, profile: profile)
        } catch let error as FuelingCalculatorError {
            errorMessage = error.localizedMessage
        } catch {
            errorMessage = String(localized: "error.invalidDuration")
        }
    }

    func updateMaxHeartRateFromText(_ text: String) {
        guard let hr = Int(text), hr > 0 else { return }
        profile.maxHeartRate = hr
        profile.refreshZoneThresholdsFromMaxHR()
    }
}
