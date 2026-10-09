import TacticalGoCore

public enum TutorialGoal: String, Sendable, CaseIterable {
    case warriorRescue, warriorCounterattack, mageSplit, mageRescue, rogueShape, rogueFinish
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
        }
        return result
    }
    public var assessment: TutorialAssessment {
        let board = state.board
        guard board.find(.one, .commander) != nil, state.winner != .two else { return .failed("己方主將被捕獲") }
        guard let hero = board.find(.one, .hero) else { return .failed("教學英雄被捕獲") }
        let heroGroup = Set(board.group(at: hero)), heroLiberties = board.liberties(at: hero)
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
        }
        if leftInitialTurn || actedOutsideInitialTurn { return .failed("已離開教學起始回合，未在原本兩個行動內完成") }
        if playerActionCount == 2 && skillOccurred && goalReached { return .completed }
        if state.status != .ongoing { return .failed("對局已結束，未完成指定目標") }
        if playerActionCount >= 2 { return .failed("已使用兩個行動，未完成本職技能與局面目標") }
        return .incomplete("在教學起始回合完成兩個行動，包含本職技能，達成局面目標")
    }
}
