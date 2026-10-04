import Combine
import CoreLocation
import Foundation

/// One-shot location lookup for weather. Waits for the permission answer instead of polling.
@MainActor
final class LocationAccessService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestCurrentCoordinate() async throws -> CLLocationCoordinate2D {
        // Only one lookup at a time; a second tap while waiting is rejected.
        guard locationContinuation == nil, authorizationContinuation == nil else {
            throw WeatherServiceError.locationUnavailable
        }

        var status = manager.authorizationStatus
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            break
        case .restricted, .denied:
            throw WeatherServiceError.locationDenied
        default:
            throw WeatherServiceError.locationUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            guard status != .notDetermined, let continuation = authorizationContinuation else { return }
            authorizationContinuation = nil
            continuation.resume(returning: status)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        Task { @MainActor in
            guard let continuation = locationContinuation else { return }
            locationContinuation = nil
            if let coordinate {
                continuation.resume(returning: coordinate)
            } else {
                continuation.resume(throwing: WeatherServiceError.locationUnavailable)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            guard let continuation = locationContinuation else { return }
            locationContinuation = nil
            continuation.resume(throwing: WeatherServiceError.locationUnavailable)
        }
    }
}
