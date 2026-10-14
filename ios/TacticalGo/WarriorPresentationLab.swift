#if DEBUG || TACTICALGO_V11
import SwiftUI
import AVFoundation
import Observation
import CryptoKit
import TacticalGoCore
import TacticalGoMotion
import TacticalGoVisuals

struct CombatPresentationLabView: View {
    @State private var warrior = ProcessInfo.processInfo.arguments.contains("--presentation-warrior") || Bundle.main.bundleIdentifier == "com.tacticalgo.prototype.presentationlab"
    var body:some View {
        VStack(spacing:0) {
            HStack {
                Button("法師 · 魔法之手") {warrior=false}.accessibilityIdentifier("lab-mage").tint(warrior ? .gray:.purple)
                Button("戰士 · 築壘") {warrior=true}.accessibilityIdentifier("lab-warrior").tint(warrior ? .brown:.gray)
            }.buttonStyle(.bordered).padding(.vertical,6)
            if warrior {WarriorPresentationLabView()} else {PresentationLabView()}
        }.background(Color(red:0.96,green:0.94,blue:0.89))
    }
}

@MainActor @Observable final class WarriorLabStore {
    var original=false
    var size=7
    var owner:Player = .one
    var capture=false
    var dense=false
    var reduced=false
    var bodyOnly=false
    var muted=false
    var voice=true
    var take="B"
    var voiceVolume=0.85
    var sfxVolume=0.65
    var reviewWidth:CGFloat?
    private(set) var session=GameSession(try! WarriorPresentationFixture.state())
    private(set) var plan:WarriorPresentationPlan?
    private(set) var started=0.0
    private(set) var animating=false
    private(set) var previewing=false
    private(set) var generation=0
    private(set) var voiceScheduled=0
    private(set) var status="準備築壘 · 2 AP / 4 Mana"
    private(set) var error:String?
    let assets:P02CozyAssets?
    let plate:UIImage?
    let audio=CombatAudio(defaults:UserDefaults(suiteName:"TacticalGo.warriorLab")!)
    @ObservationIgnored private let samples=PresentationSamples()
    @ObservationIgnored private var task:Task<Void,Never>?
    @ObservationIgnored private var active=false
    @ObservationIgnored private var interrupted=false
    @ObservationIgnored nonisolated(unsafe) private var observer:(any NSObjectProtocol)?
    init() {
        assets=try? P02CozyAssets.load()
        if let url=Bundle.main.url(forResource:"warrior-clean-plate",withExtension:"png",subdirectory:"PresentationLab/P07"),let bytes=try? Data(contentsOf:url),SHA256.hash(data:bytes).map({String(format:"%02x",$0)}).joined()=="64f95dc2137cb5d30d0b642142069ed283cef4a33e918aeb5d137e150028cb63" {plate=UIImage(data:bytes)} else {plate=nil}
        if assets==nil || plate==nil {error="戰士原畫／遮擋補底素材未載入。"}
        if let e=samples.error {error=e}
        audio.muted=false;audio.musicVolume=0
        audio.onInterruption = { [weak self] in self?.cancel() }
        observer=NotificationCenter.default.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] n in
            let raw=n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options=n.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self,let raw,let type=AVAudioSession.InterruptionType(rawValue:raw) else {return}
                self.interrupted=type == .began || !AVAudioSession.InterruptionOptions(rawValue:options).contains(.shouldResume)
                if type == .began {self.cancel()}
            }
        }
        let args=ProcessInfo.processInfo.arguments
        if args.contains("--warrior-original") {original=true}
        if args.contains("--warrior-9") {size=9}
        if args.contains("--warrior-white") {owner = .two}
        if args.contains("--warrior-dense") {dense=true}
        if args.contains("--warrior-capture") {capture=true}
        if args.contains("--warrior-body-only") {bodyOnly=true;voice=false;sfxVolume=0}
        if args.contains("--warrior-voice-A") {take="A"}
        if args.contains("--warrior-board-390") {reviewWidth=390}
        if args.contains("--warrior-board-320") {reviewWidth=320}
    }
    deinit {task?.cancel();if let observer {NotificationCenter.default.removeObserver(observer)}}
    func scene(_ value:Bool) {
        if value && !active {interrupted=false};active=value
        if !value {cancel()}
        audio.setMatchActive(value);audio.setSceneActive(value);audio.updateState(session.state)
    }
    func cancel() {generation+=1;task?.cancel();task=nil;samples.cancel();audio.cancelEffects();animating=false;previewing=false}
    func reset() {
        cancel();plan=nil;voiceScheduled=0
        do {session=GameSession(try WarriorPresentationFixture.state(owner:owner,size:size,capture:capture,dense:dense));audio.resetBattle();audio.updateState(session.state);status="準備築壘 · 2 AP / 4 Mana"}
        catch {self.error="局面載入失敗。"}
    }
    func preview() {cancel();previewing=true;status="預覽兩個落點；確認前不施放、不播放語音。"}
    func undo() {cancel();plan=nil;if session.undo() {audio.resetBattle();audio.updateState(session.state);status="已復原 · 2 AP / 4 Mana"}}
    func play() {
        guard active,!interrupted,error==nil else {return}
        cancel()
        if plan != nil {_=session.undo();plan=nil;audio.resetBattle();audio.updateState(session.state)}
        let before=session.state,outcome=session.apply(WarriorPresentationFixture.action)
        guard let receipt=WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:outcome,current:session.state,original:original) else {status="技能不合法，沒有播放成功演出。";return}
        plan=receipt;started=ProcessInfo.processInfo.systemUptime;animating=true;voiceScheduled=0
        let speaking=voice && !original && !muted && voiceVolume>0,key="w7-voice-"+take
        let speechEnd=speaking ? 0.08+samples.duration(key):0
        let recovery=max(receipt.duration,speechEnd)
        let duckedKeys=Set(receipt.sounds.filter { speaking && $0.start<speechEnd }.map(\.key))
        audio.muted=muted;audio.sfxVolume=sfxVolume;audio.duckSkill(duration:recovery+0.12)
        if !muted {
            for cue in receipt.sounds {samples.schedule(cue.key,after:started+cue.start-ProcessInfo.processInfo.systemUptime,volume:sfxVolume*(speaking && cue.start<speechEnd ? 0.42:1))}
            if speaking && samples.schedule(key,after:started+0.08-ProcessInfo.processInfo.systemUptime,volume:voiceVolume) {voiceScheduled=1}
        }
        status="築壘成功 · \(session.state.apRemaining) AP / \(session.state.mana(of:owner)) Mana"
        if ProcessInfo.processInfo.arguments.contains("--warrior-autoplay") {
            print("WARRIOR_CLOCK \(original ? "original":"candidate") wall=\(Date().timeIntervalSince1970) uptime=\(started)")
            print("WARRIOR_RECEIPT id=\(generation) caster=\(owner) ap=\(before.apRemaining)->\(session.state.apRemaining) mana=\(before.mana(of:owner))->\(session.state.mana(of:owner)) placements=\(receipt.placements) captures=\(receipt.captures) before=\(before.board.diagram.replacingOccurrences(of:"\n",with:"/")) after=\(session.state.board.diagram.replacingOccurrences(of:"\n",with:"/"))")
            fflush(nil)
        }
        let token=generation
        task=Task { [weak self] in
            guard let self else {return}
            do {try await Task.sleep(for:.seconds(max(0,self.started+receipt.duration-ProcessInfo.processInfo.systemUptime)))} catch {return}
            guard !Task.isCancelled,self.generation==token,self.active else {return}
            self.animating=false;self.audio.updateState(self.session.state)
            if speaking {
                do {try await Task.sleep(for:.seconds(max(0,self.started+recovery-ProcessInfo.processInfo.systemUptime)))} catch {return}
                for step in 1...4 {
                    guard !Task.isCancelled,self.generation==token,self.active else {return}
                    self.samples.effectsVolume(self.sfxVolume*(0.42+0.58*Double(step)/4),keys:duckedKeys)
                    do {try await Task.sleep(for:.seconds(0.03))} catch {return}
                }
            }
        }
    }
    var audit:String {"\(session.state.board.diagram)|ap=\(session.state.apRemaining)|mana=\(session.state.mana(of:owner))|active=\(animating)|voice=\(voiceScheduled)|take=\(take)|players=\(samples.playing)|captures=\(plan?.captures.count ?? 0)|generation=\(generation)"}
    func lifecycleAudit() async {
        for _ in 0..<200 {if active {break};try? await Task.sleep(for:.seconds(0.01))}
        try? await Task.sleep(for:.seconds(0.5));reset();play()
        let submitted=plan != nil && animating,committed=session.state
        try? await Task.sleep(for:.seconds(0.08));let early=ProcessInfo.processInfo.systemUptime-started<0.22
        cancel();try? await Task.sleep(for:.seconds(1.7))
        let noLate=samples.playing==0 && !animating && session.state==committed
        undo();let restored=session.state.apRemaining==2 && session.state.mana(of:owner)==4
        reset();play()
        NotificationCenter.default.post(name:AVAudioSession.interruptionNotification,object:nil,userInfo:[AVAudioSessionInterruptionTypeKey:AVAudioSession.InterruptionType.began.rawValue])
        try? await Task.sleep(for:.seconds(0.08));let held=session.state;play()
        try? await Task.sleep(for:.seconds(1.7))
        let stopped=interrupted && session.state==held && samples.playing==0 && !animating
        NotificationCenter.default.post(name:AVAudioSession.interruptionNotification,object:nil,userInfo:[AVAudioSessionInterruptionTypeKey:AVAudioSession.InterruptionType.ended.rawValue,AVAudioSessionInterruptionOptionKey:AVAudioSession.InterruptionOptions.shouldResume.rawValue])
        undo();status=submitted && early && noLate && restored && stopped ? "取消檢查通過：無延遲語音，正式結果與復原正常。":"取消檢查失敗 submitted=\(submitted) early=\(early) noLate=\(noLate) restored=\(restored) interruption=\(stopped)"
    }
}

