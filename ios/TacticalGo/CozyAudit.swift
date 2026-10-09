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
#endif
