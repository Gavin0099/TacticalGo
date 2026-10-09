import UIKit
import RealityKit

/// Fits the modeled arena at a fixed near-overhead angle. The view uses actual
/// projected intersections for picking, so framing cannot change rule coordinates.
@MainActor enum ArenaCamera {
    static func position(size: Int, viewport: CGSize, yaw: Float, zoom: Float = 1, focus: SIMD3<Float> = [0, 0.08, 0]) -> SIMD3<Float> {
        let n = Float(size), aspect = Float(viewport.width / max(1, viewport.height))
        let target = SIMD3<Float>(0, 0.08, 0)
        let direction = simd_normalize(SIMD3<Float>(sin(yaw) * 0.48, 0.88, cos(yaw) * 0.48))
        let forward = -direction, right = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
        let up = simd_cross(right, forward)
        let tanV = tan(Float(19) * .pi / 180), tanH = tanV * aspect
        let half = (n + 0.59) / 2
        // Keep the previous straight-on framing; increase distance only when a
        // rotated corner would leave the safe 94% viewport rectangle.
        var distance = (n + 1.25) * max(1, 1 / aspect) * 1.55
        for x in [-half, half] { for z in [-half, half] { for y: Float in [-0.50, 0.95] {
            let p = SIMD3<Float>(x, y, z) - target
            let requirement = simd_dot(p, direction) + max(abs(simd_dot(p, right)) / (tanH * 0.94), abs(simd_dot(p, up)) / (tanV * 0.94))
            distance = max(distance, requirement)
        } } }
        return focus + direction * (distance / min(1.8, max(1, zoom)))
    }
}
