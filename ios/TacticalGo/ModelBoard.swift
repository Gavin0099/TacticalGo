import SwiftUI
import RealityKit
import TacticalGoCore
import TacticalGoMotion

/// Original procedural model candidates. Every visible body/prop is a lit mesh,
/// shared between the tabletop and the close-up inspector; no character billboards.
@MainActor enum MiniatureModels {
    static let skin = UIColor(red: 0.96, green: 0.66, blue: 0.40, alpha: 1)
    static let leather = UIColor(red: 0.24, green: 0.11, blue: 0.065, alpha: 1)
    static let steel = UIColor(red: 0.57, green: 0.69, blue: 0.75, alpha: 1)
    static let gold = UIColor(red: 1, green: 0.65, blue: 0.13, alpha: 1)
    static let purple = UIColor(red: 0.35, green: 0.13, blue: 0.55, alpha: 1)
    static let navy = UIColor(red: 0.075, green: 0.19, blue: 0.33, alpha: 1)
    static var prototypes: [HeroClass: Entity] = [:]
    static var meshCache: [String: MeshResource] = [:]

    static func material(_ color: UIColor, metal: Bool = false) -> SimpleMaterial {
        SimpleMaterial(color: color, roughness: metal ? 0.48 : 0.72, isMetallic: metal)
    }
    @discardableResult static func part(_ parent: Entity, _ mesh: MeshResource, _ color: UIColor,
                                        at: SIMD3<Float>, scale: SIMD3<Float> = [1, 1, 1], metal: Bool = false) -> ModelEntity {
        let e = ModelEntity(mesh: mesh, materials: [material(color, metal: metal)])
        e.components.set(AuthoredSurface(color, metal: metal))
        e.position = at; e.scale = scale; parent.addChild(e); return e
    }
    static func mesh(_ key: String, make: () -> MeshResource) -> MeshResource {
        if let m = meshCache[key] { return m }
        let m = make(); meshCache[key] = m; return m
    }
    @discardableResult static func ball(_ parent: Entity, _ color: UIColor, _ at: SIMD3<Float>, _ scale: SIMD3<Float>, metal: Bool = false, smooth: Bool = false) -> ModelEntity {
        part(parent, sphere(smooth: smooth), color, at: at, scale: scale, metal: metal)
    }
    @discardableResult static func box(_ parent: Entity, _ color: UIColor, _ at: SIMD3<Float>, _ size: SIMD3<Float>, metal: Bool = false) -> ModelEntity {
        part(parent, roundedBox(), color, at: at, scale: size, metal: metal)
    }
    static func sphere(smooth: Bool = false) -> MeshResource {
        mesh(smooth ? "sphere-smooth" : "sphere") {
            let longitude = smooth ? 32 : 20, latitude = smooth ? 20 : 12
            var positions: [SIMD3<Float>] = [], indices: [UInt32] = []
            for i in 0...latitude { for j in 0..<longitude {
                let theta = Float(i) * .pi / Float(latitude), phi = Float(j) * 2 * .pi / Float(longitude)
                positions.append([sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)])
            } }
            for i in 0..<latitude { for j in 0..<longitude {
                let a = UInt32(i * longitude + j), b = UInt32(i * longitude + (j + 1) % longitude)
                let c = a + UInt32(longitude), d = b + UInt32(longitude)
                if i > 0 { indices += [a, b, c] }
                if i < latitude - 1 { indices += [b, d, c] }
            } }
            var descriptor = MeshDescriptor(name: smooth ? "sphere-1216-triangles" : "sphere-440-triangles")
            descriptor.positions = MeshBuffer(positions); descriptor.normals = MeshBuffer(positions)
            descriptor.primitives = .triangles(indices)
            return try! MeshResource.generate(from: [descriptor])
        }
    }
    static func roundedBox() -> MeshResource {
        mesh("bevelbox") {
            // Samples concentrate on the rounded edges; broad faces stay planar.
            let grid: [Float] = [-0.5, -0.484, -0.44, -0.38, 0, 0.38, 0.44, 0.484, 0.5]
            let axes: [(SIMD3<Float>, SIMD3<Float>, SIMD3<Float>)] = [
                ([1,0,0],[0,1,0],[0,0,1]), ([-1,0,0],[0,0,1],[0,1,0]),
                ([0,1,0],[0,0,1],[1,0,0]), ([0,-1,0],[1,0,0],[0,0,1]),
                ([0,0,1],[1,0,0],[0,1,0]), ([0,0,-1],[0,1,0],[1,0,0])]
            var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
            for (n, u, v) in axes {
                let base = positions.count
                for y in grid { for x in grid {
                    let cube = n * 0.5 + u * x + v * y
                    let core = SIMD3<Float>(min(0.38, max(-0.38, cube.x)), min(0.38, max(-0.38, cube.y)), min(0.38, max(-0.38, cube.z)))
                    let normal = simd_normalize(cube - core)
                    positions.append(core + normal * 0.12); normals.append(normal)
                } }
                for i in 0..<8 { for j in 0..<8 {
                    let a = UInt32(base + i * 9 + j), b = a + 1, c = a + 9, d = c + 1
                    indices += [a, b, c, b, d, c]
                } }
            }
            var descriptor = MeshDescriptor(name: "rounded-box-768-triangles")
            descriptor.positions = MeshBuffer(positions); descriptor.normals = MeshBuffer(normals)
            descriptor.primitives = .triangles(indices)
            return try! MeshResource.generate(from: [descriptor])
        }
    }
    // Revolved profile gives real tapered robes, hats, boots and crown volumes on iOS 17+.
    static func lathe(_ key: String, _ rings: [(Float, Float)], sides: Int = 24) -> MeshResource {
        mesh(key) {
            var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = [], indices: [UInt32] = []
            for i in rings.indices {
                let before = rings[max(0, i - 1)], after = rings[min(rings.count - 1, i + 1)]
                let dy = after.0 - before.0, dr = after.1 - before.1
                for j in 0..<sides {
                    let a = Float(j) * 2 * .pi / Float(sides), c = cos(a), s = sin(a)
                    positions.append([rings[i].1 * c, rings[i].0, rings[i].1 * s])
                    let n = SIMD3<Float>(dy * c, -dr, dy * s)
                    normals.append(simd_length(n) > 0 ? simd_normalize(n) : [0, 1, 0])
                }
            }
            for i in 0..<(rings.count - 1) {
                for j in 0..<sides {
                    let a = UInt32(i * sides + j), b = UInt32(i * sides + (j + 1) % sides)
                    let c = a + UInt32(sides), d = b + UInt32(sides)
                    indices += [a, c, b, b, c, d]
                }
            }
            var descriptor = MeshDescriptor(name: key)
            descriptor.positions = MeshBuffer(positions); descriptor.normals = MeshBuffer(normals)
            descriptor.primitives = .triangles(indices)
            // Profiles and topology are fixed in source, never derived from save/player data.
            return try! MeshResource.generate(from: [descriptor])
        }
    }
    @discardableResult static func cylinder(_ parent: Entity, _ color: UIColor, _ at: SIMD3<Float>, radius: Float, height: Float, metal: Bool = false) -> ModelEntity {
        let m = lathe("cylinder", [(0, 0), (0, 1), (1, 1), (1, 0)])
        return part(parent, m, color, at: at, scale: [radius, height, radius], metal: metal)
    }
    /// Closed, beveled mesh with separate facet normals for chunky equipment.
    static func polygon(_ key: String, outline: [SIMD2<Float>], depth: Float) -> MeshResource {
        mesh(key) {
            var p: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
            func triangle(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>) {
                let normal = simd_normalize(simd_cross(b - a, c - a))
                p += [a, b, c]; normals += [normal, normal, normal]
            }
            let center = outline.reduce(SIMD2<Float>.zero, +) / Float(outline.count)
            func vertex(_ i: Int, _ inset: Float, _ z: Float) -> SIMD3<Float> {
                let xy = center + (outline[i] - center) * inset; return [xy.x, xy.y, z]
            }
            for i in outline.indices {
                let j = (i + 1) % outline.count
                let a = vertex(i, 0.88, depth), b = vertex(j, 0.88, depth)
                let c = vertex(i, 1, depth * 0.55), d = vertex(j, 1, depth * 0.55)
                let e = vertex(i, 1, -depth * 0.55), f = vertex(j, 1, -depth * 0.55)
                let g = vertex(i, 0.88, -depth), h = vertex(j, 0.88, -depth)
                triangle([center.x, center.y, depth], b, a)
                triangle(a, b, c); triangle(b, d, c)
                triangle(c, d, e); triangle(d, f, e)
                triangle(e, f, g); triangle(f, h, g)
                triangle([center.x, center.y, -depth], g, h)
            }
            var descriptor = MeshDescriptor(name: key)
            descriptor.positions = MeshBuffer(p); descriptor.normals = MeshBuffer(normals)
            descriptor.primitives = .triangles(p.indices.map(UInt32.init))
            return try! MeshResource.generate(from: [descriptor])
        }
    }
    static func hero(_ hero: HeroClass) -> Entity {
        if let model = prototypes[hero] { return model.clone(recursive: true) }
        let root = Entity(); root.name = "hero-" + hero.rawValue
        let cloth = hero == .mage ? purple : hero == .rogue ? navy : UIColor(red: 0.10, green: 0.40, blue: 0.52, alpha: 1)
        // Large boots, broad chest and oversized head keep silhouettes readable at board scale.
        for x: Float in [-0.115, 0.115] {
            let side = x < 0 ? "left" : "right"
            let thigh = Entity(); thigh.name = side + "-thigh"; thigh.position = [x, 0.35, 0]; root.addChild(thigh)
            let calf = Entity(); calf.name = side + "-calf"; calf.position = [0, -0.12, 0]; thigh.addChild(calf)
            let foot = Entity(); foot.name = side + "-foot"; foot.position = [0, -0.12, 0]; calf.addChild(foot)
            let upper = cylinder(root, cloth, [x, 0.225, 0], radius: 0.077, height: 0.16)
            upper.setParent(thigh, preservingWorldTransform: true)
            let lower = cylinder(root, cloth, [x, 0.10, 0], radius: 0.078, height: 0.145)
            lower.setParent(calf, preservingWorldTransform: true)
            let outline: [SIMD2<Float>] = [[-0.085, 0.17], [0.085, 0.17], [0.105, 0.13], [0.105, -0.09],
                                          [0.075, -0.13], [-0.075, -0.13], [-0.105, -0.09], [-0.105, 0.13]]
            let sole = part(root, polygon("tailored-boot-sole", outline: outline, depth: 0.025), leather, at: [x, 0.04, 0.06])
            sole.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
            var boot: [ModelEntity] = [sole, ball(root, leather, [x, 0.105, 0.095], [0.10, 0.075, 0.15]),
                cylinder(root, leather, [x, 0.11, 0], radius: 0.09, height: 0.065),
                cylinder(root, leather, [x, 0.15, 0], radius: 0.095, height: 0.026)]
            if hero == .warrior { boot.append(ball(root, steel, [x, 0.125, 0.145], [0.09, 0.035, 0.10], metal: true)) }
            for part in boot { part.setParent(foot, preservingWorldTransform: true) }
        }
        if hero == .mage {
            part(root, lathe("robe", [(0, 0), (0, 0.28), (0.08, 0.27), (0.5, 0.17), (0.56, 0.14), (0.56, 0)]), purple, at: [0, 0.17, 0])
            box(root, gold, [0, 0.29, 0.280], [0.065, 0.09, 0.025], metal: true)
        } else {
            part(root, lathe("tailored-tunic", [(0, 0), (0, 0.78), (0.03, 0.96), (0.12, 1), (0.28, 0.96), (0.38, 0.76), (0.44, 0.48), (0.45, 0)], sides: 32), cloth, at: [0, 0.28, 0], scale: [0.235, 1, 0.17])
            if hero == .warrior {
                part(root, lathe("fitted-cuirass", [(0, 0), (0, 0.82), (0.012, 0.96), (0.04, 1), (0.16, 0.97), (0.26, 0.76), (0.31, 0.46), (0.325, 0)], sides: 32), steel, at: [0, 0.445, 0.035], scale: [0.24, 1, 0.215], metal: true)
                cylinder(root, gold, [0, 0.69, 0], radius: 0.105, height: 0.055, metal: true)
            }
        }
        cylinder(root, leather, [0, 0.38, 0], radius: 0.237, height: 0.085)
        box(root, gold, [0, 0.425, 0.255], [0.10, 0.075, 0.045], metal: true)
        for x: Float in [-0.28, 0.28] {
            let arm = Entity(); arm.name = x < 0 ? "left-arm" : "right-arm"
            arm.position = [x, 0.64, 0]; root.addChild(arm)
            var sleeveParts: [ModelEntity] = []
            if hero == .warrior {
                let shoulder = ball(root, steel, [x, 0.64, 0], [0.15, 0.155, 0.16], metal: true)
                shoulder.orientation = simd_quatf(angle: x < 0 ? -0.2 : 0.2, axis: [0, 0, 1])
                sleeveParts = [shoulder, ball(root, cloth, [x * 1.08, 0.49, 0.07], [0.09, 0.17, 0.09])]
            } else {
                sleeveParts = [part(root, sleeveMesh(left: x < 0), cloth, at: [x, 0.64, 0])]
            }
            let hand = ball(root, skin, [x * 1.15, 0.37, 0.13], [0.10, 0.105, 0.105])
            let thumb = ball(root, skin, [x * 0.94, 0.425, 0.19], [0.052, 0.067, 0.045])
            let cuff = cylinder(root, hero == .warrior ? leather : gold, [x * 1.1, 0.405, 0.1], radius: 0.10, height: 0.065, metal: hero == .mage)
            for part in sleeveParts + [hand, thumb, cuff] { part.setParent(arm, preservingWorldTransform: true) }
            if x > 0 {
                // Three curled fingers visibly wrap the grip instead of placing
                // the weapon through a featureless sphere.
                for i in 0..<3 {
                    let finger = ball(root, skin, [0.365, 0.315 + Float(i) * 0.030, 0.224], [0.060, 0.020, 0.035])
                    finger.setParent(arm, preservingWorldTransform: true)
                }
            }
        }
        cylinder(root, skin, [0, 0.70, 0], radius: 0.10, height: 0.13)
        if hero == .rogue { part(root, hoodMesh(), navy, at: [0, 0.94, -0.015]) }
        let faceScale: SIMD3<Float> = hero == .warrior ? [0.237, 0.235, 0.210] : hero == .mage ? [0.218, 0.240, 0.209] : [0.215, 0.228, 0.210]
        part(root, headMesh(hero), skin, at: [0, 0.91, 0.07], scale: faceScale)
        // Face is modeled geometry, including nose, brows, eyes and a small smile.
        ball(root, skin, [0, 0.90, 0.275], hero == .rogue ? [0.050, 0.059, 0.060] : hero == .mage ? [0.057, 0.069, 0.066] : [0.065, 0.061, 0.070])
        let ivory = UIColor(red: 0.86, green: 0.83, blue: 0.72, alpha: 1)
        for x: Float in [-0.085, 0.085] {
            let eyeHeight: Float = hero == .rogue ? 0.045 : hero == .mage ? 0.051 : 0.050
            ball(root, .white, [x, 0.96, 0.258], [0.045, eyeHeight, 0.027])
            ball(root, UIColor(red: 0.045, green: 0.07, blue: 0.09, alpha: 1), [x + (hero == .rogue ? 0.004 : 0), 0.956, 0.283], [0.022, eyeHeight * 0.60, 0.012])
            ball(root, .white, [x - 0.009, 0.971, 0.294], [0.008, 0.01, 0.005])
            let brow = part(root, polygon("tapered-expression-brow", outline: [[-0.5, 0.05], [-0.4, 0.23], [0.12, 0.3], [0.5, 0.05], [0.40, -0.13], [-0.45, -0.10]], depth: 0.07), hero == .mage ? ivory : leather,
                            at: [x, hero == .mage ? 1.028 : 1.025, 0.262], scale: [hero == .warrior ? 0.103 : 0.092, 0.07, 0.15])
            let browAngle: Float = hero == .rogue ? 0.24 : hero == .mage ? -0.10 : 0.16
            brow.orientation = simd_quatf(angle: x < 0 ? -browAngle : browAngle, axis: [0, 0, 1])
            if hero != .rogue { ball(root, skin, [x < 0 ? -0.23 : 0.23, 0.93, 0.04], [0.054, 0.078, 0.051]) }
        }
        ball(root, leather, [0, 0.815, 0.268], [0.047, 0.018, 0.012])
        switch hero {
        case .warrior:
            part(root, hairMesh(), leather, at: [0, 1.07, 0.005])
            ball(root, .white, [0, 0.826, 0.274], [0.036, 0.008, 0.01])
            // Layered leather cape and armor studs give the rear a readable silhouette.
            let cape = clothPanel("warrior-folded-cape") { u, v in
                let x = (u - 0.5) * (0.50 - v * 0.20)
                return [x, -0.24 + v * 0.48, -0.14 + v * 0.14 + cos(u * 6 * .pi) * 0.015 * (1 - v)]
            }
            part(root, cape, leather, at: [0, 0.47, -0.18]).name = "cape-shell"
            for x: Float in [-0.14, 0.14] { ball(root, gold, [x, 0.65, 0.22], [0.025, 0.025, 0.025], metal: true) }
            // Wide layered shield, modeled with a tapered lower tip and raised emblem.
            let shield = Entity(); root.addChild(shield); shield.position = [-0.35, 0.43, 0.26]
            shield.name = "shield"
            shield.orientation = simd_quatf(angle: -0.15, axis: [0, 0, 1])
            let outline: [SIMD2<Float>] = [[-0.21, 0.20], [0.21, 0.20], [0.20, -0.10], [0, -0.28], [-0.20, -0.10]]
            part(shield, polygon("warrior-shield-gold", outline: outline, depth: 0.06), gold, at: .zero, metal: true)
            part(shield, polygon("warrior-shield-face", outline: outline.map { $0 * 0.80 }, depth: 0.012), cloth, at: [0, 0, 0.066])
            shieldCrest(on: shield, cloth: cloth)
            for x: Float in [-0.14, 0.14] { ball(shield, gold, [x, 0.135, 0.072], [0.021, 0.021, 0.013], metal: true) }
            shield.setParent(root.findEntity(named: "left-arm"), preservingWorldTransform: true)
            sword(root, at: [0.36, 0.44, 0.18], short: false)
        case .mage:
            ball(root, ivory, [0, 1.075, -0.02], [0.22, 0.13, 0.20])
            for x: Float in [-0.21, 0.21] { ball(root, ivory, [x, 0.91, -0.01], [0.055, 0.16, 0.12]) }
            ball(root, ivory, [0, 0.775, 0.245], [0.054, 0.072, 0.032]).name = "face-goatee"
            for x: Float in [-0.033, 0.033] {
                let moustache = ball(root, ivory, [x, 0.839, 0.284], [0.050, 0.021, 0.019])
                moustache.orientation = simd_quatf(angle: x < 0 ? 0.12 : -0.12, axis: [0, 0, 1])
            }
            cylinder(root, purple, [0, 1.105, 0.01], radius: 0.34, height: 0.06)
            let hat = part(root, lathe("mage-hat", [(0, 0), (0, 0.235), (0.05, 0.24), (0.33, 0.11), (0.45, 0.035), (0.47, 0)]), purple, at: [0, 1.14, 0])
            hat.orientation = simd_quatf(angle: -0.12, axis: [0, 0, 1])
            cylinder(hat, gold, [0, 0.03, 0], radius: 0.233, height: 0.05, metal: true)
            let staff = cylinder(root, leather, [0.37, 0.08, 0.12], radius: 0.035, height: 1.03)
            staff.name = "staff"
            staff.orientation = simd_quatf(angle: -0.08, axis: [0, 0, 1])
            let socket = cylinder(root, gold, [0.42, 1.03, 0.12], radius: 0.095, height: 0.08, metal: true)
            let gem = part(root, crystalMesh(), .cyan, at: [0.43, 1.18, 0.12], metal: true)
            gem.name = "crystal"
            gem.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])
            for prop in [staff, socket, gem] { prop.setParent(root.findEntity(named: "right-arm"), preservingWorldTransform: true) }
            let cape = clothPanel("mage-folded-cape") { u, v in
                return [(u - 0.5) * (0.48 - v * 0.25), -0.265 + v * 0.53,
                        -0.14 + v * 0.12 + cos(u * 6 * .pi) * 0.012 * (1 - v)]
            }
            part(root, cape, purple, at: [0, 0.475, -0.18]).name = "cape-shell"
            for x: Float in [-0.075, 0.075] {
                let collar = box(root, gold, [x, 0.625, 0.18], [0.11, 0.035, 0.05], metal: true)
                collar.name = x < 0 ? "mage-collar-left" : "mage-collar-right"
                collar.orientation = simd_quatf(angle: x < 0 ? -0.45 : 0.45, axis: [0, 0, 1])
            }
            let badge = box(hat, gold, [-0.10, 0.09, 0.212], [0.04, 0.06, 0.02], metal: true)
            badge.orientation = simd_quatf(angle: .pi / 4, axis: [0, 0, 1])
            spellbook(on: root, paper: ivory)
        case .rogue:
            let mask = clothPanel("rogue-tailored-mask") { u, v in
                let angle = (u - 0.5) * 2.4, center = cos(angle)
                return [sin(angle) * 0.218, -0.055 + v * 0.12 - v * 0.025 * center * center,
                        (0.225 - v * 0.015) * center + sin(v * .pi) * 0.008]
            }
            part(root, mask, navy, at: [0, 0.80, 0.075])
            let scarf = box(root, navy, [0.23, 0.70, -0.19], [0.22, 0.14, 0.10])
            scarf.orientation = simd_quatf(angle: -0.4, axis: [0, 0, 1])
            let strap = box(root, leather, [0, 0.60, 0.185], [0.070, 0.29, 0.025])
            strap.orientation = simd_quatf(angle: -0.55, axis: [0, 0, 1])
            strapClasp(on: strap)
            sword(root, at: [0.36, 0.42, 0.19], short: true)
            let cape = clothPanel("rogue-folded-cape") { u, v in
                return [(u - 0.5) * (0.42 - v * 0.15), -0.22 + v * 0.44,
                        -0.14 + v * 0.13 + cos(u * 4 * .pi) * 0.012 * (1 - v)]
            }
            part(root, cape, navy, at: [0, 0.49, -0.19]).name = "cape-shell"
            // Hip-mounted pouch stays clear of the cloak's outward motion.
            tailoredPouch(on: root)
        case .none: break
        }
        if let shell = root.findEntity(named: "cape-shell") {
            let cape = Entity(); cape.name = "cape"; cape.position = [0, 0.735, -0.18]
            root.addChild(cape); shell.setParent(cape, preservingWorldTransform: true)
        }
        let head = Entity(); head.name = "head"; head.position = [0, 0.91, 0.07]
        let headParts = root.children.filter { $0.name.hasPrefix("face-") || ($0.name.isEmpty && $0.position.y >= 0.78 && abs($0.position.x) < 0.27) }
        root.addChild(head)
        for part in headParts { part.setParent(head, preservingWorldTransform: true) }
        prototypes[hero] = root; return root.clone(recursive: true)
    }
    static func crystalMesh() -> MeshResource {
        mesh("faceted-crystal") {
            let ring: [SIMD3<Float>] = [[-0.10, 0, -0.10], [0.10, 0, -0.10], [0.10, 0, 0.10], [-0.10, 0, 0.10]]
            var positions: [SIMD3<Float>] = [], normals: [SIMD3<Float>] = []
            for i in 0..<4 {
                let j = (i + 1) % 4
                for vertices in [[SIMD3<Float>(0, 0.17, 0), ring[j], ring[i]], [SIMD3<Float>(0, -0.10, 0), ring[i], ring[j]]] {
                    let normal = simd_normalize(simd_cross(vertices[1] - vertices[0], vertices[2] - vertices[0]))
                    positions += vertices; normals += [normal, normal, normal]
                }
            }
            var descriptor = MeshDescriptor(name: "faceted-crystal")
            descriptor.positions = MeshBuffer(positions); descriptor.normals = MeshBuffer(normals)
            descriptor.primitives = .triangles(positions.indices.map(UInt32.init))
            return try! MeshResource.generate(from: [descriptor])
        }
    }
    static func sword(_ parent: Entity, at: SIMD3<Float>, short: Bool) {
        let root = Entity(); parent.addChild(root); root.position = at
        root.name = "weapon"
        root.orientation = simd_quatf(angle: -0.18, axis: [0, 0, 1])
        cylinder(root, leather, [0, -0.09, 0], radius: 0.04, height: 0.18)
        box(root, gold, [0, 0.1, 0], [0.23, 0.05, 0.075], metal: true)
        let length: Float = short ? 0.36 : 0.62
        part(root, polygon(short ? "dagger-blade" : "sword-blade", outline: [[0, length], [0.048, length - 0.13], [0.042, 0], [-0.042, 0], [-0.048, length - 0.13]], depth: 0.022), steel, at: [0, 0.125, 0], metal: true)
        root.setParent(parent.findEntity(named: "right-arm"), preservingWorldTransform: true)
    }
    static func piece(_ piece: Piece, heroClass: HeroClass, sourceOnly: Bool = false) -> Entity {
        if !sourceOnly, let imported = ModelLibrary.unit(piece) { return imported }
        let root = Entity(), team = UIColor(piece.owner == .one ? Color.blueTeam : Color.redTeam)
        cylinder(root, gold, [0, 0, 0], radius: 0.32, height: 0.055, metal: true)
        cylinder(root, team, [0, 0.055, 0], radius: 0.295, height: 0.06)
        if piece.kind == .hero {
            let h = renderedHero(heroClass); h.scale = [0.62, 0.62, 0.62]; h.position.y = 0.115; root.addChild(h)
        } else {
            let body = trooper(commander: piece.kind == .commander, owner: piece.owner)
            body.position.y = 0.115; root.addChild(body)
        }
        if piece.owner == .one { ball(root, .white, [0, 0.10, 0.29], [0.035, 0.015, 0.025]) }
        else { box(root, .white, [0, 0.10, 0.29], [0.065, 0.025, 0.035]).orientation = simd_quatf(angle: .pi / 4, axis: [0, 1, 0]) }
        return root
    }
    /// Compact original tabletop guards keep a smaller silhouette than heroes.
    /// Equipment is geometry and has no gameplay collision or attack behavior.
    static func trooper(commander: Bool, owner: Player) -> Entity {
        let root = Entity(); root.name = commander ? "commander-miniature" : "soldier-miniature"
        let team = UIColor(owner == .one ? Color.blueTeam : Color.redTeam)
        let cloth = owner == .one ? navy : UIColor(red: 0.55, green: 0.10, blue: 0.095, alpha: 1)
        let armor = owner == .one ? steel : UIColor(red: 0.79, green: 0.73, blue: 0.59, alpha: 1)
        root.scale = SIMD3(repeating: commander ? 0.64 : 0.53)
        for x: Float in [-0.105, 0.105] {
            ball(root, cloth, [x, 0.15, 0], [0.080, 0.12, 0.083])
            box(root, leather, [x, 0.045, 0.035], [0.16, 0.09, 0.23]).name = "guard-boot"
        }
        part(root, lathe("guard-tunic", [(0, 0), (0, 0.18), (0.07, 0.22), (0.32, 0.18), (0.37, 0.11), (0.37, 0)]),
             cloth, at: [0, 0.18, 0])
        ball(root, armor, [0, 0.405, 0.035], [0.205, 0.19, 0.125], metal: true).name = "guard-breastplate"
        box(root, leather, [0, 0.265, 0.10], [0.40, 0.065, 0.15])
        box(root, gold, [0, 0.27, 0.189], [0.09, 0.075, 0.025], metal: true)
        for x: Float in [-0.23, 0.23] {
            ball(root, armor, [x, 0.465, 0], [0.12, 0.095, 0.12], metal: true)
            ball(root, cloth, [x * 1.10, 0.365, 0.025], [0.074, 0.14, 0.075])
            ball(root, skin, [x * 1.13, 0.27, 0.10], [0.073, 0.075, 0.068])
        }
        part(root, headMesh(commander ? .warrior : .rogue), skin, at: [0, 0.67, 0.025],
             scale: [0.165, 0.18, 0.15]).name = "guard-head"
        for x: Float in [-0.058, 0.058] {
            ball(root, .white, [x, 0.687, 0.163], [0.027, 0.037, 0.018])
            ball(root, .black, [x, 0.684, 0.181], [0.013, 0.023, 0.007])
        }
        ball(root, skin, [0, 0.645, 0.183], [0.035, 0.031, 0.038])
        if commander {
            // A broad five-point crown reads from the locked near-overhead camera.
            part(root, lathe("commander-crown-band", [(0, 0.143), (0, 0.19), (0.09, 0.195), (0.09, 0.15), (0, 0.143)], sides: 32),
                 gold, at: [0, 0.80, 0.025], metal: true)
            for i in 0..<5 {
                let a = Float(i) * 2 * .pi / 5
                let tooth = part(root, polygon("commander-crown-point", outline: [[-0.055, 0], [0.055, 0], [0.038, 0.08], [0, 0.16], [-0.038, 0.08]], depth: 0.045),
                                 gold, at: [sin(a) * 0.177, 0.855, 0.025 + cos(a) * 0.177], metal: true)
                tooth.orientation = simd_quatf(angle: a, axis: [0, 1, 0])
            }
            ball(root, team, [0, 0.845, 0.226], [0.038, 0.035, 0.020], metal: true)
            for x: Float in [-0.032, 0.032] {
                ball(root, leather, [x, 0.590, 0.168], [0.040, 0.014, 0.018])
            }
            part(root, clothPanel("commander-short-cape") { u, v in
                [(u - 0.5) * (0.38 - v * 0.06), v * 0.31, -0.05 + v * 0.045 + cos(u * 4 * .pi) * 0.009]
            }, team, at: [0, 0.205, -0.20])
        } else {
            part(root, lathe("guard-helmet", [(0, 0.175), (0, 0.19), (0.025, 0.20), (0.10, 0.17), (0.15, 0.10), (0.17, 0)], sides: 32),
                 armor, at: [0, 0.75, 0.025], metal: true)
            box(root, team, [0, 0.90, 0.015], [0.07, 0.07, 0.17]).name = "guard-crest"
        }
        let shield = part(root, polygon("guard-thick-shield", outline: [[-0.11, 0.12], [0.11, 0.12], [0.11, -0.06], [0, -0.16], [-0.11, -0.06]], depth: 0.035),
                          armor, at: [-0.24, 0.31, 0.18], metal: true)
        part(shield, polygon("guard-shield-face", outline: [[-0.082, 0.095], [0.082, 0.095], [0.082, -0.048], [0, -0.12], [-0.082, -0.048]], depth: 0.014), team, at: [0, 0, 0.025])
        box(root, leather, [0.257, 0.26, 0.10], [0.035, 0.16, 0.04])
        box(root, gold, [0.257, 0.35, 0.10], [0.115, 0.025, 0.05], metal: true)
        part(root, polygon("guard-short-blade", outline: [[-0.028, 0], [0.028, 0], [0.028, 0.23], [0, 0.29], [-0.028, 0.23]], depth: 0.014), armor,
             at: [0.257, 0.365, 0.10], metal: true)
        return root
    }
}

