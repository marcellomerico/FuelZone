import Foundation

/// Persisted snack library preferences (selection + custom snacks).
struct SnackLibraryState: Codable, Hashable, Sendable {
    var builtInSnackIDs: Set<UUID>
    var customSnacks: [Snack]
    var disabledBuiltInIDs: Set<UUID>

    init(
        builtInSnackIDs: Set<UUID> = [],
        customSnacks: [Snack] = [],
        disabledBuiltInIDs: Set<UUID> = []
    ) {
        self.builtInSnackIDs = builtInSnackIDs
        self.customSnacks = customSnacks
        self.disabledBuiltInIDs = disabledBuiltInIDs
    }
}
