import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class HeroPerformanceTests: XCTestCase {
    func testWarriorDownstrokeHasNoSecondHoldAndContactCarriesWeight() {
        let t = HeroBodyTiming.skill(.warrior)
        let samples = (0...6).map { t.release+(t.arrival-t.release)*Double($0)/6 }
        let poses = samples.map { HeroBodyPose.skill(.warrior,at:$0) }
        for pair in zip(poses,poses.dropFirst()) {
            XCTAssertGreaterThan(pair.1.shieldY,pair.0.shieldY,
                "After release the shield must keep descending until both soldiers land")
        }
        let coil = HeroBodyPose.skill(.warrior,at:t.anticipationEnd)
        let contact = HeroBodyPose.skill(.warrior,at:t.arrival)
        XCTAssertGreaterThan(contact.bodyY,coil.bodyY)
        XCTAssertGreaterThan(contact.bodyY,poses[0].bodyY)
        XCTAssertLessThan(HeroBodyPose.skill(.warrior,at:t.arrival+0.07).bodyY,contact.bodyY)
    }
    func testBothTeamsSummonSkillsAndDenseFixturesUseRealCore() throws {
        for h in [HeroClass.warrior,.rogue] { for owner in Player.allCases {
            for size in [7,9] { for summon in [false,true] { for capture in [false,true] where !summon || !capture {
                let s = try HeroBodyFixture.state(h,owner:owner,size:size,capture:capture,summon:summon)
                let a = HeroBodyFixture.action(h,summon:summon),o = GameEngine.apply(s,a)
                XCTAssertTrue(o.success,"\(h) \(owner) \(size) \(summon) \(capture) \(o.reason)")
                let clip = try XCTUnwrap(HeroPerformance.make(before:s,action:a,outcome:o))
                XCTAssertEqual(clip.heroClass,h);XCTAssertEqual(clip.isSummon,summon)
                XCTAssertEqual(o.state.apRemaining,1);XCTAssertEqual(o.state.mana(of:owner),summon ? 2 : 2)
                XCTAssertEqual(s.apRemaining,2);XCTAssertEqual(s.mana(of:owner),4)
                if capture { XCTAssertEqual(o.state.status,.won);XCTAssertEqual(o.state.winner,owner);XCTAssertTrue(clip.plan.cues.contains {if case .capture = $0.kind {return true};return false}) }
            }}}
            let dense = try HeroBodyFixture.state(h,owner:owner,size:9,dense:true)
            XCTAssertNotNil(dense.board[Point(3,2)]);XCTAssertNotNil(dense.board[Point(3,4)])
            XCTAssertTrue(GameEngine.apply(dense,HeroBodyFixture.action(h)).success)
        }}
    }
    func testSkillBodyReleasePrecedesReceiptedMovementAndAudio() throws {
        for h in [HeroClass.warrior,.rogue] {
            let s = try HeroBodyFixture.state(h),a = HeroBodyFixture.action(h),o = GameEngine.apply(s,a)
            let p = try XCTUnwrap(HeroPerformance.make(before:s,action:a,outcome:o)),t = p.timing
            XCTAssertLessThan(t.anticipationEnd,t.release);XCTAssertLessThan(t.release,t.moveStart);XCTAssertLessThan(t.moveStart,t.arrival)
            let movements = p.plan.cues.filter {if case .drop = $0.kind {return true};if case .swap = $0.kind{return true};return false}
            XCTAssertEqual(movements.count,h == .warrior ? 2 : 1)
            XCTAssertTrue(movements.allSatisfy{$0.start == t.moveStart && abs($0.start+$0.duration-t.arrival)<0.00001})
            XCTAssertEqual(p.audio.cues.first{$0.key == "place"}?.start,t.arrival)
            XCTAssertEqual(p.audio.cues.first{$0.key == (h == .warrior ? "warrior" : "rogue")}?.start,t.release)
            XCTAssertFalse(p.audio.cues.contains{$0.key == "capture" || $0.key == "victory"})
        }
    }
    func testFailedAndUnrelatedActionsHaveNoBodySuccessPlan() throws {
        for h in [HeroClass.warrior,.rogue] {
            let s = try HeroBodyFixture.state(h)
            let invalid:GameAction = h == .warrior ? .castBastion(Point(0,0),Point(6,6)) : .castSwap(Point(0,0))
            let o = GameEngine.apply(s,invalid);XCTAssertFalse(o.success);XCTAssertEqual(o.state,s)
            XCTAssertNil(HeroPerformance.make(before:s,action:invalid,outcome:o))
            let place = GameAction.placeSoldier(Point(0,0)),p = GameEngine.apply(s,place)
            XCTAssertNil(HeroPerformance.make(before:s,action:place,outcome:p))
        }
    }
    func testLastAPDrawFollowsRealSkillLanding() throws {
        var config = RuleConfig.board(size:7);config.maxPlies = 2
        for hero in [HeroClass.warrior,.rogue] {
            let before = try GameSetup.fromDiagram(config:config,diagram:".......\n...O...\n.......\n...H"+(hero == .rogue ? "o" : ".")+"..\n.......\n...X...\n.......",classOne:hero,classTwo:hero,manaOne:4,manaTwo:4,ap:1,ply:2)
            let action = HeroBodyFixture.action(hero),outcome = GameEngine.apply(before,action)
            XCTAssertTrue(outcome.success);XCTAssertEqual(outcome.state.status,.drawn)
            let p = try XCTUnwrap(HeroPerformance.make(before:before,action:action,outcome:outcome))
            XCTAssertTrue(p.plan.cues.contains{if case .draw = $0.kind {return $0.start == p.timing.arrival};return false})
            XCTAssertEqual(p.audio.cues.first{$0.key == "draw"}?.start,p.timing.arrival)
            XCTAssertGreaterThanOrEqual(p.audio.duration,p.timing.arrival+0.4)
            XCTAssertGreaterThanOrEqual(p.duration,p.timing.recoveryEnd)
        }
    }
    func testReadablePoseAmplitudeContinuityAndReducedRest() {
        for h in [HeroClass.warrior,.rogue] {
            let t = HeroBodyTiming.skill(h),coil = HeroBodyPose.skill(h,at:t.anticipationEnd),release = HeroBodyPose.skill(h,at:t.release)
            XCTAssertNotEqual(coil,release)
            if h == .warrior {
                // Small-board art target: at least an 8pt shield stroke and a
                // distinct held anticipation before release (no extra VFX).
                let impact = HeroBodyPose.skill(h,at:t.arrival)
                XCTAssertGreaterThan((impact.shieldY-coil.shieldY)*0.88*46.56/512,8)
                XCTAssertGreaterThan(impact.shieldY,release.shieldY)
                XCTAssertLessThan(HeroBodyPose.skill(h,at:t.arrival+0.08).shieldY,impact.shieldY)
                let hold = HeroBodyPose.skill(h,at:t.anticipationEnd+0.02)
                XCTAssertEqual(hold.shieldY,coil.shieldY)
                XCTAssertEqual(hold.shield,coil.shield)
            }
            else {XCTAssertGreaterThan(coil.bodyY*0.88*46.56/512,2.5)}
            for boundary in [0,t.anticipationEnd,t.release,t.arrival,t.recoveryEnd] {
                let a = HeroBodyPose.skill(h,at:boundary-0.000001),b = HeroBodyPose.skill(h,at:boundary+0.000001)
                XCTAssertLessThan(abs(a.bodyX-b.bodyX),0.01);XCTAssertLessThan(abs(a.held-b.held),0.01)
            }
            XCTAssertEqual(HeroBodyPose.skill(h,at:t.recoveryEnd),.rest)
            XCTAssertEqual(HeroBodyPose.skill(h,at:t.anticipationEnd,reduced:true),.rest)
            XCTAssertEqual(HeroBodyPose.summon(h,at:0.2,reduced:true),.rest)
        }
    }
}
