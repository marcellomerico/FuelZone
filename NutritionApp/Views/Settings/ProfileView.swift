import SwiftUI

/// Profile: every change is saved immediately (text fields once their value is valid).
struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var displayName = ""
    @State private var weightText = ""
    @State private var maxHRText = ""
    @State private var showPaywall = false

    private var profile: UserProfile { appState.store.profile }
    private var weightInvalid: Bool {
        !weightText.trimmingCharacters(in: .whitespaces).isEmpty && InputParsing.weightKg(weightText) == nil
    }
    private var maxHRInvalid: Bool {
        !maxHRText.trimmingCharacters(in: .whitespaces).isEmpty && InputParsing.maxHeartRate(maxHRText) == nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                aboutSection
                sportSection
                bodySection
                heartRateSection
            }
            .padding(Theme.Spacing.screen)
        }
        .scrollDismissesKeyboard(.interactively)
        .fzScreenBackground()
        .navigationTitle(Text(localized: "profile.title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: load)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func load() {
        displayName = profile.displayName ?? ""
        weightText = profile.weightKg.map { $0.formatted(.number.precision(.fractionLength(0...1))) } ?? ""
        maxHRText = profile.maxHeartRate.map(String.init) ?? ""
    }

    // MARK: Sections

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized: "profile.about.title").fzLabelStyle()
            FZTextField(label: L10n.string("onboarding.profile.name"), text: $displayName, placeholder: L10n.string("profile.name.placeholder"))
                .textContentType(.givenName)
                .onChange(of: displayName) { _, value in
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    let newName = trimmed.isEmpty ? nil : trimmed
                    guard newName != profile.displayName else { return }
                    appState.store.updateProfile { $0.displayName = newName }
                }
            FZTextField(
                label: L10n.string("onboarding.profile.weight"), text: $weightText, placeholder: "70",
                unit: "kg", keyboard: .decimalPad, isInvalid: weightInvalid
            )
            .onChange(of: weightText) { _, value in
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    if profile.weightKg != nil { appState.store.updateProfile { $0.weightKg = nil } }
                } else if let weight = InputParsing.weightKg(trimmed), weight != profile.weightKg {
                    appState.store.updateProfile { $0.weightKg = weight }
                }
            }
            if weightInvalid {
                Text(localized: "error.invalidWeight").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.danger)
            }
        }
        .fzCard()
    }

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized: "profile.sport.title").fzLabelStyle()
            FlowLayout(spacing: 8) {
                ForEach(SportType.allCases) { sport in
                    FZChip(
                        title: LocalizedEnum.label(for: sport),
                        systemImage: sport.systemImageName,
                        isSelected: profile.primarySport == sport
                    ) {
                        appState.store.updateProfile { $0.primarySport = sport }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fzCard()
    }

    private var bodySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localized: "profile.physiology.title").fzLabelStyle()
            pickerRow(titleKey: "onboarding.stomach.title", hintKey: "onboarding.stomach.tooltip") {
                FZSegmentedControl(
                    options: StomachSensitivity.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: appState.profileBinding(\.stomachSensitivity)
                )
            }
            pickerRow(titleKey: "onboarding.sweat.title", hintKey: "onboarding.sweat.tooltip") {
                FZSegmentedControl(
                    options: SweatRate.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: appState.profileBinding(\.sweatRate)
                )
            }
            pickerRow(titleKey: "onboarding.saltiness.title", hintKey: "onboarding.saltiness.tooltip") {
                FZSegmentedControl(
                    options: SweatSaltiness.allCases.map { .init(value: $0, title: LocalizedEnum.label(for: $0)) },
                    selection: appState.profileBinding(\.sweatSaltiness)
                )
            }
        }
        .fzCard()
    }

    private func pickerRow<Control: View>(titleKey: String, hintKey: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(localized: titleKey).font(Theme.Typography.subheadlineEmphasis).foregroundStyle(Theme.Colors.ink)
            control()
            Text(localized: hintKey).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Heart rate

    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localized: "profile.hr.title").fzLabelStyle()
                Spacer()
                if !appState.isPro {
                    Text("PRO").font(.caption2.weight(.heavy)).foregroundStyle(Theme.Colors.accentText)
                }
            }
            Text(localized: "profile.hr.subtitle").font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)

            FZTextField(
                label: L10n.string("session.zone.maxHR"), text: $maxHRText, placeholder: "188",
                unit: "bpm", keyboard: .numberPad, isInvalid: maxHRInvalid
            )
            .onChange(of: maxHRText) { _, value in
                let trimmed = value.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    if profile.maxHeartRate != nil {
                        appState.store.updateProfile { $0.maxHeartRate = nil; $0.zoneThresholds = nil }
                    }
                } else if let maxHR = InputParsing.maxHeartRate(trimmed), maxHR != profile.maxHeartRate {
                    appState.store.updateProfile { profile in
                        profile.maxHeartRate = maxHR
                        if let thresholds = profile.zoneThresholds, appState.isPro {
                            var updated = thresholds
                            updated.maxHeartRate = maxHR
                            profile.zoneThresholds = updated.isValid() ? updated : .standard(maxHeartRate: maxHR)
                        } else {
                            profile.zoneThresholds = .standard(maxHeartRate: maxHR)
                        }
                    }
                }
            }
            if maxHRInvalid {
                Text(localized: "error.invalidMaxHeartRate").font(Theme.Typography.caption).foregroundStyle(Theme.Colors.danger)
            }

            if let thresholds = profile.zoneThresholds {
                if appState.isPro {
                    ForEach(HeartRateZone.allCases) { zone in zoneRow(zone, thresholds: thresholds) }
                    Button {
                        if let maxHR = profile.maxHeartRate {
                            appState.store.updateProfile { $0.zoneThresholds = .standard(maxHeartRate: maxHR) }
                        }
                    } label: {
                        Label { Text(localized: "profile.hr.resetStandard") } icon: { Image(systemName: "arrow.counterclockwise") }
                    }
                    .buttonStyle(.fzSecondary)
                } else {
                    ForEach(HeartRateZone.allCases) { zone in
                        HStack(spacing: 10) {
                            ZoneBadge(zone: zone)
                            Text(LocalizedEnum.label(for: zone)).font(Theme.Typography.subheadlineEmphasis)
                            Spacer()
                            Text(HeartRateZoneCalculator.bpmLabel(for: zone, thresholds: thresholds))
                                .font(Theme.Typography.footnote).monospacedDigit().foregroundStyle(Theme.Colors.ink2)
                        }
                    }
                    Button { showPaywall = true } label: { Text(localized: "profile.hr.unlockPro") }
                        .buttonStyle(.fzSecondary)
                }
            }
        }
        .fzCard()
    }

    private func zoneRow(_ zone: HeartRateZone, thresholds: HeartRateZoneThresholds) -> some View {
        let lower = thresholds.lowerBound(for: zone)
        return HStack(spacing: 10) {
            ZoneBadge(zone: zone)
            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedEnum.label(for: zone)).font(Theme.Typography.subheadlineEmphasis)
                Text(HeartRateZoneCalculator.bpmLabel(for: zone, thresholds: thresholds))
                    .font(Theme.Typography.caption).monospacedDigit().foregroundStyle(Theme.Colors.ink2)
            }
            Spacer()
            if let keyPath = upperKeyPath(zone) {
                Stepper(value: Binding(
                    get: { thresholds[keyPath: keyPath] },
                    set: { newValue in
                        var updated = thresholds
                        updated[keyPath: keyPath] = newValue
                        if updated.isValid() {
                            appState.store.updateProfile { $0.zoneThresholds = updated }
                        }
                    }
                ), in: (lower + 1)...max(lower + 1, upperLimit(zone, thresholds: thresholds))) {
                    Text(LocalizedEnum.label(for: zone))
                }
                .labelsHidden()
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous).fill(Theme.Colors.surface2))
    }

    private func upperKeyPath(_ zone: HeartRateZone) -> WritableKeyPath<HeartRateZoneThresholds, Int>? {
        switch zone {
        case .zone1: \.zone1Upper
        case .zone2: \.zone2Upper
        case .zone3: \.zone3Upper
        case .zone4: \.zone4Upper
        case .zone5: nil
        }
    }

    private func upperLimit(_ zone: HeartRateZone, thresholds: HeartRateZoneThresholds) -> Int {
        switch zone {
        case .zone1: thresholds.zone2Upper - 1
        case .zone2: thresholds.zone3Upper - 1
        case .zone3: thresholds.zone4Upper - 1
        case .zone4: thresholds.maxHeartRate - 1
        case .zone5: thresholds.maxHeartRate
        }
    }
}
