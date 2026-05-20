import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                appearanceSection
                proSection
                aboutSection
                Button {
                    appState.profile.hasCompletedOnboarding = false
                    appState.showOnboarding = true
                } label: {
                    Text(localized: "settings.onboarding")
                }
            }
            .navigationTitle(Text(localized: "settings.title"))
        }
    }

    private var languageSection: some View {
        Section(String(localized: "settings.language")) {
            Picker("", selection: $appState.settings.language) {
                Text(localized: "settings.language.system").tag(AppLanguage.system)
                Text(localized: "settings.language.english").tag(AppLanguage.english)
                Text(localized: "settings.language.german").tag(AppLanguage.german)
            }
            .onChange(of: appState.settings.language) { _, _ in appState.saveSettings() }
        }
    }

    private var appearanceSection: some View {
        Section(String(localized: "settings.appearance")) {
            Picker("", selection: $appState.settings.appearance) {
                Text(localized: "settings.appearance.system").tag(AppAppearance.system)
                Text(localized: "settings.appearance.light").tag(AppAppearance.light)
                Text(localized: "settings.appearance.dark").tag(AppAppearance.dark)
            }
            .onChange(of: appState.settings.appearance) { _, _ in appState.saveSettings() }
        }
    }

    private var proSection: some View {
        Section {
            Toggle(isOn: $appState.settings.isProSubscriber) {
                VStack(alignment: .leading) {
                    Text(localized: "settings.pro.title")
                    Text(localized: "settings.pro.subtitle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onChange(of: appState.settings.isProSubscriber) { _, _ in
                appState.saveSettings()
                appState.sessionViewModel.updateSettings(appState.settings)
                appState.snackViewModel.configure(settings: appState.settings)
            }
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "settings.about")) {
            NavigationLink {
                ScrollView {
                    Text(localized: "settings.disclaimer.body")
                        .padding()
                }
                .navigationTitle(Text(localized: "settings.disclaimer.title"))
            } label: {
                Text(localized: "settings.disclaimer.title")
            }
        }
    }
}
