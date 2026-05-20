import SwiftUI

struct ResultsView: View {
    @ObservedObject var viewModel: ResultsViewModel
    @ObservedObject var snackViewModel: SnackViewModel
    @State private var showLibrary = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.sectionSpacing) {
                cardsSection
                warningsSection
                if let result = viewModel.result {
                    SnackPlanSummaryView(
                        result: result,
                        snacks: snackViewModel.allSnacks()
                    )
                }
                FuelTimelineView(viewModel: viewModel, snacks: snackViewModel.allSnacks())
                snackPlanLink
            }
            .padding()
        }
        .background(DesignSystem.groupedBackground)
        .navigationTitle(Text(localized: "results.title"))
        .sheet(isPresented: $showLibrary) {
            NavigationStack {
                SnackLibraryView(viewModel: snackViewModel)
            }
        }
    }

    private var cardsSection: some View {
        VStack(spacing: 12) {
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

    @ViewBuilder
    private var warningsSection: some View {
        ForEach(viewModel.warningMessages(), id: \.self) { message in
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .fuelZoneCard()
        }
    }

    private var snackPlanLink: some View {
        Button { showLibrary = true } label: {
            Label {
                Text(localized: "results.openLibrary")
            } icon: {
                Image(systemName: "fork.knife")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fuelZoneCard()
    }
}
