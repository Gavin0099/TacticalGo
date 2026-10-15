#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Ground contact silhouettes live under units, never under/over unrelated status controls.
struct ExpansionContactEffects: View {
    let receipt: ExpansionPresentation
    let time: Double, pitch: CGFloat, size: CGSize
    let reduced: Bool
    let center: (Point) -> CGPoint
    private var hero: HeroClass { receipt.before.heroClass(of:receipt.caster) }
    var body: some View {
        Canvas { context,_ in
            for beat in receipt.contactBeats {
                let f = ExpansionContactFrame.sample(at:time,start:beat.start,end:receipt.duration,reduced:reduced)
                guard f.opacity > 0 else { continue }
                let q = center(beat.at),r = pitch*CGFloat(f.radius)
                var local = context
                local.translateBy(x:q.x,y:q.y+pitch*0.05)
                local.clip(to:Path(CGRect(x:-pitch*0.49,y:-pitch*0.54,width:pitch*0.98,height:pitch*0.98)))
                local.opacity = f.opacity
                let socket = Path(ellipseIn:CGRect(x:-r,y:-r*0.34,width:r*2,height:r*0.68))
                local.fill(socket,with:.color(P02Cozy.ink.opacity(0.38)))
                switch hero {
                case .warrior: warrior(&local,r:r)
                case .mage: mage(&local,r:r)
                case .rogue:
                    let source = beat.from.map(center) ?? q
                    local.rotate(by:.radians(atan2(q.y-source.y,q.x-source.x)))
                    rogue(&local,r:r)
                case .priest: priest(&local,r:r,rise:pitch*CGFloat(f.rise))
                default: break
                }
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false).accessibilityHidden(true)
    }
    private func warrior(_ context: inout GraphicsContext,r: CGFloat) {
        for sign in [-1.0,1.0] {
            let s = CGFloat(sign)
            var wedge = Path()
            wedge.move(to:CGPoint(x:r*0.42*s,y:-r*0.23))
            wedge.addLine(to:CGPoint(x:r*s,y:-r*0.07))
            wedge.addLine(to:CGPoint(x:r*0.85*s,y:r*0.25))
            wedge.addLine(to:CGPoint(x:r*0.38*s,y:r*0.30));wedge.closeSubpath()
            context.fill(wedge,with:.color(P02Cozy.gold.opacity(0.85)))
            context.stroke(wedge,with:.color(P02Cozy.ink.opacity(0.72)),lineWidth:max(1,pitch*0.035))
        }
    }
    private func mage(_ context: inout GraphicsContext,r: CGFloat) {
        let rim = Path(ellipseIn:CGRect(x:-r,y:-r*0.34,width:r*2,height:r*0.68))
        context.stroke(rim,with:.color(P02Cozy.deepMage.opacity(0.80)),lineWidth:max(2,pitch*0.10))
        context.stroke(rim,with:.color(Color.mint.opacity(0.85)),lineWidth:max(1,pitch*0.035))
        for sign in [-1.0,1.0] {
            let s=CGFloat(sign)
            var ray=Path();ray.move(to:CGPoint(x:r*0.72*s,y:-r*0.25));ray.addLine(to:CGPoint(x:r*0.90*s,y:-r*0.42))
            context.stroke(ray,with:.color(P02Cozy.card),style:StrokeStyle(lineWidth:max(1,pitch*0.05),lineCap:.round))
        }
    }
    private func rogue(_ context: inout GraphicsContext,r: CGFloat) {
        var blade=Path();blade.move(to:CGPoint(x:-r,y:r*0.20));blade.addQuadCurve(to:CGPoint(x:r,y:-r*0.20),control:CGPoint(x:r*0.12,y:-r*0.38))
        context.stroke(blade,with:.color(P02Cozy.ink.opacity(0.90)),style:StrokeStyle(lineWidth:max(3,pitch*0.14),lineCap:.round))
        context.stroke(blade,with:.color(P02Cozy.sage),style:StrokeStyle(lineWidth:max(2,pitch*0.08),lineCap:.round))
        context.stroke(blade,with:.color(P02Cozy.card.opacity(0.90)),style:StrokeStyle(lineWidth:max(1,pitch*0.025),lineCap:.round))
    }
    private func priest(_ context: inout GraphicsContext,r: CGFloat,rise: CGFloat) {
        let rim=Path(ellipseIn:CGRect(x:-r*0.86,y:-r*0.28,width:r*1.72,height:r*0.56))
        context.stroke(rim,with:.color(P02Cozy.gold.opacity(0.85)),lineWidth:max(1,pitch*0.06))
        for sign in [-1.0,1.0] {
            let s=CGFloat(sign),x=r*0.65*s
            var petal=Path();petal.move(to:CGPoint(x:x,y:-rise))
            petal.addQuadCurve(to:CGPoint(x:x+r*0.10*s,y:-rise-r*0.58),control:CGPoint(x:x-r*0.15*s,y:-rise-r*0.38))
            context.stroke(petal,with:.color(P02Cozy.gold),style:StrokeStyle(lineWidth:max(1,pitch*0.055),lineCap:.round))
        }
    }
}
#endif
