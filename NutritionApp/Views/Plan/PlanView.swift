import SwiftUI

/// Plan tab: describe the session, watch the live numbers in the dock, create the plan.
struct PlanView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel
    var onPlanCreated: (UUID) -> Void

    @State private var showConditions = false
    @State private var isKeyboardVisible = false

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
        .safeAreaInset(edge: .bottom) {
            // The dock steps aside while typing so it never covers the focused field.
            if !isKeyboardVisible { dock }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                } label: {
                    Text(localized: "common.done").bold()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
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
                FZTextField(label: L10n.string("session.distance.km"), text: decimalBinding(\.distanceKm), placeholder: isCycling ? "60" : "21,1", unit: "km", keyboard: .decimalPad)
                if isCycling {
                    FZTextField(label: L10n.string("plan.speed"), text: speedBinding, placeholder: "28", unit: "km/h", keyboard: .decimalPad)
                } else {
                    PacePicker(paceMinutesPerKm: $viewModel.setup.paceMinutesPerKm)
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

    private var isCycling: Bool { viewModel.setup.sport == .cycling }

    /// Cyclists think in km/h; stored as minutes per km like a running pace.
    private var speedBinding: Binding<String> {
        Binding(
            get: {
                guard let pace = viewModel.setup.paceMinutesPerKm, pace > 0 else { return "" }
                return (60 / pace).formatted(.number.precision(.fractionLength(0...1)))
            },
            set: { text in
                if let speed = InputParsing.decimal(text), speed > 0 {
                    viewModel.setup.paceMinutesPerKm = 60 / speed
                } else {
                    viewModel.setup.paceMinutesPerKm = nil
                }
            }
        )
    }

    private func modeTitle(_ mode: DurationInputMode) -> String {
        switch mode {
        case .duration: L10n.string("plan.duration.mode.time")
        case .distanceAndPace: L10n.string(isCycling ? "plan.duration.mode.speed" : "plan.duration.mode.pace")
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

/// Running pace as minutes and seconds per km (e.g. 5:20 /km), not as a decimal.
private struct PacePicker: View {
    @Binding var paceMinutesPerKm: Double?
    private static let defaultSeconds = 330
    static let minuteRange = 2...20

    /// Clamped to the wheel range so a pace carried over from a fast bike speed stays selectable.
    private var totalSeconds: Int {
        guard let pace = paceMinutesPerKm, pace > 0 else { return Self.defaultSeconds }
        let seconds = Int((pace * 60 / 5).rounded()) * 5
        return min(max(seconds, Self.minuteRange.lowerBound * 60), Self.minuteRange.upperBound * 60 + 55)
    }

    private var minutes: Binding<Int> {
        Binding(
            get: { totalSeconds / 60 },
            set: { paceMinutesPerKm = Double($0 * 60 + totalSeconds % 60) / 60 }
        )
    }

    private var seconds: Binding<Int> {
        Binding(
            get: { totalSeconds % 60 },
            set: { paceMinutesPerKm = Double((totalSeconds / 60) * 60 + $0) / 60 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localized: "plan.pace.title")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.ink2)
            HStack(spacing: 0) {
                Picker(L10n.string("plan.pace.minutes"), selection: minutes) {
                    ForEach(Self.minuteRange, id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Text(":").font(.title2.weight(.heavy))
                Picker(L10n.string("plan.pace.seconds"), selection: seconds) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                Text(localized: "plan.pace.unit")
                    .font(Theme.Typography.subheadlineEmphasis)
                    .foregroundStyle(Theme.Colors.ink2)
                    .padding(.trailing, 8)
            }
            .frame(height: 120)
            .clipped()
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.Colors.surface2))
        }
        .onAppear {
            // Start from a sensible running pace; normalise values outside the wheel range.
            let normalized = Double(totalSeconds) / 60
            if paceMinutesPerKm != normalized { paceMinutesPerKm = normalized }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(localized: "plan.pace.title"))
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
