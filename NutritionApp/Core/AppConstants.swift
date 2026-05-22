import Foundation

enum AppConstants {
    static let appName = "FuelZone"
    static let defaultTaglineKey = "onboarding.tagline"

    /// Timeline steps are generated every N minutes.
    static let timelineStepMinutes = 20

    /// Absolute carbohydrate ceiling in g/h (Jeukendrup 2014 ultra-endurance tier; before stomach sensitivity).
    static let maxCarbsPerHour = 90.0

    /// Minimum session length (minutes) that triggers fueling recommendations.
    static let minimumFuelingSessionMinutes = 30

    /// Range spread applied to hourly carb recommendations (± fraction).
    static let carbRangeSpread = 0.08

    static let fluidRangeSpread = 0.1
    static let sodiumRangeSpread = 0.1

    /// Free tier: number of history sessions kept locally / in iCloud.
    static let freeHistorySessionLimit = 10
}
