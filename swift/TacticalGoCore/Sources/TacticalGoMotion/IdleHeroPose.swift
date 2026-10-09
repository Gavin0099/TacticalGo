import Foundation
import TacticalGoCore

/// Authored presentation loop. No state, time source or rule dependency.
public struct IdleHeroPose: Equatable, Sendable {
    public static let duration = 3.4
    public let stance: GroundedLegPose
    public let head, leftArm, rightArm, cape: Double
    public init(hero: HeroClass, phase: Double) {
        let t = phase.isFinite ? min(1, max(0, phase)) : 0
        // Explicit endpoints avoid floating sine residue at exported loop seams.
        guard t > 0 && t < 1 && hero != .none else {
            stance = GroundedLegPose(depth: 0); head = 0; leftArm = 0; rightArm = 0; cape = 0
            return
        }
        let wave = sin(t * 2 * .pi), breath = pow(sin(t * .pi), 2)
        stance = GroundedLegPose(depth: 0.004 * breath, rootPitch: 0.006 * wave)
        head = -0.016 * wave
        switch hero {
        case .warrior: leftArm = -0.025 * wave; rightArm = 0.015 * wave
        case .mage: leftArm = 0.012 * wave; rightArm = -0.045 * wave
        case .rogue: leftArm = 0.035 * wave; rightArm = -0.035 * wave
        case .none: leftArm = 0; rightArm = 0
        }
        let amplitude = hero == .warrior ? 0.06 : hero == .mage ? 0.04 : 0.07
        cape = amplitude * breath * sin((t - 0.12) * 2 * .pi)
    }
}
