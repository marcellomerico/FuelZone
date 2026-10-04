import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var appState: AppState

    private var records: [SessionRecord] {
        appState.store.visibleHistory(isPro: appState.isPro)
    }

    var body: some View {
        Group {
            if records.isEmpty {
                FuelZoneHistoryEmptyState {
                    appState.selectedTab = .plan
                }
                .background(DesignSystem.appBackground)
            } else {
                List {
                    ForEach(records) { record in
                        NavigationLink {
                            PlanResultView(recordID: record.id)
                        } label: {
                            HistoryRow(record: record)
                        }
                        .listRowSeparator(.hidden)
                        .listRowBackground(DesignSystem.appBackground)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                appState.store.deleteSession(id: record.id)
                            } label: {
                                Label { Text(localized: "history.action.delete") } icon: { Image(systemName: "trash") }
                            }
                            Button {
                                appState.sessionViewModel.reuse(record)
                                appState.selectedTab = .plan
                            } label: {
                                Label { Text(localized: "history.action.replan") } icon: { Image(systemName: "arrow.clockwise") }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DesignSystem.appBackground)
            }
        }
        .navigationTitle(Text(localized: "history.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
