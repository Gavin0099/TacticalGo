import SwiftUI
import TacticalGoContent
@main struct TacticalGoApp: App {
    init() {
        #if DEBUG
        Self.resetSoundPreferencesIfRequested()
        #endif
    }
    #if DEBUG
    /// UI tests pass `--sound-preferences-reset <token>` so each test starts from the default sound settings instead of
    /// whatever an earlier test left in UserDefaults. The reset happens once per token: relaunching inside the same
    /// test (to check that settings persist) keeps the values that test chose.
    private static func resetSoundPreferencesIfRequested() {
        let args = ProcessInfo.processInfo.arguments, defaults = UserDefaults.standard
        guard let i = args.firstIndex(of: "--sound-preferences-reset"), args.indices.contains(i + 1) else { return }
        let token = args[i + 1]
        guard defaults.string(forKey: "debug.soundPreferencesResetToken") != token else { return }
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("combatAudio.") { defaults.removeObject(forKey: key) }
        defaults.set(token, forKey: "debug.soundPreferencesResetToken")
    }
    #endif
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
        if !legacyReview { productRoot }
        else if ready { ContentView() }
        else if failed { Text("棋盤載入失敗。請重新開啟遊戲。").padding() }
        else { ProgressView("準備棋盤…") }
    }
    /// Owner decision 2026-10-15: the TestFlight/Beta product runs the 1.1 shell for everything (the original rules are an
    /// option inside it). Release keeps the original shell. Debug keeps it by default so the 1.0 UI suites keep their
    /// subject; `--full-game` selects the new root there.
    @ViewBuilder private var productRoot: some View {
        #if TACTICALGO_V11 && !DEBUG
        FullGameRoot()
        #elseif DEBUG
        if ProcessInfo.processInfo.arguments.contains("--full-game") { FullGameRoot() } else { PlayableGameView() }
        #else
        PlayableGameView()
        #endif
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
                else if Bundle.main.bundleIdentifier == "com.tacticalgo.prototype.presentationlab" || ProcessInfo.processInfo.arguments.contains("--v11-home") { V11HomeView() }
                // The 1.1 shell's own audits/fixtures (`--integrated-*`) are driven against the expansion shell directly.
                else if ProcessInfo.processInfo.arguments.contains(where: { $0.hasPrefix("--integrated-") }) { ExpansionGameView() }
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
