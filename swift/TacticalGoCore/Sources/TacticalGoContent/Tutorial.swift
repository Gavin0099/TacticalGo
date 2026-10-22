import TacticalGoCore

public enum TutorialGoal: String, Sendable, CaseIterable {
    case warriorRescue, warriorCounterattack, mageSplit, mageRescue, rogueShape, rogueFinish
    case advancedRescue, advancedCounterattack, advancedTiming
}
public enum TutorialAssessment: Equatable, Sendable {
    case incomplete(String), completed, failed(String)
    public var label: String {
        switch self { case .incomplete: "incomplete"; case .completed: "completed"; case .failed: "failed" }
    }
}
public struct TutorialBranch: Sendable {
    public let name: String
    public let explanation: String
    public let actions: [GameAction]
    public let expected: String
}
public struct TutorialScenario: Sendable {
    public let id: String
    public let title: String
    /// Outcome-oriented prompt. It deliberately does not disclose the example coordinates.
    public let instructions: [String]
    /// Optional help, separate from the goal prompt and never a completion gate.
    public let optionalHints: [String]
    public let heroClass: HeroClass
    public let goal: TutorialGoal
    /// The full replay, including explicit turn ends, from the official new game.
    public let sourceActions: [GameAction]
    public let branches: [TutorialBranch]
    /// Content-only objective horizon; zero preserves the original challenge contract.
    public var expeditionTurns: Int = 0
    public var config: RuleConfig { .board(size: 7) }
    /// One inspected example, not the complete set of accepted tactics.
    public var canonicalSolution: [GameAction] { branches.first { $0.name == "solution" }?.actions ?? [] }
    /// Canonical skill metadata for optional hints; the evaluator accepts other legal skill targets/order.
    public var openingSkill: GameAction {
        switch goal {
        case .warriorRescue: .castBastion(Point(0, 1), Point(1, 0))
        case .warriorCounterattack: .castBastion(Point(3, 2), Point(4, 3))
        case .mageSplit: .castMagicHand(Point(4, 2), .down)
        case .mageRescue: .castMagicHand(Point(2, 2), .down)
        case .rogueShape: .castSwap(Point(4, 3))
        case .rogueFinish: .castSwap(Point(3, 2))
        case .advancedRescue: .castBastion(Point(4, 5), Point(3, 6))
        case .advancedCounterattack: .castMagicHand(Point(4, 2), .down)
        case .advancedTiming: .castSwap(Point(4, 3))
        }
    }
}
public enum TutorialError: Error {
    case illegalSource(id: String, step: Int, reason: IllegalReason)
}
public enum TutorialReplay {
    public static func start(_ scenario: TutorialScenario) throws -> GameState {
        var state = try GameSetup.newGame(config: scenario.config, classOne: scenario.heroClass, classTwo: .none)
        for (index, action) in scenario.sourceActions.enumerated() {
            let result = GameEngine.apply(state, action)
            guard result.success else { throw TutorialError.illegalSource(id: scenario.id, step: index, reason: result.reason) }
            state = result.state
        }
        return state
    }
}
/// Pedagogical progress and initial Core group snapshots; Core exclusively owns legality/state.
/// Moved same-color soldiers have no unique identity: objectives describe resulting groups/regions.
public struct TutorialSession: Sendable {
    public let scenario: TutorialScenario
    public private(set) var state: GameState
    public private(set) var actions: [GameAction] = []
    public private(set) var events: [ActionEvent] = []
    public private(set) var playerActionCount = 0
    private let initialPlayerPly: Int
    private let initialHeroGroup: Set<Point>
    private let initialEnemyGroup: Set<Point>
    private let initialFriendlyOutpost: Set<Point>
    private let threatenedFriendlyRegion: Set<Point>
    private var skillOccurred = false
    public private(set) var opponentActionCount = 0
    public private(set) var plannedOpponentActions: [GameAction] = []
    private var capturedEnemySoldiers: [CapturedPiece] = []
    private var leftInitialTurn = false
    private var actedOutsideInitialTurn = false

