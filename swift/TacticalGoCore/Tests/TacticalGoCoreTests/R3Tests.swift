import XCTest
@testable import TacticalGoCore

final class R3Tests: XCTestCase {
    private let dense = "O..x...\n..xxx..\n.xxxxx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X"
    private func candidate(_ size: Int = 7) -> RuleConfig {
        var c = RuleConfig.board(size: size)
        c.bastionScope = .connectedGroup; c.experimentalFriendlyRedeploy = true
        return c
    }
    private func reject(_ state: GameState, _ command: FriendlyRedeployment, _ reason: IllegalReason,
                        file: StaticString = #filePath, line: UInt = #line) {
        let result = GameEngine.applyExperimentalRedeployment(state, command)
        XCTAssertEqual(result.reason, reason, file: file, line: line)
        XCTAssertEqual(result.state, state, file: file, line: line)
        XCTAssertEqual(result.events, [], file: file, line: line)
    }
    func testDefaultsDisabledAndStandardEnumerationUnchanged() throws {
        XCTAssertFalse(RuleConfig().experimentalFriendlyRedeploy)
        let original = try GameSetup.fromDiagram(config: .board(size: 7), diagram: dense, classOne: .mage, manaOne: 4)
        reject(original, FriendlyRedeployment(from: Point(3, 2), to: Point(1, 1)), .skillNotSelected)
        XCTAssertTrue(GameEngine.legalExperimentalRedeployments(original).isEmpty)
        let enabled = try GameSetup.fromDiagram(config: candidate(), diagram: dense, classOne: .mage, manaOne: 4)
        let enabledActions = GameEngine.legalActions(enabled)
        let withoutRedeployment = enabledActions.filter { if case .castFriendlyRedeploy = $0 { return false }; return true }
        XCTAssertEqual(withoutRedeployment, GameEngine.legalActions(original))
        XCTAssertEqual(enabledActions.filter { if case .castFriendlyRedeploy = $0 { return true }; return false }.count, 144)
        // Twelve in-range friendly sources and twelve pre-cast boundary empties, all mechanically legal.
        XCTAssertEqual(GameEngine.legalExperimentalRedeployments(enabled).count, 144)
    }
    func testDenseBothColorsBothBoardSizesIdentityResourcesAndEventContract() throws {
        for size in [7, 9] { for player in [Player.one, .two] {
            let offset = size == 7 ? 0 : 1
            var rows = dense.split(separator: "\n").map(String.init)
            if size == 9 { rows = ["........."] + rows.map { "." + $0 + "." } + ["........."] }
            if player == .two {
                let exchange: [Character: Character] = ["O":"X", "X":"O", "H":"Q", "x":"o"]
                rows = rows.map { String($0.map { exchange[$0] ?? $0 }) }
            }
            let state = try GameSetup.fromDiagram(config: candidate(size), diagram: rows.joined(separator: "\n"),
                classOne: player == .one ? .mage : .rogue, classTwo: player == .two ? .mage : .rogue,
                current: player, manaOne: 4, manaTwo: 4, ap: 2, ply: 30)
            let from = Point(3 + offset, 2 + offset), to = Point(1 + offset, 1 + offset)
            let action = FriendlyRedeployment(from: from, to: to)
            let result = GameEngine.applyExperimentalRedeployment(state, action)
            XCTAssertTrue(result.success)
            XCTAssertNil(result.state.board[from]); XCTAssertEqual(state.board[from], Piece(player, .soldier))
            XCTAssertEqual(result.state.board[to], Piece(player, .soldier)); XCTAssertNil(state.board[to])
            XCTAssertEqual(result.state.board[Point(3 + offset, 3 + offset)], Piece(player, .hero))
            XCTAssertEqual(result.state.apRemaining, 1); XCTAssertEqual(result.state.mana(of: player), 2)
            XCTAssertTrue(result.state.skillUsedThisTurn)
            XCTAssertEqual(result.events, [.resourcesSpent(player, ap: 1, mana: 2),
                .piecePushed(caster: player, from: from, to: to, piece: Piece(player, .soldier))])
            reject(result.state, FriendlyRedeployment(from: Point(3 + offset, 4 + offset), to: Point(1 + offset, 5 + offset)), .skillAlreadyUsed)
            XCTAssertEqual(GameEngine.apply(result.state, .castMagicHand(Point(3 + offset, 4 + offset), .left)).reason, .skillAlreadyUsed)
            let handed = GameEngine.apply(result.state, .endTurn).state
            let returned = GameEngine.apply(handed, .endTurn).state
            XCTAssertFalse(returned.skillUsedThisTurn)
            XCTAssertEqual(returned.mana(of: player), 3)
        } }
    }
    func testSourceIdentityRangeConnectionAndDestinationBoundaries() throws {
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: "O......\n....x..\n..x.x..\n.xHx.o.\n..x....\n.......\n......X", classOne: .mage, manaOne: 4)
        let to = Point(1, 2)
        reject(state, FriendlyRedeployment(from: Point(5, 3), to: to), .invalidTarget) // enemy
        reject(state, FriendlyRedeployment(from: Point(2, 3), to: to), .invalidTarget) // hero
        reject(state, FriendlyRedeployment(from: Point(6, 6), to: to), .invalidTarget) // commander
        reject(state, FriendlyRedeployment(from: Point(0, 3), to: to), .invalidTarget) // empty
        reject(state, FriendlyRedeployment(from: Point(4, 1), to: to), .outOfRange)
        // In-range but only diagonally touching the hero's group.
        reject(state, FriendlyRedeployment(from: Point(4, 2), to: to), .outOfRange)
        let disconnected = try GameSetup.fromDiagram(config: candidate(), diagram: "O......\n.......\n...x...\n..H....\n.......\n.......\n......X", classOne: .mage, manaOne: 4)
        reject(disconnected, FriendlyRedeployment(from: Point(3, 2), to: Point(1, 3)), .notAdjacentToFriend)
        reject(state, FriendlyRedeployment(from: Point(3, 3), to: Point(3, 3)), .duplicateTarget)
        reject(state, FriendlyRedeployment(from: Point(3, 3), to: Point(2, 3)), .occupied)
        reject(state, FriendlyRedeployment(from: Point(3, 3), to: Point(6, 0)), .outOfRange)
        reject(state, FriendlyRedeployment(from: Point(-1, 3), to: to), .outOfBounds)
        reject(state, FriendlyRedeployment(from: Point(3, 3), to: Point(7, 0)), .outOfBounds)
    }
    func testPreCastBoundaryAllowsSourceOnlyNeighborAndSplitsStillHaveLiberties() throws {
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: "O......\n.......\n.......\n..Hx...\n.......\n.......\n......X", classOne: .mage, manaOne: 4)
        // E4 was adjacent to the source in the original group. It remains allowed even after source withdrawal.
        let moved = GameEngine.applyExperimentalRedeployment(state, FriendlyRedeployment(from: Point(3, 3), to: Point(4, 3)))
        XCTAssertTrue(moved.success)
        XCTAssertFalse(moved.state.board.group(at: Point(2, 3)).contains(Point(4, 3)))
        XCTAssertTrue(moved.state.board.liberties(at: Point(4, 3)).contains(Point(3, 3)))
        let extensionAttempt = FriendlyRedeployment(from: Point(3, 3), to: Point(5, 3))
        reject(state, extensionAttempt, .outOfRange) // no hypothetical first move can extend range
    }
    func testSourceWithdrawalCanGiveEnemyLibertySoNoSequentialCapture() throws {
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: ".......\n..xx...\n.xOxH..\n...xx..\n.......\n.......\n......X", classOne: .mage, manaOne: 4)
        XCTAssertEqual(state.board.liberties(at: Point(2, 2)), Set([Point(2, 3)]))
        let result = GameEngine.applyExperimentalRedeployment(state, FriendlyRedeployment(from: Point(3, 2), to: Point(2, 3)))
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.state.board[Point(2, 2)], Piece(.two, .commander))
        XCTAssertEqual(result.state.board.liberties(at: Point(2, 2)), Set([Point(3, 2)]))
        XCTAssertEqual(result.events.count, 2); XCTAssertEqual(result.state.status, .ongoing)
    }
    func testRemoteCommanderCaptureEventOrderAndOnePlacementDefense() throws {
        let diagram = ".xOx...\n.......\n..x....\n..x....\n.xHx...\n.xxx...\n..X...."
        let initial = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .mage, manaOne: 4)
        let action = FriendlyRedeployment(from: Point(2, 3), to: Point(2, 1))
        let won = GameEngine.applyExperimentalRedeployment(initial, action)
        XCTAssertTrue(won.success); XCTAssertEqual(won.state.winner, .one)
        XCTAssertNil(won.state.board[Point(2, 0)])
        XCTAssertEqual(won.state.board[Point(2, 4)], Piece(.one, .hero))
        XCTAssertEqual(won.events, [.resourcesSpent(.one, ap: 1, mana: 2),
            .piecePushed(caster: .one, from: Point(2, 3), to: Point(2, 1), piece: Piece(.one, .soldier)),
            .piecesCaptured(.one, [CapturedPiece(at: Point(2, 0), piece: Piece(.two, .commander))]), .gameWon(.one)])
        XCTAssertEqual(won.state.apRemaining, 1)
        let defending = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .mage,
            current: .two, manaOne: 4, ap: 2)
        let defense = GameEngine.apply(defending, .placeSoldier(Point(2, 1)))
        XCTAssertTrue(defense.success)
        let back = GameEngine.apply(defense.state, .endTurn).state
        reject(back, action, .occupied)
        XCTAssertFalse(GameEngine.legalExperimentalRedeployments(back).contains { GameEngine.applyExperimentalRedeployment(back, $0).state.winner == .one })
    }
    func testExactKoRejectsCompleteStateAndPreviewDoesNotPolluteHistory() throws {
        var state = try GameSetup.fromDiagram(config: candidate(), diagram: dense, classOne: .mage, manaOne: 4)
        let action = FriendlyRedeployment(from: Point(3, 2), to: Point(1, 1))
        let independentlySpecified = "O..x...\n.xxxx..\n.xx.xx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X"
        let preview = GameEngine.applyExperimentalRedeployment(state, action)
        XCTAssertEqual(preview.state.board.diagram, independentlySpecified)
        XCTAssertEqual(GameEngine.applyExperimentalRedeployment(state, action), preview)
        XCTAssertFalse(state.history.contains(independentlySpecified))
        state.history.insert(independentlySpecified)
        reject(state, action, .ko)
    }
    func testSharedGatesAllRejectionsAreAtomic() throws {
        let action = FriendlyRedeployment(from: Point(3, 2), to: Point(1, 1))
        var state = try GameSetup.fromDiagram(config: candidate(), diagram: dense, classOne: .mage, manaOne: 4)
        state.mana[0] = 1; reject(state, action, .notEnoughMana)
        state.mana[0] = 4; state.apRemaining = 0; reject(state, action, .noActionPoints)
        state.apRemaining = 2; state.skillUsedThisTurn = true; reject(state, action, .skillAlreadyUsed)
        state.skillUsedThisTurn = false; state.status = .won; reject(state, action, .gameOver)
        let wrong = try GameSetup.fromDiagram(config: candidate(), diagram: dense, classOne: .warrior, manaOne: 4)
        reject(wrong, action, .wrongClass)
        let absent = try GameSetup.fromDiagram(config: candidate(), diagram: dense.replacingOccurrences(of: "H", with: "x"), classOne: .mage, manaOne: 4)
        reject(absent, action, .noHeroOnBoard)
        var sealConfig = candidate(); sealConfig.mageSkill = .seal
        let sealMage = try GameSetup.fromDiagram(config: sealConfig, diagram: dense, classOne: .mage, manaOne: 4)
        reject(sealMage, action, .skillNotSelected)
    }
    func testSealsLimitPlacementNotCandidateMovementAndLastApHandsOff() throws {
        var state = try GameSetup.fromDiagram(config: candidate(), diagram: dense, classOne: .mage, manaOne: 4, ap: 1)
        let destination = Point(1, 1)
        state.seals = [SealEffect(at: destination, caster: .two, blockedPlayer: .one)]
        XCTAssertEqual(GameEngine.apply(state, .placeSoldier(destination)).reason, .sealed)
        let result = GameEngine.applyExperimentalRedeployment(state, FriendlyRedeployment(from: Point(3, 2), to: destination))
        XCTAssertTrue(result.success); XCTAssertEqual(result.state.current, .two); XCTAssertEqual(result.state.apRemaining, 2)
        XCTAssertEqual(result.events.map(\.name), ["ResourcesSpent", "PiecePushed", "TurnEnded", "SealExpired", "TurnStarted"])
        XCTAssertEqual(result.state.mana(of: .one), 2)
    }
    func testFullBoardHasNoCandidateDestinationNotAReachableGameplayFixture() throws {
        // Deliberately structural malformed diagram, not a legal nonterminal full-board match claim.
        let full = "Oxxxxxx\nxxxxxxx\nxxxxxxx\nxxxHxxx\nxxxxxxx\nxxxxxxx\nxxxxxxX"
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: full, classOne: .mage, manaOne: 4)
        XCTAssertTrue(GameEngine.legalExperimentalRedeployments(state).isEmpty)
    }
    func testPreExistingDeadFriendlyGroupStillRejectedBySharedSettlement() throws {
        // Diagnostic invalid starting state; shows we did not bypass Core suicide guard.
        let diagram = "xoO....\no......\n.......\n..Hx...\n.......\n.......\n......X"
        let state = try GameSetup.fromDiagram(config: candidate(), diagram: diagram, classOne: .mage, manaOne: 4)
        reject(state, FriendlyRedeployment(from: Point(3, 3), to: Point(4, 3)), .suicide)
    }
    func testOwnerScreenshotWarriorG5G7RequiresConnectedRangeAndCapturesG6() throws {
        // Transcribed visible stones, not a retrieved save or proof of its Ko history.
        let diagram = "...x...\n..xOx..\n..xoox.\n...xoox\n..x.xo.\n..HXoox\n..xoQo."
        let original = try GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram,
            classOne: .warrior, classTwo: .warrior, current: .two, manaOne: 5, manaTwo: 4, ap: 2, ply: 12)
        XCTAssertEqual(original.board.liberties(at: Point(4, 6)), Set([Point(6, 4), Point(6, 6)]))
        let action = GameAction.castBastion(Point(6, 4), Point(6, 6))
        XCTAssertEqual(GameEngine.apply(original, action).reason, .outOfRange)
        XCTAssertEqual(GameEngine.apply(original, .placeSoldier(Point(6, 4))).reason, .none)
        let connected = try GameSetup.fromDiagram(config: candidate(), diagram: diagram,
            classOne: .warrior, classTwo: .warrior, current: .two, manaOne: 5, manaTwo: 4, ap: 2, ply: 12)
        let outcome = GameEngine.apply(connected, action)
        XCTAssertTrue(outcome.success)
        XCTAssertEqual(outcome.state.board[Point(6, 4)], Piece(.two, .soldier))
        XCTAssertEqual(outcome.state.board[Point(6, 6)], Piece(.two, .soldier))
        XCTAssertNil(outcome.state.board[Point(6, 5)])
        XCTAssertEqual(outcome.state.board.liberties(at: Point(4, 6)), Set([Point(6, 5)]))
        XCTAssertEqual(outcome.state.apRemaining, 1); XCTAssertEqual(outcome.state.mana(of: .two), 2)
        XCTAssertEqual(outcome.events, [.resourcesSpent(.two, ap: 1, mana: 2),
            .piecePlaced(.two, Point(6, 4), .soldier), .piecePlaced(.two, Point(6, 6), .soldier),
            .piecesCaptured(.two, [CapturedPiece(at: Point(6, 5), piece: Piece(.one, .soldier))])])
    }

}
