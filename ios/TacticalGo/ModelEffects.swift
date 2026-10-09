import UIKit
import RealityKit

/// Bounded native presentation effects. Particle timing is decorative; the
/// committed GameEngine events and MotionPlan remain the only outcome authority.
@MainActor enum MiniatureEffects {
    static func projectile(_ parent: Entity) {
        let core = ModelEntity(mesh: MiniatureModels.sphere(), materials: [UnlitMaterial(color: .white)])
        core.name = "projectile-core"; core.scale = [0.052, 0.052, 0.052]; parent.addChild(core)
        // Preloaded authored USD has emissive cyan and opacity0.25. Native iOS18
        // review caught fatal assertions in both unlit/PBR blending setters;
        // cloning a complete resource avoids mutating a cached shader here.
        let halo = ModelLibrary.magicHalo() ?? Entity()
        halo.name = "projectile-halo"; halo.scale = [0.13, 0.13, 0.13]; parent.addChild(halo)
        for i in 0..<18 {
            let trail = ModelEntity(mesh: MiniatureModels.sphere(), materials: [UnlitMaterial(color: .cyan)])
            trail.name = "projectile-trail-\(i)"; trail.scale = SIMD3(repeating: 0.035); parent.addChild(trail)
        }
        let impact = Entity(); impact.name = "projectile-impact"; parent.addChild(impact)
        let mesh = MiniatureModels.lathe("magic-impact-ring", [(0, 0.89), (0, 1), (0.06, 1), (0.06, 0.89), (0, 0.89)], sides: 48)
        let ring = ModelEntity(mesh: mesh, materials: [UnlitMaterial(color: .cyan)])
        ring.scale = [0.4, 0.35, 0.4]; impact.addChild(ring)
        impact.isEnabled = false
        if #available(iOS 18.0, *) {
            let emitter = Entity(); emitter.name = "magic-particles"
            var component = ParticleEmitterComponent.Presets.magic
            component.timing = .repeating(emit: .init(duration: 10))
            component.simulationState = .play
            component.emitterShape = .sphere; component.emitterShapeSize = [0.075, 0.075, 0.075]
            component.birthDirection = .normal; component.speed = 0.30; component.speedVariation = 0.12
            component.radialAmount = 2 * .pi
            component.particlesInheritTransform = false; component.fieldSimulationSpace = .global
            component.mainEmitter.birthRate = 70; component.mainEmitter.birthRateVariation = 0
            component.mainEmitter.size = 0.075; component.mainEmitter.sizeVariation = 0.018
            component.mainEmitter.lifeSpan = 0.36; component.mainEmitter.lifeSpanVariation = 0.04
            component.mainEmitter.sizeMultiplierAtEndOfLifespan = 0.10
            component.mainEmitter.opacityCurve = .easeFadeOut; component.mainEmitter.blendMode = .additive
            component.mainEmitter.color = .evolving(start: .single(.cyan), end: .single(UIColor.blue.withAlphaComponent(0)))
            component.mainEmitter.acceleration = [0, 0.15, 0]; component.mainEmitter.noiseStrength = 0.05
            component.spawnedEmitter = nil; component.isEmitting = false
            emitter.components.set(component); parent.addChild(emitter)
        }
    }
    static func emit(_ parent: Entity?, active: Bool) {
        guard #available(iOS 18.0, *), let emitter = parent?.findEntity(named: "magic-particles"),
              var component = emitter.components[ParticleEmitterComponent.self], component.isEmitting != active else { return }
        component.isEmitting = active
        if active { component.restart() }
        emitter.components.set(component)
    }
    static func stop(_ root: Entity) {
        if #available(iOS 18.0, *), var component = root.components[ParticleEmitterComponent.self] {
            component.isEmitting = false; component.simulationState = .stop; root.components.set(component)
        }
        for child in root.children { stop(child) }
    }
}
