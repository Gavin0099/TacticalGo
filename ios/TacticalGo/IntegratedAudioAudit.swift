#if DEBUG
import Foundation
import AVFoundation
import TacticalGoCore
import TacticalGoMotion

/// Exercises real AVAudioPlayer and the integrated store's cancellable cue task.
@MainActor enum IntegratedAudioAudit {
    struct Check: Codable { let name: String; let passed: Bool }
    static func run() async -> String {
        var checks: [Check] = []
        func record(_ name: String, _ passed: Bool) { checks.append(.init(name: name, passed: passed)) }
        let suite = "TacticalGo.IntegratedAudioAudit.\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        let audio = CombatAudio(defaults: defaults)
        audio.musicVolume = 0; audio.sfxVolume = 0.35
        audio.setMatchActive(true); audio.setSceneActive(true)
        let keys = ["selection", "mage", "place", "capture", "victory"]
        var played = false
        for _ in 0..<8 {
            for key in keys {
                audio.play(key); played = played || audio.activeEffectCount > 0
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
        audio.cancelEffects()
        record("native_player_started_and_stopped", played && audio.activeEffectCount == 0 && audio.lastError == nil)
        try? await Task.sleep(for: .milliseconds(300))
        record("native_cancel_no_revival", audio.activeEffectCount == 0)
        audio.play("victory")
        record("native_restart", audio.activeEffectCount > 0)
        try? await Task.sleep(for: .milliseconds(2500))
        record("completed_players_retained", audio.cachedEffectCount == 5 && audio.activeEffectCount == 0)
        audio.resetBattle()
        audio.musicVolume = 0.2
        try? await Task.sleep(for: .milliseconds(200))
        record("loop_music_started", audio.musicIsPlaying && audio.lastError == nil)
        audio.setSceneActive(false)
        record("background_pauses_music", !audio.musicIsPlaying)
        audio.setSceneActive(true)
        try? await Task.sleep(for: .milliseconds(200))
        record("foreground_resumes_music", audio.musicIsPlaying)
        audio.setMatchActive(false)
        record("leaving_stops_music", !audio.musicIsPlaying)
        // AUDIO-02 B: exercise the actual device-clock players, not a mock mixer.
        audio.setMatchActive(true)
        try? await Task.sleep(for: .milliseconds(250))
        func phaseSpread() -> Double {
            let times = audio.musicPlayerTimes
            guard times.count == 3 else { return .infinity }
            let raw = (times.max() ?? 0) - (times.min() ?? 0)
            return min(raw, 76.8 - raw)
        }
        record("B_three_equal_native_durations", audio.musicPlayerDurations.count == 3 && audio.musicPlayerDurations.allSatisfy { abs($0 - 76.8) < 0.001 })
        record("B_device_clock_sync", phaseSpread() < 0.01 && audio.musicIsPlaying)
        audio.seekMusicForAudit(76.1)
        try? await Task.sleep(for: .milliseconds(1100))
        record("B_loop_wrap_sync", phaseSpread() < 0.01 && (audio.musicPlayerTimes.first ?? 99) < 1 && audio.musicIsPlaying)
        audio.updateState(try! CombatDemo.initialState())
        try? await Task.sleep(for: .milliseconds(4900))
        record("B_danger_layers_ramp", audio.musicLevel == .danger && audio.musicPlayerVolumes.count == 3 && audio.musicPlayerVolumes.allSatisfy { abs($0 - 0.2) < 0.01 })
        audio.duckSkill(duration: 0.5)
        try? await Task.sleep(for: .milliseconds(200))
        record("B_skill_duck_minus_5dB", abs(audio.musicDuckGain - pow(10.0,-5.0/20.0)) < 0.001 && audio.musicPlayerVolumes.allSatisfy { $0 < 0.12 })
        audio.cancelEffects()
        record("B_cancel_clears_duck", audio.musicDuckGain == 1)
        audio.musicVolume = 0; audio.play("place")
        record("B_music_off_keeps_SFX", !audio.musicIsPlaying && audio.activeEffectCount > 0)
        audio.cancelEffects(); audio.sfxVolume = 0; audio.musicVolume = 0.2
        try? await Task.sleep(for: .milliseconds(150))
        record("B_SFX_off_keeps_music", audio.musicIsPlaying && audio.activeEffectCount == 0)
        audio.muted = true
        record("B_mute_all", !audio.musicIsPlaying && audio.activeEffectCount == 0 && !audio.musicEndingIsPlaying)
        audio.muted = false
        try? await Task.sleep(for: .milliseconds(150))
        record("B_unmute_same_phase", audio.musicIsPlaying && phaseSpread() < 0.01)
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.began.rawValue])
        try? await Task.sleep(for: .milliseconds(100))
        record("B_interruption_pauses", !audio.musicIsPlaying)
        NotificationCenter.default.post(name: AVAudioSession.interruptionNotification, object: nil,
            userInfo: [AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended.rawValue,
                       AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume.rawValue])
        try? await Task.sleep(for: .milliseconds(200))
        record("B_interruption_resumes_sync", audio.musicIsPlaying && phaseSpread() < 0.01)
        audio.play("victory")
        record("B_end_phrase_uses_music_bus_with_SFX_off", audio.musicEndingIsPlaying && audio.musicEnded && audio.activeEffectCount == 0)
        try? await Task.sleep(for: .milliseconds(1400))
        record("B_terminal_fades_loop", !audio.musicIsPlaying && audio.musicEndingIsPlaying)
        try? await Task.sleep(for: .milliseconds(4800))
        record("B_six_second_phrase_finishes", !audio.musicEndingIsPlaying)
        audio.setSceneActive(false); audio.setSceneActive(true); audio.musicVolume = 0.3
        record("B_terminal_never_revives", !audio.musicIsPlaying && !audio.musicEndingIsPlaying)
        audio.resetBattle()
        try? await Task.sleep(for: .milliseconds(200))
        record("B_restart_resets_loop", audio.musicIsPlaying && !audio.musicEnded && audio.musicLevel == .normal)
        audio.play("defeat"); audio.setSceneActive(false)
        record("B_background_cancels_ending", !audio.musicEndingIsPlaying && !audio.musicIsPlaying)
        audio.setSceneActive(true)
        try? await Task.sleep(for: .milliseconds(1400))
        record("B_background_no_old_ending", !audio.musicEndingIsPlaying && !audio.musicIsPlaying)
        audio.setMatchActive(false)
        defaults.removePersistentDomain(forName: suite)

        let store = GameStore()
        let originalMute = store.audio.muted
        store.audio.muted = true
        defer { store.leaveMatch(); store.audio.muted = originalMute }
        func prepare() {
            store.startPractice(.mage); store.setMatchAudioActive(true); store.setSceneAudioActive(true)
            store.select(Point(4, 3)); store.chooseDirection(.up)
        }
        prepare(); let endTurnCount = store.audioCueHistory.count
        store.confirm(); store.endTurn()
        try? await Task.sleep(for: .milliseconds(1000))
        record("end_turn_preserves_committed_skill_cues", Array(store.audioCueHistory.dropFirst(endTurnCount)) == ["mage", "place"])
        prepare(); let initial = store.state; store.confirm()
        try? await Task.sleep(for: .milliseconds(30))
        store.undo(); let cancelledCount = store.audioCueHistory.count
        try? await Task.sleep(for: .milliseconds(1700))
        record("undo_cancels_pending_success_cues", store.state == initial && store.audioCueHistory.count == cancelledCount)
        prepare(); store.confirm(); let committed = store.state
        try? await Task.sleep(for: .milliseconds(30))
        store.setSceneAudioActive(false); let backgroundCount = store.audioCueHistory.count
        try? await Task.sleep(for: .milliseconds(1700))
        store.setSceneAudioActive(true)
        record("background_preserves_core_and_cancels_cues", store.state == committed && store.audioCueHistory.count == backgroundCount)
        prepare(); store.confirm()
        try? await Task.sleep(for: .milliseconds(30))
        store.newMatch(); let restarted = store.state, restartCount = store.audioCueHistory.count
        try? await Task.sleep(for: .milliseconds(1700))
        record("restart_no_old_cues", store.state == restarted && store.audioCueHistory.count == restartCount)
        store.setMatchAudioActive(true)
        store.select(Point(3, 5)) // New-game black commander, occupied.
        let illegalBefore = store.state, illegalCount = store.audioCueHistory.count
        store.confirm()
        try? await Task.sleep(for: .milliseconds(500))
        record("illegal_action_no_success_cues", store.state == illegalBefore && store.audioCueHistory.count == illegalCount)
        let victoryBefore = try! CombatDemo.initialState()
        let victory = GameEngine.apply(victoryBefore, CombatDemo.action)
        let winCount = store.audioCueHistory.count
        store.presentAudio(before: victoryBefore, action: CombatDemo.action, outcome: victory)
        try? await Task.sleep(for: .milliseconds(1600))
        record("local_success_event_order", Array(store.audioCueHistory.dropFirst(winCount)) == ["mage", "place", "capture", "victory"])
        store.computer = .one
        let defeatCount = store.audioCueHistory.count
        store.presentAudio(before: victoryBefore, action: CombatDemo.action, outcome: victory)
        try? await Task.sleep(for: .milliseconds(1600))
        record("computer_win_uses_human_defeat_cue", Array(store.audioCueHistory.dropFirst(defeatCount)) == ["mage", "place", "capture", "defeat"])
        let status = checks.allSatisfy(\.passed) ? "PASS" : "FAIL"
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try? encoder.encode(checks).write(to: directory.appendingPathComponent("integrated-audio-audit.json"), options: .atomic)
        return status
    }
}
#endif
