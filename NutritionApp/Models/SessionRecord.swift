import Foundation

/// A saved planning session (history entry), synced via iCloud for all users.
struct SessionRecord: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var savedAt: Date
    var setup: SessionSetup
    var result: FuelingResult
    var profileWeightKg: Double?

    init(
        id: UUID = UUID(),
        savedAt: Date = .now,
        setup: SessionSetup,
        result: FuelingResult,
        profileWeightKg: Double? = nil
    ) {
        self.id = id
        self.savedAt = savedAt
        self.setup = setup
        self.result = result
        self.profileWeightKg = profileWeightKg
    }
}
