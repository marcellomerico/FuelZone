import Combine
import Foundation
import StoreKit

enum SubscriptionProductsLoadState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable
}

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyProductID = "com.mmerico.FuelZone.pro.monthly"
    static let yearlyProductID = "com.mmerico.FuelZone.pro.yearly"

    static let proProductIDs: Set<String> = [monthlyProductID, yearlyProductID]

    @Published private(set) var isProActive = false
    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var yearlyProduct: Product?
    @Published private(set) var isLoading = false
    @Published private(set) var productsLoadState: SubscriptionProductsLoadState = .idle
    @Published var statusMessage: String?

    var hasSubscriptionProducts: Bool {
        monthlyProduct != nil || yearlyProduct != nil
    }

    /// Approximate savings vs. 12× monthly price (for UI badge).
    var yearlySavingsPercent: Int? {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return nil }
        let monthlyAnnual = monthly.price * 12
        guard monthlyAnnual > 0 else { return nil }
        let ratio = yearly.price / monthlyAnnual
        let savings = (Decimal(1) - ratio) * 100
        return Int((savings as NSDecimalNumber).doubleValue.rounded())
    }

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refreshEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        guard productsLoadState != .loading else { return }
        isLoading = true
        productsLoadState = .loading
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: Array(Self.proProductIDs))
            monthlyProduct = products.first { $0.id == Self.monthlyProductID }
            yearlyProduct = products.first { $0.id == Self.yearlyProductID }

            if hasSubscriptionProducts {
                productsLoadState = .loaded
            } else {
                productsLoadState = .unavailable
                statusMessage = String(localized: "storekit.error.products.unavailable")
            }
        } catch {
            productsLoadState = .unavailable
            statusMessage = String(localized: "storekit.error.products")
        }
    }

    func purchaseMonthly() async {
        await purchase(productID: Self.monthlyProductID)
    }

    func purchaseYearly() async {
        await purchase(productID: Self.yearlyProductID)
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusMessage = isProActive
                ? String(localized: "storekit.restore.success")
                : String(localized: "storekit.restore.empty")
        } catch {
            statusMessage = String(localized: "storekit.error.restore")
        }
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  Self.proProductIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else { continue }
            active = true
        }
        isProActive = active
    }

    private func purchase(productID: String) async {
        if product(for: productID) == nil {
            await loadProducts()
        }
        guard let product = product(for: productID) else { return }
        await purchase(product)
    }

    private func product(for productID: String) -> Product? {
        switch productID {
        case Self.monthlyProductID: monthlyProduct
        case Self.yearlyProductID: yearlyProduct
        default: nil
        }
    }

    private func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    statusMessage = String(localized: "storekit.purchase.success")
                case .unverified:
                    statusMessage = String(localized: "storekit.error.unverified")
                }
            case .userCancelled:
                break
            case .pending:
                statusMessage = String(localized: "storekit.purchase.pending")
            @unknown default:
                break
            }
        } catch {
            statusMessage = String(localized: "storekit.error.purchase")
        }
    }

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }
}
