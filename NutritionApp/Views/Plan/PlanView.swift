import SwiftUI

/// Plan tab: describe the session, watch the live numbers in the dock, create the plan.
struct PlanView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel
    var onPlanCreated: (UUID) -> Void

    @State private var showConditions = false

    private var preview: PlanPreview? {
        viewModel.planPreview(profile: appState.store.profile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                FZScreenHeader(eyebrow: L10n.string("plan.eyebrow"), title: L10n.string("plan.title")) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        Text(initials)
                            .font(.subheadline.weight(.heavy).width(.expanded))
                    }
                    .buttonStyle(FZIconButtonStyle())
                    .accessibilityLabel(Text(localized: "profile.title"))
                }

                sportChips
                DurationCard(viewModel: viewModel)
                IntensityCard(viewModel: viewModel)
                conditionsRow

                if let error = viewModel.errorMessage {
                    FZBanner(message: error, style: .warning)
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .fzScreenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { dock }
        .sheet(isPresented: $showConditions) {
            ConditionsSheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showProPaywall) {
            PaywallView()
        }
        .onChange(of: viewModel.setup.durationMinutes) { _, _ in viewModel.syncZoneDistributionToSessionDuration() }
        .onChange(of: viewModel.setup.durationInputMode) { _, _ in viewModel.syncZoneDistributionToSessionDuration() }
        .onChange(of: viewModel.setup.distanceKm) { _, _ in viewModel.syncZoneDistributionToSessionDuration() }
        .onChange(of: viewModel.setup.paceMinutesPerKm) { _, _ in viewModel.syncZoneDistributionToSessionDuration() }
        .onChange(of: viewModel.setup.intensityMode) { _, _ in viewModel.syncZoneDistributionToSessionDuration() }
    }

    private var initials: String {
        let name = appState.store.profile.displayName?.trimmingCharacters(in: .whitespaces) ?? ""
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init)
        return letters.isEmpty ? "FZ" : letters.joined().uppercased()
    }

    private var sportChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SportType.allCases) { sport in
                    FZChip(
                        title: LocalizedEnum.label(for: sport),
                        systemImage: sport.systemImageName,
                        isSelected: viewModel.setup.sport == sport
                    ) {
                        viewModel.setup.sport = sport
                    }
                }
            }
            .padding(.horizontal, Theme.Spacing.screen)
        }
        .padding(.horizontal, -Theme.Spacing.screen)
    }

    private var conditionsRow: some View {
        Button {
            showConditions = true
        } label: {
            HStack(spacing: 12) {
                FZIconTile(systemImage: conditionsIcon)
                VStack(alignment: .leading, spacing: 2) {
                    Text(conditionsTitle)
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundStyle(Theme.Colors.ink)
                    Text(conditionsSubtitle)
                        .font(Theme.Typography.footnote)
                        .foregroundStyle(Theme.Colors.ink2)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Text(localized: "plan.conditions.change")
                    .font(Theme.Typography.subheadlineEmphasis)
                    .foregroundStyle(Theme.Colors.accentText)
            }
            .fzCard(padding: 12)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(localized: "plan.conditions.hint"))
    }

    private var conditionsTitle: String {
        let temperature = LocalizedEnum.label(for: viewModel.setup.temperature)
        let conditions = LocalizedEnum.label(for: viewModel.setup.conditions)
        if let celsius = viewModel.weatherCelsius {
            return "\(Int(celsius.rounded()))° · \(temperature) · \(conditions)"
        }
        return "\(temperature) · \(conditions)"
    }

    private var conditionsSubtitle: String {
        if let place = viewModel.setup.weatherLocationName {
            return L10n.format("plan.conditions.auto", place)
        }
        return L10n.string("plan.conditions.manual")
    }

    private var conditionsIcon: String {
        switch viewModel.setup.temperature {
        case .cool: "thermometer.snowflake"
        case .mild: "sun.max"
        case .warm: "sun.max.fill"
        case .hot: "thermometer.sun.fill"
        }
    }

    private var dock: some View {
        FZGlassPanel {
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    FZMetric(
                        value: preview.map { "\($0.carbsPerHour)" } ?? "–",
                        unit: "g/h",
                        caption: L10n.string("results.carbs"),
                        color: Theme.Nutrient.carbs.color
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    divider
                    FZMetric(
                        value: preview.map { "\($0.fluidsPerHourMl)" } ?? "–",
                        unit: "ml/h",
                        caption: L10n.string("results.fluids"),
                        color: Theme.Nutrient.fluids.color
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    divider
                    FZMetric(
                        value: preview.map { "\($0.sodiumPerHourMg)" } ?? "–",
                        unit: "mg/h",
                        caption: L10n.string("results.sodium"),
                        color: Theme.Nutrient.sodium.color
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 4)

                Button {
                    if let record = viewModel.createPlan() {
                        onPlanCreated(record.id)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(localized: "plan.create")
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(.fzPrimary)
                .disabled(preview == nil)
                .accessibilityIdentifier("plan.create")
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var divider: some View {
        Rectangle().fill(Theme.Colors.line).frame(width: 1, height: 36).padding(.trailing, 12)
    }
}

// MARK: - Duration

private struct DurationCard: View {
    @ObservedObject var viewModel: SessionViewModel

    private static let quickPicks: [(Int, String)] = [(45, "45′"), (60, "1h"), (90, "1:30"), (120, "2h"), (180, "3h"), (240, "4h")]

    private var minutes: Int? { viewModel.setup.resolvedDurationMinutes() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized: "plan.duration").fzLabelStyle()
                Spacer()
                if let minutes {
                    Text(tierLabel(minutes))
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Nutrient.carbs.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Theme.Nutrient.carbs.tint))
                }
            }

            FZSegmentedControl(
                options: DurationInputMode.allCases.map { .init(value: $0, title: modeTitle($0)) },
                selection: $viewModel.setup.durationInputMode
            )

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                MetricText(minutes.map { FZFormat.clock(minutes: $0) } ?? "–:––", size: 92)
                Text(localized: "unit.hours.short")
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundStyle(Theme.Colors.ink2)
            }
            .accessibilityElement(children: .combine)

            switch viewModel.setup.durationInputMode {
            case .duration:
                rulerAndPicks
            case .distanceAndPace:
                HStack(spacing: 10) {
                    FZTextField(label: L10n.string("session.distance.km"), text: decimalBinding(\.distanceKm), placeholder: "21,1", unit: "km", keyboard: .decimalPad)
                    FZTextField(label: L10n.string("session.pace.minPerKm"), text: decimalBinding(\.paceMinutesPerKm), placeholder: "5,5", unit: "min/km", keyboard: .decimalPad)
                }
            case .distanceAndTime:
                FZTextField(label: L10n.string("session.distance.km"), text: decimalBinding(\.distanceKm), placeholder: "42,2", unit: "km", keyboard: .decimalPad)
                rulerAndPicks
            }
        }
        .fzCard()
    }

    private var rulerAndPicks: some View {
        VStack(spacing: 10) {
            DurationRuler(minutes: Binding(
                get: { viewModel.setup.durationMinutes ?? 90 },
                set: { viewModel.setup.durationMinutes = $0 }
            ))
            HStack(spacing: 6) {
                ForEach(Self.quickPicks, id: \.0) { value, label in
                    let isSelected = viewModel.setup.durationMinutes == value
                    Button {
                        viewModel.setup.durationMinutes = value
                    } label: {
                        Text(label)
                            .font(.subheadline.weight(.bold).width(.condensed))
                            .frame(maxWidth: .infinity, minHeight: Theme.minTouch)
                            .foregroundStyle(isSelected ? Theme.Colors.onInk : Theme.Colors.ink)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                                    .fill(isSelected ? Theme.Colors.ink : Theme.Colors.surface2)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private func modeTitle(_ mode: DurationInputMode) -> String {
        switch mode {
        case .duration: L10n.string("plan.duration.mode.time")
        case .distanceAndPace: L10n.string("plan.duration.mode.pace")
        case .distanceAndTime: L10n.string("plan.duration.mode.distanceTime")
        }
    }

    private func tierLabel(_ minutes: Int) -> String {
        switch ExerciseCarbGuidelines.durationTier(for: minutes) {
        case .underMinimum: L10n.string("plan.tier.under")
        case .short: L10n.string("plan.tier.short")
        case .medium: L10n.string("plan.tier.medium")
        case .long: L10n.string("plan.tier.long")
        }
    }

    private func decimalBinding(_ keyPath: WritableKeyPath<SessionSetup, Double?>) -> Binding<String> {
        Binding(
            get: {
                guard let value = viewModel.setup[keyPath: keyPath] else { return "" }
                return value.formatted(.number.precision(.fractionLength(0...2)))
            },
            set: { viewModel.setup[keyPath: keyPath] = InputParsing.decimal($0) }
        )
    }
}

/// Ruler-style duration slider (15 min – 8 h, 5 min steps) with VoiceOver adjust support.
private struct DurationRuler: View {
    @Binding var minutes: Int
    private let range = 15...480
    private let step = 5

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let fraction = CGFloat(minutes - range.lowerBound) / CGFloat(range.upperBound - range.lowerBound)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7).fill(Theme.Colors.surface2).frame(height: 14)
                    HStack(spacing: 0) {
                        ForEach(1..<8, id: \.self) { _ in
                            Spacer()
                            Rectangle().fill(Theme.Colors.line).frame(width: 1, height: 14)
                        }
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 7).fill(Theme.Colors.ink).frame(width: max(14, width * fraction), height: 14)
                    Circle()
                        .fill(Theme.Colors.surface)
                        .overlay(Circle().stroke(Theme.Colors.ink, lineWidth: 3))
                        .frame(width: 28, height: 28)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                        .offset(x: width * fraction - 14)
                }
                .frame(height: Theme.minTouch)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0).onChanged { value in
                        let ratio = min(max(value.location.x / width, 0), 1)
                        let raw = Double(range.lowerBound) + Double(ratio) * Double(range.upperBound - range.lowerBound)
                        let snapped = Int((raw / Double(step)).rounded()) * step
                        if snapped != minutes {
                            minutes = min(max(snapped, range.lowerBound), range.upperBound)
                        }
                    }
                )
            }
            .frame(height: Theme.minTouch)
            .sensoryFeedback(.selection, trigger: minutes / 15)

            HStack {
                ForEach(0..<9, id: \.self) { hour in
                    Text(hour == 0 ? "0" : "\(hour)h")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.Colors.ink3)
                    if hour < 8 { Spacer(minLength: 0) }
                }
            }
            .accessibilityHidden(true)
        }
        .accessibilityElement()
        .accessibilityLabel(Text(localized: "plan.duration"))
        .accessibilityValue(Text(FZFormat.clock(minutes: minutes)))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: minutes = min(minutes + 15, range.upperBound)
            case .decrement: minutes = max(minutes - 15, range.lowerBound)
            @unknown default: break
            }
        }
    }
}

