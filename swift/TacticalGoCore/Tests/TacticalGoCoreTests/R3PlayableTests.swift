import XCTest
@testable import TacticalGoCore

final class R3PlayableTests: XCTestCase {
    private let dense = "O..x...\n..xxx..\n.xxxxx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X"
    private var config: RuleConfig {
        var c = RuleConfig.board(size: 7)
        c.bastionScope = .connectedGroup; c.experimentalFriendlyRedeploy = true
        return c
    }
    func testPersistedActionDelegatesExactStateEventsAndAtomicRejections() throws {
        let from = Point(3, 2), to = Point(1, 1)
        var state = try GameSetup.fromDiagram(config: config, diagram: dense, classOne: .mage, manaOne: 4)
        let compatibility = GameEngine.applyExperimentalRedeployment(state, FriendlyRedeployment(from: from, to: to))
        let result = GameEngine.apply(state, .castFriendlyRedeploy(from, to))
        XCTAssertEqual(result, compatibility)
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.state.board.diagram, "O..x...\n.xxxx..\n.xx.xx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X")
        XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecePushed(caster: .one, from: from, to: to, piece: Piece(.one, .soldier))])
        state.history.insert(result.state.board.diagram)
        let rejected = GameEngine.apply(state, .castFriendlyRedeploy(from, to))
        XCTAssertEqual(rejected.reason, .ko); XCTAssertEqual(rejected.state, state); XCTAssertTrue(rejected.events.isEmpty)
    }
    func testDefaultRejectsNewActionAndCandidateEnumerationKeepsAllOriginalActions() throws {
        let original = try GameSetup.fromDiagram(config: .board(size: 7), diagram: dense, classOne: .mage, manaOne: 4)
        XCTAssertEqual(GameEngine.apply(original, .castFriendlyRedeploy(Point(3, 2), Point(1, 1))).reason, .skillNotSelected)
        let candidate = try GameSetup.fromDiagram(config: config, diagram: dense, classOne: .mage, manaOne: 4)
        let actions = GameEngine.legalActions(candidate)
        let redeploy = actions.filter { if case .castFriendlyRedeploy = $0 { return true }; return false }
        let retained = actions.filter { if case .castFriendlyRedeploy = $0 { return false }; return true }
        XCTAssertEqual(retained, GameEngine.legalActions(original))
        XCTAssertEqual(redeploy.count, 144)
        XCTAssertEqual(redeploy, GameEngine.legalExperimentalRedeployments(candidate).map { .castFriendlyRedeploy($0.source, $0.destination) })
        for action in redeploy { XCTAssertTrue(GameEngine.apply(candidate, action).success) }
    }
    func testEnumerationGateCannotExposeIllegalSkills() throws {
        let action = GameAction.castFriendlyRedeploy(Point(3, 2), Point(1, 1))
        var state = try GameSetup.fromDiagram(config: config, diagram: dense, classOne: .mage, manaOne: 1)
        XCTAssertEqual(GameEngine.apply(state, action).reason, .notEnoughMana)
        XCTAssertTrue(GameEngine.legalExperimentalRedeployments(state).isEmpty)
        XCTAssertFalse(GameEngine.legalActions(state).contains(action))
        state.mana[0] = 4; state.apRemaining = 0
        XCTAssertEqual(GameEngine.legalActions(state), [.endTurn])
        state.apRemaining = 2; state.skillUsedThisTurn = true
        XCTAssertTrue(GameEngine.legalExperimentalRedeployments(state).isEmpty)
        let warrior = try GameSetup.fromDiagram(config: config, diagram: dense, classOne: .warrior, manaOne: 4)
        XCTAssertTrue(GameEngine.legalExperimentalRedeployments(warrior).isEmpty)
    }
    func testOriginalMagicHandRemainsAndBothMageActionsShareOneSkill() throws {
        let state = try GameSetup.fromDiagram(config: config, diagram: "O......\n.......\n..x....\n..Hx...\n.......\n.......\n......X", classOne: .mage, manaOne: 4)
        let push = GameAction.castMagicHand(Point(3, 3), .right)
        let redeploy = GameAction.castFriendlyRedeploy(Point(3, 3), Point(3, 2))
        let legal = GameEngine.legalActions(state)
        XCTAssertTrue(legal.contains(push)); XCTAssertTrue(legal.contains(redeploy))
        for first in [push, redeploy] {
            let result = GameEngine.apply(state, first)
            XCTAssertTrue(result.success); XCTAssertEqual(result.state.apRemaining, 1)
            XCTAssertEqual(result.state.mana(of: .one), 2); XCTAssertTrue(result.state.skillUsedThisTurn)
            for second in [push, redeploy] {
                let rejected = GameEngine.apply(result.state, second)
                XCTAssertEqual(rejected.reason, .skillAlreadyUsed); XCTAssertEqual(rejected.state, result.state)
                XCTAssertTrue(rejected.events.isEmpty)
            }
        }
    }
    func testUndoAndTurnReturnRestoreExactKoHistoryForRedeployment() throws {
        let start = try GameSetup.fromDiagram(config: config, diagram: "O......\n.......\n..x....\n..Hx...\n.......\n.......\n......X", classOne: .mage, manaOne: 6)
        let forward = GameAction.castFriendlyRedeploy(Point(3, 3), Point(3, 2))
        let reverse = GameAction.castFriendlyRedeploy(Point(3, 2), Point(3, 3))
        var session = GameSession(start)
        XCTAssertTrue(session.apply(forward).success)
        XCTAssertTrue(session.apply(.endTurn).success); XCTAssertTrue(session.apply(.endTurn).success)
        let before = session.state, rejected = session.apply(reverse)
        XCTAssertEqual(rejected.reason, .ko); XCTAssertEqual(session.state, before)
        XCTAssertEqual(session.log, [forward, .endTurn, .endTurn])
        for _ in 0..<3 { XCTAssertTrue(session.undo()) }
        XCTAssertEqual(session.state, start); XCTAssertTrue(session.log.isEmpty)
        XCTAssertTrue(session.apply(forward).success, "Undo must remove the new board from superko history")
    }
    func testCandidateLastAPHandsOffThroughStandardSession() throws {
        let state = try GameSetup.fromDiagram(config: config, diagram: dense, classOne: .mage, manaOne: 4, ap: 1)
        var session = GameSession(state)
        let result = session.apply(.castFriendlyRedeploy(Point(3, 2), Point(1, 1)))
        XCTAssertTrue(result.success); XCTAssertEqual(result.state.current, .two)
        XCTAssertEqual(result.state.apRemaining, 2); XCTAssertFalse(result.state.skillUsedThisTurn)
        XCTAssertEqual(result.state.mana(of: .one), 2)
        XCTAssertEqual(result.events.map(\.name), ["ResourcesSpent", "PiecePushed", "TurnEnded", "TurnStarted"])
        XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, state)
    }
}
