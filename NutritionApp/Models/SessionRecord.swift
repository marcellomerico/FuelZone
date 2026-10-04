import Foundation

/// A saved planning session (history entry), synced via iCloud for all users.
struct SessionRecord: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var savedAt: Date
    var modifiedAt: Date
    /// Optional user-given name ("Long run"); the UI falls back to sport + duration.
    var title: String?
    var setup: SessionSetup
    var result: FuelingResult
    var profileWeightKg: Double?

    init(
        id: UUID = UUID(),
        savedAt: Date = .now,
        modifiedAt: Date? = nil,
        title: String? = nil,
        setup: SessionSetup,
        result: FuelingResult,
        profileWeightKg: Double? = nil
    ) {
        self.id = id
        self.savedAt = savedAt
        self.modifiedAt = modifiedAt ?? savedAt
        self.title = title
        self.setup = setup
        self.result = result
        self.profileWeightKg = profileWeightKg
    }

    private enum CodingKeys: String, CodingKey {
        case id, savedAt, modifiedAt, title, setup, result, profileWeightKg
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        savedAt = try c.decode(Date.self, forKey: .savedAt)
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? savedAt
        title = try c.decodeIfPresent(String.self, forKey: .title)
        setup = try c.decode(SessionSetup.self, forKey: .setup)
        result = try c.decode(FuelingResult.self, forKey: .result)
        profileWeightKg = try c.decodeIfPresent(Double.self, forKey: .profileWeightKg)
    }
}
