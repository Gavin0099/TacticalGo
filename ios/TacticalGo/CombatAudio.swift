import AVFoundation
import Foundation
import Observation
import TacticalGoCore
import TacticalGoMotion

/// Presentation only. The store decides whether a Domain event succeeded and when each cue fires.
@MainActor @Observable final class CombatAudio {
    var muted: Bool {
        didSet { defaults.set(muted, forKey: "combatAudio.muted"); if muted { cancelEffects() }; reconcileMusic() }
    }
    var sfxVolume: Double {
        didSet {
            let value = Self.clamp(sfxVolume)
            if value != sfxVolume { sfxVolume = value }
            defaults.set(value, forKey: "combatAudio.sfxVolume")
            effects.values.forEach { $0.volume = Float(value) }
            if value == 0 { cancelEffects() }
        }
    }
    var musicVolume: Double {
        didSet {
            let value = Self.clamp(musicVolume)
            if value != musicVolume { musicVolume = value }
            defaults.set(value, forKey: "combatAudio.musicVolume")
            if value == 0 { endings.values.forEach { $0.stop() } }
            reconcileMusic()
        }
    }
    private(set) var lastError: String?
    /// Allows the presentation owner to invalidate delayed cues as soon as system audio is interrupted.
    @ObservationIgnored var onInterruption: (() -> Void)?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let bundle: Bundle
    @ObservationIgnored private var matchActive = false
    @ObservationIgnored private var sceneActive = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored private var sessionActive = false
    @ObservationIgnored private var music: [AVAudioPlayer] = []
    @ObservationIgnored private var endings: [String: AVAudioPlayer] = [:]
    @ObservationIgnored private var mix = BattleMusicMix()
    @ObservationIgnored private var mixTask: Task<Void, Never>?
    private var now: Double { ProcessInfo.processInfo.systemUptime }
    private static let musicKeys = ["b-normal", "b-focus", "b-danger"]
    // Keep cue players alive for this audio owner's lifetime. isPlaying can
    // become false before AVFoundation delivers its queued finishedPlaying
    // callback; dropping that player at the next cue caused a native crash.
    @ObservationIgnored private var effects: [String: AVAudioPlayer] = [:]
    @ObservationIgnored private var lastSelectionTime = -Double.infinity
    @ObservationIgnored nonisolated(unsafe) private var interruptionObserver: (any NSObjectProtocol)?
    private static let effectKeys: Set<String> = ["selection", "place", "capture", "summon", "mage", "warrior", "rogue", "danger", "victory", "defeat", "draw"]

