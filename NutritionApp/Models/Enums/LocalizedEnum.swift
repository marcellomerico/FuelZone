import Foundation

/// Maps model enums to `Localizable.strings` keys.
enum LocalizedEnum {
    static func key(for sport: SportType) -> String { "sport.\(sport.rawValue)" }
    static func key(for stomach: StomachSensitivity) -> String { "stomach.\(stomach.rawValue)" }
    static func key(for sweat: SweatRate) -> String { "sweat.\(sweat.rawValue)" }
    static func key(for saltiness: SweatSaltiness) -> String { "saltiness.\(saltiness.rawValue)" }
    static func key(for intensity: SimpleIntensity) -> String { "intensity.\(intensity.rawValue)" }
    static func key(for temperature: TemperatureLevel) -> String { "temperature.\(temperature.rawValue)" }
    static func key(for weather: WeatherCondition) -> String { "weather.\(weather.rawValue)" }
    static func key(for category: SnackCategory) -> String { "category.\(category.rawValue)" }
    static func key(for zone: HeartRateZone) -> String { "hrzone.zone\(zone.rawValue)" }
    static func key(for mode: DurationInputMode) -> String {
        switch mode {
        case .duration: "session.duration.mode.duration"
        case .distanceAndPace: "session.duration.mode.distancePace"
        case .distanceAndTime: "session.duration.mode.distanceTime"
        }
    }

    static func label(for sport: SportType) -> String { String(localized: key(for: sport)) }
    static func label(for stomach: StomachSensitivity) -> String { String(localized: key(for: stomach)) }
    static func label(for sweat: SweatRate) -> String { String(localized: key(for: sweat)) }
    static func label(for saltiness: SweatSaltiness) -> String { String(localized: key(for: saltiness)) }
    static func label(for intensity: SimpleIntensity) -> String { String(localized: key(for: intensity)) }
    static func label(for temperature: TemperatureLevel) -> String { String(localized: key(for: temperature)) }
    static func label(for weather: WeatherCondition) -> String { String(localized: key(for: weather)) }
    static func label(for category: SnackCategory) -> String { String(localized: key(for: category)) }
    static func label(for zone: HeartRateZone) -> String { String(localized: key(for: zone)) }
    static func label(for mode: DurationInputMode) -> String { String(localized: key(for: mode)) }
}

extension Snack {
    var localizedName: String {
        if let nameKey { return String(localized: nameKey) }
        let language = Bundle.main.preferredLocalizations.first ?? "en"
        if language.hasPrefix("de"), let nameDE, !nameDE.isEmpty { return nameDE }
        return nameEN ?? nameKey ?? id.uuidString
    }

    var localizedUnit: String {
        String(localized: unitKey)
    }
}

extension FuelingCalculatorError {
    var localizationKey: String {
        switch self {
        case .invalidDuration: "error.invalidDuration"
        case .invalidZoneDistribution: "error.invalidZoneDistribution"
        }
    }

    var localizedMessage: String {
        String(localized: localizationKey)
    }
}
