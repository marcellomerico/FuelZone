import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.records.isEmpty {
                    emptyState
                } else {
                    FuelZoneScreenScroll {
                        ForEach(viewModel.records) { record in
                            NavigationLink {
                                SessionDetailView(record: record)
                            } label: {
                                HistoryRow(record: record)
                                    .fuelZoneCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(Text(localized: "history.title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear { viewModel.reload() }
        }
    }

    private var emptyState: some View {
        FuelZoneScreenScroll {
            FuelZoneHeroBlock(
                systemImage: "clock",
                titleKey: "history.empty.title",
                subtitleKey: "history.empty"
            )
        }
    }
}

private struct HistoryRow: View {
    let record: SessionRecord

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.setup.sport.systemImageName)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(DesignSystem.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(record.savedAt, style: .date)
                    .font(DesignSystem.Typography.cardTitle)
                HStack(spacing: 8) {
                    Text(LocalizedEnum.label(for: record.setup.sport))
                    Text("·")
                    Text(NutritionMetricsFormatting.historyDuration(minutes: record.result.sessionDurationMinutes))
                }
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
                Text(NutritionMetricsFormatting.carbsPerHour(value: Int(record.result.carbsPerHour.midpoint)))
                    .font(DesignSystem.Typography.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}
