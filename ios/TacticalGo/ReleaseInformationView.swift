import SwiftUI

struct ReleaseInformationView: View {
    let access: PlayAccess
    let presentationChanged: @MainActor (Bool) -> Void
    @ObservedObject var ads = RewardedAdService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var privacyWork: Task<Void, Never>?
    @State private var privacyMessage: String?
    var body: some View {
        NavigationStack {
            List {
                Section("遊戲與本機資料") {
                    Text("棋局、棋譜、教學與挑戰進度、聲音偏好保存在裝置上。免費對局額度及廣告續玩資格另行保存在本機，不會改變棋盤規則。")
                }
                Section("購買與廣告") {
                    Text("一次解鎖由 Apple 處理，App 使用經驗證的交易確認資格，不接收你的付款卡片資料。獎勵廣告由 Google 提供；僅在你選擇觀看後處理必要的同意與播放流程。")
                    Text("廣告服務可能處理裝置及廣告互動資料，實際用途依服務設定與公開隱私政策說明。不要求同意追蹤才能遊玩。")
                    if ads.isConfigured {
                        Button("管理廣告隱私選擇") {
                            privacyMessage = nil
                            privacyWork = Task {
                                let error = await ads.refreshPrivacyChoices()
                                guard !Task.isCancelled, scenePhase == .active else { return }
                                if let error { privacyMessage = error }
                                else if ads.privacyOptionsRequired {
                                    await ads.presentPrivacyOptions(onPresentationChanged: presentationChanged)
                                } else { privacyMessage = "廣告服務目前沒有需要調整的隱私選擇。" }
                            }
                        }.disabled(ads.isBusy || access.purchase.isBusy)
                    }
                    if let privacyMessage { Text(privacyMessage).font(.footnote) }
                }
                if let url = configuredURL("CrownTacticsPrivacyURL") {
                    Section { Link("完整隱私政策", destination: url) }
                }
                Section("支援") {
                    Link("聯絡支援：reiko0099@gmail.com", destination: URL(string: "mailto:reiko0099@gmail.com")!)
                    if let url = configuredURL("CrownTacticsSupportURL") { Link("支援網站", destination: url) }
                    Text("© 2026 WU JUI-YI").font(.caption).foregroundStyle(.secondary)
                }
                #if DEBUG
                Section { Text("本機候選；廣告帳戶、公開政策及正式商品仍待設定。").font(.caption) }
                #endif
            }.navigationTitle("隱私與支援")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { privacyWork?.cancel(); dismiss() }.disabled(ads.isPresentingSDKContent)
                } }
        }
        .interactiveDismissDisabled(ads.isPresentingSDKContent)
        .onDisappear { if !ads.isPresentingSDKContent { privacyWork?.cancel() } }
        .onChange(of: scenePhase) { _, phase in if phase == .background { privacyWork?.cancel() } }
    }
    private func configuredURL(_ key: String) -> URL? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil else { return nil }
        return url
    }
}
