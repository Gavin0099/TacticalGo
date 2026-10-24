#if DEBUG || TACTICALGO_V11
import SwiftUI
import AVFoundation
import Observation
import TacticalGoCore
import TacticalGoMotion
import TacticalGoVisuals

/// Debug experiment with retained players and an explicit cancellation owner.
@MainActor final class PresentationSamples {
    private var players: [String: AVAudioPlayer] = [:]
    private var scheduledGains: [String:Double] = [:]
    private var effectsGain = 1.0
    private var voiceGain = 1.0
    private static func isVoice(_ key:String) -> Bool { key.contains("voice") || key.hasPrefix("mage-cast-") }
    private static func finiteGain(_ value:Double) -> Double { value.isFinite ? max(0,value) : 0 }
    private(set) var error: String?
    #if DEBUG
    private(set) var loadedResourcePaths: [String: String] = [:]
    #endif
    init() {
        let keys = ["p8-rogue-coil","p8-rogue-dash","p8-rogue-land","p8-rogue-land-first","p8-priest-prayer","p8-priest-bless","p8-priest-land","p8-slime-coil","p8-slime-bounce","p8-slime-land","p8-wolf-growl","p8-wolf-dash","p8-wolf-land","p8-voice-rogue-A","p8-voice-rogue-B","p8-voice-priest-A","p8-voice-priest-B","p-charge","p-release","p-land","p-capture","mage-voice-english","mage-cast-A","mage-cast-B","p3-air","p4-conjure","p4-push","p4-contact","p5-conjure","p5-push","p5-contact","w7-brace","w7-strike","w7-land","w7-voice-A","w7-voice-B","warrior","place","draw","capture","victory","defeat"]
        for key in keys + (ArtV2.sfx ? ["selection", "confirm", "summon", "commander-capture"] : []) {
            do {
                // The two chain contacts need independent players; scheduling one twice replaces its first start.
                let resourceKey = key == "p8-rogue-land-first" ? "p8-rogue-land" : key
                guard let url = ArtV2.audioURL(resourceKey, subdirectory: key.hasPrefix("p8-") ? "PresentationLab/P08" : key.hasPrefix("w7-") ? "PresentationLab/P07" : key.hasPrefix("mage-cast-") ? "PresentationLab/P06" : key.hasPrefix("p5-") ? "PresentationLab/P05" : key.hasPrefix("p4-") ? "PresentationLab/P04" : key == "p3-air" ? "PresentationLab/P03" : ["warrior","place","draw","capture","victory","defeat"].contains(key) ? "Audio" : "PresentationLab") else {
                    throw CocoaError(.fileNoSuchFile)
                }
                let player = try AVAudioPlayer(contentsOf: url); player.prepareToPlay(); players[key] = player
                #if DEBUG
                loadedResourcePaths[key] = url.path
                #endif
            } catch { self.error = "候選音效未載入：\(key)" }
        }
    }
    @discardableResult func schedule(_ key: String, after delay: Double, volume: Double) -> Bool {
        let base = Self.finiteGain(volume)
        let gain = base * (Self.isVoice(key) ? voiceGain : effectsGain)
        guard let player = players[key], gain > 0 else { return false }
        player.stop(); player.currentTime = 0; player.volume = Float(min(1,gain))
        let success = player.play(atTime: player.deviceCurrentTime + max(0,delay))
        if success { scheduledGains[key] = base } else { scheduledGains.removeValue(forKey:key) }
        if !success { error = "候選音效播放失敗：\(key)" }
        return success
    }
    func duration(_ key:String) -> Double { players[key]?.duration ?? 0 }
    #if DEBUG
    func volume(_ key:String) -> Double { Double(players[key]?.volume ?? 0) }
    func isPlaying(_ key:String) -> Bool { players[key]?.isPlaying ?? false }
    #endif
    /// Keep per-cue material balance. Changing a bus never starts or revives a player.
    func setMix(effects:Double,voice:Double) {
        effectsGain = Self.finiteGain(effects); voiceGain = Self.finiteGain(voice)
        for (key,base) in scheduledGains {
            guard let player = players[key] else { continue }
            let gain = base * (Self.isVoice(key) ? voiceGain : effectsGain)
            if gain == 0 { player.stop(); scheduledGains.removeValue(forKey:key) }
            player.volume = Float(min(1,gain))
        }
    }
    func effectsVolume(_ volume:Double, keys:Set<String>? = nil) {
        for (key,player) in players where !key.contains("voice") && !key.hasPrefix("mage-cast-") && (keys == nil || keys!.contains(key)) {
            player.volume = Float(min(1,max(0,volume)))
        }
    }
    func cancel(keepingVoice: Bool = false) {
        for (key,player) in players where !(keepingVoice && Self.isVoice(key)) {
            player.stop(); scheduledGains.removeValue(forKey:key)
        }
    }
    var playing: Int { players.values.filter(\.isPlaying).count }
    /// Called only after a previous visual unlock, so these voices have already started.
    var remainingVoiceDuration: Double {
        players.filter { Self.isVoice($0.key) && $0.value.isPlaying }
            .map { max(0,$0.value.duration-$0.value.currentTime) }.max() ?? 0
    }
    var playingVoices: Int { players.filter { ($0.key.contains("voice") || $0.key.hasPrefix("mage-cast-")) && $0.value.isPlaying }.count }
}

