import SwiftUI

struct SessionDetailResultsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionDetailViewModel
    @ObservedObject var snackViewModel: SnackViewModel
    @State private var swapContext: SnackSwapContext?

    var body: some View {
        FuelZoneScreenScroll {
            summarySection
            warningsSection
            SnackPlanSummaryView(result: viewModel.result, snacks: snackViewModel.allSnacks())
            timelineSection
        }
        .navigationTitle(Text(localized: "history.detail.title"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FuelingMethodologyView()
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .sheet(item: $swapContext) { context in
            SnackSwapSheet(snacks: snackViewModel.enabledSnacks()) { snack in
                viewModel.swapSnack(stepID: context.stepID, portionID: context.portionID, to: snack)
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet { appState.selectedTab = 2 }
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "results.summary.title",
                subtitleKey: "results.summary.subtitle",
                systemImage: "chart.bar.fill"
            )
            VStack(spacing: 10) {
                NutritionCardView(titleKey: "results.carbs", value: viewModel.carbsPerHourText(), subtitleKey: "results.perHour", systemImage: "flame.fill")
                NutritionCardView(titleKey: "results.fluids", value: viewModel.fluidsPerHourText(), subtitleKey: "results.perHour", systemImage: "drop.fill")
                NutritionCardView(titleKey: "results.sodium", value: viewModel.sodiumPerHourText(), subtitleKey: "results.perHour", systemImage: "bolt.fill")
            }
        }
    }

    @ViewBuilder
    private var warningsSection: some View {
        ForEach(viewModel.warningMessages(), id: \.self) { message in
            FuelZoneInfoBanner(message: message, style: .warning)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "results.timeline",
                subtitleKey: "results.timeline.hint",
                systemImage: "list.bullet.clipboard"
            )
            SessionDetailTimelineView(viewModel: viewModel, snacks: snackViewModel.allSnacks(), swapContext: $swapContext)
        }
    }
}

private struct SessionDetailTimelineView: View {
    @ObservedObject var viewModel: SessionDetailViewModel
    let snacks: [Snack]
    @Binding var swapContext: SnackSwapContext?

    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.result.timeline) { step in
                sessionStepRow(step)
            }
        }
    }

    private func sessionStepRow(_ step: TimelineStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle().fill(Color.accentColor).frame(width: 10, height: 10)
                Rectangle().fill(Color.accentColor.opacity(0.25)).frame(width: 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.format("timeline.step.range", "\(step.startMinute)", "\(step.endMinute)"))
                    .font(DesignSystem.Typography.cardTitle)
                Text(NutritionMetricsFormatting.stepTargets(
                    carbs: step.targetCarbsGrams,
                    fluidsMl: step.targetFluidsMl,
                    sodiumMg: step.targetSodiumMg
                ))
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

                ForEach(step.portions) { portion in
                    if let snack = viewModel.snack(for: portion) {
                        Button {
                            if viewModel.canSwapSnacks {
                                swapContext = SnackSwapContext(stepID: step.id, portionID: portion.id)
                            } else {
                                viewModel.showProPaywall = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: snack.category.systemImageName)
                                    .foregroundStyle(Color.accentColor)
                                Text(NutritionMetricsFormatting.snackQuantityLine(quantity: portion.quantity, name: snack.localizedName))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.canSwapSnacks {
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fuelZoneCard()
        }
    }
}
