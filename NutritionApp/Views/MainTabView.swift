import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showResults = false

    var body: some View {
        TabView {
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
            .tabItem {
                Label {
                    Text(localized: "tab.plan")
                } icon: {
                    Image(systemName: "flame.fill")
                }
            }

            HistoryView(viewModel: appState.historyViewModel)
                .tabItem {
                    Label {
                        Text(localized: "tab.history")
                    } icon: {
                        Image(systemName: "clock.fill")
                    }
                }

            SettingsView()
                .tabItem {
                    Label {
                        Text(localized: "tab.settings")
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
        }
        .tint(Color.accentColor)
    }
}
