import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResults = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                planTab
                    .opacity(appState.selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == 0)
                    .accessibilityHidden(appState.selectedTab != 0)

                historyTab
                    .opacity(appState.selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == 1)
                    .accessibilityHidden(appState.selectedTab != 1)

                snacksTab
                    .opacity(appState.selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == 2)
                    .accessibilityHidden(appState.selectedTab != 2)

                settingsTab
                    .opacity(appState.selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == 3)
                    .accessibilityHidden(appState.selectedTab != 3)
            }

            FuelZoneFloatingTabBar(selection: $appState.selectedTab)
        }
        .background(DesignSystem.appBackground)
    }

    private var planTab: some View {
        NavigationStack {
            SessionSetupView(
                viewModel: appState.sessionViewModel,
                showResults: $showResults
            )
            .navigationDestination(isPresented: $showResults) {
                ResultsView(
                    viewModel: appState.resultsViewModel,
                    snackViewModel: appState.snackViewModel
                )
            }
        }
    }

    private var historyTab: some View {
        NavigationStack {
            HistoryView(viewModel: appState.historyViewModel)
        }
    }

    private var snacksTab: some View {
        NavigationStack {
            SnackLibraryView(viewModel: appState.snackViewModel)
        }
    }

    private var settingsTab: some View {
        NavigationStack {
            SettingsView()
        }
    }
}
