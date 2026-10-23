import TacticalGoCore

public struct ChallengeReply: Sendable {
    public let actions: [GameAction]
    public let explicitTransitions: Int
    public let budgetExhausted: Bool
    public let reason: String
}

/// A bounded opponent for these three fixtures, not a general-purpose Bot upgrade.
/// Captures, turns, costs and all legality come from unchanged Core.
public enum AdvancedOpponent {
    public static func planTurn(_ root: GameState, goal: TutorialGoal, maxTransitions: Int = 2_000, expedition: Bool = false) -> ChallengeReply {
        guard root.current == .two, root.status == .ongoing else {
            return ChallengeReply(actions: [], explicitTransitions: 0, budgetExhausted: false, reason: "不在敵方回合")
        }
        var work = 0
        let budget = max(1, maxTransitions)
        func apply(_ state: GameState, _ action: GameAction) -> ActionOutcome? {
            guard work < budget else { return nil }
            work += 1
            let result = GameEngine.apply(state, action)
            return result.success ? result : nil
        }
        func key(_ actions: [GameAction]) -> String { actions.map { String(describing: $0) }.joined(separator: "/") }
        let oneBefore = root.board.points.filter { root.board[$0]?.owner == .one }.count
        let threatenedEnemyGroups = root.board.points.filter { root.board[$0]?.owner == .two && root.board.liberties(at: $0).count <= 2 }
        func score(_ state: GameState) -> Int {
            if state.winner == .two { return 1_000_000 }
            if state.winner == .one { return -1_000_000 }
            // Observed TG12 exploit: a remote one-stone sacrifice distracted the rescue
            // opponent from the commander. Only this scenario devalues material bait.
            let captureWeight = expedition && goal == .advancedRescue ? 50 : 900
            var value = (oneBefore - state.board.points.filter { state.board[$0]?.owner == .one }.count) * captureWeight
            for p in threatenedEnemyGroups {
                if state.board[p]?.owner != .two { value -= 1_000 }
                else { value += min(4, state.board.liberties(at: p).count) * 150 }
            }
            if let commander = state.board.find(.two, .commander) {
                let liberties = state.board.liberties(at: commander).count
                value += min(3, liberties) * 100
                if liberties <= 2 { value -= 10_000 }
            }
            if let commander = state.board.find(.one, .commander) {
                value -= min(12, state.board.liberties(at: commander).count) * (goal == .advancedRescue ? 120 : 20)
            }
            if let hero = state.board.find(.one, .hero) {
                value -= min(8, state.board.liberties(at: hero).count) * (goal == .advancedTiming ? 130 : 40)
            }
            return value
        }
        var first: [(GameAction, GameState, Int)] = []
        for action in GameEngine.legalActions(root) {
            guard let result = apply(root, action) else { break }
            first.append((action, result.state, score(result.state)))
        }
        first.sort { $0.2 == $1.2 ? key([$0.0]) < key([$1.0]) : $0.2 > $1.2 }
        var best: ([GameAction], GameState, Int)?
        for (action, after, _) in first.prefix(12) {
            if after.current != .two || after.status != .ongoing {
                let candidate = ([action], after, score(after))
                if best == nil || candidate.2 > best!.2 { best = candidate }
                continue
            }
            for second in GameEngine.legalActions(after) {
                guard let result = apply(after, second) else { break }
                guard result.state.current != .two || result.state.status != .ongoing else { continue }
                let actions = [action, second], value = score(result.state)
                if best == nil || value > best!.2 || (value == best!.2 && key(actions) < key(best!.0)) {
                    best = (actions, result.state, value)
                }
            }
            if work >= budget { break }
        }
        return ChallengeReply(actions: best?.0 ?? [.endTurn], explicitTransitions: work,
                              budgetExhausted: work >= budget,
                              reason: "依棋形保護受威脅棋群，並壓縮主將或英雄的氣；只比較有限的敵方完整回合。")
    }
}
