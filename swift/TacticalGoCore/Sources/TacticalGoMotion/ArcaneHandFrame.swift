import Foundation

/// D's authored physical beats share the confirmed clip clock. Coordinates
/// remain a renderer concern; none of these values can change a rules result.
public struct ArcaneHandFrame: Equatable, Sendable {
    public enum Phase: Sendable { case charge, reach, brace, push, contact, release, ended }
    public let phase: Phase
    public let reach: Double
    public let open: Double
    public let cup: Double
    public let palm: Double
    public let alpha: Double
    public let scale: Double
    public let recoil: Double
    public let pawnSquash: Double
    public static func sample(at time: Double, reduced: Bool = false) -> Self {
        func u(_ a: Double, _ b: Double) -> Double { min(1,max(0,(time-a)/(b-a))) }
        func frame(_ phase: Phase, reach: Double = 1, open: Double = 0, cup: Double = 0, palm: Double = 0,
                   alpha: Double = 1, scale: Double = 1, recoil: Double = 0, squash: Double = 1) -> Self {
            Self(phase:phase,reach:reach,open:open,cup:cup,palm:palm,alpha:alpha,scale:scale,recoil:recoil,pawnSquash:squash)
        }
        guard time.isFinite, time >= 0, time < 1.08, !reduced else { return frame(.ended,alpha:0) }
        if time < 0.30 { return frame(.charge,alpha:0) }
        if time < 0.40 {
            let t=u(0.30,0.40)
            return frame(.reach,reach:t*t*(3-2*t),open:1,alpha:t,scale:0.35+0.65*t)
        }
        if time < 0.46 {
            let t=u(0.40,0.46)
            return frame(.brace,open:1-t,cup:t,squash:1-0.16*t)
        }
        if time < 0.68 {
            let t=u(0.46,0.50)
            return frame(.push,cup:1-t,palm:t,squash:0.84+0.16*u(0.46,0.58))
        }
        if time < 0.73 { return frame(.contact,palm:1,squash:0.84) }
        let recovery=u(0.73,0.88)
        let bounce = recovery < 0.55 ? 0.84+0.24*recovery/0.55 : 1.08-0.08*(recovery-0.55)/0.45
        let release=u(0.88,1.08)
        return frame(.release,open:release,palm:1-release,alpha:1-release,scale:1-0.3*release,recoil:recovery*0.18,squash:bounce)
    }
}
