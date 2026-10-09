import TacticalGoCore

public enum TutorialCatalog {
    public static func all() throws -> [TutorialScenario] {
        try [warriorRescue(), warriorCounterattack(), mageSplit(), mageRescue(), rogueShape(), rogueFinish()]
    }
    public static func scenario(id: String) throws -> TutorialScenario? { try all().first { $0.id == id } }
    private struct Source {
        var state: GameState
        var actions: [GameAction] = []
        init(_ hero: HeroClass) throws { state = try GameSetup.newGame(config: .board(size: 7), classOne: hero, classTwo: .none) }
        mutating func perform(_ owner: Player, _ action: GameAction) throws {
            if state.current != owner { try append(.endTurn) }
            try append(action)
        }
        mutating func append(_ action: GameAction) throws {
            let result = GameEngine.apply(state, action)
            guard result.success else { throw TutorialError.illegalSource(id: "catalog construction", step: actions.count, reason: result.reason) }
            actions.append(action); state = result.state
        }
        mutating func ready() throws -> [GameAction] {
            if state.current == .one && (state.apRemaining != 2 || state.skillUsedThisTurn) { try append(.endTurn) }
            if state.current == .two { try append(.endTurn) }
            return actions
        }
        mutating func soldiers(_ owner: Player, _ points: [Point]) throws {
            for point in points { try perform(owner, .placeSoldier(point)) }
        }
    }
    private static func branch(_ name: String, _ explanation: String, _ actions: [GameAction], _ expected: String) -> TutorialBranch {
        TutorialBranch(name: name, explanation: explanation, actions: actions, expected: expected)
    }
    private static var wrong: TutorialBranch {
        branch("player-error", "在遠處連下兩兵，耗盡 AP，沒有完成局部目標。", [.placeSoldier(Point(6, 6)), .placeSoldier(Point(6, 5))], "failed")
    }
    private static func warriorRescue() throws -> TutorialScenario {
        var source = try Source(.warrior)
        try source.soldiers(.one, [Point(1, 2)])
        try source.perform(.one, .summonHero(Point(1, 1)))
        try source.soldiers(.two, [Point(2, 1), Point(0, 2), Point(2, 2), Point(1, 3)])
        let skill = GameAction.castBastion(Point(0, 1), Point(1, 0))
        return TutorialScenario(id: "warrior-rescue", title: "戰士救援", instructions: ["英雄與相連己兵遭到包圍。運用築壘擴張這一串，保持英雄與原己兵相連並保有外氣。", "在起始回合的兩個行動內完成救援；英雄串至少增加三枚兵，並保有至少兩口氣。"], optionalHints: ["英雄與己兵只剩兩口氣。用築壘同時連出 (0,1) 與 (1,0)。", "第二個行動落在 (2,0)，延伸生路；英雄須存活且保有至少兩口氣。"], heroClass: .warrior, goal: .warriorRescue, sourceActions: try source.ready(), branches: [
            branch("solution", "築壘救援，再延伸到右上外氣。", [skill, .placeSoldier(Point(2, 0))], "completed"),
            branch("alternate-correct", "先在外側落子，再用築壘接回英雄；合法調換兩個行動的順序。", [.placeSoldier(Point(2, 0)), skill], "completed"), wrong,
            branch("wrong-outcome", "築壘後在遠處落子，沒有完成英雄串的必要擴張。", [skill, .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "築壘後放棄剩餘 AP；對手堵 (2,0) 再封 (0,0)，捕獲英雄與整串。", [skill, .endTurn, .placeSoldier(Point(2, 0)), .placeSoldier(Point(0, 0))], "failed")])
    }
    private static func warriorCounterattack() throws -> TutorialScenario {
        var source = try Source(.warrior)
        try source.soldiers(.one, [Point(3, 4)])
        try source.perform(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(4, 1), Point(5, 2)])
        try source.soldiers(.two, [Point(4, 2)])
        let skill = GameAction.castBastion(Point(3, 2), Point(4, 3))
        return TutorialScenario(id: "warrior-counterattack", title: "築壘反攻", instructions: ["運用築壘反攻，捕獲英雄右上方被夾住的敵兵。", "在兩個行動內把外側己兵與英雄串連成一隊，英雄與主將都須存活。"], optionalHints: ["敵兵 (4,2) 剩兩口氣。築壘同時填 (3,2) 與 (4,3)，捕獲它。", "第二個行動落在 (5,3)，把外側己兵接回英雄串。"], heroClass: .warrior, goal: .warriorCounterattack, sourceActions: try source.ready(), branches: [
            branch("solution", "用雙落子奪取敵兵，第二手建立連線。", [skill, .placeSoldier(Point(5, 3))], "completed"),
            branch("alternate-correct", "捕獲敵兵後佔領其原點，從另一條路把外側己兵接回英雄。", [skill, .placeSoldier(Point(4, 2))], "completed"), wrong,
            branch("wrong-outcome", "合法築壘方向沒有封住敵兵所有氣，遠端落子也未接回外側己兵。", [.castBastion(Point(3, 2), Point(2, 3)), .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "築壘後提早結束；對手在 (5,3) 切斷預定的連線點。", [skill, .endTurn, .placeSoldier(Point(5, 3))], "failed")])
    }
    private static func mageSplit() throws -> TutorialScenario {
        var source = try Source(.mage)
        try source.soldiers(.one, [Point(3, 4)])
        try source.perform(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(5, 3), Point(4, 4), Point(1, 2), Point(2, 1), Point(2, 3)])
        try source.soldiers(.two, [Point(3, 2), Point(4, 2), Point(5, 2)])
        let skill = GameAction.castMagicHand(Point(4, 2), .down)
        return TutorialScenario(id: "mage-split", title: "法師切串", instructions: ["敵兵連成一串。運用魔法之手改變連線，把原敵串分成至少兩個仍存活的棋群。", "在兩個行動內取得敵兵捕獲；英雄與己方主將須存活。"], optionalHints: ["用魔法之手把敵串中央 (4,2) 向下推到 (4,3)，分開左右兩串。", "第二個行動佔據 (4,2)，捕獲被推出的敵兵；兩側敵兵須不再相連。"], heroClass: .mage, goal: .mageSplit, sourceActions: try source.ready(), branches: [
            branch("solution", "推開橋接兵，再封住其唯一的氣。", [skill, .placeSoldier(Point(4, 2))], "completed"),
            branch("alternate-correct", "把左側連接兵向左推入另一個包圍區，再填空缺，取得捕獲並分割原敵串。", [.castMagicHand(Point(3, 2), .left), .placeSoldier(Point(3, 2))], "completed"), wrong,
            branch("wrong-outcome", "移動己兵後在遠處落子，沒有分割原敵串或取得敵兵捕獲。", [.castMagicHand(Point(3, 4), .left), .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "推兵後放棄第二手；對手重佔 (4,2)，重新接回被分開的串。", [skill, .endTurn, .placeSoldier(Point(4, 2))], "failed")])
    }
    private static func mageRescue() throws -> TutorialScenario {
        var source = try Source(.mage)
        try source.soldiers(.one, [Point(3, 4)])
        try source.perform(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(2, 2)])
        try source.soldiers(.two, [Point(1, 2), Point(2, 1), Point(3, 2)])
        let skill = GameAction.castMagicHand(Point(2, 2), .down)
        return TutorialScenario(id: "mage-rescue", title: "己兵救援", instructions: ["受威脅的孤立己兵只剩一口氣。運用魔法之手與落子，把它所在區域接回英雄串。", "在兩個行動內讓救援後的英雄棋群保有至少三口氣；英雄與主將須存活。"], optionalHints: ["(2,2) 己兵只剩一口氣。用魔法之手把它向下推到 (2,3)，接回英雄。", "第二個行動收復 (2,2)，救出的兵須與英雄相連且至少有三口氣。"], heroClass: .mage, goal: .mageRescue, sourceActions: try source.ready(), branches: [
            branch("solution", "挪走打吃己兵，再收復原點。", [skill, .placeSoldier(Point(2, 2))], "completed"),
            branch("alternate-correct", "先把另一枚己兵向左推，再以連接落子接回受威脅己兵；不要求直接移動被打吃的兵。", [.castMagicHand(Point(3, 4), .left), .placeSoldier(Point(2, 3))], "completed"), wrong,
            branch("wrong-outcome", "同樣合法移動另一己兵，但第二手在遠處，受威脅棋群仍未接回英雄。", [.castMagicHand(Point(3, 4), .left), .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "救兵後讓出第二手；對手佔 (2,2)，阻止收復原點。", [skill, .endTurn, .placeSoldier(Point(2, 2))], "failed")])
    }
    private static func rogueShape() throws -> TutorialScenario {
        var source = try Source(.rogue)
        try source.soldiers(.one, [Point(3, 4)])
        try source.perform(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(2, 3), Point(3, 2), Point(6, 3), Point(5, 4)])
        try source.soldiers(.two, [Point(4, 3), Point(5, 3)])
        let skill = GameAction.castSwap(Point(4, 3))
        return TutorialScenario(id: "rogue-shape", title: "盜賊換位破形", instructions: ["敵兵連成難以正面突破的棋形。運用換位打斷這個棋形並捕獲兩枚敵兵。", "在兩個行動內完成破形，英雄須進入原敵串所在位置並存活。"], optionalHints: ["與 (4,3) 敵兵換位；被換回英雄原點的兵將被包圍捕獲。", "第二個行動落在 (5,2)，捕獲剩餘敵兵，英雄須停留在 (4,3) 並存活。"], heroClass: .rogue, goal: .rogueShape, sourceActions: try source.ready(), branches: [
            branch("solution", "換位打斷敵串，第二手收掉外側孤兵。", [skill, .placeSoldier(Point(5, 2))], "completed"),
            branch("alternate-correct", "先封住外側敵兵的氣，再換位；同樣造成兩枚敵兵捕獲。", [.placeSoldier(Point(5, 2)), skill], "completed"), wrong,
            branch("wrong-outcome", "換位只捕獲一枚敵兵，遠端第二手沒有收掉餘下敵兵。", [skill, .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "換位後提早結束；敵兵從 (5,2) 接出外氣，逃離最後一擊。", [skill, .endTurn, .placeSoldier(Point(5, 2))], "failed")])
    }
    private static func rogueFinish() throws -> TutorialScenario {
        var source = try Source(.rogue)
        try source.soldiers(.one, [Point(3, 4)])
        try source.perform(.one, .summonHero(Point(3, 3)))
        try source.soldiers(.one, [Point(2, 1), Point(3, 0)])
        try source.soldiers(.two, [Point(3, 2)])
        let skill = GameAction.castSwap(Point(3, 2))
        return TutorialScenario(id: "rogue-finish", title: "兩手最後一擊", instructions: ["敵主將仍靠一枚敵兵保持連線。運用換位與落子切斷連線，捕獲敵主將。", "必須在起始回合兩個行動內由 Core 判定己方獲勝，己方英雄與主將須存活。"], optionalHints: ["與 (3,2) 敵兵換位，切斷它與主將的連接；這一步還不能獲勝。", "第二個行動落在 (4,1)，填主將最後一口氣，由 Core 判定捕獲主將與勝利。"], heroClass: .rogue, goal: .rogueFinish, sourceActions: try source.ready(), branches: [
            branch("solution", "先切斷主將的連線，再用剩餘 AP 捕獲主將。", [skill, .placeSoldier(Point(4, 1))], "completed"),
            branch("alternate-correct", "先封住主將側邊的氣，再換位切斷連線，以第二手取得 Core 勝利。", [.placeSoldier(Point(4, 1)), skill], "completed"), wrong,
            branch("wrong-outcome", "換位後在遠處落子，敵主將仍保有最後一口氣。", [skill, .placeSoldier(Point(6, 6))], "failed"),
            branch("opponent-counter", "換位後放棄第二手；對手從 (4,1) 延伸主將串而避免捕獲。", [skill, .endTurn, .placeSoldier(Point(4, 1))], "failed")])
    }
}
