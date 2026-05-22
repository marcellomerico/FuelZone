import Foundation

struct SnackSwapContext: Identifiable, Equatable {
    let id = UUID()
    let stepID: UUID
    let portionID: UUID
}
