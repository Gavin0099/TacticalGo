#if DEBUG
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Art-only gallery, separate from receipted match playback.
struct HeroPoseReview: View {
    @State private var assets = try? CozyAssets.load()
    @State private var hero: HeroClass = .warrior
    @State private var started: Date?
    @State private var summon = false
    var body: some View {
        ScrollView {
            if let assets, let original = assets.heroes[hero], let plate = assets.heroPlates[hero] {
                VStack(spacing:16) {
                    Text("戰士／盜賊本體 · 無語音／無大型特效").font(.headline)
                    Text("原畫分層檢查，不結算棋局").font(.caption)
                    Picker("角色",selection:$hero) { Text("戰士").tag(HeroClass.warrior);Text("盜賊").tag(HeroClass.rogue) }.pickerStyle(.segmented).accessibilityIdentifier("heroPoseClass")
                    TimelineView(.animation(paused:started == nil)) { c in
                        let t = started.map{max(0,c.date.timeIntervalSince($0))} ?? 0
                        HeroBodyView(original:original,plate:plate,heroClass:hero,pose:summon ? .summon(hero,at:t) : .skill(hero,at:t),width:260)
                            .frame(width:280,height:290).background(Cozy.card,in:RoundedRectangle(cornerRadius:16))
                    }
                    HStack { Button("登場") {summon = true;started = Date()}.accessibilityIdentifier("heroPoseSummon");Button("技能") {summon = false;started = Date()}.accessibilityIdentifier("heroPoseCast") }.buttonStyle(.borderedProminent)
                    HeroSizeSheet(assets:assets,hero:hero,pitch:48)
                }.padding().foregroundStyle(Cozy.ink).task { Self.export(assets) }
            } else {Text("素材校驗失敗")}
        }.background(Cozy.card)
    }
    @MainActor static func export(_ assets: CozyAssets) {
        let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!
        let d = docs.appendingPathComponent("hero-body-review")
        try? FileManager.default.createDirectory(at:d,withIntermediateDirectories:true)
        for hero in [HeroClass.warrior,.rogue] {
            for pitch in [32.0,48.0,64.0] {
                let r = ImageRenderer(content:HeroSizeSheet(assets:assets,hero:hero,pitch:pitch).frame(width:390));r.scale = 1
                try? r.uiImage?.pngData()?.write(to:d.appendingPathComponent("\(hero.art)-black-white-\(Int(pitch)).png"))
            }
            guard let original = assets.heroes[hero],let plate = assets.heroPlates[hero] else {continue}
            let timing = HeroBodyTiming.skill(hero)
            for (name,t) in [("rest",0.0),("anticipation",timing.anticipationEnd),("release",timing.release),("settle",timing.arrival)] {
                let r = ImageRenderer(content:HeroBodyView(original:original,plate:plate,heroClass:hero,pose:.skill(hero,at:t),width:512).frame(width:512,height:512));r.scale = 1
                try? r.uiImage?.pngData()?.write(to:d.appendingPathComponent("\(hero.art)-\(name)-512.png"))
            }
        }
    }
}
private struct HeroSizeSheet: View {
    let assets:CozyAssets, hero:HeroClass, pitch:CGFloat
    var body: some View {
        let t = HeroBodyTiming.skill(hero)
        VStack(spacing:6) {
            Text("\(hero.title) · pitch \(Int(pitch)) pt · 1px/pt").font(.caption.bold())
            Text("原姿／蓄勢／出手；圖層樣本不是對局結算").font(.caption2)
            ForEach(Player.allCases,id:\.self) { owner in
                HStack(spacing:8) {
                    Text(owner == .one ? "黑" : "白").font(.caption).frame(width:22)
                    ForEach([0.0,t.anticipationEnd,t.release],id:\.self) { elapsed in
                        CozyToken(piece:Piece(owner,.hero),assets:assets,pitch:pitch,heroPose:.skill(hero,at:elapsed),heroClass:hero).frame(width:104,height:100)
                    }
                }
            }
            Text("薄底座＋實心圓／空心菱形；角色身份與最終辨識待 Owner 驗收").font(.caption2)
        }.padding(8).background(Cozy.card).foregroundStyle(Cozy.ink)
    }
}

