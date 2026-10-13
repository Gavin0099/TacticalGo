import XCTest
@testable import TacticalGoCore
import TacticalGoMotion

final class MagePresentationTests: XCTestCase {
    func testRefinedPhoneKeepsClockSoundIdentityAndContactGesture() throws {
        // Contract: C keeps the frozen phone clock, Domain result and original
        // four SFX identities. Only a quiet air stem is added during push.
        for size in [7,9] { for caster in Player.allCases { for capture in [false,true] {
            let before=try Anim01Fixture.state(size:size,caster:caster,pushedOwner:caster,capture:capture)
            let outcome=GameEngine.apply(before,Anim01Fixture.action)
            let a=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneOriginal))
            let c=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneRefined))
            XCTAssertEqual(c.clip.timing,a.clip.timing)
            XCTAssertEqual(c.before,a.before); XCTAssertEqual(c.after,a.after)
            XCTAssertEqual(c.sounds.filter { $0.key != "p3-air" },a.sounds)
            XCTAssertEqual(c.sounds.filter { $0.key == "p3-air" },[.init("p3-air",at:0.38)])
            XCTAssertLessThan(c.clip.timing.release,c.clip.timing.moveStart)
            XCTAssertLessThan(c.clip.timing.arrival,c.clip.timing.captureStart)
            // Contact holds the committed hand direction, while the torso can
            // settle. Cloth follows after body rest; completion cannot freeze.
            XCTAssertNotEqual(c.pose(at:0.26),.rest)
            XCTAssertEqual(c.pose(at:0.60).shoulder,c.pose(at:0.26).shoulder)
            XCTAssertEqual(c.pose(at:0.84).torso,0)
            XCTAssertNotEqual(c.pose(at:0.84).cape,0)
            for t in [0.95,1.2,100] { XCTAssertEqual(c.pose(at:t),.rest); XCTAssertEqual(c.board(at:t),outcome.state.board) }
            XCTAssertEqual(c.pose(at:0.26,reducedMotion:true),.rest)
            XCTAssertEqual(c.board(at:0,reducedMotion:true),outcome.state.board)
        } } }
    }
    func testRefinedPhoneLastAPEnemyPawnAndStaleReceipt() throws {
        let before=try Anim01Fixture.state(caster:.two,pushedOwner:.one,capture:false,ap:1)
        let outcome=GameEngine.apply(before,Anim01Fixture.action)
        let c=try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneRefined))
        XCTAssertEqual(c.clip.piece.owner,.one)
        XCTAssertEqual(outcome.state.current,.one)
        XCTAssertEqual(c.sounds.count,3)
        XCTAssertFalse(c.sounds.contains { $0.key == "victory" || $0.key == "capture" })
        XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:before,variant:.phoneRefined))
        let failed=GameEngine.apply(before,.castMagicHand(Point(3,3),.up))
        XCTAssertNil(MagePresentationPlan.make(before:before,action:.castMagicHand(Point(3,3),.up),outcome:failed,current:failed.state,variant:.phoneRefined))
    }
    func testPhone1023ReferenceUsesFrozenTimingAndR1Pose() throws {
        // Independent oracle: frozen signed1023 MagePerformance and audio sheet,
        // not a copy of the prior PRESENT-01 M3 timing.
        for size in [7,9] { for caster in Player.allCases { for capture in [false,true] {
            let before = try Anim01Fixture.state(size:size,caster:caster,pushedOwner:caster,capture:capture)
            let outcome = GameEngine.apply(before,Anim01Fixture.action)
            let a = try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.phoneOriginal))
            XCTAssertEqual(a.clip.timing.release,0.26)
            XCTAssertEqual(a.clip.timing.moveStart,0.38)
            XCTAssertEqual(a.clip.timing.arrival,0.60)
            XCTAssertEqual(a.clip.timing.captureStart,0.70)
            XCTAssertEqual(a.clip.duration,0.95)
            XCTAssertEqual(Array(a.sounds.prefix(2)),[.init("mage",at:0.26),.init("place",at:0.60)])
            XCTAssertFalse(a.sounds.contains { $0.key.hasPrefix("p-") })
            let release = a.pose(at:0.26)
            XCTAssertEqual(release.shoulder,18)
            XCTAssertEqual(release.heldX,-30)
            XCTAssertEqual(release.torsoX,-44)
            XCTAssertEqual(a.pose(at:0.38).shoulder,18)
            XCTAssertEqual(a.pose(at:0.95),.rest)
            XCTAssertEqual(a.pose(at:0.26,reducedMotion:true),.rest)
            XCTAssertEqual(a.after,outcome.state)
            XCTAssertEqual(a.sounds.count,capture ? 4 : 2)
        } } }
    }
    func testIndependentTimingSheetAndSameDomainResult() throws {
        for size in [7,9] { for caster in Player.allCases { for capture in [false,true] {
            let before = try Anim01Fixture.state(size:size,caster:caster,pushedOwner:caster,capture:capture)
            let outcome = GameEngine.apply(before,Anim01Fixture.action)
            XCTAssertTrue(outcome.success)
            let a = try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.original))
            let b = try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.rhythmic))
            XCTAssertEqual(a.after,b.after)
            XCTAssertEqual(a.clip.duration,0.95,accuracy:1e-9)
            XCTAssertEqual(b.clip.duration,0.70,accuracy:1e-9)
            XCTAssertEqual(b.clip.timing.anticipationEnd,0.10)
            XCTAssertEqual(b.clip.timing.release,0.22)
            XCTAssertEqual(b.clip.timing.arrival,0.52)
            XCTAssertEqual(b.sounds.prefix(3),[.init("p-charge",at:0),.init("p-release",at:0.22),.init("p-land",at:0.52)])
            XCTAssertEqual(b.after.board[Point(4,2)],Piece(caster,.soldier))
            XCTAssertNil(b.after.board[Point(4,3)])
            XCTAssertEqual(b.after.apRemaining,1)
            XCTAssertEqual(b.after.mana(of:caster),2)
            XCTAssertEqual(b.sounds.contains { $0.key == "p-capture" },capture)
            XCTAssertEqual(b.sounds.contains { $0.key == "victory" },capture)
            if capture { XCTAssertNil(b.after.board[Point(3,2)]); XCTAssertEqual(b.after.winner,caster) }
        } } }
    }
    func testEnemyOwnershipLastAPAndRestCompletion() throws {
        let before = try Anim01Fixture.state(caster:.two,pushedOwner:.one,capture:false,ap:1)
        let outcome = GameEngine.apply(before,Anim01Fixture.action)
        let b = try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:outcome.state,variant:.rhythmic))
        XCTAssertEqual(b.clip.piece.owner,.one)
        XCTAssertEqual(outcome.state.current,.one)
        XCTAssertEqual(b.board(at:0.519),before.board)
        XCTAssertEqual(b.board(at:0.52),outcome.state.board)
        XCTAssertEqual(b.board(at:0,reducedMotion:true),outcome.state.board)
        XCTAssertEqual(b.pose(at:0.7),.rest)
        XCTAssertEqual(b.pose(at:0.22,reducedMotion:true),.rest)
        XCTAssertNotEqual(b.pose(at:0.10),.rest)
        XCTAssertNotEqual(b.pose(at:0.22),.rest)
        XCTAssertEqual(b.clip.progress(at:0.21),0)
        XCTAssertEqual(b.clip.progress(at:0.52),1)
        XCTAssertEqual(b.clip.displayTime(elapsed:0.6,animating:false,reducedMotion:false),0.7,accuracy:1e-9)
    }
    func testFailedPreviewStaleAndMalformedReceiptsAreSilent() throws {
        let before = try Anim01Fixture.state(capture:false)
        let outcome = GameEngine.apply(before,Anim01Fixture.action)
        // Current is still before: uncommitted preview cannot produce a plan.
        XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:before,variant:.rhythmic))
        let later = GameEngine.apply(outcome.state,.placeSoldier(Point(0,0)))
        XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:later.state,variant:.rhythmic))
        for action in [GameAction.castMagicHand(Point(-1,3),.up), .castMagicHand(Point(4,3),.invalid), .placeSoldier(Point(4,3))] {
            XCTAssertNil(MagePresentationPlan.make(before:before,action:action,outcome:outcome,current:outcome.state,variant:.rhythmic))
        }
        let failed = GameEngine.apply(before,.castMagicHand(Point(3,3),.up))
        XCTAssertFalse(failed.success)
        XCTAssertNil(MagePresentationPlan.make(before:before,action:.castMagicHand(Point(3,3),.up),outcome:failed,current:failed.state,variant:.rhythmic))
        let forged = ActionOutcome(state:outcome.state,events:[],reason:.none)
        XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:forged,current:forged.state,variant:.rhythmic))
    }
    func testUndoDoesNotDependOnAnimationCompletion() throws {
        let before = try Anim01Fixture.state(capture:true)
        var session = GameSession(before)
        let outcome = session.apply(Anim01Fixture.action)
        let plan = try XCTUnwrap(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:session.state,variant:.rhythmic))
        XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state,before)
        XCTAssertEqual(plan.after.status,.won)
        XCTAssertNil(MagePresentationPlan.make(before:before,action:Anim01Fixture.action,outcome:outcome,current:session.state,variant:.rhythmic))
    }
}
