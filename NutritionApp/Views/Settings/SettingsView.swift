import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        FuelZoneScreenScroll {
            profileSection
            languageSection
            appearanceSection
            proSection
            #if DEBUG
            debugProSection
            #endif
            legalSection
            syncSection
            aboutSection
            onboardingSection
        }
        .navigationTitle(Text(localized: "settings.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await appState.subscriptionManager.loadProducts()
        }
    }

    private var profileSection: some View {
        NavigationLink {
            ProfileView()
        } label: {
            FuelZoneProfileCard(
                titleKey: "profile.title",
                subtitleKey: "settings.profile.subtitle",
                initials: profileInitials
            )
        }
        .buttonStyle(.plain)
    }

    private var profileInitials: String {
        let name = appState.profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parts = name.split(separator: " ").prefix(2)
        if parts.isEmpty { return "FZ" }
        return parts.map { String($0.prefix(1)).uppercased() }.joined()
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSettingsLabel(titleKey: "settings.language")
            FuelZoneSegmentedPicker(
                options: [
                    (.system, "settings.language.system"),
                    (.english, "settings.language.english"),
                    (.german, "settings.language.german")
                ],
                selection: $appState.settings.language
            )
            .onChange(of: appState.settings.language) { _, _ in appState.saveSettings() }
        }
        .fuelZoneCard()
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            FuelZoneSettingsLabel(titleKey: "settings.appearance")
            FuelZoneSegmentedPicker(
                options: [
                    (.system, "settings.appearance.system"),
                    (.light, "settings.appearance.light"),
                    (.dark, "settings.appearance.dark")
                ],
                selection: $appState.settings.appearance
            )
            .onChange(of: appState.settings.appearance) { _, _ in appState.saveSettings() }
        }
        .fuelZoneCard()
    }

    private var proSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FuelZoneProCard(
                subscriptionManager: appState.subscriptionManager,
                isProActive: appState.settings.isProSubscriber
            )

            if let message = appState.subscriptionManager.statusMessage,
               appState.subscriptionManager.productsLoadState != .unavailable {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.textSecondary)
            }
        }
    }

    #if DEBUG
    private var debugProSection: some View {
        HStack {
            Text(localized: "settings.pro.debugToggle")
                .font(DesignSystem.Typography.bodySecondary)
                .foregroundStyle(DesignSystem.textPrimary)
            Spacer()
            Toggle("", isOn: $appState.settings.isProSubscriber)
                .labelsHidden()
                .tint(DesignSystem.accent)
        }
        .fuelZoneCard()
        .onChange(of: appState.settings.isProSubscriber) { _, _ in
            appState.saveSettings()
        }
    }
    #endif

    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            legalLinkRow(titleKey: "settings.legal.privacy", url: AppLegalLinks.privacyPolicy)
            FuelZoneCardDivider()
            legalLinkRow(titleKey: "settings.legal.terms", url: AppLegalLinks.termsOfUse)
            FuelZoneCardDivider()
            if let mailURL = URL(string: "mailto:\(AppLegalLinks.supportEmail)") {
                legalLinkRow(titleKey: "settings.legal.support", url: mailURL)
            }
        }
        .fuelZoneCard(padding: 6)
    }

    private func legalLinkRow(titleKey: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 11) {
                Text(localized: titleKey)
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.textTertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
        }
    }

    private var syncSection: some View {
        NavigationLink {
            FuelZoneScreenScroll {
                FuelZoneSectionHeader(
                    titleKey: "settings.sync.title",
                    subtitleKey: "settings.sync.description"
                )
                Button {
                    appState.syncNow()
                } label: {
                    Text(localized: "settings.sync.now")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .navigationTitle(Text(localized: "settings.sync.title"))
            .navigationBarTitleDisplayMode(.inline)
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "icloud.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DesignSystem.sodiumAccent)
                Text(localized: "settings.sync.title")
                    .font(DesignSystem.Typography.cardTitle)
                    .foregroundStyle(DesignSystem.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignSystem.textTertiary)
            }
            .fuelZoneCard()
        }
        .buttonStyle(.plain)
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 0) {
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
        .fuelZoneCard(padding: 6)
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
        .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
    }
}
