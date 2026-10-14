import TacticalGoCore

/// Global prerequisites only. A nil restriction still requires Core target validation.
public enum TacticalRestriction: Equatable, Sendable {
    case finished, noActions, noClass, needsHero, heroLost, used, alreadySummoned
    case mana(needed: Int, current: Int), noLoot, lootLocked, unsupported
    public var message: String {
        switch self {
        case .finished: "對局已結束"
        case .noActions: "沒有行動點，請結束回合"
        case .noClass: "請先選擇英雄職業"
        case .needsHero: "請先召喚英雄，才能施放技能"
        case .heroLost: "英雄已離場，本局不能再次召喚"
        case .used: "本回合已施法，下一回合才能再用"
        case .alreadySummoned: "本局已召喚過英雄，不能再召喚"
        case .mana(let needed,let current): "能量不足：需要\(needed)，目前\(current)"
        case .noLoot: "尚未取得這項戰利能力"
        case .lootLocked: "戰利能力下個己方回合才解鎖"
        case .unsupported: "此職業／規則沒有這項技能"
        }
    }
}

public enum TacticalReadiness {
    public static func restriction(_ state: GameState, mode: TacticalHintMode,
                                   ability: MonsterAbility = .stickyBounce) -> TacticalRestriction? {
        guard state.status == .ongoing else { return .finished }
        guard state.apRemaining > 0 else { return .noActions }
        let hero = state.heroClass(of:state.current)
        if mode == .summon {
            guard hero != .none else { return .noClass }
            guard !state.hasSummonedHero(state.current) else { return .alreadySummoned }
        }
        if mode == .skill || mode == .advanced || mode == .loot {
            guard !state.skillUsedThisTurn else { return .used }
            if mode != .loot || ability == .shadowStep {
                guard state.board.find(state.current,.hero) != nil else {
                    return state.hasSummonedHero(state.current) ? .heroLost : .needsHero
                }
            }
        }
        if mode == .advanced && (!state.config.expansionSkills || hero == .priest || hero == .none) { return .unsupported }
        let cost = mode == .advanced ? state.config.expansionSkillManaCost : mode == .skill ? state.config.skillManaCost : mode == .summon ? state.config.summonCost(hero) : 0
        let mana = state.mana(of:state.current)
        guard mana >= cost else { return .mana(needed:cost,current:mana) }
        if mode == .loot {
            guard let loot = state.loot(of:state.current,ability:ability) else { return .noLoot }
            if state.ply < loot.unlockPly { return .lootLocked }
        }
        return nil
    }
}
