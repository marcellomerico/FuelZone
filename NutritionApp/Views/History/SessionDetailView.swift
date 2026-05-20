import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject private var appState: AppState
    let record: SessionRecord

    var body: some View {
        ResultsView(
            viewModel: appState.resultsViewModel,
            snackViewModel: appState.snackViewModel
        )
        .onAppear {
            appState.resultsViewModel.setResult(
                record.result,
                setup: record.setup,
                profile: UserProfile(weightKg: record.profileWeightKg)
            )
        }
    }
}
