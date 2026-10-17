import SwiftUI

/// Shown at a new-game boundary, never during a board action or an unfinished game.
struct UnlockView: View {
    @Bindable var access: PlayAccess
    @ObservedObject var ads = RewardedAdService.shared
    let continueGame: @MainActor () -> Void
    var continueTitle = "開始下一局"
    /// Opened from the lobby's 「購買與恢復」 entry: the purchase is offered even while free matches remain.
    var storeEntry = false
    let presentationChanged: @MainActor (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var generation = UUID()
    @State private var work: Task<Void, Never>?
    @State private var adMessage: String?
    @State private var readyToContinue = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "crown.fill").font(.system(size: 46)).foregroundStyle(Cozy.confirm).accessibilityHidden(true)
                    Text(title).font(.title2.bold()).accessibilityIdentifier("unlockTitle")
                    Text("前 3 場完整對局免費。新手教學、玩法練習與戰術挑戰不消耗額度；既有存局可繼續。")
                        .font(.subheadline).multilineTextAlignment(.center)
                    if offersPurchase {
                        Button { buy() } label: {
                            VStack(spacing: 4) {
                                Text("一次購買，永久去廣告").font(.headline)
                                Text(access.purchase.product?.displayPrice ?? "商品暫不可用").font(.subheadline)
                            }.frame(maxWidth: .infinity, minHeight: 52)
                        }.buttonStyle(.borderedProminent)
                            .disabled(access.purchase.product == nil || access.purchase.isBusy || ads.isBusy)
                            .accessibilityIdentifier("unlockPurchase")
                    }
                    if access.canStartMatch {
                        if storeEntry {
                            Button(continueTitle) { readyToContinue = false; continueGame(); dismiss() }
                                .buttonStyle(.bordered).accessibilityIdentifier("accessContinue")
                        } else {
                            Button(continueTitle) { readyToContinue = false; continueGame(); dismiss() }
                                .buttonStyle(.borderedProminent).accessibilityIdentifier("accessContinue")
                        }
                    } else {
                        Button { watchAd() } label: {
                            Label("看廣告，再玩一局", systemImage: "play.rectangle")
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }.buttonStyle(.bordered).disabled(ads.isBusy || access.purchase.isBusy || access.errorMessage != nil)
                            .accessibilityIdentifier("watchRewardedAd")
                        Text("廣告只在開局前播放，對戰途中不打斷。提前關閉不會取得下一局。")
                            .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    if access.purchase.isBusy || ads.isBusy { ProgressView("處理中…").accessibilityIdentifier("accessBusy") }
                    if let message = access.errorMessage ?? adMessage ?? access.purchase.message {
                        Text(message).font(.subheadline).multilineTextAlignment(.center).accessibilityIdentifier("accessMessage")
                    }
                    HStack {
                        Button("恢復購買") { work = Task { await access.purchase.restore() } }.accessibilityIdentifier("restorePurchases")
                        Spacer()
                        // Only a failed product load needs a retry; a loaded store showed this as if it were an error.
                        if !access.purchase.isUnlocked && access.purchase.product == nil {
                            Button("重試商店") { work = Task { await access.purchase.loadProduct() } }
                        }
                    }.disabled(access.purchase.isBusy || ads.isBusy)
                    if ads.privacyOptionsRequired {
                        Button("廣告隱私選擇") { work = Task { await ads.presentPrivacyOptions(onPresentationChanged: presentationChanged) } }
                    }
                    #if DEBUG
                    Text("本機測試商品／測試廣告；不是正式收費版。")
                        .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("monetizationTestNotice")
                    #endif
                }.padding(24).frame(maxWidth: 500).frame(maxWidth: .infinity)
            }.navigationTitle(storeEntry ? "購買與恢復" : "繼續遊玩").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) {
                    Button("稍後再說") { cancelWork(); dismiss() }.disabled(ads.isPresentingSDKContent).accessibilityIdentifier("unlockDismiss")
                } }
        }.interactiveDismissDisabled(ads.isPresentingSDKContent || access.purchase.isBusy)
            .task { await access.purchase.loadProduct() }
            .onDisappear { if !ads.isPresentingSDKContent { cancelWork() } }
            .onChange(of: scenePhase) { _, phase in
                // UIKit's advertising screen may make SwiftUI inactive; only real background cancels.
                if phase == .background { cancelWork() }
                if phase == .active { continueWhenActive() }
            }
    }

    private var title: String {
        if access.purchase.isUnlocked { return storeEntry ? "已永久解鎖" : "繼續你的戰局" }
        return storeEntry ? "購買與恢復" : "選擇繼續遊玩的方式"
    }
    private var offersPurchase: Bool { !access.purchase.isUnlocked && (storeEntry || !access.canStartMatch) }

    private func buy() {
        let current = generation
        work = Task {
            let result = await access.purchase.purchase()
            guard !Task.isCancelled, generation == current else { return }
            if case .unlocked = result { readyToContinue = true; continueWhenActive() }
        }
    }
    private func watchAd() {
        let current = generation
        adMessage = nil
        work = Task {
            let result = await ads.watchForOneMatch(onEarnedReward: { id in
                try access.earnedReward(requestID: id)
            }, onPresentationChanged: presentationChanged)
            guard !Task.isCancelled, generation == current else { return }
            switch result {
            case .earned: readyToContinue = true; continueWhenActive()
            case .dismissedWithoutReward: adMessage = "廣告未觀看完成，沒有消耗額度。"
            case .cancelled: adMessage = "已中止廣告，尚未開始新局。"
            case .unavailable(let message): adMessage = message
            }
        }
    }
    // StoreKit / UIKit may finish while the scene is briefly inactive. Wait for its
    // return, but clear this intent on a real background or cancelled sheet.
    private func continueWhenActive() {
        guard readyToContinue, scenePhase == .active else { return }
        readyToContinue = false
        continueGame(); dismiss()
    }
    private func cancelWork() { generation = UUID(); readyToContinue = false; work?.cancel(); work = nil; ads.cancelPendingRequest() }
}
