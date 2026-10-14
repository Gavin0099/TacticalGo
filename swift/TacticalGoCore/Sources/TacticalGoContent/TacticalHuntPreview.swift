import TacticalGoCore

/// A read-only description of the selected hunt, using Core's actual legality.
/// It deliberately does not inherit the previously selected hero-skill mode.
public struct TacticalHuntPreview {
    public let kind: MonsterKind?
    public let reason: IllegalReason
    public let friendly: Int
    public let enemy: Int
    public let apCost: Int
    public let awardsLoot: Bool
    public init(_ state: GameState, at point: Point) {
        kind = state.config.monsterBattlefield?.kind(at:point)
        reason = GameEngine.validate(state,.huntMonster(point))
        let control = GameEngine.monsterControl(state,at:point,for:state.current)
        friendly = control.friendly; enemy = control.enemy
        apCost = state.config.monsterBattlefield?.huntAPCost ?? 0
        awardsLoot = state.config.monsterBattlefield?.awardsLoot == true
    }
    public var name: String { kind == .shadowWolf ? "暗影狼" : "史萊姆" }
    public var reward: String { kind == .shadowWolf ? "影步" : "黏彈" }
    public var title: String { "討伐 · \(name)" }
    public var summary: String { "\(apCost) AP／0 能量 · 正鄰控制 我\(friendly)：敵\(enemy)" }
    public var help: String {
        let wolf = kind == .shadowWolf ? "己方英雄須站在狼的上下左右一格。" : ""
        let loot = awardsLoot ? "取得\(reward)一次，下個己方回合可用；使用需1 AP、0能量，與職業技能共用每回合一次。" : "本局討伐不發戰利能力。"
        return "包圍不會自動討伐：點選魔物或討伐選單，再按確認。\(name)的上、下、左、右至少2格須是己子，且多於敵方；斜角不計。\(wolf)討伐需\(apCost) AP、0能量，不占施法次數。\(loot)"
    }
    public var targetRestriction: String? {
        switch reason {
        case .insufficientMonsterControl: "正鄰控制 我\(friendly)：敵\(enemy)；友軍需至少2格且多於敵方"
        case .noHeroOnBoard where kind == .shadowWolf: "己方英雄須站在狼的上下左右一格"
        default: nil
        }
    }
}
