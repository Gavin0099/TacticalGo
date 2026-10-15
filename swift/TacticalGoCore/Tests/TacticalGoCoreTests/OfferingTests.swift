import XCTest
@testable import TacticalGoCore

final class OfferingTests: XCTestCase {
    private func state(player: Player = .one, mana: Int = 6, ap: Int = 2) throws -> GameState {
        let diagram = player == .one ? "....O....\n.........\n.........\n.........\n...Hx....\n.........\n.........\n....X....\n........." : "....X....\n.........\n.........\n.........\n...Qo....\n.........\n.........\n....O....\n........."
        var c = RuleConfig.board(size:9); c.expansionSkills = true
        return try GameSetup.fromDiagram(config:c,diagram:diagram,classOne:player == .one ? .priest:.mage,classTwo:player == .two ? .priest:.mage,current:player,manaOne:mana,manaTwo:mana,ap:ap)
    }
    private func rejected(_ s: GameState,_ point: Point,_ reason: IllegalReason) {
        let result = GameEngine.apply(s,.castOffering(point))
        XCTAssertEqual(result.reason,reason); XCTAssertEqual(result.state,s); XCTAssertTrue(result.events.isEmpty)
    }
    func testOfferingOnlyRemovesOwnSoldierBothSidesChargesOnceAndUndo() throws {
        for player in Player.allCases {
            let before = try state(player:player); var session = GameSession(before)
            let result = session.apply(.castOffering(Point(4,4)))
            XCTAssertTrue(result.success)
            var expected = before.board; expected[Point(4,4)] = nil
            XCTAssertEqual(session.state.board,expected)
            XCTAssertEqual(result.events,[.resourcesSpent(player,ap:1,mana:2),.pieceSacrificed(player,Point(4,4))])
            XCTAssertEqual(session.state.mana(of:player),4); XCTAssertEqual(session.state.apRemaining,1)
            XCTAssertTrue(session.state.skillUsedThisTurn)
            rejected(session.state,Point(4,4),.skillAlreadyUsed)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,before)
            XCTAssertTrue(GameEngine.legalActions(before).contains(.castOffering(Point(4,4))))
        }
    }
    func testOfferingFailuresDoNotChargeOrMutateAndCannotRepeatPriorBoard() throws {
        let s = try state()
        rejected(s,Point(-1,0),.outOfBounds)
        rejected(s,Point(3,4),.invalidTarget) // Hero is not a sacrifice.
        rejected(s,Point(4,7),.invalidTarget) // Commander is not a sacrifice.
        rejected(s,Point(4,0),.invalidTarget) // Enemy commander is not a sacrifice.
        rejected(s,Point(0,0),.invalidTarget)
        rejected(try state(mana:1),Point(4,4),.notEnoughMana)
        var far = s; far.board[Point(0,0)] = Piece(.one,.soldier)
        rejected(far,Point(0,0),.outOfRange)
        var prior = s.board; prior[Point(4,4)] = nil
        var ko = s; ko.history.insert(prior.diagram)
        rejected(ko,Point(4,4),.ko)
        var noHero = s; noHero.board[Point(3,4)] = nil
        rejected(noHero,Point(4,4),.noHeroOnBoard)
        var wrong = s; wrong.classes[0] = .mage
        rejected(wrong,Point(4,4),.wrongClass)
    }
    func testOfferingLastAPHandsOverWithoutCreatingSoldiers() throws {
        let before = try state(ap:1); let result = GameEngine.apply(before,.castOffering(Point(4,4)))
        XCTAssertTrue(result.success); XCTAssertEqual(result.state.current,.two); XCTAssertEqual(result.state.apRemaining,2)
        XCTAssertNil(result.state.board[Point(4,4)]); XCTAssertEqual(result.state.mana(of:.one),4)
        XCTAssertEqual(result.state.board[Point(4,7)],Piece(.one,.commander))
        XCTAssertFalse(result.events.contains { if case .piecePlaced = $0 { return true }; return false })
    }
}
