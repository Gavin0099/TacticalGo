import XCTest
@testable import TacticalGoCore
final class ExpansionMonsterIntegrationTests: XCTestCase {
    func testReachableLootAndEachClassShareOneSkillBothOrdersCostsAndUndo() throws {
        for hero in [HeroClass.warrior,.mage,.rogue,.priest] { for mana in [4,5] { for hunt in [0,1] {
            var config = RuleConfig.board(size:9);config.expansionSkills = true;config.expansionSkillManaCost = mana
            config.monsterBattlefield = .init(huntAPCost:hunt,awardsLoot:true)
            var s = GameSession(try GameSetup.newGame(config:config,classOne:hero,classTwo:.mage))
            let opening: [GameAction] = [.placeSoldier(Point(3,4)),.placeSoldier(Point(2,3)),.placeSoldier(Point(2,2)),.summonHero(Point(3,3)),.placeSoldier(Point(4,3))]
            for a in opening { XCTAssertTrue(s.apply(a).success) }
            if s.state.current == .two { XCTAssertTrue(s.apply(.endTurn).success) }
            XCTAssertTrue(s.apply(.huntMonster(Point(4,4))).success)
            while s.state.current != .one || s.state.mana(of:.one) < mana || s.state.ply < s.state.lootInventory(of:.one)[0].unlockPly {
                XCTAssertTrue(s.apply(.endTurn).success)
            }
            let before = s.state
            XCTAssertEqual(before.apRemaining,2);XCTAssertFalse(before.skillUsedThisTurn)
            let ability = GameAction.useStickyBounce(anchor:Point(3,3),target:Point(4,3))
            let advanced: GameAction
            switch hero {
            case .warrior: advanced = .castReformation(.init(Point(4,3),Point(4,2)),.init(Point(3,4),Point(2,4)))
            case .mage: advanced = .castDoublePull(.init(Point(4,3),Point(4,2)),.init(Point(3,4),Point(2,4)))
            case .rogue: advanced = .castChainSwap(first:Point(2,3),second:Point(2,2))
            case .priest: advanced = .castSanctuary(sacrifice:Point(4,3),destination:Point(4,6))
            case .none: XCTFail();continue
            }
            XCTAssertEqual(GameEngine.validate(before,ability),.none)
            XCTAssertEqual(GameEngine.validate(before,advanced),.none)
            for (first,second) in [(advanced,ability),(ability,advanced)] {
                let accepted = s.apply(first);XCTAssertTrue(accepted.success)
                XCTAssertTrue(s.state.skillUsedThisTurn);XCTAssertEqual(s.state.apRemaining,1)
                let blocked = s.apply(second)
                XCTAssertFalse(blocked.success);XCTAssertEqual(blocked.reason,.skillAlreadyUsed)
                XCTAssertEqual(blocked.state,accepted.state);XCTAssertTrue(blocked.events.isEmpty)
                XCTAssertTrue(s.undo());XCTAssertEqual(s.state,before)
                XCTAssertEqual(s.state.lootInventory(of:.one).count,1)
            }
            var replay = GameSession(try GameSetup.newGame(config:config,classOne:hero,classTwo:.mage))
            for action in s.log { XCTAssertTrue(replay.apply(action).success) }
            XCTAssertEqual(replay.state,before)
        } } }
    }
}
