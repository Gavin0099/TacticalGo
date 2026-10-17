import XCTest
@testable import TacticalGoCore

/// PRIEST-S2-P0: the priest's second skill is a separate action (`castSanctum`) charged the expansion cost, while the
/// historical `castSanctuary` keeps its 2-mana semantics so recorded matches replay unchanged.
final class PriestSanctumTests: XCTestCase {
    func position(_ stones: [(Point,Character)], cost: Int = 4, ap: Int = 2, mana: Int = 6) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        for (p,c) in stones { rows[p.y][p.x] = c }
        var c = RuleConfig.board(size: 9); c.expansionSkills = true; c.expansionSkillManaCost = cost
        return try GameSetup.fromDiagram(config: c, diagram: rows.map { String($0) }.joined(separator: "\n"),
                                         classOne: .priest, classTwo: .mage, current: .one, manaOne: mana, manaTwo: mana, ap: ap)
    }
    let base: [(Point,Character)] = [(Point(3,4),"H"),(Point(4,4),"x"),(Point(1,1),"x")]
    let sanctum = GameAction.castSanctum(sacrifice: Point(4,4), destination: Point(4,6))
    let legacy = GameAction.castSanctuary(sacrifice: Point(4,4), destination: Point(4,6))

    func testSanctumChargesTheSecondSkillCostWithTheSanctuaryBoardResult() throws {
        for cost in [4,5] {
            let s = try position(base, cost: cost)
            var session = GameSession(s)
            let o = session.apply(sanctum)
            XCTAssertTrue(o.success)
            XCTAssertNil(o.state.board[Point(4,4)]); XCTAssertEqual(o.state.board[Point(4,6)], Piece(.one,.soldier))
            XCTAssertEqual(o.state.mana(of:.one), 6 - cost); XCTAssertEqual(o.state.apRemaining, 1)
            XCTAssertTrue(o.state.skillUsedThisTurn)
            XCTAssertEqual(o.events, [.resourcesSpent(.one,ap:1,mana:cost),.pieceSacrificed(.one,Point(4,4)),.piecePlaced(.one,Point(4,6),.soldier)])
            // Same board as the historical skill; only the cost differs.
            XCTAssertEqual(GameEngine.apply(s, legacy).state.board, o.state.board)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, s)
        }
    }
    func testHistoricalSanctuaryKeepsTwoManaForReplay() throws {
        let o = GameEngine.apply(try position(base), legacy)
        XCTAssertTrue(o.success); XCTAssertEqual(o.state.mana(of:.one), 4)
    }
    func testSanctumNeedsTheSecondSkillManaAndSharesTheOncePerTurnGate() throws {
        let poor = try position(base, mana: 3)
        XCTAssertEqual(GameEngine.apply(poor, sanctum).reason, .notEnoughMana)
        XCTAssertTrue(GameEngine.apply(poor, .castOffering(Point(4,4))).success, "Offering still costs 2")
        let s = try position(base + [(Point(2,4),"x")])
        let offered = GameEngine.apply(s, .castOffering(Point(2,4)))
        XCTAssertTrue(offered.success)
        XCTAssertEqual(GameEngine.apply(offered.state, sanctum).reason, .skillAlreadyUsed)
        let sanctified = GameEngine.apply(s, sanctum)
        XCTAssertTrue(sanctified.success)
        XCTAssertEqual(GameEngine.apply(sanctified.state, .castOffering(Point(2,4))).reason, .skillAlreadyUsed)
    }
    func testSanctumRejectsLikeSanctuary() throws {
        let s = try position(base)
        XCTAssertEqual(GameEngine.apply(s, .castSanctum(sacrifice:Point(3,4),destination:Point(4,6))).reason, .invalidTarget)
        XCTAssertEqual(GameEngine.apply(s, .castSanctum(sacrifice:Point(1,1),destination:Point(4,6))).reason, .outOfRange)
        XCTAssertEqual(GameEngine.apply(s, .castSanctum(sacrifice:Point(4,4),destination:Point(7,7))).reason, .outOfRange)
        var sealed = s; sealed.seals = [SealEffect(at:Point(4,6),caster:.two,blockedPlayer:.one)]
        XCTAssertEqual(GameEngine.apply(sealed, sanctum).reason, .sealed)
        let warrior = try GameSetup.fromDiagram(config: s.config, diagram: s.board.diagram, classOne: .warrior, classTwo: .mage,
                                                manaOne: 6, manaTwo: 6, ap: 2)
        XCTAssertEqual(GameEngine.apply(warrior, sanctum).reason, .wrongClass)
    }
    func testLegalActionsOfferSanctumOnlyWhenAffordableAndEveryCandidateIsLegal() throws {
        let rich = GameEngine.legalActions(try position(base), expansionCandidateLimit: 512)
        let sanctums = rich.filter { if case .castSanctum = $0 { return true }; return false }
        XCTAssertFalse(sanctums.isEmpty)
        XCTAssertTrue(sanctums.contains(sanctum))
        let s = try position(base)
        for case .castSanctum(let source, let destination) in sanctums {
            XCTAssertEqual(GameEngine.validate(s, .castSanctum(sacrifice: source, destination: destination)), .none)
        }
        let poor = GameEngine.legalActions(try position(base, mana: 3), expansionCandidateLimit: 512)
        XCTAssertFalse(poor.contains { if case .castSanctum = $0 { return true }; return false })
    }
}
