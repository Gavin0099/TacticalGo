import XCTest
import TacticalGoCore
import TacticalGoContent

final class ExpansionPracticeTests: XCTestCase {
    func testFourSkillsReachableForBothManaCostsReplayAndUndo() throws {
        for fixture in ExpansionPractice.allCases { for cost in [4,5] {
            var session = try fixture.session(cost:cost); let before = session.state
            XCTAssertEqual(before.current,.one); XCTAssertGreaterThanOrEqual(before.mana(of:.one),fixture == .priest ? 2 : cost)
            let o = session.apply(fixture.action); XCTAssertTrue(o.success)
            let committed = session.state
            var replay = GameSession(try GameSetup.newGame(config:before.config,classOne:fixture.hero,classTwo:.mage))
            for action in session.log { XCTAssertTrue(replay.apply(action).success) }
            XCTAssertEqual(replay.state,committed)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,before)
            // None of these demonstrations is an immediate commander win.
            XCTAssertEqual(committed.status,.ongoing)
        } }
    }
}
