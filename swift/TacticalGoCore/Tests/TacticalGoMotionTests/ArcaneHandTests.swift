import XCTest
@testable import TacticalGoCore
import TacticalGoMotion

final class ArcaneHandTests: XCTestCase {
    func testAuthoredPhysicalBeatsAndReducedCompletion() {
        // Independent authoring sheet in PRESENT-04 PLAN: reach .30-.40,
        // brace .40-.46, force .46-.68, hold impact .68-.73, release to1.08.
        let reach=ArcaneHandFrame.sample(at:0.35)
        XCTAssertEqual(reach.phase,.reach); XCTAssertGreaterThan(reach.open,0.9)
        let brace=ArcaneHandFrame.sample(at:0.459)
        XCTAssertEqual(brace.phase,.brace); XCTAssertGreaterThan(brace.cup,0.95)
        XCTAssertLessThan(brace.pawnSquash,0.86)
        let push=ArcaneHandFrame.sample(at:0.55)
        XCTAssertEqual(push.phase,.push); XCTAssertEqual(push.palm,1)
        XCTAssertEqual(ArcaneHandFrame.sample(at:0.70).phase,.contact)
        XCTAssertEqual(ArcaneHandFrame.sample(at:0.70).pawnSquash,0.84)
        XCTAssertGreaterThan(ArcaneHandFrame.sample(at:0.815).pawnSquash,1)
        for t in [1.08,2,Double.nan,Double.infinity,-1] {
            let f=ArcaneHandFrame.sample(at:t)
            XCTAssertEqual(f.alpha,0); XCTAssertEqual(f.pawnSquash,1)
        }
        XCTAssertEqual(ArcaneHandFrame.sample(at:0.55,reduced:true).alpha,0)
        XCTAssertEqual(ArcaneHandFrame.sample(at:0.55,reduced:true).pawnSquash,1)
        for i in 0...108 {
            let f=ArcaneHandFrame.sample(at:Double(i)/100)
            if f.alpha > 0 { XCTAssertEqual(f.open+f.cup+f.palm,1,accuracy:1e-9) }
            XCTAssertTrue((0.84...1.08).contains(f.pawnSquash))
        }
    }
    func testDAndPhoneBaselineShareRulesInBothTeamsAndCapture() throws {
        for size in [7,9] { for caster in Player.allCases { for capture in [false,true] {
            let before=try Anim01Fixture.state(size:size,caster:caster,pushedOwner:caster,capture:capture)
            let outcome=GameEngine.apply(before,Anim01Fixture.action)
            let d=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.arcaneHand))
            let a=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneOriginal))
            XCTAssertEqual(d.before,a.before);XCTAssertEqual(d.after,a.after)
            XCTAssertEqual(d.clip.from,Point(4,3));XCTAssertEqual(d.clip.to,Point(4,2))
            XCTAssertEqual(d.clip.duration,1.08)
            XCTAssertEqual(Array(d.sounds.prefix(3)),[.init("p4-conjure",at:0.08),.init("p4-push",at:0.46),.init("p4-contact",at:0.68)])
            XCTAssertEqual(d.sounds.contains(.init("capture",at:0.80)),capture)
            XCTAssertEqual(d.sounds.contains(.init("victory",at:1.08)),capture)
            XCTAssertEqual(d.clip.progress(at:0.46),0);XCTAssertEqual(d.clip.progress(at:0.68),1)
            XCTAssertEqual(d.pose(at:1.08),.rest);XCTAssertEqual(d.pose(at:0.55,reducedMotion:true),.rest)
            XCTAssertEqual(d.board(at:1.08),outcome.state.board)
            XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:before,variant:.arcaneHand))
        } } }
    }
    func testAudioRevisionKeepsAcceptedAnimationAndRulesWithSameBeats() throws {
        let before=try Anim01Fixture.state(capture:true),outcome=GameEngine.apply(before,Anim01Fixture.action)
        let d=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.arcaneHand))
        let e=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.arcaneHand,arcaneAudio:.weighty))
        XCTAssertEqual(e.before,d.before);XCTAssertEqual(e.after,d.after);XCTAssertEqual(e.clip,d.clip)
        XCTAssertEqual(Array(e.sounds.prefix(3)),[.init("p5-conjure",at:0.08),.init("p5-push",at:0.46),.init("p5-contact",at:0.68)])
        XCTAssertEqual(Array(e.sounds.suffix(2)),Array(d.sounds.suffix(2)))
        for t in [0.18,0.30,0.46,0.68,0.80,1.08] { XCTAssertEqual(e.pose(at:t),d.pose(at:t));XCTAssertEqual(e.board(at:t),d.board(at:t)) }
        let a=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneOriginal,arcaneAudio:.weighty))
        XCTAssertEqual(Array(a.sounds.prefix(2)),[.init("mage",at:0.26),.init("place",at:0.60)])
    }
    func testAllCardinalPushesAndLastAPAreConfirmedBeforeMotion() throws {
        for direction in [PushDirection.up,.down,.left,.right] {
            var rows=Array(repeating:Array(repeating:Character("."),count:7),count:7)
            rows[3][4]="o"; rows[3][direction == .left ? 5:3]="H"; rows[5][1]="X";rows[1][1]="O"
            let before=try GameSetup.fromDiagram(config:.board(size:7),diagram:rows.map { String($0) }.joined(separator:"\n"),classOne:.mage,classTwo:.warrior,current:.one,manaOne:4,manaTwo:4,ap:1)
            let action=GameAction.castMagicHand(Point(4,3),direction),outcome=GameEngine.apply(before,action)
            let d=try XCTUnwrap(MagePresentationPlan.make(before:before,action:action,outcome:outcome,current:outcome.state,variant:.arcaneHand))
            XCTAssertEqual(d.clip.to,direction.destination(from:Point(4,3)))
            XCTAssertEqual(d.clip.piece.owner,.two);XCTAssertEqual(outcome.state.current,.two)
            XCTAssertEqual(d.sounds.count,3)
            let bad=GameAction.castMagicHand(d.clip.hero,direction),failed=GameEngine.apply(before,bad)
            XCTAssertNil(MagePresentationPlan.make(before:before,action:bad,outcome:failed,current:failed.state,variant:.arcaneHand))
        }
    }
}
