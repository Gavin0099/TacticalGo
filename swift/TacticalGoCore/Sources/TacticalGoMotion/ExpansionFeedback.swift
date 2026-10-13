import Foundation
import TacticalGoCore

/// Local lighting/impact envelope. Peak belongs to contact, never preview or a wall-clock callback.
public struct SpellAccentFrame: Equatable, Sendable {
    public let charge: Double, impact: Double, scale: Double
    public static let quiet = Self(charge:0,impact:0,scale:1)
    public static func sample(at time: Double, release: Double, arrival: Double, duration: Double, reduced: Bool = false) -> Self {
        guard !reduced,time.isFinite,release.isFinite,arrival.isFinite,duration.isFinite,
              release >= 0,arrival > release,duration > arrival,time >= 0,time < duration else { return .quiet }
        let charge = time < release ? MotionCurves.ease(time/max(0.001,release))*0.65 : max(0,1-(time-release)/0.10)*0.65
        let u = MotionCurves.clamp((time-arrival)/0.22)
        let impact = time >= arrival && time < arrival+0.22 ? (1-u)*(1-u) : 0
        return .init(charge:charge,impact:impact,scale:0.86+0.34*u)
    }
}

/// Cell-relative presentation values. Identity is the exact resting pose.
public struct ExpansionTokenFrame: Equatable, Sendable {
    public var scaleX = 1.0, scaleY = 1.0, lift = 0.0, tilt = 0.0, opacity = 1.0
    public static let rest = Self()
}

extension ExpansionPresentation {
    public var isChainSwap: Bool { if case .castChainSwap = action { return true }; return false }
    public var isOffering: Bool { if case .castOffering = action { return true }; return false }
    public func contextOpacity(at point: Point, time: Double, reduced: Bool = false) -> Double {
        guard isHeroSkill,!reduced,time.isFinite,time >= release,time < duration else { return 1 }
        guard point != hero,!placements.contains(point),!sacrifices.contains(point),
              !transfers.contains(where: { $0.from == point || $0.to == point }),!captures.contains(where: { $0.at == point }) else { return 1 }
        let focus = MotionCurves.clamp((time-release)/0.10)*(1-MotionCurves.clamp((time-arrival)/0.18))
        return 1-0.12*focus
    }
    public func tokenFrame(at point: Point, time: Double, moving: Bool = false, reduced: Bool = false) -> ExpansionTokenFrame {
        guard !reduced, time.isFinite, time >= 0, time < duration else { return .rest }
        if sacrifices.contains(point), case .castOffering = action {
            let u = MotionCurves.clamp((time-release)/max(0.001,arrival-release))
            return .init(scaleX: 1-0.18*u, scaleY: 1+0.10*u, lift: -0.18*u, opacity: 1-u)
        }
        guard placements.contains(point) || transfers.contains(where: { $0.to == point }) else { return .rest }
        let landing = MotionCurves.clamp((time-arrival)/0.18)
        let pulse = time >= arrival ? sin(.pi*landing) * (1-landing) : 0
        switch action {
        case .castMagicHand, .castDoublePull:
            let squash = ArcaneHandFrame.sample(at:time).pawnSquash
            return .init(scaleX: 2-squash, scaleY: squash)
        case .castBastion, .castReformation:
            let hold = time >= arrival ? 1-MotionCurves.ease((time-arrival-0.04)/0.14) : 0
            return .init(scaleX: 1+0.14*hold, scaleY: 1-0.16*hold,
                         lift: moving ? -0.16*sin(.pi*progress(at:time)) : 0)
        case .castSwap, .castChainSwap:
            var t = progress(at:time)
            if case .castChainSwap(let first,_) = action,let move = transfers.first(where: { $0.to == point }) {
                t = move.piece.kind == .hero ? (t < 0.5 ? t*2 : (t-0.5)*2) : move.from == first ? min(1,t*2) : max(0,(t-0.5)*2)
            }
            let lean = moving ? sin(.pi*t) : 0
            return .init(scaleX: 1+0.06*lean, scaleY: 1-0.05*lean, tilt: -7*lean)
        case .summonHero, .placeSoldier:
            return .init(scaleX: 1+0.10*pulse, scaleY: 1-0.12*pulse)
        default: return .rest
        }
    }
}

/// Captured pieces leave their own socket; they do not fly across unrelated cells.
public struct CaptureDissolveFrame: Equatable, Sendable {
    public let opacity: Double, scale: Double, lift: Double
    public static func sample(at time: Double, start: Double, commander: Bool = false, reduced: Bool = false) -> Self {
        guard !reduced, time.isFinite, start.isFinite, time < start+0.18 else { return .init(opacity:0,scale:1,lift:0) }
        let u = MotionCurves.clamp((time-start)/0.18)
        return .init(opacity: 1-u, scale: 1-(commander ? 0.08:0.18)*u, lift: -(commander ? 0.16:0.10)*u)
    }
}

/// Offering has an origin and an upward dissolution, never a placement or return destination.
public struct OfferingDissolveFrame: Equatable, Sendable {
    public let opacity: Double, lift: Double, spread: Double
    public static func sample(at time: Double, release: Double, arrival: Double) -> Self {
        guard time.isFinite, release.isFinite, arrival.isFinite, arrival > release,
              time >= release, time < arrival + 0.24 else { return .init(opacity: 0, lift: 0, spread: 0) }
        let t = (time - release) / (arrival - release + 0.24)
        return .init(opacity: sin(.pi * t) * 0.9, lift: t * 0.55, spread: sin(.pi * t) * 0.16)
    }
}

/// Opposing moves use opposing normals so a simple swap does not merge both units at its midpoint.
public enum RogueSwapArc {
    public static func offset(dx: Double, dy: Double, progress: Double, pitch: Double) -> (x: Double, y: Double) {
        guard dx.isFinite, dy.isFinite, progress.isFinite, pitch.isFinite, pitch > 0 else { return (0, 0) }
        let distance = hypot(dx, dy)
        guard distance > 0, progress > 0, progress < 1 else { return (0, 0) }
        let lift = sin(.pi * progress) * pitch * 0.32
        return (-dy / distance * lift, dx / distance * lift)
    }
}

/// A chain is two readable exchanges: the first pawn clears before the second exchange.
public enum RogueChainPath {
    public static func position(from a: (x: Double,y: Double), to b: (x: Double,y: Double), via middle: (x: Double,y: Double), progress: Double, pitch: Double, hero: Bool, firstEnemy: Bool) -> (x: Double,y: Double) {
        guard progress.isFinite else { return b }
        let u = MotionCurves.clamp(progress)
        let start: (x: Double,y: Double), end: (x: Double,y: Double), t: Double
        if hero {
            start = u < 0.5 ? a : middle; end = u < 0.5 ? middle : b
            t = u < 0.5 ? u*2 : (u-0.5)*2
        } else {
            start = a; end = b; t = firstEnemy ? min(1,u*2) : max(0,(u-0.5)*2)
        }
        let arc = RogueSwapArc.offset(dx:end.x-start.x,dy:end.y-start.y,progress:t,pitch:pitch)
        return (start.x+(end.x-start.x)*t+arc.x,start.y+(end.y-start.y)*t+arc.y)
    }
}
