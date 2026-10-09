import Foundation
import TacticalGoCore
import TacticalGoMotion

/// A committed action receipt for presentation. New previews never create receipts.
struct BoardPlayback: Sendable {
    let id = UUID()
    let before: GameState
    let action: GameAction
    let outcome: ActionOutcome
    let plan: MotionPlan
    init(before: GameState, action: GameAction, outcome: ActionOutcome) {
        self.before = before; self.action = action; self.outcome = outcome
        plan = MotionPlan.make(before: before, action: action, outcome: outcome)
    }
}