struct WarriorPresentationLabView:View {
    @State private var store=WarriorLabStore()
    @Environment(\.scenePhase) private var scene
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    var body:some View {
        ScrollView {
            VStack(spacing:12) {
                Text("戰士 · 築壘").font(.title2.bold())
                HStack {
                    Button("原版節奏") {store.original=true;store.reset()}.accessibilityIdentifier("warrior-old")
                    Button("盾擊＋英文語音") {store.original=false;store.reset()}.accessibilityIdentifier("warrior-new")
                    Button(store.size==7 ? "7×7":"9×9") {store.size=store.size==7 ? 9:7;store.reset()}.accessibilityIdentifier("warrior-size")
                    Button(store.owner == .one ? "黑方":"白方") {store.owner=store.owner.opponent;store.reset()}.accessibilityIdentifier("warrior-team")
                }.buttonStyle(.bordered)
                TimelineView(.animation(minimumInterval:1/60,paused:!store.animating)) { _ in
                    let t=store.animating ? ProcessInfo.processInfo.systemUptime-store.started:(store.plan?.duration ?? 0)
                    if let assets=store.assets,let plate=store.plate {WarriorLabBoard(store:store,assets:assets,plate:plate,time:t,reduced:store.reduced || systemReduced)}
                }.aspectRatio(8/9.0,contentMode:.fit).frame(width:store.reviewWidth).accessibilityIdentifier("warrior-board")
                Text(store.error ?? store.status).font(.callout).accessibilityIdentifier("warrior-status")
                HStack {
                    Button("預覽") {store.preview()}.accessibilityIdentifier("warrior-preview")
                    Button("取消") {store.cancel()}.accessibilityIdentifier("warrior-cancel")
                    Button("施放／重播") {store.play()}.accessibilityIdentifier("warrior-play").buttonStyle(.borderedProminent)
                    Button("復原") {store.undo()}.accessibilityIdentifier("warrior-undo")
                }.buttonStyle(.bordered)
                HStack {
                    Button("提子局面") {store.capture.toggle();store.dense=false;store.reset()}.accessibilityIdentifier("warrior-capture")
                    Button("密集棋形") {store.dense.toggle();store.capture=false;store.reset()}.accessibilityIdentifier("warrior-dense")
                    Button("重設") {store.reset()}.accessibilityIdentifier("warrior-reset")
                }.buttonStyle(.bordered)
                Toggle("只看角色動作",isOn:$store.bodyOnly).accessibilityIdentifier("warrior-body-only")
                Toggle("減少動態",isOn:$store.reduced).accessibilityIdentifier("warrior-reduced").onChange(of:store.reduced) {store.cancel()}
                Toggle("靜音",isOn:$store.muted).accessibilityIdentifier("warrior-muted").onChange(of:store.muted) {store.cancel()}
                Toggle("英文技能語音：Hold the line!",isOn:$store.voice).accessibilityIdentifier("warrior-voice").onChange(of:store.voice) {store.cancel()}
                Picker("配音候選",selection:$store.take) {Text("A · 堅定守護").tag("A");Text("B · 戰線號令").tag("B")}.pickerStyle(.segmented).onChange(of:store.take) {store.cancel()}
                HStack {Text("語音");Slider(value:$store.voiceVolume,in:0...1).onChange(of:store.voiceVolume) {store.cancel()}}
                HStack {Text("音效");Slider(value:$store.sfxVolume,in:0...1).onChange(of:store.sfxVolume) {store.cancel()}}
                Text("先喊出指令、抬盾蓄勢，盾牌向兩側展開防線，再擊地讓兩顆士兵同時落定。配音保留自然長度；語音時降低音效。原版節奏為同一棋形的舊時序與靜態角色比較，非完整手機1.0畫面還原。").font(.caption).foregroundStyle(.secondary)
                if let image=store.assets?.heroes[.warrior],let plate=store.plate {
                    ForEach([0.0,0.20,0.58],id:\.self) {t in
                        HStack(spacing:24) {ForEach([32,48,64],id:\.self) {width in
                            VStack {WarriorBodyView(original:image,plate:plate,pose:WarriorBodyPose.skill(at:t,reduced:store.reduced || systemReduced),width:CGFloat(width));Text("\(width) pt").font(.caption2)}
                        };Text(t==0 ? "站穩":t==0.20 ? "蓄勢":"擊地").font(.caption)}
                    }
                }
                Text(store.audit).font(.system(size:1)).foregroundStyle(.clear).frame(height:1).accessibilityIdentifier("warrior-audit")
            }.padding(16).frame(maxWidth:600)
        }.preferredColorScheme(.light)
            .onAppear {store.scene(scene == .active);store.reset()}.onDisappear {store.scene(false)}
            .onChange(of:scene) {store.scene(scene == .active)}.onChange(of:systemReduced) {store.cancel()}
            .task {
                if ProcessInfo.processInfo.arguments.contains("--warrior-lifecycle-audit") {await store.lifecycleAudit();return}
                if ProcessInfo.processInfo.arguments.contains("--warrior-autoplay") {
                    do {try await Task.sleep(for:.seconds(3));for _ in 0..<3 {store.play();try await Task.sleep(for:.seconds(2.5))}} catch {store.cancel()}
                }
            }
    }
}

