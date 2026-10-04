import SwiftUI

/// Settings tab as a grouped list: profile, Pro, app preferences, knowledge, legal.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPaywall = false

    var body: some View {
        List {
            Section {
                FZScreenHeader(eyebrow: nil, title: L10n.string("settings.title"))
                    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 4, trailing: 4))
                    .listRowBackground(Color.clear)

                NavigationLink {
                    ProfileView()
                } label: {
                    HStack(spacing: 14) {
                        Text(initials)
                            .font(.title3.weight(.heavy).width(.expanded))
                            .foregroundStyle(Theme.Colors.onInk)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Theme.Colors.ink))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(localized: "profile.title")
                                .font(.headline.weight(.heavy).width(.expanded))
                                .foregroundStyle(Theme.Colors.ink)
                            Text(profileSummary)
                                .font(Theme.Typography.footnote)
                                .foregroundStyle(Theme.Colors.ink2)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Theme.Colors.surface)
            }

            Section {
                Button { showPaywall = true } label: { proRow }
                    .listRowBackground(Theme.Colors.ink)
            }

            Section {
                HStack {
                    Label { Text(localized: "settings.language") } icon: { Image(systemName: "globe") }
                    Spacer()
                    Picker(L10n.string("settings.language"), selection: appState.settingsBinding(\.language)) {
                        Text(localized: "settings.language.system").tag(AppLanguage.system)
                        Text(localized: "settings.language.english").tag(AppLanguage.english)
                        Text(localized: "settings.language.german").tag(AppLanguage.german)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .tint(Theme.Colors.ink2)
                }
                HStack(spacing: 12) {
                    Label { Text(localized: "settings.appearance") } icon: { Image(systemName: "circle.lefthalf.filled") }
                    Spacer()
                    FZSegmentedControl(
                        options: [
                            .init(value: AppAppearance.system, title: L10n.string("settings.appearance.auto")),
                            .init(value: AppAppearance.light, title: L10n.string("settings.appearance.light")),
                            .init(value: AppAppearance.dark, title: L10n.string("settings.appearance.dark")),
                        ],
                        selection: appState.settingsBinding(\.appearance)
                    )
                    .frame(maxWidth: 220)
                }
                Button {
                    Task { await appState.store.syncNow() }
                } label: {
                    HStack {
                        Label { Text(localized: "settings.sync.title") } icon: { Image(systemName: "icloud") }
                        Spacer()
                        syncStatus
                    }
                }
            } header: {
                Text(localized: "settings.section.app")
            }
            .listRowBackground(Theme.Colors.surface)

            #if DEBUG
            Section {
                Toggle(isOn: $appState.debugSimulatePro) {
                    Label { Text(localized: "settings.pro.debugToggle") } icon: { Image(systemName: "hammer") }
                }
                .tint(Theme.Colors.accentFill)
            } header: {
                Text("Debug")
            }
            .listRowBackground(Theme.Colors.surface)
            #endif

            Section {
                NavigationLink {
                    FuelingMethodologyView()
                } label: {
                    Label { Text(localized: "methodology.title") } icon: { Image(systemName: "book.closed") }
                }
                NavigationLink {
                    DisclaimerView()
                } label: {
                    Label { Text(localized: "settings.disclaimer.title") } icon: { Image(systemName: "doc.text") }
                }
            } header: {
                Text(localized: "settings.section.knowledge")
            }
            .listRowBackground(Theme.Colors.surface)

            Section {
                Link(destination: AppLegalLinks.privacyPolicy) { externalRow("settings.legal.privacy") }
                Link(destination: AppLegalLinks.termsOfUse) { externalRow("settings.legal.terms") }
                if let mail = URL(string: "mailto:\(AppLegalLinks.supportEmail)") {
                    Link(destination: mail) { externalRow("settings.legal.support") }
                }
                Button {
                    appState.startOnboarding()
                } label: {
                    Text(localized: "settings.onboarding").foregroundStyle(Theme.Colors.ink)
                }
            } header: {
                Text(localized: "settings.section.legal")
            } footer: {
                Text(L10n.format("settings.footer", appVersion))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
            .listRowBackground(Theme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .fzScreenBackground()
        .tint(Theme.Colors.ink)
        .foregroundStyle(Theme.Colors.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var proRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .foregroundStyle(Theme.Colors.onAccent)
                .frame(width: 44, height: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.Colors.accentFill))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text("FuelZone Pro")
                    .font(.headline.weight(.heavy).width(.expanded))
                Text(localized: appState.isPro ? "settings.pro.active" : "settings.pro.subtitle.short")
                    .font(Theme.Typography.footnote)
                    .opacity(0.8)
            }
            .foregroundStyle(Theme.Colors.onInk)
            Spacer(minLength: 0)
            if !appState.isPro {
                Text(localized: "settings.pro.upgrade")
                    .font(Theme.Typography.subheadlineEmphasis)
                    .foregroundStyle(Theme.Colors.onAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Theme.Colors.accentFill))
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var syncStatus: some View {
        switch appState.store.syncStatus {
        case .syncing:
            ProgressView()
        case .synced(let date):
            statusLabel(L10n.format("settings.sync.synced", date.formatted(.relative(presentation: .named))), color: Theme.Colors.success)
        case .unavailable:
            statusLabel(L10n.string("settings.sync.unavailable"), color: Theme.Colors.ink3)
        case .failed:
            statusLabel(L10n.string("settings.sync.failed"), color: Theme.Colors.danger)
        case .idle:
            statusLabel(L10n.string("settings.sync.now"), color: Theme.Colors.ink3)
        }
    }

    private func statusLabel(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)
        }
    }

    private func externalRow(_ key: String) -> some View {
        HStack {
            Text(localized: key).foregroundStyle(Theme.Colors.ink)
            Spacer()
            Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold)).foregroundStyle(Theme.Colors.ink3)
        }
    }

    private var initials: String {
        let name = appState.store.profile.displayName?.trimmingCharacters(in: .whitespaces) ?? ""
        let letters = name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init)
        return letters.isEmpty ? "FZ" : letters.joined().uppercased()
    }

    private var profileSummary: String {
        let profile = appState.store.profile
        var parts = [LocalizedEnum.label(for: profile.primarySport)]
        if let weight = profile.weightKg { parts.append("\(Int(weight.rounded())) kg") }
        if let maxHR = profile.maxHeartRate { parts.append(L10n.format("settings.profile.maxHR", "\(maxHR)")) }
        return parts.joined(separator: " · ")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

struct DisclaimerView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                FZIconTile(systemImage: "doc.text.fill", foreground: Theme.Colors.accentText, background: Theme.Nutrient.carbs.tint, size: 56)
                Text(localized: "settings.disclaimer.body")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fzCard(padding: 20)
            .padding(Theme.Spacing.screen)
        }
        .fzScreenBackground()
        .navigationTitle(Text(localized: "settings.disclaimer.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
