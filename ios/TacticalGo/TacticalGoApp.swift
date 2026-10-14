import SwiftUI
import TacticalGoContent
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
    @ViewBuilder private var normalRoot: some View {
        if !legacyReview { PlayableGameView() }
        else if ready { ContentView() }
        else if failed { Text("棋盤載入失敗。請重新開啟遊戲。").padding() }
        else { ProgressView("準備棋盤…") }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("--advanced-challenges") { ChallengesView(campaign: .advanced) {} }
                else if ProcessInfo.processInfo.arguments.contains("--intro-challenges") { ChallengesView {} }
                else if ProcessInfo.processInfo.arguments.contains("--hero-pose-review") { HeroPoseReview() }
                else if ProcessInfo.processInfo.arguments.contains("--mage-pose-review") { MagePoseReview() }
                else if ProcessInfo.processInfo.arguments.contains("--exp-art-review") { ExpansionArtReview() }
                else if ProcessInfo.processInfo.arguments.contains("--monster-lab") { MonsterLabView() }
                else if ProcessInfo.processInfo.arguments.contains("--expansion-lab") { ExpansionLabView() }
                else if ProcessInfo.processInfo.arguments.contains("--presentation-lab") { CombatPresentationLabView() }
                // The 1.1 shell's own audits/fixtures (`--integrated-*`) are driven against the expansion shell directly.
                else if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--integrated-") }) { ExpansionGameView() }
                else if Bundle.main.bundleIdentifier == "com.tacticalgo.prototype.presentationlab" || ProcessInfo.processInfo.arguments.contains("--v11-home") { V11HomeView() }
                else { normalRoot }
                #else
                normalRoot
                #endif
            }.task {
                guard legacyReview, !ready, !failed else { return }
                do { try await ModelLibrary.load(); ready = true }
                catch { failed = true; print("Model resource load failed:", error) }
            }
        }
    }
}
