#if DEBUG
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Visual inspection only. This screen never pretends to apply a game action.
struct MagePoseReview: View {
    @State private var assets = try? CozyAssets.load()
    @State private var start: Date?
    @State private var summon = false
    @State private var poseTime = 0.0
    @State private var compact = false
    var body: some View {
        ScrollView {
            if let assets, let original = assets.heroes[.mage] {
                VStack(spacing: 18) {
                    Text("法師本體 · 無語音／無光效").font(.headline)
                    Text("原畫分層造型檢查；此頁不結算棋局").font(.caption)
                    HStack {
                        ForEach([0.0,0.18,0.28],id: \.self) { t in
                            VStack {
                                MageBodyView(original: original,plate: assets.mageBody.cleanPlate,pose: MageBodyPose.cast(at:t,timing:MageTempo.full.timing),width:100)
                                Text(t == 0 ? "原姿" : t == 0.18 ? "蓄勢" : "出手").font(.caption)
                            }
                        }
                    }
                    TimelineView(.animation(paused: start == nil)) { context in
                        let timing = (compact ? MageTempo.compact : .full).timing
                        let t = start.map { max(0,context.date.timeIntervalSince($0)) } ?? poseTime
                        let pose = summon ? MageBodyPose.summon(at:t,timing:timing) : MageBodyPose.cast(at:t,timing:timing)
                        MageBodyView(original:original,plate:assets.mageBody.cleanPlate,pose:pose,width:280)
                            .frame(height:280).background(Cozy.card,in:RoundedRectangle(cornerRadius:16))
                    }
                    HStack {
                        Button("登場") { summon = true; start = Date() }.accessibilityIdentifier("magePoseSummon")
                        Button("施法") { summon = false; start = Date() }.accessibilityIdentifier("magePoseCast")
                    }.buttonStyle(.borderedProminent)
                    Toggle("緊湊節奏",isOn:$compact).padding(.horizontal)
                    Text("64 px · 黑白底座與職業標記").font(.caption)
                    HStack {
                        ForEach(Player.allCases,id:\.self) { owner in
                            CozyToken(piece:Piece(owner,.hero),assets:assets,pitch:64,heroClass:.mage).frame(width:80,height:90)
                        }
                    }
                }.padding().foregroundStyle(Cozy.ink)
                    .task { MagePoseReview.export(assets) }
            } else { Text("分層素材校驗失敗") }
        }.background(Cozy.card)
    }
    @MainActor static func export(_ assets: CozyAssets) {
        guard let original = assets.heroes[.mage],let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first else { return }
        let directory = docs.appendingPathComponent("mage-pose-review")
        try? FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        for width in [32,48,64,128,512] {
            for (name,t) in [("rest",0.0),("anticipation",0.18),("release",0.28),("recover",0.75)] {
                let renderer = ImageRenderer(content: MageBodyView(original:original,plate:assets.mageBody.cleanPlate,pose:MageBodyPose.cast(at:t,timing:MageTempo.full.timing),width:CGFloat(width)).frame(width:CGFloat(width),height:CGFloat(width)))
                renderer.scale = 1
                try? renderer.uiImage?.pngData()?.write(to:directory.appendingPathComponent("\(name)-\(width).png"))
            }
        }
    }
}

