import XCTest
import TacticalGoCore
import TacticalGoMotion
final class ExpansionReviewFixtureTests: XCTestCase {
    func testBothFactionsSevenNineDenseConfirmedActionsAndReducedBoard() throws {
        for hero in [HeroClass.warrior,.mage,.rogue,.priest] { for owner in Player.allCases { for size in [7,9] { for dense in [false,true] {
            let before = try ExpansionReviewFixture.state(hero:hero,owner:owner,size:size,dense:dense)
            let action = ExpansionReviewFixture.action(hero:hero),o = GameEngine.apply(before,action)
            XCTAssertTrue(o.success,"\(hero) \(owner) \(size) dense=\(dense)")
            let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:action,outcome:o,current:o.state))
            XCTAssertEqual(p.board(at:0),before.board);XCTAssertEqual(p.board(at:p.arrival),o.state.board)
            XCTAssertEqual(p.board(at:0,reduced:true),o.state.board)
            var s = GameSession(before);XCTAssertEqual(s.apply(action),o);XCTAssertTrue(s.undo());XCTAssertEqual(s.state,before)
        } } } }
    }
}
