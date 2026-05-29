import CoreLocation
import Foundation

struct WeatherSnapshot: Sendable {
    let temperatureCelsius: Double
    let humidityPercent: Double
    let windSpeedKmh: Double
    let locationLabel: String
}

enum WeatherServiceError: Error {
    case locationDenied
    case locationUnavailable
    case geocodingFailed
    case weatherUnavailable
}

/// Fetches current conditions via Open-Meteo (no API key) and maps them to app enums.
enum WeatherService {
    private static let geocoder = CLGeocoder()

    static func geocode(locationName: String) async throws -> CLLocationCoordinate2D {
        let trimmed = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw WeatherServiceError.geocodingFailed }
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(trimmed) { placemarks, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let location = placemarks?.first?.location else {
                    continuation.resume(throwing: WeatherServiceError.geocodingFailed)
                    return
                }
                continuation.resume(returning: location.coordinate)
            }
        }
    }

    static func fetchCurrent(at coordinate: CLLocationCoordinate2D, locationLabel: String) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,wind_speed_10m"),
            URLQueryItem(name: "timezone", value: "auto")
        ]
        guard let url = components.url else { throw WeatherServiceError.weatherUnavailable }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WeatherServiceError.weatherUnavailable
        }
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        guard let current = decoded.current else { throw WeatherServiceError.weatherUnavailable }
        return WeatherSnapshot(
            temperatureCelsius: current.temperature2m,
            humidityPercent: current.relativeHumidity2m,
            windSpeedKmh: current.windSpeed10m,
            locationLabel: locationLabel
        )
    }

    static func mapToTemperature(_ snapshot: WeatherSnapshot) -> TemperatureLevel {
        switch snapshot.temperatureCelsius {
        case ..<10: return .cool
        case ..<18: return .mild
        case ..<26: return .warm
        default: return .hot
        }
    }

    static func mapToConditions(_ snapshot: WeatherSnapshot) -> WeatherCondition {
        if snapshot.windSpeedKmh >= 25 { return .windy }
        if snapshot.humidityPercent >= 70 { return .humid }
        return .dry
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: OpenMeteoCurrent?
}

private struct OpenMeteoCurrent: Decodable {
    let temperature2m: Double
    let relativeHumidity2m: Double
    let windSpeed10m: Double

    enum CodingKeys: String, CodingKey {
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windSpeed10m = "wind_speed_10m"
    }
}