// MARK: - Intensity

private struct IntensityCard: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized: "plan.intensity").fzLabelStyle()
                Spacer()
                FZSegmentedControl(
                    options: [
                        .init(value: IntensityMode.simple, title: L10n.string("session.intensity.simple")),
                        .init(value: IntensityMode.zoneBased, title: L10n.string("plan.intensity.zones"), badge: viewModel.canUseZoneMode ? nil : "PRO"),
                    ],
                    selection: $viewModel.setup.intensityMode,
                    onSelect: { mode in
                        if mode == .zoneBased, !viewModel.canUseZoneMode {
                            viewModel.showProPaywall = true
                            return false
                        }
                        return true
                    }
                )
                .frame(maxWidth: 210)
            }

            if viewModel.setup.intensityMode == .simple {
                HStack(spacing: 8) {
                    ForEach(Array(SimpleIntensity.allCases.enumerated()), id: \.element) { index, intensity in
                        FZSelectableTile(isSelected: viewModel.setup.simpleIntensity == intensity) {
                            viewModel.setup.simpleIntensity = intensity
                        } content: { selected in
                            VStack(alignment: .leading, spacing: 6) {
                                EffortBars(level: index + 1, onInk: selected)
                                Spacer(minLength: 0)
                                Text(LocalizedEnum.label(for: intensity))
                                    .font(Theme.Typography.bodyEmphasis)
                                if let carbs = viewModel.previewCarbs(for: intensity) {
                                    Text("≈ \(carbs) g/h")
                                        .font(Theme.Typography.caption)
                                        .monospacedDigit()
                                        .opacity(selected ? 0.8 : 1)
                                        .foregroundStyle(selected ? Theme.Colors.onInk : Theme.Colors.ink2)
                                }
                            }
                        }
                    }
                }
            } else {
                ZoneEditorView(
                    distribution: $viewModel.setup.zoneDistribution,
                    sessionMinutes: viewModel.resolvedSessionMinutes,
                    thresholds: viewModel.zoneThresholds
                )
            }
        }
        .fzCard()
    }
}

