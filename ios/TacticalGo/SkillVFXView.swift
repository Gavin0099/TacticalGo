import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Finite charge / ribbon / impact effects; successful receipt only. Tactical overlays stay above it.
struct SkillVFXLayer: View {
    let receipt: BoardPlayback
    let plan: SkillVFX
    let elapsed: Double
    let pitch: CGFloat
    let size: CGSize
    let reduced: Bool
    let foreground: Bool
    let center: (Point) -> CGPoint
    @State private var reducedVisible = true

    var body: some View {
        Canvas { context, _ in
            if reduced {
                if reducedVisible { drawReduced(&context) }
            } else if plan.isActive(at:elapsed) {
                if foreground { drawForeground(&context) } else { drawGround(&context) }
            }
        }
        .frame(width:size.width,height:size.height)
        .allowsHitTesting(false).accessibilityHidden(true)
        .task(id:receipt.id) {
            reducedVisible = true
            guard reduced else {return}
            do {try await Task.sleep(for:.seconds(SkillVFX.reducedHintDuration))} catch {return}
            reducedVisible = false
        }
    }
    private var accent: Color {
        switch plan.kind {
        case .bastion: Color(red:0.76,green:0.46,blue:0.10)
        case .magicHand: Color(red:0.32,green:0.29,blue:0.76)
        case .swap: Color(red:0.51,green:0.35,blue:0.67)
        }
    }
    private let light = Color(red:1,green:0.95,blue:0.78)
    private func u(_ start:Double,_ finish:Double) -> Double { MotionCurves.clamp((elapsed-start)/max(0.001,finish-start)) }
    private func offset(_ p:CGPoint,_ x:CGFloat=0,_ y:CGFloat=0) -> CGPoint {CGPoint(x:p.x+x,y:p.y+y)}
    private func ring(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double,_ color:Color?=nil,_ ellipse:Bool=false,_ width:CGFloat=1.6) {
        let rect=CGRect(x:p.x-radius,y:p.y-radius*(ellipse ? 0.36:1),width:2*radius,height:2*radius*(ellipse ? 0.36:1))
        let path=Path(ellipseIn:rect)
        context.stroke(path,with:.color((color ?? accent).opacity(alpha)),lineWidth:width)
    }
    private func aura(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double) {
        let path=Path(ellipseIn:CGRect(x:p.x-radius,y:p.y-radius*0.35,width:radius*2,height:radius*0.7))
        context.fill(path,with:.radialGradient(Gradient(colors:[accent.opacity(alpha),accent.opacity(0)]),center:p,startRadius:0,endRadius:radius))
    }
    private func stars(_ context:inout GraphicsContext,_ p:CGPoint,_ progress:Double,_ count:Int=5) {
        guard progress>=0,progress<1 else{return}
        for i in 0..<count {
            let angle=Double(i)*2*Double.pi/Double(count)+0.3
            let radius=pitch*CGFloat(0.22+0.16*progress)
            let q=offset(p,CGFloat(cos(angle))*radius,CGFloat(sin(angle))*radius*0.40-pitch*CGFloat(0.08*progress))
            let s=max(1,pitch*0.035)*CGFloat(1-progress)
            let path=Path { v in v.move(to:offset(q,0,-s));v.addLine(to:offset(q,s,0));v.addLine(to:offset(q,0,s));v.addLine(to:offset(q,-s,0));v.closeSubpath() }
            context.fill(path,with:.color(light.opacity(0.85*(1-progress))))
        }
    }
    private func cornerMarks(_ context:inout GraphicsContext,_ p:CGPoint,_ alpha:Double) {
        let r=pitch*0.39,l=pitch*0.11
        for sx in [CGFloat(-1),CGFloat(1)] {for sy in [CGFloat(-1),CGFloat(1)] {
            let path=Path {v in
                v.move(to:offset(p,sx*(r-l),sy*r*0.48));v.addLine(to:offset(p,sx*r,sy*r*0.48));v.addLine(to:offset(p,sx*r,sy*(r*0.48-l)))
            }
            context.stroke(path,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:1.7,lineCap:.round,lineJoin:.round))
        }}
    }
    /// A colored envelope supplies contrast on wood; the warm core is deliberately smaller.
    private func glow(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double,_ color:Color?=nil,_ flat:CGFloat=1) {
        guard alpha>0 else{return}
        let c=color ?? accent
        let path=Path(ellipseIn:CGRect(x:p.x-radius,y:p.y-radius*flat,width:radius*2,height:radius*2*flat))
        context.fill(path,with:.radialGradient(Gradient(stops:[.init(color:light.opacity(alpha),location:0),.init(color:c.opacity(alpha*0.86),location:0.23),.init(color:c.opacity(alpha*0.38),location:0.55),.init(color:c.opacity(0),location:1)]),center:p,startRadius:0,endRadius:radius))
    }
    private func ribbon(_ context:inout GraphicsContext,_ points:[CGPoint],_ width:CGFloat,_ alpha:Double) {
        guard points.count>1,alpha>0 else{return}
        var path=Path();path.move(to:points[0]);for q in points.dropFirst(){path.addLine(to:q)}
        // Distinct saturated silhouette, soft halo, then a small luminous center.
        var halo=context;halo.addFilter(.blur(radius:max(1,pitch*0.055)))
        halo.stroke(path,with:.color(accent.opacity(alpha*0.60)),style:StrokeStyle(lineWidth:width*2.4,lineCap:.round,lineJoin:.round))
        context.stroke(path,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:width,lineCap:.round,lineJoin:.round))
        context.stroke(path,with:.color(light.opacity(alpha*0.88)),style:StrokeStyle(lineWidth:max(1,width*0.24),lineCap:.round,lineJoin:.round))
    }
    private func burst(_ context:inout GraphicsContext,_ p:CGPoint,_ age:Double,_ count:Int=18,_ flat:Double=0.48,_ lifetime:Double=0.26) {
        for sample in SkillBurstSample.samples(at:age,lifetime:lifetime,count:count,flatten:flat) {
            let q=offset(p,pitch*sample.x,pitch*sample.y),tail=offset(p,pitch*sample.tailX,pitch*sample.tailY)
            var line=Path();line.move(to:tail);line.addLine(to:q)
            context.stroke(line,with:.color(accent.opacity(sample.alpha)),style:StrokeStyle(lineWidth:max(1.4,pitch*sample.scale*1.8),lineCap:.round))
            context.stroke(line,with:.color(light.opacity(sample.alpha)),style:StrokeStyle(lineWidth:max(0.8,pitch*sample.scale*0.65),lineCap:.round))
            glow(&context,q,max(1.8,pitch*sample.scale*1.5),sample.alpha*0.75)
        }
    }
    private func impact(_ context:inout GraphicsContext,_ p:CGPoint,_ start:Double,_ lifetime:Double=0.26,_ count:Int=18) {
        guard elapsed>=start,elapsed<start+lifetime else{return}
        let t=u(start,start+lifetime),launch=1-pow(1-t,3)
        glow(&context,p,pitch*CGFloat(0.28+0.35*launch),0.88*pow(1-t,2),nil,0.43)
        ring(&context,p,pitch*CGFloat(0.15+0.50*launch),0.95*(1-t),nil,true,pitch*CGFloat(0.035*(1-t))+1)
        ring(&context,p,pitch*CGFloat(0.11+0.43*launch),0.8*(1-t),light,true,1.3)
        burst(&context,p,elapsed-start,count,0.38,lifetime)
    }
    private func chargeSeal(_ context:inout GraphicsContext,_ hero:CGPoint) {
        guard elapsed<plan.release else{return}
        let charge=u(0,plan.release),radius=pitch*CGFloat(0.72-0.05*charge)
        glow(&context,hero,radius*1.2,0.42+0.30*charge,nil,0.4)
        // Broken sweeping arcs and inward motes create visible gathering, not a static UI ring.
        for i in 0..<3 {
            let angle=Double(i)*2*Double.pi/3+elapsed*5
            var points:[CGPoint]=[]
            for j in 0...18 {
                let a=angle+Double(j)/18*1.30
                points.append(offset(hero,CGFloat(cos(a))*radius,CGFloat(sin(a))*radius*0.36))
            }
            ribbon(&context,points,max(2.2,pitch*0.06),0.80+0.20*charge)
        }
        if plan.kind != .swap {
            // Discrete runic teeth make a magical seal, rather than a selection highlight.
            for i in 0..<6 {
                let a=Double(i)*Double.pi/3,q=offset(hero,CGFloat(cos(a))*radius*0.82,CGFloat(sin(a))*radius*0.29)
                let r=pitch*0.07
                let rune=Path {v in v.move(to:offset(q,-r,0));v.addLine(to:offset(q,0,-r));v.addLine(to:offset(q,r,0));v.addLine(to:offset(q,0,r));v.closeSubpath()}
                context.fill(rune,with:.color(accent.opacity(0.75+0.25*charge)))
                context.stroke(rune,with:.color(light.opacity(0.8*charge)),lineWidth:1)
            }
        }
        for i in 0..<8 {
            let age=(charge+Double(i)/8).truncatingRemainder(dividingBy:1)
            let a=Double(i)*2.39996+charge*1.3,r=pitch*CGFloat(0.78-0.38*age)
            glow(&context,offset(hero,CGFloat(cos(a))*r,CGFloat(sin(a))*r*0.36),max(1.8,pitch*0.045),sin(.pi*age)*0.9)
        }
    }
    private func drawGround(_ context:inout GraphicsContext) {
        let hero=offset(center(plan.hero),0,pitch*0.27)
        chargeSeal(&context,hero)
        switch plan.kind {
        case .bastion:
            // Two matching summoning shafts establish both new anchors before the body drops.
            if elapsed>=plan.release,elapsed<plan.arrival+0.14 {
                let rise=u(plan.release,plan.arrival),fade=1-u(plan.arrival,plan.arrival+0.14)
                for p in plan.destinations {
                    let q=offset(center(p),0,pitch*0.16),height=pitch*CGFloat(0.62+0.16*rise)
                    let shaft=Path(roundedRect:CGRect(x:q.x-pitch*0.25,y:q.y-height,width:pitch*0.50,height:height),cornerRadius:pitch*0.12)
                    context.fill(shaft,with:.linearGradient(Gradient(colors:[accent.opacity(0),accent.opacity(0.42*fade),light.opacity(0.80*fade)]),startPoint:offset(q,0,-height),endPoint:q))
                    ring(&context,q,pitch*0.34,fade,nil,true,2.6)
                    for i in 0..<5 {
                        let t=(rise+Double(i)*0.21).truncatingRemainder(dividingBy:1)
                        glow(&context,offset(q,pitch*CGFloat(Double(i-2)*0.08),-height*CGFloat(t)),max(1.5,pitch*0.045),sin(.pi*t)*fade)
                    }
                }
            }
            // Shield contact, then the same-clock paired landings: one defensive impact.
            impact(&context,hero,plan.arrival,0.28,24)
            for p in plan.destinations {impact(&context,offset(center(p),0,pitch*0.17),plan.arrival,0.26,18)}
        case .magicHand:
            let source=offset(center(plan.sources[0]),0,pitch*0.16),target=offset(center(plan.destinations[0]),0,pitch*0.17)
            if elapsed>=plan.release,elapsed<plan.arrival {
                let t=u(plan.moveStart,plan.arrival)
                let q=CGPoint(x:source.x+(target.x-source.x)*t,y:source.y+(target.y-source.y)*t)
                glow(&context,q,pitch*0.43,0.6,nil,0.45)
                ring(&context,q,pitch*0.35,0.85,nil,true,2.2)
                burst(&context,source,elapsed-plan.moveStart,12,0.38,0.20)
            }
            impact(&context,target,plan.arrival,0.28,22)
        case .swap:
            for p in plan.sources {impact(&context,offset(center(p),0,pitch*0.17),plan.moveStart,0.18,12)}
            for p in plan.destinations {impact(&context,offset(center(p),0,pitch*0.17),plan.arrival,0.22,14)}
        }
        // A captured unit's departure remains subordinate to its exact event payload.
        if elapsed>=plan.captureStart,elapsed<plan.captureStart+0.18 {
            for p in plan.captures {burst(&context,center(p.at),elapsed-plan.captureStart,10,0.6,0.18)}
        }
    }
    private func arrow(_ context:inout GraphicsContext,_ from:CGPoint,_ to:CGPoint,_ alpha:Double,_ dashed:Bool=false) {
        let dx=to.x-from.x,dy=to.y-from.y,d=max(1,hypot(dx,dy)),ux=dx/d,uy=dy/d
        let trim=min(pitch*0.22,d*0.24),a=offset(from,ux*trim,uy*trim),b=offset(to,-ux*trim,-uy*trim)
        let p=Path {v in v.move(to:a);v.addLine(to:b);v.move(to:offset(b,-ux*4-uy*2,-uy*4+ux*2));v.addLine(to:b);v.addLine(to:offset(b,-ux*4+uy*2,-uy*4-ux*2))}
        context.stroke(p,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:1.8,lineCap:.round,lineJoin:.round,dash:dashed ? [3,2]:[]))
    }
    private func drawForeground(_ context:inout GraphicsContext) {
        let hero=center(plan.hero)
        // This local staff core deliberately sits above the staff, not across the face.
        if plan.kind == .magicHand,elapsed<plan.moveStart {
            let tip=MageBodyView.tipOffset(pose:MageBodyPose.cast(at:elapsed,timing:receipt.mageTempo.timing),width:pitch*0.92)
            let orb=offset(hero,tip.x,tip.y),charge=u(0,plan.release)
            glow(&context,orb,pitch*CGFloat(0.17+0.12*charge),0.75+0.2*charge)
            for i in 0..<5 {
                let a=Double(i)*2*Double.pi/5+elapsed*12,r=pitch*CGFloat(0.20-0.12*charge)
                glow(&context,offset(orb,CGFloat(cos(a))*r,CGFloat(sin(a))*r),max(1.5,pitch*0.04),0.85)
            }
        }
        // A board-sized sibling layer avoids per-token clipping (Pow's particle-layer lesson).
        // Only directional strokes are masked; ground bursts are behind the real actors.
        var ink=context,mask=Path(CGRect(origin:.zero,size:size))
        for p in receipt.before.board.points where receipt.before.board[p] != nil || plan.destinations.contains(p) {
            let q=center(p);mask.addRect(CGRect(x:q.x-pitch*0.32,y:q.y-pitch*0.63,width:pitch*0.64,height:pitch*0.70))
        }
        ink.clip(to:mask,style:FillStyle(eoFill:true))
        // Visible impact fragments occupy the free floor band, never a face or grip.
        // The behind-actor field gives depth; this front field prevents the landing disappearing
        // entirely beneath a cutout's opaque skirt / shield / token base.
        if plan.kind == .bastion {
            impact(&ink,offset(hero,0,pitch*0.27),plan.arrival,0.28,20)
            for p in plan.destinations {impact(&ink,offset(center(p),0,pitch*0.27),plan.arrival,0.26,20)}
        } else if plan.kind == .magicHand {
            impact(&ink,offset(center(plan.destinations[0]),0,pitch*0.27),plan.arrival,0.28,22)
        } else {
            for p in plan.destinations {impact(&ink,offset(center(p),0,pitch*0.27),plan.arrival,0.22,14)}
        }
        if plan.kind == .magicHand,elapsed>=plan.release,elapsed<plan.arrival {
            let source=offset(center(plan.sources[0]),0,pitch*0.17),target=offset(center(plan.destinations[0]),0,pitch*0.17)
            let tip=MageBodyView.tipOffset(pose:MageBodyPose.cast(at:elapsed,timing:receipt.mageTempo.timing),width:pitch*0.92)
            let orb=offset(hero,tip.x,tip.y),control=offset(hero,(source.x-hero.x)*0.58,pitch*0.45)
            func point(_ f:Double) -> CGPoint {
                let t=CGFloat(MotionCurves.clamp(f)),a=1-t
                return CGPoint(x:a*a*orb.x+2*a*t*control.x+t*t*source.x,y:a*a*orb.y+2*a*t*control.y+t*t*source.y)
            }
            // A rapidly advancing comet strikes at the movement cue; finite trailing sparks.
            let flight=u(plan.release,plan.moveStart),head=point(flight)
            var points:[CGPoint]=[]
            for i in 0...16 {points.append(point(max(0,flight-0.48)+Double(i)/16*min(0.48,flight)))}
            let alpha=elapsed<plan.moveStart ? 1.0:0.65*(1-u(plan.moveStart,plan.arrival))
            ribbon(&ink,points,max(3,pitch*0.12),alpha)
            glow(&ink,head,max(5,pitch*0.23),alpha)
            for i in 0..<7 {
                let f=max(0,flight-Double(i)*0.075),q=point(f),a=Double(i)*2.39996
                glow(&ink,offset(q,CGFloat(sin(a))*pitch*0.08,CGFloat(cos(a))*pitch*0.06),max(1.5,pitch*0.045),alpha*(1-Double(i)/8))
            }
            // The impulse trail follows the same real pushed unit's one-cell trajectory.
            let travel=u(plan.moveStart,plan.arrival)
            if elapsed>=plan.moveStart {
                let body=CGPoint(x:source.x+(target.x-source.x)*travel,y:source.y+(target.y-source.y)*travel)
                ribbon(&ink,[source,body],max(2.4,pitch*0.10),0.85*(1-travel*0.65))
                burst(&ink,source,elapsed-plan.moveStart,16,0.5,0.22)
            }
        }
        if plan.kind == .swap,elapsed>=plan.release,elapsed<plan.arrival {
            let f=u(plan.moveStart,plan.arrival)
            for i in 0..<2 {
                let a=center(plan.sources[i]),b=center(plan.destinations[i]),vertical=plan.sources[i].x==plan.destinations[i].x
                func position(_ fraction:Double) -> CGPoint {
                    let t=MotionCurves.clamp(fraction),p=MotionCurves.swapProgress(t),lane=pitch*(i==0 ? -0.16:0.08)*CGFloat(sin(.pi*t))
                    return CGPoint(x:a.x+(b.x-a.x)*p+(vertical ? lane:0),y:a.y+(b.y-a.y)*p+(vertical ? 0:lane)+pitch*0.17)
                }
                // Two curved speed ribbons retain the actual opposing trajectories and identity.
                for lane in 0..<3 {
                    let shift=CGFloat(lane-1)*pitch*0.06,alpha=Double(lane==1 ? 0.90:0.45)
                    let points=(0...14).map {j in offset(position(max(0,f-0.50)+Double(j)/14*min(0.50,f)),0,shift)}
                    ribbon(&ink,points,max(2,pitch*(lane==1 ? 0.10:0.035)),alpha)
                }
                let q=position(f)
                glow(&ink,q,pitch*0.27,0.7,nil,0.6)
                if elapsed<plan.moveStart {arrow(&ink,offset(a,0,pitch*0.2),offset(b,0,pitch*0.2),0.75,true)}
            }
        }
    }
    private func drawReduced(_ context:inout GraphicsContext) {
        if !foreground {
            for p in plan.destinations {cornerMarks(&context,offset(center(p),0,pitch*0.16),0.9)}
        } else if plan.kind != .bastion {
            for (a,b) in zip(plan.sources,plan.destinations) {arrow(&context,offset(center(a),0,pitch*0.22),offset(center(b),0,pitch*0.22),0.8,true)}
        }
    }
}

