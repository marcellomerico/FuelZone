import SwiftUI

/// A saved plan: hero number, targets, pack list and Fuel Track. Used after planning and from the history.
struct PlanResultView: View {
    @EnvironmentObject private var appState: AppState
    let recordID: UUID

    var body: some View {
        PlanResultContent(
            viewModel: PlanResultViewModel(
                recordID: recordID,
                store: appState.store,
                isPro: { [weak appState] in appState?.isPro ?? false }
            )
        )
    }
}

private struct PlanResultContent: View {
    @EnvironmentObject private var appState: AppState
    @StateObject var viewModel: PlanResultViewModel
    @State private var showRename = false
    @State private var newTitle = ""

    var body: some View {
        Group {
            if let record = viewModel.record, let summary = viewModel.summary {
                content(record: record, summary: summary)
            } else {
                ContentUnavailableView(L10n.string("history.detail.missing"), systemImage: "clock.badge.xmark")
            }
        }
        .fzScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.swapContext) { context in
            SnackSwapSheet(snacks: viewModel.swapCandidates, kitIDs: Set(appState.store.kitSnacks.map(\.id))) { snack in
                viewModel.swap(stepID: context.stepID, portionID: context.portionID, to: snack)
            }
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            PaywallView()
        }
        .alert(Text(localized: "results.rename"), isPresented: $showRename) {
            TextField(L10n.string("results.rename.placeholder"), text: $newTitle)
            Button(role: .cancel) {} label: { Text(localized: "common.cancel") }
            Button { viewModel.rename(to: newTitle) } label: { Text(localized: "common.save") }
        }
    }

    private func content(record: SessionRecord, summary: FuelPlanSummary) -> some View {
        let result = record.result
        let hasSnacks = !summary.packItems.isEmpty
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                chips(record)
                hero(result: result, summary: summary, hasSnacks: hasSnacks)
                HStack(spacing: 10) {
                    nutrientTile(
                        title: L10n.string("results.fluids"), icon: "drop.fill", nutrient: .fluids,
                        value: hasSnacks || summary.waterMl > 0 ? summary.fluidsPerHour : result.fluidsPerHourMl.midpoint,
                        unit: "ml/h", target: result.fluidsPerHourMl, scaleMax: 1300
                    )
                    nutrientTile(
                        title: L10n.string("results.sodium"), icon: "diamond.fill", nutrient: .sodium,
                        value: hasSnacks ? summary.sodiumPerHour : result.sodiumPerHourMg.midpoint,
                        unit: "mg/h", target: result.sodiumPerHourMg, scaleMax: 900
                    )
                }

                ForEach(viewModel.warningMessages(), id: \.self) { message in
                    FZBanner(message: message, style: .warning)
                }
                if !hasSnacks, result.sessionDurationMinutes >= AppConstants.minimumFuelingSessionMinutes {
                    FZBanner(message: L10n.string("results.emptyKit"))
                }

                if hasSnacks || summary.waterMl > 0 {
                    FZSectionHeader(
                        title: L10n.string("results.packList"),
                        trailing: L10n.format("results.packList.for", FZFormat.clock(minutes: result.sessionDurationMinutes))
                    )
                    .padding(.top, 8)
                    packList(summary)
                }

                if result.timeline.contains(where: { !$0.portions.isEmpty || $0.waterMl > 0 }) {
                    FZSectionHeader(
                        title: L10n.string("results.fuelTrack"),
                        trailing: L10n.string(viewModel.canSwapSnacks ? "results.fuelTrack.hint" : "results.fuelTrack.hintPro")
                    )
                    .padding(.top, 8)
                    FuelTrackView(
                        stops: PlanPresentation.stops(for: result, snack: viewModel.snack(for:)),
                        canSwap: viewModel.canSwapSnacks,
                        onSwap: { stepID, portionID in viewModel.requestSwap(stepID: stepID, portionID: portionID) }
                    )
                }

                HStack(spacing: 10) {
                    ShareLink(item: PlanPresentation.shareText(record: record, summary: summary, snack: viewModel.snack(for:))) {
                        Label { Text(localized: "results.share") } icon: { Image(systemName: "square.and.arrow.up") }
                    }
                    .buttonStyle(.fzSecondary)
                    Label { Text(localized: "results.saved") } icon: { Image(systemName: "checkmark") }
                        .font(Theme.Typography.subheadlineEmphasis)
                        .foregroundStyle(Theme.Colors.ink2)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.Colors.surface2))
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.vertical, 12)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(PlanPresentation.title(for: record))
                        .font(.headline.weight(.heavy).width(.expanded))
                        .foregroundStyle(Theme.Colors.ink)
                    Text(record.savedAt.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.ink2)
                }
                .accessibilityElement(children: .combine)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        newTitle = record.title ?? ""
                        showRename = true
                    } label: {
                        Label { Text(localized: "results.rename") } icon: { Image(systemName: "pencil") }
                    }
                    NavigationLink {
                        FuelingMethodologyView()
                    } label: {
                        Label { Text(localized: "methodology.title") } icon: { Image(systemName: "book.closed") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Text(localized: "common.more"))
            }
        }
    }

    private func chips(_ record: SessionRecord) -> some View {
        let setup = record.setup
        let intensity = setup.intensityMode == .simple
            ? LocalizedEnum.label(for: setup.simpleIntensity)
            : L10n.string("plan.intensity.zones")
        let items = [
            L10n.format("results.chip.duration", FZFormat.clock(minutes: record.result.sessionDurationMinutes)),
            intensity,
            "\(LocalizedEnum.label(for: setup.temperature)) · \(LocalizedEnum.label(for: setup.conditions))",
        ]
        return FlowLayout(spacing: 6) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(Theme.Typography.caption.weight(.bold))
                    .foregroundStyle(Theme.Colors.ink)
                    .padding(.horizontal, 11)
                    .frame(minHeight: 28)
                    .background(Capsule().fill(Theme.Colors.surface2))
            }
        }
    }

    private func hero(result: FuelingResult, summary: FuelPlanSummary, hasSnacks: Bool) -> some View {
        let planned = hasSnacks ? summary.carbsPerHour : result.carbsPerHour.midpoint
        let inTarget = summary.carbsWithinTarget(result.carbsPerHour)
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(localized: "results.carbs").fzLabelStyle()
                Spacer()
                if hasSnacks {
                    Label {
                        Text(localized: inTarget ? "results.inTarget" : "results.offTarget")
                    } icon: {
                        Image(systemName: inTarget ? "checkmark" : "exclamationmark.triangle.fill")
                    }
                    .font(Theme.Typography.subheadlineEmphasis)
                    .foregroundStyle(Theme.Colors.accentText)
                }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                MetricText(FZFormat.integer(planned), size: 120, color: Theme.Nutrient.carbs.color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: "results.perHourGrams")
                        .font(.title3.weight(.heavy).width(.condensed))
                        .foregroundStyle(Theme.Nutrient.carbs.color)
                    Text(L10n.format(
                        "results.targetLine",
                        FZFormat.range(result.carbsPerHour),
                        FZFormat.integer(hasSnacks ? summary.totalCarbs : result.totalCarbsGrams.midpoint)
                    ))
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.ink2)
                }
            }
            if result.sessionDurationMinutes >= AppConstants.minimumFuelingSessionMinutes {
                CarbTierMeter(target: result.carbsPerHour, planned: planned)
            }
        }
        .fzCard(padding: 18, radius: Theme.Radius.hero)
        .accessibilityElement(children: .combine)
    }

    private func nutrientTile(
        title: String, icon: String, nutrient: Theme.Nutrient,
        value: Double, unit: String, target: NutritionRange, scaleMax: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label { Text(title).fzLabelStyle() } icon: {
                Image(systemName: icon).font(.caption.weight(.bold)).foregroundStyle(nutrient.color)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                MetricText(FZFormat.integer(value), size: 46, color: nutrient.color, relativeTo: .title)
                Text(unit).font(Theme.Typography.caption.weight(.bold)).foregroundStyle(nutrient.color)
            }
            FZRangeMeter(range: 0...scaleMax, target: target.min...target.max, value: value, nutrient: nutrient)
            Text(L10n.format("results.target", FZFormat.range(target), unit))
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fzCard(padding: 14)
        .accessibilityElement(children: .combine)
    }

    private func packList(_ summary: FuelPlanSummary) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(summary.packItems.enumerated()), id: \.element.id) { index, item in
                packRow(
                    icon: PlanPresentation.icon(for: item.snack),
                    nutrient: PlanPresentation.nutrient(for: item.snack),
                    count: "\(item.unitsToPack)×",
                    title: item.snack.localizedName,
                    detail: L10n.format(
                        "results.packItem.detail",
                        FZFormat.integer(item.snack.carbsPerDefaultPortion),
                        FZFormat.integer(item.snack.sodiumMgPerDefaultPortion)
                    )
                )
                if index < summary.packItems.count - 1 || summary.waterMl > 0 {
                    Divider().overlay(Theme.Colors.line)
                }
            }
            if summary.waterMl > 0 {
                packRow(
                    icon: "drop.fill", nutrient: .fluids, count: "\(summary.waterMl)",
                    title: L10n.string("results.water.name"), detail: L10n.string("results.water.detail")
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.Colors.surface))
    }

    private func packRow(icon: String, nutrient: Theme.Nutrient, count: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            FZIconTile(systemImage: icon, foreground: nutrient.color, background: nutrient.tint)
            MetricText(count, size: 32, relativeTo: .title2)
                .frame(minWidth: 48, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Typography.bodyEmphasis).foregroundStyle(Theme.Colors.ink)
                Text(detail).font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
