#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Decorative objects follow only the confirmed receipt. Danger/base overlays remain above these effects.
enum ExpansionEffectPlane: Equatable { case ground, foreground }
struct ExpansionSpellEffects: View {
    let receipt: ExpansionPresentation
    let assets: P02CozyAssets
    let hands: [UIImage]
    let time: Double, pitch: CGFloat, size: CGSize
    let reduced: Bool
    var plane: ExpansionEffectPlane = .foreground
    let center: (Point) -> CGPoint
    var body: some View {
        ZStack {
            if !reduced,time.isFinite,time >= 0,time < receipt.duration {
                if plane == .foreground {
                    switch receipt.action {
                    case .castMagicHand,.castFriendlyRedeploy,.castDoublePull: mage
                    case .castBastion,.castReformation: warrior
                    case .castSwap,.castChainSwap: rogue
                    case .castSanctuary: priest
                    case .castOffering: offering
                    case .useStickyBounce: bounce
                    case .useShadowStep: shadow
                    case .huntMonster: huntReward
                    default: EmptyView()
                    }
                    if !receipt.captures.isEmpty { captureRings }
                }
                paintedAccents
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false).accessibilityHidden(true)
    }
    private var heroCenter: CGPoint { receipt.hero.map(center) ?? .zero }
    private var huntReward: some View {
        ZStack {
            if let point = receipt.hunted.first,let grant = receipt.lootGrants.first {
                let kind: MonsterKind = grant.ability == .stickyBounce ? .slime:.shadowWolf
                let f = MonsterHuntFrame.sample(kind:kind,at:time,arrival:receipt.arrival,duration:receipt.duration)
                let q = center(point)
                ZStack {
                    Ellipse().fill(grant.owner == .one ? P02Cozy.ink:P02Cozy.card)
                        .overlay(Ellipse().stroke(grant.owner == .one ? P02Cozy.sage:P02Cozy.ink,lineWidth:1.5))
                        .frame(width:pitch*0.58,height:pitch*0.22).offset(y:pitch*0.10)
                    GameIconView(icon:grant.ability == .stickyBounce ? .slime:.shadow,size:pitch*0.58)
                }.scaleEffect(f.rewardScale).opacity(f.rewardOpacity)
                    .position(x:q.x,y:q.y-pitch*f.rewardLift)
            }
        }
    }
    private var accentFrame: SpellAccentFrame { .sample(at:time,release:receipt.release,arrival:receipt.arrival,duration:receipt.duration) }
    @ViewBuilder private var paintedAccents: some View {
        switch receipt.action {
        case .castBastion,.castReformation: if plane == .ground { paintedWarrior }
        case .castMagicHand,.castFriendlyRedeploy,.castDoublePull: paintedMage
        case .castSwap,.castChainSwap: if plane == .ground { paintedRogue }
        case .castOffering: paintedPriest
        default: EmptyView()
        }
    }
    private var paintedWarrior: some View {
        let f = accentFrame
        return ZStack {
                GameSpellSprite(index:5,size:pitch*0.88).opacity(f.charge*0.32).position(x:heroCenter.x,y:heroCenter.y+pitch*0.02)
                ForEach(targets,id:\.self) { target in
                    let q = center(target)
                    GameSpellSprite(index:0,size:pitch*1.44*f.scale).opacity(f.impact*0.82).position(q)
                    GameSpellSprite(index:5,size:pitch*1.26*f.scale).opacity(f.impact*0.46).position(q)
                }
                    }
    }
    private var paintedMage: some View {
        let f = accentFrame
        return ZStack {
                if plane == .foreground {
                    let offset = MageBodyView.tipOffset(pose:.cast(at:time,timing:MagePresentationVariant.arcaneHand.timing,reduced:false,revision:.r2),width:pitch*0.92)
                    GameSpellSprite(index:4,size:pitch*0.66).opacity(f.charge).position(x:heroCenter.x+offset.x,y:heroCenter.y+offset.y)
                } else {
                    ForEach(receipt.transfers.indices,id:\.self) { i in
                        GameSpellSprite(index:1,size:pitch*1.30*f.scale).opacity(f.impact*0.76).position(center(receipt.transfers[i].to))
                    }
                }
                    }
    }
    private var paintedRogue: some View {
        return ZStack {
                ForEach(receipt.transfers.indices,id:\.self) { i in
                    let move = receipt.transfers[i],a = center(move.from),b = center(move.to),u = receipt.progress(at:time)
                    let q: CGPoint = {
                        if case .castChainSwap(let first,_) = receipt.action {
                            let middle = center(first)
                            let p = RogueChainPath.position(from:(Double(a.x),Double(a.y)),to:(Double(b.x),Double(b.y)),via:(Double(middle.x),Double(middle.y)),progress:u,pitch:Double(pitch),hero:move.piece.kind == .hero,firstEnemy:move.from == first)
                            return CGPoint(x:p.x,y:p.y)
                        }
                        let o = RogueSwapArc.offset(dx:Double(b.x-a.x),dy:Double(b.y-a.y),progress:u,pitch:Double(pitch))
                        return CGPoint(x:a.x+(b.x-a.x)*u+o.x,y:a.y+(b.y-a.y)*u+o.y)
                    }()
                    let stage = move.piece.kind == .hero ? u : {
                        if case .castChainSwap(let first,_) = receipt.action { return move.from == first ? min(1,u*2):max(0,(u-0.5)*2) }
                        return u
                    }()
                    let alpha = time >= receipt.moveStart && time < receipt.arrival ? sin(Double.pi*stage)*0.64:0
                    GameSpellSprite(index:move.piece.kind == .hero ? 2:6,size:pitch*1.06)
                        .rotationEffect(.radians(atan2(b.y-a.y,b.x-a.x))).opacity(alpha).position(q)
                }
                    }
    }
    private var paintedPriest: some View {
        let f = accentFrame
        return ZStack {
                if let sacrifice = receipt.sacrifices.first {
                    let q = center(sacrifice),leaf = OfferingDissolveFrame.sample(at:time,release:receipt.release,arrival:receipt.arrival)
                    if plane == .foreground {
                        GameSpellSprite(index:3,size:pitch*1.10).opacity(leaf.opacity*0.80).position(x:q.x,y:q.y-pitch*leaf.lift)
                    } else {
                        GameSpellSprite(index:7,size:pitch*1.26*f.scale).opacity(f.impact*0.64).position(q)
                    }
                }
                    }
    }
    private var captureRings: some View {
        Canvas { context,_ in
            guard time >= receipt.captureStart,time < receipt.captureStart+0.18 else { return }
            let u = (time-receipt.captureStart)/0.18
            for captured in receipt.captures {
                let q = center(captured.at),commander = captured.piece.kind == .commander
                let r = pitch*(commander ? 0.42:0.26)*(1+0.20*u)
                context.stroke(Path(ellipseIn:CGRect(x:q.x-r,y:q.y-r*0.32,width:r*2,height:r*0.64)),with:.color((commander ? P02Cozy.gold:P02Cozy.card).opacity(0.70*(1-u))),lineWidth:max(1,pitch*0.04*(1-u)))
            }
        }
    }
    private var targets: [Point] { receipt.placements + receipt.transfers.map(\.to) }
    private func lerp(_ a: CGPoint,_ b: CGPoint,_ t: Double) -> CGPoint { CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t) }
    private var mage: some View {
        let f = ArcaneHandFrame.sample(at:time)
        let offset = MageBodyView.tipOffset(pose:.cast(at:time,timing:MagePresentationVariant.arcaneHand.timing,reduced:false,revision:.r2),width:pitch*0.92)
        let staff = CGPoint(x:heroCenter.x+offset.x,y:heroCenter.y+offset.y)
        return ZStack {
            ForEach(receipt.transfers.indices,id:\.self) { i in
                let move = receipt.transfers[i],a = center(move.from),b = center(move.to),d = max(1,hypot(b.x-a.x,b.y-a.y))
                let unit = CGPoint(x:(b.x-a.x)/d,y:(b.y-a.y)/d),pawn = lerp(a,b,receipt.progress(at:time))
                let braced = CGPoint(x:pawn.x-unit.x*pitch*(0.40+f.recoil),y:pawn.y-unit.y*pitch*(0.40+f.recoil)-pitch*0.03)
                let q = lerp(staff,braced,f.reach)
                Canvas { context,_ in
                    if f.alpha > 0 {
                        var beam = Path();beam.move(to:staff);beam.addQuadCurve(to:q,control:CGPoint(x:(staff.x+q.x)/2,y:max(staff.y,q.y)+pitch*0.22))
                        context.stroke(beam,with:.color(P02Cozy.ink.opacity(f.alpha*0.45)),style:StrokeStyle(lineWidth:pitch*0.17,lineCap:.round))
                        context.stroke(beam,with:.color(P02Cozy.deepMage.opacity(f.alpha*0.85)),style:StrokeStyle(lineWidth:pitch*0.12,lineCap:.round))
                        context.stroke(beam,with:.color(Color.mint.opacity(f.alpha*0.9)),style:StrokeStyle(lineWidth:pitch*0.04,lineCap:.round))
                    }
                    wave(context,at:b,color:P02Cozy.deepMage)
                    if time >= receipt.arrival,time < receipt.arrival+0.14 {
                        let u = (time-receipt.arrival)/0.14
                        for j in 0..<4 {
                            let angle = Double(j)*Double.pi/2, r = pitch*(0.26+0.12*u)
                            let q = CGPoint(x:b.x+cos(angle)*r,y:b.y+sin(angle)*r*0.55)
                            var star = Path();star.move(to:CGPoint(x:q.x,y:q.y-pitch*0.05));star.addLine(to:CGPoint(x:q.x,y:q.y+pitch*0.05))
                            star.move(to:CGPoint(x:q.x-pitch*0.04,y:q.y));star.addLine(to:CGPoint(x:q.x+pitch*0.04,y:q.y))
                            context.stroke(star,with:.color(Color.mint.opacity(0.70*(1-u))),lineWidth:1)
                        }
                    }
                }
                if hands.count == 3,f.alpha > 0 {
                    ZStack { P04HandSprite(poses:hands,index:0,width:pitch*1.10).opacity(f.open)
                        P04HandSprite(poses:hands,index:1,width:pitch*1.10).opacity(f.cup)
                        P04HandSprite(poses:hands,index:2,width:pitch*1.10).opacity(f.palm)
                    }.scaleEffect(f.scale).rotationEffect(.radians(atan2(unit.y,unit.x))).opacity(f.alpha).position(q)
                }
            }
            if time >= 0.08,time < 0.34 {
                let t = min(1,(time-0.08)/0.22)
                Rectangle().fill(Color.mint).frame(width:pitch*(0.10+0.08*t),height:pitch*(0.14+0.12*t)).rotationEffect(.degrees(45)).opacity(1-min(1,max(0,(time-0.30)/0.04))).position(staff)
            }
        }
    }
    private var warrior: some View {
        let f = WarriorBastionEffectFrame.sample(at:time)
        return ZStack {
            ForEach(targets,id:\.self) { p in
                let end = center(p),q = lerp(heroCenter,end,f.travel)
                Canvas { context,_ in
                    if f.alpha > 0 {
                        var path = Path();path.move(to:heroCenter);path.addLine(to:q)
                        context.stroke(path,with:.color(P02Cozy.gold.opacity(f.alpha*0.65)),style:StrokeStyle(lineWidth:max(1,pitch*0.05),lineCap:.round))
                    }
                    wave(context,at:end,color:P02Cozy.gold)
                    if time >= receipt.arrival,time < receipt.arrival+0.18 {
                        let u = (time-receipt.arrival)/0.18
                        for j in 0..<4 {
                            let direction = j < 2 ? -1.0 : 1.0
                            let q = CGPoint(x:end.x+direction*pitch*(0.18+Double(j%2)*0.08+u*0.15),y:end.y-pitch*0.02-pitch*sin(u*Double.pi)*0.10)
                            context.fill(Path(ellipseIn:CGRect(x:q.x,y:q.y,width:pitch*0.065,height:pitch*0.035)),with:.color(P02Cozy.gold.opacity(0.55*(1-u))))
                        }
                    }
                }
                if case .castBastion = receipt.action,let image = assets.heroes[.warrior],f.alpha > 0 {
                    WarriorShieldProjection(original:image,width:pitch*0.78*f.scale).opacity(f.alpha).position(x:q.x,y:q.y-pitch*(0.30+f.lift))
                }
            }
        }
    }
    private var rogue: some View {
        Canvas { context,_ in
            guard time >= receipt.release,time < receipt.captureStart else { return }
            let alpha = min(1,(time-receipt.release)/0.04)*max(0,1-(time-receipt.arrival)/0.08)
            for move in receipt.transfers {
                let a = center(move.from), b = center(move.to)
                var path = Path();path.move(to:a)
                if case .castSwap = receipt.action {
                    let head = receipt.progress(at:time), tail = max(0,head-0.35)
                    let startOffset = RogueSwapArc.offset(dx:b.x-a.x,dy:b.y-a.y,progress:tail,pitch:pitch)
                    path = Path();path.move(to:CGPoint(x:a.x+(b.x-a.x)*tail+startOffset.x,y:a.y+(b.y-a.y)*tail+startOffset.y))
                    for i in 1...12 {
                        let t = tail+(head-tail)*Double(i)/12, offset = RogueSwapArc.offset(dx:b.x-a.x,dy:b.y-a.y,progress:t,pitch:pitch)
                        path.addLine(to:CGPoint(x:a.x+(b.x-a.x)*t+offset.x,y:a.y+(b.y-a.y)*t+offset.y))
                    }
                } else if case .castChainSwap(let first,_) = receipt.action {
                    let middle = center(first),head = receipt.progress(at:time),tail = max(0,head-0.25)
                    path = Path()
                    for i in 0...12 {
                        let t = tail+(head-tail)*Double(i)/12
                        let q = RogueChainPath.position(from:(Double(a.x),Double(a.y)),to:(Double(b.x),Double(b.y)),via:(Double(middle.x),Double(middle.y)),progress:t,pitch:Double(pitch),hero:move.piece.kind == .hero,firstEnemy:move.from == first)
                        if i == 0 { path.move(to:CGPoint(x:q.x,y:q.y)) } else { path.addLine(to:CGPoint(x:q.x,y:q.y)) }
                    }
                } else {
                    path.addLine(to:b)
                }
                context.stroke(path,with:.color(P02Cozy.sage.opacity(alpha*0.65)),style:StrokeStyle(lineWidth:pitch*0.05,lineCap:.round))
                wave(context,at:b,color:P02Cozy.sage)
            }
        }
    }
    private var offering: some View {
        Canvas { context, _ in
            guard let source = receipt.sacrifices.first else { return }
            let f = OfferingDissolveFrame.sample(at: time, release: receipt.release, arrival: receipt.arrival)
            guard f.opacity > 0 else { return }
            let origin = center(source)
            if time >= receipt.arrival {
                let u = min(1,(time-receipt.arrival)/0.18),r = pitch*0.29
                context.stroke(Path(ellipseIn:CGRect(x:origin.x-r,y:origin.y-r*0.32,width:r*2,height:r*0.64)),with:.color(P02Cozy.gold.opacity(0.55*(1-u))),style:StrokeStyle(lineWidth:1,dash:[2,3]))
            }
            for i in 0..<5 {
                let q = CGPoint(x: origin.x + Double(i-2) * pitch * f.spread,
                                y: origin.y - pitch * (f.lift + Double(i % 2) * 0.05))
                let r = pitch * 0.045
                var leaf = Path(); leaf.move(to: CGPoint(x:q.x,y:q.y+r))
                leaf.addQuadCurve(to:CGPoint(x:q.x,y:q.y-r),control:CGPoint(x:q.x-r*1.3,y:q.y))
                leaf.addQuadCurve(to:CGPoint(x:q.x,y:q.y+r),control:CGPoint(x:q.x+r*1.3,y:q.y));leaf.closeSubpath()
                context.fill(leaf,with:.color(P02Cozy.gold.opacity(f.opacity)))
            }
        }
    }
    private var priest: some View {
        Canvas { context,_ in
            guard let sacrifice = receipt.sacrifices.first,time >= 0.20 else { return }
            let target = receipt.placements.first ?? sacrifice
            let donor = center(sacrifice),end = center(target),hand = CGPoint(x:heroCenter.x-pitch*0.15,y:heroCenter.y-pitch*0.51)
            let collect = min(1,max(0,(time-0.20)/0.12)),gift = receipt.progress(at:time)
            let q = time < receipt.moveStart ? lerp(donor,hand,collect):lerp(hand,end,gift)
            let alpha = time < receipt.arrival ? collect:max(0,1-(time-receipt.arrival)/0.22)
            for i in 0..<3 {
                let a = Double(i-1)*0.7,r = pitch*0.09
                var leaf = Path();leaf.move(to:CGPoint(x:q.x,y:q.y+r))
                leaf.addQuadCurve(to:CGPoint(x:q.x+sin(a)*r*2,y:q.y-r*1.8),control:CGPoint(x:q.x-r,y:q.y-r))
                leaf.addQuadCurve(to:CGPoint(x:q.x,y:q.y+r),control:CGPoint(x:q.x+r,y:q.y-r));leaf.closeSubpath()
                context.fill(leaf,with:.color(P02Cozy.gold.opacity(alpha*0.85)))
            }
            wave(context,at:end,color:P02Cozy.sage)
        }
    }
    private var bounce: some View {
        Canvas { context,_ in
            guard let move = receipt.transfers.first else { return }
            let p = lerp(center(move.from),center(move.to),receipt.progress(at:time))
            if time >= receipt.moveStart,time < receipt.arrival {
                let r = pitch*0.15
                context.stroke(Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r*0.6,width:r*2,height:r*1.2)),with:.color(Color.mint.opacity(0.75)),lineWidth:pitch*0.04)
            }
            wave(context,at:center(move.to),color:P02Cozy.sage)
        }
    }
    private var shadow: some View {
        Canvas { context,_ in
            guard let move = receipt.transfers.first,time >= receipt.moveStart,time < receipt.captureStart else { return }
            let p = lerp(center(move.from),center(move.to),receipt.progress(at:time))
            var line = Path();line.move(to:center(move.from));line.addLine(to:p)
            context.stroke(line,with:.color(Color.indigo.opacity(0.5*max(0,1-(time-receipt.arrival)/0.08))),style:StrokeStyle(lineWidth:pitch*0.09,lineCap:.round,dash:[pitch*0.18,pitch*0.08]))
            wave(context,at:center(move.to),color:.indigo)
        }
    }
    private func wave(_ context: GraphicsContext,at p: CGPoint,color: Color) {
        guard time >= receipt.arrival,time < receipt.arrival+0.18 else { return }
        let t = (time-receipt.arrival)/0.18,r = pitch*(0.31+0.19*t)
        context.stroke(Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r*0.32,width:r*2,height:r*0.64)),with:.color(color.opacity(0.85*(1-t))),lineWidth:max(1,pitch*0.05*(1-t)))
    }
}

/// Samples untouched generated pixels; each cell has transparent gutters.
private struct GameSpellSprite: View {
    let index: Int
    let size: CGFloat
    var body: some View {
        Image("game-spell-atlas-v22").resizable().frame(width:size*4,height:size*2)
            .offset(x:-CGFloat(index%4)*size,y:-CGFloat(index/4)*size)
            .frame(width:size,height:size,alignment:.topLeading).clipped()
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}
#endif
