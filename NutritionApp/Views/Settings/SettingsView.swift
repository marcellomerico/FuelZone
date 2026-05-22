import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                profileSection
                languageSection
                appearanceSection
                proSection
                syncSection
                aboutSection
                onboardingSection
            }
            .navigationTitle(Text(localized: "settings.title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await appState.subscriptionManager.loadProducts()
            }
        }
    }

    private var profileSection: some View {
        NavigationLink {
            ProfileView()
        } label: {
            FuelZoneNavigationRow(
                titleKey: "profile.title",
                subtitleKey: "settings.profile.subtitle",
                systemImage: "person.crop.circle.fill"
            )
            .fuelZoneCard()
        }
        .buttonStyle(.plain)
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(titleKey: "settings.language", systemImage: "globe")
            Picker("", selection: $appState.settings.language) {
                Text(localized: "settings.language.system").tag(AppLanguage.system)
                Text(localized: "settings.language.english").tag(AppLanguage.english)
                Text(localized: "settings.language.german").tag(AppLanguage.german)
            }
            .pickerStyle(.segmented)
            .onChange(of: appState.settings.language) { _, _ in appState.saveSettings() }
        }
        .fuelZoneCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(titleKey: "settings.appearance", systemImage: "circle.lefthalf.filled")
            Picker("", selection: $appState.settings.appearance) {
                Text(localized: "settings.appearance.system").tag(AppAppearance.system)
                Text(localized: "settings.appearance.light").tag(AppAppearance.light)
                Text(localized: "settings.appearance.dark").tag(AppAppearance.dark)
            }
            .pickerStyle(.segmented)
            .onChange(of: appState.settings.appearance) { _, _ in appState.saveSettings() }
        }
        .fuelZoneCard()
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            FuelZoneSectionHeader(
                titleKey: "settings.pro.title",
                subtitleKey: "settings.pro.subtitle",
                systemImage: "star.fill"
            )

            if appState.settings.isProSubscriber {
                FuelZoneInfoBanner(message: String(localized: "storekit.status.active"), style: .success)
            } else if let product = appState.subscriptionManager.monthlyProduct {
                Text(product.displayPrice)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(Color.accentColor)
                Button {
                    Task { await appState.subscriptionManager.purchaseMonthly() }
                } label: {
                    Text(localized: "storekit.subscribe")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(appState.subscriptionManager.isLoading)
            }

            FuelZoneTextButton(titleKey: "storekit.restore") {
                Task { await appState.subscriptionManager.restorePurchases() }
            }

            if let message = appState.subscriptionManager.statusMessage {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            #if DEBUG
            Toggle(isOn: $appState.settings.isProSubscriber) {
                Text(localized: "settings.pro.debugToggle")
                    .font(DesignSystem.Typography.bodySecondary)
            }
            .onChange(of: appState.settings.isProSubscriber) { _, _ in
                appState.saveSettings()
            }
            #endif
        }
        .fuelZoneCard()
    }

    private var syncSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSectionHeader(
                titleKey: "settings.sync.title",
                subtitleKey: "settings.sync.description",
                systemImage: "icloud"
            )
            Button {
                appState.syncNow()
            } label: {
                Text(localized: "settings.sync.now")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .fuelZoneCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            FuelZoneSectionHeader(titleKey: "settings.about", systemImage: "info.circle")

            NavigationLink {
                FuelingMethodologyView()
            } label: {
                FuelZoneNavigationRow(
                    titleKey: "methodology.title",
                    subtitleKey: "settings.methodology.subtitle",
                    systemImage: "book.closed.fill"
                )
            }
            .buttonStyle(.plain)

            FuelZoneCardDivider()

            NavigationLink {
                FuelZoneDisclaimerView()
            } label: {
                FuelZoneNavigationRow(
                    titleKey: "settings.disclaimer.title",
                    subtitleKey: "settings.disclaimer.subtitle",
                    systemImage: "doc.text"
                )
            }
            .buttonStyle(.plain)
        }
        .fuelZoneCard()
    }

    private var onboardingSection: some View {
        Button {
            appState.profile.hasCompletedOnboarding = false
            appState.showOnboarding = true
        } label: {
            Text(localized: "settings.onboarding")
        }
        .buttonStyle(PrimaryButtonStyle())
    }
}

struct FuelZoneDisclaimerView: View {
    var body: some View {
        FuelZoneScreenScroll {
            FuelZoneHeroBlock(
                systemImage: "doc.text.fill",
                subtitleKey: "settings.disclaimer.body"
            )
        }
        .navigationTitle(Text(localized: "settings.disclaimer.title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
