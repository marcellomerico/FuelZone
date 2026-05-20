import Foundation

/// A snack assigned to a timeline step with a quantity (e.g. 1.5 gels).
struct SnackPortion: Codable, Hashable, Identifiable, Sendable {
    var id: UUID
    var snackID: UUID
    var quantity: Double

    init(id: UUID = UUID(), snackID: UUID, quantity: Double) {
        self.id = id
        self.snackID = snackID
        self.quantity = quantity
    }

    func totalCarbs(for snack: Snack) -> Double {
        snack.carbsPerServing * quantity
    }

    func totalSodiumMg(for snack: Snack) -> Double {
        snack.sodiumMgPerServing * quantity
    }
}