#if DEBUG
@MainActor @Observable final class PresentationLabStore {
    var variant: MagePresentationVariant = .arcaneHand
    var size = 7
    var caster: Player = .one
    var capture = false
    var dense = false
    var reduced = false
    var bodyOnly = false
    var airLayer = true
    var weightySound = true
    var usesPhoneAssets: Bool { variant == .phoneOriginal || variant == .phoneRefined || variant == .arcaneHand }
    var voice = false
    var castVoice = true
    var castTake = "B"
    var muted = false
    var voiceVolume = 0.85
    var sfxVolume = 0.65
    var reviewWidth: CGFloat?
    private(set) var session: GameSession
    private(set) var plan: MagePresentationPlan?
    private(set) var started = 0.0
    private(set) var animating = false
    private(set) var previewing = false
    private(set) var message = "同一棋形，比較兩種演出。"
    private(set) var generation = 0
    private(set) var cuesFired = 0
    private(set) var voiceScheduled = 0
    private(set) var assetError: String?
    let original: UIImage?
    let plate: UIImage?
    let phoneAssets: P02CozyAssets?
    let handPoses: [UIImage]
    let audio = CombatAudio(defaults: UserDefaults(suiteName: "TacticalGo.presentationLab")!)
    @ObservationIgnored private let samples = PresentationSamples()
    @ObservationIgnored private var playbackTask: Task<Void,Never>?
    @ObservationIgnored private var voiceUsed = false
    @ObservationIgnored private var active = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored nonisolated(unsafe) private var interruptionObserver: (any NSObjectProtocol)?
    init() {
        session = GameSession(try! Anim01Fixture.state(capture: false))
        original = try? PresentationMageBodyAssets.loadOriginal()
        let assets = try? PresentationMageBodyAssets.load(); plate = assets?.cleanPlate
        phoneAssets = try? P02CozyAssets.load()
        handPoses = P04HandAssets.load()
        if handPoses.count != 3 { assetError = "魔法手姿勢素材未載入，停止比較。" }
        if original == nil || plate == nil { assetError = "法師素材未載入，停止比較。" }
        if phoneAssets == nil { assetError = "手機 1023 基準素材未載入，停止比較。" }
        if let error = samples.error { assetError = error }
        audio.muted = false; audio.sfxVolume = sfxVolume; audio.musicVolume = 0
        audio.onInterruption = { [weak self] in self?.cancel() }
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self, let raw, let type = AVAudioSession.InterruptionType(rawValue:raw) else { return }
                self.interrupted = type == .began || !AVAudioSession.InterruptionOptions(rawValue:options).contains(.shouldResume)
                if type == .began { self.cancel() }
            }
        }
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--presentation-A") { variant = .phoneOriginal }
        if args.contains("--presentation-D") { variant = .arcaneHand }
        if args.contains("--presentation-C") { variant = .phoneRefined }
        if args.contains("--presentation-body-only") { bodyOnly = true }
        if args.contains("--presentation-M3") { variant = .original }
        if args.contains("--presentation-rejected") { variant = .rhythmic }
        if args.contains("--presentation-9") { size = 9 }
        if args.contains("--presentation-white") { caster = .two }
        capture = args.contains("--presentation-capture")
        dense = args.contains("--presentation-dense")
        if args.contains("--presentation-board-390") { reviewWidth = 390 }
        if args.contains("--presentation-board-320") { reviewWidth = 320 }
    }
    deinit {
        playbackTask?.cancel()
        if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
    }
    func scene(active: Bool) {
        if active && !self.active { interrupted = false }
        self.active = active
        if !active { cancel() }
        audio.setMatchActive(active); audio.setSceneActive(active); audio.updateState(session.state)
    }
    func cancel() {
        generation += 1; playbackTask?.cancel(); playbackTask = nil
        samples.cancel(); audio.cancelEffects(); animating = false; previewing = false
    }
    func reset() {
        cancel(); plan = nil; voiceUsed = false; cuesFired = 0; voiceScheduled = 0
        do {
            let state: GameState
            if dense {
                var rows = (try Anim01Fixture.state(size: size, caster: caster, pushedOwner: caster, capture: false)).board.diagram.split(separator: "\n").map { Array($0) }
                // All four orthogonal hero neighbors packed; empty liberties
                // remain outside the friendly group. Legal stress fixture only.
                for p in [Point(2,3),Point(3,2),Point(3,4),Point(5,3),Point(5,2),Point(4,4)] { rows[p.y][p.x] = caster == .one ? "x" : "o" }
                state = try GameSetup.fromDiagram(config: .board(size: size), diagram: rows.map { String($0) }.joined(separator: "\n"),
                    classOne: caster == .one ? .mage : .warrior, classTwo: caster == .two ? .mage : .warrior,
                    current: caster, manaOne: 4, manaTwo: 4, ap: 2)
            } else { state = try Anim01Fixture.state(size: size, caster: caster, pushedOwner: caster, capture: capture) }
            session = GameSession(state); audio.resetBattle(); audio.updateState(state)
            message = "準備施法 · 2 AP / 4 Mana"
        } catch { message = "測試局面載入失敗。" }
    }
    func preview() { cancel(); previewing = true; message = "預覽落點；確認前不演出、不消耗資源。" }
    func undo() {
        cancel(); plan = nil
        if session.undo() { audio.resetBattle(); audio.updateState(session.state); message = "已復原；視聽排程已取消。" }
    }
    private func hardwareCue(_ key: String) -> Bool {
        variant == .arcaneHand || key.hasPrefix("p-") || key.hasPrefix("p3-") || key.hasPrefix("p4-")
    }
    func play(systemReduced: Bool) {
        guard active, !interrupted, assetError == nil else { return }
        cancel()
        // Replay uses exactly the same before-state, not a second Domain move.
        if plan != nil {
            _ = session.undo(); plan = nil
            audio.resetBattle(); audio.updateState(session.state)
        }
        let before = session.state
        let outcome = session.apply(Anim01Fixture.action)
        guard let new = MagePresentationPlan.make(before: before, action: Anim01Fixture.action, outcome: outcome,
                                                  current: session.state, variant: variant, arcaneAudio: weightySound ? .weighty : .soft) else {
            message = "技能不合法，沒有播放成功演出。"; return
        }
        plan = new; started = ProcessInfo.processInfo.systemUptime; animating = true; cuesFired = 0; voiceScheduled = 0
        let castKey = "mage-cast-" + castTake
        let speaking = variant == .arcaneHand && castVoice && !muted && voiceVolume > 0
        let voiceEnd = speaking ? 0.08 + samples.duration(castKey) : 0
        let playbackEnd = max(new.clip.duration, voiceEnd + (speaking ? 0.12 : 0))
        if ProcessInfo.processInfo.arguments.contains("--presentation-autoplay") {
            print("PRESENT_CLOCK \(variant.rawValue) wall=\(Date().timeIntervalSince1970) uptime=\(started)")
            fflush(nil)
        }
        audio.sfxVolume = sfxVolume; audio.muted = muted
        audio.duckSkill(duration: !usesPhoneAssets && voice && !voiceUsed ? 1.5 : playbackEnd)
        if !muted {
            for cue in new.sounds where hardwareCue(cue.key) {
                if cue.key == "p3-air" && !airLayer { continue }
                samples.schedule(cue.key, after: started + cue.start - ProcessInfo.processInfo.systemUptime, volume: sfxVolume * (speaking && cue.start < voiceEnd ? 0.42 : 1))
            }
            if speaking && samples.schedule(castKey, after: started + 0.08 - ProcessInfo.processInfo.systemUptime, volume: voiceVolume) {
                voiceScheduled = 1
            }
            if !usesPhoneAssets && voice && !voiceUsed {
                samples.schedule("mage-voice-english", after: started + 0.10 - ProcessInfo.processInfo.systemUptime, volume: voiceVolume); voiceUsed = true
            }
        }
        message = "施法成功 · \(session.state.apRemaining) AP / \(session.state.mana(of: caster)) Mana"
        let token = generation
        playbackTask = Task { [weak self] in
            for cue in new.sounds {
                guard let self else { return }
                let delay = max(0, self.started + cue.start - ProcessInfo.processInfo.systemUptime)
                do { try await Task.sleep(for: .seconds(delay)) } catch { return }
                guard !Task.isCancelled, self.generation == token, self.active else { return }
                if !self.muted && !self.hardwareCue(cue.key) { self.audio.play(cue.key) }
                self.cuesFired += 1
            }
            guard let self else { return }
            do { try await Task.sleep(for: .seconds(max(0,self.started + new.clip.duration - ProcessInfo.processInfo.systemUptime))) } catch { return }
            guard !Task.isCancelled, self.generation == token else { return }
            self.animating = false; self.audio.updateState(self.session.state)
            // Speech retains its natural duration. Recover any remaining SFX
            // tail only after it finishes; cancellation owns this task too.
            if speaking {
                do { try await Task.sleep(for:.seconds(max(0,self.started + voiceEnd - ProcessInfo.processInfo.systemUptime))) } catch { return }
                for step in 1...4 {
                    guard !Task.isCancelled, self.generation == token, self.active else { return }
                    self.samples.effectsVolume(self.sfxVolume * (0.42 + 0.58 * Double(step)/4))
                    do { try await Task.sleep(for:.seconds(0.03)) } catch { return }
                }
            }
        }
    }
    var audit: String { "\(session.state.board.diagram)|ap=\(session.state.apRemaining)|mana=\(session.state.mana(of: caster))|active=\(animating)|cues=\(cuesFired)|players=\(samples.playing + audio.activeEffectCount)|voice=\(voiceScheduled)|take=\(castTake)|generation=\(generation)" }
    /// Native audit interrupts before release; XCTest taps are too slow to
    /// reliably interrupt a 700ms performance at a specified phase.
    func verifyEarlyCancellation() async {
        // The view task can start while its scene is still becoming active.
        // An audit must wait for the same availability guard as a real tap.
        for _ in 0..<200 {
            if active { break }
            do { try await Task.sleep(for: .seconds(0.01)) } catch { return }
        }
        guard active else { message = "取消檢查未啟動：場景尚未 active。"; return }
        // Run after the initial view/image layout, as a real user tap would.
        // Keep the pre-release deadline unchanged; do not hide late cancellation.
        do { try await Task.sleep(for: .seconds(0.5)) } catch { return }
        reset(); voice = true; play(systemReduced: false)
        let submitted = plan != nil && animating
        let setupTime = ProcessInfo.processInfo.systemUptime - started
        let committed = session.state
        do {
            try await Task.sleep(for: .seconds(0.08))
            let cancelTime = ProcessInfo.processInfo.systemUptime - started
            let early = cancelTime < 0.22
            cancel(); let fired = cuesFired
            try await Task.sleep(for: .seconds(max(1.6,samples.duration("mage-cast-" + castTake) + 0.3)))
            let noLateWork = fired == cuesFired && samples.playing == 0 && audio.activeEffectCount == 0 && !animating
            let stateHeld = session.state == committed
            undo()
            let restored = session.state.apRemaining == 2 && session.state.mana(of: caster) == 4
            reset(); play(systemReduced: false)
            NotificationCenter.default.post(name:AVAudioSession.interruptionNotification,object:nil,
                userInfo:[AVAudioSessionInterruptionTypeKey:AVAudioSession.InterruptionType.began.rawValue])
            try await Task.sleep(for: .seconds(0.08))
            let interruptedState = session.state
            play(systemReduced: false) // Must not submit or schedule during interruption.
            try await Task.sleep(for: .seconds(max(1.6,samples.duration("mage-cast-" + castTake) + 0.3)))
            let interruptionHeld = session.state == interruptedState && interrupted && !animating && samples.playing == 0 && audio.activeEffectCount == 0
            NotificationCenter.default.post(name:AVAudioSession.interruptionNotification,object:nil,
                userInfo:[AVAudioSessionInterruptionTypeKey:AVAudioSession.InterruptionType.ended.rawValue,
                          AVAudioSessionInterruptionOptionKey:AVAudioSession.InterruptionOptions.shouldResume.rawValue])
            try await Task.sleep(for: .seconds(0.05))
            undo()
            voice = false
            let passed = submitted && early && noLateWork && stateHeld && restored && interruptionHeld
            message = passed ? "中途取消檢查通過：無延遲聲音，正式結果與復原正常。" : "取消檢查失敗：submitted=\(submitted) early=\(early) time=\(cancelTime) setup=\(setupTime) late=\(noLateWork) state=\(stateHeld) undo=\(restored) interruption=\(interruptionHeld)"
            print("PRESENT_LIFECYCLE \(message) setup=\(setupTime) cancel=\(cancelTime) submitted=\(submitted) early=\(early) noLate=\(noLateWork) state=\(stateHeld) undo=\(restored) interruption=\(interruptionHeld)")
            fflush(nil)
        } catch { cancel(); message = "取消檢查 Task 被中斷。" }
    }
}

