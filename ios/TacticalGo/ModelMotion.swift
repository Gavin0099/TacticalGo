import UIKit
import SwiftUI
import RealityKit
import TacticalGoCore
import TacticalGoMotion

/// Weak target avoids a display-link/view retain cycle. All mutations stay on UIKit's main actor.
@MainActor final class MotionFrameTarget: NSObject {
    weak var view: TabletopView?
    init(_ view: TabletopView) { self.view = view }
    @objc func frame(_ link: CADisplayLink) { view?.motionFrame(link.timestamp) }
}

/// Rest transforms for a real imported weighted skeleton. Clothing and props
/// keep their authored vertex groups; presentation poses do not change rules.
@MainActor struct SkeletonPose {
    let model: ModelEntity
    let rest: [Transform]
    static func collect(_ root: Entity) -> [SkeletonPose] {
        var poses: [SkeletonPose] = []
        if let model = root as? ModelEntity, !model.jointTransforms.isEmpty {
            poses.append(SkeletonPose(model: model, rest: model.jointTransforms))
        }
        for child in root.children { poses += collect(child) }
        return poses
    }
    func reset() { model.jointTransforms = rest }
    func position(of name: String, local: SIMD3<Float>, relativeTo target: Entity?) -> SIMD3<Float>? {
        guard let fullName = model.jointNames.first(where: { $0.split(separator: "/").last.map(String.init) == name }) else { return nil }
        let chain = fullName.split(separator: "/")
        var matrix = matrix_identity_float4x4
        for depth in 1...chain.count {
            let ancestor = chain.prefix(depth).joined(separator: "/")
            guard let index = model.jointNames.firstIndex(of: ancestor), index < model.jointTransforms.count else { return nil }
            matrix = matrix * model.jointTransforms[index].matrix
        }
        let value = matrix * SIMD4<Float>(local.x, local.y, local.z, 1)
        return model.convert(position: [value.x, value.y, value.z], to: target)
    }
    func rotate(_ name: String, angle: Float) {
        let joint = name.replacingOccurrences(of: "-", with: "_")
        guard let index = model.jointNames.firstIndex(where: { $0.split(separator: "/").last.map(String.init) == joint }), index < rest.count else { return }
        var transforms = model.jointTransforms
        transforms[index].rotation = rest[index].rotation * simd_quatf(angle: angle, axis: [1, 0, 0])
        model.jointTransforms = transforms
    }
}

