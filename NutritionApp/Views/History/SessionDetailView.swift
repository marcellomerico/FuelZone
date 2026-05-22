import SwiftUI

struct SessionDetailView: View {
    @EnvironmentObject private var appState: AppState
    let record: SessionRecord

    @StateObject private var detailViewModel: SessionDetailViewModel

    init(record: SessionRecord) {
        self.record = record
        _detailViewModel = StateObject(wrappedValue: SessionDetailViewModel(
            record: record,
            settings: AppSettings(),
            snacks: []
        ))
    }

    var body: some View {
        SessionDetailResultsView(
            viewModel: detailViewModel,
            snackViewModel: appState.snackViewModel
        )
        .onAppear {
            detailViewModel.updateSettings(appState.settings)
            detailViewModel.updateSnacks(appState.snackViewModel.allSnacks())
        }
    }
}