struct PresentationLabView: View {
    @State private var store = PresentationLabStore()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack { VStack(alignment: .leading) {
                    Text("魔法之手 · 聲畫比較").font(.title2.bold())
                    Text("A：手機 1.0（1023）　D：魔法手演出候選").font(.caption).foregroundStyle(.secondary)
                }; Spacer(); Image(systemName: "wand.and.stars").foregroundStyle(.purple) }
                HStack {
                    Button("A 手機原版") { store.variant = .phoneOriginal; store.reset() }.accessibilityIdentifier("present-A")
                        .tint(store.variant == .phoneOriginal ? .purple : .gray)
                    Button("D 魔法手") { store.variant = .arcaneHand; store.reset() }.accessibilityIdentifier("present-D")
                        .tint(store.variant == .arcaneHand ? .purple : .gray)
                    Button(store.size == 7 ? "7×7" : "9×9") { store.size = store.size == 7 ? 9 : 7; store.reset() }.accessibilityIdentifier("present-size")
                    Button(store.caster == .one ? "黑方" : "白方") { store.caster = store.caster.opponent; store.reset() }.accessibilityIdentifier("present-team")
                }.buttonStyle(.bordered)
                TimelineView(.animation(minimumInterval: 1/60, paused: !store.animating)) { _ in
                    let reduced = store.reduced || systemReduced
                    let time = store.plan?.clip.displayTime(elapsed: ProcessInfo.processInfo.systemUptime-store.started,
                        animating: store.animating, reducedMotion: reduced) ?? 0
                    Group {
                        if store.usesPhoneAssets, let assets = store.phoneAssets {
                            P02ReferenceBoard(store:store,assets:assets,time:time,reduced:reduced)
                        } else { PresentationBoard(store: store, time: time, reduced: reduced) }
                    }.aspectRatio(store.usesPhoneAssets ? 8/9.0 : 1,contentMode: .fit)
                }.frame(width:store.reviewWidth).accessibilityIdentifier("presentation-board")
                Text(store.assetError ?? store.message).font(.callout).accessibilityIdentifier("present-status")
                HStack {
                    Button("預覽") { store.preview() }.accessibilityIdentifier("present-preview")
                    Button("取消") { store.cancel() }.accessibilityIdentifier("present-cancel")
                    Button("施放／重播") { store.play(systemReduced: systemReduced) }.accessibilityIdentifier("present-play").buttonStyle(.borderedProminent)
                    Button("復原") { store.undo() }.accessibilityIdentifier("present-undo")
                }.buttonStyle(.bordered)
                HStack {
                    Button(store.capture ? "提子局面 ✓" : "提子局面") { store.capture.toggle(); store.dense = false; store.reset() }.accessibilityIdentifier("present-capture")
                    Button(store.dense ? "密集棋形 ✓" : "密集棋形") { store.dense.toggle(); store.capture = false; store.reset() }.accessibilityIdentifier("present-dense")
                    Button("重設") { store.reset() }.accessibilityIdentifier("present-reset")
                }.buttonStyle(.bordered)
                Toggle("只看角色動作", isOn: $store.bodyOnly).accessibilityIdentifier("present-body-only")
                Toggle("減少動態", isOn: $store.reduced).accessibilityIdentifier("present-reduced").onChange(of: store.reduced) { store.cancel() }
                Toggle("靜音", isOn: $store.muted).accessibilityIdentifier("present-muted").onChange(of: store.muted) { store.cancel(); store.audio.muted = store.muted }
                if store.variant == .phoneRefined {
                    Toggle("推動氣流音層", isOn: $store.airLayer).accessibilityIdentifier("present-air").onChange(of: store.airLayer) { store.cancel() }
                }
                if store.variant == .arcaneHand {
                    Toggle("英文施法語音：Move aside!",isOn:$store.castVoice).accessibilityIdentifier("present-cast-voice").onChange(of:store.castVoice) { store.cancel() }
                    Picker("配音候選",selection:$store.castTake) {
                        Text("A · 自信指令").tag("A")
                        Text("B · 俏皮施法").tag("B")
                    }.pickerStyle(.segmented).accessibilityIdentifier("present-cast-take").onChange(of:store.castTake) { store.cancel() }
                    HStack { Text("語音");Slider(value:$store.voiceVolume,in:0...1).onChange(of:store.voiceVolume) { store.cancel() } }
                    Toggle("新版音效：力量與魔法殘響",isOn:$store.weightySound).accessibilityIdentifier("present-weighty-audio").onChange(of:store.weightySound) { store.cancel() }
                }
                HStack { Text("音效"); Slider(value: $store.sfxVolume, in: 0...1).onChange(of: store.sfxVolume) { store.cancel(); store.audio.sfxVolume = store.sfxVolume } }
                if !store.usesPhoneAssets {
                    Toggle("退回版英文語音：Off you go!", isOn: $store.voice).accessibilityIdentifier("present-voice").onChange(of: store.voice) { store.cancel() }
                }
                Text("同一棋形：A 保留手機原版。D 保留已接受的魔法手動畫，加入英文 Move aside! 配音；語音時降低音效。上方 A／B 是兩個配音候選，每次重播可比較；聽感待驗收。").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 25) {
                    ForEach([32,48,64],id: \.self) { width in
                        VStack { if let original = store.original, let plate = store.plate {
                            PresentationMageBodyView(original: original,plate: plate,pose: store.reduced || systemReduced ? .rest : MageBodyPose.cast(at:store.variant.timing.release,timing:store.variant.timing,revision:store.variant == .phoneRefined || store.variant == .arcaneHand ? .r2 : store.variant == .phoneOriginal ? .r1 : .m3),width:CGFloat(width))
                        }; Text("\(width) pt").font(.caption2) }
                    }
                }.frame(height: 85).accessibilityIdentifier("present-small-review")
                if store.variant == .arcaneHand, store.handPoses.count == 3 {
                    HStack(spacing: 20) {
                        ForEach(0..<3,id: \.self) { index in
                            VStack { P04HandSprite(poses:store.handPoses,index:index,width:64)
                                Text(["伸出","抓穩","推開"][index]).font(.caption2) }
                        }
                    }.accessibilityIdentifier("present-hand-review")
                }
                Text(store.audit).font(.system(size:1)).foregroundStyle(.clear).frame(height:1).accessibilityIdentifier("present-audit")
            }.padding(16).frame(maxWidth: 600)
        }.background(Color(red:0.96,green:0.94,blue:0.89))
            .preferredColorScheme(.light)
            .onAppear { store.scene(active: scenePhase == .active); store.reset() }
            .onDisappear { store.scene(active: false) }
            .onChange(of: scenePhase) { store.scene(active: scenePhase == .active) }
            .onChange(of: systemReduced) { store.cancel() }
            .task {
                if ProcessInfo.processInfo.arguments.contains("--presentation-lifecycle-audit") {
                    await store.verifyEarlyCancellation(); return
                }
                guard ProcessInfo.processInfo.arguments.contains("--presentation-autoplay") else { return }
                do {
                    try await Task.sleep(for: .seconds(2))
                    for _ in 0..<4 {
                        store.play(systemReduced: systemReduced)
                        try await Task.sleep(for: .seconds(2.5))
                    }
                } catch { store.cancel() }
            }
    }
}

