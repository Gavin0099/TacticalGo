import Foundation
import Observation
import StoreKit

/// Only verified StoreKit transactions grant permanent access. No paid flag in defaults.
@MainActor @Observable final class UnlockPurchase {
    enum PurchaseResult { case unlocked, cancelled, pending, failed }
    private(set) var product: Product?
    private(set) var isUnlocked = false
    private(set) var isChecking = true
    private(set) var isBusy = false
    private(set) var message: String?
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var entitlementRevision: UInt64 = 0
    let productID: String

    init(bundle: Bundle = .main) {
        #if DEBUG
        productID = bundle.object(forInfoDictionaryKey: "CrownTacticsUnlockProductID") as? String ?? "com.tacticalgo.crowntactics.unlock"
        #else
        productID = bundle.object(forInfoDictionaryKey: "CrownTacticsUnlockProductID") as? String ?? ""
        #endif
    }
    deinit { updates?.cancel() }

    func start() async {
        if updates == nil {
            updates = Task { [weak self] in
                for await result in Transaction.updates {
                    guard !Task.isCancelled, let self else { return }
                    guard case .verified(let transaction) = result,
                          transaction.productID == self.productID else { continue }
                    await self.refreshEntitlements()
                    await transaction.finish()
                }
            }
        }
        await refreshEntitlements()
        await loadProduct()
    }

    func refreshEntitlements() async {
        entitlementRevision &+= 1
        let revision = entitlementRevision
        var verified = false
        if !productID.isEmpty {
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result,
                      transaction.productID == productID,
                      transaction.productType == .nonConsumable,
                      transaction.revocationDate == nil else { continue }
                verified = true
            }
        }
        guard revision == entitlementRevision else { return }
        isUnlocked = verified
        isChecking = false
    }

    func loadProduct() async {
        guard !productID.isEmpty else { message = "購買商品尚未設定；不會產生費用。"; return }
        do {
            product = try await Product.products(for: [productID]).first { $0.type == .nonConsumable }
            message = product == nil ? "商品暫時無法取得，請稍後重試。" : nil
        } catch { product = nil; message = "無法連線至商店，請稍後重試。" }
    }

    func purchase() async -> PurchaseResult {
        guard !isBusy, let product else { return .failed }
        isBusy = true; message = nil
        defer { isBusy = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let transaction) = result,
                      transaction.productID == productID,
                      transaction.productType == .nonConsumable,
                      transaction.revocationDate == nil else {
                    message = "購買尚未通過驗證，未解鎖。請使用恢復購買重試。"
                    return .failed
                }
                await refreshEntitlements()
                await transaction.finish()
                if isUnlocked { message = "已解鎖；往後不需觀看廣告。"; return .unlocked }
                message = "交易已收到，權限仍待確認。請稍後恢復購買。"
                return .failed
            case .userCancelled: message = "已取消購買。"; return .cancelled
            case .pending: message = "購買等待批准，完成後會自動更新。"; return .pending
            @unknown default: message = "購買尚未完成，請稍後重試。"; return .failed
            }
        } catch { message = "購買未完成。請稍後重試，不會重複解鎖或扣除試玩額度。"; return .failed }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true; message = nil
        defer { isBusy = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            message = isUnlocked ? "已恢復購買。" : "此 Apple 帳戶尚無可恢復的解鎖購買。"
        } catch { message = "恢復購買未完成，請稍後重試。" }
    }
}
