import TacticalGoCore

public enum TacticalHintMode: Sendable { case soldier, summon, skill, advanced, loot }

/// Read-only suggestions backed by successful Core actions. Advanced search is bounded.
public enum TacticalHints {
    public static func updatedConfig(size: Int, advancedCost: Int = 4) -> RuleConfig {
        var c = RuleConfig.board(size: size)
        c.expansionSkills = true; c.expansionSkillManaCost = advancedCost
        c.bastionScope = .connectedGroup; c.experimentalFriendlyRedeploy = true
        return c
    }
    public static func targets(_ state: GameState, mode: TacticalHintMode, selected: [Point],
                               ability: MonsterAbility = .stickyBounce) -> Set<Point> {
        guard state.status == .ongoing, state.apRemaining > 0 else { return [] }
        if mode == .soldier || mode == .summon {
            return Set(state.board.points.filter {
                GameEngine.validate(state, mode == .soldier ? .placeSoldier($0) : .summonHero($0)) == .none
            })
        }
        let actions = GameEngine.legalActions(state, expansionCandidateLimit: mode == .advanced ? 512 : 1)
        var result: Set<Point> = []
        for action in actions {
            let paths: [[Point]]
            switch (mode, action) {
            case (.skill, .castBastion(let a, let b)): paths = [[a,b],[b,a]]
            case (.skill, .castFriendlyRedeploy(let a, let b)) where state.config.experimentalFriendlyRedeploy: paths = [[a,b]]
            case (.skill, .castMagicHand(let p, _)) where !state.config.experimentalFriendlyRedeploy: paths = [[p]]
            case (.skill, .castSwap(let p)), (.skill, .castOffering(let p)): paths = [[p]]
            case (.advanced, .castReformation(let a, let b)), (.advanced, .castDoublePull(let a, let b)):
                paths = [[a.from,a.to,b.from,b.to],[b.from,b.to,a.from,a.to]]
            case (.advanced, .castChainSwap(let a, let b)): paths = [[a,b]]
            case (.loot, .useStickyBounce(let a, let b)) where ability == .stickyBounce: paths = [[a,b]]
            case (.loot, .useShadowStep(let p)) where ability == .shadowStep: paths = [[p]]
            default: continue
            }
            for path in paths where selected.count < path.count && Array(path.prefix(selected.count)) == selected {
                result.insert(path[selected.count])
            }
        }
        return result
    }
}
