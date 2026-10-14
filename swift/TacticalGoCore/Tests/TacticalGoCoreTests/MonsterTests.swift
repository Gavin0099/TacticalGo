import XCTest
@testable import TacticalGoCore

final class MonsterTests: XCTestCase {
    private let center = Point(4, 4)
    private func config(cost: Int = 1, at: Point = Point(4, 4)) -> RuleConfig {
        var c = RuleConfig.board(size: 9)
        c.monsterBattlefield = MonsterBattlefield(at: at, huntAPCost: cost)
        return c
    }
    /// Handwritten boundary positions are distinct from the legal-opening replay tests below.
    private func position(_ stones: [(Point, Character)], cost: Int = 1, ap: Int = 2,
                          hero: HeroClass = .none) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"; rows[4][4] = "M"
        if stones.contains(where: { $0.1 == "X" }) { rows[7][4] = "." }
        for (p, symbol) in stones { rows[p.y][p.x] = symbol }
        return try GameSetup.fromDiagram(config: config(cost: cost),
            diagram: rows.map { String($0) }.joined(separator: "\n"), classOne: hero, manaOne: 6, ap: ap)
    }
    private func assertRejected(_ state: GameState, _ action: GameAction, _ reason: IllegalReason,
                                file: StaticString = #filePath, line: UInt = #line) {
        let o = GameEngine.apply(state, action)
        XCTAssertEqual(o.reason, reason, file: file, line: line)
        XCTAssertEqual(o.state, state, file: file, line: line)
        XCTAssertEqual(o.events, [], file: file, line: line)
    }
    /// A legal opening: black left control; white develops A1 and passes; black right control.
    private func reachable(cost: Int, at: Point = Point(4, 4)) throws -> GameSession {
        var session = GameSession(try GameSetup.newGame(config: config(cost: cost, at: at),
            classOne: .warrior, classTwo: .mage))
        for action: GameAction in [.placeSoldier(Point(at.x - 1, at.y)), .placeSoldier(Point(0, 0)),
                                   .endTurn, .placeSoldier(Point(at.x + 1, at.y))] {
            XCTAssertTrue(session.apply(action).success)
        }
        return session
    }
    func testModeIsOptInAndValidatesSetup() throws {
        for size in [7, 9] {
            XCTAssertNil(try GameSetup.newGame(config: .board(size: size)).board.monsters.first)
        }
        for p in [center, Point(3, 4)] {
            let s = try GameSetup.newGame(config: config(at: p))
            XCTAssertEqual(s.board.monsters.first, p)
            XCTAssertFalse(s.board.isEmpty(p))
            XCTAssertEqual(try Board.parse(s.board.diagram), s.board)
        }
        for p in [Point(0, 4), Point(8, 4), Point(-1, 4), Point(4, 1), Point(4, 7)] {
            XCTAssertThrowsError(try GameSetup.newGame(config: config(at: p)))
        }
        for cost in [-1, 2] { XCTAssertThrowsError(try GameSetup.newGame(config: config(cost: cost))) }
        var small = config(); small.boardSize = 7; small.commanderOneStart = Point(3, 5)
        XCTAssertThrowsError(try GameSetup.newGame(config: small))
        XCTAssertThrowsError(try GameSetup.fromDiagram(diagram: "M..\n...\n..."))
        XCTAssertEqual(try Board.parse("MM.\n...\n...").monsters, Set([Point(0,0),Point(1,0)]))
    }
    func testNeutralBlocksLibertyAndDoesNotConnectGroups() throws {
        let s = try position([(Point(4, 3), "x"), (Point(4, 5), "x")])
        XCTAssertEqual(s.board.group(at: Point(4, 3)), [Point(4, 3)])
        XCTAssertEqual(s.board.group(at: center), [])
        XCTAssertEqual(s.board.liberties(at: Point(4, 3)), Set([Point(3, 3), Point(5, 3), Point(4, 2)]))
        XCTAssertEqual(s.board.liberties(at: center), [])
        XCTAssertNil(s.board[center]) // no fake black/white owner
    }
    func testAllPlacementAndMovementPathsRejectNeutralOccupancy() throws {
        let warrior = try position([(Point(4, 3), "H")], hero: .warrior)
        assertRejected(warrior, .placeSoldier(center), .occupied)
        assertRejected(warrior, .castBastion(center, Point(3, 3)), .occupied)
        let summon = try position([(Point(4, 3), "x")], hero: .mage)
        assertRejected(summon, .summonHero(center), .occupied)
        var mage = try position([(Point(4, 2), "H"), (Point(4, 3), "x")], hero: .mage)
        assertRejected(mage, .castMagicHand(Point(4, 3), .down), .occupied)
        var sealConfig = mage.config; sealConfig.mageSkill = .seal
        mage = try GameSetup.fromDiagram(config: sealConfig, diagram: mage.board.diagram, classOne: .mage, manaOne: 6)
        assertRejected(mage, .castSeal(center), .occupied)
        var redeployConfig = config(); redeployConfig.experimentalFriendlyRedeploy = true
        let redeploy = try GameSetup.fromDiagram(config: redeployConfig,
            diagram: try position([(Point(3, 3), "H"), (Point(3, 4), "x")]).board.diagram, classOne: .mage, manaOne: 6)
        assertRejected(redeploy, .castFriendlyRedeploy(Point(3, 4), center), .occupied)
        XCTAssertFalse(GameEngine.legalActions(warrior).contains(.placeSoldier(center)))
        XCTAssertFalse(GameEngine.legalExperimentalRedeployments(redeploy).contains { $0.destination == center })
    }
    func testCaptureUsesNeutralAsBlockedLibertyButDoesNotCaptureMonster() throws {
        let victim = Point(4, 3)
        let s = try position([(victim, "o"), (Point(3, 3), "x"), (Point(5, 3), "x")])
        XCTAssertEqual(s.board.liberties(at: victim), Set([Point(4, 2)]))
        let o = GameEngine.apply(s, .placeSoldier(Point(4, 2)))
        XCTAssertTrue(o.success)
        XCTAssertNil(o.state.board[victim])
        XCTAssertEqual(o.state.board.monsters.first, center)
        XCTAssertTrue(o.events.contains(.piecesCaptured(.one, [CapturedPiece(at: victim, piece: Piece(.two, .soldier))])))
    }
    func testMonsterSurvivesFourOccupiedNeighbors() throws {
        let s = try position([(Point(4, 3), "x"), (Point(4, 5), "x"), (Point(3, 4), "x"), (Point(5, 4), "x")])
        let o = GameEngine.apply(s, .placeSoldier(Point(0, 0)))
        XCTAssertTrue(o.success)
        XCTAssertEqual(o.state.board.monsters.first, center)
        XCTAssertEqual(o.events.filter { $0.name == "PiecesCaptured" }, [])
    }
    func testSuicideBlockedByMonsterIsAtomic() throws {
        let s = try position([(Point(4, 2), "o"), (Point(3, 3), "o"), (Point(5, 3), "o")])
        assertRejected(s, .placeSoldier(Point(4, 3)), .suicide)
    }
    func testTieAndDiagonalDoNotGrantControl() throws {
        let tie = try position([(Point(3, 4), "x"), (Point(4, 3), "x"), (Point(5, 4), "o"), (Point(4, 5), "o")])
        XCTAssertEqual(GameEngine.monsterControl(tie, for: .one).friendly, 2)
        assertRejected(tie, .huntMonster(center), .insufficientMonsterControl)
        var white = tie; white.current = .two
        assertRejected(white, .huntMonster(center), .insufficientMonsterControl)
        let diagonal = try position([(Point(3, 3), "x"), (Point(5, 5), "x")])
        assertRejected(diagonal, .huntMonster(center), .insufficientMonsterControl)
    }
    func testAllFriendlyPieceKindsCountAndHuntHasNoManaOrSkillCost() throws {
        var s = try position([(Point(3, 4), "H"), (Point(4, 3), "X"), (Point(5, 4), "o")], hero: .warrior)
        s.skillUsedThisTurn = true
        let o = GameEngine.apply(s, .huntMonster(center))
        XCTAssertTrue(o.success)
        XCTAssertNil(o.state.board.monsters.first)
        XCTAssertTrue(o.state.board.isEmpty(center))
        XCTAssertEqual(o.state.apRemaining, 1)
        XCTAssertEqual(o.state.mana(of: .one), 6)
        XCTAssertTrue(o.state.skillUsedThisTurn)
        XCTAssertEqual(o.events, [.resourcesSpent(.one, ap: 1, mana: 0), .monsterHunted(.one, center)])
        XCTAssertEqual(o.state.board.liberties(at: Point(3, 4)).count, s.board.liberties(at: Point(3, 4)).count + 1)
        XCTAssertEqual(o.state.board.liberties(at: Point(5, 4)).count, s.board.liberties(at: Point(5, 4)).count + 1)
    }
    func testRejectedHuntsAndDisabledModeHaveNoEffects() throws {
        let original = try GameSetup.newGame()
        assertRejected(original, .huntMonster(center), .monsterModeDisabled)
        let s = try position([(Point(3, 4), "x"), (Point(5, 4), "x")])
        assertRejected(s, .huntMonster(Point(0, 0)), .invalidTarget)
        assertRejected(s, .huntMonster(Point(-1, 4)), .outOfBounds)
        let hunted = GameEngine.apply(s, .huntMonster(center)).state
        assertRejected(hunted, .huntMonster(center), .invalidTarget)
    }
    func testHuntHistoryIncludesNeutralAndRejectsExactRepeat() throws {
        var s = try position([(Point(3, 4), "x"), (Point(5, 4), "x")])
        var cleared = s.board; cleared.monsters = []
        XCTAssertNotEqual(s.board.diagram, cleared.diagram)
        s.history.insert(cleared.diagram)
        assertRejected(s, .huntMonster(center), .ko)
    }
    func testReachableSameOpeningComparesOnlyHuntCost() throws {
        for p in [center, Point(3, 4)] {
            var free = try reachable(cost: 0, at: p), paid = try reachable(cost: 1, at: p)
            XCTAssertEqual(free.state.board, paid.state.board)
            XCTAssertEqual(free.state.apRemaining, 1)
            XCTAssertEqual(paid.state.apRemaining, 1)
            let before = free.state
            XCTAssertTrue(free.apply(.huntMonster(p)).success)
            XCTAssertTrue(paid.apply(.huntMonster(p)).success)
            XCTAssertEqual(free.state.board, paid.state.board)
            XCTAssertEqual(free.state.current, .one)
            XCTAssertEqual(free.state.apRemaining, 1)
            XCTAssertEqual(paid.state.current, .two)
            XCTAssertTrue(free.undo()); XCTAssertEqual(free.state, before)
            XCTAssertTrue(free.apply(.huntMonster(p)).success) // history restored
        }
    }
    func testFreeWindowAfterLastAPAllowsOnlyHuntOrSkip() throws {
        var session = try reachable(cost: 0)
        XCTAssertTrue(session.apply(.placeSoldier(Point(4, 6))).success)
        let window = session.state
        XCTAssertEqual(window.apRemaining, 0)
        XCTAssertEqual(window.current, .one)
        XCTAssertTrue(window.awaitingFreeHunt)
        XCTAssertEqual(GameEngine.legalActions(window), [.huntMonster(center), .endTurn])
        assertRejected(window, .placeSoldier(Point(0, 1)), .noActionPoints)
        assertRejected(window, .summonHero(Point(4, 6)), .noActionPoints)
        let o = session.apply(.huntMonster(center))
        XCTAssertEqual(o.events, [.resourcesSpent(.one, ap: 0, mana: 0), .monsterHunted(.one, center),
            .turnEnded(.one, ply: 3), .turnStarted(.two, ply: 4, ap: 2, mana: 5)])
        XCTAssertFalse(session.state.awaitingFreeHunt)
        XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, window)
        XCTAssertTrue(session.apply(.endTurn).success)
        XCTAssertEqual(session.state.board.monsters.first, center)
        XCTAssertEqual(session.state.current, .two)
        XCTAssertFalse(session.state.awaitingFreeHunt)
    }
    func testFreeWindowEligibilityIsRecomputedAfterCaptures() throws {
        // Two adjacent white control stones are each in atari. Completing the last AP captures both.
        let s = try position([(Point(3, 4), "x"), (Point(4, 5), "x"), (Point(4, 3), "o"), (Point(5, 4), "o"),
            (Point(4, 2), "x"), (Point(3, 3), "x"), (Point(6, 4), "x"), (Point(5, 5), "x")], cost: 0, ap: 1)
        XCTAssertEqual(GameEngine.monsterControl(s, for: .one).enemy, 2)
        let o = GameEngine.apply(s, .placeSoldier(Point(5, 3)))
        XCTAssertTrue(o.success)
        XCTAssertNil(o.state.board[Point(4, 3)])
        XCTAssertNil(o.state.board[Point(5, 4)])
        XCTAssertTrue(o.state.awaitingFreeHunt)
        XCTAssertEqual(GameEngine.monsterControl(o.state, for: .one).enemy, 0)
    }
    func testNoWindowForTieUnavailableHuntOrImmediateVictory() throws {
        let tie = try position([(Point(3, 4), "x"), (Point(4, 3), "x"), (Point(5, 4), "o"), (Point(4, 5), "o")], cost: 0, ap: 1)
        let passed = GameEngine.apply(tie, .placeSoldier(Point(0, 0)))
        XCTAssertEqual(passed.state.current, .two)
        XCTAssertFalse(passed.state.awaitingFreeHunt)
        var repeatState = try position([(Point(3, 4), "x"), (Point(5, 4), "x")], cost: 0, ap: 1)
        var forbidden = repeatState.board; forbidden[Point(0, 0)] = Piece(.one, .soldier); forbidden.monsters = []
        repeatState.history.insert(forbidden.diagram)
        let repeated = GameEngine.apply(repeatState, .placeSoldier(Point(0, 0)))
        XCTAssertEqual(repeated.state.current, .two)
        XCTAssertFalse(repeated.state.awaitingFreeHunt)
        let win = try position([(Point(3, 4), "x"), (Point(5, 4), "x"), (Point(3, 1), "x"),
            (Point(5, 1), "x"), (Point(4, 0), "x")], cost: 0, ap: 1)
        let victory = GameEngine.apply(win, .placeSoldier(Point(4, 2)))
        XCTAssertEqual(victory.state.winner, .one)
        XCTAssertFalse(victory.state.awaitingFreeHunt)
        XCTAssertFalse(victory.events.contains { $0.name == "TurnStarted" })
        assertRejected(victory.state, .huntMonster(center), .gameOver)
    }
    func testLastTurnFreeHuntThenDrawAndUndo() throws {
        var initial = try position([(Point(3, 4), "x"), (Point(5, 4), "x")], cost: 0, ap: 1)
        initial.ply = initial.config.maxPlies
        var session = GameSession(initial)
        XCTAssertTrue(session.apply(.placeSoldier(Point(0, 0))).success)
        XCTAssertTrue(session.state.awaitingFreeHunt)
        let window = session.state
        XCTAssertTrue(session.apply(.huntMonster(center)).success)
        XCTAssertEqual(session.state.status, .drawn)
        XCTAssertNil(session.state.board.monsters.first)
        XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, window)
        XCTAssertTrue(session.apply(.endTurn).success)
        XCTAssertEqual(session.state.status, .drawn)
        XCTAssertEqual(session.state.board.monsters.first, center)
    }
    func testReachableOpponentCanDenyControlAfterHuntIsSkipped() throws {
        for cost in [0, 1] {
            var session = try reachable(cost: cost)
            XCTAssertTrue(session.apply(.placeSoldier(Point(4, 6))).success)
            if cost == 0 { XCTAssertTrue(session.apply(.endTurn).success) }
            XCTAssertEqual(session.state.current, .two)
            XCTAssertTrue(session.apply(.placeSoldier(Point(4, 3))).success)
            XCTAssertTrue(session.apply(.placeSoldier(Point(4, 5))).success)
            XCTAssertEqual(session.state.current, .one)
            XCTAssertEqual(GameEngine.monsterControl(session.state, for: .one).friendly, 2)
            XCTAssertEqual(GameEngine.monsterControl(session.state, for: .one).enemy, 2)
            assertRejected(session.state, .huntMonster(center), .insufficientMonsterControl)
        }
    }
    func testLegalOpeningCanWinWithoutHuntingAgainstScriptedPasses() throws {
        // Reachability only: an opponent passing does not establish a viable competitive strategy.
        for cost in [0, 1] {
            var session = GameSession(try GameSetup.newGame(config: config(cost: cost)))
            for action: GameAction in [.placeSoldier(Point(4, 0)), .endTurn,
                                       .placeSoldier(Point(3, 1)), .placeSoldier(Point(5, 1)),
                                       .endTurn, .placeSoldier(Point(4, 2))] {
                XCTAssertTrue(session.apply(action).success)
            }
            XCTAssertEqual(session.state.winner, .one)
            XCTAssertEqual(session.state.board.monsters.first, center)
            XCTAssertFalse(session.log.contains(.huntMonster(center)))
        }
    }

}