/// Mage-only specialization of the frozen1023 commercial CozyBoard.
/// Other actions and the shipping app remain outside this lab.
private struct P02ReferenceBoard: View {
    let store: PresentationLabStore
    let assets: P02CozyAssets
    let time: Double
    let reduced: Bool
    var body: some View {
        GeometryReader { geo in
            let fit = Anim01Geometry(width:geo.size.width,height:geo.size.height,boardSize:store.size)
            let size = CGSize(width:fit.width,height:fit.height)
            let presentation = BoardPresentation(state:store.session.state,selected:[],legal:[],preview:nil)
            let plan = store.plan
            let showing = plan != nil && time < plan!.clip.duration && !reduced
            let board = showing ? plan!.before.board : store.session.state.board
            let pitch = CGFloat(fit.pitch)
            ZStack {
                Image(uiImage:assets.shadow).resizable().frame(width:size.width,height:size.height)
                Image(uiImage:assets.board).resizable().frame(width:size.width,height:size.height)
                ArenaGrid(boardSize:store.size).stroke(Color.ink.opacity(0.30),lineWidth:1)
                if let plan, !store.bodyOnly {
                    Group {
                        if store.variant == .arcaneHand, store.handPoses.count == 3 {
                            P04MageEffects(receipt:plan,poses:store.handPoses,elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:false,center:{presentation.center($0,size)})
                        } else if store.variant == .phoneRefined {
                            P03MageEffects(receipt:plan,elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:false,center:{presentation.center($0,size)})
                        } else {
                            P02SkillVFXLayer(receipt:plan,id:store.generation,plan:P02SkillVFX(plan),elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:false,center:{presentation.center($0,size)})
                        }
                    }.zIndex(3)
                }
                ForEach(board.points,id:\.self) { p in
                    if let piece = board[p], !(showing && p == plan?.clip.from) {
                        let captured = plan?.clip.captures.contains { $0.at == p } ?? false
                        let opacity = showing && captured && time >= plan!.clip.timing.captureStart ? max(0,1-(time-plan!.clip.timing.captureStart)/0.18) : 1
                        P02CozyToken(piece:piece,assets:assets,pitch:pitch,magePose:p == plan?.clip.hero ? plan!.pose(at:time,reducedMotion:reduced) : .rest,commercialStyle:true,heroClass:store.session.state.heroClass(of:piece.owner))
                            .opacity(opacity).position(presentation.center(p,size)).zIndex(Double(p.y)*10+10)
                    }
                }
                if let plan, showing {
                    let a=presentation.center(plan.clip.from,size),b=presentation.center(plan.clip.to,size),t=plan.clip.progress(at:time)
                    let timing=plan.clip.timing
                    let squash = store.variant == .arcaneHand ? ArcaneHandFrame.sample(at:time,reduced:reduced).pawnSquash : time >= timing.arrival && time < timing.captureStart ? 0.94+0.06*(time-timing.arrival)/(timing.captureStart-timing.arrival) : 1
                    P02CozyToken(piece:plan.clip.piece,assets:assets,pitch:pitch,squash:squash,commercialStyle:true,heroClass:.mage)
                        .position(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t).zIndex(Double(plan.clip.from.y)*10+Double(plan.clip.to.y-plan.clip.from.y)*10*t+11)
                }
                if let plan, !store.bodyOnly {
                    Group {
                        if store.variant == .arcaneHand, store.handPoses.count == 3 {
                            P04MageEffects(receipt:plan,poses:store.handPoses,elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:true,center:{presentation.center($0,size)})
                        } else if store.variant == .phoneRefined {
                            P03MageEffects(receipt:plan,elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:true,center:{presentation.center($0,size)})
                        } else {
                            P02SkillVFXLayer(receipt:plan,id:store.generation,plan:P02SkillVFX(plan),elapsed:time,pitch:pitch,size:size,reduced:reduced,foreground:true,center:{presentation.center($0,size)})
                        }
                    }.zIndex(190)
                }
                ForEach(store.session.state.board.points,id:\.self) { p in
                    if presentation.danger.contains(p) {
                        Circle().stroke(Color(red:0.81,green:0.40,blue:0.35),style:StrokeStyle(lineWidth:2,dash:[3,3])).frame(width:pitch*0.80).position(presentation.center(p,size)).zIndex(210)
                    }
                }
                if store.previewing {
                    Circle().stroke(P02Cozy.deepMage,lineWidth:2).frame(width:pitch*0.78).position(presentation.center(Point(4,2),size)).zIndex(210)
                }
            }.frame(width:size.width,height:size.height).offset(x:fit.x,y:fit.y)
                .accessibilityLabel("手機 1023 基準 · \(store.size) 乘 \(store.size) 棋盤")
        }
    }
}

