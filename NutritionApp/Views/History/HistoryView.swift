import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        Group {
            if viewModel.records.isEmpty {
                FuelZoneHistoryEmptyState {
                    appState.selectedTab = 0
                }
                .background(DesignSystem.appBackground)
            } else {
                FuelZoneScreenScroll {
                    ForEach(viewModel.records) { record in
                        NavigationLink {
                            SessionDetailView(record: record)
                        } label: {
                            HistoryRow(record: record)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(Text(localized: "history.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.reload() }
    }
}

private struct HistoryRow: View {
    let record: SessionRecord

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.setup.sport.systemImageName)
                .font(.title3)
                .foregroundStyle(DesignSystem.accent)
                .frame(width: 44, height: 44)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.savedAt, style: .date)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                HStack(spacing: 8) {
                    Text(LocalizedEnum.label(for: record.setup.sport))
                    Text("·")
                    Text(NutritionMetricsFormatting.historyDuration(minutes: record.result.sessionDurationMinutes))
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
                Text(NutritionMetricsFormatting.carbsPerHour(value: Int(record.result.carbsPerHour.midpoint)))
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.accentLight)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DesignSystem.textTertiary)
        }
        .fuelZoneCard()
    }
}