    public init(_ scenario: TutorialScenario) throws {
        self.scenario = scenario
        let start = try TutorialReplay.start(scenario)
        state = start; initialPlayerPly = start.ply
        initialHeroGroup = Set(start.board.find(.one, .hero).map { start.board.group(at: $0) } ?? [])
        let enemyAnchor: Point?
        switch scenario.goal {
        case .warriorCounterattack: enemyAnchor = Point(4, 2)
        case .mageSplit: enemyAnchor = Point(3, 2)
        case .rogueShape: enemyAnchor = Point(4, 3)
        default: enemyAnchor = nil
        }
        initialEnemyGroup = Set(enemyAnchor.map { start.board.group(at: $0) } ?? [])
        initialFriendlyOutpost = scenario.goal == .warriorCounterattack ? Set(start.board.group(at: Point(5, 2))) : []
        if scenario.goal == .mageRescue {
            let anchor = Point(2, 2)
            threatenedFriendlyRegion = Set(start.board.group(at: anchor)).union(start.board.liberties(at: anchor))
        } else { threatenedFriendlyRegion = [] }
    }
    @discardableResult public mutating func apply(_ action: GameAction) -> ActionOutcome {
        let actor = state.current, actorPly = state.ply
        let result = GameEngine.apply(state, action)
        if result.success {
            if actor == .two && action != .endTurn { opponentActionCount += 1 }
            if actor == .one {
                if action == .endTurn { leftInitialTurn = true }
                else {
                    playerActionCount += 1
                    if actorPly != initialPlayerPly { actedOutsideInitialTurn = true }
                    switch (scenario.heroClass, action) {
                    case (.warrior, .castBastion), (.mage, .castMagicHand), (.rogue, .castSwap): skillOccurred = true
                    default: break
                    }
                }
            }
            for event in result.events {
                if case .piecesCaptured(.one, let pieces) = event {
                    capturedEnemySoldiers += pieces.filter { $0.piece == Piece(.two, .soldier) }
                }
            }
            actions.append(action); events += result.events; state = result.state
            if [.advancedRescue, .advancedCounterattack, .advancedTiming].contains(scenario.goal) {
                if actor == .one && state.current == .two && state.status == .ongoing, case .incomplete = assessment {
                    plannedOpponentActions = AdvancedOpponent.planTurn(state, goal: scenario.goal, expedition: scenario.expeditionTurns > 0).actions
                } else if actor == .two && plannedOpponentActions.first == action {
                    plannedOpponentActions.removeFirst()
                }
            }
        }
        return result
    }
    public var assessment: TutorialAssessment {
        let board = state.board
        guard board.find(.one, .commander) != nil, state.winner != .two else { return .failed("己方主將被捕獲") }
        guard let hero = board.find(.one, .hero) else { return .failed("教學英雄被捕獲") }
        let heroGroup = Set(board.group(at: hero)), heroLiberties = board.liberties(at: hero)
        if [.advancedRescue, .advancedCounterattack, .advancedTiming].contains(scenario.goal) {
            return advancedAssessment(hero: hero, heroLiberties: heroLiberties.count)
        }
        let goalReached: Bool
        switch scenario.goal {
        case .warriorRescue:
            goalReached = initialHeroGroup.isSubset(of: heroGroup) && heroGroup.count >= initialHeroGroup.count + 3
                && heroLiberties.count >= 2
        case .warriorCounterattack:
            let capturedTarget = capturedEnemySoldiers.contains { initialEnemyGroup.contains($0.at) }
            goalReached = capturedTarget && !initialFriendlyOutpost.isEmpty && initialFriendlyOutpost.isSubset(of: heroGroup)
        case .mageSplit:
            // Distinct groups are obtained exclusively from Core, among surviving original enemy locations.
            let survivingGroups = Set(initialEnemyGroup.filter { board[$0]?.owner == .two }.map { Set(board.group(at: $0)) })
            goalReached = survivingGroups.count >= 2 && !capturedEnemySoldiers.isEmpty
        case .mageRescue:
            let connectedThreatRegion = threatenedFriendlyRegion.contains { board[$0] == Piece(.one, .soldier) && heroGroup.contains($0) }
            goalReached = connectedThreatRegion && heroGroup.count > initialHeroGroup.count && heroLiberties.count >= 3
        case .rogueShape:
            goalReached = initialEnemyGroup.contains(hero) && initialEnemyGroup.allSatisfy { board[$0]?.owner != .two }
                && capturedEnemySoldiers.count >= 2
        case .rogueFinish:
            goalReached = state.status == .won && state.winner == .one
        case .advancedRescue, .advancedCounterattack, .advancedTiming:
            preconditionFailure("Advanced objectives are assessed before this switch")
        }
        if leftInitialTurn || actedOutsideInitialTurn { return .failed("已離開教學起始回合，未在原本兩個行動內完成") }
        if playerActionCount == 2 && skillOccurred && goalReached { return .completed }
        if state.status != .ongoing { return .failed("對局已結束，未完成指定目標") }
        if playerActionCount >= 2 { return .failed("已使用兩個行動，未完成本職技能與局面目標") }
        return .incomplete("在教學起始回合完成兩個行動，包含本職技能，達成局面目標")
    }

