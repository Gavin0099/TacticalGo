import XCTest
@testable import TacticalGoCore

final class ExpansionSkillTests: XCTestCase {
    func config(cost: Int = 4, enabled: Bool = true) -> RuleConfig {
        var c = RuleConfig.board(size: 9); c.expansionSkills = enabled; c.expansionSkillManaCost = cost; return c
    }
    func position(_ hero: HeroClass, _ stones: [(Point,Character)], player: Player = .one,
                  cost: Int = 4, ap: Int = 2, mana: Int = 6, enabled: Bool = true) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        for (p,c) in stones { rows[p.y][p.x] = c }
        if player == .two {
            let exchange: [Character:Character] = ["x":"o","o":"x","H":"Q","Q":"H","X":"O","O":"X"]
            rows = rows.map { $0.map { exchange[$0] ?? $0 } }
        }
        return try GameSetup.fromDiagram(config: config(cost: cost, enabled: enabled), diagram: rows.map { String($0) }.joined(separator:"\n"),
            classOne: player == .one ? hero : .mage, classTwo: player == .two ? hero : .mage,
            current: player, manaOne: mana, manaTwo: mana, ap: ap)
    }
    func rejected(_ s: GameState, _ a: GameAction, _ reason: IllegalReason, file: StaticString = #filePath, line: UInt = #line) {
        let result = GameEngine.apply(s,a)
        XCTAssertEqual(result.reason,reason,file:file,line:line)
        XCTAssertEqual(result.state,s,file:file,line:line); XCTAssertEqual(result.events,[],file:file,line:line)
    }
    let pull = GameAction.castDoublePull(.init(Point(4,4),Point(5,4)), .init(Point(3,3),Point(3,2)))
    let reform = GameAction.castReformation(.init(Point(4,4),Point(5,3)), .init(Point(5,4),Point(5,5)))
    let chain = GameAction.castChainSwap(first:Point(4,4),second:Point(5,4))
    let rescue = GameAction.castSanctuary(sacrifice:Point(4,4),destination:Point(4,6))

    func testDoublePullBothFactionsAndCostsPreservesOwnershipChargesOnceAndUndo() throws {
        for player in Player.allCases { for cost in [4,5] {
            let s = try position(.mage,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")],player:player,cost:cost)
            var session = GameSession(s); let o = session.apply(pull)
            XCTAssertTrue(o.success); XCTAssertNil(o.state.board[Point(4,4)]); XCTAssertNil(o.state.board[Point(3,3)])
            XCTAssertEqual(o.state.board[Point(5,4)],Piece(player,.soldier))
            XCTAssertEqual(o.state.board[Point(3,2)],Piece(player.opponent,.soldier))
            XCTAssertEqual(o.state.apRemaining,1); XCTAssertEqual(o.state.mana(of:player),6-cost)
            XCTAssertTrue(o.state.skillUsedThisTurn)
            XCTAssertEqual(o.events,[.resourcesSpent(player,ap:1,mana:cost),
                .piecePushed(caster:player,from:Point(4,4),to:Point(5,4),piece:Piece(player,.soldier)),
                .piecePushed(caster:player,from:Point(3,3),to:Point(3,2),piece:Piece(player.opponent,.soldier))])
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,s)
        } }
    }
    func testDoublePullDoesNotCaptureIntermediatePosition() throws {
        // o at E4 has only E3. First shift fills E3, second vacates E5, so it survives at E4.
        let s = try position(.mage,[(Point(3,3),"H"),(Point(3,2),"x"),(Point(4,3),"o"),(Point(5,3),"x"),(Point(4,4),"x")])
        let a = GameAction.castDoublePull(.init(Point(3,2),Point(4,2)),.init(Point(4,4),Point(5,4)))
        let o = GameEngine.apply(s,a); XCTAssertTrue(o.success)
        XCTAssertEqual(o.state.board[Point(4,3)],Piece(.two,.soldier))
        XCTAssertEqual(o.state.board.liberties(at:Point(4,3)),Set([Point(4,4)]))
        XCTAssertFalse(o.events.contains { if case .piecesCaptured = $0 { return true }; return false })
        let single = GameEngine.apply(s,.castMagicHand(Point(3,2),.right))
        XCTAssertTrue(single.success); XCTAssertNil(single.state.board[Point(4,3)])
    }
    func testDoublePullDuplicateOccupiedVacatedSourceAndWrongTargetRejections() throws {
        let s = try position(.mage,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")])
        rejected(s,.castDoublePull(.init(Point(4,4),Point(5,4)),.init(Point(4,4),Point(4,5))),.duplicateTarget)
        rejected(s,.castDoublePull(.init(Point(4,4),Point(4,3)),.init(Point(3,3),Point(4,3))),.duplicateTarget)
        rejected(s,.castDoublePull(.init(Point(4,4),Point(5,4)),.init(Point(3,3),Point(3,4))),.occupied)
        // A destination may not use any source even though it would be vacated by this action.
        rejected(s,.castDoublePull(.init(Point(4,4),Point(4,3)),.init(Point(3,3),Point(4,4))),.occupied)
        rejected(s,.castDoublePull(.init(Point(3,4),Point(2,4)),.init(Point(3,3),Point(3,2))),.invalidTarget)
        rejected(s,.castDoublePull(.init(Point(4,4),Point(6,4)),.init(Point(3,3),Point(3,2))),.outOfRange)
        rejected(s,.castDoublePull(.init(Point(-1,4),Point(0,4)),.init(Point(3,3),Point(3,2))),.outOfBounds)
    }
    func testDoublePullFinalSuicideAndKoRejectEveryChange() throws {
        let s = try position(.mage,[(Point(3,3),"H"),(Point(2,3),"o"),(Point(4,3),"o"),(Point(3,2),"o"),(Point(3,5),"o"),(Point(2,4),"x")])
        rejected(s,.castDoublePull(.init(Point(3,5),Point(3,4)),.init(Point(2,4),Point(2,5))),.suicide)
        var ko = try position(.mage,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")])
        var final = ko.board; final[Point(4,4)] = nil; final[Point(5,4)] = Piece(.one,.soldier)
        final[Point(3,3)] = nil; final[Point(3,2)] = Piece(.two,.soldier); ko.history.insert(final.diagram)
        rejected(ko,pull,.ko)
    }
    func testWarriorTransfersToRemoteOriginalFrontierWithoutCreatingExtraSoldiers() throws {
        for player in Player.allCases {
            let s = try position(.warrior,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(5,4),"x")],player:player)
            let o = GameEngine.apply(s,reform); XCTAssertTrue(o.success)
            XCTAssertNil(o.state.board[Point(4,4)]); XCTAssertNil(o.state.board[Point(5,4)])
            XCTAssertEqual(o.state.board[Point(5,3)],Piece(player,.soldier)); XCTAssertEqual(o.state.board[Point(5,5)],Piece(player,.soldier))
            XCTAssertEqual(o.state.board.points.filter { o.state.board[$0]?.kind == .soldier }.count,2)
            // Remote E-frontier targets cannot be reached by the original hero-adjacent Bastion.
            rejected(s,.castBastion(Point(5,3),Point(5,5)),.outOfRange)
        }
    }
    func testReformationRejectsUnconnectedEnemyOutOfFrontierAndDuplicateTargets() throws {
        let s = try position(.warrior,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(5,4),"x"),(Point(1,1),"x"),(Point(3,3),"o")])
        rejected(s,.castReformation(.init(Point(1,1),Point(5,3)),.init(Point(5,4),Point(5,5))),.outOfRange)
        rejected(s,.castReformation(.init(Point(3,3),Point(5,3)),.init(Point(5,4),Point(5,5))),.invalidTarget)
        rejected(s,.castReformation(.init(Point(4,4),Point(7,4)),.init(Point(5,4),Point(5,5))),.outOfRange)
        rejected(s,.castReformation(.init(Point(4,4),Point(5,3)),.init(Point(5,4),Point(5,3))),.duplicateTarget)
        rejected(s,.castReformation(.init(Point(4,4),Point(5,4)),.init(Point(5,4),Point(5,5))),.occupied)
    }
    func testChainSwapHasThreeActualTransfersNoIntermediateSettlementAndBothFactions() throws {
        for player in Player.allCases {
            let s = try position(.rogue,[(Point(3,4),"H"),(Point(4,4),"o"),(Point(5,4),"o")],player:player)
            let o = GameEngine.apply(s,chain); XCTAssertTrue(o.success)
            XCTAssertEqual(o.state.board[Point(3,4)],Piece(player.opponent,.soldier))
            XCTAssertEqual(o.state.board[Point(4,4)],Piece(player.opponent,.soldier))
            XCTAssertEqual(o.state.board[Point(5,4)],Piece(player,.hero))
            XCTAssertEqual(o.events,[.resourcesSpent(player,ap:1,mana:4),
                .piecePushed(caster:player,from:Point(3,4),to:Point(5,4),piece:Piece(player,.hero)),
                .piecePushed(caster:player,from:Point(4,4),to:Point(3,4),piece:Piece(player.opponent,.soldier)),
                .piecePushed(caster:player,from:Point(5,4),to:Point(4,4),piece:Piece(player.opponent,.soldier))])
        }
    }
    func testChainSwapRejectsRepeatsWrongTargetsPathsSuicideAndKo() throws {
        let s = try position(.rogue,[(Point(3,4),"H"),(Point(4,4),"o"),(Point(5,4),"o"),(Point(4,3),"Q")])
        rejected(s,.castChainSwap(first:Point(4,4),second:Point(3,4)),.duplicateTarget)
        rejected(s,.castChainSwap(first:Point(4,4),second:Point(4,4)),.duplicateTarget)
        rejected(s,.castChainSwap(first:Point(5,4),second:Point(4,4)),.outOfRange)
        rejected(s,.castChainSwap(first:Point(4,4),second:Point(4,3)),.invalidTarget)
        let trapped = try position(.rogue,[(Point(3,4),"H"),(Point(4,4),"o"),(Point(5,4),"o"),(Point(5,3),"o"),(Point(6,4),"o"),(Point(5,5),"o")])
        rejected(trapped,chain,.suicide)
        var ko = s; var final = s.board
        final[Point(3,4)] = Piece(.two,.soldier); final[Point(5,4)] = Piece(.one,.hero); ko.history.insert(final.diagram)
        rejected(ko,chain,.ko)
    }
    func testPriestSacrificeAndReinforcementAreDistinctFromCaptureAndPreserveCount() throws {
        for player in Player.allCases {
            let s = try position(.priest,[(Point(3,4),"H"),(Point(4,4),"x")],player:player)
            let o = GameEngine.apply(s,rescue); XCTAssertTrue(o.success)
            XCTAssertNil(o.state.board[Point(4,4)]); XCTAssertEqual(o.state.board[Point(4,6)],Piece(player,.soldier))
            XCTAssertEqual(o.state.mana(of:player),4); XCTAssertEqual(o.state.apRemaining,1)
            XCTAssertEqual(o.events,[.resourcesSpent(player,ap:1,mana:2),.pieceSacrificed(player,Point(4,4)),.piecePlaced(player,Point(4,6),.soldier)])
            XCTAssertTrue(o.state.skillUsedThisTurn)
        }
    }
    func testPriestInvalidHeroTargetRemoteDestinationSealFinalSuicideAndKo() throws {
        let s = try position(.priest,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(1,1),"x")])
        rejected(s,.castSanctuary(sacrifice:Point(3,4),destination:Point(4,6)),.invalidTarget)
        rejected(s,.castSanctuary(sacrifice:Point(1,1),destination:Point(4,6)),.outOfRange)
        rejected(s,.castSanctuary(sacrifice:Point(4,4),destination:Point(7,7)),.outOfRange)
        var sealed = s; sealed.seals = [SealEffect(at:Point(4,6),caster:.two,blockedPlayer:.one)]
        rejected(sealed,rescue,.sealed)
        let doomed = try position(.priest,[(Point(2,4),"H"),(Point(3,4),"x"),(Point(3,7),"o"),(Point(5,7),"o"),(Point(4,8),"o"),(Point(3,6),"o"),(Point(5,6),"o"),(Point(4,5),"o")])
        rejected(doomed,.castSanctuary(sacrifice:Point(3,4),destination:Point(4,6)),.suicide)
        var ko = s; var final = s.board; final[Point(4,4)] = nil; final[Point(4,6)] = Piece(.one,.soldier); ko.history.insert(final.diagram)
        rejected(ko,rescue,.ko)
    }
    func testSharedSkillGateManaOptInSetupAndLastAPHandOver() throws {
        let s = try position(.mage,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")])
        var disabled = s; disabled = try position(.mage,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")],enabled:false)
        rejected(disabled,pull,.skillNotSelected)
        var low = s; low.mana[0] = 3; rejected(low,pull,.notEnoughMana)
        var used = s; used.skillUsedThisTurn = true; rejected(used,pull,.skillAlreadyUsed)
        var noAP = s; noAP.apRemaining = 0; rejected(noAP,pull,.noActionPoints)
        var over = s; over.status = .won; rejected(over,pull,.gameOver)
        let wrong = try position(.rogue,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(3,3),"o")]); rejected(wrong,pull,.wrongClass)
        let absent = try position(.mage,[(Point(4,4),"x"),(Point(3,3),"o")]); rejected(absent,pull,.noHeroOnBoard)
        let first = GameEngine.apply(s,.castMagicHand(Point(4,4),.right)); XCTAssertTrue(first.success)
        rejected(first.state,pull,.skillAlreadyUsed)
        let advanced = GameEngine.apply(s,pull); rejected(advanced.state,.castMagicHand(Point(5,4),.right),.skillAlreadyUsed)
        var last = s; last.apRemaining = 1
        let result = GameEngine.apply(last,pull); XCTAssertTrue(result.success)
        XCTAssertEqual(result.state.current,.two); XCTAssertEqual(result.state.ply,2); XCTAssertFalse(result.state.skillUsedThisTurn)
        XCTAssertEqual(result.state.apRemaining,2)
        XCTAssertThrowsError(try GameSetup.newGame(classOne:.priest))
        XCTAssertThrowsError(try GameSetup.newGame(config:config(cost:3),classOne:.mage))
        let priest = try GameSetup.newGame(config:config(),classOne:.priest)
        XCTAssertEqual(priest.mana(of:.one),4); XCTAssertEqual(priest.config.summonCost(.priest),3)
    }
    func testLegalEnumerationAndUndoForAllFourActions() throws {
        let fixtures: [(HeroClass,[(Point,Character)],GameAction)] = [
            (HeroClass.mage,[(Point(3,4),Character("H")),(Point(4,4),"x"),(Point(3,3),"o")],pull),
            (.warrior,[(Point(3,4),"H"),(Point(4,4),"x"),(Point(5,4),"x")],reform),
            (.rogue,[(Point(3,4),"H"),(Point(4,4),"o"),(Point(5,4),"o")],chain),
            (.priest,[(Point(3,4),"H"),(Point(4,4),"x")],.castOffering(Point(4,4)))
        ]
        for (hero,stones,action) in fixtures {
            let s = try position(hero,stones)
            let canonicalAlternative: GameAction
            switch action {
            case .castDoublePull(let a,let b): canonicalAlternative = .castDoublePull(b,a)
            case .castReformation(let a,let b): canonicalAlternative = .castReformation(b,a)
            default: canonicalAlternative = action
            }
            let legal = GameEngine.legalActions(s)
            XCTAssertTrue(legal.contains(action) || legal.contains(canonicalAlternative), "Missing \(hero) candidate")
            var session = GameSession(s); XCTAssertTrue(session.apply(action).success)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,s); XCTAssertEqual(session.log,[])
        }
    }
    func testAllFourSkillsCaptureActualCommanderBeforeLastAPHandoverAndRestoreByUndo() throws {
        let wall: [(Point,Character)] = [(Point(3,1),"x"),(Point(5,1),"x"),(Point(4,0),"x")]
        let fixtures: [(HeroClass,[(Point,Character)],GameAction)] = [
            (.mage,[(Point(3,4),"H"),(Point(4,3),"x"),(Point(3,3),"x")],.castDoublePull(.init(Point(4,3),Point(4,2)),.init(Point(3,3),Point(2,3)))),
            (.warrior,[(Point(3,4),"H"),(Point(4,3),"x"),(Point(3,3),"x")],.castReformation(.init(Point(4,3),Point(4,2)),.init(Point(3,3),Point(2,3)))),
            (.rogue,[(Point(3,3),"H"),(Point(3,2),"o"),(Point(4,2),"o")],.castChainSwap(first:Point(3,2),second:Point(4,2))),
            (.priest,[(Point(3,2),"H"),(Point(2,2),"x")],.castSanctuary(sacrifice:Point(2,2),destination:Point(4,2)))
        ]
        for (hero,stones,action) in fixtures {
            let s = try position(hero,wall+stones,ap:1)
            var session = GameSession(s); let o = session.apply(action)
            XCTAssertTrue(o.success,"\(hero): \(o.reason)")
            XCTAssertNil(o.state.board[Point(4,1)])
            XCTAssertEqual(o.state.status,.won); XCTAssertEqual(o.state.winner,.one)
            XCTAssertEqual(o.state.current,.one); XCTAssertEqual(o.state.apRemaining,0)
            XCTAssertTrue(o.events.contains(.piecesCaptured(.one,[CapturedPiece(at:Point(4,1),piece:Piece(.two,.commander))])))
            XCTAssertEqual(o.events.last,.gameWon(.one))
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,s)
        }
    }
}
