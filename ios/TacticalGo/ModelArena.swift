import UIKit
import RealityKit

/// Original modeled garden arena. Decoration stays outside the rule intersections.
/// No collision or game state lives here; projected grid coordinates remain authoritative.
@MainActor enum MiniatureArena {
    static let stone = UIColor(red: 0.53, green: 0.58, blue: 0.55, alpha: 1)
    static let darkStone = UIColor(red: 0.33, green: 0.39, blue: 0.37, alpha: 1)
    static let timber = UIColor(red: 0.36, green: 0.20, blue: 0.10, alpha: 1)
    static let leaf = UIColor(red: 0.31, green: 0.57, blue: 0.15, alpha: 1)
    static let brightLeaf = UIColor(red: 0.46, green: 0.69, blue: 0.21, alpha: 1)
    /// A few broad facets read as cut stone without tiny noisy surface details.
    static func stoneMesh(_ variant: Int) -> MeshResource {
        MiniatureModels.mesh("garden-chipped-stone-\(variant)") {
            let outline: [SIMD2<Float>] = [[-0.5,-0.32],[-0.32,-0.5],[0.32,-0.5],[0.5,-0.32],
                [0.5,0.32],[0.32,0.5],[-0.32,0.5],[-0.5,0.32]]
            let rings: [(Float, Float)] = [(-0.5,0.86),(-0.30,1),(0.28,1),(0.5,0.83)]
            var points: [SIMD3<Float>] = [], indices: [UInt32] = []
            for (level, ring) in rings.enumerated() {
                for (corner, xy) in outline.enumerated() {
                    let chip: Float = level == 3 && (corner + variant * 2) % 5 == 0 ? 0.86 : 1
                    points.append([xy.x * ring.1 * chip, ring.0, xy.y * ring.1 * chip])
                }
            }
            for level in 0..<3 { for j in 0..<8 {
                let a = UInt32(level * 8 + j), b = UInt32(level * 8 + (j + 1) % 8)
                let c = a + 8, d = b + 8
                indices += [a,c,b,b,c,d]
            } }
            let bottom = UInt32(points.count); points.append([0,-0.5,0])
            let top = UInt32(points.count); points.append([0,0.5,0])
            for j in 0..<8 {
                indices += [bottom,UInt32(j),UInt32((j+1)%8),top,UInt32(24+(j+1)%8),UInt32(24+j)]
            }
            return MiniatureModels.surfaceMesh("garden-chipped-stone-\(variant)", positions: points, indices: indices)
        }
    }
    /// Closed original leaf volume with broad lobes, shared by every corner crown.
    static func foliageMesh() -> MeshResource {
        MiniatureModels.mesh("garden-lobed-foliage") {
            let longitude = 20, latitude = 12
            var positions: [SIMD3<Float>] = [], indices: [UInt32] = []
            for i in 0...latitude { for j in 0..<longitude {
                let theta = Float(i) * .pi / Float(latitude), phi = Float(j) * 2 * .pi / Float(longitude)
                let radius: Float = 1 + 0.065 * sin(theta) * sin(phi * 5 + theta * 3)
                positions.append([sin(theta) * cos(phi) * radius, cos(theta), sin(theta) * sin(phi) * radius])
            } }
            for i in 0..<latitude { for j in 0..<longitude {
                let a = UInt32(i * longitude + j), b = UInt32(i * longitude + (j+1)%longitude)
                let c = a + UInt32(longitude), d = b + UInt32(longitude)
                if i > 0 { indices += [a,b,c] }
                if i < latitude - 1 { indices += [b,d,c] }
            } }
            return MiniatureModels.surfaceMesh("garden-lobed-foliage", positions: positions, indices: indices)
        }
    }
    static func build(size n: Int) -> Entity {
        let root = Entity(); root.name = "garden-arena-\(n)"
        let edge = Float(n) + 0.55, half = edge / 2
        let flat = MiniatureModels.mesh("arena-flat-box") { .generateBox(size: 1) }
        func slab(_ name: String, _ color: UIColor, _ at: SIMD3<Float>, _ scale: SIMD3<Float>) {
            MiniatureModels.part(root, flat, color, at: at, scale: scale).name = name
        }
        slab("earth-foundation", timber, [0, -0.28, 0], [edge, 0.44, edge])
        slab("stone-plinth", darkStone, [0, -0.10, 0], [edge + 0.035, 0.12, edge + 0.035])
        slab("turf", UIColor(red: 0.32, green: 0.54, blue: 0.22, alpha: 1), [0, -0.025, 0], [edge - 0.10, 0.06, edge - 0.10])
        // Fine-grain tiles are actual low-poly surfaces, with broad continuous turf.
        for x in 0..<(2 * (n - 1)) { for z in 0..<(2 * (n - 1)) {
            let variation = CGFloat((x * 13 + z * 7) % 5) * 0.004
            let shade: CGFloat = ((x + z) % 2 == 0 ? 1 : 0.95) - variation
            let color = UIColor(red: 0.46 * shade, green: 0.69 * shade, blue: 0.27 * shade, alpha: 1)
            let at = SIMD3<Float>(Float(x) * 0.5 - Float(n - 1) / 2 + 0.25, 0.010, Float(z) * 0.5 - Float(n - 1) / 2 + 0.25)
            slab("turf-\(x)-\(z)", color, at, [0.5, 0.018, 0.5])
        } }
        for i in 0..<n {
            let offset = Float(i) - Float(n - 1) / 2
            let line = UIColor(red: 0.22, green: 0.43, blue: 0.17, alpha: 1)
            slab("grid-x-\(i)", line, [offset, 0.028, 0], [0.018, 0.009, Float(n - 1)])
            slab("grid-z-\(i)", line, [0, 0.028, offset], [Float(n - 1), 0.009, 0.018])
        }
        // Low stone edging leaves the nearest grid point clear from every camera yaw.
        for side in [-1, 1] {
            let s = Float(side), count = n + 1, pitch = (edge - 0.10) / Float(count)
            for i in 0..<count {
                let along = (Float(i) + 0.5) * pitch - (edge - 0.10) / 2
                let tint = i % 3 == 0 ? darkStone : stone
                MiniatureModels.part(root, stoneMesh(i % 3), tint, at: [s * (half - 0.16), 0.035, along], scale: [0.22, 0.16, pitch * 0.94]).name = "side-stone-\(side)-\(i)"
                MiniatureModels.part(root, stoneMesh((i + 1) % 3), tint, at: [along, 0.035, s * (half - 0.16)], scale: [pitch * 0.94, 0.16, 0.22]).name = "end-stone-\(side)-\(i)"
            }
            // Corner shrubs and small fence posts create modeled depth without covering units.
            for end in [-1, 1] {
                let z = Float(end) * (half - 0.37), x = s * (half - 0.39)
                let bush = Entity(); bush.name = "corner-shrub-\(side)-\(end)"; bush.position = [x, 0, z]
                MiniatureModels.cylinder(bush, timber, [0, 0.03, 0], radius: 0.060, height: 0.49).name = "shrub-trunk"
                MiniatureModels.part(bush, foliageMesh(), leaf, at: [0,0.43,0], scale: [0.24,0.27,0.22]).name = "foliage-body"
                MiniatureModels.part(bush, foliageMesh(), brightLeaf, at: [-s * 0.045,0.62,-Float(end) * 0.025], scale: [0.20,0.23,0.19]).name = "foliage-crown"
                for j in 0..<3 {
                    let angle = Float(j) * 2 * .pi / 3
                    MiniatureModels.part(bush, foliageMesh(), j == 1 ? brightLeaf : leaf,
                        at: [cos(angle) * 0.10,0.44,sin(angle) * 0.08], scale: [0.15,0.19,0.14]).name = "foliage-lobe-\(j)"
                }
                root.addChild(bush)
            }
            let flag = Entity(); flag.name = side < 0 ? "red-banner" : "blue-banner"
            flag.position = [s * (half - 0.40), 0, side < 0 ? -(half - 1.13) : half - 1.13]
            MiniatureModels.box(flag, darkStone, [0, 0.07, 0], [0.29, 0.16, 0.29])
            MiniatureModels.cylinder(flag, timber, [0, 0.47, 0], radius: 0.035, height: 0.80)
            MiniatureModels.ball(flag, MiniatureModels.gold, [0, 0.90, 0], [0.058, 0.065, 0.058], metal: true)
            let cloth = side < 0 ? UIColor(red: 0.76, green: 0.19, blue: 0.16, alpha: 1) : UIColor(red: 0.13, green: 0.45, blue: 0.80, alpha: 1)
            MiniatureModels.box(flag, cloth, [-s * 0.16, 0.70, 0], [0.30, 0.29, 0.030]).name = "banner-cloth"
            MiniatureModels.box(flag, MiniatureModels.gold, [-s * 0.16, 0.69, 0.025], [0.065, 0.12, 0.012], metal: true)
            root.addChild(flag)
        }
        // Sparse cut grass at the border, never attached to a playable point.
        for side in [-1, 1] { for i in 1..<(n - 1) where i % 2 == 0 {
            let offset = Float(i) - Float(n - 1) / 2
            for j in 0..<3 {
                let blade = MiniatureModels.box(root, j == 1 ? brightLeaf : leaf,
                    [Float(side) * (half - 0.39), 0.065, offset + Float(j - 1) * 0.045], [0.024, 0.12 + Float(j % 2) * 0.045, 0.028])
                blade.orientation = simd_quatf(angle: Float(j - 1) * 0.24, axis: [0, 0, 1]); blade.name = "border-grass"
            }
        } }
        return root
    }
}
