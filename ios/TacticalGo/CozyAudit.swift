#if DEBUG
import Foundation
import TacticalGoCore
import TacticalGoMotion

@MainActor enum CozyTrace {
    private static var lastPhase: [UUID: String] = [:]
    private static var rows: [[String: Any]] = []
    static func record(receipt: BoardPlayback?, elapsed: Double, reduced: Bool) {
        guard let receipt else { return }
        let clip = receipt.magicHand
        let duration = receipt.visualDuration
        let phase: String
        if reduced { phase = "reduced-final" }
        else if clip != nil { phase = clip!.timing.phase(at: elapsed) }
        else if let hero = receipt.heroPerformance {
            let t = hero.timing
            if hero.isSummon { phase = elapsed < 0.26 ? "body-summon-approach" : elapsed < hero.duration ? "body-summon-settle" : "final" }
            else { phase = elapsed < t.anticipationEnd ? "body-charge" : elapsed < t.release ? "body-release" : elapsed < t.moveStart ? "body-impact" : elapsed < t.arrival ? "body-travel" : elapsed < t.captureStart ? "body-land" : elapsed < duration ? "body-recover-capture" : "final" }
        }
        else {
            switch receipt.action {
            case .summonHero: phase = elapsed < 0.322 ? "summon-appear" : elapsed < 0.46 ? "summon-settle" : elapsed < duration ? "capture" : "final"
            case .castBastion: phase = elapsed < 0.18 ? "shield" : elapsed < 0.48 ? "two-drops" : elapsed < duration ? "capture" : "final"
            case .castSwap: phase = elapsed < 0.10 ? "swap-charge" : elapsed < 0.42 ? "swap-travel" : elapsed < duration ? "capture" : "final"
            default: phase = elapsed < 0.21 ? "drop" : elapsed < 0.30 ? "land" : elapsed < duration ? "capture-or-result" : "final"
            }
        }
        guard lastPhase[receipt.id] != phase else { return }
        lastPhase[receipt.id] = phase
        rows.append(["receipt": receipt.id.uuidString, "phase": phase, "elapsed": elapsed,
                     "observedUptime": ProcessInfo.processInfo.systemUptime, "receiptUptime": receipt.startedUptime,
                     "progress": clip?.progress(at: elapsed, reducedMotion: reduced) ?? min(1, max(0, elapsed / max(0.001,duration)))])
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
            await wait(audio.voiceDurationForAudit("voice-mage-summon") + 0.85); check("voice_duck_restores", audio.musicDuckGain > 0.99)
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
/// Bounded DEBUG evidence of the exact successful store receipt; never writes game state.
@MainActor enum GameFeelReceiptAudit {
    private static var rows: [[String: Any]] = []
    static func record(_ receipt: BoardPlayback, reduced: Bool) {
        func snapshot(_ state: GameState) -> [String: Any] {
            ["current": String(describing: state.current),"ap": state.apRemaining,"mana": [state.mana(of: .one),state.mana(of: .two)],
             "status": String(describing: state.status),"classes": [state.heroClass(of: .one).rawValue,state.heroClass(of: .two).rawValue],
             "pieces": state.board.points.compactMap { p -> [String: Any]? in
                 guard let piece = state.board[p] else { return nil }
                 return ["at": [p.x,p.y],"kind": String(describing: piece.kind),"owner": String(describing: piece.owner)]
             }]
        }
        let directory = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first
        if rows.isEmpty, let directory, let data = try? Data(contentsOf: directory.appendingPathComponent("game-feel-receipts.json")),
           let stored = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] { rows = stored }
        let voice = HeroVoiceCue.make(before: receipt.before,action: receipt.action,outcome: receipt.outcome)?.key ?? "none"
        rows.append(["id": receipt.id.uuidString,"receiptUptime": receipt.startedUptime,"action": String(describing: receipt.action),
                     "before": snapshot(receipt.before),"after": snapshot(receipt.outcome.state),"voice": voice,"voiceEligibilityOnly": true,"reducedMotion": reduced,
                     "mageTempo":receipt.mageTempo.rawValue,"visualDuration":receipt.visualDuration,
                     "heroBody":receipt.heroPerformance.map { p in ["class":p.heroClass.rawValue,"summon":p.isSummon,"release":p.timing.release,"moveStart":p.timing.moveStart,"arrival":p.timing.arrival,"captureStart":p.timing.captureStart,"recoveryEnd":p.timing.recoveryEnd] as [String:Any] } ?? [:],
                     "skillVFX":receipt.skillVFX.map{ p in ["kind":p.kind.rawValue,"hero":[p.hero.x,p.hero.y],"sources":p.sources.map{[$0.x,$0.y]},"destinations":p.destinations.map{[$0.x,$0.y]},"release":p.release,"moveStart":p.moveStart,"arrival":p.arrival,"captureStart":p.captureStart,"end":p.end] as [String:Any]} ?? [:],
                     "mageRevision":ProcessInfo.processInfo.arguments.contains("--mage-m2-reference") ? "m2" : "m3",
                     "effectsEnabled": !ProcessInfo.processInfo.arguments.contains("--mage-no-effects"),
                     "events": receipt.outcome.events.map { String(describing: $0) },"size": receipt.before.board.size])
        if rows.count > 64 { rows.removeFirst() }
        if let d = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: rows,options: [.prettyPrinted,.sortedKeys]).write(to: d.appendingPathComponent("game-feel-receipts.json"),options: .atomic)
        }
    }
}
/// Fixed visual invariants are authored from the reviewed coordinates/timing brief.
@MainActor enum GameFeelFrameAudit {
    static func run(store: GameStore) async -> String {
        let originalReduced = store.presentationReducedMotion, muted = store.audio.muted
        defer { store.cancelPresentation(); store.presentationReducedMotion = originalReduced; store.audio.muted = muted }
        var rows: [[String: Any]] = []
        func check(_ key: String,_ value: Bool) { rows.append(["check": key,"pass": value]) }
        func load(_ hero: HeroClass, diagram: String, mode: GameStore.Mode) {
            store.leaveMatch(); store.computer = nil; store.presentationReducedMotion = false
            store.session = GameSession(try! GameSetup.fromDiagram(config: .board(size: 7),diagram: diagram,classOne: hero,manaOne: 4,ap: 2))
            store.size = 7; store.mode = mode; store.audio.muted = false
            store.setSceneAudioActive(true); store.setMatchAudioActive(true)
        }
        let plain = "...O...\n.......\n.......\n.......\n.......\n...X...\n......."
        for hero in [HeroClass.warrior,.mage,.rogue] {
            load(hero,diagram: plain,mode: .summon)
            let before = store.state
            store.select(Point(3,4)); store.confirm()
            guard let receipt = store.playback else { check("summon_receipt",false); continue }
            let begin = BotBoardFrame.committed(receipt,elapsed: 0,pitch: 40,reducedMotion: false)
            let landed = BotBoardFrame.committed(receipt,elapsed: 0.46,pitch: 40,reducedMotion: false)
            check("summon_\(hero)_starts_one_hidden_hero",begin.hidden == [Point(3,4)] && begin.sprites.count == 1 && begin.sprites.first?.piece == Piece(.one,.hero) && begin.sprites.first?.opacity == 0)
            check("summon_\(hero)_lands_then_releases",landed.sprites.isEmpty && store.state.apRemaining == 1)
            store.confirm(); check("rapid_repeat_no_second_spend",store.state.apRemaining == 1)
            store.undo(); check("summon_undo_original",store.state == before && store.playback == nil && !store.isPresenting)
        }
        load(.warrior,diagram: "...O...\n.......\n.......\n...H...\n.......\n...X...\n.......",mode: .skill)
        store.select(Point(2,3)); store.select(Point(4,3)); store.confirm()
        if let receipt = store.playback {
            let frame = BotBoardFrame.committed(receipt,elapsed: 0.26,pitch: 40,reducedMotion: false)
            check("bastion_two_synchronous_soldiers_hero_fixed",frame.hidden == [Point(2,3),Point(4,3)] && frame.sprites.count == 2 && frame.sprites.allSatisfy { $0.piece.kind == .soldier } && frame.sprites[0].lift == frame.sprites[1].lift && !frame.hidden.contains(Point(3,3)))
            check("bastion_one_AP_two_Mana",store.state.apRemaining == 1 && store.state.mana(of: .one) == 2)
        } else { check("bastion_receipt",false) }
        load(.rogue,diagram: "...O...\n.......\n.......\n...Ho..\n.......\n...X...\n.......",mode: .skill)
        store.select(Point(4,3)); store.confirm()
        if let receipt = store.playback {
            let frame = BotBoardFrame.committed(receipt,elapsed: 0.32,pitch: 40,reducedMotion: false)
            check("swap_two_opposite_paths_halfway",frame.hidden == [Point(3,3),Point(4,3)] && frame.sprites.count == 2 && frame.sprites.allSatisfy { abs($0.progress - 0.5) < 0.001 } && frame.sprites[0].from == frame.sprites[1].to && frame.sprites[1].from == frame.sprites[0].to)
            check("swap_preserves_two_piece_identities",Set(frame.sprites.map { String(describing: $0.piece) }).count == 2 && store.state.board[Point(4,3)] == Piece(.one,.hero) && store.state.board[Point(3,3)] == Piece(.two,.soldier))
        } else { check("swap_receipt",false) }
        let surround = ".......\n...x...\n..xO...\n...x...\n.......\n...X...\n......."
        for reduced in [false,true] {
            load(.warrior,diagram: surround,mode: .soldier); store.presentationReducedMotion = reduced
            let before = store.state, audioStart = store.audio.playbackObservations.count; store.select(Point(4,2)); store.confirm()
            if let receipt = store.playback {
                let frame = BotBoardFrame.committed(receipt,elapsed: 0.4,pitch: 40,reducedMotion: reduced)
                let commander = frame.sprites.first { $0.piece == Piece(.two,.commander) }
                check("capture_\(reduced)_real_commander_result",store.state.winner == .one && store.state.board[Point(3,2)] == nil && store.state.apRemaining == 1)
                check("capture_\(reduced)_visual_contract",reduced ? frame.sprites.isEmpty && !store.isPresenting : (commander?.opacity ?? 1) < 1 && (commander?.scale ?? 1) < 1)
                try? await Task.sleep(for: .seconds(0.70))
                let actualKeys = store.audio.playbackObservations.dropFirst(audioStart).compactMap { $0["key"] }
                check("capture_\(reduced)_sound_retained",actualKeys.contains("place") && actualKeys.contains("capture"))
                store.undo(); check("capture_\(reduced)_undo_clears_all",store.state == before && store.playback == nil && !store.isPresenting)
            } else { check("capture_receipt",false) }
        }
        let pass = rows.allSatisfy { $0["pass"] as? Bool == true }
        if let d = FileManager.default.urls(for: .documentDirectory,in: .userDomainMask).first {
            try? JSONSerialization.data(withJSONObject: ["status":pass ? "PASS":"FAIL","checks":rows],options: [.prettyPrinted,.sortedKeys]).write(to:d.appendingPathComponent("game-feel-frame-audit.json"),options:.atomic)
        }
        return pass ? "PASS \(rows.count)/\(rows.count)" : "FAIL"
    }
}
#endif
