import XCTest
@testable import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoMotion

final class MonsterHuntFrameTests: XCTestCase {
    func testRealHuntReceiptsCarryActualGrantWithoutChangingTimingOrState() throws {
        for fixture in [MonsterPresentationPractice.slimeHunt,.wolfHunt] {
            let before = try fixture.session().state
            let outcome = GameEngine.apply(before,fixture.action)
            let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:outcome,current:outcome.state))
            XCTAssertEqual(p.lootGrants.count,1);XCTAssertEqual(p.lootGrants[0].owner,.one)
            XCTAssertEqual(p.lootGrants[0].ability,fixture == .slimeHunt ? .stickyBounce:.shadowStep)
            XCTAssertEqual(p.lootGrants[0].unlockPly,before.ply+2)
            XCTAssertEqual(p.arrival,0.44);XCTAssertEqual(p.duration,0.76)
            XCTAssertEqual(p.board(at:0.43),before.board);XCTAssertEqual(p.board(at:0.44),outcome.state.board)
            XCTAssertEqual(p.after,outcome.state)
        }
    }
    func testHuntWithoutLootCannotShowRewardAndForgedGrantCannotCreateReceipt() throws {
        let fixture = MonsterPresentationPractice.slimeHunt,source = try fixture.session()
        var c = source.state.config;c.monsterBattlefield = .init(huntAPCost:1,awardsLoot:false)
        var replay = GameSession(try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage))
        for a in source.log { XCTAssertTrue(replay.apply(a).success) }
        let before = replay.state,outcome = GameEngine.apply(before,fixture.action)
        let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:outcome,current:outcome.state))
        XCTAssertEqual(p.hunted,[Point(4,4)]);XCTAssertTrue(p.lootGrants.isEmpty)
        let forged = ActionOutcome(state:outcome.state,events:outcome.events+[.monsterLootGranted(.two,.shadowStep,unlockPly:1)],reason:.none)
        XCTAssertNil(ExpansionPresentation.make(before:before,action:fixture.action,outcome:forged,current:forged.state))
    }
    func testCompressionAtContactIsDifferentFromPreparationAndStaysInsideOneCell() {
        let prep = MonsterHuntFrame.sample(kind:.slime,at:0.10)
        let impact = MonsterHuntFrame.sample(kind:.slime,at:0.43)
        XCTAssertGreaterThan(impact.x,prep.x);XCTAssertLessThan(impact.y,prep.y)
        for kind in MonsterKind.allCases { for i in 0...760 {
            let f = MonsterHuntFrame.sample(kind:kind,at:Double(i)/1000)
            XCTAssertTrue((0.9...1.24).contains(f.x));XCTAssertTrue((0.65...1.1).contains(f.y))
            XCTAssertLessThanOrEqual(0.70*f.x,0.90)
            XCTAssertTrue((0...1).contains(f.rewardOpacity));XCTAssertTrue((0.75...1).contains(f.rewardScale))
            XCTAssertLessThanOrEqual(abs(f.tilt),4.01)
        } }
    }
    func testRewardStartsAfterArrivalAndSettlesWithoutResidueOrReducedMotion() {
        for kind in MonsterKind.allCases {
            for t in [0.0,0.14,0.30,0.439,0.44] { XCTAssertEqual(MonsterHuntFrame.sample(kind:kind,at:t).rewardOpacity,0) }
            XCTAssertGreaterThan(MonsterHuntFrame.sample(kind:kind,at:0.50).rewardOpacity,0.9)
            XCTAssertEqual(MonsterHuntFrame.sample(kind:kind,at:0.76),.rest)
            for t in [-1.0,Double.nan,Double.infinity,1.0] { XCTAssertEqual(MonsterHuntFrame.sample(kind:kind,at:t),.rest) }
            for t in [0.1,0.43,0.50] { XCTAssertEqual(MonsterHuntFrame.sample(kind:kind,at:t,reduced:true),.rest) }
        }
    }
}
