import Foundation
import Observation
import StoreKit

/// One-time "Remove Ads" purchase, StoreKit 2 only (no extra SDK, no receipt server).
///
/// - The ad-free state is cached in UserDefaults so ads never flash on launch for buyers, then
///   re-verified from `Transaction.currentEntitlements` (works offline, signed by the App Store).
/// - `Transaction.updates` is observed for purchases made elsewhere (other devices, Family
///   Sharing, Ask to Buy approvals) and for refunds, which revoke the entitlement.
@MainActor
@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    /// Must match the product ID created in App Store Connect.
    static let removeAdsProductID = "com.nagasiddharthadonepudi.HabitTracker.removeads"
    private static let cacheKey = "purchases.isAdFree"

    private(set) var isAdFree: Bool
    private(set) var removeAdsProduct: Product?
    private(set) var isWorking = false
    /// User-facing message after a failed or pending purchase/restore.
    var message: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    private init() {
        isAdFree = UserDefaults.standard.bool(forKey: Self.cacheKey)
    }

    /// Call once at launch.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
        Task {
            await refreshEntitlements()
            await loadProduct()
        }
    }

    func loadProduct() async {
        removeAdsProduct = try? await Product.products(for: [Self.removeAdsProductID]).first
    }

    func purchaseRemoveAds() async {
        if removeAdsProduct == nil { await loadProduct() }
        guard let product = removeAdsProduct else {
            message = "The App Store isn't reachable right now. Please try again later."
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                await handle(verification)
                if isAdFree { Analytics.track(.removeAdsPurchased) }
            case .pending:
                message = "Your purchase is waiting for approval. Ads will disappear once it's approved."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = error.localizedDescription
        }
    }

    /// Restore Purchases (App Store Review requires it for non-consumables).
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await AppStore.sync()
        } catch {
            message = error.localizedDescription
            return
        }
        await refreshEntitlements()
        if isAdFree {
            Analytics.track(.removeAdsRestored)
        } else {
            message = "No previous Remove Ads purchase was found for this Apple Account."
        }
    }

    func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.removeAdsProductID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setAdFree(owned)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        // Unverified transactions are ignored: they didn't come from the App Store.
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.removeAdsProductID {
            await refreshEntitlements()
        }
        await transaction.finish()
    }

    private func setAdFree(_ value: Bool) {
        guard value != isAdFree else { return }
        isAdFree = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
