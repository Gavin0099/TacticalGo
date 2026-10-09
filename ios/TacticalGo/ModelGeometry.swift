import RealityKit
import UIKit
import simd
import TacticalGoCore

extension MiniatureModels {
    /// Closed sculpted volumes retain rounded cartoon cheeks while giving
    /// each class its own jaw and forehead proportions.
    static func headMesh(_ hero: HeroClass) -> MeshResource {
        let name = "sculpted-" + hero.rawValue.lowercased() + "-head"
        return mesh(name) {
            let sides = 32, rings = 20
            var p: [SIMD3<Float>] = [[0, 1, 0]], indices: [UInt32] = []
            func roundedSquare(_ value: Float, exponent: Float) -> Float {
                (value < 0 ? -1 : 1) * pow(abs(value), exponent)
            }
            let exponent: Float = hero == .warrior ? 0.84 : hero == .mage ? 0.95 : 0.9
            for i in 1..<rings {
                let theta = Float(i) * .pi / Float(rings), y = cos(theta)
                let jaw = 1 - max(0, -y) * (hero == .warrior ? 0.05 : hero == .mage ? 0.16 : 0.12)
                for j in 0..<sides {
                    let phi = Float(j) * 2 * .pi / Float(sides)
                    p.append([roundedSquare(cos(phi), exponent: exponent) * sin(theta) * jaw,
                              y, roundedSquare(sin(phi), exponent: exponent) * sin(theta)])
                }
            }
            for j in 0..<sides { indices += [0, UInt32(1 + (j + 1) % sides), UInt32(1 + j)] }
            for i in 0..<(rings - 2) { for j in 0..<sides {
                let a = UInt32(1 + i * sides + j), b = UInt32(1 + i * sides + (j + 1) % sides)
                let c = a + UInt32(sides), d = b + UInt32(sides)
                indices += [a, b, c, b, d, c]
            } }
            let bottom = UInt32(p.count); p.append([0, -1, 0])
            for j in 0..<sides { indices += [UInt32(1 + (rings - 2) * sides + j), UInt32(1 + (rings - 2) * sides + (j + 1) % sides), bottom] }
            return surfaceMesh(name, positions: p, indices: indices)
        }
    }
    static func sleeveMesh(left: Bool) -> MeshResource {
        let name = left ? "tailored-left-sleeve" : "tailored-right-sleeve"
        return mesh(name) {
            let profile: [(Float, Float)] = [(0, 0), (0.025, 0.5), (0.10, 0.85), (0.20, 1), (0.34, 0.98), (0.55, 0.87), (0.78, 0.75), (0.94, 0.67), (1, 0.66), (1, 0)]
            let sides = 32
            var p: [SIMD3<Float>] = [], indices: [UInt32] = []
            for (t, radius) in profile {
                for j in 0..<sides {
                    let angle = Float(j) * 2 * .pi / Float(sides)
                    p.append([(left ? -1 : 1) * t * 0.03 + cos(angle) * 0.145 * radius,
                              0.13 - t * 0.375, t * 0.095 + sin(angle) * 0.155 * radius])
                }
            }
            for i in 0..<(profile.count - 1) { for j in 0..<sides {
                let a = UInt32(i * sides + j), b = UInt32(i * sides + (j + 1) % sides)
                let c = a + UInt32(sides), d = b + UInt32(sides)
                // Profile travels downward, so winding reverses the upward lathe.
                if i > 0 { indices += [a, b, c] }
                if i < profile.count - 2 { indices += [b, d, c] }
            } }
            return surfaceMesh(name, positions: p, indices: indices)
        }
    }
    static func hairMesh() -> MeshResource {
        mesh("sculpted-warrior-hair") {
            let sides = 40, rings = 12
            var p: [SIMD3<Float>] = [[0.045, 0.17, -0.025]], indices: [UInt32] = []
            for i in 1...rings {
                let theta = Float(i) / Float(rings) * .pi / 2
                for j in 0..<sides {
                    let phi = Float(j) * 2 * .pi / Float(sides), front = max(0, sin(phi))
                    let fringe = -0.035 * (1 - front) + front * (-0.012 + 0.018 * cos(phi * 10))
                    p.append([sin(theta) * cos(phi) * 0.245 + 0.045 * cos(theta),
                              cos(theta) * 0.17 + fringe * pow(sin(theta), 6)
                                + max(0, cos(phi)) * 0.018 * sin(theta * 2),
                              sin(theta) * sin(phi) * 0.225 - 0.025 * cos(theta)])
                }
            }
            for j in 0..<sides { indices += [0, UInt32(1 + (j + 1) % sides), UInt32(1 + j)] }
            for i in 0..<(rings - 1) { for j in 0..<sides {
                let a = UInt32(1 + i * sides + j), b = UInt32(1 + i * sides + (j + 1) % sides)
                let c = a + UInt32(sides), d = b + UInt32(sides)
                indices += [a, b, c, b, d, c]
            } }
            let center = UInt32(p.count); p.append([0, -0.025, 0])
            for j in 0..<sides {
                indices += [UInt32(1 + (rings - 1) * sides + j), UInt32(1 + (rings - 1) * sides + (j + 1) % sides), center]
            }
            return surfaceMesh("sculpted-warrior-hair", positions: p, indices: indices)
        }
    }
    /// Fixed-resolution, closed cloth shells. Both sides and every boundary are
    /// modeled; these remain lit three-dimensional meshes when the camera turns.
    static func clothPanel(_ key: String, columns: Int = 24, rows: Int = 12,
                           thickness: Float = 0.018,
                           point: (Float, Float) -> SIMD3<Float>) -> MeshResource {
        mesh(key) {
            var p: [SIMD3<Float>] = [], indices: [UInt32] = []
            let stride = columns + 1, sideCount = stride * (rows + 1)
            for side in 0..<2 {
                for y in 0...rows { for x in 0...columns {
                    let position = point(Float(x) / Float(columns), Float(y) / Float(rows))
                    p.append(position + [0, 0, side == 0 ? thickness / 2 : -thickness / 2])
                } }
            }
            for y in 0..<rows { for x in 0..<columns {
                let a = UInt32(y * stride + x), b = a + 1, c = a + UInt32(stride), d = c + 1
                indices += [a, b, c, b, d, c]
                let offset = UInt32(sideCount)
                indices += [a + offset, c + offset, b + offset, b + offset, c + offset, d + offset]
            } }
            // Boundary order follows the outward front-face perimeter.
            var boundary: [UInt32] = (0...columns).map(UInt32.init)
            boundary += (1...rows).map { UInt32($0 * stride + columns) }
            boundary += (0..<columns).reversed().map { UInt32(rows * stride + $0) }
            boundary += (1..<rows).reversed().map { UInt32($0 * stride) }
            for i in boundary.indices {
                let a = boundary[i], b = boundary[(i + 1) % boundary.count]
                let c = a + UInt32(sideCount), d = b + UInt32(sideCount)
                indices += [a, c, b, b, c, d]
            }
            return surfaceMesh(key, positions: p, indices: indices)
        }
    }
    /// A real hood with an open face, inner lining and a closed rim, rather than
    /// intersecting spheres around the skin and leaving visible ear slivers.
    static func hoodMesh() -> MeshResource {
        mesh("tailored-hood") {
            let rings = 20, sides = 32, opening: Float = 0.90
            var p: [SIMD3<Float>] = [], indices: [UInt32] = []
            let sideCount = rings * sides + 1
            for side in 0..<2 {
                let radius = side == 0 ? SIMD3<Float>(0.30, 0.32, 0.265) : SIMD3<Float>(0.274, 0.294, 0.239)
                for i in 0..<rings {
                    let theta = opening + (.pi - opening) * Float(i) / Float(rings)
                    for j in 0..<sides {
                        let phi = Float(j) * 2 * .pi / Float(sides)
                        p.append(radius * [sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta)])
                    }
                }
                p.append([0, 0, -radius.z])
                let offset = UInt32(side * sideCount)
                func face(_ a: UInt32, _ b: UInt32, _ c: UInt32) {
                    indices += side == 0 ? [a + offset, b + offset, c + offset] : [a + offset, c + offset, b + offset]
                }
                for i in 0..<(rings - 1) { for j in 0..<sides {
                    let a = UInt32(i * sides + j), b = UInt32(i * sides + (j + 1) % sides)
                    let c = a + UInt32(sides), d = b + UInt32(sides)
                    face(a, c, b); face(b, c, d)
                } }
                for j in 0..<sides {
                    face(UInt32((rings - 1) * sides + j), UInt32(rings * sides), UInt32((rings - 1) * sides + (j + 1) % sides))
                }
            }
            for j in 0..<sides {
                let a = UInt32(j), b = UInt32((j + 1) % sides), c = a + UInt32(sideCount), d = b + UInt32(sideCount)
                indices += [a, b, c, b, d, c]
            }
            return surfaceMesh("tailored-hood", positions: p, indices: indices)
        }
    }
    /// Small closed equipment volumes share the same rig as their parent. These
    /// are original geometric motifs; they remain dimensional in rear views.
    static func shieldCrest(on shield: Entity, cloth: UIColor) {
        let lozenge: [SIMD2<Float>] = [[0, 0.09], [0.066, 0], [0, -0.104], [-0.066, 0]]
        part(shield, polygon("shield-crest-border", outline: lozenge, depth: 0.017), gold,
             at: [0, -0.005, 0.092], metal: true).name = "shield-crest-border"
        part(shield, polygon("shield-crest-inset", outline: lozenge.map { $0 * 0.62 }, depth: 0.008), cloth,
             at: [0, -0.005, 0.109]).name = "shield-crest-inset"
        for left in [true, false] {
            let wing: [SIMD2<Float>] = [[0.035, 0.012], [0.145, 0.080], [0.120, -0.025]]
            let outline = left ? wing.map { SIMD2<Float>(-$0.x, $0.y) }.reversed().map { $0 } : wing
            part(shield, polygon(left ? "crest-left-wing" : "crest-right-wing", outline: outline, depth: 0.010), gold,
                 at: [0, -0.005, 0.090], metal: true).name = left ? "crest-left-wing" : "crest-right-wing"
        }
    }
    static func equipmentPlate(_ key: String, halfSize: SIMD2<Float>, depth: Float) -> MeshResource {
        polygon(key, outline: [[-halfSize.x, halfSize.y], [halfSize.x, halfSize.y],
                               [halfSize.x, -halfSize.y], [-halfSize.x, -halfSize.y]], depth: depth)
    }
    static func spellbook(on root: Entity, paper: UIColor) {
        let book = Entity(); book.name = "mage-spellbook"; root.addChild(book)
        book.position = [-0.135, 0.505, 0.218]
        book.orientation = simd_quatf(angle: -0.16, axis: [0, 0, 1])
        // The back cover meets the robe/belt; a leather tab connects the
        // book's lower edge to the belt instead of leaving a floating prop.
        part(root, equipmentPlate("spellbook-belt-tab", halfSize: [0.021, 0.061], depth: 0.020), leather,
             at: [-0.135, 0.423, 0.198]).name = "spellbook-belt-tab"
        let cover = UIColor(red: 0.19, green: 0.075, blue: 0.30, alpha: 1)
        part(book, equipmentPlate("spellbook-pages", halfSize: [0.055, 0.079], depth: 0.027), paper,
             at: .zero).name = "spellbook-pages"
        for front in [false, true] {
            part(book, equipmentPlate("spellbook-cover", halfSize: [0.067, 0.092], depth: 0.008), cover,
                 at: [0, 0, front ? 0.036 : -0.036]).name = front ? "spellbook-front" : "spellbook-back"
        }
        part(book, equipmentPlate("spellbook-spine", halfSize: [0.009, 0.088], depth: 0.033), cover,
             at: [-0.062, 0, 0]).name = "spellbook-spine"
        let glyph: [SIMD2<Float>] = [[0, 0.048], [0.020, 0], [0, -0.048], [-0.020, 0]]
        part(book, polygon("spellbook-glyph", outline: glyph, depth: 0.006), gold,
             at: [0.006, 0, 0.049], metal: true).name = "spellbook-glyph"
        // Recessed page separations remain visible on the unbound right edge.
        for z: Float in [-0.014, 0, 0.014] {
            part(book, equipmentPlate("spellbook-page-edge", halfSize: [0.004, 0.069], depth: 0.0015), leather,
                 at: [0.055, 0, z]).name = "spellbook-page-edge"
        }
    }
    static func strapClasp(on strap: Entity) {
        // Strap scale is intentionally cancelled: this clasp has authored world
        // dimensions and inherits only the strap's tilt, not its box dimensions.
        let clasp = Entity(); clasp.name = "rogue-strap-clasp"
        strap.parent?.addChild(clasp); clasp.position = strap.position + [0, 0, 0.031]
        clasp.orientation = strap.orientation
        for x: Float in [-0.041, 0.041] {
            part(clasp, equipmentPlate("clasp-upright", halfSize: [0.009, 0.046], depth: 0.008), gold,
                 at: [x, 0, 0], metal: true)
        }
        for y: Float in [-0.039, 0.039] {
            part(clasp, equipmentPlate("clasp-crossbar", halfSize: [0.036, 0.007], depth: 0.008), gold,
                 at: [0, y, 0], metal: true)
        }
        part(clasp, equipmentPlate("clasp-pin", halfSize: [0.006, 0.027], depth: 0.006), gold,
             at: [0, 0.007, 0.009], metal: true)
    }
    static func tailoredPouch(on root: Entity) {
        let pouch = Entity(); pouch.name = "rogue-side-pouch"; root.addChild(pouch)
        pouch.position = [-0.27, 0.40, -0.13]
        pouch.orientation = simd_quatf(angle: -0.35, axis: [0, 0, 1])
        box(pouch, leather, .zero, [0.09, 0.25, 0.065]).name = "pouch-body"
        let flap: [SIMD2<Float>] = [[-0.050, 0.035], [0.050, 0.035], [0.043, -0.022], [0, -0.047], [-0.043, -0.022]]
        part(pouch, polygon("pouch-folded-flap", outline: flap, depth: 0.007),
             UIColor(red: 0.34, green: 0.17, blue: 0.09, alpha: 1), at: [0, 0.062, 0.039]).name = "pouch-folded-flap"
        part(pouch, polygon("pouch-clasp", outline: [[0, 0.014], [0.010, 0], [0, -0.014], [-0.010, 0]], depth: 0.005),
             gold, at: [0, 0.036, 0.052], metal: true).name = "pouch-clasp"
        for x: Float in [-0.032, 0.032] {
            for y: Float in [-0.035, -0.065] {
                part(pouch, equipmentPlate("pouch-stitch", halfSize: [0.002, 0.008], depth: 0.0015),
                     UIColor(red: 0.66, green: 0.46, blue: 0.26, alpha: 1), at: [x, y, 0.034]).name = "pouch-stitch"
            }
        }
    }

    static func surfaceMesh(_ name: String, positions: [SIMD3<Float>], indices: [UInt32]) -> MeshResource {
        var normals = [SIMD3<Float>](repeating: .zero, count: positions.count)
        for i in stride(from: 0, to: indices.count, by: 3) {
            let a = Int(indices[i]), b = Int(indices[i + 1]), c = Int(indices[i + 2])
            let normal = simd_cross(positions[b] - positions[a], positions[c] - positions[a])
            normals[a] += normal; normals[b] += normal; normals[c] += normal
        }
        normals = normals.map { simd_length($0) > 0.0000001 ? simd_normalize($0) : [0, 0, 1] }
        var descriptor = MeshDescriptor(name: name)
        descriptor.positions = MeshBuffer(positions); descriptor.normals = MeshBuffer(normals)
        descriptor.primitives = .triangles(indices)
        return try! MeshResource.generate(from: [descriptor])
    }
}
