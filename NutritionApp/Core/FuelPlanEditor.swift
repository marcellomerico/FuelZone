import Foundation

/// Edits an existing plan (snack swaps) while keeping amounts sensible.
enum FuelPlanEditor {
    /// Replaces one portion with `newSnack`, scaling the amount so the stop keeps roughly the same
    /// carbohydrates (gels in half steps, drinks by volume, everything else as one portion).
    static func swap(
        in result: FuelingResult,
        stepID: UUID,
        portionID: UUID,
        to newSnack: Snack,
        lookup: (UUID) -> Snack?
    ) -> FuelingResult? {
        guard let stepIndex = result.timeline.firstIndex(where: { $0.id == stepID }),
              let portionIndex = result.timeline[stepIndex].portions.firstIndex(where: { $0.id == portionID })
        else { return nil }

        var updated = result
        let oldPortion = updated.timeline[stepIndex].portions[portionIndex]
        let oldSnack = updated.usedSnacks.first { $0.id == oldPortion.snackID } ?? lookup(oldPortion.snackID)

        let quantity = matchedQuantity(replacing: oldPortion, of: oldSnack, with: newSnack)
        updated.timeline[stepIndex].portions[portionIndex].snackID = newSnack.id
        updated.timeline[stepIndex].portions[portionIndex].quantity = quantity
        updated.timeline[stepIndex].isUserModified = true

        if !updated.usedSnacks.contains(where: { $0.id == newSnack.id }) {
            updated.usedSnacks.append(newSnack)
        }
        let referenced = Set(updated.timeline.flatMap(\.portions).map(\.snackID))
        updated.usedSnacks.removeAll { !referenced.contains($0.id) }
        return updated
    }

    static func matchedQuantity(replacing portion: SnackPortion, of oldSnack: Snack?, with newSnack: Snack) -> Double {
        if let newBottle = newSnack.fluidMlPerDefaultPortion {
            let oldMl = oldSnack?.fluidMl(forQuantity: portion.quantity) ?? 0
            let targetMl = oldMl > 0 ? oldMl : 250
            return max(50, (targetMl / 50).rounded() * 50) / newBottle
        }
        guard let oldSnack else { return 1 }
        let oldCarbs = oldSnack.carbs(forQuantity: portion.quantity)
        let newCarbs = newSnack.carbsPerDefaultPortion
        guard oldCarbs > 0, newCarbs > 0, newSnack.category == .gel else { return 1 }
        return max(0.5, (oldCarbs / newCarbs * 2).rounded() / 2)
    }
}