#if DEBUG
/// Native renderer + the visible screen's real GameStore; engineering evidence only.
@MainActor enum SkillVFXAudit {
    static func run(store:GameStore,assets:CozyAssets) async -> String {
        let runID=UUID().uuidString,started=Date().timeIntervalSince1970
        var rows:[[String:Any]]=[];var renders:[[String:Any]]=[]
        let docs=FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!,dir=docs.appendingPathComponent("skill-vfx-checkpoints")
        try? FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        func check(_ key:String,_ pass:Bool) {
            var row:[String:Any]=["check":key,"pass":pass]
            if !pass {row["observedBoard"]=store.state.board.diagram;row["ap"]=store.state.apRemaining;row["playbackPresent"]=store.playback != nil;row["isPresenting"]=store.isPresenting}
            rows.append(row)
        }
        func load(_ h:HeroClass,_ owner:Player,_ capture:Bool=false,_ dense:Bool=false,_ reduced:Bool=false) {
            store.leaveMatch();store.computer=nil;store.size=dense ? 9:7;store.presentationReducedMotion=reduced
            store.session=GameSession(try! SkillVFXFixture.state(h,owner:owner,size:store.size,capture:capture,dense:dense))
            store.mode = .skill;store.selected=[];store.pushDirection=nil;store.audio.voiceEnabled=false;store.audio.musicEnabled=false;store.audio.muted=true
            store.setSceneAudioActive(true);store.setMatchAudioActive(true)
        }
        func select(_ h:HeroClass) {
            if h == .warrior {store.select(Point(2,3));store.select(Point(4,3))}
            else {store.select(Point(4,3));if h == .mage {store.chooseDirection(.up)}}
        }
        func render(_ r:BoardPlayback,_ name:String,_ t:Double,_ width:Double=390,_ reduced:Bool=false) {
            let begin=ProcessInfo.processInfo.systemUptime
            let board=CozyBoard(presentation:BoardPresentation(state:r.outcome.state,selected:[],legal:[],preview:nil),assets:assets,playback:r,botPlayback:nil,botStartedAt:nil,animating:true,reducedMotion:reduced,checkpoint:t,effectsEnabled:true,select:{_ in}).frame(width:width,height:width*9/8)
            let image=ImageRenderer(content:board);image.scale=1
            if let data=image.uiImage?.pngData() {try? data.write(to:dir.appendingPathComponent(name+".png"))}
            renders.append(["file":name+".png","checkpoint":t,"width":width,"reduced":reduced,"renderAndPNGms":(ProcessInfo.processInfo.systemUptime-begin)*1000])
        }
        for h in [HeroClass.warrior,.mage,.rogue] {for owner in Player.allCases {for capture in [false,true] {
            load(h,owner,capture);let before=store.state,key=h.art+"-"+String(describing:owner)+"-"+String(capture)
            select(h);check(key+"-preview",store.state==before && store.playback==nil && store.preview?.success==true)
            store.cancelSelection();check(key+"-cancel",store.state==before && store.playback==nil)
            select(h);store.confirm()
            guard let r=store.playback,let fx=r.skillVFX else {check(key+"-receipt",false);continue}
            let after=store.state;store.confirm();check(key+"-once",store.state==after && store.playback?.id==r.id)
            check(key+"-targets",fx.destinations.count==(h == .mage ? 1:2))
            check(key+"-resources",after.apRemaining==1 && after.mana(of:owner)==2)
            check(key+"-actual-capture",fx.captures.isEmpty == !capture)
            check(key+"-voice-off",!store.audio.voiceEnabled)
            if owner == .one {
                render(r,key+"-charge",fx.release*0.7)
                render(r,key+"-release",fx.release+0.005)
                render(r,key+"-move",(fx.moveStart+fx.arrival)/2)
                render(r,key+"-landing",fx.arrival+0.015)
                render(r,key+"-impact",fx.arrival+0.085)
                if capture {render(r,key+"-capture",fx.captureStart+0.05)}
                render(r,key+"-final",r.visualDuration)
            }
            try? await Task.sleep(for:.seconds(r.visualDuration+0.08))
            check(key+"-no-lock",!store.isPresenting && store.state==GameEngine.apply(before,SkillVFXFixture.action(h)).state)
            store.undo();check(key+"-undo",store.playback==nil && store.state==before)
            store.select(Point(3,3));store.confirm();check(key+"-illegal",store.playback==nil && store.state==before)
        }}}
        for h in [HeroClass.warrior,.mage,.rogue] {for owner in Player.allCases {
            load(h,owner,false,true);select(h);store.confirm()
            if let r=store.playback,let fx=r.skillVFX {
                render(r,h.art+"-dense-"+String(describing:owner)+"-charge",fx.release*0.75,320)
                render(r,h.art+"-dense-"+String(describing:owner)+"-landing",fx.arrival+0.085,320)
                check(h.art+"-dense-"+String(describing:owner),r.before.board[Point(3,2)] != nil && r.before.board[Point(3,4)] != nil)
            } else {check(h.art+"-dense",false)}
            store.cancelPresentation();check(h.art+"-interrupt",store.playback==nil && !store.isPresenting)
            load(h,owner,false,true,true);let before=store.state;select(h);store.confirm()
            if let r=store.playback {render(r,h.art+"-reduced-"+String(describing:owner),0,320,true)}
            check(h.art+"-reduced-final",store.state==GameEngine.apply(before,SkillVFXFixture.action(h)).state && !store.isPresenting)
            store.setSceneAudioActive(false);check(h.art+"-background-clear",store.playback==nil)
        }}
        for h in [HeroClass.warrior,.mage,.rogue] {for boundary in ["restart","leave"] {
            load(h,.one);select(h);store.confirm()
            let duration=store.playback?.visualDuration ?? 1
            if boundary == "restart" {store.newMatch(classOne:h,classTwo:h)} else {store.leaveMatch()}
            let state=store.state
            check(h.art+"-"+boundary+"-clear",store.playback==nil && !store.isPresenting)
            try? await Task.sleep(for:.seconds(duration+0.03))
            check(h.art+"-"+boundary+"-no-stale",store.playback==nil && store.state==state)
        }}
        let pass=rows.allSatisfy{$0["pass"] as? Bool==true}
        let result:[String:Any]=["revision":"finite-bursts-03","runID":runID,"startedUnix":started,"completedUnix":Date().timeIntervalSince1970,"status":pass ? "PASS":"FAIL","checks":rows,"renders":renders,"voice":"off","vfx":"on","boundary":"Real Core/GameStore + native SwiftUI snapshots; not physical FPS or human VFX acceptance"]
        try? JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]).write(to:docs.appendingPathComponent("skill-vfx-audit.json"))
        store.cancelPresentation();store.presentationReducedMotion=false;store.setSceneAudioActive(true)
        return pass ? "PASS \(rows.count)/\(rows.count)":"FAIL"
    }
}
#endif
