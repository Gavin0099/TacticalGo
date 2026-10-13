#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Decorative objects follow only the confirmed receipt. Danger/base overlays remain above these effects.
struct ExpansionSpellEffects: View {
    let receipt: ExpansionPresentation
    let assets: P02CozyAssets
    let hands: [UIImage]
    let time: Double, pitch: CGFloat, size: CGSize
    let reduced: Bool
    let center: (Point) -> CGPoint
    var body: some View {
        ZStack {
            if !reduced,time.isFinite,time >= 0,time < receipt.duration {
                switch receipt.action {
                case .castMagicHand,.castDoublePull: mage
                case .castBastion,.castReformation: warrior
                case .castSwap,.castChainSwap: rogue
                case .castSanctuary, .castOffering: priest
                case .useStickyBounce: bounce
                case .useShadowStep: shadow
                default: EmptyView()
                }
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false).accessibilityHidden(true)
    }
    private var heroCenter: CGPoint { receipt.hero.map(center) ?? .zero }
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
                        context.stroke(beam,with:.color(P02Cozy.deepMage.opacity(f.alpha*0.75)),style:StrokeStyle(lineWidth:pitch*0.08,lineCap:.round))
                        context.stroke(beam,with:.color(Color.mint.opacity(f.alpha*0.8)),style:StrokeStyle(lineWidth:pitch*0.035,lineCap:.round))
                    }
                    wave(context,at:b,color:P02Cozy.deepMage)
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
                }
                if let image = assets.heroes[.warrior],f.alpha > 0 {
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
                var path = Path();path.move(to:center(move.from))
                if move.piece.kind == .hero,case .castChainSwap(let first,_) = receipt.action { path.addLine(to:center(first)) }
                path.addLine(to:center(move.to))
                context.stroke(path,with:.color(P02Cozy.ink.opacity(alpha*0.65)),style:StrokeStyle(lineWidth:pitch*0.065,lineCap:.round,dash:[pitch*0.13,pitch*0.10]))
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
#endif
