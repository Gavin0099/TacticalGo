#if DEBUG
import Foundation
import AVFoundation
import TacticalGoCore
import TacticalGoContent
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
        audio.musicEnabled = true; audio.voiceEnabled = false
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
        record("completed_players_retained", audio.cachedEffectCount == 11 && audio.activeEffectCount == 0)
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
        let beforeWrap = audio.musicPlayerTimes
        try? await Task.sleep(for: .milliseconds(1100))
        let afterWrap = audio.musicPlayerTimes
        // The physical device may service the main-actor task after 1.1 seconds;
        // verify an actual wrap from the near-end seek rather than a brittle <1s phase.
        record("B_loop_wrap_sync", beforeWrap.count == 3 && beforeWrap.allSatisfy { $0 >= 76.0 } &&
               afterWrap.count == 3 && afterWrap.allSatisfy { $0 < 76.0 } && phaseSpread() < 0.01 && audio.musicIsPlaying)
        let wrapEvidence: [String: Any] = ["before": beforeWrap, "after": afterWrap,
            "phaseSpread": phaseSpread(), "cachedSFX": audio.cachedEffectCount]
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: wrapEvidence, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("integrated-audio-observations.json"), options: .atomic)
        }
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
        // AV21: real expansion receipt routes the player's defeat through the existing music bus.
        audio.resetBattle(); audio.musicVolume = 0.2; audio.sfxVolume = 0
        let terminal = ExpansionLabStore(soundDefaults:defaults); terminal.computer = .one; terminal.muted = true
        var terminalCalls: [String] = []
        terminal.onTerminalCue = { key in terminalCalls.append(key); audio.play(key) }
        terminal.warriorBotReview(); terminal.scene(true)
        let winningShift = GameAction.castReformation(SoldierShift(Point(3,3),Point(4,2)), SoldierShift(Point(5,3),Point(5,2)))
        let terminalCommitted = terminal.commit(winningShift,systemReduced:false)
        record("expansion_receipt_is_computer_commander_capture", terminalCommitted && terminal.state.status == .won && terminal.state.winner == .one)
        try? await Task.sleep(for: .milliseconds(1300))
        record("expansion_defeat_routes_music_with_SFX_off", terminalCalls == ["defeat"] && audio.musicEnded && audio.musicEndingIsPlaying && audio.activeEffectCount == 0)
        terminal.stop(); audio.cancelEffects(); audio.setSceneActive(false); audio.setSceneActive(true)
        try? await Task.sleep(for: .milliseconds(1400))
        record("expansion_terminal_no_loop_or_ending_revival", terminalCalls == ["defeat"] && !audio.musicIsPlaying && !audio.musicEndingIsPlaying)
        // UX26: new ordinary Redeploy must use the accepted Mage voice and transfer presentation.
        let redeploy = ExpansionLabStore(soundDefaults:defaults);redeploy.practice(.mage);redeploy.voice = true;redeploy.muted = false;redeploy.scene(true)
        let redeployBefore = redeploy.state, move = GameAction.castFriendlyRedeploy(Point(4,5),Point(5,5))
        let expectedMove = GameEngine.apply(redeployBefore,move)
        let redeployed = redeploy.commit(move,systemReduced:false)
        record("updated_mage_redeploy_routes_confirmed_transfer_and_B_voice",redeployed && expectedMove.success && redeploy.state == expectedMove.state && redeploy.presentationHold == 1.08 && Set(redeploy.lastSoundKeys) == Set(["p5-conjure","p5-push","p5-contact","mage-cast-B"]))
        try? await Task.sleep(for:.milliseconds(160))
        record("updated_mage_native_voice_player_started",redeploy.audit.contains("voices=1"))
        redeploy.undo()
        record("updated_mage_undo_cancels_audio_and_restores_state",redeploy.state == redeployBefore && redeploy.audit.contains("voices=0") && !redeploy.playing)
        _ = redeploy.commit(move,systemReduced:false)
        try? await Task.sleep(for:.milliseconds(160));redeploy.scene(false)
        try? await Task.sleep(for:.milliseconds(1300));redeploy.scene(true)
        record("updated_mage_background_never_replays_old_voice",redeploy.state == expectedMove.state && redeploy.audit.contains("voices=0") && !redeploy.playing)
        redeploy.scene(false)
        // AV23: an ordinary follow-up must not truncate a completed skill's committed voice.
        let responsive = ExpansionLabStore(soundDefaults:defaults);responsive.practice(.rogue);responsive.voice = true;responsive.muted = false;responsive.scene(true)
        let original = responsive.state,chain = ExpansionPractice.rogue.action
        let expectedChain = GameEngine.apply(original,chain)
        let chainCommitted = responsive.commit(chain,systemReduced:false)
        record("expansion_chain_schedules_two_independent_contacts",chainCommitted && responsive.lastSoundKeys.contains("p8-rogue-land-first") && responsive.lastSoundKeys.contains("p8-rogue-land") && responsive.audit.hasPrefix("cues=5|"))
        record("expansion_music_duck_keeps_voice_window",responsive.presentationAudioHold > responsive.presentationHold && responsive.presentationHold == 0.70)
        try? await Task.sleep(for:.milliseconds(800))
        record("expansion_visual_unlocks_while_voice_tail_plays",chainCommitted && !responsive.playing && responsive.state == expectedChain.state && responsive.audit.contains("voices=1"))
        let follow = GameAction.placeSoldier(Point(8,8)),expectedFollow = GameEngine.apply(responsive.state,follow)
        let followed = responsive.commit(follow,systemReduced:false)
        record("expansion_ordinary_followup_retains_voice",followed && expectedFollow.success && responsive.state == expectedFollow.state && responsive.audit.contains("voices=1"))
        responsive.undo()
        record("expansion_undo_cancels_retained_voice",responsive.state == expectedChain.state && responsive.audit.contains("voices=0"))
        responsive.practice(.rogue);responsive.scene(true);_ = responsive.commit(chain,systemReduced:false)
        try? await Task.sleep(for:.milliseconds(800))
        responsive.scene(false)
        record("expansion_background_cancels_retained_voice",responsive.audit.contains("voices=0") && !responsive.playing)
        try? await Task.sleep(for:.milliseconds(700))
        responsive.scene(true)
        record("expansion_return_cannot_replay_old_voice",responsive.audit.contains("voices=0") && !responsive.playing)
        responsive.scene(false)
        audio.resetBattle(); terminal.warriorBotReview(); terminal.scene(true)
        _ = terminal.commit(winningShift,systemReduced:false)
        try? await Task.sleep(for: .milliseconds(30))
        terminal.scene(false); audio.cancelEffects(); audio.finishBattleSilently(); audio.setSceneActive(false)
        try? await Task.sleep(for: .milliseconds(1500))
        terminal.scene(true); audio.setSceneActive(true)
        record("expansion_background_cancels_pending_terminal", terminalCalls == ["defeat"] && audio.musicEnded && !audio.musicIsPlaying && !audio.musicEndingIsPlaying)
        terminal.scene(false); terminal.onTerminalCue = nil
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
    static func runVolumes() async -> String {
        var checks:[Check] = []
        func record(_ name:String,_ passed:Bool) { checks.append(.init(name:name,passed:passed)) }
        func near(_ value:Double,_ expected:Double) -> Bool { abs(value-expected) < 0.000001 }
        let suite = "TacticalGo.VolumeAudit.\(UUID())"
        // The suite name must match cleanup, and no normal user preference is touched.
        let isolated = UserDefaults(suiteName:suite)!
        defer { isolated.removePersistentDomain(forName:suite) }
        let match = ExpansionLabStore(soundDefaults:isolated)
        let background = CombatAudio(defaults:isolated)
        background.musicVolume = 0.2; background.setMatchActive(true);background.setSceneActive(true)
        defer { match.scene(false);background.setMatchActive(false) }
        record("fresh_defaults_preserve_29A_without_eager_keys",match.sfxVolume == 0.80 && match.voiceVolume == 0.85 && match.voice && isolated.object(forKey:"combatAudio.expansionSFXVolume") == nil)
        let action = ExpansionPractice.rogue.action
        func prepare() { match.practice(.rogue);match.muted = false;match.scene(true) }
        prepare()
        let before = match.state,expected = GameEngine.apply(before,action)
        record("default_success",match.commit(action,systemReduced:false) && match.state == expected.state)
        record("default_stage_gains_preserved",near(match.soundVolumeForAudit("p8-rogue-coil"),0.20) && near(match.soundVolumeForAudit("p8-rogue-dash"),0.26) && near(match.soundVolumeForAudit("p8-rogue-land"),0.30) && near(match.soundVolumeForAudit("p8-voice-rogue-B"),0.85))
        let committed = match.state,generation = match.generation,hold = match.presentationHold
        match.sfxVolume = 0.40;match.voiceVolume = 0.425
        record("live_change_preserves_stage_ratios",near(match.soundVolumeForAudit("p8-rogue-coil"),0.10) && near(match.soundVolumeForAudit("p8-rogue-dash"),0.13) && near(match.soundVolumeForAudit("p8-rogue-land"),0.15) && near(match.soundVolumeForAudit("p8-voice-rogue-B"),0.425))
        record("mix_does_not_cancel_visual_or_mutate_domain",match.playing && match.state == committed && match.generation == generation && match.presentationHold == hold && hold == 0.70)
        try? await Task.sleep(for:.milliseconds(120))
        match.sfxVolume = 0
        record("SFX_zero_cancels_only_effects",!match.soundPlayingForAudit("p8-rogue-dash") && !match.soundPlayingForAudit("p8-rogue-land") && match.soundPlayingForAudit("p8-voice-rogue-B"))
        match.sfxVolume = 0.80
        try? await Task.sleep(for:.milliseconds(300))
        record("SFX_restore_does_not_revive_delayed_contacts",!match.soundPlayingForAudit("p8-rogue-land-first") && !match.soundPlayingForAudit("p8-rogue-land") && match.soundPlayingForAudit("p8-voice-rogue-B"))
        match.voiceVolume = 0
        record("voice_zero_cancels_voice_keeps_visual",!match.soundPlayingForAudit("p8-voice-rogue-B") && match.playing && match.state == committed)
        match.voiceVolume = 0.85
        record("voice_restore_does_not_restart",!match.soundPlayingForAudit("p8-voice-rogue-B"))
        prepare();_ = match.commit(action,systemReduced:false)
        match.voice = false
        try? await Task.sleep(for:.milliseconds(100))
        record("voice_toggle_cancels_only_voice",!match.soundPlayingForAudit("p8-voice-rogue-B") && match.playing && match.soundPlayingForAudit("p8-rogue-coil"))
        match.voice = true
        record("voice_toggle_on_no_revival",!match.soundPlayingForAudit("p8-voice-rogue-B"))
        prepare();match.voiceVolume = 0
        _ = match.commit(action,systemReduced:false)
        record("next_cast_silent_voice_uses_unvoiced_material",!match.lastSoundKeys.contains("p8-voice-rogue-B") && near(match.soundVolumeForAudit("p8-rogue-coil"),0.42) && near(match.soundVolumeForAudit("p8-rogue-land"),0.65))
        match.voiceVolume = 0.33;match.sfxVolume = 0.27;match.voice = false
        let reloaded = ExpansionLabStore(soundDefaults:isolated)
        record("independent_preferences_reconstruct",near(reloaded.sfxVolume,0.27) && near(reloaded.voiceVolume,0.33) && !reloaded.voice && background.musicVolume == 0.2)
        let saved = isolated.persistentDomain(forName:suite)! as NSDictionary
        reloaded.configureReviewSound(voiceEnabled:true)
        record("DEBUG_review_does_not_write_owner_preferences",saved.isEqual(to:isolated.persistentDomain(forName:suite)!) && reloaded.sfxVolume == 0.80 && reloaded.voiceVolume == 0.85 && reloaded.voice)
        match.sfxVolume = .nan;match.voiceVolume = .infinity
        record("nonfinite_levels_safely_zero",match.sfxVolume == 0 && match.voiceVolume == 0)
        match.sfxVolume = 3;match.voiceVolume = -1
        record("levels_clamp_to_slider_contract",match.sfxVolume == 1 && match.voiceVolume == 0)
        record("SFX_voice_controls_keep_BGM",background.musicIsPlaying && background.musicVolume == 0.2)
        match.stop();match.voice = true;match.voiceVolume = 0.85;match.sfxVolume = 0.80
        prepare();_ = match.commit(action,systemReduced:false);match.undo()
        match.sfxVolume = 0.50;match.voiceVolume = 0.50
        try? await Task.sleep(for:.milliseconds(450))
        record("mix_change_after_undo_no_revival",match.state == before && !match.soundPlayingForAudit("p8-rogue-land") && !match.soundPlayingForAudit("p8-voice-rogue-B"))
        // Cached player API additionally checks future scheduling and 100% gain bounds.
        let players = PresentationSamples()
        players.setMix(effects:0,voice:1)
        record("zero_effect_bus_rejects_new_cue_keeps_voice",!players.schedule("p8-rogue-land",after:0.3,volume:0.3) && players.schedule("p8-voice-rogue-B",after:0,volume:0.85))
        players.setMix(effects:1.25,voice:1/0.85)
        _ = players.schedule("p8-slime-land",after:0,volume:0.65)
        record("full_slider_keeps_native_gain_bound",near(players.volume("p8-slime-land"),0.8125) && near(players.volume("p8-voice-rogue-B"),1))
        players.cancel();background.musicVolume = 0
        prepare();_ = match.commit(action,systemReduced:false)
        try? await Task.sleep(for:.milliseconds(100))
        record("BGM_zero_keeps_voice_and_SFX",!background.musicIsPlaying && match.soundPlayingForAudit("p8-voice-rogue-B") && match.soundPlayingForAudit("p8-rogue-coil"))
        match.scene(false);match.sfxVolume = 0.80;match.voiceVolume = 0.85;match.scene(true)
        try? await Task.sleep(for:.milliseconds(400))
        record("background_mix_changes_do_not_revive",!match.soundPlayingForAudit("p8-rogue-land") && !match.soundPlayingForAudit("p8-voice-rogue-B"))
        let encoder = JSONEncoder();encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        let url = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!.appendingPathComponent("integrated-volume-audit.json")
        try? encoder.encode(checks).write(to:url,options:.atomic)
        return checks.allSatisfy(\.passed) ? "PASS" : "FAIL"
    }
    /// Uses actual Core commits and native player acceptance with a controlled cadence clock.
    /// Undo permits repeatable valid casts; this is not a real-time match or fatigue test.
    static func runVoiceCadence() async -> String {
        var checks:[Check] = []
        func record(_ name:String,_ passed:Bool) { checks.append(.init(name:name,passed:passed)) }
        let suite = "TacticalGo.CadenceAudit.\(UUID())"
        let isolated = UserDefaults(suiteName:suite)!
        defer { isolated.removePersistentDomain(forName:suite) }
        let match = ExpansionLabStore(soundDefaults:isolated)
        // This audit covers the spaced (balanced → calm) mechanics, as before; the product speaks on every cast (`.everyCast`).
        match.setVoiceCadenceForAudit(.balanced)
        defer { match.scene(false) }
        let action = ExpansionPractice.rogue.action
        let key = "p8-voice-rogue-B"
        func prepare() {
            match.practice(.rogue);match.configureReviewSound(voiceEnabled:true);match.scene(true)
            match.voiceClockForAudit = 0;match.voiceKeyForAudit = nil
        }
        func cast(_ time:Double) -> Bool {
            match.voiceClockForAudit = time
            let before = match.state, expected = GameEngine.apply(before,action)
            let success = match.commit(action,systemReduced:false)
            record("core_cast_\(checks.count)",success && expected.success && match.state == expected.state && match.presentationHold == 0.70)
            return match.lastSoundKeys.contains(key)
        }
        prepare()
        record("first_success_has_original_B",cast(0) && abs(match.soundVolumeForAudit(key)-0.85)<0.000001)
        match.undo()
        record("undo_cancels_and_does_not_rearm_line",!match.soundPlayingForAudit(key) && !cast(3))
        record("quiet_cast_preserves_full_SFX",Set(match.lastSoundKeys)==Set(["p8-rogue-coil","p8-rogue-dash","p8-rogue-land-first","p8-rogue-land"]) && abs(match.soundVolumeForAudit("p8-rogue-land")-0.65)<0.000001)
        match.undo();record("second_quiet_cast",!cast(6))
        match.undo();record("next_spaced_cast_has_B",cast(12))
        match.scene(false);match.scene(true)
        try? await Task.sleep(for:.milliseconds(400))
        record("background_cancels_without_replaying",!match.soundPlayingForAudit(key) && !match.soundPlayingForAudit("p8-rogue-land"))
        match.undo();record("background_does_not_rearm_line",!cast(15))
        prepare();match.muted = true
        record("muted_cast_has_no_cue",!cast(0) && match.lastSoundKeys.isEmpty)
        match.undo();match.muted = false;record("unmute_preserves_first_line",cast(3))
        prepare();match.voice = false
        record("voice_off_cast_is_full_SFX",!cast(0) && match.lastSoundKeys.contains("p8-rogue-land"))
        match.undo();match.voice = true;record("voice_on_preserves_first_line",cast(3))
        prepare();match.voiceVolume = 0
        record("zero_voice_has_no_line",!cast(0))
        match.undo();match.voiceVolume = 0.85;record("restored_voice_preserves_first_line",cast(3))
        prepare();match.voiceKeyForAudit = "quality35-missing-voice"
        record("missing_player_uses_full_SFX",!cast(0) && !match.lastSoundKeys.contains("quality35-missing-voice") && abs(match.soundVolumeForAudit("p8-rogue-land")-0.65)<0.000001)
        match.undo();match.voiceKeyForAudit = nil;record("failed_player_preserves_first_line",cast(3))
        prepare()
        let original = match.state,originalCues = match.cues
        match.mode = .advanced;match.select(Point(5,4));match.cancelSelection()
        record("preview_cancel_no_cues_or_domain_change",match.state==original && match.cues==originalCues)
        record("invalid_core_no_voice",!match.commit(.castChainSwap(first:Point(0,0),second:Point(0,1)),systemReduced:false) && match.state==original && match.cues==originalCues)
        record("preview_invalid_preserve_first_line",cast(0))
        prepare();match.setVoiceCadenceForAudit(.calm)
        record("calm_first_line",cast(0))
        for time in [6.0,12.0,17.0] { match.undo();record("calm_quiet_\(Int(time))",!cast(time)) }
        match.undo();record("calm_next_spaced_line",cast(18))
        match.restart();match.practice(.rogue)
        record("new_session_resets_cadence",cast(0))
        prepare();_ = cast(0);match.undo()
        let failedSetupBefore = match.state
        match.advancedCost = 7;match.restart()
        record("failed_new_game_retains_current_domain",match.state==failedSetupBefore && match.message.contains("開局失敗"))
        match.advancedCost = 4
        record("failed_new_game_does_not_rearm_voice",!cast(3))
        do {
            try match.voiceHandoffReview();match.configureReviewSound(voiceEnabled:true);match.scene(true)
            match.voiceClockForAudit = 100
            let firstExpected = GameEngine.apply(match.state,CombatVoiceHandoff.first)
            record("handoff_first_confirmed",match.commit(CombatVoiceHandoff.first,systemReduced:false) && match.state==firstExpected.state && match.lastSoundKeys.contains(key))
            try? await Task.sleep(for:.milliseconds(800))
            record("handoff_visual_unlock_has_voice_tail",!match.playing && match.soundPlayingForAudit(key))
            record("handoff_turn_is_legal",match.commit(.endTurn,systemReduced:false) && match.state.current == .two)
            match.voiceClockForAudit = 100.9
            let secondExpected = GameEngine.apply(match.state,CombatVoiceHandoff.second)
            record("quiet_other_class_preserves_previous_line",match.commit(CombatVoiceHandoff.second,systemReduced:false) && secondExpected.success && match.state==secondExpected.state && !match.lastSoundKeys.contains("mage-cast-B") && match.soundPlayingForAudit(key))
            record("carried_line_keeps_prep_mix_full_later_contact_and_input_timing",abs(match.soundVolumeForAudit("p5-conjure")-0.20)<0.000001 && abs(match.soundVolumeForAudit("p5-contact")-0.65)<0.000001 && match.presentationHold==1.08)
            match.undo();record("undo_cancels_carried_line",!match.soundPlayingForAudit(key))
        } catch { record("legal_handoff_fixture_loaded",false) }
        let encoder = JSONEncoder();encoder.outputFormatting = [.prettyPrinted,.sortedKeys]
        let url = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!.appendingPathComponent("integrated-cadence-audit.json")
        try? encoder.encode(checks).write(to:url,options:.atomic)
        return checks.allSatisfy(\.passed) ? "PASS":"FAIL"
    }

}
#endif
