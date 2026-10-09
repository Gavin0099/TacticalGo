import XCTest
import TacticalGoCore
import TacticalGoMotion

final class CombatFeedbackTests: XCTestCase {
    func testMagicHandCommanderCaptureAndResourcesFromReviewedPosition() throws {
        for size in [7, 9] {
            let initial = try CombatDemo.initialState(size: size)
            XCTAssertEqual(initial.board.liberties(at: Point(3, 2)), [Point(4, 2)])
            var session = GameSession(initial)
            let outcome = session.apply(CombatDemo.action)
            XCTAssertTrue(outcome.success)
            XCTAssertNil(outcome.state.board[Point(4, 3)])
            XCTAssertEqual(outcome.state.board[Point(4, 2)], Piece(.one, .soldier))
            XCTAssertNil(outcome.state.board[Point(3, 2)])
            XCTAssertEqual(outcome.state.status, .won)
            XCTAssertEqual(outcome.state.winner, .one)
            XCTAssertEqual(outcome.state.mana(of: .one), 2)
            XCTAssertEqual(outcome.state.apRemaining, 1)
            let plan = CombatFeedbackPlan.make(before: initial, action: CombatDemo.action, outcome: outcome)
            // Timing specification is hand-authored in COMBAT_FEEL_01_TIMING.md.
            XCTAssertEqual(plan.cues, [.init("mage", at: 0), .init("place", at: 0.56), .init("capture", at: 0.62), .init("victory", at: 0.96)])
            XCTAssertEqual(plan.duration, 1.55, accuracy: 0.001)
            XCTAssertTrue(session.undo())
            XCTAssertEqual(session.state, initial)
            XCTAssertTrue(session.apply(CombatDemo.action).success)
        }
    }
    func testIllegalAndInsufficientManaProduceNoSuccessSounds() throws {
        let initial = try CombatDemo.initialState()
        let poor = try GameSetup.fromDiagram(config: initial.config, diagram: initial.board.diagram, classOne: .mage, manaOne: 1, ap: 2)
        for (state, action) in [(initial, GameAction.castMagicHand(Point(4, 3), .left)), (poor, CombatDemo.action)] {
            let outcome = GameEngine.apply(state, action)
            XCTAssertFalse(outcome.success)
            XCTAssertEqual(outcome.state, state)
            XCTAssertTrue(outcome.events.isEmpty)
            XCTAssertEqual(CombatFeedbackPlan.make(before: state, action: action, outcome: outcome).cues, [])
        }
    }
    func testNonCapturePushNeverPlaysCaptureOrVictoryAndReducedMotionKeepsSound() throws {
        let initial = try GameSetup.fromDiagram(config: .board(size: 7), diagram: ".......\n...O...\n.......\n...Hx..\n.......\n...X...\n.......", classOne: .mage, manaOne: 4, ap: 2)
        let outcome = GameEngine.apply(initial, CombatDemo.action)
        XCTAssertTrue(outcome.success)
        XCTAssertEqual(outcome.state.status, .ongoing)
        let plan = CombatFeedbackPlan.make(before: initial, action: CombatDemo.action, outcome: outcome)
        XCTAssertEqual(plan.cues, [.init("mage", at: 0), .init("place", at: 0.56)])
        XCTAssertEqual(CombatFeedbackPlan.make(before: initial, action: CombatDemo.action, outcome: outcome, reducedMotion: true), plan)
    }
    func testDangerPlaysOnlyWhenCommanderEntersOneLiberty() throws {
        let initial = try GameSetup.fromDiagram(config: .board(size: 7), diagram: ".......\n...O...\n...x...\n.......\n.......\n...X...\n.......", classOne: .mage, manaOne: 4, ap: 2)
        var session = GameSession(initial)
        let first = session.apply(.placeSoldier(Point(2, 1)))
        XCTAssertFalse(CombatFeedbackPlan.make(before: initial, action: .placeSoldier(Point(2, 1)), outcome: first).cues.contains { $0.key == "danger" })
        let before = session.state
        let next = session.apply(.placeSoldier(Point(4, 1)))
        XCTAssertTrue(CombatFeedbackPlan.make(before: before, action: .placeSoldier(Point(4, 1)), outcome: next).cues.contains { $0.key == "danger" })
        let endangered = session.state
        let end = session.apply(.endTurn)
        XCTAssertFalse(CombatFeedbackPlan.make(before: endangered, action: .endTurn, outcome: end).cues.contains { $0.key == "danger" })
    }
    func testCandidateRedeployUsesSuccessfulMovementCueAndRejectsWithoutSound() throws {
        var config = RuleConfig.board(size: 7); config.experimentalFriendlyRedeploy = true
        let state = try GameSetup.fromDiagram(config: config,
            diagram: "O......\n.......\n.......\n..Hx...\n.......\n.......\n......X", classOne: .mage, manaOne: 4)
        let action = GameAction.castFriendlyRedeploy(Point(3, 3), Point(4, 3))
        let result = GameEngine.apply(state, action)
        XCTAssertTrue(result.success)
        let cues = CombatFeedbackPlan.make(before: state, action: action, outcome: result).cues
        XCTAssertEqual(cues, [.init("mage", at: 0), .init("place", at: 0.56)])
        let illegal = GameAction.castFriendlyRedeploy(Point(3, 3), Point(6, 3))
        XCTAssertTrue(CombatFeedbackPlan.make(before: state, action: illegal, outcome: GameEngine.apply(state, illegal)).cues.isEmpty)
    }

}
