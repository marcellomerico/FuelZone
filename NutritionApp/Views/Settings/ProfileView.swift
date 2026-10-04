import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @State private var displayName = ""
    @State private var weightText = ""
    @State private var maxHRText = ""
    @State private var zoneThresholds: HeartRateZoneThresholds?
    @State private var profileError: String?
    @State private var showProPaywall = false

    private var canEditHeartRateZones: Bool {
        appState.isPro
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: DesignSystem.sectionSpacing) {
                aboutSection
                sportSection
                physiologySection
                heartRateSection
                if let profileError {
                    FuelZoneInfoBanner(message: profileError, style: .warning)
                }
                Button {
                    saveProfile()
                } label: {
                    Text(localized: "profile.save")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
            .fuelZoneScreenContent()
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .background(DesignSystem.appBackground)
        .navigationTitle(Text(localized: "profile.title"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadFromProfile() }
        .sheet(isPresented: $showProPaywall) {
            ProPaywallSheet()
                .environmentObject(appState)
        }
    }

    private func loadFromProfile() {
        let p = appState.store.profile
        displayName = p.displayName ?? ""
        weightText = p.weightKg.map { String(format: "%.1f", $0) } ?? ""
        maxHRText = p.maxHeartRate.map { "\($0)" } ?? ""
        zoneThresholds =
            p.zoneThresholds
            ?? p.maxHeartRate.map { HeartRateZoneThresholds.standard(maxHeartRate: $0) }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "profile.about.title",
                subtitleKey: "profile.about.subtitle",
                systemImage: "person.fill"
            )
            FuelZoneLabeledField(
                labelKey: "onboarding.profile.name", text: $displayName, keyboardType: .default)
            FuelZoneLabeledField(labelKey: "onboarding.profile.weight", text: $weightText)
        }
        .fuelZoneCard()
    }

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "profile.sport.title",
                subtitleKey: "profile.sport.subtitle",
                systemImage: "sportscourt"
            )
            SportSelectionGrid(selection: appState.profileBinding(\.primarySport))
                .frame(maxWidth: .infinity)
        }
        .fuelZoneCard()
    }

    private var physiologySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "profile.physiology.title",
                subtitleKey: "profile.physiology.subtitle",
                systemImage: "figure.run"
            )
            profilePickerRow(
                titleKey: "onboarding.stomach.title",
                selection: appState.profileBinding(\.stomachSensitivity),
                cases: StomachSensitivity.allCases,
                label: { LocalizedEnum.label(for: $0) }
            )
            profilePickerRow(
                titleKey: "onboarding.sweat.title",
                selection: appState.profileBinding(\.sweatRate),
                cases: SweatRate.allCases,
                label: { LocalizedEnum.label(for: $0) }
            )
            profilePickerRow(
                titleKey: "onboarding.saltiness.title",
                selection: appState.profileBinding(\.sweatSaltiness),
                cases: SweatSaltiness.allCases,
                label: { LocalizedEnum.label(for: $0) }
            )
        }
        .fuelZoneCard()
    }

    @ViewBuilder
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "profile.hr.title",
                subtitleKey: "profile.hr.subtitle",
                systemImage: "heart.fill"
            )

            if !canEditHeartRateZones {
                FuelZoneInfoBanner(
                    message: String(localized: "profile.hr.proRequired"), style: .info)
                Button {
                    showProPaywall = true
                } label: {
                    Text(localized: "profile.hr.unlockPro")
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            if canEditHeartRateZones {
                FuelZoneLabeledField(
                    labelKey: "session.zone.maxHR", text: $maxHRText, keyboardType: .numberPad)

                Button {
                    applyStandardZonesFromMaxHR()
                } label: {
                    Label {
                        Text(localized: "profile.hr.resetStandard")
                    } icon: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .font(DesignSystem.Typography.cardTitle)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DesignSystem.accentSoft)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: DesignSystem.buttonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)

                if let thresholds = zoneThresholds {
                    zoneLimitsEditor(thresholds)
                } else {
                    FuelZoneInfoBanner(
                        message: String(localized: "profile.hr.missingMax"), style: .info)
                }
            } else if let thresholds = zoneThresholds ?? appState.store.profile.zoneThresholds {
                zoneLimitsReadOnly(thresholds)
            }
        }
        .fuelZoneCard()
    }

    @ViewBuilder
    private func zoneLimitsReadOnly(_ thresholds: HeartRateZoneThresholds) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: "profile.hr.zoneLimits")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            ForEach(HeartRateZone.allCases) { zone in
                Text(
                    "\(LocalizedEnum.label(for: zone)): \(zoneBpmRangeLabel(zone: zone, thresholds: thresholds))"
                )
                .font(DesignSystem.Typography.bodySecondary)
            }
        }
    }

    private func zoneBpmRangeLabel(zone: HeartRateZone, thresholds: HeartRateZoneThresholds)
        -> String
    {
        let lower = thresholds.lowerBound(for: zone)
        let upper: Int =
            switch zone {
            case .zone1: thresholds.zone1Upper
            case .zone2: thresholds.zone2Upper
            case .zone3: thresholds.zone3Upper
            case .zone4: thresholds.zone4Upper
            case .zone5: thresholds.maxHeartRate
            }
        return "\(lower)–\(upper) bpm"
    }

    @ViewBuilder
    private func zoneLimitsEditor(_ thresholds: HeartRateZoneThresholds) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized: "profile.hr.zoneLimits")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

            zoneUpperRow(
                zone: .zone1, titleKey: "hrzone.zone1", keyPath: \.zone1Upper,
                thresholds: thresholds)
            zoneUpperRow(
                zone: .zone2, titleKey: "hrzone.zone2", keyPath: \.zone2Upper,
                thresholds: thresholds)
            zoneUpperRow(
                zone: .zone3, titleKey: "hrzone.zone3", keyPath: \.zone3Upper,
                thresholds: thresholds)
            zoneUpperRow(
                zone: .zone4, titleKey: "hrzone.zone4", keyPath: \.zone4Upper,
                thresholds: thresholds)

            Text(
                L10n.format(
                    "profile.hr.zone5Range",
                    "\(thresholds.lowerBound(for: .zone5))",
                    "\(thresholds.maxHeartRate)"
                )
            )
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(DesignSystem.textSecondary)

            if !thresholds.isValid() {
                Text(localized: "profile.hr.validation")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func zoneUpperRow(
        zone: HeartRateZone,
        titleKey: String,
        keyPath: WritableKeyPath<HeartRateZoneThresholds, Int>,
        thresholds: HeartRateZoneThresholds
    ) -> some View {
        let binding = Binding(
            get: { zoneThresholds?[keyPath: keyPath] ?? thresholds[keyPath: keyPath] },
            set: { newValue in
                guard var t = zoneThresholds else { return }
                t[keyPath: keyPath] = newValue
                zoneThresholds = t
            }
        )
        let t = zoneThresholds ?? thresholds
        let lower = t.lowerBound(for: zone)
        let upperMax = zoneUpperMaximum(for: zone, thresholds: t)

        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(localized: titleKey)
                        .font(DesignSystem.Typography.cardTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(
                        L10n.format("session.zone.bpmRange", "\(lower)", "\(binding.wrappedValue)")
                    )
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                }
                .layoutPriority(1)
                Spacer(minLength: 4)
                Stepper("", value: binding, in: lower...max(lower, upperMax))
                    .labelsHidden()
                    .fixedSize()
                Text("\(binding.wrappedValue)")
                    .monospacedDigit()
                    .font(DesignSystem.Typography.bodySecondary.weight(.semibold))
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(DesignSystem.embeddedTrack)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func profilePickerRow<T: Hashable & Identifiable>(
        titleKey: String,
        selection: Binding<T>,
        cases: [T],
        label: @escaping (T) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: titleKey)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            VStack(spacing: 8) {
                ForEach(cases) { item in
                    FuelZoneSelectionRow(
                        title: label(item),
                        isSelected: selection.wrappedValue == item
                    ) {
                        selection.wrappedValue = item
                    }
                }
            }
        }
    }

    private func zoneUpperMaximum(for zone: HeartRateZone, thresholds: HeartRateZoneThresholds)
        -> Int
    {
        switch zone {
        case .zone1: thresholds.zone2Upper - 1
        case .zone2: thresholds.zone3Upper - 1
        case .zone3: thresholds.zone4Upper - 1
        case .zone4: thresholds.maxHeartRate - 1
        case .zone5: thresholds.maxHeartRate
        }
    }

    private func applyStandardZonesFromMaxHR() {
        guard canEditHeartRateZones else {
            showProPaywall = true
            return
        }
        profileError = nil
        guard let maxHR = Int(maxHRText.trimmingCharacters(in: .whitespaces)),
            HeartRateZoneCalculator.validMaxHRRange.contains(maxHR)
        else {
            profileError = String(localized: "error.invalidMaxHeartRate")
            return
        }
        maxHRText = "\(maxHR)"
        zoneThresholds = HeartRateZoneThresholds.standard(maxHeartRate: maxHR)
    }

    private func saveProfile() {
        profileError = nil
        var profile = appState.store.profile
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.displayName = trimmedName.isEmpty ? nil : trimmedName
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespaces)
        if trimmedWeight.isEmpty {
            profile.weightKg = nil
        } else if let weight = InputParsing.weightKg(trimmedWeight) {
            profile.weightKg = weight
        } else {
            profileError = L10n.string("error.invalidWeight")
            return
        }

        if canEditHeartRateZones {
            let trimmedHR = maxHRText.trimmingCharacters(in: .whitespaces)
            if trimmedHR.isEmpty {
                profile.maxHeartRate = nil
                profile.zoneThresholds = nil
            } else if let maxHR = Int(trimmedHR),
                HeartRateZoneCalculator.validMaxHRRange.contains(maxHR)
            {
                profile.maxHeartRate = maxHR
                if var thresholds = zoneThresholds {
                    thresholds.maxHeartRate = maxHR
                    if thresholds.isValid() {
                        profile.zoneThresholds = thresholds
                    } else {
                        profile.refreshZoneThresholdsFromMaxHR()
                        zoneThresholds = profile.zoneThresholds
                        profileError = String(localized: "profile.hr.validation")
                        return
                    }
                } else {
                    profile.refreshZoneThresholdsFromMaxHR()
                    zoneThresholds = profile.zoneThresholds
                }
            } else {
                profileError = String(localized: "error.invalidMaxHeartRate")
                return
            }
        }

        let updated = profile
        appState.store.updateProfile { $0 = updated }
        loadFromProfile()
    }
}
