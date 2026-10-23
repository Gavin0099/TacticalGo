import XCTest
import TacticalGoContent
import TacticalGoCore

final class TwoActionForecastTests: XCTestCase {
    private func whiteToMove() throws -> GameState {
        let start = try GameSetup.newGame(config: TacticalHints.updatedConfig(size: 7),
                                          classOne: .warrior, classTwo: .mage)
        let first = GameEngine.apply(start, .endTurn)
        XCTAssertTrue(first.success)
        XCTAssertEqual(first.state.current, .two)
        XCTAssertEqual(first.state.apRemaining, 2)
        return first.state
    }

    private func placements(_ state: GameState) -> [GameAction] {
        GameEngine.legalActions(state).filter {
            if case .placeSoldier = $0 { return true }
            return false
        }
    }

    func testTrialReplaysTwoLegalActionsAndNeverMutatesOriginal() throws {
        let original = try whiteToMove(), saved = original
        var draft = TwoActionForecast(origin: original)
        let first = try XCTUnwrap(placements(original).first)
        XCTAssertTrue(draft.chooseFirst(first))
        let intermediate = try XCTUnwrap(draft.secondBase)
        XCTAssertEqual(intermediate.current, .two)
        XCTAssertEqual(intermediate.apRemaining, 1)
        let second = try XCTUnwrap(placements(intermediate).first)
        XCTAssertTrue(draft.chooseSecond(second))
        let a = try XCTUnwrap(draft.firstStep)
        let b = try XCTUnwrap(draft.secondStep)
        XCTAssertEqual(a.apBefore, 2)
        XCTAssertEqual(a.apAfter, 1)
        XCTAssertEqual(b.apBefore, 1)
        XCTAssertNil(b.apAfter, "next player's 2 AP is not ours")
        XCTAssertEqual(b.before, a.after)
        XCTAssertEqual(draft.projectedState, b.after)
        XCTAssertEqual(original, saved, "trial did not write the live session")
        XCTAssertFalse(draft.matches(b.after))
    }

    func testInvalidFirstAndSecondNeverCorruptExistingSelection() throws {
        let original = try whiteToMove()
        var draft = TwoActionForecast(origin: original)
        let first = try XCTUnwrap(placements(original).first)
        XCTAssertTrue(draft.chooseFirst(first))
        let before = draft
        let ownCommander = try XCTUnwrap(original.board.find(.two, .commander))
        XCTAssertFalse(draft.chooseFirst(.placeSoldier(ownCommander)))
        XCTAssertEqual(draft.first, before.first)
        XCTAssertEqual(draft.projectedState, before.projectedState)
        XCTAssertFalse(draft.chooseSecond(.placeSoldier(ownCommander)))
        XCTAssertNil(draft.second)
    }

    func testRebaseInvalidatesAnOccupiedSecondAndSupportsClearing() throws {
        let original = try whiteToMove()
        let places = placements(original)
        XCTAssertGreaterThanOrEqual(places.count, 3)
        var draft = TwoActionForecast(origin: original)
        XCTAssertTrue(draft.chooseFirst(places[0]))
        XCTAssertTrue(draft.chooseSecond(places[1]))
        XCTAssertTrue(draft.chooseFirst(places[1]))
        XCTAssertEqual(draft.first, places[1])
        XCTAssertNil(draft.second, "old second conflicts with the new first")
        XCTAssertTrue(draft.chooseSecond(places[2]))
        XCTAssertTrue(draft.chooseFirst(nil))
        XCTAssertNil(draft.first)
        XCTAssertNil(draft.second)
        XCTAssertEqual(draft.projectedState, original)
    }

    func testUnchangedLegalSecondMayBeKeptAfterFirstChange() throws {
        let original = try whiteToMove()
        let places = placements(original)
        XCTAssertGreaterThanOrEqual(places.count, 3)
        var draft = TwoActionForecast(origin: original)
        XCTAssertTrue(draft.chooseFirst(places[0]))
        XCTAssertTrue(draft.chooseSecond(places[1]))
        XCTAssertTrue(draft.chooseFirst(places[2]))
        XCTAssertEqual(draft.second, places[1])
        XCTAssertNotNil(draft.secondStep)
    }

    func testFirstTurnOneAPDoesNotPretendASecondActionIsAvailable() throws {
        let original = try GameSetup.newGame(config: TacticalHints.updatedConfig(size: 7),
                                              classOne: .rogue, classTwo: .priest)
        XCTAssertEqual(original.apRemaining, 1)
        var draft = TwoActionForecast(origin: original)
        let action = try XCTUnwrap(placements(original).first)
        XCTAssertTrue(draft.chooseFirst(action))
        XCTAssertNil(draft.secondBase)
        XCTAssertFalse(draft.chooseSecond(.endTurn))
        XCTAssertFalse(draft.hasTwoActions)
    }

    func testRogueChainSwapReportsCurrentTurnFactsNotOpponentPrediction() throws {
        // Geometry-only synthetic fixture; the archived P1R official history is separately
        // replay-verified in PR #37 and is not invented here.
        let config = TacticalHints.updatedConfig(size: 9)
        let board = """
        oo.oooooo
        o.ooOooo.
        ooxxQ.o.o
        xoxooooo.
        xxxxxoxoo
        xx.xxx.xo
        x.x.H.x.x
        .x.xXx.x.
        x.xxxxxxx
        """
        let original = try GameSetup.fromDiagram(config: config, diagram: board, classOne: .priest,
                                                 classTwo: .rogue, current: .two, manaOne: 6, manaTwo: 6,
                                                 ap: 2, ply: 60)
        var draft = TwoActionForecast(origin: original)
        XCTAssertTrue(draft.chooseFirst(.placeSoldier(Point(5,2))))
        XCTAssertTrue(draft.chooseSecond(.castChainSwap(first: Point(3,2), second: Point(2,2))))
        let first = try XCTUnwrap(draft.firstStep)
        let second = try XCTUnwrap(draft.secondStep)
        XCTAssertEqual(first.manaAfter, 6)
        XCTAssertEqual(second.manaBefore, 6)
        XCTAssertEqual(second.manaAfter, 2, "only current own-turn cost: no invented next-turn mana")
        XCTAssertEqual(second.enemySoldiersCaptured, 2)
        XCTAssertEqual(second.ownSoldiersSacrificed, 0)
        XCTAssertEqual(original.mana(of: .two), 6)
        XCTAssertEqual(original.board.diagram, board)
    }
}
