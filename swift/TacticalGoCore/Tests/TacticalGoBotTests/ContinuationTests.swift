import XCTest
import TacticalGoCore
@testable import TacticalGoBot

final class ContinuationTests: XCTestCase {
    func testDefaultAndEasyRemainBaselineAndTinyBudgetIsLegal() throws {
        let root=try GameSetup.newGame(config:.board(size:7),classOne:.mage,classTwo:.rogue)
        for difficulty in BotDifficulty.allCases {
            let old=try XCTUnwrap(BotPlanner.planTurn(root,difficulty:difficulty))
            let explicit=try XCTUnwrap(BotPlanner.planTurn(root,difficulty:difficulty,policy:.baseline))
            XCTAssertEqual(old.actions,explicit.actions);XCTAssertEqual(old.stats.domainTransitions,explicit.stats.domainTransitions)
            let option=try XCTUnwrap(BotPlanner.planTurn(root,difficulty:difficulty,policy:.forcingContinuation))
            if difficulty == .easy {XCTAssertEqual(option.actions,old.actions);XCTAssertEqual(option.stats.domainTransitions,old.stats.domainTransitions)}
        }
        let tiny=try XCTUnwrap(BotPlanner.planTurn(root,limits:BotLimits(maxDomainTransitions:1),policy:.forcingContinuation))
        XCTAssertEqual(tiny.actions,[.endTurn]);XCTAssertLessThanOrEqual(tiny.stats.domainTransitions,1)
        XCTAssertTrue(GameEngine.apply(root,tiny.actions[0]).success)
        XCTAssertNil(BotPlanner.planTurn(root,policy:.forcingContinuation,cancelled:{true}))
    }
    /// Independently specified positive control: the enclosed commander has four exits,
    /// the outer wall has an independently retained corner liberty. Injecting a pass baseline tests the proof oracle only;
    /// it is deliberately NOT evidence the real baseline incorrectly passes here.
    func testOracleRequiresEveryEnemyTurnAndHasARealPositiveControl() throws {
        let root=try GameSetup.fromDiagram(config:.board(size:7),diagram:".xxxxxx\nxxxxxxx\nxxx.xxx\nxx.O.xx\nxxx.xxx\nxxxXxxx\nxxxxxxx",classOne:.none,classTwo:.none,manaOne:6,manaTwo:6,ap:2,ply:15)
        XCTAssertEqual(root.board.liberties(at:Point(3,3)).count,4)
        let opening:[GameAction]=[.placeSoldier(Point(3,2)),.placeSoldier(Point(2,3))]
        var after=root
        for action in opening {let out=GameEngine.apply(after,action);XCTAssertTrue(out.success);after=out.state}
        XCTAssertEqual(after.board.liberties(at:Point(3,3)).count,2)
        let baseline=BotTurnPlan(actions:[.endTurn],reasons:["Injected positive-control baseline"],stats:BotSearchStats(),score:0)
        var oracle=BotContinuation(root:root,baseline:baseline,limits:.standard,candidates:[BotTurnCandidate(state:after,actions:opening)],cancelled:{false})
        let result=try XCTUnwrap(oracle.run())
        XCTAssertEqual(result.actions,opening)
        XCTAssertEqual(result.stats.continuationComparisons.filter {$0.hasPrefix("proved-reply:")}.count,3, "Enemy can pass, extend east then pass, or extend south then pass; the last internal fill is suicide")
        XCTAssertLessThanOrEqual(result.stats.domainTransitions,6_000)
        XCTAssertFalse(result.stats.budgetExhausted)
        XCTAssertNotEqual(after.status,.won,"The selected first turn has not yet won")
    }
    func testInsufficientOracleBudgetCannotPublishPartialProof() throws {
        let root=try GameSetup.fromDiagram(config:.board(size:7),diagram:".xxxxxx\nxxxxxxx\nxxx.xxx\nxx.O.xx\nxxx.xxx\nxxxXxxx\nxxxxxxx",classOne:.none,classTwo:.none,manaOne:6,manaTwo:6,ap:2,ply:15)
        let opening: [GameAction] = [.placeSoldier(Point(3,2)), .placeSoldier(Point(2,3))]
        var after = root
        for action in opening {
            let out = GameEngine.apply(after, action)
            XCTAssertTrue(out.success); after = out.state
        }
        let baseline=BotTurnPlan(actions:[.endTurn],reasons:[],stats:BotSearchStats(),score:0)
        var oracle=BotContinuation(root:root,baseline:baseline,limits:BotLimits(maxDomainTransitions:2),candidates:[BotTurnCandidate(state:after,actions:opening)],cancelled:{false})
        let result=try XCTUnwrap(oracle.run())
        XCTAssertEqual(result.actions,[.endTurn])
        XCTAssertTrue(result.stats.budgetExhausted)
        XCTAssertFalse(result.stats.continuationComparisons.contains {$0.hasPrefix("proved-reply:")})
    }
    func testCancellationAfterProofWorkStartsCannotPublishTheCandidate() throws {
        let root = try GameSetup.fromDiagram(config: .board(size: 7), diagram: ".xxxxxx\nxxxxxxx\nxxx.xxx\nxx.O.xx\nxxx.xxx\nxxxXxxx\nxxxxxxx", classOne: .none, classTwo: .none, manaOne: 6, manaTwo: 6, ap: 2, ply: 15)
        let opening: [GameAction] = [.placeSoldier(Point(3,2)), .placeSoldier(Point(2,3))]
        var after = root
        for action in opening { after = GameEngine.apply(after, action).state }
        let baseline = BotTurnPlan(actions: [.endTurn], reasons: [], stats: BotSearchStats(), score: 0)
        for stopAt in [2, 5] {
            let cancellation = ProofCancellation(stopAt: stopAt)
            var oracle = BotContinuation(root: root, baseline: baseline, limits: .standard,
                candidates: [BotTurnCandidate(state: after, actions: opening)], cancelled: { cancellation.next() })
            XCTAssertNil(oracle.run(), "A partial proof cannot escape cancellation")
            XCTAssertLessThanOrEqual(oracle.stats.domainTransitions, 6_000)
            XCTAssertEqual(root.board.liberties(at: Point(3,3)).count, 4)
        }
    }
}

private final class ProofCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var calls = 0
    private let stopAt: Int
    init(stopAt: Int) { self.stopAt = stopAt }
    func next() -> Bool {
        lock.lock(); defer { lock.unlock() }
        calls += 1
        return calls >= stopAt
    }
}
