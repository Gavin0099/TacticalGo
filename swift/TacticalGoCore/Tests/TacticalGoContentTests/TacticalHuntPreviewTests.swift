import XCTest
import TacticalGoCore
@testable import TacticalGoContent

final class TacticalHuntPreviewTests: XCTestCase {
    let monster = Point(4,4)
    /// A reachable warrior opening: the hero and new frontier soldier control the slime.
    func afterBastion(cost:Int) throws -> GameSession {
        var c = TacticalHints.updatedConfig(size:9)
        c.monsterBattlefield = .init(huntAPCost:cost,awardsLoot:true)
        var session = GameSession(try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage))
        for action: GameAction in [.placeSoldier(Point(4,6)),.placeSoldier(Point(0,0)),.endTurn,
                                  .summonHero(Point(4,5)),.placeSoldier(Point(3,5)),.endTurn,
                                  .castBastion(Point(3,4),Point(5,5))] {
            XCTAssertTrue(session.apply(action).success,"\(action)")
        }
        return session
    }
    func testPaidHuntAfterSkillUsesActualActionAndNeverChargesPreview() throws {
        var session = try afterBastion(cost:1);let before = session.state
        XCTAssertTrue(before.skillUsedThisTurn);XCTAssertEqual(before.apRemaining,1)
        // Start-of-turn regeneration leaves two Mana, below the four-Mana advanced skill.
        XCTAssertEqual(before.mana(of:.one),2)
        XCTAssertEqual(TacticalReadiness.restriction(before,mode:.advanced),.used)
        let preview = TacticalHuntPreview(before,at:monster)
        XCTAssertEqual(preview.reason,.none);XCTAssertEqual(preview.apCost,1)
        XCTAssertEqual(preview.friendly,2);XCTAssertEqual(preview.enemy,0)
        XCTAssertEqual(preview.title,"討伐 · 史萊姆");XCTAssertEqual(preview.reward,"黏彈")
        XCTAssertEqual(session.state,before);XCTAssertNil(before.loot(of:.one))
        let outcome = session.apply(.huntMonster(monster))
        XCTAssertTrue(outcome.success);XCTAssertTrue(outcome.events.contains(.resourcesSpent(.one,ap:1,mana:0)))
        XCTAssertFalse(session.state.board.monsters.contains(monster))
        XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
    }
    func testZeroActionFreeWindowIsNotConfusedWithHeroPrerequisites() throws {
        var session = try afterBastion(cost:0)
        XCTAssertTrue(session.apply(.placeSoldier(Point(0,1))).success)
        let before = session.state
        XCTAssertEqual(before.current,.one);XCTAssertEqual(before.apRemaining,0);XCTAssertTrue(before.awaitingFreeHunt)
        XCTAssertEqual(TacticalReadiness.restriction(before,mode:.skill),.noActions)
        let preview = TacticalHuntPreview(before,at:monster)
        XCTAssertEqual(preview.reason,.none);XCTAssertEqual(preview.apCost,0)
        XCTAssertTrue(preview.help.contains("不占施法次數"));XCTAssertEqual(session.state,before)
        XCTAssertTrue(session.apply(.huntMonster(monster)).success)
        XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
    }
    func testWolfNeedsAdjacentHeroEvenIfGlobalSkillIsReady() throws {
        var c = TacticalHints.updatedConfig(size:9);c.monsterBattlefield = .init(kind:.shadowWolf,awardsLoot:true)
        let state = try GameSetup.fromDiagram(config:c,
            diagram:".........\n....O....\n.........\n.........\n...xMx...\n.........\n....H....\n....X....\n.........",classOne:.mage,manaOne:6)
        XCTAssertNil(TacticalReadiness.restriction(state,mode:.skill))
        let preview = TacticalHuntPreview(state,at:monster)
        XCTAssertEqual(preview.reason,.noHeroOnBoard);XCTAssertEqual(preview.friendly,2)
        XCTAssertTrue(preview.targetRestriction?.contains("上下左右一格") == true)
        XCTAssertTrue(preview.help.contains("影步一次"));XCTAssertEqual(preview.reward,"影步")
        XCTAssertEqual(GameEngine.apply(state,.huntMonster(monster)).state,state)
    }
    func testSlimeHuntNeedsNeitherHeroNorManaFromLegalOpening() throws {
        var c = TacticalHints.updatedConfig(size:9)
        c.initialMana = 0;c.manaGainPerTurn = 0
        c.monsterBattlefield = .init(huntAPCost:1,awardsLoot:true)
        var session = GameSession(try GameSetup.newGame(config:c,classOne:.mage,classTwo:.warrior))
        for action: GameAction in [.placeSoldier(Point(3,4)),.placeSoldier(Point(0,0)),.endTurn,.placeSoldier(Point(5,4))] {
            XCTAssertTrue(session.apply(action).success)
        }
        let before = session.state
        XCTAssertEqual(before.mana(of:.one),0);XCTAssertNil(before.board.find(.one,.hero))
        XCTAssertEqual(TacticalReadiness.restriction(before,mode:.skill),.needsHero)
        XCTAssertEqual(TacticalHuntPreview(before,at:monster).reason,.none)
        let outcome = session.apply(.huntMonster(monster))
        XCTAssertTrue(outcome.success);XCTAssertTrue(outcome.events.contains(.resourcesSpent(.one,ap:1,mana:0)))
        XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
    }
    func testUncontrolledAndRemovedMonsterRemainInvalid() throws {
        var c = TacticalHints.updatedConfig(size:9);c.monsterBattlefield = .init(awardsLoot:false)
        let state = try GameSetup.newGame(config:c,classOne:.mage,classTwo:.warrior)
        let preview = TacticalHuntPreview(state,at:monster)
        XCTAssertEqual(preview.reason,.insufficientMonsterControl);XCTAssertEqual(preview.friendly,0)
        XCTAssertTrue(preview.targetRestriction?.contains("我0：敵0") == true)
        XCTAssertTrue(preview.help.contains("不發戰利"))
        XCTAssertTrue(preview.help.contains("包圍不會自動討伐"))
        XCTAssertTrue(preview.help.contains("再按確認"))
        let removed = TacticalHuntPreview(state,at:Point(3,4))
        XCTAssertEqual(removed.reason,.invalidTarget)
        let noMode = try GameSetup.newGame(config:TacticalHints.updatedConfig(size:9))
        XCTAssertEqual(TacticalHuntPreview(noMode,at:monster).reason,.monsterModeDisabled)
    }
}