/// Shared authored pose: used by native close-up playback and source USD sampling.
@MainActor struct MiniaturePose {
    static let jointNames = ["left-arm", "right-arm", "head", "left-thigh", "left-calf", "left-foot", "right-thigh", "right-calf", "right-foot", "cape"]
    let hero: Entity
    let heroClass: HeroClass
    let rest: Transform
    let parts: [(Entity, Transform)]
    let skeletons: [SkeletonPose]
    var animatedEntities: [Entity] { [hero] + parts.map { $0.0 } }
    init(hero: Entity, heroClass: HeroClass) {
        self.hero = hero; self.heroClass = heroClass; rest = hero.transform
        parts = Self.jointNames.compactMap { name in
            hero.findEntity(named: name).map { ($0, $0.transform) }
        }
        skeletons = SkeletonPose.collect(hero)
    }
    func reset() {
        hero.transform = rest
        for (part, transform) in parts { part.transform = transform }
        for skeleton in skeletons { skeleton.reset() }
    }
    func apply(_ t: Double) {
        reset()
        guard t > 0, t < 1 else { return }
        func rotate(_ name: String, _ angle: Float) {
            if let (part, transform) = parts.first(where: { $0.0.name == name }) {
                part.orientation = transform.rotation * simd_quatf(angle: angle, axis: [1, 0, 0])
            }
            for skeleton in skeletons { skeleton.rotate(name, angle: angle) }
        }
        let anticipation = Float(MotionCurves.anticipation(t))
        var pitch: Float = 0, depth: Float = 0
        switch heroClass {
        case .warrior:
            let strike = Float(MotionCurves.shieldStrike(t))
            pitch = strike; depth = sin(Float(t) * .pi) * 0.025
            rotate("left-arm", -strike * 2.5); rotate("head", -strike * 0.7)
        case .mage:
            pitch = anticipation * 0.6; depth = sin(Float(t) * .pi) * 0.012
            rotate("right-arm", -anticipation * 1.8); rotate("head", -anticipation * 0.4)
        case .rogue:
            pitch = anticipation * 1.4; depth = sin(Float(t) * .pi) * 0.07
            rotate("right-arm", -anticipation * 2); rotate("left-arm", anticipation * 2)
        case .none: break
        }
        let stance = GroundedLegPose(depth: Double(depth), rootPitch: Double(pitch))
        let capeAmplitude: Float = heroClass == .rogue ? 0.18 : (heroClass == .warrior ? 0.14 : 0.10)
        rotate("cape", Float(MotionCurves.capeFollowThrough(t, lateImpact: heroClass == .warrior)) * capeAmplitude)
        hero.orientation = rest.rotation * simd_quatf(angle: Float(stance.rootPitch), axis: [1, 0, 0])
        hero.position.y = rest.translation.y - Float(stance.depth) * rest.scale.y
        for side in ["left", "right"] {
            rotate(side + "-thigh", Float(stance.hip))
            rotate(side + "-calf", Float(stance.knee))
            rotate(side + "-foot", Float(stance.ankle))
        }
    }
    func applyIdle(_ phase: Double) {
        reset()
        let idle = IdleHeroPose(hero: heroClass, phase: phase), stance = idle.stance
        func rotate(_ name: String, _ angle: Double) {
            if let (part, transform) = parts.first(where: { $0.0.name == name }) {
                part.orientation = transform.rotation * simd_quatf(angle: Float(angle), axis: [1, 0, 0])
            }
            for skeleton in skeletons { skeleton.rotate(name, angle: Float(angle)) }
        }
        rotate("head", idle.head); rotate("left-arm", idle.leftArm); rotate("right-arm", idle.rightArm)
        rotate("cape", idle.cape)
        hero.orientation = rest.rotation * simd_quatf(angle: Float(stance.rootPitch), axis: [1, 0, 0])
        hero.position.y = rest.translation.y - Float(stance.depth) * rest.scale.y
        for side in ["left", "right"] {
            rotate(side + "-thigh", stance.hip); rotate(side + "-calf", stance.knee); rotate(side + "-foot", stance.ankle)
        }
    }

}

