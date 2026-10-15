import XCTest
import Foundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

final class AdvancedChallengeTests: XCTestCase {
    private func start(_ index: Int) throws -> ChallengeController {
        var controller = try ChallengeController(campaign: .advanced)
        try controller.choose(controller.catalog[index].id)
        return controller
    }
    private func human(_ controller: inout ChallengeController, _ actions: [GameAction]) throws {
        for action in actions {
            XCTAssertEqual(controller.session?.state.current, .one)
            let before = try XCTUnwrap(controller.session?.state)
            let expected = GameEngine.apply(before, action)
            XCTAssertTrue(expected.success, "\(action): \(expected.reason)")
            XCTAssertEqual(try controller.commit(action), expected)
        }
    }
    private func opponent(_ controller: inout ChallengeController) throws {
        var count = 0
        while let action = controller.opponentAction {
            let before = try XCTUnwrap(controller.session?.state)
            XCTAssertEqual(before.current, .two)
            let expected = GameEngine.apply(before, action)
            XCTAssertTrue(expected.success)
            XCTAssertEqual(try controller.commit(action), expected)
            count += action == .endTurn ? 0 : 1
            XCTAssertLessThanOrEqual(count, 2)
        }
        XCTAssertGreaterThan(count, 0, "A pass-only script is not counterplay")
    }
    func testThreeOfficialSourcesPreserveEveryStateAndFullKoReplay() throws {
        XCTAssertEqual(try TutorialCatalog.all().count, 6)
        let catalog = try AdvancedCatalog.all()
        XCTAssertEqual(catalog.count, 3)
        for scenario in catalog {
            var state = try GameSetup.newGame(config: scenario.config, classOne: scenario.heroClass, classTwo: .none)
            for action in scenario.sourceActions {
                let result = GameEngine.apply(state, action)
                XCTAssertTrue(result.success); state = result.state
            }
            XCTAssertEqual(try TutorialReplay.start(scenario), state)
            XCTAssertEqual(state.current, .one)
            XCTAssertEqual(state.apRemaining, 2)
            XCTAssertFalse(state.config.experimentalFriendlyRedeploy)
            XCTAssertEqual(state.config.bastionScope, .heroAdjacent)
            for p in state.board.points where state.board[p] != nil { XCTAssertFalse(state.board.liberties(at: p).isEmpty) }
        }
    }
    func testRescueRequiresExtensionAfterActualTwoActionCounterattack() throws {
        var c = try start(0)
        try human(&c, [.castBastion(Point(4,5), Point(3,6)), .placeSoldier(Point(5,5))])
        try opponent(&c)
        XCTAssertFalse(c.locked)
        let afterCounter = try XCTUnwrap(c.session?.state)
        let commander = try XCTUnwrap(afterCounter.board.find(.one, .commander))
        XCTAssertLessThan(afterCounter.board.liberties(at: commander).count, 6)
        try human(&c, [.placeSoldier(Point(5,3)), .placeSoldier(Point(5,4))])
        XCTAssertEqual(c.assessment, .completed)
        XCTAssertThrowsError(try c.commit(.endTurn))
    }
    func testWarriorOrdinaryConnectionAlsoSurvivesButLeavesDifferentFrontier() throws {
        var ordinary = try start(0), bastion = try start(0)
        try human(&ordinary, [.placeSoldier(Point(4,5)), .placeSoldier(Point(5,5))])
        try human(&bastion, [.castBastion(Point(4,5),Point(3,6)), .placeSoldier(Point(5,5))])
        try opponent(&ordinary); try opponent(&bastion)
        XCTAssertEqual(ordinary.session?.state.board[Point(3,6)]?.owner, .two)
        XCTAssertEqual(bastion.session?.state.board[Point(3,6)]?.owner, .one)
        for controller in [ordinary, bastion] {
            var c = controller
            try human(&c, [.placeSoldier(Point(5,3)), .placeSoldier(Point(5,4))])
            XCTAssertEqual(c.assessment, .completed)
            // Four AP used in both plans. Ordinary leaves more Mana; bastion holds D7.
            XCTAssertEqual(c.session?.playerActionCount, 4)
        }
        XCTAssertEqual(ordinary.session?.state.mana(of:.one), 5)
        XCTAssertEqual(bastion.session?.state.mana(of:.one), 3)
    }
    func testFillingBothCommanderExitsLooksLikeRescueButTwoActionReplyClosesTheFrontier() throws {
        var c = try start(0)
        let root = try XCTUnwrap(c.session?.state)
        // Independently inspected geometry: D6 has E6/D7 as its only exits. Both
        // connect to E7/F7, but filling both fails to extend outward before the reply.
        XCTAssertEqual(root.board.liberties(at: Point(3,5)), Set([Point(4,5), Point(3,6)]))
        try human(&c, [.placeSoldier(Point(4,5)), .placeSoldier(Point(3,6))])
        XCTAssertEqual(c.session?.state.board.liberties(at: Point(3,5)),
                       Set([Point(2,6), Point(4,4), Point(5,5), Point(6,6)]))
        XCTAssertEqual(c.session?.plannedOpponentActions,
                       [.placeSoldier(Point(2,6)), .placeSoldier(Point(4,4))])
        for (action, liberties) in [(GameAction.placeSoldier(Point(2,6)), 3), (.placeSoldier(Point(4,4)), 2)] {
            let before = try XCTUnwrap(c.session?.state)
            let expected = GameEngine.apply(before, action)
            XCTAssertTrue(expected.success)
            XCTAssertEqual(try c.commit(action), expected)
            XCTAssertEqual(c.session?.state.board.liberties(at: Point(3,5)).count, liberties)
        }
        XCTAssertEqual(c.session?.opponentActionCount, 2)
        XCTAssertFalse(c.locked, "The player must get the actual reply before the goal is evaluated")
        XCTAssertEqual(c.session?.state.board.liberties(at: Point(3,5)), Set([Point(5,5), Point(6,6)]))
        // Extending along the right edge is locally plausible, but G7 adds no new
        // outlet after F6 already opens G6. This is a pressure/objective failure,
        // not an invented instant capture by an enemy with only two AP.
        try human(&c, [.placeSoldier(Point(5,5)), .placeSoldier(Point(6,6))])
        XCTAssertEqual(c.assessment, .failed("主將棋群只剩 2 氣；反擊後仍未建立足夠的逃生空間。"))
        XCTAssertTrue(c.locked)
        XCTAssertEqual(c.session?.state.status, .ongoing)
        XCTAssertNil(c.session?.state.winner)
        XCTAssertEqual(c.session?.state.board.liberties(at: Point(3,5)), Set([Point(5,4), Point(6,5)]))
        let restored = try ChallengeController(progress: c.progress, campaign: .advanced)
        XCTAssertEqual(restored.session?.state, c.session?.state, "All Ko/resource history comes from accepted Core replay")
        XCTAssertEqual(restored.assessment, c.assessment)

        // Same first move, but spend the other AP extending outward instead of
        // filling D7: the existing ordinary alternative can complete the rescue.
        var alternative = try start(0)
        try human(&alternative, [.placeSoldier(Point(4,5)), .placeSoldier(Point(5,5))])
        try opponent(&alternative)
        try human(&alternative, [.placeSoldier(Point(5,3)), .placeSoldier(Point(5,4))])
        XCTAssertEqual(alternative.assessment, .completed)
    }
    func testMageCounterResponseHasTwoDifferentLegalFollowupPlans() throws {
        for continuation: [GameAction] in [
            [.castMagicHand(Point(3,2), .left), .placeSoldier(Point(3,2))],
            [.placeSoldier(Point(6,1)), .placeSoldier(Point(6,3))]
        ] {
            var c = try start(1)
            try human(&c, [.castMagicHand(Point(4,2), .down), .placeSoldier(Point(4,2))])
            try opponent(&c)
            XCTAssertFalse(c.locked)
            try human(&c, continuation)
            XCTAssertEqual(c.assessment, .completed)
        }
    }
    func testRogueOrdinaryPlanTradesAnExtraTurnForManaWhileSwapSavesActions() throws {
        var ordinary = try start(2)
        try human(&ordinary, [.placeSoldier(Point(4,2)), .placeSoldier(Point(4,4))])
        try opponent(&ordinary)
        XCTAssertFalse(ordinary.locked)
        try human(&ordinary, [.placeSoldier(Point(6,2)), .placeSoldier(Point(6,4))])
        XCTAssertEqual(ordinary.assessment, .completed)
        XCTAssertEqual(ordinary.session?.state.mana(of: .one), 6)
        XCTAssertEqual(ordinary.session?.playerActionCount, 4)
        for opening: [GameAction] in [
            [.castSwap(Point(4,3)), .placeSoldier(Point(6,3))],
            [.placeSoldier(Point(6,3)), .castSwap(Point(4,3))]
        ] {
            var c = try start(2)
            try human(&c, opening)
            try opponent(&c)
            XCTAssertEqual(c.assessment, .completed)
            XCTAssertEqual(c.session?.playerActionCount, 2)
            XCTAssertEqual(c.session?.state.mana(of: .one), 5)
            // Two liberties do not by themselves prove danger: these two local spaces
            // cannot be legally filled by this opponent to capture the hero in two actions.
            let state = try XCTUnwrap(c.session?.state)
            let hero = try XCTUnwrap(state.board.find(.one, .hero))
            XCTAssertEqual(state.board.liberties(at: hero).count, 2)
            let enemyTurn = GameEngine.apply(state, .endTurn).state
            for p in state.board.liberties(at: hero) {
                XCTAssertFalse(GameEngine.apply(enemyTurn, .placeSoldier(p)).success)
            }
        }
    }
    func testLateSwapCostsAnActionWhichOrdinaryCaptureNeeds() throws {
        var c = try start(2)
        try human(&c, [.placeSoldier(Point(4,2)), .placeSoldier(Point(4,4))])
        try opponent(&c)
        // At this changed frontier the two ordinary closures capture the entire three-stone
        // group; swapping the central soldier spends an AP on the wrong group instead.
        try human(&c, [.castSwap(Point(4,3)), .placeSoldier(Point(6,2))])
        XCTAssertEqual(c.assessment?.label, "failed")
        XCTAssertEqual(c.session?.state.mana(of: .one), 4, "Two Mana spent; the next own turn has not started")
    }
    func testOpponentDependsOnActualStateAndBudgetIsExplicit() throws {
        var supported = try start(0), ignored = try start(0)
        try human(&supported, [.castBastion(Point(4,5), Point(3,6)), .placeSoldier(Point(5,5))])
        try human(&ignored, [.placeSoldier(Point(0,0)), .placeSoldier(Point(1,0))])
        XCTAssertNotEqual(supported.session?.plannedOpponentActions, ignored.session?.plannedOpponentActions)
        let root = try XCTUnwrap(supported.session?.state)
        let a = AdvancedOpponent.planTurn(root, goal: .advancedRescue)
        let b = AdvancedOpponent.planTurn(root, goal: .advancedRescue)
        XCTAssertEqual(a.actions, b.actions); XCTAssertEqual(a.explicitTransitions, b.explicitTransitions)
        XCTAssertLessThanOrEqual(a.explicitTransitions, 2_000)
        let tiny = AdvancedOpponent.planTurn(root, goal: .advancedRescue, maxTransitions: 1)
        XCTAssertTrue(tiny.budgetExhausted)
        XCTAssertTrue(GameEngine.apply(root, tiny.actions[0]).success)
    }
    func testResumeAfterOneEnemyReceiptAndPrematurePassNeverMakesFalseSuccess() throws {
        var c = try start(1)
        try human(&c, [.castMagicHand(Point(4,2), .down), .placeSoldier(Point(4,2))])
        let first = try XCTUnwrap(c.opponentAction)
        _ = try c.commit(first)
        let restored = try ChallengeController(progress: c.progress, campaign: .advanced)
        XCTAssertEqual(restored.session?.state, c.session?.state)
        XCTAssertEqual(restored.opponentAction, c.opponentAction)
        XCTAssertNotNil(restored.opponentAction)
        var early = try start(0)
        _ = try early.commit(.endTurn)
        try opponent(&early)
        XCTAssertNotEqual(early.assessment, .completed)
    }
    func testPlausibleErrorsReceiveActualCounterplayAndPreciseFailure() throws {
        var rescue = try start(0)
        try human(&rescue, [.placeSoldier(Point(0,0)), .placeSoldier(Point(1,0))])
        try opponent(&rescue)
        XCTAssertEqual(rescue.session?.state.winner, .two)
        XCTAssertEqual(rescue.assessment?.label, "failed")
        var mage = try start(1)
        try human(&mage, [.castMagicHand(Point(4,2), .down), .placeSoldier(Point(6,6))])
        try opponent(&mage)
        if !mage.locked {
            try human(&mage, [.placeSoldier(Point(0,0)), .placeSoldier(Point(1,0))])
        }
        XCTAssertEqual(mage.assessment?.label, "failed")
        var rogue = try start(2)
        try human(&rogue, [.castSwap(Point(4,3)), .placeSoldier(Point(0,0))])
        try opponent(&rogue)
        if !rogue.locked { try human(&rogue, [.placeSoldier(Point(6,6)), .placeSoldier(Point(5,6))]) }
        XCTAssertEqual(rogue.assessment?.label, "failed")
    }
    func testPreviewIllegalAndCancelDoNotAlterAcceptedJournalOrResources() throws {
        var c = try start(1)
        let before = c.progress, state = c.session?.state
        XCTAssertEqual(c.preview(.castMagicHand(Point(4,2), .invalid))?.reason, .invalidDirection)
        let invalid = try c.commit(.castMagicHand(Point(4,2), .invalid))
        XCTAssertFalse(invalid.success)
        XCTAssertEqual(c.progress, before); XCTAssertEqual(c.session?.state, state)
        _ = c.preview(.castMagicHand(Point(4,2), .down))
        XCTAssertEqual(c.progress, before); XCTAssertEqual(c.session?.state, state)
    }
    func testUndoReplaysLastHumanDecisionWithOpponentReceiptsAndRejectsTampering() throws {
        var c = try start(1)
        try human(&c, [.castMagicHand(Point(4,2), .down)])
        let first = c.session?.state
        try human(&c, [.placeSoldier(Point(4,2))])
        try opponent(&c)
        let fullProgress = c.progress
        XCTAssertEqual(try ChallengeController(progress: fullProgress, campaign: .advanced).session?.state, c.session?.state)
        XCTAssertTrue(try c.undo())
        XCTAssertEqual(c.session?.state, first)
        XCTAssertEqual(c.progress.runs[c.scenario!.id]?.count, 1)
        var corrupt = fullProgress
        corrupt.runs[c.scenario!.id]![2] = RecordedAction(.endTurn)
        XCTAssertThrowsError(try ChallengeController(progress: corrupt, campaign: .advanced))
    }
    func testNewProgressFileNeverMutatesIntroductoryProgressAndMatchDirectory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let intro = ChallengeRepository(directory: directory)
        var old = try ChallengeController(); try old.choose(old.catalog[0].id)
        try intro.save(old.progress)
        let bytes = try Data(contentsOf: intro.file)
        let matches = RecordRepository(directory: directory.appendingPathComponent("Matches"))
        var match = MatchRecord(size: 7, one: .warrior, two: .mage, computer: .two, difficulty: "standard", rules: .original)
        var live = try match.rebuild().0
        let before = live.state, accepted = live.apply(.placeSoldier(Point(0,0)))
        XCTAssertTrue(accepted.success)
        match.steps.append(RecordStep(action: .placeSoldier(Point(0,0)), before: before, outcome: accepted, difficulty: "standard", decision: nil))
        try matches.save(match)
        let matchBytes = try Data(contentsOf: matches.url(match.id))
        let advanced = ChallengeRepository(directory: directory, campaign: .advanced)
        var c = try start(0)
        try human(&c, [.castBastion(Point(4,5), Point(3,6))])
        try advanced.save(c.progress)
        XCTAssertEqual(try advanced.load().session?.state, c.session?.state)
        XCTAssertEqual(try Data(contentsOf: intro.file), bytes)
        XCTAssertNotEqual(intro.file, advanced.file)
        try c.retry(); XCTAssertTrue(c.session!.actions.isEmpty)
        XCTAssertFalse(c.locked)
        try advanced.save(c.progress)
        try c.choose(c.catalog[2].id); c.leave(); try advanced.save(c.progress)
        XCTAssertEqual(try Data(contentsOf: intro.file), bytes)
        XCTAssertEqual(try Data(contentsOf: matches.url(match.id)), matchBytes)
        XCTAssertEqual(try MatchRecord.decode(matchBytes).rebuild().0.state, live.state)
    }
}
