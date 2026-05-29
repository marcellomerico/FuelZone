import Combine
import CoreLocation
import Foundation

@MainActor
final class SessionViewModel: ObservableObject {
    @Published var setup = SessionSetup()
    @Published var isCalculating = false
    @Published var errorMessage: String?
    @Published var showProPaywall = false
    @Published var isFetchingWeather = false
    @Published var weatherStatusMessage: String?
    @Published private(set) var zoneThresholds: HeartRateZoneThresholds?
    @Published private(set) var lastResult: FuelingResult?

    private let locationAccess = LocationAccessService()
    private var profile = UserProfile()
    private var settings = AppSettings()
    private weak var snackViewModel: SnackViewModel?
    private weak var resultsViewModel: ResultsViewModel?

    var resolvedSessionMinutes: Int? { setup.resolvedDurationMinutes() }

    var zoneTotalMinutes: Int { setup.zoneDistribution.totalMinutes }

    var isZoneDistributionValid: Bool {
        guard let minutes = resolvedSessionMinutes else { return false }
        return setup.zoneDistribution.isValid(sessionDurationMinutes: minutes)
    }

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
        zoneThresholds = profile.zoneThresholds
            ?? profile.maxHeartRate.flatMap { HeartRateZoneCalculator.thresholds(maxHeartRate: $0) }
    }

    func bind(results: ResultsViewModel) {
        resultsViewModel = results
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
        zoneThresholds = profile.zoneThresholds
            ?? profile.maxHeartRate.flatMap { HeartRateZoneCalculator.thresholds(maxHeartRate: $0) }
    }

    func exportedProfile() -> UserProfile { profile }
    func updateSettings(_ settings: AppSettings) { self.settings = settings }

    var canUseZoneMode: Bool {
        settings.hasAccess(to: .zoneBasedIntensity)
    }

    func selectIntensityMode(_ mode: IntensityMode) {
        if mode == .zoneBased, !canUseZoneMode {
            showProPaywall = true
            return
        }
        setup.intensityMode = mode
    }

    /// Keeps zone minutes aligned when the user changes session duration.
    func applyWeather(fromLocationName name: String) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            weatherStatusMessage = String(localized: "session.weather.locationRequired")
            return
        }
        await fetchAndApplyWeather(
            coordinateProvider: { try await WeatherService.geocode(locationName: trimmed) },
            locationLabel: trimmed
        )
    }

    func applyWeatherFromCurrentLocation() async {
        await fetchAndApplyWeather(
            coordinateProvider: { try await locationAccess.requestCurrentCoordinate() },
            locationLabel: String(localized: "session.weather.currentLocation")
        )
    }

    private func fetchAndApplyWeather(
        coordinateProvider: () async throws -> CLLocationCoordinate2D,
        locationLabel: String
    ) async {
        weatherStatusMessage = nil
        isFetchingWeather = true
        defer { isFetchingWeather = false }
        do {
            let coordinate = try await coordinateProvider()
            let snapshot = try await WeatherService.fetchCurrent(at: coordinate, locationLabel: locationLabel)
            setup.weatherLocationName = snapshot.locationLabel
            setup.weatherLatitude = coordinate.latitude
            setup.weatherLongitude = coordinate.longitude
            setup.temperature = WeatherService.mapToTemperature(snapshot)
            setup.conditions = WeatherService.mapToConditions(snapshot)
            weatherStatusMessage = L10n.format(
                "session.weather.applied",
                String(format: "%.0f", snapshot.temperatureCelsius),
                LocalizedEnum.label(for: setup.temperature),
                LocalizedEnum.label(for: setup.conditions)
            )
        } catch WeatherServiceError.locationDenied {
            weatherStatusMessage = String(localized: "session.weather.locationDenied")
        } catch {
            weatherStatusMessage = String(localized: "session.weather.failed")
        }
    }

    func syncZoneDistributionToSessionDuration() {
        guard setup.intensityMode == .zoneBased,
              let total = setup.resolvedDurationMinutes(), total > 0 else { return }

        if setup.zoneDistribution.isValid(sessionDurationMinutes: total) { return }
        setup.zoneDistribution = setup.zoneDistribution.scaled(toSessionMinutes: total)
    }

    func calculatePlan() {
        errorMessage = nil
        isCalculating = true
        defer { isCalculating = false }

        if setup.intensityMode == .zoneBased, !canUseZoneMode {
            showProPaywall = true
            return
        }

        if let validationError = validateSetupInput() {
            errorMessage = validationError
            return
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

    private func validateSetupInput() -> String? {
        switch setup.durationInputMode {
        case .duration:
            guard let minutes = setup.durationMinutes, minutes > 0 else {
                return String(localized: "error.invalidDuration")
            }
        case .distanceAndPace:
            guard let km = setup.distanceKm, km > 0,
                  let pace = setup.paceMinutesPerKm, pace > 0,
                  setup.resolvedDurationMinutes() != nil else {
                return String(localized: "error.invalidDuration")
            }
        case .distanceAndTime:
            guard let km = setup.distanceKm, km > 0,
                  let minutes = setup.durationMinutes, minutes > 0 else {
                return String(localized: "error.distanceTimeIncomplete")
            }
        }
        return nil
    }
}