@MainActor final class TabletopView: ARView {
    let world = AnchorEntity(world: .zero), camera = PerspectiveCamera(), content = Entity()
    let keyLight = DirectionalLight()
    var presentation: BoardPresentation?
    var select: ((Point) -> Void)?
    var inspector = false
    var inspectedHero: HeroClass?
    var inspectionMotionID: UUID?
    var inspectionMotionStart: CFTimeInterval?
    var inspectionIdleStart: CFTimeInterval?
    var inspectionIdleCompletedID: UUID?
    var inspectionPose: MiniaturePose?
    var inspectionResourceID: ObjectIdentifier?
    var inspectionResourceEntity: Entity?
    var inspectionResourceRest: [(ModelEntity, [Transform])] = []
    #if DEBUG
    var inspectionTraceTask: Task<Void, Never>?
    var inspectionTraceID: UUID?
    #endif
    var yaw: Float = 0
    var zoom: Float = 1
    var focusPoint: Point?
    var panOffset = SIMD2<Float>.zero
    var panChanged: ((SIMD2<Float>) -> Void)?
    private var panGroundAnchor: SIMD3<Float>?
    private var panLimits: (minimum: SIMD2<Float>, maximum: SIMD2<Float>)?
    private lazy var boardPan = UIPanGestureRecognizer(target: self, action: #selector(panBoard(_:)))
    private weak var coordinatedScroll: UIScrollView?
    var renderedState: GameState?
    var units: [Point: Entity] = [:]
    var overlayNodes: [Entity] = []
    var sealNodes: [Point: Entity] = [:]
    var playbackID: UUID?
    var playedReceipts: Set<UUID> = []
    var activePlayback: BoardPlayback?
    var renderLease: UUID?
    var motionStart: CFTimeInterval = 0
    var motionRate: Double = 1
    var motionNodes: [Entity] = []
    var captureActors: [Point: Entity] = [:]
    var cueEffects: [Int: Entity] = [:]
    var displayLink: CADisplayLink?
    var posedParts: [(Entity, Transform)] = []
    var posedSkeletons: [SkeletonPose] = []
    #if DEBUG
    private var panReceipts: [[String: Any]] = []
    private var captureReady = false
    private var captureCheckScheduled = false
    private var captureAttempts = 0
    #endif
    init() {
        super.init(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        // SwiftUI exposes one named arena and an explicit accessible cell list.
        // Metal's private rendering subviews are not independent UI targets.
        isAccessibilityElement = false; accessibilityElements = []; accessibilityElementsHidden = true
        environment.background = .color(UIColor(red: 0.075, green: 0.17, blue: 0.21, alpha: 1))
        renderOptions.insert(.disableMotionBlur)
        scene.addAnchor(world); world.addChild(camera); world.addChild(content)
        let key = keyLight; key.light.color = .init(red: 1, green: 0.91, blue: 0.78, alpha: 1); key.light.intensity = 2200
        key.shadow = .init(maximumDistance: 24, depthBias: 1)
        key.look(at: [0, 0, 0], from: [-5, 9, 6], relativeTo: nil); world.addChild(key)
        let fill = DirectionalLight(); fill.light.color = .init(red: 0.61, green: 0.80, blue: 1, alpha: 1); fill.light.intensity = 1100
        fill.look(at: [0, 0.4, 0], from: [4, 5, -4], relativeTo: nil); world.addChild(fill)
        boardPan.maximumNumberOfTouches = 1
        boardPan.isEnabled = false
        addGestureRecognizer(boardPan)
        let boardTap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        boardTap.require(toFail: boardPan)
        addGestureRecognizer(boardTap)
    }
    required init?(coder: NSCoder) { fatalError("Programmatic view only") }
    @available(*, unavailable) required init(frame: CGRect) { fatalError("Use init()") }
    override func layoutSubviews() {
        super.layoutSubviews(); coordinateBoardScroll(); positionCamera(); markReviewCaptureReady()
    }
    private func coordinateBoardScroll() {
        var ancestor = superview
        while let node = ancestor {
            if let scroll = node as? UIScrollView {
                if coordinatedScroll !== scroll {
                    // Outside the arena the child receives no touches, so the
                    // page still scrolls. At full scale the child is disabled.
                    scroll.panGestureRecognizer.require(toFail: boardPan)
                    coordinatedScroll = scroll
                }
                return
            }
            ancestor = node.superview
        }
    }
    private var boardFocus: SIMD3<Float> {
        let size = presentation?.state.board.size ?? 7
        let point = zoom > 1 ? focusPoint.map { Self.position($0, size: size) } : nil
        let offset = zoom > 1 ? panOffset : .zero
        let half = Float(size - 1) / 2
        return [min(half, max(-half, (point?.x ?? 0) + offset.x)), 0.08,
                min(half, max(-half, (point?.z ?? 0) + offset.y))]
    }
    private func groundPoint(_ screenPoint: CGPoint) -> SIMD3<Float>? {
        guard let ray = ray(through: screenPoint), abs(ray.direction.y) > 0.0001 else { return nil }
        let t = (0.035 - ray.origin.y) / ray.direction.y
        let point = ray.origin + ray.direction * t
        return t >= 0 && point.x.isFinite && point.z.isFinite ? point : nil
    }
    @objc private func panBoard(_ gesture: UIPanGestureRecognizer) {
        guard !inspector, zoom > 1, let data = presentation else { return }
        switch gesture.state {
        case .began:
            panGroundAnchor = groundPoint(gesture.location(in: self))
            let focus = boardFocus
            let corners = [CGPoint(x: 0, y: bounds.midY), CGPoint(x: bounds.width, y: bounds.midY),
                           CGPoint(x: bounds.midX, y: 0), CGPoint(x: bounds.midX, y: bounds.height)]
                .compactMap(groundPoint)
            guard corners.count == 4 else { panGroundAnchor = nil; return }
            let half = Float(data.state.board.size - 1) / 2
            let arenaHalf = (Float(data.state.board.size) + 0.59) / 2
            // Mid-edge rays bound useful travel without forbidding horizontal
            // movement when perspective corners extend beyond the ground.
            // Include the starting focus so an orthogonal drag cannot snap it.
            let reference = focusPoint.map { Self.position($0, size: data.state.board.size) } ?? .zero
            func range(_ offsets: [Float], current: Float, reference: Float) -> (Float, Float) {
                let low = max(-half, -arenaHalf - offsets.min()!)
                let high = min(half, arenaHalf - offsets.max()!)
                return low <= high ? (min(low, min(current, reference)), max(high, max(current, reference))) : (current, current)
            }
            let x = range(corners.map { $0.x - focus.x }, current: focus.x, reference: reference.x)
            let z = range(corners.map { $0.z - focus.z }, current: focus.z, reference: reference.z)
            panLimits = ([x.0, z.0], [x.1, z.1])
        case .changed:
            guard let anchor = panGroundAnchor, let limits = panLimits, let now = groundPoint(gesture.location(in: self)) else { return }
            let base = focusPoint.map { Self.position($0, size: data.state.board.size) } ?? .zero
            let focus = boardFocus + anchor - now
            panOffset = [min(limits.maximum.x, max(limits.minimum.x, focus.x)) - base.x,
                         min(limits.maximum.y, max(limits.minimum.y, focus.z)) - base.z]
            positionCamera(); panChanged?(panOffset)
        case .ended, .cancelled, .failed:
            panGroundAnchor = nil
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--pan-receipt") {
                let focus = boardFocus
                let center = project(Self.position(Point(data.state.board.size / 2, data.state.board.size / 2), size: data.state.board.size))
                panReceipts.append(["pid": ProcessInfo.processInfo.processIdentifier, "endedAtUnix": Date().timeIntervalSince1970, "size": data.state.board.size, "focus": [focus.x, focus.y, focus.z],
                    "camera": [camera.position.x, camera.position.y, camera.position.z],
                    "panMinimum": panLimits.map { [$0.minimum.x, $0.minimum.y] } ?? [],
                    "panMaximum": panLimits.map { [$0.maximum.x, $0.maximum.y] } ?? [],
                    "centerProjection": center.map { [$0.x, $0.y] } ?? [],
                    "selected": data.selected.map { [$0.x, $0.y] }, "diagram": data.state.board.diagram,
                    "ap": data.state.apRemaining, "mana": data.state.mana(of: data.state.current),
                    "gestureState": gesture.state.rawValue])
                do {
                    let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    try JSONSerialization.data(withJSONObject: Array(panReceipts.suffix(64)), options: [.prettyPrinted, .sortedKeys])
                        .write(to: folder.appendingPathComponent("board-pan-\(ProcessInfo.processInfo.processIdentifier)-\(data.state.board.size).json"), options: .atomic)
                } catch { print("Pan receipt failed:", error) }
            }
            #endif
        default: break
        }
    }
    /// A debug capture must wait for the requested native board to be mounted
    /// and foreground, then still allow rendering time and visual inspection.
    private func markReviewCaptureReady() {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard !captureReady, let index = args.firstIndex(of: "--capture-ready-token"), index + 1 < args.count,
              UUID(uuidString: args[index + 1]) != nil else { return }
        let size = args.contains("--nine") ? 9 : 7
        let review: GameStore.Review = args.contains("--danger") ? .danger : args.contains("--skill") ? .skill : .normal
        let expected = GameStore.scenario(size: size, review: review)
        let expectedSelection = review == .skill ? [Point(4, 3)] : []
        let wantsModel = args.contains("--capture-model")
        let heroIndex = args.firstIndex(of: "--model-class")
        let expectedHero = heroIndex.flatMap { $0 + 1 < args.count ? HeroClass(rawValue: args[$0 + 1]) : nil } ?? .warrior
        let requestedMounted = wantsModel
            ? inspector && inspectedHero == expectedHero && content.children.contains(where: { $0.name.hasPrefix("hero-") })
                && (!(args.contains("--identity-models") || args.contains("--rig-models") || args.contains("--package-models") || args.contains("--source-models")) || inspectionResourceEntity != nil)
            : !inspector && renderedState == expected && presentation?.selected == expectedSelection
        guard requestedMounted, window != nil, bounds.width > 0, bounds.height > 0, UIApplication.shared.applicationState == .active else {
            guard !captureCheckScheduled, captureAttempts < 100 else { return }
            captureCheckScheduled = true; captureAttempts += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.captureCheckScheduled = false; self?.markReviewCaptureReady()
            }
            return
        }
        do {
            let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            var receipt: [String: Any] = ["token": args[index + 1], "size": size, "review": review.rawValue,
                "diagram": presentation?.state.board.diagram ?? "", "nativeUnits": units.count,
                "viewport": [bounds.width, bounds.height], "foreground": true,
                "claim": "requested native board mounted in active app; screenshot pixels still need visual review"]
            receipt["cameraYawRadians"] = yaw
            receipt["shadowDepthBias"] = keyLight.shadow?.depthBias
            receipt["keyShadowEnabled"] = keyLight.components[DirectionalLightComponent.Shadow.self] != nil
            if #available(iOS 18.0, *) {
                receipt["shadowCullOverride"] = keyLight.shadow.map { String(describing: $0.cullModeOverride) } ?? "no-shadow"
            }
            if wantsModel {
                receipt["modelHero"] = expectedHero.rawValue
                receipt["claim"] = "requested native model mounted in active app; screenshot pixels still need visual review"
                if let imported = inspectionResourceEntity {
                    receipt["nativeClips"] = imported.availableAnimations.map { ["name": $0.definition.name, "durationSeconds": $0.definition.duration] }
                    let skins = SkeletonPose.collect(imported)
                    receipt["nativeSkinMeshCount"] = skins.count
                    receipt["nativeJointLeafNames"] = Array(Set(skins.flatMap { $0.model.jointNames.map { $0.split(separator: "/").last.map(String.init) ?? $0 } })).sorted()
                }
            }
            try JSONSerialization.data(withJSONObject: receipt, options: [.prettyPrinted, .sortedKeys])
                .write(to: folder.appendingPathComponent("capture-ready-" + args[index + 1] + ".json"), options: .atomic)
            captureReady = true
        } catch { print("Review capture readiness failed:", error) }
        #endif
    }
    func positionCamera() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        camera.camera.fieldOfViewInDegrees = inspector ? 34 : 38
        // The portrait inspector needs precision at character scale rather than
        // a board-sized shadow range; gameplay still covers the whole arena.
        var bias: Float = 1
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if inspector, let i = args.firstIndex(of: "--shadow-bias"), i + 1 < args.count,
           let value = Float(args[i + 1]), value.isFinite { bias = min(4, max(0.5, value)) }
        #endif
        var shadow = DirectionalLightComponent.Shadow(maximumDistance: inspector ? 6 : 24, depthBias: bias)
        #if DEBUG
        if #available(iOS 18.0, *), let index = args.firstIndex(of: "--shadow-cull"), index + 1 < args.count {
            switch args[index + 1] {
            case "front": shadow.cullModeOverride = .front
            case "back": shadow.cullModeOverride = .back
            case "none": shadow.cullModeOverride = .some(.none)
            default: break
            }
        }
        #endif
        keyLight.shadow = shadow
        #if DEBUG
        if inspector && args.contains("--shadow-disabled") { keyLight.components.remove(DirectionalLightComponent.Shadow.self) }
        #endif
        if inspector {
            camera.look(at: [0, 0.8, 0], from: [sin(yaw) * 3.8, 1.8, cos(yaw) * 3.8], relativeTo: nil)
        } else {
            let size = presentation?.state.board.size ?? 7
            let focus = boardFocus
            let at = ArenaCamera.position(size: size, viewport: bounds.size, yaw: yaw, zoom: zoom, focus: focus)
            camera.look(at: focus, from: at, relativeTo: nil)
        }
    }
    static func position(_ point: Point, size: Int) -> SIMD3<Float> {
        [Float(point.x) - Float(size - 1) / 2, 0.035, Float(point.y) - Float(size - 1) / 2]
    }
    func show(_ data: BoardPresentation, playback: BoardPlayback?, reducedMotion: Bool, yaw: Float, zoom: Float = 1, focus: Point? = nil, pan: SIMD2<Float> = .zero) {
        let rebuild = inspector || renderedState != data.state
        self.yaw = yaw; self.zoom = zoom; focusPoint = focus; panOffset = pan; presentation = data; inspector = false
        boardPan.isEnabled = zoom > 1
        coordinateBoardScroll()
        inspectedHero = nil
        let n = data.state.board.size
        if rebuild {
        cancelPlayback()
        inspectionResourceID = nil; inspectionResourceEntity = nil; inspectionResourceRest = []
        content.children.removeAll(); units = [:]; overlayNodes = []
        content.addChild(MiniatureArena.build(size: n))
        for p in data.state.board.points {
            let position = Self.position(p, size: n)
            if let piece = data.state.board[p] {
                let e = MiniatureModels.piece(piece, heroClass: data.state.heroClass(of: piece.owner)); e.position = position; content.addChild(e); units[p] = e
            }
        }
        renderedState = data.state
        }
        for e in overlayNodes { e.removeFromParent() }; overlayNodes = []; sealNodes = [:]
        for p in data.state.board.points {
            let position = Self.position(p, size: n)
            let beforeCount = content.children.count
            if data.legal.contains(p) { MiniatureModels.cylinder(content, UIColor.white.withAlphaComponent(0.65), position + [0, 0.015, 0], radius: 0.04, height: 0.015) }
            if data.state.seals.contains(where: { $0.at == p }) { sealNodes[p] = ring(position, color: .systemPurple, radius: 0.35) }
            if data.danger.contains(p) || data.captures.contains(p) { ring(position, color: .systemRed, radius: 0.40) }
            if data.selected.contains(p) { ring(position, color: MiniatureModels.gold, radius: 0.44) }
            if content.children.count > beforeCount { overlayNodes += content.children.dropFirst(beforeCount) }
        }
        positionCamera()
        markReviewCaptureReady()
        if reducedMotion || playback == nil {
            cancelPlayback(); playbackID = playback?.id
            if let playback { playedReceipts.insert(playback.id) }
        }
        else if let playback, !playedReceipts.contains(playback.id) {
            playedReceipts.insert(playback.id)
            playbackID = playback.id; beginPlayback(playback)
        }
        if activePlayback != nil { motionFrame(CACurrentMediaTime()) }
    }
    @discardableResult func ring(_ at: SIMD3<Float>, color: UIColor, radius: Float) -> ModelEntity {
        let ring = MiniatureModels.lathe("target-ring", [(0, 0.92), (0, 1), (0.06, 1), (0.06, 0.92), (0, 0.92)], sides: 48)
        return MiniatureModels.part(content, ring, color, at: at + [0, 0.015, 0], scale: [radius, 0.5, radius])
    }
    func inspect(_ hero: HeroClass, yaw: Float, motionID: UUID?, resource: Entity? = nil, idle: Bool = false) {
        let resourceID = resource.map(ObjectIdentifier.init)
        let rebuild = !inspector || inspectedHero != hero || inspectionResourceID != resourceID
        if rebuild { cancelPlayback() }
        renderedState = nil; units = [:]
        inspector = true; self.yaw = yaw; boardPan.isEnabled = false; panGroundAnchor = nil
        if rebuild {
            inspectedHero = hero
            inspectionResourceID = resourceID
            content.children.removeAll()
            let model = resource?.clone(recursive: true) ?? MiniatureModels.renderedHero(hero)
            model.name = "hero-" + hero.rawValue; content.addChild(model)
            inspectionResourceEntity = resourceID == nil ? nil : model
            inspectionResourceRest = []
            func saveJoints(_ e: Entity) {
                if let m = e as? ModelEntity, !m.jointTransforms.isEmpty { inspectionResourceRest.append((m, m.jointTransforms)) }
                for child in e.children { saveJoints(child) }
            }
            if resourceID != nil { saveJoints(model) }
            MiniatureModels.cylinder(content, MiniatureModels.gold, [0, -0.11, 0], radius: 0.68, height: 0.10, metal: true)
            MiniatureModels.cylinder(content, MiniatureModels.navy, [0, -0.025, 0], radius: 0.64, height: 0.025)
        }
        positionCamera()
        if idle {
            if (inspectionIdleStart == nil && inspectionIdleCompletedID != motionID) || inspectionMotionID != motionID {
                inspectionMotionID = motionID; beginInspectionIdle()
            }
        } else {
            if inspectionIdleStart != nil { cancelPlayback() }
            if let motionID, inspectionMotionID != motionID {
                inspectionMotionID = motionID; beginInspectionMotion()
            }
        }
        markReviewCaptureReady()
    }
    @objc func tap(_ gesture: UITapGestureRecognizer) {
        guard !inspector, let data = presentation else { return }
        let tap = gesture.location(in: self)
        // Project actual 3D grid centers. Never reuse the flat board's approximation.
        let targets = data.state.board.points.compactMap { p -> (Point, CGPoint)? in
            project(Self.position(p, size: data.state.board.size)).map { (p, $0) }
        }
        guard let nearest = targets.min(by: { hypot($0.1.x - tap.x, $0.1.y - tap.y) < hypot($1.1.x - tap.x, $1.1.y - tap.y) }) else { return }
        let pitch = targets.filter { $0.0 != nearest.0 }.map { hypot($0.1.x - nearest.1.x, $0.1.y - nearest.1.y) }.min() ?? 0
        if hypot(nearest.1.x - tap.x, nearest.1.y - tap.y) <= pitch * 0.55 { select?(nearest.0) }
    }
}

