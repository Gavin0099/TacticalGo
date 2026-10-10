import Foundation
import TacticalGoCore
import TacticalGoMotion

/// A committed action receipt for presentation. New previews never create receipts.
struct BoardPlayback: Sendable {
    let id = UUID()
    let startedAt = Date()
    let startedUptime = ProcessInfo.processInfo.systemUptime
    let before: GameState
    let action: GameAction
    let outcome: ActionOutcome
    let plan: MotionPlan
    let mageTempo: MageTempo
    let heroPerformance: HeroPerformance?
    var magicHand: Anim01MagicHand? { Anim01MagicHand.make(before: before, action: action, outcome: outcome, tempo: mageTempo) }
    var skillVFX: SkillVFX? { SkillVFX.make(before: before, action: action, outcome: outcome, tempo: mageTempo) }
    var mageSummon: Point? {
        guard outcome.success, case .summonHero(let point) = action, before.heroClass(of: before.current) == .mage else { return nil }
        return point
    }
    var visualDuration: Double { magicHand?.duration ?? heroPerformance?.duration ?? (mageSummon != nil ? max(plan.duration, mageTempo.timing.summonEnd) : plan.duration) }
    init(before: GameState, action: GameAction, outcome: ActionOutcome, mageTempo: MageTempo = .full) {
        self.mageTempo = mageTempo
        self.before = before; self.action = action; self.outcome = outcome
        let performance = HeroPerformance.make(before:before,action:action,outcome:outcome)
        heroPerformance = performance
        plan = performance?.plan ?? MotionPlan.make(before: before, action: action, outcome: outcome)
    }
}
