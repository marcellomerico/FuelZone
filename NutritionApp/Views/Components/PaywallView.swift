import StoreKit
import SwiftUI

/// FuelZone Pro: dark hero with the course line, features, yearly/monthly choice, legal links.
struct PaywallView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: Plan = .yearly

    enum Plan { case yearly, monthly }

    private var manager: SubscriptionManager { appState.subscriptionManager }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                hero
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    if appState.isPro {
                        FZBanner(message: L10n.string("storekit.status.active"), style: .success)
                    }
                    features
                    if !appState.isPro {
                        planPicker
                    }
                }
                .padding(Theme.Spacing.screen)
            }
        }
        .ignoresSafeArea(edges: .top)
        .fzScreenBackground()
        .overlay(alignment: .topTrailing) {
            // Sticky close button, reachable at any scroll position.
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.body.weight(.bold)).foregroundStyle(.white)
                    .frame(width: Theme.minTouch, height: Theme.minTouch)
                    .background(Circle().fill(.black.opacity(0.45)))
            }
            .padding(.top, 14)
            .padding(.trailing, 16)
            .accessibilityLabel(Text(localized: "common.close"))
        }
        .safeAreaInset(edge: .bottom) {
            if !appState.isPro { purchaseBar }
        }
        .task { await manager.loadProducts() }
        .onChange(of: appState.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .presentationDragIndicator(.visible)
    }

    // MARK: Hero

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            Color(red: 0.078, green: 0.078, blue: 0.078)
            GeometryReader { proxy in
                Path { path in
                    let w = proxy.size.width
                    let h = proxy.size.height
                    // Course line across the top right, clear of the title.
                    path.move(to: CGPoint(x: w * 0.30, y: h * 0.44))
                    path.addCurve(to: CGPoint(x: w * 0.55, y: h * 0.30), control1: CGPoint(x: w * 0.38, y: h * 0.42), control2: CGPoint(x: w * 0.45, y: h * 0.30))
                    path.addCurve(to: CGPoint(x: w * 0.78, y: h * 0.24), control1: CGPoint(x: w * 0.64, y: h * 0.30), control2: CGPoint(x: w * 0.68, y: h * 0.36))
                    path.addCurve(to: CGPoint(x: w, y: h * 0.10), control1: CGPoint(x: w * 0.88, y: h * 0.12), control2: CGPoint(x: w * 0.94, y: h * 0.08))
                }
                .stroke(Color(red: 0.95, green: 0.60, blue: 0.12), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Colors.onAccent)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.Colors.accentFill))
                Text("FuelZone Pro")
                    .font(.system(size: 38, weight: .heavy).width(.expanded))
                    .foregroundStyle(.white)
                Text(localized: "pro.paywall.message")
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Theme.Spacing.screen)
            .padding(.top, 70)
            .padding(.bottom, 24)
        }
        .frame(minHeight: 300)
        .environment(\.colorScheme, .dark)
    }

    // MARK: Features

    private var features: some View {
        VStack(spacing: 0) {
            feature("heart.fill", "pro.paywall.feature.zones")
            Divider().overlay(Theme.Colors.line)
            feature("plus.circle.fill", "pro.paywall.feature.customSnacks")
            Divider().overlay(Theme.Colors.line)
            feature("barcode.viewfinder", "pro.paywall.feature.barcode")
            Divider().overlay(Theme.Colors.line)
            feature("arrow.left.arrow.right", "pro.paywall.feature.snackSwap")
            Divider().overlay(Theme.Colors.line)
            feature("clock.fill", "pro.paywall.feature.history")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.Colors.surface))
    }

    private func feature(_ icon: String, _ key: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.Colors.accentText)
                .frame(width: 26)
                .accessibilityHidden(true)
            Text(localized: key)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundStyle(Theme.Colors.ink)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 48)
    }

    // MARK: Plans

    @ViewBuilder
    private var planPicker: some View {
        if manager.hasSubscriptionProducts {
            HStack(spacing: 10) {
                if let yearly = manager.yearlyProduct {
                    planOption(
                        plan: .yearly,
                        title: L10n.string("storekit.plan.yearly"),
                        price: yearly.displayPrice,
                        detail: monthlyEquivalent(yearly),
                        badge: manager.yearlySavingsPercent.map { "−\($0) %" }
                    )
                }
                if let monthly = manager.monthlyProduct {
                    planOption(
                        plan: .monthly,
                        title: L10n.string("storekit.plan.monthly"),
                        price: monthly.displayPrice,
                        detail: L10n.string("pro.plan.monthly.detail"),
                        badge: nil
                    )
                }
            }
        } else if manager.productsLoadState == .loading || manager.productsLoadState == .idle {
            ProgressView().frame(maxWidth: .infinity, minHeight: 100)
        } else {
            VStack(spacing: 10) {
                FZBanner(message: L10n.string("storekit.error.products.unavailable"), style: .warning)
                Button {
                    Task { await manager.loadProducts() }
                } label: {
                    Text(localized: "storekit.retry")
                }
                .buttonStyle(.fzSecondary)
            }
        }
    }

    private func planOption(plan: Plan, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.Typography.footnote).foregroundStyle(Theme.Colors.ink2)
                MetricText(price, size: 30, relativeTo: .title2)
                Text(detail).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.ink2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isSelected ? Theme.Colors.ink : Theme.Colors.line, lineWidth: isSelected ? 2 : 1)
                    )
            )
            .overlay(alignment: .topLeading) {
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(Theme.Colors.onAccent)
                        .padding(.horizontal, 8)
                        .frame(height: 20)
                        .background(Capsule().fill(Theme.Colors.accentFill))
                        .offset(x: 12, y: -10)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func monthlyEquivalent(_ product: Product) -> String {
        let perMonth = product.price / 12
        let formatted = perMonth.formatted(product.priceFormatStyle)
        return L10n.format("pro.plan.yearly.detail", formatted)
    }

    // MARK: Purchase bar

    private var purchaseBar: some View {
        VStack(spacing: 6) {
            Button {
                Task {
                    switch selectedPlan {
                    case .yearly: await manager.purchaseYearly()
                    case .monthly: await manager.purchaseMonthly()
                    }
                }
            } label: {
                if manager.isLoading {
                    ProgressView().tint(Theme.Colors.onAccent)
                } else {
                    Text(localized: selectedPlan == .yearly ? "pro.cta.yearly" : "pro.cta.monthly")
                }
            }
            .buttonStyle(.fzPrimary)
            .disabled(!manager.hasSubscriptionProducts || manager.isLoading)

            if let message = manager.statusMessage, manager.productsLoadState == .loaded {
                Text(message).font(Theme.Typography.caption).foregroundStyle(Theme.Colors.ink2)
            }

            HStack(spacing: 4) {
                Button { Task { await manager.restorePurchases() } } label: {
                    Text(localized: "storekit.restore.short")
                }
                Text("·").foregroundStyle(Theme.Colors.ink3)
                Link(destination: AppLegalLinks.privacyPolicy) { Text(localized: "settings.legal.privacy") }
                Text("·").foregroundStyle(Theme.Colors.ink3)
                Link(destination: AppLegalLinks.termsOfUse) { Text(localized: "settings.legal.terms") }
            }
            .font(Theme.Typography.footnote)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .foregroundStyle(Theme.Colors.ink2)
            .tint(Theme.Colors.ink2)
            .frame(minHeight: 36)

            Text(localized: "storekit.subscription.legal")
                .font(.caption2)
                .foregroundStyle(Theme.Colors.ink2)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.screen)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}
