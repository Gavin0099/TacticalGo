import Foundation
import UIKit
import RealityKit
import TacticalGoCore
import TacticalGoMotion

/// Authored constant surface values accompany the rendered mesh into review exports.
struct AuthoredSurface: Component {
    let color: [Float]
    let roughness: Float
    let metallic: Float
    init(_ color: UIColor, metal: Bool) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.color = [Float(r), Float(g), Float(b), Float(a)]
        roughness = metal ? 0.48 : 0.72; metallic = metal ? 1 : 0
    }
}

/// Exports the actual mesh streams and hierarchy used on iPhone, not a second model generator.
/// This is a local developer review path, outside player state and rule APIs.
@MainActor enum ModelResourceExport {
    #if DEBUG
    /// Exercise the real native presentation interruption paths on the leased
    /// view. Snapshot all unit transforms and actual imported joints before
    /// playing; compare against that independent rest snapshot afterwards.
    static func verifyPlaybackRestoration(on view: TabletopView) throws -> URL {
        struct Snapshot: Equatable {
            var transforms: [String: Transform] = [:]
            var joints: [String: [Transform]] = [:]
            var enabled: [String: Bool] = [:]
        }
        func snapshot() -> Snapshot {
            var result = Snapshot()
            func visit(_ entity: Entity, _ path: String) {
                result.transforms[path] = entity.transform
                result.enabled[path] = entity.isEnabled
                if let model = entity as? ModelEntity, !model.jointTransforms.isEmpty {
                    result.joints[path] = model.jointTransforms
                }
                for (index, child) in entity.children.enumerated() { visit(child, path + "/\(index):" + child.name) }
            }
            for (point, unit) in view.units { visit(unit, "\(point.x),\(point.y)") }
            return result
        }
        let original = view.presentation, originalRate = view.motionRate
        let originalYaw = view.yaw, originalZoom = view.zoom, originalFocus = view.focusPoint
        defer {
            view.cancelPlayback(); view.setMotionRate(originalRate)
            if let original { view.show(original, playback: nil, reducedMotion: true, yaw: originalYaw, zoom: originalZoom, focus: originalFocus) }
        }
        view.setMotionRate(1)
        var rows: [[String: Any]] = []
        for example in MotionExample.allCases {
            let before = try example.initialState(), outcome = GameEngine.apply(before, example.action)
            guard outcome.success else { throw CocoaError(.fileReadCorruptFile) }
            let data = BoardPresentation(state: outcome.state, selected: [], legal: [], preview: nil)
            view.show(data, playback: nil, reducedMotion: true, yaw: 0)
            let rest = snapshot()
            for phase in [0.25, 0.55, 0.9] {
                for ending in ["skip", "reduced", "natural"] {
                    let receipt = BoardPlayback(before: before, action: example.action, outcome: outcome)
                    view.show(data, playback: receipt, reducedMotion: false, yaw: 0)
                    view.displayLink?.invalidate() // Deterministic native frame evaluation; no second ARView.
                    view.motionFrame(view.motionStart + receipt.plan.duration * phase)
                    let changed = snapshot() != rest
                    switch ending {
                    case "skip": view.show(data, playback: nil, reducedMotion: false, yaw: 0)
                    case "reduced": view.show(data, playback: receipt, reducedMotion: true, yaw: 0)
                    default: view.motionFrame(view.motionStart + receipt.plan.duration + 0.01)
                    }
                    let restored = snapshot() == rest
                    let cleared = view.activePlayback == nil && view.displayLink == nil && view.motionNodes.isEmpty
                        && view.captureActors.isEmpty && view.posedParts.isEmpty && view.posedSkeletons.isEmpty
                    view.cancelPlayback()
                    let idempotent = snapshot() == rest
                    rows.append(["example": example.rawValue, "phase": phase, "ending": ending,
                        "unitPoseChangedAtSample": changed, "restored": restored, "cleared": cleared,
                        "idempotent": idempotent, "skeletons": rest.joints.count,
                        "passed": restored && cleared && idempotent])
                }
            }
        }
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = folder.appendingPathComponent("playback-restoration-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "actual native unit and imported-joint state after interruption; deterministic frame evaluation, not rendered-pixel or physical-device evidence", "results": rows], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    #endif
    #if DEBUG
    /// Actual native source/imported joint checks, including the mounted gallery lifecycle.
    static func verifyIdlePoses(on view: TabletopView) throws -> URL {
        let original = view.presentation, originalYaw = view.yaw
        defer {
            view.cancelPlayback()
            if let original { view.show(original, playback: nil, reducedMotion: true, yaw: originalYaw) }
        }
        var rows: [[String: Any]] = []
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let source = MiniatureModels.hero(hero), imported = MiniatureModels.renderedHero(hero)
            guard let skin = SkeletonPose.collect(imported).first else { throw CocoaError(.fileReadCorruptFile) }
            for entity in [source, imported] { entity.scale = [0.6, 0.6, 0.6]; entity.position = [0.32, 0.2, -0.72] }
            let sourcePose = MiniaturePose(hero: source, heroClass: hero), importedPose = MiniaturePose(hero: imported, heroClass: hero)
            let rest = skin.rest, rootRest = imported.transform
            let anchors = ["left", "right"].map { source.findEntity(named: $0 + "-foot")!.position(relativeTo: nil) }
            for frame in 0...102 {
                let phase = Double(frame) / 102
                sourcePose.applyIdle(phase); importedPose.applyIdle(phase)
                var errors: [Float] = []
                for (index, side) in ["left", "right"].enumerated() {
                    let expected = source.findEntity(named: side + "-foot")!.position(relativeTo: nil)
                    guard let actual = skin.position(of: side + "_foot", local: .zero, relativeTo: nil),
                          let up = skin.position(of: side + "_foot", local: [0, 0.05, 0], relativeTo: nil) else { throw CocoaError(.fileReadCorruptFile) }
                    errors += [simd_length(actual - expected), simd_length(actual - anchors[index]),
                               simd_length(simd_normalize(up - actual) - SIMD3<Float>(0, 1, 0))]
                }
                for name in ["head", "left-arm", "right-arm", "cape"] {
                    let part = source.findEntity(named: name)!
                    let local: SIMD3<Float> = name == "cape" ? [0, -0.30, 0] : [0, 0.06, 0]
                    guard let actual = skin.position(of: name.replacingOccurrences(of: "-", with: "_"), local: local, relativeTo: nil) else { throw CocoaError(.fileReadCorruptFile) }
                    errors.append(simd_length(actual - part.convert(position: local, to: nil)))
                }
                let changed = skin.model.jointTransforms != rest
                rows.append(["hero": hero.rawValue, "frame": frame, "maxNativeError": errors.max()!,
                    "nativeJointsChanged": changed, "passed": errors.max()! < 0.00001 && (frame == 0 || frame == 102 || changed)])
            }
            importedPose.reset(); sourcePose.reset()
            rows.append(["hero": hero.rawValue, "ending": "direct-reset", "passed": skin.model.jointTransforms == rest && imported.transform == rootRest])
            for ending in ["stop", "attack", "hero-change", "leave", "reduced"] {
                view.inspect(hero, yaw: 0.30, motionID: nil)
                guard let mounted = view.content.children.first(where: { $0.name.hasPrefix("hero-") }),
                      let mountedSkin = SkeletonPose.collect(mounted).first else { throw CocoaError(.fileReadCorruptFile) }
                let mountedRest = mounted.transform, jointRest = mountedSkin.rest
                let id = UUID(); view.inspect(hero, yaw: 0.30, motionID: id, idle: true)
                view.displayLink?.invalidate()
                guard let start = view.inspectionIdleStart else { throw CocoaError(.fileReadCorruptFile) }
                view.motionFrame(start + 0.85)
                let changed = mountedSkin.model.jointTransforms != jointRest
                switch ending {
                case "stop", "reduced": view.inspect(hero, yaw: 0.30, motionID: id, idle: false)
                case "attack": view.inspect(hero, yaw: 0.30, motionID: UUID()); view.cancelPlayback()
                case "hero-change": view.inspect(hero == .warrior ? .mage : .warrior, yaw: 0.30, motionID: nil)
                default:
                    let state = try GameSetup.newGame()
                    view.show(BoardPresentation(state: state, selected: [], legal: [], preview: nil), playback: nil, reducedMotion: false, yaw: 0)
                }
                let restored = mounted.transform == mountedRest && mountedSkin.model.jointTransforms == jointRest
                rows.append(["hero": hero.rawValue, "ending": ending, "nativeJointsChanged": changed,
                    "restored": restored, "cleared": view.inspectionIdleStart == nil && view.displayLink == nil,
                    "passed": changed && restored && view.inspectionIdleStart == nil && view.displayLink == nil])
            }
        }
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let file = folder.appendingPathComponent("idle-pose-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "actual native source/imported feet, head/arm/cape sockets and mounted gallery interruption; not rendered-pixel or physical-device evidence", "results": rows], options: [.prettyPrinted, .sortedKeys]).write(to: file, options: .atomic)
        return file
    }
    #endif
    static func verifySockets() throws -> URL {
        let source = MiniatureModels.hero(.mage), loaded = MiniatureModels.renderedHero(.mage)
        for hero in [source, loaded] { hero.position = [0.3, 0.115, -0.7]; hero.scale = [0.62, 0.62, 0.62] }
        guard let crystal = source.findEntity(named: "crystal"), let skeleton = SkeletonPose.collect(loaded).first else { throw CocoaError(.fileReadCorruptFile) }
        let expectedPose = MiniaturePose(hero: source, heroClass: .mage), actualPose = MiniaturePose(hero: loaded, heroClass: .mage)
        var results: [[String: Any]] = []
        func values(_ p: SIMD3<Float>) -> [Float] { [p.x, p.y, p.z] }
        for t in [0.0, 0.2, 0.45, 0.7, 1.0] {
            expectedPose.apply(t); actualPose.apply(t)
            guard let actual = skeleton.position(of: "right_arm", local: [0.15, 0.54, 0.12], relativeTo: nil) else { throw CocoaError(.fileReadCorruptFile) }
            let expected = crystal.position(relativeTo: nil), error = simd_length(actual - expected)
            results.append(["phase": t, "expectedSourceCrystal": values(expected), "actualSkeletonSocket": values(actual), "errorMeters": error, "passed": error < 0.00001])
        }
        let unknownRejected = skeleton.position(of: "missing_joint", local: .zero, relativeTo: nil) == nil
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = folder.appendingPathComponent("socket-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "native imported skeleton socket versus original crystal entity across scaled/transformed poses", "results": results, "unknownJointRejected": unknownRejected], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    @available(iOS 18.0, *)
    static func verifyCapePoses() async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var rows: [[String: Any]] = []
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let source = MiniatureModels.hero(hero)
            let loaded = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + "-rig.usdz"))
            let wrapper = Entity(); wrapper.addChild(loaded)
            for entity in [source, wrapper] { entity.scale = [0.6, 0.6, 0.6]; entity.position = [0.32, 0.2, -0.72] }
            guard let cape = source.findEntity(named: "cape"),
                  let shell = source.findEntity(named: "cape-shell") as? ModelEntity,
                  let skin = SkeletonPose.collect(wrapper).first else { throw CocoaError(.fileReadCorruptFile) }
            var hem: SIMD3<Float>?
            for instance in shell.model!.mesh.contents.instances {
                guard let model = shell.model!.mesh.contents.models.first(where: { $0.id == instance.model }) else { continue }
                for part in model.parts { for p in part.positions.elements {
                    let q = instance.transform * SIMD4<Float>(p.x, p.y, p.z, 1)
                    let local = shell.convert(position: [q.x, q.y, q.z], to: cape)
                    if hem == nil || local.y < hem!.y { hem = local }
                } }
            }
            guard let hem else { throw CocoaError(.fileReadCorruptFile) }
            let originalHem = cape.convert(position: hem, to: source)
            let sourcePose = MiniaturePose(hero: source, heroClass: hero), importedPose = MiniaturePose(hero: wrapper, heroClass: hero)
            let rest = skin.rest, initialTransform = wrapper.transform
            for phase in [0.0, 0.25, 0.475, 0.70, 0.85, 1.0] {
                sourcePose.apply(phase); importedPose.apply(phase)
                guard let actual = skin.position(of: "cape", local: hem, relativeTo: nil),
                      let hinge = skin.position(of: "cape", local: .zero, relativeTo: nil) else { throw CocoaError(.fileReadCorruptFile) }
                let expected = cape.convert(position: hem, to: nil), sourceHinge = cape.position(relativeTo: nil)
                let error = simd_length(expected - actual), hingeError = simd_length(sourceHinge - hinge)
                let posedHem = cape.convert(position: hem, to: source), outward = posedHem.z <= originalHem.z + 0.000001
                rows.append(["hero": hero.rawValue, "phase": phase, "sample": "actual lowest source cape vertex, fully cape-weighted hem",
                             "nativeHemSocketErrorMeters": error, "nativeHingeErrorMeters": hingeError,
                             "hemMovedOutwardInBodySpace": outward,
                             "passed": error < 0.000001 && hingeError < 0.000001 && outward])
            }
            importedPose.reset(); sourcePose.reset()
            rows.append(["hero": hero.rawValue, "restored": skin.model.jointTransforms == rest && wrapper.transform == initialTransform])
        }
        let file = folder.appendingPathComponent("cape-pose-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "native cape hinge/fully-weighted hem sockets versus original source; shoulder blend and rendered cloth verified separately", "results": rows], options: [.prettyPrinted, .sortedKeys])
            .write(to: file, options: .atomic)
        return file
    }
    @available(iOS 18.0, *)
    static func verifyLegPoses() async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var rows: [[String: Any]] = []
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let source = MiniatureModels.hero(hero)
            let loaded = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + "-rig.usdz"))
            let wrapper = Entity(); wrapper.addChild(loaded)
            for entity in [source, wrapper] { entity.scale = [0.6, 0.6, 0.6]; entity.position = [0.32, 0.2, -0.72] }
            let sourcePose = MiniaturePose(hero: source, heroClass: hero), importedPose = MiniaturePose(hero: wrapper, heroClass: hero)
            guard let skin = SkeletonPose.collect(wrapper).first else { throw CocoaError(.fileReadCorruptFile) }
            let rest = skin.rest, initialTransform = wrapper.transform
            var anchors: [String: SIMD3<Float>] = [:]
            for side in ["left", "right"] { anchors[side] = source.findEntity(named: side + "-foot")!.position(relativeTo: nil) }
            for phase in [0.0, 0.15, 0.35, 0.5, 0.7, 1.0] {
                sourcePose.apply(phase); importedPose.apply(phase)
                for side in ["left", "right"] {
                    let sourceFoot = source.findEntity(named: side + "-foot")!
                    let expected = sourceFoot.position(relativeTo: nil)
                    guard let actual = skin.position(of: side + "_foot", local: .zero, relativeTo: nil),
                          let up = skin.position(of: side + "_foot", local: [0, 0.05, 0], relativeTo: nil) else { throw CocoaError(.fileReadCorruptFile) }
                    let error = simd_length(expected - actual), planted = simd_length(expected - anchors[side]!)
                    let upError = simd_length(simd_normalize(up - actual) - SIMD3<Float>(0, 1, 0))
                    rows.append(["hero": hero.rawValue, "phase": phase, "side": side,
                        "sourceFoot": [expected.x, expected.y, expected.z], "importedFoot": [actual.x, actual.y, actual.z],
                        "roundTripErrorMeters": error, "sourcePlantedErrorMeters": planted, "importedUpVectorError": upError,
                        "passed": error < 0.000001 && planted < 0.000001 && upError < 0.00001])
                }
            }
            importedPose.reset(); sourcePose.reset()
            rows.append(["hero": hero.rawValue, "restored": skin.model.jointTransforms == rest && wrapper.transform == initialTransform])
        }
        let file = folder.appendingPathComponent("leg-pose-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "native hierarchical leg socket versus authored source; planted ankle, flat foot and rest restoration", "results": rows], options: [.prettyPrinted, .sortedKeys])
            .write(to: file, options: .atomic)
        return file
    }
    @available(iOS 18.0, *)
    /// Compare actual imported clip bindings on the mounted native view.
    /// Recognition alone cannot prove that naming/wrapping preserves animation targets.
    static func auditImportedClips(in view: TabletopView) async throws -> URL {
        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try await Task.sleep(for: .seconds(3))
        view.cancelPlayback(); view.inspector = true
        var rows: [[String: Any]] = []
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let resource = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + "-rig.usdz"))
            for mode in ["authored-name", "renamed-root", "named-wrapper", "released-controller"] {
                for index in resource.availableAnimations.indices {
                    view.content.children.removeAll()
                    let imported = resource.clone(recursive: true)
                    let originalName = imported.name
                    let host: Entity
                    if mode == "named-wrapper" {
                        host = Entity(); host.name = "hero-" + hero.rawValue; host.addChild(imported)
                    } else {
                        host = imported
                        if mode == "renamed-root" { host.name = "hero-" + hero.rawValue }
                    }
                    view.content.addChild(host); view.positionCamera()
                    let skins = SkeletonPose.collect(imported)
                    guard skins.count == 1 else { throw CocoaError(.fileReadCorruptFile) }
                    try await Task.sleep(for: .seconds(0.15))
                    let clip = imported.availableAnimations[index]
                    let controller: AnimationPlaybackController?
                    if mode == "released-controller" { _ = imported.playAnimation(clip); controller = nil }
                    else { controller = imported.playAnimation(clip) }
                    var samples: [[String: Any]] = []
                    var lastPhase = 0.0
                    for phase in [0.55, 0.84] {
                        try await Task.sleep(for: .seconds(clip.definition.duration * (phase - lastPhase)))
                        lastPhase = phase
                        let skin = skins[0]
                        var angles: [String: Float] = [:]
                        for joint in skin.model.jointNames.indices {
                            let rest = skin.rest[joint].rotation
                            let posed = skin.model.jointTransforms[joint].rotation
                            angles[skin.model.jointNames[joint]] = 2 * acos(min(1, abs(simd_dot(rest.vector, posed.vector))))
                        }
                        samples.append(["phase": phase, "controllerTime": controller?.time ?? -1, "jointRotationDeltaRadians": angles])
                    }
                    imported.stopAllAnimations(recursive: true)
                    rows.append(["hero": hero.rawValue, "mode": mode, "authoredRootName": originalName,
                        "clipIndex": index, "clipName": clip.definition.name, "definition": String(reflecting: clip.definition), "samples": samples])
                    host.removeFromParent()
                }
            }
        }
        let url = folder.appendingPathComponent("imported-clip-binding-audit.json")
        try JSONSerialization.data(withJSONObject: ["kind": "mounted native playback joint deltas; diagnostic, no pixel or physical-device claim", "results": rows], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }

    @available(iOS 18.0, *)
    static func verifyRigs() async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var results: [[String: Any]] = []
        func geometryBounds(_ root: Entity) -> (SIMD3<Float>, SIMD3<Float>) {
            var minimum = SIMD3<Float>(repeating: .infinity), maximum = SIMD3<Float>(repeating: -.infinity)
            func visit(_ e: Entity) {
                if let model = e.components[ModelComponent.self] {
                    let mesh = model.mesh.contents
                    for instance in mesh.instances {
                        guard let geometry = mesh.models.first(where: { $0.id == instance.model }) else { continue }
                        let matrix = e.transformMatrix(relativeTo: nil) * instance.transform
                        for part in geometry.parts { for p in part.positions.elements {
                            let transformed = matrix * SIMD4<Float>(p.x, p.y, p.z, 1)
                            let point = SIMD3<Float>(transformed.x, transformed.y, transformed.z)
                            minimum = simd_min(minimum, point); maximum = simd_max(maximum, point)
                        } }
                    }
                }
                for child in e.children { visit(child) }
            }
            visit(root); return (minimum, maximum)
        }
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let loaded = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + "-rig.usdz"))
            let source = MiniatureModels.hero(hero), expected = source.visualBounds(relativeTo: nil), actual = loaded.visualBounds(relativeTo: nil)
            let error = max(simd_length(expected.min - actual.min), simd_length(expected.max - actual.max))
            var skeletons: [[String: Any]] = []
            func visit(_ e: Entity) {
                if let m = e as? ModelEntity, !m.jointNames.isEmpty {
                    skeletons.append(["entity": m.name, "joints": m.jointNames, "restTransformCount": m.jointTransforms.count])
                }
                for child in e.children { visit(child) }
            }
            visit(loaded)
            let sourceBounds = geometryBounds(source), loadedBounds = geometryBounds(loaded)
            let restError = max(simd_length(sourceBounds.0 - loadedBounds.0), simd_length(sourceBounds.1 - loadedBounds.1))
            results.append(["hero": hero.rawValue, "visualBoundsError": error, "rawRestGeometryBoundsError": restError, "skeletons": skeletons,
                            "animations": loaded.availableAnimations.map { ["name": $0.definition.name, "duration": $0.definition.duration] },
                            "expectedJoints": MiniaturePose.jointNames.count + 1,
                            "passed": restError < 0.003 && skeletons.count == 1 && skeletons.first?["restTransformCount"] as? Int == MiniaturePose.jointNames.count + 1 && !loaded.availableAnimations.isEmpty])
        }
        let url = folder.appendingPathComponent("rig-import-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "native RealityKit skeleton, bounds, clip recognition; visible playback separately reviewed", "results": results], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    #if DEBUG
    @available(iOS 18.0, *)
    static func verifyArenas() async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        func meshCount(_ entity: Entity) -> Int {
            (entity.components[ModelComponent.self] == nil ? 0 : 1) + entity.children.reduce(0) { $0 + meshCount($1) }
        }
        func vertices(_ root: Entity) -> [SIMD3<Float>] {
            var result: [SIMD3<Float>] = []
            func visit(_ entity: Entity) {
                if let mesh = entity.components[ModelComponent.self]?.mesh.contents {
                    for instance in mesh.instances {
                        guard let model = mesh.models.first(where: { $0.id == instance.model }) else { continue }
                        let matrix = entity.transformMatrix(relativeTo: nil) * instance.transform
                        for part in model.parts { for p in part.positions.elements {
                            let q = matrix * SIMD4<Float>(p.x, p.y, p.z, 1)
                            result.append([q.x, q.y, q.z])
                        } }
                    }
                }
                for child in entity.children { visit(child) }
            }
            visit(root); return result
        }
        struct Cell: Hashable {
            let x: Int, y: Int, z: Int
            init(_ p: SIMD3<Float>) { x = Int(floor(p.x * 100_000)); y = Int(floor(p.y * 100_000)); z = Int(floor(p.z * 100_000)) }
            init(_ x: Int, _ y: Int, _ z: Int) { self.x = x; self.y = y; self.z = z }
        }
        // Match a complete multiset of actual native vertices, including coincident
        // copies. Neighbor cells avoid a false mismatch at quantization boundaries.
        func vertexError(_ source: [SIMD3<Float>], _ target: [SIMD3<Float>]) -> Float? {
            guard source.count == target.count else { return nil }
            var cells: [Cell: [Int]] = [:], used = Set<Int>(), maximum: Float = 0
            for (i, p) in target.enumerated() { cells[Cell(p), default: []].append(i) }
            for p in source {
                let cell = Cell(p); var best: (Int, Float)?
                for x in -1...1 { for y in -1...1 { for z in -1...1 {
                    for i in cells[Cell(cell.x + x, cell.y + y, cell.z + z)] ?? [] where !used.contains(i) {
                        let error = simd_length(p - target[i])
                        if error < 0.000001 && (best == nil || error < best!.1) { best = (i, error) }
                    }
                } } }
                guard let best else { return nil }; used.insert(best.0); maximum = max(maximum, best.1)
            }
            return maximum
        }
        var rows: [[String: Any]] = []
        for size in [7, 9] {
            let source = MiniatureArena.build(size: size)
            let loaded = try await Entity(contentsOf: folder.appendingPathComponent("arena\(size).usdz"))
            let original = vertices(source), imported = vertices(loaded)
            let error = vertexError(original, imported)
            let meshesMatch = meshCount(source) == meshCount(loaded)
            rows.append(["size": size, "sourceVertices": original.count, "importedVertices": imported.count,
                         "sourceMeshes": meshCount(source), "importedMeshes": meshCount(loaded),
                         "matchedEveryVertex": error != nil, "maximumVertexErrorMeters": error ?? -1,
                         "passed": meshesMatch && error != nil && error! < 0.000001])
        }
        let url = folder.appendingPathComponent("arena-import-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "native actual world vertex multiset and mesh count, no rendered pixel/performance claim", "results": rows], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    #endif
    @available(iOS 18.0, *)
    static func verifyUnits(compacted: Bool = false) async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        func meshCount(_ entity: Entity) -> Int {
            (entity.components[ModelComponent.self] == nil ? 0 : 1) + entity.children.reduce(0) { $0 + meshCount($1) }
        }
        func vertices(_ root: Entity) -> [SIMD3<Float>] {
            var result: [SIMD3<Float>] = []
            func visit(_ entity: Entity) {
                if let mesh = entity.components[ModelComponent.self]?.mesh.contents {
                    for instance in mesh.instances {
                        guard let model = mesh.models.first(where: { $0.id == instance.model }) else { continue }
                        let matrix = entity.transformMatrix(relativeTo: nil) * instance.transform
                        for part in model.parts { for p in part.positions.elements {
                            let q = matrix * SIMD4<Float>(p.x, p.y, p.z, 1)
                            result.append([q.x, q.y, q.z])
                        } }
                    }
                }
                for child in entity.children { visit(child) }
            }
            visit(root); return result
        }
        struct Cell: Hashable {
            let x: Int, y: Int, z: Int
            init(_ p: SIMD3<Float>) { x = Int(floor(p.x * 100_000)); y = Int(floor(p.y * 100_000)); z = Int(floor(p.z * 100_000)) }
            init(_ x: Int, _ y: Int, _ z: Int) { self.x = x; self.y = y; self.z = z }
        }
        // Match a complete multiset of actual native vertices, including coincident
        // copies. Neighbor cells avoid a false mismatch at quantization boundaries.
        func vertexError(_ source: [SIMD3<Float>], _ target: [SIMD3<Float>]) -> Float? {
            guard source.count == target.count else { return nil }
            var cells: [Cell: [Int]] = [:], used = Set<Int>(), maximum: Float = 0
            for (i, p) in target.enumerated() { cells[Cell(p), default: []].append(i) }
            for p in source {
                let cell = Cell(p); var best: (Int, Float)?
                for x in -1...1 { for y in -1...1 { for z in -1...1 {
                    for i in cells[Cell(cell.x + x, cell.y + y, cell.z + z)] ?? [] where !used.contains(i) {
                        let error = simd_length(p - target[i])
                        if error < 0.000001 && (best == nil || error < best!.1) { best = (i, error) }
                    }
                } } }
                guard let best else { return nil }; used.insert(best.0); maximum = max(maximum, best.1)
            }
            return maximum
        }
        var rows: [[String: Any]] = []
        for owner in [Player.one, .two] {
            for kind in [PieceKind.soldier, .commander] {
                let name = (owner == .one ? "Blue" : "Red") + (kind == .soldier ? "Soldier" : "Commander")
                let source = MiniatureModels.piece(Piece(owner, kind), heroClass: .none, sourceOnly: true)
                let loaded = try await Entity(contentsOf: folder.appendingPathComponent(name.lowercased() + ".usdz"))
                let expected = source.visualBounds(relativeTo: nil), actual = loaded.visualBounds(relativeTo: nil)
                let error = max(simd_length(expected.min - actual.min), simd_length(expected.max - actual.max))
                let originalPoints = vertices(source), importedPoints = vertices(loaded)
                let completeVertexError = vertexError(originalPoints, importedPoints)
                // visualBounds unions transformed part AABBs; after baking a
                // rotated owner marker, that conservative box may become tighter.
                // Compare the actual geometry extents as well as every vertex.
                func actualBounds(_ points: [SIMD3<Float>]) -> (SIMD3<Float>, SIMD3<Float>) {
                    var low = SIMD3<Float>(repeating: .infinity), high = SIMD3<Float>(repeating: -.infinity)
                    for p in points { low = simd_min(low, p); high = simd_max(high, p) }
                    return (low, high)
                }
                let originalBounds = actualBounds(originalPoints), importedBounds = actualBounds(importedPoints)
                let geometryBoundsError = max(simd_length(originalBounds.0 - importedBounds.0), simd_length(originalBounds.1 - importedBounds.1))
                let expectedMeshes = compacted ? (kind == .commander ? 9 : 8) : meshCount(source)
                rows.append(["name": name, "sourceMeshes": meshCount(source), "importedMeshes": meshCount(loaded),
                             "boundsErrorMeters": error, "sourceHeight": expected.extents.y,
                             "actualVertexBoundsErrorMeters": geometryBoundsError,
                             "sourceVertices": originalPoints.count, "importedVertices": importedPoints.count,
                             "allVerticesMatched": completeVertexError != nil, "maxMatchedVertexErrorMeters": completeVertexError ?? -1,
                             "passed": geometryBoundsError < 0.000001 && meshCount(loaded) == expectedMeshes && completeVertexError != nil])
            }
        }
        let url = folder.appendingPathComponent(compacted ? "compact-unit-import-verification.json" : "unit-import-verification.json")
        try JSONSerialization.data(withJSONObject: ["kind": "actual native miniature source versus imported static USDZ; no skeletal or physical-device claim", "results": rows], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    @available(iOS 18.0, *)
    static func verifyPackages() async throws -> URL {
        let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        var results: [[String: Any]] = []
        func values(_ v: SIMD3<Float>) -> [Float] { [v.x, v.y, v.z] }
        func count(_ e: Entity) -> Int { (e.components[ModelComponent.self] == nil ? 0 : 1) + e.children.reduce(0) { $0 + count($1) } }
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let loaded = try await Entity(contentsOf: folder.appendingPathComponent(hero.rawValue.lowercased() + ".usdz"))
            let source = MiniatureModels.hero(hero), expected = source.visualBounds(relativeTo: nil), actual = loaded.visualBounds(relativeTo: nil)
            let error = max(simd_length(expected.min - actual.min), simd_length(expected.max - actual.max))
            let sourceCount = count(source), importedCount = count(loaded)
            var result: [String: Any] = ["hero": hero.rawValue, "sourceMin": values(expected.min), "sourceMax": values(expected.max),
                            "importedMin": values(actual.min), "importedMax": values(actual.max), "boundsError": error,
                            "sourceMeshes": sourceCount, "importedMeshes": importedCount,
                            "passed": error < 0.003 && sourceCount == importedCount]
            let poseURL = folder.appendingPathComponent(hero.rawValue.lowercased() + "-pose.usdz")
            if FileManager.default.fileExists(atPath: poseURL.path) {
                let animated = try await Entity(contentsOf: poseURL)
                result["poseAnimationCount"] = animated.availableAnimations.count
                result["poseAnimationDurations"] = animated.availableAnimations.map { $0.definition.duration }
                result["poseImported"] = true
            }
            results.append(result)
        }
        let url = folder.appendingPathComponent("model-import-verification.json")
        try JSONSerialization.data(withJSONObject: ["results": results, "kind": "native RealityKit import; static bounds and mesh count"], options: [.prettyPrinted, .sortedKeys]).write(to: url, options: .atomic)
        return url
    }
    static func writeCandidates(arenaOnly: Bool = false, unitsOnly: Bool = false, idle: Bool = false) throws -> URL {
        var meshes: [String: Any] = [:], meshIDs: [ObjectIdentifier: String] = [:]
        func matrix(_ value: simd_float4x4) -> [[Float]] {
            (0..<4).map { i in [value[i].x, value[i].y, value[i].z, value[i].w] }
        }
        func vector(_ value: SIMD3<Float>) -> [Float] { [value.x, value.y, value.z] }
        func resource(_ mesh: MeshResource) throws -> String {
            let identity = ObjectIdentifier(mesh)
            if let id = meshIDs[identity] { return id }
            let id = "mesh_\(meshIDs.count)"; meshIDs[identity] = id
            let contents = mesh.contents
            let models = try contents.models.map { model -> [String: Any] in
                let parts = try model.parts.map { part -> [String: Any] in
                    guard let indices = part.triangleIndices else {
                        throw NSError(domain: "TacticalGoModelExport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing triangles in \(part.id)"])
                    }
                    return ["id": part.id, "points": part.positions.elements.map(vector),
                            "normals": part.normals?.elements.map(vector) ?? [], "triangles": indices.elements]
                }
                return ["id": model.id, "parts": parts]
            }
            meshes[id] = ["models": models, "instances": contents.instances.map {
                ["model": $0.model, "matrixColumns": matrix($0.transform)] as [String: Any]
            }]
            return id
        }
        func node(_ entity: Entity, samples: [ObjectIdentifier: [[String: Any]]]) throws -> [String: Any] {
            var data: [String: Any] = ["name": entity.name, "matrixColumns": matrix(entity.transform.matrix),
                                       "children": try entity.children.map { try node($0, samples: samples) }]
            if let animation = samples[ObjectIdentifier(entity)] { data["matrixSamples"] = animation }
            if let model = entity.components[ModelComponent.self] { data["mesh"] = try resource(model.mesh) }
            if let surface = entity.components[AuthoredSurface.self] {
                data["surface"] = ["colorSRGB": surface.color, "roughness": surface.roughness, "metallic": surface.metallic]
            }
            return data
        }
        var models: [String: Any] = [:]
        for hero in arenaOnly || unitsOnly ? [] : [HeroClass.warrior, .mage, .rogue] {
            let entity = MiniatureModels.hero(hero), pose = MiniaturePose(hero: entity, heroClass: hero)
            var samples: [ObjectIdentifier: [[String: Any]]] = [:]
            let endFrame = idle ? 102 : 42
            for frame in 0...endFrame {
                if idle { pose.applyIdle(Double(frame) / Double(endFrame)) }
                else { pose.apply(Double(frame) / Double(endFrame)) }
                for part in pose.animatedEntities {
                    samples[ObjectIdentifier(part), default: []].append(["time": frame, "matrixColumns": matrix(part.transform.matrix)])
                }
            }
            pose.reset(); models[hero.rawValue] = try node(entity, samples: samples)
        }
        if arenaOnly {
            for size in [7, 9] {
                models["Arena\(size)"] = try node(MiniatureArena.build(size: size), samples: [:])
            }
        }
        if unitsOnly {
            for owner in [Player.one, .two] {
                for kind in [PieceKind.soldier, .commander] {
                    let name = (owner == .one ? "Blue" : "Red") + (kind == .soldier ? "Soldier" : "Commander")
                    models[name] = try node(MiniatureModels.piece(Piece(owner, kind), heroClass: .none, sourceOnly: true), samples: [:])
                }
            }
        }
        var snapshot: [String: Any] = ["schema": "tacticalgo-model-snapshot.v1", "upAxis": "Y", "metersPerUnit": 1,
                                      "source": arenaOnly ? "MiniatureArena runtime mesh streams" : "MiniatureModels runtime mesh streams", "models": models, "meshes": meshes]
        if !arenaOnly && !unitsOnly {
            snapshot["animation"] = ["framesPerSecond": 30, "endTimeCode": idle ? 102 : 42, "kind": idle ? "idle cycle; source hierarchy for weighted skin" : "rigid pose study; no skin"]
        }
        let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent(arenaOnly ? "arena-candidates.json" : unitsOnly ? "unit-candidates.json" : idle ? "idle-candidates.json" : "model-candidates.json")
        try JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys]).write(to: url, options: .atomic)
        return url
    }
}
