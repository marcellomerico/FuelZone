import SwiftUI

struct FuelTimelineView: View {
    @ObservedObject var viewModel: ResultsViewModel
    let snacks: [Snack]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let timeline = viewModel.result?.timeline {
                ForEach(timeline) { step in
                    TimelineStepRow(step: step, viewModel: viewModel)
                }
            }
        }
    }
}

private struct TimelineStepRow: View {
    let step: TimelineStep
    @ObservedObject var viewModel: ResultsViewModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                Rectangle().fill(Color.accentColor.opacity(0.3)).frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(L10n.format("timeline.step.range", "\(step.startMinute)", "\(step.endMinute)"))
                        .font(DesignSystem.Typography.cardTitle)
                    if step.isUserModified {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }

                Text(NutritionMetricsFormatting.stepTargets(
                    carbs: step.targetCarbsGrams,
                    fluidsMl: step.targetFluidsMl,
                    sodiumMg: step.targetSodiumMg
                ))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

                ForEach(step.portions) { portion in
                    if let snack = viewModel.snack(for: portion) {
                        portionRow(portion: portion, snack: snack)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fuelZoneCard()
        }
    }

    @ViewBuilder
    private func portionRow(portion: SnackPortion, snack: Snack) -> some View {
        let label = HStack {
            Image(systemName: snack.category.systemImageName)
            Text(NutritionMetricsFormatting.snackQuantityLine(
                quantity: portion.quantity,
                name: snack.localizedName
            ))
            .font(.caption)
            Spacer()
            if viewModel.canSwapSnacks {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }

        if viewModel.canSwapSnacks {
            Button {
                viewModel.requestSwap(stepID: step.id, portionID: portion.id)
            } label: {
                label
            }
            .buttonStyle(.plain)
        } else {
            Button {
                viewModel.showProPaywall = true
            } label: {
                label
            }
            .buttonStyle(.plain)
        }
    }
}
