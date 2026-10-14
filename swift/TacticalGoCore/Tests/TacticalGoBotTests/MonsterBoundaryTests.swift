import XCTest
import TacticalGoCore
import TacticalGoBot
final class MonsterBotBoundaryTests: XCTestCase {
    func testMonsterOpeningIsLegalAndDoesNotInventFreeRewards() throws {
        var c = RuleConfig.board(size:9); c.monsterBattlefield = .init(awardsLoot:true)
        let s = try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage)
        let plan = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
        var after = s
        for action in plan.actions { let outcome = GameEngine.apply(after,action);XCTAssertTrue(outcome.success);after = outcome.state }
        XCTAssertEqual(after.current,.two);XCTAssertTrue(after.lootInventory(of:.one).isEmpty)
        XCTAssertTrue(after.board.monsters.contains(Point(4,4)))
    }
}