    init(defaults: UserDefaults = .standard, bundle: Bundle = .main) {
        self.defaults = defaults
        self.bundle = bundle
        muted = defaults.bool(forKey: "combatAudio.muted")
        sfxVolume = Self.clamp(defaults.object(forKey: "combatAudio.sfxVolume") as? Double ?? 0.65)
        musicVolume = Self.clamp(defaults.object(forKey: "combatAudio.musicVolume") as? Double ?? 0.30)
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let typeRaw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeRaw) else { return }
            let began = type == .began
            let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let mayResume = AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume)
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.interrupted = began || !mayResume
                if began {
                    self.cancelEffects()
                    self.sessionActive = false
                    self.onInterruption?()
                }
                self.reconcileMusic()
            }
        }
    }

    deinit {
        mixTask?.cancel()
        if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
    }

    func setMatchActive(_ active: Bool) {
        matchActive = active
        if !active {
            cancelEffects()
            resetBattle()
        }
        reconcileMusic()
    }

    func setSceneActive(_ active: Bool) {
        let returningToForeground = active && !sceneActive
        sceneActive = active
        if returningToForeground { interrupted = false }
        if !active { cancelEffects() }
        reconcileMusic()
    }

    /// This starts one cue immediately; no timers, game rules or outcome inference live here.
    func play(_ key: String) {
        if ["victory", "defeat", "draw"].contains(key) { finishBattle(key) }
        guard Self.effectKeys.contains(key), matchActive, sceneActive, !interrupted, !muted, sfxVolume > 0 else { return }
        if key == "selection" {
            let now = ProcessInfo.processInfo.systemUptime
            guard now - lastSelectionTime >= 0.08 else { return }
            lastSelectionTime = now
        }
        guard activateSession() else { return }
        if effects[key] == nil { effects[key] = makePlayer(key) }
        guard let player = effects[key] else { return }
        // Reuse one retained voice per cue. Repeated cues restart rather than
        // accumulating old voices; the cache is bounded by the known 11 keys.
        if effects.values.filter({ $0.isPlaying }).count >= 8,
           let other = effects.first(where: { $0.key != key && $0.value.isPlaying })?.value { other.stop() }
        player.stop(); player.currentTime = 0
        player.volume = Float(sfxVolume)
        if !player.play() { lastError = "音效無法播放：\(key)" }
    }

    func cancelEffects() {
        effects.values.forEach { $0.stop() }
        endings.values.forEach { $0.stop() }
        mix.cancelDuck()
        updateMix()
        lastSelectionTime = -Double.infinity
    }

    func resetBattle() {
        mixTask?.cancel(); mixTask = nil
        music.forEach { $0.stop(); $0.currentTime = 0 }
        endings.values.forEach { $0.stop() }
        mix = BattleMusicMix()
        reconcileMusic()
    }
    func updateState(_ state: GameState) {
        if state.status == .ongoing {
            if mix.ended { resetBattle() }
            mix.request(BattleMusicMix.threat(state), at: now)
        }
        updateMix()
    }
    func duckSkill(duration: Double) {
        guard matchActive, sceneActive, !muted, !interrupted, sfxVolume > 0 else { return }
        mix.duck(through: now + duration, at: now)
        startMixTask()
    }
    private func finishBattle(_ key: String) {
        guard matchActive, sceneActive, !interrupted, !mix.ended else { return }
        mix.finish(at: now); startMixTask()
        guard !muted, musicVolume > 0, key != "draw", activateSession() else { return }
        if endings[key] == nil { endings[key] = makePlayer("b-" + key) }
        if let player = endings[key] {
            player.currentTime = 0; player.volume = Float(musicVolume)
            if !player.play() { lastError = "勝敗樂句無法播放。" }
        }
    }

    #if DEBUG
    var musicIsPlaying: Bool { music.contains { $0.isPlaying } }
    var musicPlayerTimes: [Double] { music.map(\.currentTime) }
    var musicPlayerVolumes: [Float] { music.map(\.volume) }
    var musicPlayerDurations: [Double] { music.map(\.duration) }
    var musicEndingIsPlaying: Bool { endings.values.contains { $0.isPlaying } }
    var musicEnded: Bool { mix.ended }
    var musicDuckGain: Double { mix.duckGain(at: now) }
    var musicLevel: BattleMusicLevel { mix.level }
    func seekMusicForAudit(_ time: Double) {
        music.forEach { $0.pause(); $0.currentTime = time }
        reconcileMusic()
    }
    var cachedEffectCount: Int { effects.count }
    var activeEffectCount: Int { effects.values.filter { $0.isPlaying }.count }
    #endif

    private func updateMix() {
        mix.advance(at: now)
        let factor = musicVolume * mix.duckGain(at: now) * mix.loopGain(at: now)
        let layers = mix.layers(at: now)
        for (i, player) in music.enumerated() { player.volume = Float(factor * layers[i]) }
        endings.values.forEach { $0.volume = Float(musicVolume) }
        if mix.ended && mix.loopGain(at: now) == 0 { music.forEach { $0.pause() } }
    }
    private func startMixTask() {
        guard mixTask == nil, sceneActive, matchActive else { return }
        mixTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.sceneActive, self.matchActive else { return }
                self.updateMix()
                if self.mix.ended && self.mix.loopGain(at: self.now) == 0 {
                    self.mixTask = nil; return
                }
                do { try await Task.sleep(for: .milliseconds(50)) } catch { return }
            }
        }
    }
    private func reconcileMusic() {
        guard matchActive, sceneActive, !interrupted, !muted, musicVolume > 0,
              !mix.ended || mix.loopGain(at: now) > 0 else {
            mixTask?.cancel(); mixTask = nil
            if let phase = music.first?.currentTime {
                music.forEach { $0.pause(); $0.currentTime = phase }
            }
            if !sceneActive || !matchActive || muted {
                if sessionActive {
                    try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                    sessionActive = false
                }
            }
            return
        }
        guard activateSession() else { return }
        if music.isEmpty {
            let players = Self.musicKeys.compactMap(makePlayer)
            guard players.count == 3,
                  players.allSatisfy({ abs($0.duration - 76.8) < 0.001 }) else {
                lastError = "B 音樂層缺失或長度不一致。"; return
            }
            music = players
            music.forEach { $0.numberOfLoops = -1 }
        }
        updateMix()
        if music.contains(where: { !$0.isPlaying }), let clock = music.first {
            let phase = clock.currentTime
            music.forEach { $0.pause(); $0.currentTime = phase; $0.prepareToPlay() }
            let start = clock.deviceCurrentTime + 0.10
            let results = music.map { $0.play(atTime: start) }
            if !results.allSatisfy({ $0 }) {
                music.forEach { $0.stop() }; lastError = "B 背景音樂無法同步播放。"
            }
        }
        startMixTask()
    }

    private func activateSession() -> Bool {
        if sessionActive { return true }
        do {
            // Ambient respects the iPhone silent switch and mixes with the owner's existing audio.
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            sessionActive = true
            return true
        } catch {
            lastError = "音訊工作階段啟動失敗：\(error.localizedDescription)"
            return false
        }
    }

    private func makePlayer(_ name: String) -> AVAudioPlayer? {
        guard let url = bundle.url(forResource: name, withExtension: "wav", subdirectory: "Audio")
            ?? bundle.url(forResource: name, withExtension: "wav") else {
            lastError = "找不到音訊素材：\(name).wav"
            return nil
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            lastError = "無法讀取音訊素材 \(name)：\(error.localizedDescription)"
            return nil
        }
    }

    private static func clamp(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0 }
}
