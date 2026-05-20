import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    ContentUnavailableView {
                        Label {
                            Text(localized: "history.empty")
                        } icon: {
                            Image(systemName: "clock")
                        }
                    }
                } else {
                    List {
                        ForEach(viewModel.records) { record in
                            NavigationLink {
                                SessionDetailView(record: record)
                            } label: {
                                HistoryRow(record: record)
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                }
            }
            .navigationTitle(Text(localized: "history.title"))
            .onAppear { viewModel.reload() }
        }
    }
}

private struct HistoryRow: View {
    let record: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.savedAt, style: .date)
                .font(.headline)
            HStack {
                Label(LocalizedEnum.label(for: record.setup.sport), systemImage: record.setup.sport.systemImageName)
                Text("· \(record.result.sessionDurationMinutes) min")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text("\(Int(record.result.carbsPerHour.midpoint)) g/h")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        }
    }
}
