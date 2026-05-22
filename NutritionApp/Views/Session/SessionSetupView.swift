import SwiftUI

struct SessionSetupView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel
    @Binding var showResults: Bool
    var body: some View {
        FuelZoneScreenScroll {
            sportSection
            durationSection
            intensitySection
            environmentSection

            if let error = viewModel.errorMessage {
                FuelZoneInfoBanner(message: error, style: .warning)
            }

            PrimaryCTAButton(
                titleKey: "session.calculate",
                isLoading: viewModel.isCalculating
            ) {
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
        }
        .navigationTitle(Text(localized: "session.title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $viewModel.showProPaywall) {
            ProPaywallSheet {
                appState.selectedTab = 2
            }
        }
    }

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(titleKey: "session.sport", systemImage: "sportscourt")
            SportSelectionGrid(selection: $viewModel.setup.sport)
        }
        .fuelZoneCard()
        .onAppear { viewModel.updateProfile(appState.profile) }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "session.duration.section",
                subtitleKey: "session.duration.sectionHint",
                systemImage: "clock"
            )

            Picker("", selection: $viewModel.setup.durationInputMode) {
                ForEach(DurationInputMode.allCases) { mode in
                    Text(LocalizedEnum.label(for: mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.setup.durationInputMode {
            case .duration:
                FuelZoneLabeledField(labelKey: "session.duration.minutes", text: intBinding(\.durationMinutes), keyboardType: .numberPad)
            case .distanceAndPace:
                FuelZoneLabeledField(labelKey: "session.distance.km", text: doubleBinding(\.distanceKm))
                FuelZoneLabeledField(labelKey: "session.pace.minPerKm", text: doubleBinding(\.paceMinutesPerKm))
                if let minutes = viewModel.setup.resolvedDurationMinutes() {
                    Text(L10n.format("session.duration.computed", "\(minutes)"))
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
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
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "session.intensity.title",
                subtitleKey: "session.intensity.hint",
                systemImage: "heart.fill"
            )
            IntensityModePicker(viewModel: viewModel)

            if viewModel.setup.intensityMode == .simple {
                Picker("", selection: $viewModel.setup.simpleIntensity) {
                    ForEach(SimpleIntensity.allCases) { level in
                        Text(LocalizedEnum.label(for: level)).tag(level)
                    }
                }
                .pickerStyle(.segmented)
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
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "session.environment.title",
                subtitleKey: "session.environment.hint",
                systemImage: "cloud.sun"
            )

            Text(localized: "session.temperature.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            Picker("", selection: $viewModel.setup.temperature) {
                ForEach(TemperatureLevel.allCases) { t in
                    Text(LocalizedEnum.label(for: t)).tag(t)
                }
            }
            .pickerStyle(.segmented)

            Text(localized: "session.conditions.title")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
            Picker("", selection: $viewModel.setup.conditions) {
                ForEach(WeatherCondition.allCases) { c in
                    Text(LocalizedEnum.label(for: c)).tag(c)
                }
            }
            .pickerStyle(.segmented)
        }
        .fuelZoneCard()
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
