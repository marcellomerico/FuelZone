import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var planPath: [UUID] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                planTab
                    .opacity(appState.selectedTab == .plan ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .plan)
                    .accessibilityHidden(appState.selectedTab != .plan)

                historyTab
                    .opacity(appState.selectedTab == .history ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .history)
                    .accessibilityHidden(appState.selectedTab != .history)

                snacksTab
                    .opacity(appState.selectedTab == .snacks ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .snacks)
                    .accessibilityHidden(appState.selectedTab != .snacks)

                settingsTab
                    .opacity(appState.selectedTab == .settings ? 1 : 0)
                    .allowsHitTesting(appState.selectedTab == .settings)
                    .accessibilityHidden(appState.selectedTab != .settings)
            }

            FuelZoneFloatingTabBar(selection: $appState.selectedTab)
        }
        .background(DesignSystem.appBackground)
    }

    private var planTab: some View {
        NavigationStack(path: $planPath) {
            SessionSetupView(viewModel: appState.sessionViewModel) { recordID in
                planPath.append(recordID)
            }
            .navigationDestination(for: UUID.self) { recordID in
                PlanResultView(recordID: recordID)
            }
        }
    }

    private var historyTab: some View {
        NavigationStack {
            HistoryView()
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