private struct PresentationBoard: View {
    let store: PresentationLabStore
    let time: Double
    let reduced: Bool
    var body: some View {
        GeometryReader { geo in
            let plan = store.plan
            let board = plan?.board(at: time,reducedMotion: reduced) ?? store.session.state.board
            let width = geo.size.width
            let pitch = width / CGFloat(board.size+1)
            let art = min(64,pitch*0.88)
            let radius = pitch*0.23
            let moving = plan != nil && !reduced && time < plan!.clip.timing.arrival
            ZStack {
                RoundedRectangle(cornerRadius: 20).fill(Color(red:0.77,green:0.57,blue:0.34).gradient)
                    .overlay(RoundedRectangle(cornerRadius:20).stroke(Color.brown.opacity(0.7),lineWidth:3))
                Path { path in
                    for n in 0..<board.size {
                        let a = point(Point(n,0),pitch), b = point(Point(n,board.size-1),pitch)
                        let c = point(Point(0,n),pitch), d = point(Point(board.size-1,n),pitch)
                        path.move(to:a); path.addLine(to:b); path.move(to:c); path.addLine(to:d)
                    }
                }.stroke(Color(red:0.22,green:0.12,blue:0.06).opacity(0.65),lineWidth:1)
                if store.previewing {
                    Circle().stroke(Color.cyan,lineWidth:3).frame(width:pitch*0.7,height:pitch*0.7).position(point(Point(4,2),pitch))
                }
                ForEach(board.points,id: \.self) { p in
                    if let piece = board[p], !(moving && p == plan?.clip.from) {
                        token(piece, at:p, board:board, pitch:pitch, art:art, radius:radius, pose:plan?.pose(at:time,reducedMotion:reduced) ?? .rest)
                    }
                }
                if let plan, moving {
                    let from = point(plan.clip.from,pitch), to = point(plan.clip.to,pitch), t = plan.clip.progress(at:time)
                    PieceToken(piece:plan.clip.piece,heroClass:.mage,radius:radius,artSize:art)
                        .position(x:from.x+(to.x-from.x)*t,y:from.y+(to.y-from.y)*t)
                }
                if let plan, !reduced, !store.bodyOnly, time >= plan.clip.timing.release, time < plan.clip.timing.arrival {
                    let hero = point(plan.clip.hero,pitch)
                    let tip = PresentationMageBodyView.tipOffset(pose:plan.pose(at:time),width:art)
                    let start = CGPoint(x:hero.x+tip.x,y:hero.y+tip.y)
                    let from = point(plan.clip.from,pitch), to = point(plan.clip.to,pitch), t = plan.clip.progress(at:time)
                    let target = CGPoint(x:from.x+(to.x-from.x)*t,y:from.y+(to.y-from.y)*t)
                    Path { p in p.move(to:start); p.addQuadCurve(to:target,control:CGPoint(x:target.x,y:start.y-pitch*0.5)) }
                        .stroke(Color.cyan.opacity(0.65),style:StrokeStyle(lineWidth:2,lineCap:.round,dash:[3,4])).allowsHitTesting(false)
                }
                if let plan, !store.bodyOnly, time >= plan.clip.timing.arrival, time < plan.clip.timing.arrival+0.14 {
                    Circle().stroke(Color.cyan.opacity(0.8),lineWidth:2).frame(width:pitch*0.65,height:pitch*0.65)
                        .position(point(plan.clip.to,pitch)).allowsHitTesting(false)
                }
                if let plan, !reduced, time >= plan.clip.timing.captureStart, time < plan.clip.timing.captureEnd {
                    ForEach(plan.clip.captures,id:\.at) { captured in
                        PieceToken(piece:captured.piece,heroClass:plan.before.heroClass(of:captured.piece.owner),radius:radius,artSize:art)
                            .opacity(1-(time-plan.clip.timing.captureStart)/0.18).position(point(captured.at,pitch)).allowsHitTesting(false)
                    }
                }
            }.accessibilityElement(children:.ignore).accessibilityLabel("\(board.size) 乘 \(board.size) 棋盤")
        }
    }
    private func point(_ p:Point,_ pitch:CGFloat) -> CGPoint { CGPoint(x:CGFloat(p.x+1)*pitch,y:CGFloat(p.y+1)*pitch) }
    @ViewBuilder private func token(_ piece:Piece,at p:Point,board:Board,pitch:CGFloat,art:CGFloat,radius:CGFloat,pose:MageBodyPose) -> some View {
        ZStack {
            if piece.kind == .hero, piece.owner == store.caster, let original = store.original, let plate = store.plate {
                Ellipse().fill(piece.owner == .one ? Color.blueTeam : Color.redTeam).frame(width:pitch*0.65,height:pitch*0.32)
                    .overlay(Ellipse().stroke(.white,lineWidth:1))
                PresentationMageBodyView(original:original,plate:plate,pose:pose,width:art).offset(y:-art*0.375)
                Image(systemName:piece.owner == .one ? "circle.fill" : "triangle.fill").font(.system(size:5)).foregroundStyle(.white).offset(y:pitch*0.08)
            } else { PieceToken(piece:piece,heroClass:store.session.state.heroClass(of:piece.owner),radius:radius,artSize:art) }
            if piece.kind == .commander, board.liberties(at:p).count <= 1 {
                Circle().stroke(Color.red,lineWidth:2).frame(width:pitch*0.72,height:pitch*0.72)
            }
        }.position(point(p,pitch))
    }
}
#endif
#endif
