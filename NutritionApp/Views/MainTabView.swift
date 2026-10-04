import SwiftUI

/// Native tab bar (Liquid Glass on iOS 26+). Each tab keeps its own navigation stack.
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var planPath: [UUID] = []
    @State private var historyPath: [UUID] = []

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            NavigationStack(path: $planPath) {
                PlanView(viewModel: appState.sessionViewModel) { recordID in
                    planPath.append(recordID)
                }
                .navigationDestination(for: UUID.self) { PlanResultView(recordID: $0) }
            }
            .tabItem { Label { Text(localized: "tab.plan") } icon: { Image(systemName: "flame") } }
            .tag(AppTab.plan)

            NavigationStack(path: $historyPath) {
                HistoryView {
                    planPath = []
                    appState.selectedTab = .plan
                }
                .navigationDestination(for: UUID.self) { PlanResultView(recordID: $0) }
            }
            .tabItem { Label { Text(localized: "tab.history") } icon: { Image(systemName: "clock") } }
            .tag(AppTab.history)

            NavigationStack {
                SnacksView(viewModel: appState.snackViewModel)
            }
            .tabItem { Label { Text(localized: "tab.snacks") } icon: { Image(systemName: "bag") } }
            .tag(AppTab.snacks)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label { Text(localized: "tab.settings") } icon: { Image(systemName: "gearshape") } }
            .tag(AppTab.settings)
        }
        .tint(Theme.Colors.accentText)
    }
}
