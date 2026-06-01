import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: ResultsViewModel
    @ObservedObject var snackViewModel: SnackViewModel
    @State private var showLibrary = false

    var body: some View {
        FuelZoneScreenScroll {
            summarySection
            warningsSection
            if let result = viewModel.result {
                SnackPlanSummaryView(
                    result: result,
                    snacks: snackViewModel.allSnacks()
                )
            }
            timelineSection
            snackPlanLink
        }
        .navigationTitle(Text(localized: "results.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FuelingMethodologyView()
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(DesignSystem.accent)
                }
                .accessibilityLabel(Text(localized: "results.methodology.link"))
            }
        }
        .sheet(isPresented: $showLibrary) {
            NavigationStack {
                SnackLibraryView(viewModel: snackViewModel)
                    .environmentObject(appState)
            }
        }
        .sheet(item: $viewModel.swapContext) { context in
            SnackSwapSheet(snacks: snackViewModel.enabledSnacks()) { snack in
                viewModel.swapSnack(stepID: context.stepID, portionID: context.portionID, to: snack)
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet { appState.selectedTab = 3 }
                .environmentObject(appState)
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
                NutritionCardView(
                    titleKey: "results.carbs",
                    value: viewModel.carbsPerHourText(),
                    subtitleKey: "results.perHour",
                    systemImage: "flame.fill"
                )
                NutritionCardView(
                    titleKey: "results.fluids",
                    value: viewModel.fluidsPerHourText(),
                    subtitleKey: "results.perHour",
                    systemImage: "drop.fill"
                )
                NutritionCardView(
                    titleKey: "results.sodium",
                    value: viewModel.sodiumPerHourText(),
                    subtitleKey: "results.perHour",
                    systemImage: "bolt.fill"
                )
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
            FuelTimelineView(viewModel: viewModel, snacks: snackViewModel.allSnacks())
        }
    }

    private var snackPlanLink: some View {
        NavigationLink {
            SnackLibraryView(viewModel: snackViewModel)
                .environmentObject(appState)
        } label: {
            FuelZoneNavigationRow(
                titleKey: "results.openLibrary",
                subtitleKey: "results.openLibrary.hint",
                systemImage: "fork.knife.circle.fill"
            )
            .fuelZoneCard()
        }
        .buttonStyle(.plain)
    }
}
