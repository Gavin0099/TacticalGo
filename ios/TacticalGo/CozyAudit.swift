#if DEBUG
import Foundation
import TacticalGoCore
import TacticalGoMotion

@MainActor enum CozyTrace {
    private static var lastPhase: [UUID: String] = [:]
    private static var rows: [[String: Any]] = []
    static func record(receipt: BoardPlayback?, elapsed: Double, reduced: Bool) {
        guard let receipt, let clip = Anim01MagicHand.make(before: receipt.before, action: receipt.action, outcome: receipt.outcome) else { return }
        let phase = reduced ? "reduced-final" : elapsed < 0.08 ? "charge" : elapsed < 0.30 ? "push" : elapsed < 0.40 ? "settle" : elapsed < clip.duration ? "capture" : "final"
        guard lastPhase[receipt.id] != phase else { return }
        lastPhase[receipt.id] = phase
        rows.append(["receipt": receipt.id.uuidString, "phase": phase, "elapsed": elapsed,
                     "observedUptime": ProcessInfo.processInfo.systemUptime, "receiptUptime": receipt.startedUptime,
                     "progress": clip.progress(at: elapsed, reducedMotion: reduced)])
        if rows.count > 100 { rows.removeFirst() }
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("cozy-render-trace.json"), options: .atomic)
        }
    }
}