extension TabletopView {
    func setMotionRate(_ rate: Double) {
        let now = CACurrentMediaTime(), newRate = max(0.1, rate)
        if activePlayback != nil {
            // Keep the current phase when changing speed during an action.
            let phase = max(0, now - motionStart) * motionRate
            motionStart = now - phase / newRate
        }
        motionRate = newRate
    }
    func cancelPlayback(reason: String = "cancel") {
        #if DEBUG
        if let receipt = activePlayback {
            MotionReviewTrace.record("native-" + reason, values: ["receipt": receipt.id.uuidString])
        }
        #endif
        #if DEBUG
        if inspectionTraceTask != nil, let id = inspectionTraceID {
            MotionReviewTrace.record("native-cancel", values: ["receipt": id.uuidString, "source": "model-inspection"])
        }
        inspectionTraceTask?.cancel(); inspectionTraceTask = nil; inspectionTraceID = nil
        #endif
        displayLink?.invalidate(); displayLink = nil; activePlayback = nil
        inspectionMotionStart = nil; inspectionIdleStart = nil
        inspectionPose?.reset(); inspectionPose = nil
        inspectionResourceEntity?.stopAllAnimations(recursive: true)
        for (entity, joints) in inspectionResourceRest { entity.jointTransforms = joints }
        for e in motionNodes { MiniatureEffects.stop(e); e.removeFromParent() }
        motionNodes = []; captureActors = [:]; cueEffects = [:]
        for (e, transform) in posedParts { e.transform = transform }; posedParts = []
        for skeleton in posedSkeletons { skeleton.reset() }; posedSkeletons = []
        for ring in sealNodes.values { ring.isEnabled = true }
        if let state = renderedState {
            for (p, e) in units {
                e.transform = Transform(translation: Self.position(p, size: state.board.size))
                e.isEnabled = true
                for h in e.children where h.name.hasPrefix("hero-") { h.orientation = simd_quatf() }
            }
        }
    }
    /// Close-up pose study shares the exact same rigid-part hierarchy as gameplay.
    /// It is an art control and cannot produce or modify any rule result.
    func beginInspectionMotion() {
        cancelPlayback()
        guard inspector, let hero = content.children.first(where: { $0.name.hasPrefix("hero-") }) else { return }
        if let imported = inspectionResourceEntity, let animation = imported.availableAnimations.first {
            let controller = imported.playAnimation(animation)
            #if DEBUG
            if MotionReviewTrace.enabled, let id = inspectionMotionID {
                inspectionTraceID = id
                let skins = SkeletonPose.collect(imported)
                MotionReviewTrace.record("native-start", values: ["receipt": id.uuidString, "source": "imported-clip",
                    "hero": inspectedHero?.rawValue ?? "None", "clip": animation.definition.name,
                    "durationSeconds": animation.definition.duration, "rate": 1])
                inspectionTraceTask = Task { @MainActor [weak self] in
                    var previous = 0.0
                    for phase in [0.55, 0.84, 1.06] {
                        do { try await Task.sleep(for: .seconds(animation.definition.duration * (phase - previous))) }
                        catch { return }
                        guard let self, self.inspectionMotionID == id else { return }
                        previous = phase
                        var angles: [String: Float] = [:]
                        for skin in skins {
                            for index in skin.model.jointNames.indices {
                                angles[skin.model.jointNames[index]] = 2 * acos(min(1, abs(simd_dot(skin.rest[index].rotation.vector, skin.model.jointTransforms[index].rotation.vector))))
                            }
                        }
                        MotionReviewTrace.record("native-sample", values: ["receipt": id.uuidString, "normalizedPhase": phase,
                            "controllerTime": controller.time, "isComplete": controller.isComplete, "jointRotationDeltaRadians": angles])
                    }
                    guard let self else { return }
                    MotionReviewTrace.record(controller.isComplete ? "native-complete" : "native-incomplete", values: ["receipt": id.uuidString])
                    self.inspectionTraceTask = nil; self.inspectionTraceID = nil
                }
            }
            #endif
            return
        }
        inspectionPose = MiniaturePose(hero: hero, heroClass: inspectedHero ?? .none)
        inspectionMotionStart = CACurrentMediaTime()
        #if DEBUG
        if let id = inspectionMotionID {
            MotionReviewTrace.record("native-start", values: ["receipt": id.uuidString, "source": "authored-pose", "durationSeconds": 1.4, "rate": 1])
        }
        #endif
        let link = CADisplayLink(target: MotionFrameTarget(self), selector: #selector(MotionFrameTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common); displayLink = link
    }
    func beginInspectionIdle() {
        cancelPlayback()
        guard inspector, let hero = content.children.first(where: { $0.name.hasPrefix("hero-") }) else { return }
        inspectionPose = MiniaturePose(hero: hero, heroClass: inspectedHero ?? .none)
        inspectionIdleStart = CACurrentMediaTime()
        #if DEBUG
        if let id = inspectionMotionID {
            MotionReviewTrace.record("native-start", values: ["receipt": id.uuidString, "source": "authored-idle",
                "hero": inspectedHero?.rawValue ?? "None", "durationSeconds": IdleHeroPose.duration * 2, "rate": 1])
        }
        #endif
        let link = CADisplayLink(target: MotionFrameTarget(self), selector: #selector(MotionFrameTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 30, preferred: 30)
        link.add(to: .main, forMode: .common); displayLink = link
    }
    func beginPlayback(_ playback: BoardPlayback) {
        cancelPlayback()
        guard playback.outcome.success, playback.plan.duration > 0 else { return }
        activePlayback = playback; motionStart = CACurrentMediaTime()
        #if DEBUG
        MotionReviewTrace.record("native-start", values: ["receipt": playback.id.uuidString, "rate": motionRate,
            "durationSeconds": playback.plan.duration, "cues": playback.plan.cues.map {
                ["kind": String(describing: $0.kind), "start": $0.start, "duration": $0.duration] as [String: Any]
            }])
        #endif
        for e in units.values {
            posedSkeletons += SkeletonPose.collect(e)
            if let hero = e.children.first(where: { $0.name.hasPrefix("hero-") }) { posedParts.append((hero, hero.transform)) }
            for name in MiniaturePose.jointNames {
                if let part = e.findEntity(named: name) { posedParts.append((part, part.transform)) }
            }
        }
        for (index, cue) in playback.plan.cues.enumerated() {
            if case .capture(let piece) = cue.kind, let p = cue.points.first {
                let e = MiniatureModels.piece(piece, heroClass: playback.before.heroClass(of: piece.owner))
                e.position = Self.position(p, size: playback.before.board.size)
                content.addChild(e); captureActors[p] = e; motionNodes.append(e)
            }
            let effect = Entity(); effect.name = "motion-\(index)"; content.addChild(effect)
            motionNodes.append(effect); cueEffects[index] = effect
            switch cue.kind {
            case .drop:
                if let p = cue.points.first { effect.position = Self.position(p, size: playback.before.board.size); effectRing(effect, .white, 0.24) }
            case .bastion:
                for p in cue.points.dropFirst() {
                    let r = Entity(); r.position = Self.position(p, size: playback.before.board.size)
                    effect.addChild(r); effectRing(r, MiniatureModels.gold, 0.32)
                }
            case .seal:
                MiniatureEffects.projectile(effect)
            case .sealExpired:
                if let p = cue.points.first { effect.position = Self.position(p, size: playback.before.board.size); effectRing(effect, .systemPurple, 0.35) }
            case .swap:
                for _ in 0..<10 { let trail = Entity(); glow(trail, .white, radius: 0.03); effect.addChild(trail) }
            case .capture:
                if let p = cue.points.first {
                    effect.position = Self.position(p, size: playback.before.board.size)
                    for i in 0..<6 {
                        let a = Float(i) * .pi / 3
                        MiniatureModels.ball(effect, MiniatureModels.gold, [cos(a) * 0.25, 0.15, sin(a) * 0.25], [0.035, 0.035, 0.035])
                    }
                }
            case .win(let player):
                let team = UIColor(player == .one ? Color.blueTeam : Color.redTeam)
                for i in 0..<24 {
                    let a = Float(i) * 2.39996, r = Float(i % 6 + 1) * 0.35
                    let e = MiniatureModels.box(effect, i % 2 == 0 ? MiniatureModels.gold : team, [cos(a) * r, 0, sin(a) * r], [0.065, 0.035, 0.08])
                    e.name = "confetti-\(i)"
                }
            case .turn(let player):
                if let p = playback.outcome.state.board.find(player, .commander) {
                    effect.position = Self.position(p, size: playback.before.board.size)
                    effectRing(effect, UIColor(player == .one ? Color.blueTeam : Color.redTeam), 0.4)
                }
            case .draw:
                for player in [Player.one, .two] {
                    if let p = playback.outcome.state.board.find(player, .commander) {
                        let node = Entity(); node.position = Self.position(p, size: playback.before.board.size)
                        effect.addChild(node); effectRing(node, MiniatureModels.gold, 0.42)
                    }
                }
            }
            effect.isEnabled = false
        }
        motionFrame(motionStart)
        let link = CADisplayLink(target: MotionFrameTarget(self), selector: #selector(MotionFrameTarget.frame(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common); displayLink = link
    }
    private func glow(_ parent: Entity, _ color: UIColor, radius: Float) {
        let e = ModelEntity(mesh: MiniatureModels.sphere(), materials: [UnlitMaterial(color: color)])
        e.scale = [radius, radius, radius]; parent.addChild(e)
    }
    private func effectRing(_ parent: Entity, _ color: UIColor, _ radius: Float) {
        let mesh = MiniatureModels.lathe("target-ring", [(0, 0.92), (0, 1), (0.06, 1), (0.06, 0.92), (0, 0.92)], sides: 48)
        MiniatureModels.part(parent, mesh, color, at: [0, 0.02, 0], scale: [radius, 0.5, radius])
    }
    func motionFrame(_ timestamp: CFTimeInterval) {
        if let start = inspectionIdleStart, let pose = inspectionPose {
            let cycles = max(0, timestamp - start) / IdleHeroPose.duration
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--idle-tour") && cycles >= 2 {
                inspectionIdleCompletedID = inspectionMotionID
                if let id = inspectionMotionID { MotionReviewTrace.record("native-complete", values: ["receipt": id.uuidString]) }
                cancelPlayback(); return
            }
            #endif
            pose.applyIdle(cycles.truncatingRemainder(dividingBy: 1)); return
        }
        if let start = inspectionMotionStart, let pose = inspectionPose {
            let t = (timestamp - start) / 1.4
            pose.apply(t)
            if t >= 1 {
                #if DEBUG
                if let id = inspectionMotionID { MotionReviewTrace.record("native-complete", values: ["receipt": id.uuidString]) }
                #endif
                cancelPlayback()
            }
            return
        }
        guard let playback = activePlayback else { return }
        let elapsed = max(0, timestamp - motionStart) * motionRate, plan = playback.plan, n = playback.before.board.size
        func actor(_ p: Point) -> Entity? { units[p] ?? captureActors[p] }
        for (index, cue) in plan.cues.enumerated() {
            let raw = (elapsed - cue.start) / cue.duration, t = MotionCurves.clamp(raw), f = Float(t)
            let effect = cueEffects[index]
            effect?.isEnabled = raw >= 0 && raw < 1
            switch cue.kind {
            case .drop:
                guard let p = cue.points.first, let e = actor(p) else { continue }
                e.isEnabled = raw >= 0
                e.position = Self.position(p, size: n) + [0, Float(MotionCurves.dropHeight(t)), 0]
                let squash = Float(MotionCurves.squash(t)); e.scale = [1 / sqrt(squash), squash, 1 / sqrt(squash)]
                effect?.isEnabled = t >= 0.70 && t < 1
                effect?.scale = SIMD3(repeating: 1 + (f - 0.7) * 2)
            case .capture:
                guard let p = cue.points.first, let e = captureActors[p] else { continue }
                guard raw >= 0 else { continue }
                e.position = Self.position(p, size: n) + [0, f * 0.65, 0]
                e.scale = SIMD3(repeating: max(0.001, 1 - Float(MotionCurves.ease(t))))
                e.orientation = simd_quatf(angle: f * 2.1, axis: [0, 1, 0]); e.isEnabled = raw < 1
                effect?.scale = SIMD3(repeating: 1 + f * 1.8)
            case .swap:
                guard cue.points.count == 2 else { continue }
                let a = cue.points[0], b = cue.points[1], pa = Self.position(a, size: n), pb = Self.position(b, size: n)
                let progress = Float(MotionCurves.swapProgress(t)), side = sin(f * .pi) * 0.36
                let direction = pb - pa, perpendicular = simd_normalize(SIMD3<Float>(-direction.z, 0, direction.x))
                let hop = SIMD3<Float>(0, sin(f * .pi) * 0.12, 0)
                let first = pa + direction * progress + perpendicular * side + hop
                let second = pb - direction * progress - perpendicular * side + hop
                actor(b)?.position = first; actor(a)?.position = second
                let hero = actor(b)?.children.first(where: { $0.name.hasPrefix("hero-") })
                groundedPose(hero, depth: sin(f * .pi) * 0.07, pitch: Float(MotionCurves.anticipation(t)) * 1.4)
                for (i, e) in (effect?.children.enumerated()).map(Array.init) ?? [] {
                    let trail = max(0, progress - Float(i % 5) * 0.06)
                    e.position = i < 5 ? pa + direction * trail + [0, 0.15, 0] : pb - direction * trail + [0, 0.15, 0]
                }
            case .bastion:
                if let p = cue.points.first {
                    let hero = units[p]?.children.first { $0.name.hasPrefix("hero-") }
                    let strike = Float(MotionCurves.shieldStrike(t))
                    groundedPose(hero, depth: sin(f * .pi) * 0.025, pitch: strike)
                    pose(hero, "left-arm", angle: -strike * 2.5)
                    pose(hero, "head", angle: -strike * 0.7)
                }
                effect?.scale = SIMD3(repeating: 1 + sin(f * .pi) * 0.3)
            case .seal:
                guard let target = cue.points.last, let source = cue.points.first else { continue }
                let hero = units[source]?.children.first(where: { $0.name.hasPrefix("hero-") })
                if let hero {
                    groundedPose(hero, depth: sin(f * .pi) * 0.012, pitch: Float(MotionCurves.anticipation(t)) * 0.6)
                    pose(hero, "right-arm", angle: -Float(MotionCurves.anticipation(t)) * 1.8)
                }
                // In the editable skeleton package the staff is weighted mesh,
                // not a separate entity. Its authored socket is arm-local:
                // crystal (0.43,1.18,0.12) minus shoulder (0.28,0.64,0).
                let a = hero?.findEntity(named: "crystal")?.position(relativeTo: content)
                    ?? hero.flatMap { SkeletonPose.collect($0).first?.position(of: "right_arm", local: [0.15, 0.54, 0.12], relativeTo: content) }
                    ?? (Self.position(source, size: n) + [0.22, 0.85, 0.05])
                let b = Self.position(target, size: n) + [0, 0.14, 0]
                func flight(_ phase: Double) -> SIMD3<Float> {
                    let progress = Float(MotionCurves.ease((phase - 0.20) / 0.55))
                    return a + (b - a) * progress + [0, sin(progress * .pi) * 0.35, 0]
                }
                // State is already committed; reveal the presentation ring only on arrival.
                sealNodes[target]?.isEnabled = t >= 0.75
                let current = flight(t)
                effect?.position = current
                effect?.scale = SIMD3(repeating: 1)
                for name in ["projectile-core", "projectile-halo"] {
                    let node = effect?.findEntity(named: name)
                    node?.isEnabled = raw >= 0 && t < 0.78
                    let radius: Float = name == "projectile-core" ? 0.052 : 0.13
                    node?.scale = SIMD3(repeating: radius * (0.65 + sin(min(1, f / 0.2) * .pi / 2) * 0.65))
                }
                let trails = effect?.children.filter { $0.name.hasPrefix("projectile-trail-") } ?? []
                for (i, e) in trails.enumerated() {
                    let age = Double(i + 1) * 0.015, phase = t - age
                    e.isEnabled = raw >= 0 && phase >= 0.20 && t < 0.88
                    let angle = Float(i) * 2.39996 + f * 6
                    let radius = Float(i + 1) * 0.0025
                    e.position = flight(phase) - current + [cos(angle) * radius, sin(angle) * radius, 0]
                    e.scale = SIMD3(repeating: 0.036 * (1 - Float(i) / 22) * max(0, 1 - max(0, f - 0.75) / 0.13))
                }
                let impact = effect?.findEntity(named: "projectile-impact")
                let arrival = Float(MotionCurves.clamp((t - 0.75) / 0.25))
                impact?.isEnabled = raw >= 0 && t >= 0.75
                impact?.position = b - current + [0, -0.10, 0]
                impact?.scale = [1 + arrival * 1.4, max(0.001, 1 - arrival), 1 + arrival * 1.4]
                MiniatureEffects.emit(effect, active: raw >= 0 && t < 0.78)
            case .sealExpired: effect?.scale = SIMD3(repeating: max(0.001, 1 - f))
            case .turn: effect?.scale = SIMD3(repeating: 1 + f * 0.35)
            case .win:
                for (i, e) in (effect?.children.enumerated()).map(Array.init) ?? [] {
                    let a = Float(i) * 2.39996, r = Float(i % 6 + 1) * (0.35 + f * 0.7)
                    e.position = [cos(a) * r, sin(f * .pi) * 2 + Float(i % 3) * 0.10, sin(a) * r]
                    e.orientation = simd_quatf(angle: f * Float(i % 4 + 1) * 2, axis: [1, 1, 0])
                }
            case .draw:
                for node in (effect?.children).map(Array.init) ?? [] { node.scale = SIMD3(repeating: 1 + sin(f * .pi) * 0.22) }
            }
        }
        if elapsed >= plan.duration { cancelPlayback(reason: "complete") }
    }
    private func pose(_ hero: Entity?, _ name: String, angle: Float) {
        guard let hero else { return }
        if let part = hero.findEntity(named: name), let rest = posedParts.first(where: { $0.0 === part })?.1 {
            part.transform = rest
            part.orientation = rest.rotation * simd_quatf(angle: angle, axis: [1, 0, 0])
        }
        for current in SkeletonPose.collect(hero) {
            posedSkeletons.first(where: { $0.model === current.model })?.rotate(name, angle: angle)
        }
    }
    private func groundedPose(_ hero: Entity?, depth: Float, pitch: Float) {
        guard let hero, let rest = posedParts.first(where: { $0.0 === hero })?.1 else { return }
        let stance = GroundedLegPose(depth: Double(depth), rootPitch: Double(pitch))
        hero.orientation = rest.rotation * simd_quatf(angle: Float(stance.rootPitch), axis: [1, 0, 0])
        hero.position.y = rest.translation.y - Float(stance.depth) * rest.scale.y
        for side in ["left", "right"] {
            pose(hero, side + "-thigh", angle: Float(stance.hip))
            pose(hero, side + "-calf", angle: Float(stance.knee))
            pose(hero, side + "-foot", angle: Float(stance.ankle))
        }
    }
}