private struct WarriorLabBoard:View {
    let store:WarriorLabStore,assets:P02CozyAssets,plate:UIImage,time:Double,reduced:Bool
    var body:some View {
        GeometryReader {geo in
            let fit=Anim01Geometry(width:geo.size.width,height:geo.size.height,boardSize:store.size),size=CGSize(width:fit.width,height:fit.height),pitch=CGFloat(fit.pitch)
            let presentation=BoardPresentation(state:store.session.state,selected:[],legal:[],preview:nil),plan=store.plan
            let board=plan?.board(at:time,reduced:reduced) ?? store.session.state.board
            ZStack {
                Image(uiImage:assets.shadow).resizable().frame(width:size.width,height:size.height)
                Image(uiImage:assets.board).resizable().frame(width:size.width,height:size.height)
                ArenaGrid(boardSize:store.size).stroke(Color.ink.opacity(0.30),lineWidth:1)
                ForEach(board.points,id:\.self) {p in if let piece=board[p] {
                    token(piece,at:p,plan:plan,pitch:pitch).position(presentation.center(p,size)).zIndex(Double(p.y)*10+10)
                }}
                if let plan,!reduced,time>=plan.fallStart,time<plan.arrival {
                    ForEach(plan.placements,id:\.self) {p in
                        let t=plan.fallProgress(at:time),c=presentation.center(p,size)
                        P02CozyToken(piece:Piece(plan.caster,.soldier),assets:assets,pitch:pitch,commercialStyle:true,heroClass:.warrior)
                            .opacity(min(1,t*5)).position(x:c.x,y:c.y-pitch*0.55*(1-t*t)).zIndex(Double(p.y)*10+12)
                    }
                }
                if let plan,!reduced,time>=plan.arrival,time<plan.captureStart+0.20 {
                    ForEach(plan.captures.indices,id:\.self) {i in
                        let p=plan.captures[i]
                        P02CozyToken(piece:p.piece,assets:assets,pitch:pitch,commercialStyle:true,heroClass:plan.before.heroClass(of:p.piece.owner))
                            .opacity(time<plan.captureStart ? 1:max(0,1-(time-plan.captureStart)/0.20)).position(presentation.center(p.at,size)).zIndex(160)
                    }
                }
                if let plan,!plan.original,!store.bodyOnly,!reduced,let original=assets.heroes[.warrior] {
                    WarriorBastionEffects(plan:plan,time:time,original:original,pitch:pitch,size:size,presentation:presentation).zIndex(7)
                }
                if let plan,!store.bodyOnly,!reduced,time<plan.duration {
                    let c=presentation.center(plan.hero,size)
                    if plan.original {
                        Image(systemName:"shield.fill").foregroundStyle(P02Cozy.gold.opacity(max(0,1-time/0.48))).font(.system(size:pitch*0.33)).position(x:c.x,y:c.y-pitch*0.14*time/0.48).zIndex(190)
                    } else if time>=0.58,time<0.83 {
                        let t=(time-0.58)/0.25
                        Ellipse().stroke(P02Cozy.gold.opacity(0.65*(1-t)),lineWidth:max(1,pitch*0.035)).frame(width:pitch*(0.45+0.65*t),height:pitch*(0.16+0.20*t)).position(x:c.x,y:c.y+pitch*0.02).zIndex(4)
                        ForEach(plan.placements,id:\.self) {p in
                            let target=presentation.center(p,size)
                            Ellipse().stroke(P02Cozy.gold.opacity(0.55*(1-t)),lineWidth:1).frame(width:pitch*(0.48+0.3*t),height:pitch*0.20).position(x:target.x,y:target.y+pitch*0.03).zIndex(4)
                        }
                    }
                }
                ForEach(store.session.state.board.points,id:\.self) {p in if presentation.danger.contains(p) {Circle().stroke(Color(red:0.81,green:0.40,blue:0.35),style:StrokeStyle(lineWidth:2,dash:[3,3])).frame(width:pitch*0.8).position(presentation.center(p,size)).zIndex(210)}}
                if store.previewing {ForEach([Point(2,3),Point(4,3)],id:\.self) {p in Circle().stroke(P02Cozy.gold,lineWidth:2).frame(width:pitch*0.78).position(presentation.center(p,size)).zIndex(210)}}
            }.frame(width:size.width,height:size.height).offset(x:fit.x,y:fit.y)
        }
    }
    @ViewBuilder private func token(_ piece:Piece,at point:Point,plan:WarriorPresentationPlan?,pitch:CGFloat)->some View {
        if piece.kind == .hero,piece.owner==store.owner,let original=assets.heroes[.warrior] {
            let canvas=pitch*0.88
            ZStack {
                P02SellUnitBase(black:piece.owner == .one,commander:false,width:pitch*0.74).offset(y:pitch*0.03)
                WarriorBodyView(original:original,plate:plate,pose:plan?.pose(at:time,reduced:reduced) ?? .rest,width:canvas).offset(y:canvas*(0.5-448/512.0))
                Group {
                    if piece.owner == .one {Circle().fill(P02Cozy.card).overlay(Circle().fill(P02Cozy.coordinate).padding(0.7))}
                    else {Rectangle().fill(P02Cozy.ink).overlay(Rectangle().fill(P02Cozy.card).padding(1)).rotationEffect(.degrees(45))}
                }.frame(width:max(3.5,pitch*0.1),height:max(3.5,pitch*0.1)).offset(x:-pitch*0.20,y:pitch*0.225)
            }
        } else {
            let squash=plan != nil && plan!.placements.contains(point) && !reduced && time>=plan!.arrival && time<plan!.arrival+0.12 ? 0.86+0.14*MotionCurves.ease((time-plan!.arrival)/0.12):1
            P02CozyToken(piece:piece,assets:assets,pitch:pitch,squash:squash,commercialStyle:true,heroClass:store.session.state.heroClass(of:piece.owner))
        }
    }
}
/// Behind all faction bases and pawns: the shield splits into two bracing
/// projections, travels to confirmed targets and strikes exactly on arrival.
private struct WarriorBastionEffects:View {
    let plan:WarriorPresentationPlan,time:Double,original:UIImage,pitch:CGFloat,size:CGSize,presentation:BoardPresentation
    var body:some View {
        let f=WarriorBastionEffectFrame.sample(at:time),h=presentation.center(plan.hero,size)
        ZStack {
            Canvas {ctx,_ in
                guard f.alpha>0 else {return}
                for p in plan.placements {
                    let end=presentation.center(p,size)
                    let x=h.x+(end.x-h.x)*f.travel,y=h.y+(end.y-h.y)*f.travel
                    var line=Path();line.move(to:CGPoint(x:h.x,y:h.y+pitch*0.08));line.addLine(to:CGPoint(x:x,y:y+pitch*0.08))
                    ctx.stroke(line,with:.color(P02Cozy.gold.opacity(f.alpha*0.65)),style:StrokeStyle(lineWidth:max(1,pitch*0.05),lineCap:.round))
                    if f.impact>0 {
                        let spread=1-f.impact
                        for i in 0..<6 {
                            let a=Double(i)*Double.pi/3
                            let cx=end.x+cos(a)*pitch*(0.22+0.33*spread),cy=end.y+sin(a)*pitch*(0.08+0.15*spread)
                            let r=pitch*0.045*f.impact
                            var shard=Path();shard.move(to:CGPoint(x:cx,y:cy-r*1.5));shard.addLine(to:CGPoint(x:cx+r,y:cy));shard.addLine(to:CGPoint(x:cx,y:cy+r*1.5));shard.addLine(to:CGPoint(x:cx-r,y:cy));shard.closeSubpath()
                            ctx.fill(shard,with:.color(P02Cozy.gold.opacity(0.82*f.impact)))
                        }
                    }
                }
            }.frame(width:size.width,height:size.height)
            ForEach(plan.placements,id:\.self) {p in
                let end=presentation.center(p,size),dx=end.x-h.x,dy=end.y-h.y
                let n=max(1,hypot(dx,dy)),offset=pitch*0.22*(1-f.travel)
                let x=h.x+dx*f.travel+dx/n*offset,y=h.y+dy*f.travel+dy/n*offset-pitch*(0.30+f.lift)
                WarriorShieldProjection(original:original,width:pitch*0.78*f.scale)
                    .shadow(color:P02Cozy.gold.opacity(f.alpha*0.4),radius:pitch*0.035)
                    .opacity(f.alpha).position(x:x,y:y)
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false)
    }
}
#endif
