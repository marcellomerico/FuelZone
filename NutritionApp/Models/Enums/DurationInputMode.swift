import Foundation

enum DurationInputMode: String, Codable, CaseIterable, Identifiable {
    case duration
    case distanceAndPace
    case distanceAndTime

    var id: String { rawValue }
}
