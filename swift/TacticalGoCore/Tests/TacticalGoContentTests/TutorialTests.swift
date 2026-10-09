import XCTest
import TacticalGoCore
@testable import TacticalGoContent

final class TutorialTests: XCTestCase {
    private func branch(_ scenario: TutorialScenario, _ name: String) throws -> TutorialBranch {
        try XCTUnwrap(scenario.branches.first { $0.name == name })
    }
    func testSixOfficialSourcesReplayAndKeepBothCommandersAlive() throws {
        let scenarios = try TutorialCatalog.all()
        XCTAssertEqual(scenarios.count, 6)
        XCTAssertEqual(Set(scenarios.map(\.id)).count, 6)
        XCTAssertEqual(Set(scenarios.map(\.goal)).count, 6)
        for scenario in scenarios {
            var state = try GameSetup.newGame(config: .board(size: 7), classOne: scenario.heroClass, classTwo: .none)
            XCTAssertEqual(state.board.find(.one, .commander), Point(3, 5))
            XCTAssertEqual(state.board.find(.two, .commander), Point(3, 1))
            XCTAssertEqual(state.board.points.filter { state.board[$0] != nil }.count, 2)
            for action in scenario.sourceActions {
                let before = state
                let result = GameEngine.apply(before, action)
                XCTAssertTrue(result.success, "\(scenario.id): \(action): \(result.reason)")
                XCTAssertEqual(result.state.status, .ongoing)
                XCTAssertNotNil(result.state.board.find(.one, .commander))
                XCTAssertNotNil(result.state.board.find(.two, .commander))
                let spent = result.events.compactMap { event -> (Int, Int)? in
                    if case .resourcesSpent(_, let ap, let mana) = event { return (ap, mana) }; return nil
                }
                if action == .endTurn { XCTAssertTrue(spent.isEmpty) }
                else {
                    XCTAssertEqual(spent.count, 1); XCTAssertEqual(spent.first?.0, 1)
                    XCTAssertGreaterThan(before.apRemaining, 0)
                    XCTAssertGreaterThanOrEqual(result.state.mana(of: before.current), 0)
                }
                state = result.state
            }
            XCTAssertEqual(state, try TutorialReplay.start(scenario))
            XCTAssertEqual(state.config, .board(size: 7))
            XCTAssertEqual(state.current, .one); XCTAssertEqual(state.apRemaining, 2)
            XCTAssertFalse(state.skillUsedThisTurn)
            XCTAssertTrue(state.hasSummonedHero(.one)); XCTAssertFalse(state.hasSummonedHero(.two))
            XCTAssertNotNil(state.board.find(.one, .hero))
            XCTAssertGreaterThanOrEqual(state.mana(of: .one), state.config.skillManaCost)
        }
    }
    func testEveryBranchIndependentlyRunsCoreAndMatchesObservableGoal() throws {
        for scenario in try TutorialCatalog.all() {
            for branch in scenario.branches {
                var core = try TutorialReplay.start(scenario)
                var session = try TutorialSession(scenario)
                XCTAssertEqual(session.assessment.label, "incomplete")
                for (index, action) in branch.actions.enumerated() {
                    let expected = GameEngine.apply(core, action)
                    if branch.name == "opponent-counter" && index >= 2 { XCTAssertEqual(core.current, .two) }
                    XCTAssertTrue(expected.success, "\(scenario.id)/\(branch.name)/\(index): \(expected.reason)")
                    let observed = session.apply(action)
                    XCTAssertEqual(observed, expected)
                    XCTAssertEqual(session.state, expected.state)
                    core = expected.state
                    if index == 0 { XCTAssertEqual(session.assessment.label, "incomplete", "One action must never pass") }
                }
                XCTAssertEqual(session.assessment.label, branch.expected, "\(scenario.id)/\(branch.name)")
                if branch.expected == "completed" { XCTAssertEqual(session.playerActionCount, 2) }
            }
        }
    }
    func testOccupiedAndOutOfBoundsRejectionCannotAdvanceProgress() throws {
        for scenario in try TutorialCatalog.all() {
            var session = try TutorialSession(scenario)
            let before = session.state
            XCTAssertEqual(session.apply(.placeSoldier(Point(3, 5))).reason, .occupied)
            XCTAssertEqual(session.apply(.placeSoldier(Point(-1, 0))).reason, .outOfBounds)
            XCTAssertEqual(session.state, before)
            XCTAssertTrue(session.actions.isEmpty); XCTAssertTrue(session.events.isEmpty)
            XCTAssertEqual(session.playerActionCount, 0); XCTAssertEqual(session.assessment.label, "incomplete")
        }
    }
    func testSkillConsumesOneAPManaAndCannotBeRepeatedSameTurn() throws {
        for scenario in try TutorialCatalog.all() {
            var session = try TutorialSession(scenario)
            let skill = try XCTUnwrap(scenario.branches.first { $0.name == "solution" }?.actions.first)
            let mana = session.state.mana(of: .one)
            XCTAssertTrue(session.apply(skill).success)
            XCTAssertEqual(session.state.apRemaining, 1)
            XCTAssertEqual(session.state.mana(of: .one), mana - 2)
            XCTAssertTrue(session.state.skillUsedThisTurn)
            let after = session.state
            XCTAssertEqual(session.apply(skill).reason, .skillAlreadyUsed)
            XCTAssertEqual(session.state, after)
            XCTAssertEqual(session.playerActionCount, 1)
            XCTAssertEqual(session.assessment.label, "incomplete")
        }
    }
    func testExactTeachingInvariantsAreCoreQueries() throws {
        let all = try TutorialCatalog.all()
        let rescue = try TutorialReplay.start(XCTUnwrap(all.first { $0.id == "warrior-rescue" }))
        XCTAssertEqual(rescue.board.liberties(at: Point(1, 1)), Set([Point(0, 1), Point(1, 0)]))
        let mage = try TutorialReplay.start(XCTUnwrap(all.first { $0.id == "mage-rescue" }))
        XCTAssertEqual(mage.board.liberties(at: Point(2, 2)), Set([Point(2, 3)]))
        let split = try XCTUnwrap(all.first { $0.id == "mage-split" })
        var session = try TutorialSession(split)
        XCTAssertTrue(session.state.board.group(at: Point(3, 2)).contains(Point(5, 2)))
        XCTAssertTrue(session.apply(split.canonicalSolution[0]).success)
        XCTAssertFalse(session.state.board.group(at: Point(3, 2)).contains(Point(5, 2)))
        XCTAssertEqual(session.state.board.liberties(at: Point(4, 3)), Set([Point(4, 2)]))
        let counter = try branch(split, "opponent-counter").actions.dropFirst()
        for action in counter { XCTAssertTrue(session.apply(action).success) }
        XCTAssertTrue(session.state.board.group(at: Point(3, 2)).contains(Point(5, 2)))
        XCTAssertEqual(session.assessment.label, "failed")
    }
    func testRogueFinishNeedsTwoActionsAndCoreCommanderCapture() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "rogue-finish"))
        var session = try TutorialSession(scenario)
        XCTAssertTrue(session.apply(scenario.canonicalSolution[0]).success)
        XCTAssertEqual(session.state.status, .ongoing)
        XCTAssertEqual(session.state.board.liberties(at: Point(3, 1)), Set([Point(4, 1)]))
        XCTAssertEqual(session.assessment.label, "incomplete")
        let result = session.apply(scenario.canonicalSolution[1])
        XCTAssertEqual(result.state.status, .won); XCTAssertEqual(result.state.winner, .one)
        XCTAssertTrue(result.events.contains(.gameWon(.one)))
        XCTAssertTrue(result.events.contains { event in
            if case .piecesCaptured(.one, let pieces) = event {
                return pieces.contains { $0.at == Point(3, 1) && $0.piece == Piece(.two, .commander) }
            }; return false
        })
        XCTAssertEqual(session.assessment, .completed)
    }
    func testDelayedSecondActionDoesNotPassTwoActionTurn() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "mage-rescue"))
        var session = try TutorialSession(scenario)
        for action in [scenario.canonicalSolution[0], .endTurn, .endTurn, scenario.canonicalSolution[1]] {
            XCTAssertTrue(session.apply(action).success)
        }
        XCTAssertEqual(session.assessment.label, "failed")
    }
    func testAlternateMagicHandRescueConnectsThreatenedRegionWithThreeLiberties() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "mage-rescue"))
        var session = try TutorialSession(scenario)
        XCTAssertTrue(session.apply(.castMagicHand(Point(3, 4), .left)).success)
        XCTAssertTrue(session.apply(.placeSoldier(Point(2, 3))).success)
        XCTAssertEqual(session.state.board[Point(2, 2)], Piece(.one, .soldier))
        XCTAssertEqual(session.state.board[Point(2, 3)], Piece(.one, .soldier))
        XCTAssertTrue(session.state.board.group(at: Point(2, 3)).contains(Point(3, 3)))
        XCTAssertGreaterThanOrEqual(session.state.board.liberties(at: Point(2, 2)).count, 3)
        XCTAssertEqual(session.assessment.label, "completed", "Observable rescue succeeds without moving the threatened soldier")
    }
    func testMalformedSourceFailsRatherThanLoadingAnUnreachableDiagram() throws {
        let original = try XCTUnwrap(TutorialCatalog.scenario(id: "rogue-finish"))
        let bad = TutorialScenario(id: "bad", title: "bad", instructions: [], optionalHints: [], heroClass: .rogue,
            goal: original.goal, sourceActions: [.placeSoldier(Point(3, 5))], branches: [])
        XCTAssertThrowsError(try TutorialReplay.start(bad)) { error in
            guard case TutorialError.illegalSource(let id, let step, let reason) = error else { return XCTFail("Unexpected error") }
            XCTAssertEqual(id, "bad"); XCTAssertEqual(step, 0); XCTAssertEqual(reason, .occupied)
        }
    }
    func testWarriorRescueCounterReallyCapturesHeroThroughCore() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "warrior-rescue"))
        var session = try TutorialSession(scenario)
        for action in try branch(scenario, "opponent-counter").actions { XCTAssertTrue(session.apply(action).success) }
        XCTAssertNil(session.state.board.find(.one, .hero))
        XCTAssertNotNil(session.state.board.find(.one, .commander))
        XCTAssertTrue(session.events.contains { event in
            if case .piecesCaptured(.two, let pieces) = event { return pieces.contains { $0.piece == Piece(.one, .hero) } }
            return false
        })
        XCTAssertEqual(session.assessment, .failed("教學英雄被捕獲"))
    }
    func testInstructionsAndOptionalCanonicalHelpAreSeparate() throws {
        for scenario in try TutorialCatalog.all() {
            XCTAssertFalse(scenario.instructions.isEmpty)
            XCTAssertFalse(scenario.instructions.joined().contains(where: { "0123456789(".contains($0) }))
            XCTAssertFalse(scenario.optionalHints.isEmpty)
            XCTAssertEqual(scenario.canonicalSolution, try branch(scenario, "solution").actions)
            XCTAssertEqual(scenario.branches.filter { $0.name == "alternate-correct" }.count, 1)
        }
    }
    func testCannotWaitForAnotherPlayerTurnThenPass() throws {
        for scenario in try TutorialCatalog.all() {
            var session = try TutorialSession(scenario)
            let initialPly = session.state.ply
            for action in [.endTurn, .endTurn] + scenario.canonicalSolution {
                XCTAssertTrue(session.apply(action).success)
            }
            XCTAssertGreaterThan(session.state.ply, initialPly)
            XCTAssertEqual(session.playerActionCount, 2)
            XCTAssertEqual(session.assessment.label, "failed")
        }
    }
    func testLegalSkillAndRemotePlacementRejectWrongGroupOutcome() throws {
        for scenario in try TutorialCatalog.all() {
            var session = try TutorialSession(scenario)
            for action in try branch(scenario, "wrong-outcome").actions { XCTAssertTrue(session.apply(action).success) }
            XCTAssertEqual(session.playerActionCount, 2)
            XCTAssertEqual(session.assessment.label, "failed", scenario.id)
        }
    }
    func testConnectedRescueWithoutAnySkillStillFails() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "mage-rescue"))
        var session = try TutorialSession(scenario)
        for action in [GameAction.placeSoldier(Point(2, 3)), .placeSoldier(Point(2, 4))] { XCTAssertTrue(session.apply(action).success) }
        XCTAssertTrue(session.state.board.group(at: Point(2, 2)).contains(Point(3, 3)))
        XCTAssertGreaterThanOrEqual(session.state.board.liberties(at: Point(2, 2)).count, 3)
        XCTAssertEqual(session.assessment.label, "failed", "Observable state alone cannot bypass the skill requirement")
    }
    func testMageAlternateSplitHasDifferentPushCaptureAndDistinctCoreGroups() throws {
        let scenario = try XCTUnwrap(TutorialCatalog.scenario(id: "mage-split"))
        var session = try TutorialSession(scenario)
        let alternate = try branch(scenario, "alternate-correct")
        XCTAssertTrue(session.apply(alternate.actions[0]).success)
        XCTAssertEqual(session.state.board.liberties(at: Point(2, 2)), Set([Point(3, 2)]))
        let result = session.apply(alternate.actions[1])
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.events.contains { event in
            if case .piecesCaptured(.one, let pieces) = event { return pieces.contains { $0.at == Point(2, 2) && $0.piece == Piece(.two, .soldier) } }
            return false
        })
        XCTAssertFalse(session.state.board.group(at: Point(3, 1)).contains(Point(4, 2)))
        XCTAssertTrue(session.state.board.group(at: Point(4, 2)).contains(Point(5, 2)))
        XCTAssertEqual(session.assessment, .completed)
    }
}
