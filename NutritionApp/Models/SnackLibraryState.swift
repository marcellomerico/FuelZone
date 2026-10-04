import Foundation

/// The user's snack setup: which snacks are in “My kit” (used for planning) plus custom snacks.
struct SnackLibrary: Codable, Hashable, Sendable {
    /// Snacks (built-in or custom) the planner may use.
    var kitSnackIDs: Set<UUID>
    var customSnacks: [Snack]
    var modifiedAt: Date
    /// Built-in snacks the user switched off before the kit existed. Resolved once by `UserDataStore`.
    var legacyDisabledBuiltInIDs: Set<UUID>?

    /// Starter kit for new users: two gels, an isotonic drink and a salt tablet (IDs from DefaultSnacks.json).
    static let starterKitNameKeys: [String] = [
        "snack.gel.maurten160",
        "snack.gel.gu.roctane",
        "snack.drink.isotonic",
        "snack.electrolyte.salt.tablet",
    ]

    init(
        kitSnackIDs: Set<UUID> = [],
        customSnacks: [Snack] = [],
        modifiedAt: Date = .distantPast,
        legacyDisabledBuiltInIDs: Set<UUID>? = nil
    ) {
        self.kitSnackIDs = kitSnackIDs
        self.customSnacks = customSnacks
        self.modifiedAt = modifiedAt
        self.legacyDisabledBuiltInIDs = legacyDisabledBuiltInIDs
    }

    private enum CodingKeys: String, CodingKey {
        case kitSnackIDs, customSnacks, modifiedAt, legacyDisabledBuiltInIDs
        case disabledBuiltInIDs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        customSnacks = try c.decodeIfPresent([Snack].self, forKey: .customSnacks) ?? []
        modifiedAt = try c.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? .distantPast
        if let kit = try c.decodeIfPresent(Set<UUID>.self, forKey: .kitSnackIDs) {
            kitSnackIDs = kit
            legacyDisabledBuiltInIDs = try c.decodeIfPresent(Set<UUID>.self, forKey: .legacyDisabledBuiltInIDs)
        } else {
            // Pre-kit format (SnackLibraryState): every built-in except the disabled ones was active,
            // custom snacks carried their own `isEnabled` flag.
            kitSnackIDs = Set(customSnacks.filter(\.isEnabled).map(\.id))
            legacyDisabledBuiltInIDs = try c.decodeIfPresent(Set<UUID>.self, forKey: .disabledBuiltInIDs) ?? []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(kitSnackIDs, forKey: .kitSnackIDs)
        try c.encode(customSnacks, forKey: .customSnacks)
        try c.encode(modifiedAt, forKey: .modifiedAt)
        try c.encodeIfPresent(legacyDisabledBuiltInIDs, forKey: .legacyDisabledBuiltInIDs)
    }
}
