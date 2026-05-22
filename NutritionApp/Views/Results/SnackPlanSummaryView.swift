import SwiftUI

struct SnackPlanSummaryView: View {
    let result: FuelingResult
    let snacks: [Snack]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "results.snackPlan",
                subtitleKey: "results.snackPlan.hint",
                systemImage: "takeoutbag.and.cup.and.straw"
            )

            Text(NutritionMetricsFormatting.snackPlanTotals(
                carbs: Int(aggregateTotals().carbs),
                sodium: Int(aggregateTotals().sodium),
                fluids: aggregateTotals().fluids
            ))
            .font(DesignSystem.Typography.bodySecondary)
            .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(uniqueSnackIDs().enumerated()), id: \.element) { index, id in
                    if let snack = snacks.first(where: { $0.id == id }) {
                        HStack(spacing: 12) {
                            Image(systemName: snack.category.systemImageName)
                                .foregroundStyle(Color.accentColor)
                            Text("\(totalQuantity(for: id), specifier: "%.1f")× \(snack.localizedName)")
                                .font(DesignSystem.Typography.bodySecondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        if index < uniqueSnackIDs().count - 1 {
                            FuelZoneCardDivider()
                        }
                    }
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
