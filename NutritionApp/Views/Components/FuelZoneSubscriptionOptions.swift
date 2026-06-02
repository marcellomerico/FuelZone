import StoreKit
import SwiftUI

/// Monthly / yearly Pro subscription picker (Settings + Paywall).
struct FuelZoneSubscriptionOptions: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var showsLegalDisclaimer: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let yearly = subscriptionManager.yearlyProduct {
                planButton(
                    titleKey: "storekit.plan.yearly",
                    price: yearly.displayPrice,
                    subtitle: yearlySubtitle,
                    isRecommended: true
                ) {
                    Task { await subscriptionManager.purchaseYearly() }
                }
            }

            if let monthly = subscriptionManager.monthlyProduct {
                planButton(
                    titleKey: "storekit.plan.monthly",
                    price: monthly.displayPrice,
                    subtitle: String(localized: "storekit.plan.monthly.period"),
                    isRecommended: subscriptionManager.yearlyProduct == nil
                ) {
                    Task { await subscriptionManager.purchaseMonthly() }
                }
            }

            productsPlaceholder

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text(localized: "storekit.restore")
                    .font(DesignSystem.Typography.micro)
                    .foregroundStyle(DesignSystem.accentLight.opacity(0.85))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .disabled(subscriptionManager.isLoading)

            if showsLegalDisclaimer {
                Text(localized: "storekit.subscription.legal")
                    .font(DesignSystem.Typography.micro)
                    .foregroundStyle(DesignSystem.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .disabled(subscriptionManager.isLoading && subscriptionManager.hasSubscriptionProducts)
        .task {
            if !subscriptionManager.hasSubscriptionProducts {
                await subscriptionManager.loadProducts()
            }
        }
    }

    @ViewBuilder
    private var productsPlaceholder: some View {
        if subscriptionManager.hasSubscriptionProducts {
            EmptyView()
        } else if subscriptionManager.productsLoadState == .loading {
            ProgressView()
                .tint(DesignSystem.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else if subscriptionManager.productsLoadState == .unavailable {
            VStack(alignment: .leading, spacing: 10) {
                FuelZoneInfoBanner(
                    message: String(localized: "storekit.error.products.unavailable"),
                    style: .warning
                )

                #if DEBUG
                Text(localized: "storekit.error.products.hint.debug")
                    .font(DesignSystem.Typography.micro)
                    .foregroundStyle(DesignSystem.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                #endif

                Button {
                    Task { await subscriptionManager.loadProducts() }
                } label: {
                    Text(localized: "storekit.retry")
                        .font(DesignSystem.Typography.caption.weight(.semibold))
                        .foregroundStyle(DesignSystem.accentOnAmber)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(DesignSystem.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var yearlySubtitle: String {
        if let percent = subscriptionManager.yearlySavingsPercent, percent > 0 {
            return L10n.format("storekit.plan.yearly.savings", "\(percent)")
        }
        return String(localized: "storekit.plan.yearly.period")
    }

    private func planButton(
        titleKey: String,
        price: String,
        subtitle: String,
        isRecommended: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(localized: titleKey)
                            .font(DesignSystem.Typography.cardTitle)
                            .foregroundStyle(DesignSystem.textPrimary)
                        if isRecommended {
                            Text(localized: "storekit.plan.recommended")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(DesignSystem.accentOnAmber)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(subtitle)
                        .font(DesignSystem.Typography.micro)
                        .foregroundStyle(DesignSystem.textSecondary)
                }

                Spacer(minLength: 0)

                Text(price)
                    .font(DesignSystem.Typography.metricValue)
                    .foregroundStyle(isRecommended ? DesignSystem.accentLight : DesignSystem.textPrimary)
            }
            .padding(12)
            .background(DesignSystem.embeddedTrack)
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(
                        isRecommended ? DesignSystem.accent.opacity(0.55) : DesignSystem.divider,
                        lineWidth: isRecommended ? 1.5 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(subscriptionManager.isLoading)
    }
}
