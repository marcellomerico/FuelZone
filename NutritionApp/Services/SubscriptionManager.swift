import Combine
import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let monthlyProductID = "com.mmerico.FuelZone.pro.monthly"

    @Published private(set) var isProActive = false
    @Published private(set) var monthlyProduct: Product?
    @Published private(set) var isLoading = false
    @Published var statusMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { await listenForTransactions() }
        Task { await refreshEntitlements() }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [Self.monthlyProductID])
            monthlyProduct = products.first
        } catch {
            statusMessage = String(localized: "storekit.error.products")
        }
    }

    func purchaseMonthly() async {
        guard let product = monthlyProduct else {
            await loadProducts()
            guard let product = monthlyProduct else { return }
            await purchase(product)
            return
        }
        await purchase(product)
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
                  transaction.productID == Self.monthlyProductID,
                  transaction.revocationDate == nil else { continue }
            active = true
        }
        isProActive = active
    }

    private func purchase(_ product: Product) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    statusMessage = String(localized: "storekit.purchase.success")
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