    private func advancedAssessment(hero: Point, heroLiberties: Int) -> TutorialAssessment {
        if scenario.expeditionTurns > 0 {
            return expeditionAssessment(heroLiberties: heroLiberties)
        }
        guard let commander = state.board.find(.one, .commander) else { return .failed("己方主將已被提走。敵方利用剩餘生存空格完成包圍。") }
        let commanderLiberties = state.board.liberties(at: commander).count
        let counterPlayed = opponentActionCount > 0
        if scenario.goal == .advancedTiming, counterPlayed, state.current == .one,
           state.ply >= initialPlayerPly + 2, capturedEnemySoldiers.count >= 2,
           commanderLiberties >= 3, heroLiberties >= 2 { return .completed }
        let secondTurnFinished = state.ply >= initialPlayerPly + 3 || state.status != .ongoing
        guard secondTurnFinished else {
            if state.current == .two { return .incomplete("敵方正在反制；回應完成後再調整你的計畫。") }
            return .incomplete(counterPlayed ? "敵方已回應。完成第二回合的救援或反打，再檢查棋群與資源。" : "先制定兩次行動的計畫；敵方會根據棋形反擊。")
        }
        guard counterPlayed, playerActionCount >= 3 else { return .failed("尚未完成攻防循環：需要敵方實際反擊，並在下一回合完成計畫。") }
        if state.winner == .two { return .failed("主將被敵方連續兩次行動包圍。第一回合暫時補氣，仍需保留下一回合的出口。") }
        let requiredLiberties = scenario.goal == .advancedRescue ? 6 : 3
        guard commanderLiberties >= requiredLiberties else { return .failed("主將棋群只剩 \(commanderLiberties) 氣；反擊後仍未建立足夠的逃生空間。") }
        let requiredHeroLiberties = scenario.goal == .advancedTiming ? 2 : requiredLiberties
        guard heroLiberties >= requiredHeroLiberties else { return .failed("英雄棋群只剩 \(heroLiberties) 氣。進攻雖有效，但忽略了敵方對英雄的包圍。") }
        let required = scenario.goal == .advancedRescue ? 0 : 2
        guard capturedEnemySoldiers.count >= required else { return .failed("已提走 \(capturedEnemySoldiers.count) 名敵兵；敵方補回連線後，需要改變計畫取得兩名敵兵的戰果。") }
        return .completed
    }
    private func expeditionAssessment(heroLiberties: Int) -> TutorialAssessment {
        guard let commander = state.board.find(.one, .commander) else { return .failed("主將被提走。") }
        // The last enemy reply must finish before objective success is possible.
        let repliesFinished = state.ply >= initialPlayerPly + 2 * scenario.expeditionTurns
        if state.status != .ongoing && !repliesFinished {
            return .failed("對局已提前結束，未完成指定攻防目標。")
        }
        guard repliesFinished else {
            let round = min(scenario.expeditionTurns, (state.ply - initialPlayerPly) / 2 + 1)
            return .incomplete("第 \(round)／\(scenario.expeditionTurns) 輪：\(state.current == .two ? "等待敵方反擊完成" : "保留退路，再決定進攻")。")
        }
        guard opponentActionCount >= scenario.expeditionTurns, playerActionCount >= scenario.expeditionTurns else {
            return .failed("未完成實際攻防；跳過回合不算完成遠征。")
        }
        let commanderLiberties = state.board.liberties(at: commander).count
        // Rescue offers explicit route tradeoffs: hold D7 with three liberties in each group,
        // or open a wider route with five. The outpost is an objective, not a new Core rule.
        if scenario.goal == .advancedRescue {
            let holdsOutpost = state.board[Point(3,6)]?.owner == .one
            let minimum = min(commanderLiberties, heroLiberties)
            if minimum >= 5 || (holdsOutpost && minimum >= 3) { return .completed }
            return .failed("最後反擊後未建立通路：需雙棋群各五氣，或守住 D7 且各三氣。")
        }
        let required = 3
        guard commanderLiberties >= required else {
            return .failed("最後反擊後，主將剩 \(commanderLiberties) 氣，目標至少 \(required) 氣。")
        }
        let heroRequired = scenario.goal == .advancedTiming ? 2 : required
        guard heroLiberties >= heroRequired else {
            return .failed("最後反擊後，英雄剩 \(heroLiberties) 氣，目標至少 \(heroRequired) 氣。")
        }
        if scenario.goal != .advancedRescue && capturedEnemySoldiers.count < 2 {
            return .failed("最後反擊後已提 \(capturedEnemySoldiers.count) 名敵兵，目標至少 2 名。")
        }
        return .completed
    }

}
