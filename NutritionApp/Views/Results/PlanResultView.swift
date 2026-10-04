import SwiftUI

/// A saved plan: targets, pack list and timeline. Used right after planning and from the history.
struct PlanResultView: View {
    @EnvironmentObject private var appState: AppState
    let recordID: UUID

    var body: some View {
        PlanResultContent(
            viewModel: PlanResultViewModel(
                recordID: recordID,
                store: appState.store,
                isPro: { [weak appState] in appState?.isPro ?? false }
            )
        )
    }
}

private struct PlanResultContent: View {
    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel: PlanResultViewModel

    var body: some View {
        FuelZoneScreenScroll {
            if let result = viewModel.result, let summary = viewModel.summary {
                targetsSection(result)
                ForEach(viewModel.warningMessages(), id: \.self) { message in
                    FuelZoneInfoBanner(message: message, style: .warning)
                }
                packListSection(summary)
                timelineSection(result)
            } else {
                FuelZoneInfoBanner(message: L10n.string("history.detail.missing"), style: .info)
            }
        }
        .navigationTitle(Text(localized: "results.title"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.swapContext) { context in
            SnackSwapSheet(snacks: viewModel.swapCandidates) { snack in
                viewModel.swap(stepID: context.stepID, portionID: context.portionID, to: snack)
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet().environmentObject(appState)
        }
    }

    private func targetsSection(_ result: FuelingResult) -> some View {
        VStack(spacing: 10) {
            NutritionCardView(titleKey: "results.carbs", value: format(result.carbsPerHour, unit: "g"), subtitleKey: "results.perHour", systemImage: "flame.fill")
            NutritionCardView(titleKey: "results.fluids", value: format(result.fluidsPerHourMl, unit: "ml"), subtitleKey: "results.perHour", systemImage: "drop.fill")
            NutritionCardView(titleKey: "results.sodium", value: format(result.sodiumPerHourMg, unit: "mg"), subtitleKey: "results.perHour", systemImage: "bolt.fill")
        }
    }

    private func packListSection(_ summary: FuelPlanSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FuelZoneSectionHeader(titleKey: "results.snackPlan")
            ForEach(summary.packItems) { item in
                Text("\(item.unitsToPack)× \(item.snack.localizedName)")
                    .font(DesignSystem.Typography.bodySecondary)
            }
            if summary.waterMl > 0 {
                Text(L10n.format("results.water.total", "\(summary.waterMl)"))
                    .font(DesignSystem.Typography.bodySecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fuelZoneCard()
    }

    private func timelineSection(_ result: FuelingResult) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            FuelZoneSectionHeader(titleKey: "results.timeline")
            ForEach(result.timeline) { step in
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.format("timeline.step.range", "\(step.startMinute)", "\(step.endMinute)"))
                        .font(DesignSystem.Typography.cardTitle)
                    ForEach(step.portions) { portion in
                        if let snack = viewModel.snack(for: portion) {
                            Button {
                                viewModel.requestSwap(stepID: step.id, portionID: portion.id)
                            } label: {
                                Text(NutritionMetricsFormatting.portionLine(portion: portion, snack: snack))
                                    .font(DesignSystem.Typography.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if step.waterMl > 0 {
                        Text(L10n.format("results.water.step", "\(step.waterMl)"))
                            .font(DesignSystem.Typography.caption)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fuelZoneCard()
            }
        }
    }

    private func format(_ range: NutritionRange, unit: String) -> String {
        L10n.format("results.range.format", "\(Int(range.min.rounded()))", "\(Int(range.max.rounded()))", unit)
    }
}