/// Executes the visible game's actual store/audio owner, not a parallel player.
@MainActor enum CozyAudit {
    static func run(store: GameStore) async -> String {
        let audio = store.audio
        let savedMute = audio.muted, savedSFX = audio.sfxVolume
        defer { store.cancelPresentation(); audio.muted = savedMute; audio.sfxVolume = savedSFX }
        audio.muted = false; audio.sfxVolume = 0.65
        store.setSceneAudioActive(true); store.setMatchAudioActive(true)
        var rows: [[String: Any]] = []
        func check(_ name: String, _ pass: Bool) { rows.append(["check": name, "pass": pass]) }
        func reset(capture: Bool = true) {
            store.leaveMatch(); store.computer = nil; store.recordErrorMessage = nil
            store.session = GameSession(try! Anim01Fixture.state(capture: capture))
            store.size = 7; store.mode = .skill; store.selected = []; store.pushDirection = nil
            store.setMatchAudioActive(true)
        }
        func prepare() { store.select(Point(4, 3)); store.chooseDirection(.up) }
        func wait(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
        reset(); prepare()
        let before = store.state, count = audio.playbackObservations.count
        check("preview_unchanged_resources_and_source", store.state == before && store.preview?.success == true)
        check("preview_no_success_cues", !audio.playbackObservations.dropFirst(count).contains { $0["key"] != "selection" })
        store.cancelSelection(); await wait(0.9)
        check("cancel_no_pending_success", audio.activeEffectCount == 0 && store.state == before)
        prepare(); store.confirm()
        let committed = store.state, receipt = store.playback
        store.confirm()
        check("rapid_confirmation_commits_once", store.state == committed && store.playback?.id == receipt?.id)
        // Let the actual victory voice finish for the retained native recording.
        await wait(3.2)
        let cues = audio.playbackObservations.dropFirst(count).filter { $0["key"] != "selection" }
        check("success_real_owner_mage_place_capture_victory", cues.map { $0["key"] ?? "" } == ["mage", "place", "capture", "victory"] && cues.allSatisfy { $0["playing"] == "true" })
        check("settled_domain_result", store.state == GameEngine.apply(before, Anim01Fixture.action).state && !store.isPresenting)
        check("music_hold_sfx_active", !audio.musicIntegrationAllowed && !audio.musicIsPlaying && audio.lastError == nil)
        let observations = Array(cues)
        reset(capture: false); prepare(); let noCaptureCount = audio.playbackObservations.count
        store.confirm(); await wait(1.05)
        check("no_capture_no_capture_or_victory_sound", audio.playbackObservations.dropFirst(noCaptureCount).map { $0["key"] ?? "" } == ["mage", "place"])
        reset(); store.selected = [Point(0, 0)]; store.pushDirection = .up
        let invalidState = store.state, invalidCount = audio.playbackObservations.count
        store.confirm(); await wait(0.9)
        check("invalid_no_spend_no_receipt_no_sound", store.state == invalidState && store.playback == nil && !store.isPresenting && audio.playbackObservations.count == invalidCount)
        for boundary in ["undo", "cancel", "background", "restart", "leave", "interruption"] {
            reset(); prepare(); let initial = store.state
            store.confirm(); await wait(0.025)
            let observed = audio.playbackObservations.count
            switch boundary {
            case "undo": store.undo()
            case "cancel": store.cancelSelection()
            case "background": store.setSceneAudioActive(false)
            case "restart": store.newMatch(classOne: .mage, classTwo: .warrior)
            case "leave": store.leaveMatch()
            default: audio.onInterruption?()
            }
            await wait(0.95)
            check(boundary + "_no_late_sound_or_visual", audio.activeEffectCount == 0 && audio.playbackObservations.count == observed && !store.isPresenting && store.playback == nil)
            if boundary == "undo" { check("undo_full_core_history", store.state == initial) }
            store.setSceneAudioActive(true); store.setMatchAudioActive(true)
        }
        reset(); prepare(); audio.sfxVolume = 0
        let silentCount = audio.playbackObservations.count; store.confirm(); await wait(1.05)
        check("sfx_zero_suppresses_cues", audio.playbackObservations.count == silentCount)
        let pass = rows.allSatisfy { $0["pass"] as? Bool == true }
        let report: [String: Any] = ["status": pass ? "PASS" : "FAIL", "checks": rows,
            "owner": "PlayableGameView.store.audio", "cueObservations": observations,
            "receiptUptime": receipt?.startedUptime ?? -1,
            "claimBoundary": "Actual retained AVAudioPlayer.play return, not speaker/headphone audibility or measured acoustic latency"]
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
                .write(to: directory.appendingPathComponent("cozy-runtime-audit.json"), options: .atomic)
        }
        return pass ? "PASS \(rows.count)/\(rows.count)" : "FAIL"
    }
}
/// Native retained-owner audit; generated fixture actions still pass through GameStore/Core.
@MainActor enum HeroVoiceAudit {
    static func run(store: GameStore) async -> String {
        let audio = store.audio
        let settings = (audio.voiceEnabled, audio.voiceVolume, audio.sfxVolume, audio.muted, audio.musicEnabled, audio.musicVolume)
        defer {
            store.cancelPresentation(); audio.voiceEnabled = settings.0; audio.voiceVolume = settings.1
            audio.sfxVolume = settings.2; audio.muted = settings.3; audio.musicEnabled = settings.4; audio.musicVolume = settings.5
        }
        audio.muted = false; audio.voiceEnabled = true; audio.voiceVolume = 0.75; audio.sfxVolume = 0.65
        var rows: [[String: Any]] = []
        var states: [[String: Any]] = []
        func check(_ key: String, _ pass: Bool) { rows.append(["check": key, "pass": pass]) }
        func wait(_ t: Double) async { try? await Task.sleep(for: .seconds(t)) }
        func reset(_ hero: HeroClass, owner: Player = .one, skill: Bool = false) {
            store.leaveMatch(); store.computer = nil; store.recordErrorMessage = nil
            let diagram: String
            if skill {
                let h = owner == .one ? "H" : "Q", enemy = owner == .one ? "o" : "x"
                diagram = "...O...\n.......\n.......\n..." + h + (hero == .rogue ? enemy : ".") + "..\n.......\n...X...\n......."
            } else { diagram = "...O...\n.......\n.......\n.......\n.......\n...X...\n......." }
            let state = skill && hero == .mage ? try! Anim01Fixture.state(caster: owner, pushedOwner: owner, capture: false)
                : try! GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram, classOne: hero, classTwo: hero, current: owner, manaOne: 4, manaTwo: 4, ap: 2)
            store.session = GameSession(state); store.size = 7; store.mode = skill ? .skill : .summon
            store.selected = []; store.pushDirection = nil; store.setSceneAudioActive(true); store.setMatchAudioActive(true)
        }
        func prepare(_ hero: HeroClass, owner: Player = .one, skill: Bool = false) {
            if !skill { store.select(owner == .one ? Point(3,4) : Point(3,1)); return }
            switch hero {
            case .warrior: store.select(Point(2,3)); store.select(Point(4,3))
            case .mage: store.select(Point(4,3)); store.chooseDirection(.up)
            case .rogue: store.select(Point(4,3))
            case .none: return
            }
        }
        for hero in [HeroClass.warrior, .mage, .rogue] {
            for skill in [false, true] {
                for owner in Player.allCases {
                    reset(hero, owner: owner, skill: skill)
                    let before = store.state, n = audio.voiceObservations.count
                    prepare(hero, owner: owner, skill: skill)
                    check("preview_\(hero.rawValue)_\(skill)_\(owner)", store.state == before && audio.voiceObservations.count == n && store.preview?.success == true)
                    store.cancelSelection(); check("cancel_preview_silent", audio.voiceObservations.count == n && store.state == before)
                    prepare(hero, owner: owner, skill: skill); store.confirm(); let after = store.state
                    await wait(0.06)
                    let key = "voice-" + hero.rawValue.lowercased() + (skill ? "-skill" : "-summon")
                    let spoken = audio.voiceObservations.dropFirst(n)
                    check(key + "_\(owner)", spoken.count == 1 && spoken.first?["key"] == key && spoken.first?["playing"] == "true" && audio.activeVoiceCount == 1 && after != before)
                    states.append(["hero": hero.rawValue, "skill": skill, "owner": String(describing: owner), "beforeAP": before.apRemaining, "afterAP": after.apRemaining, "beforeMana": before.mana(of: owner), "afterMana": after.mana(of: owner), "observedVoice": Array(spoken)])
                    await wait(max(0, audio.voiceDurationForAudit(key) - 0.06) + 0.15)
                    check("voice_finishes_no_queue", audio.activeVoiceCount == 0)
                }
            }
        }
        reset(.mage); prepare(.mage); store.confirm(); await wait(0.06)
        audio.sfxVolume = 0; check("sfx_zero_keeps_voice", audio.activeVoiceCount == 1)
        audio.musicVolume = 0; check("music_zero_keeps_voice", audio.activeVoiceCount == 1)
        audio.voiceEnabled = false; check("voice_disabled_stops_voice_only", audio.activeVoiceCount == 0)
        let n = audio.voiceObservations.count; reset(.mage); prepare(.mage); store.confirm(); await wait(0.06)
        check("voice_disabled_summon_silent", audio.voiceObservations.count == n)
        audio.voiceEnabled = true; audio.sfxVolume = 0.65
        reset(.mage); prepare(.mage); store.confirm(); await wait(0.55)
        store.mode = .soldier; store.select(Point(2,5)); store.confirm()
        check("ordinary_second_AP_does_not_restart_or_cut_voice", audio.activeVoiceCount == 1)
        for boundary in ["undo", "restart", "leave", "background", "interruption", "mute"] {
            reset(.warrior); prepare(.warrior); store.confirm(); await wait(0.06)
            let n = audio.voiceObservations.count
            switch boundary {
            case "undo": store.undo()
            case "restart": store.newMatch(classOne: .warrior, classTwo: .mage)
            case "leave": store.leaveMatch()
            case "background": store.setSceneAudioActive(false)
            case "interruption": audio.onInterruption?()
            default: audio.muted = true
            }
            await wait(1.2)
            check(boundary + "_voice_no_late_replay", audio.activeVoiceCount == 0 && audio.voiceObservations.count == n)
            audio.muted = false
        }
        reset(.mage); store.selected = [Point(0,0)]; let invalid = store.state, n2 = audio.voiceObservations.count
        store.confirm(); check("invalid_no_voice_or_spend", store.state == invalid && audio.voiceObservations.count == n2)
        if audio.musicIntegrationAllowed {
            reset(.mage); audio.musicEnabled = true; audio.musicVolume = 0.25
            await wait(0.25); check("prototype_bgm_starts_on_actual_owner", audio.musicIsPlaying)
            prepare(.mage); store.confirm(); await wait(0.20)
            check("voice_ducks_actual_bgm", audio.musicDuckGain < 0.7 && audio.musicIsPlaying)
            await wait(audio.voiceDurationForAudit("voice-mage-summon") + 0.5); check("voice_duck_restores", audio.musicDuckGain > 0.99)
        }
        check("six_retained_voices_only", audio.cachedVoiceCount == 6)
        let pass = rows.allSatisfy { $0["pass"] as? Bool == true }
        let report: [String: Any] = ["status": pass ? "PASS" : "FAIL", "checks": rows, "receiptStates": states, "voiceObservations": audio.voiceObservations, "actualOwner": "PlayableGameView.store.audio", "quality": "Prototype TTS; no human hearing or final actor approval", "bgmAuditOnly": audio.musicIntegrationAllowed]
        if let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted,.sortedKeys]).write(to: d.appendingPathComponent("hero-voice-audit.json"), options: .atomic)
        }
        return pass ? "PASS \(rows.count)/\(rows.count)" : "FAIL"
    }
}
#endif
