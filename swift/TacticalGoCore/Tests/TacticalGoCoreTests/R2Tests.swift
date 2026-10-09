import XCTest
@testable import TacticalGoCore

final class R2Tests: XCTestCase {
    private func candidate(_ warrior: Bool = true, _ mage: Bool = true) -> RuleConfig {
        var config = RuleConfig.board(size: 7)
        if warrior { config.bastionScope = .connectedGroup }
        if mage { config.magicHandDestination = .opposingSoldierExchange }
        return config
    }
    private func checkReject(_ state: GameState, _ action: GameAction, _ reason: IllegalReason,
                             file: StaticString = #filePath, line: UInt = #line) {
        let result = GameEngine.apply(state, action)
        XCTAssertEqual(result.reason, reason, file: file, line: line)
        XCTAssertEqual(result.state, state, file: file, line: line)
        XCTAssertTrue(result.events.isEmpty, file: file, line: line)
    }
    func testDefaultsRetainOriginalRulesAndSeparateSwitches() throws {
        XCTAssertEqual(RuleConfig().bastionScope, .heroAdjacent)
        XCTAssertEqual(RuleConfig().magicHandDestination, .emptyOnly)
        let diagram = "..O....\n.......\n..x....\n.xxx...\n.xHx...\n.xxx...\n..X...."
        for (w, m) in [(false, false), (true, false), (false, true), (true, true)] {
            let state = try GameSetup.fromDiagram(config: candidate(w, m), diagram: diagram, classOne: .warrior, manaOne: 4, ap: 2)
            let outcome = GameEngine.apply(state, .castBastion(Point(1, 2), Point(3, 2)))
            XCTAssertEqual(outcome.success, w)
        }
    }
    func testWarriorPreCastFrontierDoesNotExtendViaFirstStoneOrDisconnectedGroup() throws {
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n...xx..\n.......\n.xHx...\n.xxx...\n..X....", classOne: .warrior, manaOne: 4)
        for (a, b) in [(Point(3, 3), Point(4, 3)), (Point(4, 3), Point(3, 3)), (Point(3, 1), Point(4, 1))] {
            checkReject(state, .castBastion(a, b), .outOfRange)
        }
        XCTAssertFalse(GameEngine.legalActions(state).contains(.castBastion(Point(3, 3), Point(4, 3))))
    }
    func testWarriorEventsResourcesOriginalStateAndUndoOnSevenAndNine() throws {
        for size in [7, 9] {
            var state = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n..x....\n.xxx...\n.xHx...\n.xxx...\n..X....", classOne: .warrior, manaOne: 4, ap: 2)
            if size == 9 { state = try padded(state) }
            let offset = size == 9 ? 1 : 0
            let a = Point(1 + offset, 2 + offset), b = Point(3 + offset, 2 + offset)
            var session = GameSession(state)
            let result = session.apply(.castBastion(a, b))
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecePlaced(.one, a, .soldier), .piecePlaced(.one, b, .soldier)])
            XCTAssertEqual(result.state.apRemaining, 1)
            XCTAssertEqual(result.state.mana(of: .one), 2)
            XCTAssertTrue(result.state.skillUsedThisTurn)
            XCTAssertNil(state.board[a]); XCTAssertNil(state.board[b])
            XCTAssertEqual(GameEngine.apply(state, .castBastion(b, a)).state, result.state)
            checkReject(result.state, .castBastion(Point(0, 2), Point(0, 3)), .skillAlreadyUsed)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, state)
            XCTAssertTrue(session.apply(.castBastion(a, b)).success)
        }
    }
    private func padded(_ state: GameState) throws -> GameState {
        let rows = state.board.diagram.split(separator: "\n").map { "." + $0 + "." }
        let diagram = (["........."] + rows + ["........."]).joined(separator: "\n")
        return try GameSetup.fromDiagram(config: state.config, diagram: diagram, classOne: state.heroClass(of: .one), manaOne: 4, ap: 2)
    }
    func testMageExchangeEitherTargetOwnerBothSizesAndAllDirections() throws {
        // Explicit direction/destination pairs from the orthogonal movement specification.
        let destinations: [(PushDirection, Point)] = [(.up, Point(3, 2)), (.right, Point(4, 3)), (.down, Point(3, 4)), (.left, Point(2, 3))]
        for size in [7, 9] { for owner in [Player.one, .two] { for (direction, destination) in destinations {
            var board = Board(size: size)
            let target = Point(3, 3), hero = direction == .left ? Point(4, 3) : Point(2, 3)
            board[Point(0, 0)] = Piece(.two, .commander); board[Point(size - 1, size - 1)] = Piece(.one, .commander)
            board[hero] = Piece(.one, .hero)
            board[target] = Piece(owner, .soldier); board[destination] = Piece(owner.opponent, .soldier)
            let state = try GameSetup.fromDiagram(config: candidate(), diagram: board.diagram, classOne: .mage, manaOne: 4, ap: 2)
            var session = GameSession(state)
            let result = session.apply(.castMagicHand(target, direction))
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.state.board[target], Piece(owner.opponent, .soldier))
            XCTAssertEqual(result.state.board[destination], Piece(owner, .soldier))
            XCTAssertEqual(result.state.board[hero], Piece(.one, .hero))
            XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecesSwapped(.one, target, destination)])
            XCTAssertEqual(result.state.apRemaining, 1); XCTAssertEqual(result.state.mana(of: .one), 2)
            XCTAssertTrue(result.state.skillUsedThisTurn)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, state)
            XCTAssertTrue(session.apply(.castMagicHand(target, direction)).success)
        } } }
    }
    func testMageDestinationIdentityAndDirectionBoundariesRejectWithoutEffects() throws {
        for (destination, reason) in [(Piece(.two, .soldier), IllegalReason.invalidTarget), (Piece(.one, .commander), .invalidTarget), (Piece(.two, .hero), .invalidTarget)] {
            var board = Board(size: 7)
            board[Point(1, 3)] = Piece(.one, .hero); board[Point(2, 3)] = Piece(.two, .soldier); board[Point(3, 3)] = destination
            let state = try GameSetup.fromDiagram(config: candidate(), diagram: board.diagram, classOne: .mage, manaOne: 4)
            checkReject(state, .castMagicHand(Point(2, 3), .right), reason)
            checkReject(state, .castMagicHand(Point(2, 3), .invalid), .invalidDirection)
            checkReject(state, .castMagicHand(Point(1, 3), .right), .invalidTarget)
            checkReject(state, .castMagicHand(Point(5, 3), .right), .outOfRange)
        }
        let edge = try GameSetup.fromDiagram(config: candidate(), diagram: ".......\n.......\n.......\noH.....\n.......\n.......\n.......", classOne: .mage, manaOne: 4)
        checkReject(edge, .castMagicHand(Point(0, 3), .left), .outOfBounds)
    }
    func testMageEmptyPushAndSealedMovementRetainOldBehavior() throws {
        var state = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n.......\n.H.o...\n.......\n.......\n..X....", classOne: .mage, manaOne: 4)
        state.seals = [SealEffect(at: Point(4, 3), caster: .two, blockedPlayer: .one)]
        let result = GameEngine.apply(state, .castMagicHand(Point(3, 3), .right))
        XCTAssertTrue(result.success) // original target within 2, destination at distance 3, seals restrict placement only
        XCTAssertNil(result.state.board[Point(3, 3)])
        XCTAssertEqual(result.state.board[Point(4, 3)], Piece(.two, .soldier))
        XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecePushed(caster: .one, from: Point(3, 3), to: Point(4, 3), piece: Piece(.two, .soldier))])
    }
    func testMageSuicideAndExactSuperkoDoNotMutateOrSpend() throws {
        let suicide = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n...o...\n.Hxoo..\n...o...\n.......\n..X....", classOne: .mage, manaOne: 4)
        checkReject(suicide, .castMagicHand(Point(2, 3), .right), .suicide)
        var ko = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n.......\n.Hox...\n.......\n.......\n..X....", classOne: .mage, manaOne: 4)
        ko.history.insert("..O....\n.......\n.......\n.Hxo...\n.......\n.......\n..X....")
        checkReject(ko, .castMagicHand(Point(2, 3), .right), .ko)
    }
    func testMageRemoteCutCaptureWinEventsAndRogueDifference() throws {
        let diagram = ".......\n...xx..\n.HxoOx.\n...ox..\n.......\n.......\n..X...."
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .mage, manaOne: 4)
        let result = GameEngine.apply(state, .castMagicHand(Point(3, 2), .up))
        XCTAssertTrue(result.success); XCTAssertEqual(result.state.winner, .one)
        XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecesSwapped(.one, Point(3, 2), Point(3, 1)), .piecesCaptured(.one, [CapturedPiece(at: Point(4, 2), piece: Piece(.two, .commander))]), .gameWon(.one)])
        XCTAssertEqual(result.state.board[Point(1, 2)], Piece(.one, .hero))
        XCTAssertEqual(result.state.board[Point(3, 1)], Piece(.two, .soldier))
        XCTAssertEqual(result.state.board[Point(3, 2)], Piece(.one, .soldier))
        XCTAssertNil(result.state.board[Point(4, 2)])
        let rogue = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .rogue, manaOne: 4)
        XCTAssertFalse(GameEngine.legalActions(rogue).contains { if case .castSwap = $0 { true } else { false } })
    }
    func testWarriorRemoteThreatCanBePreemptedByOneOrdinaryPlacement() throws {
        let diagram = ".xOx...\n.......\n..x....\n..x....\n.xHx...\n.xxx...\n..X...."
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .warrior, manaOne: 4)
        XCTAssertEqual(GameEngine.apply(state, .castBastion(Point(2, 1), Point(3, 2))).state.winner, .one)
        let defender = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .warrior, current: .two, manaOne: 4, ap: 2)
        let after = GameEngine.apply(defender, .placeSoldier(Point(2, 1)))
        XCTAssertTrue(after.success)
        let attack = GameEngine.apply(after.state, .endTurn).state
        XCTAssertFalse(GameEngine.legalActions(attack).contains { action in
            if case .castBastion = action { return GameEngine.apply(attack, action).state.winner == .one }
            return false
        })
    }
    func testWarriorCandidateSuicideAndKoAreAtomicRejections() throws {
        let suicide = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n...o...\n..oxo..\n.o.H.o.\n..ooo..\n.......\n..X....", classOne: .warrior, manaOne: 4)
        checkReject(suicide, .castBastion(Point(2, 3), Point(4, 3)), .suicide)
        var ko = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n..x....\n.xxx...\n.xHx...\n.xxx...\n..X....", classOne: .warrior, manaOne: 4)
        // Independently specified result of placing at B3 and D3.
        ko.history.insert("..O....\n.......\n.xxx...\n.xxx...\n.xHx...\n.xxx...\n..X....")
        checkReject(ko, .castBastion(Point(1, 2), Point(3, 2)), .ko)
    }
    func testWarriorTwoRemoteLibertiesTakeOneSkillButTwoOrdinaryPlacements() throws {
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: "...x...\n...O...\n..xxx..\n..xxx..\n..xHx..\n..xxx..\n...X...", classOne: .warrior, manaOne: 4, ap: 2)
        let a = Point(2, 1), b = Point(4, 1)
        XCTAssertEqual(state.board.liberties(at: Point(3, 1)), Set([a, b]))
        let skill = GameEngine.apply(state, .castBastion(a, b))
        XCTAssertEqual(skill.state.winner, .one); XCTAssertEqual(skill.state.apRemaining, 1)
        XCTAssertEqual(skill.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecePlaced(.one, a, .soldier), .piecePlaced(.one, b, .soldier), .piecesCaptured(.one, [CapturedPiece(at: Point(3, 1), piece: Piece(.two, .commander))]), .gameWon(.one)])
        for (first, second) in [(a, b), (b, a)] {
            let after = GameEngine.apply(state, .placeSoldier(first))
            XCTAssertTrue(after.success); XCTAssertEqual(after.state.status, .ongoing)
            let final = GameEngine.apply(after.state, .placeSoldier(second))
            XCTAssertEqual(final.state.winner, .one); XCTAssertEqual(final.state.apRemaining, 0)
        }
    }
    func testMixedWarriorThenEnemyMageResponseSeparatesBAndD() throws {
        let diagram = "ooO.oo.\no...Qo.\n..x.oo.\n.xxx...\n.xHx...\n.xxx...\n..X...."
        for mageExchange in [false, true] {
            let state = try GameSetup.fromDiagram(config: candidate(true, mageExchange), diagram: diagram,
                                                 classOne: .warrior, classTwo: .mage, manaOne: 4, manaTwo: 4, ap: 2)
            let bastion = GameEngine.apply(state, .castBastion(Point(1, 2), Point(3, 2)))
            XCTAssertTrue(bastion.success); XCTAssertEqual(bastion.state.current, .one)
            let response = GameEngine.apply(bastion.state, .endTurn).state
            XCTAssertEqual(response.current, .two); XCTAssertFalse(response.skillUsedThisTurn)
            let action = GameAction.castMagicHand(Point(3, 2), .right)
            if mageExchange {
                let result = GameEngine.apply(response, action)
                XCTAssertTrue(result.success)
                XCTAssertEqual(result.state.board[Point(3, 2)], Piece(.two, .soldier))
                XCTAssertEqual(result.state.board[Point(4, 2)], Piece(.one, .soldier))
                XCTAssertEqual(result.state.board[Point(4, 1)], Piece(.two, .hero))
                XCTAssertEqual(result.state.mana(of: .two), 3); XCTAssertEqual(result.state.apRemaining, 1)
                XCTAssertEqual(result.events, [.resourcesSpent(.two, ap: 1, mana: 2), .piecesSwapped(.two, Point(3, 2), Point(4, 2))])
            } else { checkReject(response, action, .occupied) }
        }
    }
    func testCandidateGatesAndWarriorSealedOrDuplicateTarget() throws {
        var state = try GameSetup.fromDiagram(config: candidate(), diagram: "..O....\n.......\n..x....\n.xxx...\n.xHx...\n.xxx...\n..X....", classOne: .warrior, manaOne: 4)
        let action = GameAction.castBastion(Point(1, 2), Point(3, 2))
        checkReject(state, .castBastion(Point(1, 2), Point(1, 2)), .duplicateTarget)
        state.seals = [SealEffect(at: Point(1, 2), caster: .two, blockedPlayer: .one)]
        checkReject(state, action, .sealed)
        state.seals = []; state.mana[0] = 1; checkReject(state, action, .notEnoughMana)
        state.mana[0] = 4; state.apRemaining = 0; checkReject(state, action, .noActionPoints)
        state.apRemaining = 2; state.skillUsedThisTurn = true; checkReject(state, action, .skillAlreadyUsed)
        state.skillUsedThisTurn = false; state.status = .won; checkReject(state, action, .gameOver)
    }
}
