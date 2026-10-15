import XCTest
import TacticalGoCore
@testable import TacticalGoContent

final class TacticalReadinessTests: XCTestCase {
    func position(mana:Int = 2,ap:Int = 2,hero:Bool = true,summoned:Bool = false) throws -> GameState {
        try GameSetup.fromDiagram(config:TacticalHints.updatedConfig(size:7),
            diagram:hero ? ".......\n...O...\n.......\n..xHx..\n.......\n...X...\n......." : ".......\n...O...\n.......\n..x.x..\n.......\n...X...\n.......",
            classOne:.mage,classTwo:.warrior,manaOne:mana,ap:ap,summonedOne:summoned)
    }
    func testResourcesOnlyPermitSelectionNotIllegalTarget() throws {
        let s = try position(),before = s
        XCTAssertNil(TacticalReadiness.restriction(s,mode:.skill))
        XCTAssertEqual(TacticalReadiness.restriction(s,mode:.advanced),.mana(needed:4,current:2))
        XCTAssertEqual(GameEngine.validate(s,.castFriendlyRedeploy(Point(0,0),Point(6,6))),.invalidTarget)
        XCTAssertEqual(s,before)
    }
    func testAbsentAndLostHeroHaveDifferentActionableReasons() throws {
        let absent = try position(hero:false),lost = try position(hero:false,summoned:true)
        XCTAssertEqual(TacticalReadiness.restriction(absent,mode:.skill),.needsHero)
        XCTAssertEqual(TacticalReadiness.restriction(lost,mode:.skill),.heroLost)
        XCTAssertEqual(TacticalReadiness.restriction(lost,mode:.summon),.alreadySummoned)
        XCTAssertEqual(TacticalReadiness.restriction(try position(),mode:.summon),.alreadySummoned)
        XCTAssertNil(TacticalReadiness.restriction(absent,mode:.soldier))
    }
    func testUsedQuotaAndUndoComeFromSuccessfulCoreOutcome() throws {
        var session = GameSession(try position())
        let before = session.state
        XCTAssertTrue(session.apply(.castFriendlyRedeploy(Point(2,3),Point(2,4))).success)
        XCTAssertEqual(TacticalReadiness.restriction(session.state,mode:.skill),.used)
        XCTAssertEqual(TacticalReadiness.restriction(session.state,mode:.advanced),.used)
        XCTAssertNil(TacticalReadiness.restriction(session.state,mode:.soldier))
        XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
        XCTAssertNil(TacticalReadiness.restriction(session.state,mode:.skill))
    }
    func testNoActionsAndTerminalOverrideAbilitySelection() throws {
        let empty = try position(ap:0)
        XCTAssertEqual(TacticalReadiness.restriction(empty,mode:.soldier),.noActions)
        XCTAssertEqual(TacticalReadiness.restriction(empty,mode:.skill),.noActions)
        var c = TacticalHints.updatedConfig(size:7);c.maxPlies = 1
        let initial = try GameSetup.newGame(config:c,classOne:.mage,classTwo:.warrior)
        let result = GameEngine.apply(initial,.endTurn)
        XCTAssertTrue(result.success);XCTAssertEqual(result.state.status,.drawn)
        XCTAssertEqual(TacticalReadiness.restriction(result.state,mode:.summon),.finished)
    }
    func testLootLockAndUnlockFromLegalOpeningWithoutHero() throws {
        var c = TacticalHints.updatedConfig(size:9)
        // Free hunting retains this turn's remaining AP, exposing the locked reward window.
        c.monsterBattlefield = .init(huntAPCost:0,kind:.slime,awardsLoot:true)
        var session = GameSession(try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage))
        for a: GameAction in [.placeSoldier(Point(3,4)),.placeSoldier(Point(0,0)),.endTurn,.placeSoldier(Point(5,4)),.huntMonster(Point(4,4))] {
            XCTAssertTrue(session.apply(a).success)
        }
        XCTAssertEqual(session.state.current,.one)
        XCTAssertEqual(TacticalReadiness.restriction(session.state,mode:.loot),.lootLocked)
        XCTAssertTrue(session.apply(.endTurn).success);XCTAssertTrue(session.apply(.endTurn).success)
        XCTAssertNil(TacticalReadiness.restriction(session.state,mode:.loot))
        XCTAssertEqual(TacticalReadiness.restriction(session.state,mode:.loot,ability:.shadowStep),.needsHero)
    }
}
