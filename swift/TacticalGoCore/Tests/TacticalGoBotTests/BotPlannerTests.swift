import XCTest
import TacticalGoCore
import TacticalGoBot

final class BotPlannerTests: XCTestCase {
    private func state(_ diagram: String, hero: HeroClass = .none, ap: Int = 2, mana: Int = 5) throws -> GameState {
        try GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram, classOne: hero, classTwo: .mage, manaOne: mana, ap: ap, ply: 15)
    }
    private func execute(_ initial: GameState, _ plan: BotTurnPlan, file: StaticString = #filePath, line: UInt = #line) -> GameState {
        var state = initial
        let owner = initial.current
        XCTAssertFalse(plan.actions.isEmpty, file: file, line: line)
        for action in plan.actions {
            XCTAssertEqual(state.current, owner, "Plan must never act for the opponent", file: file, line: line)
            XCTAssertEqual(state.status, .ongoing, file: file, line: line)
            let outcome = GameEngine.apply(state, action)
            XCTAssertTrue(outcome.success, "\(botActionDescription(action)): \(outcome.reason)", file: file, line: line)
            state = outcome.state
        }
        XCTAssertTrue(state.current != owner || state.status != .ongoing, file: file, line: line)
        XCTAssertLessThanOrEqual(plan.stats.domainTransitions, BotLimits.standard.maxDomainTransitions, file: file, line: line)
        return state
    }
    func testDirectCommanderCaptureOutranksSummon() throws {
        let s = try state("xOx....\n.......\n.......\n.......\n.......\n...X...\n.......", hero: .warrior)
        XCTAssertEqual(s.board.liberties(at: Point(1, 0)), [Point(1, 1)])
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        XCTAssertEqual(plan.actions, [.placeSoldier(Point(1, 1))])
        XCTAssertEqual(execute(s, plan).winner, .one)
    }
    func testTwoOrdinaryActionsCaptureCommander() throws {
        let two = try state(".......\n..xOx..\n.......\n.......\n.......\n...X...\n.......")
        XCTAssertEqual(two.board.liberties(at: Point(3, 1)), [Point(3, 0), Point(3, 2)])
        let plan = try XCTUnwrap(BotPlanner.planTurn(two))
        XCTAssertEqual(plan.actions.count, 2)
        XCTAssertEqual(execute(two, plan).winner, .one)
    }
    func testMagicHandThenPlacementFindsTwoActionDecapitation() throws {
        let s = try state("...x...\n..xOx..\n.H.o...\n.......\n.......\n...X...\n.......", hero: .mage)
        XCTAssertEqual(s.board.liberties(at: Point(3, 1)).count, 3)
        // Independent witness: D3→E3 cuts the commander group, then D3 takes its last liberty.
        let cut = GameEngine.apply(s, .castMagicHand(Point(3, 2), .right))
        XCTAssertTrue(cut.success)
        XCTAssertEqual(GameEngine.apply(cut.state, .placeSoldier(Point(3, 2))).state.winner, .one)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        XCTAssertEqual(plan.actions.count, 2)
        if case .castMagicHand = plan.actions[0] {} else { XCTFail("Expected the cut before capture") }
        XCTAssertEqual(execute(s, plan).winner, .one)
    }
    func testCommanderOneLibertyIsRescuedInsteadOfRemoteAttack() throws {
        let s = try state("..O....\n.......\n.......\n...o...\n..oXo..\n.......\n.......", hero: .warrior)
        XCTAssertEqual(s.board.liberties(at: Point(3, 4)), [Point(3, 5)])
        let witness = GameEngine.apply(s, .placeSoldier(Point(3, 5)))
        XCTAssertTrue(witness.success)
        XCTAssertEqual(witness.state.board.liberties(at: Point(3, 4)).count, 3)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        let result = execute(s, plan)
        let commander = try XCTUnwrap(result.board.find(.one, .commander))
        XCTAssertGreaterThan(result.board.liberties(at: commander).count, 2, plan.actions.map(botActionDescription).joined(separator: " / ")+"\n"+result.board.diagram)
        // Exhaustive immediate enemy reply from Core must not kill the rescued commander.
        XCTAssertFalse(GameEngine.legalActions(result).contains { GameEngine.apply(result, $0).state.winner == .two })
    }
    func testSummonsUsefulHeroAtOpeningInsteadOfRandomRemoteStone() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        let result = execute(s, plan)
        XCTAssertEqual(plan.actions.count, 1)
        XCTAssertNotNil(result.board.find(.one, .hero))
        XCTAssertEqual(result.mana(of: .one), 2)
    }
    func testWarriorUsesBastionToCaptureTwoLibertyCommanderWithOneAP() throws {
        let s = try state(".......\n..xxx..\n.xoOox.\n...H...\n.......\n...X...\n.......", hero: .warrior, ap: 1)
        XCTAssertEqual(s.board.liberties(at: Point(3, 2)), [Point(2, 3), Point(4, 3)])
        XCTAssertEqual(GameEngine.apply(s, .castBastion(Point(2, 3), Point(4, 3))).state.winner, .one)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        XCTAssertTrue(plan.actions.contains { if case .castBastion = $0 { true } else { false } })
        XCTAssertEqual(execute(s, plan).winner, .one)
    }
    func testRogueSwapCapturesEnemyGroupAndKeepsHeroSafe() throws {
        let s = try state(".......\n..x....\n.xOx...\n..oHx..\n...x...\n...X...\n.......", hero: .rogue, ap: 1)
        // Swap C4 soldier into D4: it cuts the C3 commander; the hero links to safe allies.
        let witness = GameEngine.apply(s, .castSwap(Point(2, 3)))
        XCTAssertTrue(witness.success)
        XCTAssertNil(witness.state.board[Point(3, 3)])
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        XCTAssertTrue(plan.actions.contains { if case .castSwap = $0 { true } else { false } })
        let result = execute(s, plan)
        XCTAssertNotNil(result.board.find(.one, .hero))
        XCTAssertEqual(result.winner, .one)
    }
    func testDeterminismCancellationTerminalAndTinyBudget() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .mage, classTwo: .rogue)
        let a = try XCTUnwrap(BotPlanner.planTurn(s))
        let b = try XCTUnwrap(BotPlanner.planTurn(s))
        XCTAssertEqual(a.actions, b.actions); XCTAssertEqual(a.reasons, b.reasons)
        XCTAssertEqual(a.stats.domainTransitions, b.stats.domainTransitions)
        XCTAssertNil(BotPlanner.planTurn(s, cancelled: { true }))
        let tiny = try XCTUnwrap(BotPlanner.planTurn(s, limits: BotLimits(maxDomainTransitions: 1)))
        XCTAssertEqual(tiny.actions.count, 1); XCTAssertTrue(tiny.stats.budgetExhausted)
        _ = execute(s, tiny)
        let win = try state("xOx....\n.......\n.......\n.......\n.......\n...X...\n.......")
        let terminal = GameEngine.apply(win, .placeSoldier(Point(1, 1))).state
        XCTAssertNil(BotPlanner.planTurn(terminal))
    }
    func testSkillOnceResourcesAndDomainRejectsUnsafeActionAreRespected() throws {
        let s = try state("..O....\n...o...\n..oxo..\n.o.H.o.\n..ooo..\n.......\n...X...", hero: .warrior)
        XCTAssertFalse(GameEngine.apply(s, .castBastion(Point(2, 3), Point(4, 3))).success)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s))
        _ = execute(s, plan)
        XCTAssertLessThanOrEqual(plan.actions.filter { switch $0 { case .castBastion, .castMagicHand, .castSwap, .castSeal: true; default: false } }.count, 1)
        XCTAssertGreaterThanOrEqual(execute(s, plan).mana(of: .one), 0)
    }
    func testCancellationDuringSearchReturnsNoCommittablePlan() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .mage, classTwo: .rogue)
        let counter = CancellationCounter()
        XCTAssertNil(BotPlanner.planTurn(s, cancelled: { counter.next() }))
        XCTAssertGreaterThanOrEqual(counter.calls, 20)
    }
    func testTwoActionTacticSurvivesNarrowOrdinaryBeam() throws {
        let s = try state("...x...\n..xOx..\n.H.o...\n.......\n.......\n...X...\n.......", hero: .mage)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s, limits: BotLimits(ownBeamWidth: 1)))
        XCTAssertEqual(execute(s, plan).winner, .one)
    }

    func testIncompleteReplyNeverReceivesSafeComparisonScore() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s, limits: BotLimits(maxDomainTransitions: 60)))
        XCTAssertTrue(plan.stats.budgetExhausted)
        XCTAssertTrue(plan.stats.candidateComparisons.isEmpty)
        XCTAssertTrue(plan.reasons.contains { $0.contains("未完成驗證") })
        _ = execute(s, plan)
    }

    func testExplicitStandardPreservesDefaultPlan() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let original = try XCTUnwrap(BotPlanner.planTurn(s))
        let explicit = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .standard))
        XCTAssertEqual(original.actions, explicit.actions)
        XCTAssertEqual(original.reasons, explicit.reasons)
        XCTAssertEqual(original.score, explicit.score)
        XCTAssertEqual(original.stats.domainTransitions, explicit.stats.domainTransitions)
        XCTAssertEqual(original.stats.candidateComparisons, explicit.stats.candidateComparisons)
    }

    func testEasyFormalOneAndTwoAPTurnsAreCompleteLegalAndDeterministic() throws {
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let opening = try GameSetup.newGame(config: .board(size: 7), classOne: hero, classTwo: hero)
            for s in [opening, GameEngine.apply(opening, .endTurn).state] {
                let a = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .easy))
                let b = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .easy))
                let result = execute(s, a)
                XCTAssertEqual(a.actions, b.actions); XCTAssertEqual(a.reasons, b.reasons)
                XCTAssertEqual(a.stats.domainTransitions, b.stats.domainTransitions)
                XCTAssertEqual(a.stats.difficulty, .easy)
                XCTAssertFalse(a.stats.searchesOpponentTurn)
                XCTAssertEqual(a.stats.replyCandidates, 0)
                XCTAssertLessThanOrEqual(a.stats.domainTransitions, BotLimits.easy.maxDomainTransitions)
                XCTAssertNotNil(result.board.find(s.current, .hero), "Opening summon must be useful, not random passing")
                XCTAssertTrue(a.reasons.contains { $0.contains("不搜尋對手") })
            }
        }
    }

    func testEasyRescuesOneLibertyCommander() throws {
        let s = try state("..O....\n.......\n.......\n...o...\n..oXo..\n.......\n.......", hero: .warrior)
        XCTAssertEqual(s.board.liberties(at: Point(3, 4)), [Point(3, 5)])
        let plan = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .easy))
        let result = execute(s, plan)
        let commander = try XCTUnwrap(result.board.find(.one, .commander))
        XCTAssertGreaterThan(result.board.liberties(at: commander).count, 2)
        XCTAssertFalse(GameEngine.legalActions(result).contains { GameEngine.apply(result, $0).state.winner == .two })
    }

    func testEasyMageStillUsesSkillThenPlacementForTwoActionWin() throws {
        let s = try state("...x...\n..xOx..\n.H.o...\n.......\n.......\n...X...\n.......", hero: .mage)
        let witness = GameEngine.apply(s, .castMagicHand(Point(3, 2), .right))
        XCTAssertTrue(witness.success)
        XCTAssertEqual(GameEngine.apply(witness.state, .placeSoldier(Point(3, 2))).state.winner, .one)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .easy))
        XCTAssertEqual(plan.actions.count, 2)
        if case .castMagicHand = plan.actions[0] {} else { XCTFail("Expected a tactical cut") }
        XCTAssertEqual(execute(s, plan).winner, .one)
    }

    func testEasyWarriorAndRogueUseWinningFirstSkills() throws {
        let warrior = try state(".......\n..xxx..\n.xoOox.\n...H...\n.......\n...X...\n.......", hero: .warrior, ap: 1)
        XCTAssertEqual(GameEngine.apply(warrior, .castBastion(Point(2, 3), Point(4, 3))).state.winner, .one)
        let w = try XCTUnwrap(BotPlanner.planTurn(warrior, difficulty: .easy))
        XCTAssertTrue(w.actions.contains { if case .castBastion = $0 { true } else { false } })
        XCTAssertEqual(execute(warrior, w).winner, .one)
        let rogue = try state(".......\n..x....\n.xOx...\n..oHx..\n...x...\n...X...\n.......", hero: .rogue, ap: 1)
        XCTAssertEqual(GameEngine.apply(rogue, .castSwap(Point(2, 3))).state.winner, .one)
        let r = try XCTUnwrap(BotPlanner.planTurn(rogue, difficulty: .easy))
        XCTAssertTrue(r.actions.contains { if case .castSwap = $0 { true } else { false } })
        XCTAssertEqual(execute(rogue, r).winner, .one)
    }

    func testEasyCancellationAndTinyBudgetRemainSafe() throws {
        let s = try GameSetup.newGame(config: .board(size: 7), classOne: .mage, classTwo: .rogue)
        XCTAssertNil(BotPlanner.planTurn(s, difficulty: .easy, cancelled: { true }))
        let counter = CancellationCounter()
        XCTAssertNil(BotPlanner.planTurn(s, difficulty: .easy, cancelled: { counter.next() }))
        XCTAssertGreaterThanOrEqual(counter.calls, 20)
        let tiny = try XCTUnwrap(BotPlanner.planTurn(s, limits: BotLimits(maxDomainTransitions: 1), difficulty: .easy))
        XCTAssertEqual(tiny.actions, [.endTurn]); XCTAssertEqual(tiny.stats.domainTransitions, 1)
        XCTAssertTrue(tiny.stats.budgetExhausted)
        XCTAssertFalse(tiny.stats.searchesOpponentTurn)
        _ = execute(s, tiny)
    }

    func testDenseFullManaMakesUsefulMoveRatherThanRepeatedPurePass() throws {
        let s = try state(".o.oxx.\noooOxxx\no.oooxx\n.ooQxxx\nooxHxx.\n.ooXx.x\nooooxx.", hero:.warrior, mana:6)
        XCTAssertEqual(s.board.liberties(at:Point(3,5)),Set([Point(6,0),Point(6,4),Point(5,5),Point(6,6)]))
        for difficulty in BotDifficulty.allCases {
            let plan = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty))
            XCTAssertTrue(plan.actions.contains { $0 != .endTurn })
            let result = execute(s,plan), commander = try XCTUnwrap(result.board.find(.one,.commander))
            XCTAssertGreaterThanOrEqual(result.board.liberties(at:commander).count,3)
            XCTAssertFalse(GameEngine.legalActions(result).contains { GameEngine.apply(result,$0).state.winner == .two })
        }
    }
    func testEasyCloseCandidateChoiceIsDeterministicAndSafeInOpening() throws {
        let opening = try GameSetup.newGame(config:.board(size:7),classOne:.warrior,classTwo:.mage)
        let s = GameEngine.apply(opening,.endTurn).state
        let a = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
        let b = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
        XCTAssertEqual(a.actions,b.actions)
        XCTAssertTrue(a.stats.candidateComparisons.contains { $0.hasPrefix("easy-relaxed") })
        let result = execute(s,a), commander = try XCTUnwrap(result.board.find(.two,.commander))
        XCTAssertGreaterThanOrEqual(result.board.liberties(at:commander).count,3)
        XCTAssertNotNil(result.board.find(.two,.hero))
        XCTAssertFalse(GameEngine.legalActions(result).contains { GameEngine.apply(result,$0).state.winner == .one })
    }
    func testEasyActuallyOmitsOpponentSearch() throws {
        let opening = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let s = GameEngine.apply(opening, .endTurn).state
        let standard = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .standard))
        let easy = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: .easy))
        XCTAssertGreaterThan(standard.stats.replyCandidates, 0)
        XCTAssertTrue(standard.stats.candidateComparisons.contains { $0.contains("reply=") })
        XCTAssertEqual(easy.stats.replyCandidates, 0)
        XCTAssertFalse(easy.stats.candidateComparisons.contains { $0.contains("reply=") })
        XCTAssertLessThan(easy.stats.domainTransitions, standard.stats.domainTransitions)
        _ = execute(s, easy)
    }

}

private final class CancellationCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    var calls: Int { lock.lock(); defer { lock.unlock() }; return value }
    func next() -> Bool { lock.lock(); defer { lock.unlock() }; value += 1; return value >= 20 }
}
