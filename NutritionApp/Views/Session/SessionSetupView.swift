import SwiftUI

struct SessionSetupView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel
    @Binding var showResults: Bool

    private var preview: (carbsPerHour: Int, gelCount: Int, sodiumPerHour: Int) {
        viewModel.planPreviewMetrics(profile: appState.profile)
    }

    var body: some View {
        FuelZoneScreenScroll {
            sportSection
            durationSection
            intensitySection
            environmentSection

            if let error = viewModel.errorMessage {
                FuelZoneInfoBanner(message: error, style: .warning)
            }

            fuelPreviewCard
        }
        .navigationTitle(Text(localized: "session.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet {
                appState.selectedTab = 3
            }
            .environmentObject(appState)
        }
        .onAppear { viewModel.updateProfile(appState.profile) }
    }

    private var fuelPreviewCard: some View {
        FuelZonePlanPreviewCard(
            carbsPerHour: preview.carbsPerHour,
            gelCount: preview.gelCount,
            sodiumPerHour: preview.sodiumPerHour,
            isLoading: viewModel.isCalculating
        ) {
            startPlan()
        }
    }

    private func startPlan() {
        viewModel.calculatePlan()
        if viewModel.lastResult != nil {
            appState.profile = viewModel.exportedProfile()
            appState.saveProfile()
            appState.historyViewModel.saveSession(
                setup: viewModel.setup,
                result: viewModel.lastResult!,
                profile: appState.profile
            )
            showResults = true
        }
    }

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(titleKey: "session.sport")
            SportSelectionGrid(selection: $viewModel.setup.sport)
        }
        .fuelZoneCard()
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                FuelZoneSectionHeader(titleKey: "session.duration.section")
                Spacer()
                Text(localized: LocalizedEnum.key(for: viewModel.setup.durationInputMode))
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textTertiary)
            }

            FuelZoneSegmentedPicker(
                options: DurationInputMode.allCases.map { ($0, LocalizedEnum.key(for: $0)) },
                selection: $viewModel.setup.durationInputMode
            )

            switch viewModel.setup.durationInputMode {
            case .duration:
                FuelZoneDurationSlider(
                    minutes: Binding(
                        get: { viewModel.setup.durationMinutes ?? 90 },
                        set: { viewModel.setup.durationMinutes = $0 }
                    )
                )
            case .distanceAndPace:
                FuelZoneLabeledField(labelKey: "session.distance.km", text: doubleBinding(\.distanceKm))
                FuelZoneLabeledField(labelKey: "session.pace.minPerKm", text: doubleBinding(\.paceMinutesPerKm))
                if let minutes = viewModel.setup.resolvedDurationMinutes() {
                    Text(L10n.format("session.duration.computed", "\(minutes)"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                }
            case .distanceAndTime:
                FuelZoneLabeledField(labelKey: "session.distance.km", text: doubleBinding(\.distanceKm))
                FuelZoneLabeledField(labelKey: "session.duration.minutes", text: intBinding(\.durationMinutes), keyboardType: .numberPad)
            }
        }
        .fuelZoneCard()
        .onChange(of: viewModel.setup.durationInputMode) { _, _ in
            viewModel.syncZoneDistributionToSessionDuration()
        }
        .onChange(of: viewModel.setup.durationMinutes) { _, _ in
            viewModel.syncZoneDistributionToSessionDuration()
        }
        .onChange(of: viewModel.setup.distanceKm) { _, _ in
            viewModel.syncZoneDistributionToSessionDuration()
        }
        .onChange(of: viewModel.setup.paceMinutesPerKm) { _, _ in
            viewModel.syncZoneDistributionToSessionDuration()
        }
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "session.intensity.title",
                subtitleKey: "session.intensity.hint"
            )
            IntensityModePicker(viewModel: viewModel)

            if viewModel.setup.intensityMode == .simple {
                FuelZoneSegmentedPicker(
                    options: SimpleIntensity.allCases.map { ($0, LocalizedEnum.key(for: $0)) },
                    selection: $viewModel.setup.simpleIntensity
                )
            } else {
                ZoneEditorView(
                    distribution: $viewModel.setup.zoneDistribution,
                    sessionDurationMinutes: viewModel.resolvedSessionMinutes,
                    thresholds: viewModel.zoneThresholds
                )

                NavigationLink {
                    ProfileView()
                } label: {
                    FuelZoneNavigationRow(
                        titleKey: "profile.title",
                        subtitleKey: "session.zone.editInProfile",
                        systemImage: "person.crop.circle"
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .fuelZoneCard()
    }

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "session.environment.title",
                subtitleKey: "session.environment.hint"
            )

            weatherLocationSection

            Text(localized: "session.temperature.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            FuelZoneSegmentedPicker(
                options: TemperatureLevel.allCases.map { ($0, LocalizedEnum.key(for: $0)) },
                selection: $viewModel.setup.temperature
            )

            Text(localized: "session.conditions.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)
            FuelZoneSegmentedPicker(
                options: WeatherCondition.allCases.map { ($0, LocalizedEnum.key(for: $0)) },
                selection: $viewModel.setup.conditions
            )
        }
        .fuelZoneCard()
    }

    private var weatherLocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localized: "session.weather.locationTitle")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.textSecondary)

            FuelZoneLabeledField(
                labelKey: "session.weather.locationPlaceholder",
                text: Binding(
                    get: { viewModel.setup.weatherLocationName ?? "" },
                    set: { viewModel.setup.weatherLocationName = $0.isEmpty ? nil : $0 }
                ),
                keyboardType: .default
            )

            HStack(spacing: 10) {
                Button {
                    Task {
                        let name = viewModel.setup.weatherLocationName ?? ""
                        await viewModel.applyWeather(fromLocationName: name)
                    }
                } label: {
                    Text(localized: "session.weather.applyLocation")
                        .font(DesignSystem.Typography.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.accentOnAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(DesignSystem.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isFetchingWeather)

                Button {
                    Task { await viewModel.applyWeatherFromCurrentLocation() }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DesignSystem.accent)
                        .frame(width: 44, height: 44)
                        .background(DesignSystem.embeddedTrack)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isFetchingWeather)
                .accessibilityLabel(Text(localized: "session.weather.useGPS"))
            }

            if viewModel.isFetchingWeather {
                ProgressView()
                    .tint(DesignSystem.accent)
                    .frame(maxWidth: .infinity)
            }

            if let message = viewModel.weatherStatusMessage {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
        }
    }

    private func intBinding(_ keyPath: WritableKeyPath<SessionSetup, Int?>) -> Binding<String> {
        Binding(
            get: { viewModel.setup[keyPath: keyPath].map(String.init) ?? "" },
            set: { viewModel.setup[keyPath: keyPath] = Int($0) }
        )
    }

    private func doubleBinding(_ keyPath: WritableKeyPath<SessionSetup, Double?>) -> Binding<String> {
        Binding(
            get: {
                viewModel.setup[keyPath: keyPath].map { String($0) } ?? ""
            },
            set: {
                viewModel.setup[keyPath: keyPath] = Double($0.replacingOccurrences(of: ",", with: "."))
            }
        )
    }
}
