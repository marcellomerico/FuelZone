import SwiftUI

struct SnackPlanSummaryView: View {
    let result: FuelingResult
    let snacks: [Snack]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: "results.snackPlan")
                .font(.headline)

            let totals = aggregateTotals()
            Text("\(Int(totals.carbs)) g · \(Int(totals.sodium)) mg · \(totals.fluids) ml")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(uniqueSnackIDs(), id: \.self) { id in
                if let snack = snacks.first(where: { $0.id == id }) {
                    let qty = totalQuantity(for: id)
                    HStack {
                        Image(systemName: snack.category.systemImageName)
                        Text("\(qty, specifier: "%.1f")× \(snack.localizedName)")
                    }
                    .font(.caption)
                }
            }
        }
        .fuelZoneCard()
    }

    private func aggregateTotals() -> (carbs: Double, sodium: Double, fluids: Int) {
        result.timeline.reduce((0, 0, 0)) { partial, step in
            (
                partial.0 + step.targetCarbsGrams,
                partial.1 + step.targetSodiumMg,
                partial.2 + step.targetFluidsMl
            )
        }
    }

    private func uniqueSnackIDs() -> [UUID] {
        var seen = Set<UUID>()
        return result.timeline.flatMap(\.portions).compactMap { portion in
            guard !seen.contains(portion.snackID) else { return nil }
            seen.insert(portion.snackID)
            return portion.snackID
        }
    }

    private func totalQuantity(for snackID: UUID) -> Double {
        result.timeline.flatMap(\.portions)
            .filter { $0.snackID == snackID }
            .reduce(0) { $0 + $1.quantity }
    }
}
