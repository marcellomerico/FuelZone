import SwiftUI

/// History tab: saved plans grouped by month, swipe to plan again or delete.
struct HistoryView: View {
    @EnvironmentObject private var appState: AppState
    var onReplan: () -> Void = {}

    private var records: [SessionRecord] {
        appState.store.visibleHistory(isPro: appState.isPro)
    }

    private var hiddenCount: Int {
        appState.store.history.count - records.count
    }

    private var groups: [(title: String, records: [SessionRecord])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record -> Date in
            calendar.dateInterval(of: .month, for: record.savedAt)?.start ?? record.savedAt
        }
        return grouped.keys.sorted(by: >).map { month in
            let title = calendar.isDate(month, equalTo: .now, toGranularity: .month)
                ? L10n.string("history.thisMonth")
                : month.formatted(.dateTime.month(.wide).year())
            return (title, grouped[month] ?? [])
        }
    }

    var body: some View {
        List {
            FZScreenHeader(eyebrow: L10n.string("history.eyebrow"), title: L10n.string("history.title"))
                .listRowInsets(EdgeInsets(top: 8, leading: Theme.Spacing.screen, bottom: 4, trailing: Theme.Spacing.screen))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            if records.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(groups, id: \.title) { group in
                Section {
                    ForEach(group.records) { record in
                        NavigationLink(value: record.id) {
                            HistoryCard(record: record)
                        }
                        .listRowInsets(EdgeInsets(top: 5, leading: Theme.Spacing.screen, bottom: 5, trailing: Theme.Spacing.screen))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { appState.store.deleteSession(id: record.id) }
                            } label: {
                                Label { Text(localized: "history.action.delete") } icon: { Image(systemName: "trash") }
                            }
                            Button {
                                appState.sessionViewModel.reuse(record)
                                onReplan()
                            } label: {
                                Label { Text(localized: "history.action.replan") } icon: { Image(systemName: "arrow.clockwise") }
                            }
                            .tint(Theme.Colors.ink)
                        }
                        .contextMenu {
                            Button {
                                appState.sessionViewModel.reuse(record)
                                onReplan()
                            } label: {
                                Label { Text(localized: "history.action.replan") } icon: { Image(systemName: "arrow.clockwise") }
                            }
                            Button(role: .destructive) {
                                appState.store.deleteSession(id: record.id)
                            } label: {
                                Label { Text(localized: "history.action.delete") } icon: { Image(systemName: "trash") }
                            }
                        }
                    }
                } header: {
                    Text(group.title).fzLabelStyle().padding(.leading, 4)
                }
            }

            if hiddenCount > 0 {
                Button {
                    showPaywall = true
                } label: {
                    FZBanner(message: L10n.format("history.freeLimit", "\(hiddenCount)"))
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .fzScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    @State private var showPaywall = false

    private var emptyState: some View {
        VStack(spacing: 14) {
            FZIconTile(systemImage: "flame.fill", foreground: Theme.Colors.accentText, background: Theme.Nutrient.carbs.tint, size: 72)
            Text(localized: "history.empty.title")
                .font(Theme.Typography.title)
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.center)
            Text(localized: "history.empty")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Colors.ink2)
                .multilineTextAlignment(.center)
            Button {
                appState.selectedTab = .plan
            } label: {
                Text(localized: "history.empty.cta")
            }
            .buttonStyle(.fzPrimary)
            .padding(.top, 6)
        }
        .padding(.horizontal, 30)
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }
}

/// Card with title, date, key numbers and a mini Fuel Track.
private struct HistoryCard: View {
    let record: SessionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                FZIconTile(systemImage: record.setup.sport.systemImageName)
                VStack(alignment: .leading, spacing: 2) {
                    Text(PlanPresentation.title(for: record))
                        .font(.headline.weight(.heavy).width(.expanded))
                        .foregroundStyle(Theme.Colors.ink)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.ink2)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 0) {
                FZMetric(value: FZFormat.clock(minutes: record.result.sessionDurationMinutes), unit: "", caption: L10n.string("unit.hours.short"), size: 26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                FZMetric(value: FZFormat.integer(record.result.carbsPerHour.midpoint), unit: "", caption: L10n.string("history.carbsPerHourCaption"), color: Theme.Nutrient.carbs.color, size: 26)
                    .frame(maxWidth: .infinity, alignment: .leading)
                FZMetric(value: FZFormat.integer(record.result.fluidsPerHourMl.midpoint), unit: "", caption: L10n.string("history.fluidsPerHourCaption"), color: Theme.Nutrient.fluids.color, size: 26)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            MiniTrack(result: record.result)
        }
        .fzCard(padding: 16)
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let date = record.savedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return "\(date) · \(LocalizedEnum.label(for: record.setup.temperature))"
    }
}

/// Tiny course line with dots for each stop (amber = carbs, blue = fluids only).
private struct MiniTrack: View {
    let result: FuelingResult

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.line).frame(height: 2)
                ForEach(result.timeline.filter { !$0.portions.isEmpty }) { step in
                    let position = CGFloat(PlanPresentation.intakeMinute(for: step)) / CGFloat(max(1, result.sessionDurationMinutes))
                    let hasCarbs = step.targetCarbsGrams > 0
                    Circle()
                        .fill(hasCarbs ? Theme.Colors.accentFill : Theme.Nutrient.fluids.color)
                        .frame(width: 9, height: 9)
                        .offset(x: proxy.size.width * position - 4.5)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}
