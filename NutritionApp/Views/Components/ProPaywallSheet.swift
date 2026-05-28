import SwiftUI
import StoreKit

struct ProPaywallSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    var onOpenSettings: (() -> Void)?

    var body: some View {
        NavigationStack {
            FuelZoneScreenScroll {
                FuelZoneHeroBlock(
                    systemImage: "star.circle.fill",
                    titleKey: "pro.paywall.title",
                    subtitleKey: "pro.paywall.message"
                )

                VStack(alignment: .leading, spacing: 12) {
                    FuelZoneSectionHeader(
                        titleKey: "pro.paywall.featuresTitle",
                        systemImage: "checkmark.seal"
                    )
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.zones", systemImage: "heart.fill")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.barcode", systemImage: "barcode.viewfinder")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.snackSwap", systemImage: "arrow.triangle.swap")
                    FuelZoneBulletRow(textKey: "pro.paywall.feature.history", systemImage: "clock.fill")
                }
                .fuelZoneCard()

                if appState.settings.isProSubscriber {
                    FuelZoneInfoBanner(message: String(localized: "storekit.status.active"), style: .success)
                } else {
                    if let product = appState.subscriptionManager.monthlyProduct {
                        Text(product.displayPrice)
                            .font(DesignSystem.Typography.metricValue)
                            .foregroundStyle(Color.accentColor)
                    }
                    Button {
                        Task { await appState.subscriptionManager.purchaseMonthly() }
                    } label: {
                        Text(localized: "storekit.subscribe")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(appState.subscriptionManager.isLoading)

                    FuelZoneTextButton(titleKey: "storekit.restore") {
                        Task { await appState.subscriptionManager.restorePurchases() }
                    }
                    .disabled(appState.subscriptionManager.isLoading)
                }

                if let status = appState.subscriptionManager.statusMessage {
                    Text(status)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)
                }

                FuelZoneTextButton(titleKey: "pro.paywall.cta") {
                    dismiss()
                    onOpenSettings?()
                }

                FuelZoneTextButton(titleKey: "pro.paywall.dismiss") {
                    dismiss()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await appState.subscriptionManager.loadProducts()
        }
        .onChange(of: appState.settings.isProSubscriber) { _, isPro in
            if isPro {
                dismiss()
            }
        }
    }
}
