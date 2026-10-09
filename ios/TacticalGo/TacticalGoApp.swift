import SwiftUI
@main struct TacticalGoApp: App {
    @State private var ready = false
    @State private var failed = false
    private var legacyReview: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--review-controls")
        #else
        false
        #endif
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if !legacyReview { PlayableGameView() }
                else if ready { ContentView() }
                else if failed { Text("棋盤載入失敗。請重新開啟遊戲。").padding() }
                else { ProgressView("準備棋盤…") }
            }.task {
                guard legacyReview, !ready, !failed else { return }
                do { try await ModelLibrary.load(); ready = true }
                catch { failed = true; print("Model resource load failed:", error) }
            }
        }
    }
}
