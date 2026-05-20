import SwiftUI

struct SessionSetupView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SessionViewModel
    @Binding var showResults: Bool
    @State private var maxHRText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.sectionSpacing) {
                sportSection
                durationSection
                intensitySection
                environmentSection

                if let error = viewModel.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }

                PrimaryCTAButton(
                    titleKey: "session.calculate",
                    isLoading: viewModel.isCalculating
                ) {
                    viewModel.calculatePlan()
                    if viewModel.lastResult != nil {
                        appState.historyViewModel.saveSession(
                            setup: viewModel.setup,
                            result: viewModel.lastResult!,
                            profile: appState.profile
                        )
                        showResults = true
                    }
                }
            }
            .padding()
        }
        .background(DesignSystem.groupedBackground)
        .navigationTitle(Text(localized: "session.title"))
        .onAppear {
            if let hr = appState.profile.maxHeartRate {
                maxHRText = "\(hr)"
            }
        }
    }

    private var sportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized: "session.sport").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SportType.allCases) { sport in
                        Button { viewModel.setup.sport = sport } label: {
                            Label(LocalizedEnum.label(for: sport), systemImage: sport.systemImageName)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(viewModel.setup.sport == sport
                                    ? Color.accentColor.opacity(0.2) : DesignSystem.cardBackground)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $viewModel.setup.durationInputMode) {
                ForEach(DurationInputMode.allCases) { mode in
                    Text(LocalizedEnum.label(for: mode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.setup.durationInputMode {
            case .duration, .distanceAndTime:
                labeledField("session.duration.minutes", text: Binding(
                    get: { viewModel.setup.durationMinutes.map(String.init) ?? "" },
                    set: { viewModel.setup.durationMinutes = Int($0) }
                ))
            case .distanceAndPace:
                labeledField("session.distance.km", text: Binding(
                    get: { viewModel.setup.distanceKm.map { String($0) } ?? "" },
                    set: { viewModel.setup.distanceKm = Double($0.replacingOccurrences(of: ",", with: ".")) }
                ))
                labeledField("session.pace.minPerKm", text: Binding(
                    get: { viewModel.setup.paceMinutesPerKm.map { String($0) } ?? "" },
                    set: { viewModel.setup.paceMinutesPerKm = Double($0.replacingOccurrences(of: ",", with: ".")) }
                ))
            }
        }
        .fuelZoneCard()
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized: "session.intensity.title").font(.headline)

            Picker("", selection: $viewModel.setup.intensityMode) {
                Text(localized: "session.intensity.simple").tag(IntensityMode.simple)
                HStack {
                    Text(localized: "session.intensity.zoneBased")
                    if !viewModel.canUseZoneMode {
                        Text(localized: "session.intensity.proBadge")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .tag(IntensityMode.zoneBased)
            }
            .pickerStyle(.segmented)
            .onChange(of: viewModel.setup.intensityMode) { _, mode in
                if mode == .zoneBased, !viewModel.canUseZoneMode {
                    viewModel.setup.intensityMode = .simple
                }
            }

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
                    maxHeartRateText: $maxHRText,
                    onMaxHRChange: { viewModel.updateMaxHeartRateFromText($0) }
                )
            }
        }
        .fuelZoneCard()
    }

    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localized: "session.temperature.title").font(.subheadline.weight(.semibold))
            Picker("", selection: $viewModel.setup.temperature) {
                ForEach(TemperatureLevel.allCases) { t in
                    Text(LocalizedEnum.label(for: t)).tag(t)
                }
            }
            .pickerStyle(.segmented)

            Text(localized: "session.conditions.title").font(.subheadline.weight(.semibold))
            Picker("", selection: $viewModel.setup.conditions) {
                ForEach(WeatherCondition.allCases) { c in
                    Text(LocalizedEnum.label(for: c)).tag(c)
                }
            }
            .pickerStyle(.segmented)
        }
        .fuelZoneCard()
    }

    private func labeledField(_ key: String, text: Binding<String>) -> some View {
        TextField(String(localized: key), text: text)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
    }
}
