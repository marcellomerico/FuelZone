import SwiftUI

struct ProPaywallSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                FuelZoneHeroBlock(
                    systemImage: "star.circle.fill",
                    titleKey: "pro.paywall.title",
                    subtitleKey: "pro.paywall.message"
                )

                VStack(alignment: .leading, spacing: 12) {
                    FuelZoneSectionHeader(titleKey: "pro.paywall.featuresTitle")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.zones", systemImage: "heart.fill")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.customSnacks", systemImage: "plus.circle.fill")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.barcode", systemImage: "barcode.viewfinder")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.snackSwap", systemImage: "arrow.triangle.swap")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.history", systemImage: "clock.fill")
                }
                .fuelZoneCard()

                if appState.isPro {
                    FuelZoneInfoBanner(message: String(localized: "storekit.status.active"), style: .success)
                } else {
                    FuelZoneSubscriptionOptions(
                        subscriptionManager: appState.subscriptionManager,
                        showsLegalDisclaimer: true
                    )
                    .fuelZoneCard()
                }

                if let status = appState.subscriptionManager.statusMessage {
                    Text(status)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.textSecondary)
                }

                FuelZoneTextButton(titleKey: "pro.paywall.dismiss") {
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignSystem.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(DesignSystem.textTertiary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await appState.subscriptionManager.loadProducts()
        }
        .onChange(of: appState.isPro) { _, isPro in
            if isPro {
                dismiss()
            }
        }
    }
}
