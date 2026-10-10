import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class SkillVFXTests: XCTestCase {
    func testFiniteBurstsCannotOutliveTheirReceiptOrReachNeighborAnchor() {
        for age in [-1.0, 0.26, 10, Double.nan, Double.infinity] { XCTAssertTrue(SkillBurstSample.samples(at:age).isEmpty) }
        for frame in 0..<26 {
            let age=Double(frame)/100
            let samples=SkillBurstSample.samples(at:age,count:100)
            XCTAssertEqual(samples.count,28)
            XCTAssertEqual(samples,SkillBurstSample.samples(at:age,count:100))
            for p in samples {
                XCTAssertTrue(p.x.isFinite && p.y.isFinite && p.alpha.isFinite)
                XCTAssertLessThan(hypot(p.x,p.y),0.72)
                XCTAssertTrue((0...1).contains(p.alpha));XCTAssertGreaterThan(p.scale,0)
            }
        }
        XCTAssertTrue(SkillBurstSample.samples(at:0.1,count:-5).isEmpty)
    }
    func testClassesTeamsSizesAndCapturesUseExactSuccessfulReceipts() throws {
        for h in [HeroClass.warrior,.mage,.rogue] {for owner in Player.allCases {for size in [7,9] {for capture in [false,true] {
            let before=try SkillVFXFixture.state(h,owner:owner,size:size,capture:capture)
            let action=SkillVFXFixture.action(h),outcome=GameEngine.apply(before,action)
            XCTAssertTrue(outcome.success)
            let fx=try XCTUnwrap(SkillVFX.make(before:before,action:action,outcome:outcome))
            XCTAssertEqual(fx.caster,owner);XCTAssertEqual(fx.hero,Point(3,3))
            XCTAssertEqual(fx.destinations,h == .warrior ? [Point(2,3),Point(4,3)]:h == .mage ? [Point(4,2)]:[Point(4,3),Point(3,3)])
            XCTAssertEqual(outcome.state.apRemaining,1);XCTAssertEqual(outcome.state.mana(of:owner),2)
            XCTAssertEqual(fx.captures.isEmpty,!capture)
            if capture {XCTAssertTrue(fx.captures.contains{$0.piece.kind == .commander})}
            XCTAssertEqual(before.apRemaining,2);XCTAssertEqual(before.mana(of:owner),4)
        }}}}
    }
    func testDenseFixturesAndEnemyMageTargetsRetainIdentity() throws {
        for h in [HeroClass.warrior,.mage,.rogue] {for owner in Player.allCases {
            let before=try SkillVFXFixture.state(h,owner:owner,size:9,dense:true,enemyTarget:h == .mage)
            XCTAssertNotNil(before.board[Point(3,2)]);XCTAssertNotNil(before.board[Point(3,4)])
            let action=SkillVFXFixture.action(h),result=GameEngine.apply(before,action)
            XCTAssertTrue(result.success)
            let fx=try XCTUnwrap(SkillVFX.make(before:before,action:action,outcome:result))
            if h == .mage {XCTAssertEqual(result.state.board[fx.destinations[0]]?.owner,owner.opponent)}
        }}
    }
    func testIllegalActionsAndOrdinaryActionsHaveNoSkillEffects() throws {
        let before=try SkillVFXFixture.state(.warrior)
        for action in [GameAction.castBastion(Point(2,3),Point(2,3)),.castSwap(Point(4,3)),.endTurn,.placeSoldier(Point(0,0))] {
            XCTAssertNil(SkillVFX.make(before:before,action:action,outcome:GameEngine.apply(before,action)))
        }
        let summon=try HeroBodyFixture.state(.warrior,summon:true)
        let action=GameAction.summonHero(Point(3,4)),result=GameEngine.apply(summon,action)
        XCTAssertTrue(result.success);XCTAssertNil(SkillVFX.make(before:summon,action:action,outcome:result))
    }
    func testSharedTimingsAndEffectWindowDoNotExtendPresentationLock() throws {
        for h in [HeroClass.warrior,.mage,.rogue] {
            let before=try SkillVFXFixture.state(h,capture:true),a=SkillVFXFixture.action(h),r=GameEngine.apply(before,a)
            let fx=try XCTUnwrap(SkillVFX.make(before:before,action:a,outcome:r))
            XCTAssertLessThan(fx.release,fx.moveStart);XCTAssertLessThan(fx.moveStart,fx.arrival);XCTAssertLessThan(fx.arrival,fx.captureStart)
            XCTAssertFalse(fx.isActive(at:-0.001));XCTAssertTrue(fx.isActive(at:fx.arrival));XCTAssertFalse(fx.isActive(at:fx.end))
            if h == .mage {XCTAssertEqual(fx.end,Anim01MagicHand.make(before:before,action:a,outcome:r)?.duration)}
            else {XCTAssertEqual(fx.end,HeroPerformance.make(before:before,action:a,outcome:r)?.duration)}
        }
        XCTAssertLessThanOrEqual(SkillVFX.reducedHintDuration,0.25)
    }
    func testCompactMageUsesCompactBodyAndSoundClock() throws {
        let b=try SkillVFXFixture.state(.mage),a=SkillVFXFixture.action(.mage),o=GameEngine.apply(b,a)
        let fx=try XCTUnwrap(SkillVFX.make(before:b,action:a,outcome:o,tempo:.compact))
        XCTAssertEqual(fx.arrival,MageTempo.compact.timing.arrival)
        XCTAssertEqual(fx.release,CombatFeedbackPlan.anim01(before:b,action:a,outcome:o,tempo:.compact).cues.first{$0.key=="mage"}?.start)
    }
    func testLegalCandidateRedeploymentDoesNotPretendToBeOneCellPush() throws {
        var c=RuleConfig.board(size:7);c.experimentalFriendlyRedeploy=true
        let b=try GameSetup.fromDiagram(config:c,diagram:"O..x...\n..xxx..\n.xxxxx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X",classOne:.mage,manaOne:4)
        let a=GameAction.castFriendlyRedeploy(Point(3,2),Point(1,1)),o=GameEngine.apply(b,a)
        XCTAssertTrue(o.success);XCTAssertNil(SkillVFX.make(before:b,action:a,outcome:o))
    }
}