@MainActor enum MageBodyAudit {
    static func run(store: GameStore, assets: CozyAssets) async -> String {
        var rows: [[String:Any]] = []
        func check(_ name: String,_ pass: Bool) { rows.append(["check":name,"pass":pass]) }
        func wait(_ t: Double) async { try? await Task.sleep(for:.seconds(t)) }
        func load(_ capture: Bool = false,_ owner: Player = .one,_ tempo: MageTempo = .full,_ reduced: Bool = false) {
            store.leaveMatch(); store.computer = nil; store.mageTempo = tempo; store.presentationReducedMotion = reduced
            store.session = GameSession(try! Anim01Fixture.state(caster:owner,pushedOwner:owner,capture:capture))
            store.size = 7; store.mode = .skill; store.selected = []; store.pushDirection = nil
            store.audio.voiceEnabled = false; store.audio.musicEnabled = false; store.audio.muted = false; store.audio.sfxVolume = 0.65
            store.setSceneAudioActive(true); store.setMatchAudioActive(true)
        }
        func prepare() { store.select(Point(4,3)); store.chooseDirection(.up) }
        let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!
        let screens = docs.appendingPathComponent("mage-body-checkpoints")
        try? FileManager.default.createDirectory(at:screens,withIntermediateDirectories:true)
        for tempo in MageTempo.allCases {
            for owner in Player.allCases {
                for captured in [false,true] {
                    load(captured,owner,tempo); let before = store.state
                    prepare(); let prefix = "\(tempo.rawValue)-\(owner)-\(captured)"
                    check(prefix+"-preview-no-state-no-receipt",store.state == before && store.preview?.success == true && store.playback == nil)
                    store.cancelSelection(); check(prefix+"-cancel-preview",store.state == before && store.playback == nil)
                    prepare(); let count = store.audio.playbackObservations.count; store.confirm()
                    let after = store.state, receipt = store.playback!
                    store.confirm(); check(prefix+"-confirm-once",store.state == after && store.playback?.id == receipt.id)
                    check(prefix+"-successful-receipt",receipt.magicHand != nil && receipt.mageTempo == tempo && store.isPresenting)
                    if tempo == .full && owner == .one {
                        for (name,t) in [("anticipation",0.18),("release",0.28),("push",0.42),("land",0.54),("recover",0.75)] {
                            let content = CozyBoard(presentation:BoardPresentation(state:store.state,selected:[],legal:[],preview:nil),assets:assets,playback:receipt,botPlayback:nil,botStartedAt:nil,animating:true,reducedMotion:false,checkpoint:t,effectsEnabled:false,select:{_ in}).frame(width:390,height:438.75)
                            let renderer = ImageRenderer(content:content); renderer.scale = 1
                            try? renderer.uiImage?.pngData()?.write(to:screens.appendingPathComponent("\(captured)-\(name).png"))
                        }
                    }
                    await wait(receipt.visualDuration+0.22)
                    check(prefix+"-final-once-and-unlocked",store.state == after && !store.isPresenting && store.state == GameEngine.apply(before,Anim01Fixture.action).state)
                    check(prefix+"-resources",store.state.mana(of:owner) == 2 && store.state.apRemaining == 1)
                    check(prefix+"-voice-off",store.audio.activeVoiceCount == 0 && !store.audio.voiceEnabled)
                    let cues = store.audio.playbackObservations.dropFirst(count).compactMap { $0["key"] }
                    check(prefix+"-shared-sfx",cues == (captured ? ["mage","place","capture","victory"] : ["mage","place"]))
                    store.undo(); check(prefix+"-undo",store.state == before && store.playback == nil && !store.isPresenting)
                }
            }
        }
        for boundary in ["undo","cancel","background","restart","leave","interruption"] {
            for time in [0.05,0.45,0.75] {
                load(true); prepare(); let before = store.state; store.confirm(); await wait(time)
                let count = store.audio.playbackObservations.count
                switch boundary {
                case "undo": store.undo()
                case "cancel": store.cancelSelection()
                case "background": store.setSceneAudioActive(false)
                case "restart": store.newMatch(classOne:.mage,classTwo:.warrior)
                case "leave": store.leaveMatch()
                default: store.audio.onInterruption?()
                }
                await wait(1.0)
                check("\(boundary)-\(time)-no-stale-work",store.playback == nil && !store.isPresenting && store.audio.playbackObservations.count == count && store.audio.activeEffectCount == 0)
                if boundary == "undo" { check("undo-\(time)-original",store.state == before) }
            }
        }
        load(); let invalid = store.state; store.selected = [Point(3,3)]; store.pushDirection = .up
        store.confirm(); check("illegal-no-presentation-no-cost",store.state == invalid && store.playback == nil && !store.isPresenting)
        load(true,.two,.full,true); prepare(); let before = store.state; let count = store.audio.playbackObservations.count; store.confirm()
        check("reduced-final-no-lock",!store.isPresenting && store.state == GameEngine.apply(before,Anim01Fixture.action).state)
        await wait(1.15)
        check("reduced-keeps-sfx-no-voice",store.audio.playbackObservations.dropFirst(count).compactMap { $0["key"] } == ["mage","place","capture","victory"] && store.audio.activeVoiceCount == 0)
        store.undo(); check("reduced-undo",store.state == before && store.playback == nil)
        MagePoseReview.export(assets)
        let passed = rows.allSatisfy { $0["pass"] as? Bool == true }
        try? JSONSerialization.data(withJSONObject:["status":passed ? "PASS":"FAIL","checks":rows,"voice":"disabled","renderer":"actual SwiftUI CozyBoard; ImageRenderer receipt checkpoints","deviceBoundary":"Simulator checks do not prove physical-device or human acting acceptance"],options:[.prettyPrinted,.sortedKeys]).write(to:docs.appendingPathComponent("mage-body-audit.json"),options:.atomic)
        return passed ? "PASS \(rows.count)/\(rows.count)" : "FAIL"
    }
}
#endif
