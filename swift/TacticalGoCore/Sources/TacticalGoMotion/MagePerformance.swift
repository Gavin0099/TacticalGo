import Foundation

/// One presentation clock for the mage, pushed piece, VFX, SFX and input lock.
/// Nothing here resolves an action or changes a game state.
public enum MageTempo: String, Sendable, CaseIterable {
    case full, compact
    public var timing: MageTiming {
        self == .full
            ? MageTiming(anticipationEnd: 0.18, release: 0.28, moveStart: 0.30, arrival: 0.54, captureStart: 0.66, recoveryEnd: 0.95, summonEnd: 0.72)
            : MageTiming(anticipationEnd: 0.12, release: 0.20, moveStart: 0.22, arrival: 0.42, captureStart: 0.51, recoveryEnd: 0.76, summonEnd: 0.60)
    }
}

public struct MageTiming: Equatable, Sendable {
    public let anticipationEnd: Double
    public let release: Double
    public let moveStart: Double
    public let arrival: Double
    public let captureStart: Double
    public let recoveryEnd: Double
    public let summonEnd: Double
    public var captureEnd: Double { captureStart + 0.18 }
    public func phase(at time: Double) -> String {
        if time < anticipationEnd { return "anticipation" }
        if time < release { return "release" }
        if time < moveStart { return "release-hold" }
        if time < arrival { return "push" }
        if time < captureStart { return "settle" }
        if time < recoveryEnd { return "recover" }
        return "final"
    }
}

/// Angles in degrees, offsets in the immutable 512px source-art coordinates.
/// Shoulder and elbow transforms are nested; hand and staff share the same grip transform.
public struct MageBodyPose: Equatable, Sendable {
    public var torso = 0.0
    public var torsoY = 0.0
    public var shoulder = 0.0
    public var elbow = 0.0
    public var head = 0.0
    public var cape = 0.0
    public var lift = 0.0
    public var opacity = 1.0
    public static let rest = Self()
    private static func smooth(_ t: Double) -> Double { let u = min(1, max(0, t)); return u * u * (3 - 2 * u) }
    private static func mix(_ a: Self, _ b: Self, _ t: Double) -> Self {
        let t = smooth(t)
        func v(_ a: Double, _ b: Double) -> Double { a + (b - a) * t }
        return Self(torso: v(a.torso,b.torso),torsoY: v(a.torsoY,b.torsoY),shoulder: v(a.shoulder,b.shoulder),elbow: v(a.elbow,b.elbow),head: v(a.head,b.head),cape: v(a.cape,b.cape),lift: v(a.lift,b.lift),opacity: v(a.opacity,b.opacity))
    }
    public static func cast(at time: Double, timing: MageTiming, reduced: Bool = false) -> Self {
        guard !reduced, time >= 0, time < timing.recoveryEnd else { return .rest }
        let coil = Self(torso: -2, torsoY: 7, shoulder: -12, elbow: -8, head: 2, cape: -1)
        let release = Self(torso: 2, torsoY: -3, shoulder: 16, elbow: 8, head: -2, cape: -3)
        let hold = Self(torso: 1, torsoY: 0, shoulder: 12, elbow: 5, head: -1, cape: 4)
        let bodyEnd = timing.recoveryEnd - 0.10
        let keys: [(Double, Self)] = [(0,.rest),(timing.anticipationEnd,coil),(timing.release,release),(timing.arrival,hold),(bodyEnd,Self(cape: 1.5)),(timing.recoveryEnd,.rest)]
        for i in 1..<keys.count where time <= keys[i].0 {
            let a = keys[i-1], b = keys[i]
            var pose = mix(a.1,b.1,(time-a.0)/(b.0-a.0))
            // Cape alone follows through after the body has settled.
            if time >= bodyEnd { pose.cape = 1.5 * (1-smooth((time-bodyEnd)/0.10)) }
            return pose
        }
        return .rest
    }
    public static func summon(at time: Double, timing: MageTiming, reduced: Bool = false) -> Self {
        guard !reduced, time >= 0, time < timing.summonEnd else { return .rest }
        let t = time / timing.summonEnd
        let approach = Self(shoulder: -6, elbow: -6, cape: -3, lift: -26, opacity: 0)
        let grounded = Self(torso: -1, torsoY: 10, shoulder: 9, elbow: 5, head: 1, cape: -4)
        let stable = Self(shoulder: -2, elbow: -1, cape: 3)
        if t < 0.38 { return mix(approach,grounded,t/0.38) }
        if t < 0.72 { return mix(grounded,stable,(t-0.38)/0.34) }
        return mix(stable,.rest,(t-0.72)/0.28)
    }
}