/// Exercise the screen's actual GameStore and shared audio instance.
@MainActor enum HeroBodyAudit {
    static func run(store:GameStore,assets:CozyAssets) async -> String {
        var rows:[[String:Any]] = []
        func check(_ key:String,_ value:Bool) {rows.append(["check":key,"pass":value])}
        func wait(_ t:Double) async {try? await Task.sleep(for:.seconds(t))}
        func load(_ hero:HeroClass,_ owner:Player = .one,_ capture:Bool = false,_ reduced:Bool = false) {
            store.leaveMatch();store.computer = nil;store.size = 7;store.presentationReducedMotion = reduced
            store.session = GameSession(try! HeroBodyFixture.state(hero,owner:owner,capture:capture));store.mode = .skill
            store.selected = [];store.pushDirection = nil
            store.audio.voiceEnabled = false;store.audio.musicEnabled = false;store.audio.muted = false;store.audio.sfxVolume = 0.65
            store.setSceneAudioActive(true);store.setMatchAudioActive(true)
        }
        func prepare(_ hero:HeroClass) { if hero == .warrior {store.select(Point(2,3));store.select(Point(4,3))} else {store.select(Point(4,3))} }
        let docs = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!
        let checkpoints = docs.appendingPathComponent("hero-body-checkpoints");try? FileManager.default.createDirectory(at:checkpoints,withIntermediateDirectories:true)
        for hero in [HeroClass.warrior,.rogue] {for owner in Player.allCases {for capture in [false,true] {
            load(hero,owner,capture);let before = store.state;prepare(hero)
            let key = "\(hero.art)-\(owner)-\(capture)"
            check(key+"-preview",store.state == before && store.playback == nil && store.preview?.success == true)
            store.cancelSelection();check(key+"-cancel",store.state == before && store.playback == nil)
            prepare(hero);let audioCount = store.audio.playbackObservations.count;store.confirm()
            guard let receipt = store.playback,let performance = receipt.heroPerformance else {check(key+"-receipt",false);continue}
            let after = store.state;store.confirm();check(key+"-once",after == store.state && store.playback?.id == receipt.id)
            let t = performance.timing
            check(key+"-shared-timeline",receipt.plan == performance.plan && t.release < t.moveStart && t.moveStart < t.arrival)
            let early = BotBoardFrame.committed(receipt,elapsed:t.moveStart-0.01,pitch:46.56,reducedMotion:false)
            let halfway = BotBoardFrame.committed(receipt,elapsed:(t.moveStart+t.arrival)/2,pitch:46.56,reducedMotion:false)
            if hero == .warrior {
                check(key+"-two-drops-after-release",early.sprites.filter{$0.piece.kind == .soldier}.isEmpty && halfway.sprites.filter{$0.piece.kind == .soldier}.count == 2)
            } else {
                let moving = halfway.sprites.filter{$0.from != $0.to}
                check(key+"-two-opposite-tracked-paths",moving.count == 2 && moving.allSatisfy{abs($0.progress-0.5)<0.001} && moving.contains{$0.piece.kind == .hero && $0.from == Point(3,3) && $0.to == Point(4,3)})
                check(key+"-separate-crossing-lanes",moving.contains{$0.piece.kind == .hero && $0.lift < 0} && moving.contains{$0.piece.kind == .soldier && $0.lift > 0})
            }
            if owner == .one && !capture {
                for (name,time) in [("rest",0.0),("anticipation",t.anticipationEnd),("release",t.release),("travel",(t.moveStart+t.arrival)/2),("settle",t.arrival),("recovered",receipt.visualDuration)] {
                    let content = CozyBoard(presentation:BoardPresentation(state:after,selected:[],legal:[],preview:nil),assets:assets,playback:receipt,botPlayback:nil,botStartedAt:nil,animating:true,reducedMotion:false,checkpoint:time,effectsEnabled:false,select:{_ in}).frame(width:390,height:438.75)
                    let r = ImageRenderer(content:content);r.scale = 1;try? r.uiImage?.pngData()?.write(to:checkpoints.appendingPathComponent("\(hero.art)-\(name).png"))
                }
            }
            await wait(receipt.visualDuration+0.25)
            check(key+"-final-core-no-lock",store.state == GameEngine.apply(before,HeroBodyFixture.action(hero)).state && !store.isPresenting)
            check(key+"-resources",store.state.apRemaining == 1 && store.state.mana(of:owner) == 2)
            let played = store.audio.playbackObservations.dropFirst(audioCount).compactMap{$0["key"]}
            check(key+"-shared-sfx",played == (capture ? [hero.art,"place","capture","victory"] : [hero.art,"place"]))
            check(key+"-voice-off",store.audio.activeVoiceCount == 0 && !store.audio.voiceEnabled)
            store.undo();check(key+"-undo",store.state == before && store.playback == nil && !store.isPresenting)
        }}}
        for hero in [HeroClass.warrior,.rogue] {
            for boundary in ["undo","cancel","background","restart","leave","interruption"] {
                load(hero,.one,true);prepare(hero);let before = store.state;store.confirm();await wait(0.10)
                let count = store.audio.playbackObservations.count
                switch boundary {
                case "undo":store.undo()
                case "cancel":store.cancelSelection()
                case "background":store.setSceneAudioActive(false)
                case "restart":store.newMatch(classOne:hero,classTwo:hero)
                case "leave":store.leaveMatch()
                default:store.audio.onInterruption?()
                }
                await wait(1.2)
                check(hero.art+"-\(boundary)-no-stale",store.playback == nil && !store.isPresenting && store.audio.playbackObservations.count == count && store.audio.activeEffectCount == 0)
                if boundary == "undo" {check(hero.art+"-interrupt-undo-state",store.state == before)}
            }
            load(hero);let invalid = store.state;store.selected = [Point(0,0)];store.confirm()
            check(hero.art+"-illegal-no-charge",store.state == invalid && store.playback == nil && !store.isPresenting)
            load(hero,.two,true,true);let before = store.state;prepare(hero);store.confirm()
            check(hero.art+"-reduced-no-lock-final",!store.isPresenting && store.state == GameEngine.apply(before,HeroBodyFixture.action(hero)).state)
            await wait(1.2);check(hero.art+"-reduced-no-voice",store.audio.activeVoiceCount == 0)
            store.undo();check(hero.art+"-reduced-undo",store.state == before && store.playback == nil)
        }
        let vertical = try! GameSetup.fromDiagram(config:.board(size:7),diagram:".......\n...O...\n...o...\n...H...\n.......\n...X...\n.......",classOne:.rogue,classTwo:.rogue,manaOne:4,manaTwo:4,ap:2)
        let verticalAction = GameAction.castSwap(Point(3,2)),verticalOutcome = GameEngine.apply(vertical,verticalAction)
        check("rogue-vertical-real-core",verticalOutcome.success)
        let verticalReceipt = BoardPlayback(before:vertical,action:verticalAction,outcome:verticalOutcome)
        let vt = verticalReceipt.heroPerformance!.timing
        let vf = BotBoardFrame.committed(verticalReceipt,elapsed:(vt.moveStart+vt.arrival)/2,pitch:46.56,reducedMotion:false)
        check("rogue-vertical-perpendicular-lanes",vf.sprites.contains{$0.piece.kind == .hero && $0.lateral<0 && $0.lift == 0} && vf.sprites.contains{$0.piece.kind == .soldier && $0.lateral>0 && $0.lift == 0})
        HeroPoseReview.export(assets)
        for hero in [HeroClass.warrior,.rogue] { for owner in Player.allCases {
            let before = try! HeroBodyFixture.state(hero,owner:owner,size:9,dense:true),action = HeroBodyFixture.action(hero)
            let outcome = GameEngine.apply(before,action),receipt = BoardPlayback(before:before,action:action,outcome:outcome)
            let t = receipt.heroPerformance!.timing
            for (name,time) in [("before",0.0),("anticipation",t.anticipationEnd),("travel",(t.moveStart+t.arrival)/2),("final",receipt.visualDuration)] {
                let content = CozyBoard(presentation:BoardPresentation(state:outcome.state,selected:[],legal:[],preview:nil),assets:assets,playback:receipt,botPlayback:nil,botStartedAt:nil,animating:true,reducedMotion:false,checkpoint:time,effectsEnabled:false,select:{_ in}).frame(width:312,height:351)
                let r = ImageRenderer(content:content);r.scale = 1;try? r.uiImage?.pngData()?.write(to:checkpoints.appendingPathComponent("dense-\(hero.art)-\(owner)-\(name).png"))
            }
        }}
        let passed = rows.allSatisfy{$0["pass"] as? Bool == true}
        try? JSONSerialization.data(withJSONObject:["status":passed ? "PASS":"FAIL","checks":rows,"voice":"off","effects":"off","boundary":"Native SwiftUI/actual GameStore; physical-device and human acting Gates separate"],options:[.prettyPrinted,.sortedKeys]).write(to:docs.appendingPathComponent("hero-body-audit.json"))
        return passed ? "PASS \(rows.count)/\(rows.count)" : "FAIL"
    }
}
#endif
