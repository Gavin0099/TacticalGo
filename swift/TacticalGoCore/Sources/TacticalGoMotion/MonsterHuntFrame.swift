import Foundation
import TacticalGoCore

/// Existing monster pixels react around the confirmed removal, without moving their board anchor.
public struct MonsterHuntFrame: Equatable, Sendable {
    public let x: Double, y: Double, tilt: Double, lift: Double
    public let rewardOpacity: Double, rewardScale: Double, rewardLift: Double
    public static let rest = Self(x:1,y:1,tilt:0,lift:0,rewardOpacity:0,rewardScale:1,rewardLift:0)
    public static func sample(kind: MonsterKind, at time: Double, arrival: Double = 0.44,
                              duration: Double = 0.76, reduced: Bool = false) -> Self {
        guard !reduced,time.isFinite,arrival > 0,duration > arrival,time >= 0,time < duration else { return .rest }
        if time >= arrival {
            let t = (time-arrival)/(duration-arrival)
            let appear = MotionCurves.ease(t/0.20),fade = 1-MotionCurves.ease((t-0.55)/0.45)
            return .init(x:1,y:1,tilt:0,lift:0,rewardOpacity:appear*fade,
                         rewardScale:0.75+0.25*appear,rewardLift:0.04+0.14*t)
        }
        let t = time/arrival
        let brace = sin(min(1,t/0.45)*Double.pi)
        let contact = MotionCurves.ease((t-0.74)/0.26)
        if kind == .slime {
            return .init(x:1+0.14*brace+0.24*contact,y:1-0.12*brace-0.35*contact,
                         tilt:0,lift:-0.04*brace,rewardOpacity:0,rewardScale:1,rewardLift:0)
        }
        return .init(x:1,y:1-0.04*contact,tilt:-4*brace+4*contact,lift:-0.03*brace+0.025*contact,
                     rewardOpacity:0,rewardScale:1,rewardLift:0)
    }
}