// MARK: - Conditions

private struct ConditionsSheet: View {
    @ObservedObject var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var place = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    Text(localized: "session.environment.hint")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.ink2)

                    VStack(alignment: .leading, spacing: 10) {
                        Text(localized: "plan.conditions.weather").fzLabelStyle()
                        Button {
                            Task { await viewModel.applyWeatherFromCurrentLocation() }
                        } label: {
                            Label { Text(localized: "session.weather.useGPS") } icon: { Image(systemName: "location.fill") }
                        }
                        .buttonStyle(.fzSecondary)
                        HStack(alignment: .bottom, spacing: 8) {
                            FZTextField(label: L10n.string("session.weather.locationPlaceholder"), text: $place, placeholder: "Berlin")
                                .submitLabel(.search)
                                .onSubmit { Task { await viewModel.applyWeather(fromLocationName: place) } }
                            Button {
                                Task { await viewModel.applyWeather(fromLocationName: place) }
                            } label: {
                                Image(systemName: "magnifyingglass")
                            }
                            .buttonStyle(FZIconButtonStyle(filled: true))
                            .accessibilityLabel(Text(localized: "session.weather.applyLocation"))
                        }
                        if viewModel.isFetchingWeather {
                            ProgressView().frame(maxWidth: .infinity)
                        } else if let message = viewModel.weatherStatusMessage {
                            Text(message).font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)
                        }
                    }
                    .disabled(viewModel.isFetchingWeather)
                    .fzCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text(localized: "session.temperature.title").fzLabelStyle()
                        FZSegmentedControl(
                            options: TemperatureLevel.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                            selection: Binding(
                                get: { viewModel.setup.temperature },
                                set: { viewModel.setManualConditions(temperature: $0) }
                            )
                        )
                        Text(localized: "session.conditions.title").fzLabelStyle().padding(.top, 6)
                        FZSegmentedControl(
                            options: WeatherCondition.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                            selection: Binding(
                                get: { viewModel.setup.conditions },
                                set: { viewModel.setManualConditions(conditions: $0) }
                            )
                        )
                    }
                    .fzCard()
                }
                .padding(Theme.Spacing.screen)
            }
            .fzScreenBackground()
            .navigationTitle(Text(localized: "session.environment.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text(localized: "common.done") }
                }
            }
            .onAppear { place = viewModel.setup.weatherLocationName ?? "" }
        }
    }
}
