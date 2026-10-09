import Foundation

/// Bounded planar IK for the candidate's symmetric 0.12m thigh/calf chain.
/// Keeps ankle position and foot pitch fixed while the root crouches/leans.
public struct GroundedLegPose: Sendable, Equatable {
    public let depth: Double
    public let rootPitch: Double
    public let hip: Double
    public let knee: Double
    public let ankle: Double
    public init(depth requestedDepth: Double, rootPitch requestedPitch: Double = 0) {
        let pitch = requestedPitch.isFinite ? min(0.4, max(-0.4, requestedPitch)) : 0
        let desired = requestedDepth.isFinite ? min(0.12, max(0, requestedDepth)) : 0
        let hipHeight = 0.35, ankleHeight = 0.11, reach = 0.24
        // Leaning with a fully straight leg can make the planted ankle
        // unreachable. Lower the root only as much as needed for reach.
        let minimumDepth = max(0, hipHeight * cos(pitch)
            - sqrt(max(0, reach * reach - pow(hipHeight * sin(pitch), 2))) - ankleHeight)
        let depth = max(desired, minimumDepth)
        let y = (ankleHeight + depth) * cos(pitch) - hipHeight
        let z = -(ankleHeight + depth) * sin(pitch)
        let bend = acos(min(1, max(0, hypot(y, z) / reach)))
        let direction = atan2(-z, -y)
        self.depth = depth; rootPitch = pitch
        hip = direction - bend; knee = bend * 2
        ankle = -pitch - hip - knee
    }
}