/// Only the mounted host may configure the shared renderer: outgoing SwiftUI
/// representables can receive updates while their replacement is being inserted.
@MainActor final class TabletopLease { let id = UUID() }
struct ModelBoard: UIViewRepresentable {
    let view: TabletopView
    let presentation: BoardPresentation
    let playback: BoardPlayback?
    let reducedMotion: Bool
    var speed: Double = 1
    let yaw: Float
    var zoom: Float = 1
    var focusPoint: Point?
    var panOffset = SIMD2<Float>.zero
    var panChanged: ((SIMD2<Float>) -> Void)? = nil
    let select: (Point) -> Void
    func makeCoordinator() -> TabletopLease { TabletopLease() }
    func makeUIView(context: Context) -> TabletopView { view.renderLease = context.coordinator.id; return view }
    func updateUIView(_ view: TabletopView, context: Context) {
        guard view.renderLease == context.coordinator.id else { return }
        view.select = select; view.panChanged = panChanged; view.setMotionRate(speed)
        view.show(presentation, playback: playback, reducedMotion: reducedMotion, yaw: yaw, zoom: zoom, focus: focusPoint, pan: panOffset)
    }
    static func dismantleUIView(_ view: TabletopView, coordinator: TabletopLease) {
        guard view.renderLease == coordinator.id else { return }
        view.cancelPlayback(); view.renderLease = nil
    }
}
struct ModelPreview: UIViewRepresentable {
    let view: TabletopView
    let hero: HeroClass
    let yaw: Float
    let motionID: UUID?
    var resource: Entity? = nil
    var idle = false
    func makeCoordinator() -> TabletopLease { TabletopLease() }
    func makeUIView(context: Context) -> TabletopView { view.renderLease = context.coordinator.id; return view }
    func updateUIView(_ view: TabletopView, context: Context) {
        guard view.renderLease == context.coordinator.id else { return }
        view.inspect(hero, yaw: yaw, motionID: motionID, resource: resource, idle: idle)
    }
    static func dismantleUIView(_ view: TabletopView, coordinator: TabletopLease) {
        guard view.renderLease == coordinator.id else { return }
        view.cancelPlayback(); view.renderLease = nil
    }
}
struct ModelGallery: View {
    let view: TabletopView
    let done: () -> Void
    @State private var hero: HeroClass = {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--model-class"), i + 1 < args.count,
           let hero = HeroClass(rawValue: args[i + 1]), hero != .none { return hero }
        #endif
        return .warrior
    }()
    private static var initialYaw: Float {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--model-back") { return 0.30 + .pi }
        #endif
        return 0.30
    }
    @State private var yaw: Float = ModelGallery.initialYaw
    @State private var startYaw: Float = ModelGallery.initialYaw
    @State private var motionID: UUID?
    @State private var idle = false
    @State private var reduceIdle = false
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @State private var resource: Entity?
    @State private var resourceMessage: String?
    @State private var showIdentity = ProcessInfo.processInfo.arguments.contains("--identity-models")
    private var resourceKind: String? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--rig-models") { return "rig" }
        if ProcessInfo.processInfo.arguments.contains("--package-models") { return "pose" }
        #endif
        return nil
    }
    var body: some View {
        VStack(spacing: 16) {
            HStack { Text("英雄模型").font(.title2.bold()); Spacer(); Button("完成", action: done) }
            Picker("英雄", selection: $hero) {
                Text("戰士").tag(HeroClass.warrior); Text("法師").tag(HeroClass.mage); Text("盜賊").tag(HeroClass.rogue)
            }.pickerStyle(.segmented).accessibilityIdentifier("modelClass")
            Toggle("原圖建模候選", isOn: $showIdentity)
                .accessibilityIdentifier("identityModelToggle")
            if showIdentity {
                HStack(spacing: 10) {
                    Image("identity-reference-" + hero.rawValue.lowercased()).resizable().scaledToFit().frame(width: 48, height: 56)
                    Text("原設計對照 · 造型仍在製作中").font(.caption)
                    Spacer()
                }
            }
            ModelPreview(view: view, hero: hero, yaw: yaw, motionID: motionID, resource: resource, idle: idle && !reducedMotion && !reduceIdle).clipShape(RoundedRectangle(cornerRadius: 24))
                .gesture(DragGesture().onChanged { yaw = startYaw + Float($0.translation.width) * 0.012 }.onEnded { _ in startYaw = yaw })
                .accessibilityIdentifier("modelPreview")
            if let resourceMessage { Text(resourceMessage).font(.caption).accessibilityIdentifier("resourceModelStatus") }
            HStack {
                Button { idle = false; motionID = UUID() } label: {
                    Label("造型動作", systemImage: "play.fill").frame(minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("modelMotion")
                Spacer()
                Button { idle.toggle(); if idle { motionID = UUID() } } label: {
                    Text(idle ? "停止待機" : "待機呼吸").frame(minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("modelIdle").accessibilityValue(idle ? "播放中" : "停止")
                    .disabled(showIdentity || reducedMotion || reduceIdle).accessibilityHint(showIdentity ? "候選請用造型動作播放原生片段" : (reducedMotion || reduceIdle ? "依減少動態設定停用" : "呼吸與披風循環動作"))
                Spacer()
                Button { yaw += .pi; startYaw = yaw } label: {
                    Text("轉到背面").frame(minHeight: 44).contentShape(Rectangle())
                }.accessibilityIdentifier("rotateModel")
            }
            HStack {
                Text("減少動態"); Spacer()
                Toggle("減少動態", isOn: $reduceIdle).labelsHidden().fixedSize()
                    .accessibilityIdentifier("modelReduceMotion").disabled(reducedMotion)
            }
        }.padding(20).foregroundStyle(.white).background(Color.ink).preferredColorScheme(.dark)
        .modifier(ReviewTimecode())
        .onChange(of: hero) { _, _ in motionID = nil; idle = false }
        .onChange(of: showIdentity) { _, _ in motionID = nil; idle = false }
        .onChange(of: reducedMotion) { if reducedMotion { idle = false } }
        .onChange(of: reduceIdle) { if reduceIdle { idle = false } }
        .task(id: hero.rawValue + (showIdentity ? "-identity" : "-baseline")) {
            if showIdentity {
                resource = nil; resourceMessage = "載入原圖建模候選…"
                do {
                    guard let url = Bundle.main.url(forResource: "identity-" + hero.rawValue.lowercased(), withExtension: "usdz", subdirectory: "Models") else { throw CocoaError(.fileNoSuchFile) }
                    let model: Entity
                    if #available(iOS 18.0, *) { model = try await Entity(contentsOf: url) }
                    else {
                        var loaded: Entity?
                        for try await entity in Entity.loadAsync(contentsOf: url).values { loaded = entity; break }
                        guard let loaded else { throw CocoaError(.fileReadUnknown) }
                        model = loaded
                    }
                    guard !Task.isCancelled else { return }
                    resource = model
                    let title = hero == .warrior ? "戰士" : (hero == .mage ? "法師" : "盜賊")
                    resourceMessage = "原圖\(title)候選 · 技能片段已載入"
                } catch {
                    guard !Task.isCancelled else { return }
                    resourceMessage = "原圖候選載入失敗：\(error.localizedDescription)"
                }
                return
            }
            resource = nil; resourceMessage = nil
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--source-models") {
                resource = MiniatureModels.hero(hero)
                resourceMessage = "原生未貼圖模型 · 陰影對照"
                return
            }
            #endif
            guard let resourceKind, #available(iOS 18.0, *) else { return }
            resource = nil; resourceMessage = "載入建模資源…"
            do {
                let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                let model = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + "-" + resourceKind + ".usdz"))
                guard !Task.isCancelled else { return }
                resource = model
                resourceMessage = "建模資源 · \(model.availableAnimations.count) 段動作"
            } catch {
                guard !Task.isCancelled else { return }
                resourceMessage = "建模資源載入失敗：\(error.localizedDescription)"
            }
        }
        .task {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--idle-tour") {
                try? await Task.sleep(for: .seconds(5))
                for candidate in [HeroClass.warrior, .mage, .rogue] {
                    guard !Task.isCancelled else { return }
                    hero = candidate; idle = false; yaw = 0.30; startYaw = yaw
                    try? await Task.sleep(for: .seconds(1))
                    for back in [false, true] {
                        yaw = back ? 0.30 + .pi : 0.30; startYaw = yaw
                        let id = UUID(); MotionReviewTrace.record("requested", values: ["receipt": id.uuidString, "example": candidate.rawValue + (back ? " idle rear" : " idle front")])
                        motionID = id; idle = true
                        try? await Task.sleep(for: .seconds(IdleHeroPose.duration * 2 + 0.25))
                        idle = false; try? await Task.sleep(for: .seconds(0.25))
                    }
                }
                MotionReviewTrace.record("tour-complete")
            }
            if ProcessInfo.processInfo.arguments.contains("--model-tour") {
                try? await Task.sleep(for: .seconds(5))
                for candidate in [HeroClass.warrior, .mage, .rogue] {
                    guard !Task.isCancelled else { return }
                    hero = candidate; yaw = 0.30; startYaw = yaw
                    try? await Task.sleep(for: .seconds(1))
                    // Textured USDZ may still be loading. A fallback model's
                    // pose must not be recorded as imported-resource playback.
                    for _ in 0..<50 {
                        if (!showIdentity && resourceKind == nil) || resource != nil { break }
                        try? await Task.sleep(for: .seconds(0.1))
                    }
                    guard !Task.isCancelled, hero == candidate, (!showIdentity && resourceKind == nil) || resource != nil else { return }
                    let front = UUID(); MotionReviewTrace.record("requested", values: ["receipt": front.uuidString, "example": candidate.rawValue + " front"])
                    let motionDelay = max(2, (resource?.availableAnimations.first?.definition.duration ?? 1.4) + 0.6)
                    motionID = front; try? await Task.sleep(for: .seconds(motionDelay))
                    yaw += .pi; startYaw = yaw; try? await Task.sleep(for: .seconds(2))
                    let back = UUID(); MotionReviewTrace.record("requested", values: ["receipt": back.uuidString, "example": candidate.rawValue + " back"])
                    motionID = back; try? await Task.sleep(for: .seconds(motionDelay))
                }
                MotionReviewTrace.record("tour-complete")
            }
            #endif
        }
    }
}
