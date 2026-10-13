import XCTest
@testable import TacticalGoCore
@testable import TacticalGoMotion

final class WarriorPresentationTests:XCTestCase {
    func testWeightedDownstrokeImpactHoldAndDelayedRecoveryPreserveRestAndReducedMotion() {
        // Owner contract: hold windup until .42; contact .58; hold to .64;
        // recoil .74, body rest .94, cloth follows. No rule/timing alteration.
        let coil = WarriorBodyPose.skill(at:0.42,weighted:true)
        let impact = WarriorBodyPose.skill(at:0.58,weighted:true)
        let hold = WarriorBodyPose.skill(at:0.64,weighted:true)
        XCTAssertEqual(coil.shieldY,-104);XCTAssertEqual(impact.shieldY,46)
        XCTAssertEqual(impact.body,hold.body);XCTAssertEqual(impact.shieldY,hold.shieldY)
        XCTAssertLessThan(WarriorBodyPose.skill(at:0.74,weighted:true).shieldY,impact.shieldY)
        XCTAssertEqual(WarriorBodyPose.skill(at:0.94,weighted:true).body,0)
        XCTAssertNotEqual(impact,WarriorBodyPose.skill(at:0.58))
        for time in [-1,1.02,Double.nan,Double.infinity] { XCTAssertEqual(WarriorBodyPose.skill(at:time,weighted:true),.rest) }
        XCTAssertEqual(WarriorBodyPose.skill(at:0.58,reduced:true,weighted:true),.rest)
    }
    func testAtomicPlacementBoardAndResourcesForBothTeamsAndSizes() throws {
        for owner in Player.allCases {for size in [7,9] {for dense in [false,true] {
            let before=try WarriorPresentationFixture.state(owner:owner,size:size,dense:dense)
            for at in before.board.points where before.board[at] != nil {XCTAssertFalse(before.board.liberties(at:at).isEmpty,"review fixture starts with zero liberties")}
            let outcome=GameEngine.apply(before,WarriorPresentationFixture.action)
            let p=try XCTUnwrap(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:outcome,current:outcome.state))
            XCTAssertEqual(Set(p.placements),Set([Point(2,3),Point(4,3)]))
            for at in p.placements {XCTAssertNil(before.board[at]);XCTAssertEqual(p.after.board[at],Piece(owner,.soldier))}
            XCTAssertEqual(p.after.apRemaining,1);XCTAssertEqual(p.after.mana(of:owner),2)
            XCTAssertEqual(p.board(at:0.579),before.board);XCTAssertEqual(p.board(at:0.58),outcome.state.board)
            XCTAssertEqual(p.board(at:0,reduced:true),outcome.state.board)
            XCTAssertEqual(p.fallProgress(at:0.34),0);XCTAssertEqual(p.fallProgress(at:0.58),1)
            XCTAssertFalse(p.sounds.contains {$0.key=="capture" || $0.key=="victory"})
        }}}
    }
    func testActualCaptureAndWinnerOnlyFromReceipt() throws {
        for owner in Player.allCases {
            let before=try WarriorPresentationFixture.state(owner:owner,capture:true)
            let result=GameEngine.apply(before,WarriorPresentationFixture.action)
            let p=try XCTUnwrap(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:result,current:result.state))
            XCTAssertEqual(p.captures,[CapturedPiece(at:Point(2,2),piece:Piece(owner.opponent,.commander))])
            XCTAssertNil(result.state.board[Point(2,2)]);XCTAssertEqual(result.state.winner,owner)
            XCTAssertTrue(p.sounds.contains {.init("capture",at:0.68)==$0})
            XCTAssertTrue(p.sounds.contains {.init("victory",at:1.02)==$0})
        }
    }
    func testPreviewFailedStaleAndForgedPlacementReceiptRejected() throws {
        let before=try WarriorPresentationFixture.state(),outcome=GameEngine.apply(before,WarriorPresentationFixture.action)
        XCTAssertNil(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:outcome,current:before))
        let failed=GameEngine.apply(before,.castBastion(Point(2,3),Point(2,3)))
        XCTAssertFalse(failed.success)
        XCTAssertNil(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:failed,current:failed.state))
        for action in [GameAction.castBastion(Point(-1,3),Point(4,3)),.placeSoldier(Point(2,3)),.castBastion(Point(2,3),Point(3,2))] {
            XCTAssertNil(WarriorPresentationPlan.make(before:before,action:action,outcome:outcome,current:outcome.state))
        }
        let variants:[[ActionEvent]]=[[],[.piecePlaced(.one,Point(2,3),.soldier)],[.piecePlaced(.two,Point(2,3),.soldier),.piecePlaced(.two,Point(4,3),.soldier)]]
        for events in variants {
            let typed:[ActionEvent]=events
            let forged=ActionOutcome(state:outcome.state,events:typed,reason:.none)
            XCTAssertNil(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:forged,current:forged.state))
        }
    }
    func testSecondAPLastAPAndUndoDoNotDependOnAnimation() throws {
        var session=GameSession(try WarriorPresentationFixture.state())
        let before=session.state,result=session.apply(WarriorPresentationFixture.action)
        let p=try XCTUnwrap(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:result,current:session.state))
        XCTAssertTrue(session.apply(.placeSoldier(Point(0,2))).success)
        XCTAssertEqual(session.state.current,.two);XCTAssertEqual(session.state.apRemaining,2)
        XCTAssertNil(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:result,current:session.state))
        XCTAssertTrue(session.undo());XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
        XCTAssertEqual(p.after,result.state)
        let last=try WarriorPresentationFixture.state(owner:.two,ap:1),end=GameEngine.apply(last,WarriorPresentationFixture.action)
        let final=try XCTUnwrap(WarriorPresentationPlan.make(before:last,action:WarriorPresentationFixture.action,outcome:end,current:end.state))
        XCTAssertEqual(final.caster,.two);XCTAssertEqual(end.state.current,.one);XCTAssertEqual(end.state.apRemaining,2)
        // The existing audio catalog has no turn.wav; turn state must update
        // without scheduling an invented sound resource.
        XCTAssertFalse(final.sounds.contains {$0.key=="turn"})
    }
    func testHandAuthoredContactAndRecoveryContract() throws {
        // Oracle is WARRIOR-07 plan: both pawns touch ground at .58, then recoil.
        XCTAssertEqual(WarriorBodyPose.skill(at:0.20).shieldY,-88)
        XCTAssertEqual(WarriorBodyPose.skill(at:0.58).shieldY,34)
        XCTAssertLessThan(WarriorBodyPose.skill(at:0.65).shieldY,34)
        XCTAssertEqual(WarriorBodyPose.skill(at:0.92).body,0)
        XCTAssertNotEqual(WarriorBodyPose.skill(at:0.92).cloth,0)
        for t in [-1,1.02,2,Double.nan,Double.infinity] {XCTAssertEqual(WarriorBodyPose.skill(at:t),.rest)}
        XCTAssertEqual(WarriorBodyPose.skill(at:0.58,reduced:true),.rest)
        let before=try WarriorPresentationFixture.state(),outcome=GameEngine.apply(before,WarriorPresentationFixture.action)
        let a=try XCTUnwrap(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:outcome,current:outcome.state,original:true))
        let b=try XCTUnwrap(WarriorPresentationPlan.make(before:before,action:WarriorPresentationFixture.action,outcome:outcome,current:outcome.state))
        XCTAssertEqual(a.after,b.after);XCTAssertEqual(a.pose(at:0.20),.rest)
        XCTAssertEqual(a.arrival,0.39);XCTAssertEqual(b.arrival,0.58)
        XCTAssertEqual(Array(b.sounds.prefix(3)),[.init("w7-brace",at:0.20),.init("w7-strike",at:0.58),.init("w7-land",at:0.58)])
    }
    func testShieldProjectionFollowsSummonContactWithoutLingeringBuff() {
        // Owner asks for a tangible skill effect: forge, deploy, hit and fade.
        XCTAssertEqual(WarriorBastionEffectFrame.sample(at:0.20).phase,.forge)
        XCTAssertEqual(WarriorBastionEffectFrame.sample(at:0.34).phase,.deploy)
        XCTAssertLessThan(WarriorBastionEffectFrame.sample(at:0.57).travel,1)
        let hit=WarriorBastionEffectFrame.sample(at:0.58)
        XCTAssertEqual(hit.phase,.impact);XCTAssertEqual(hit.travel,1);XCTAssertEqual(hit.lift,0);XCTAssertEqual(hit.impact,1)
        XCTAssertEqual(WarriorBastionEffectFrame.sample(at:0.80).phase,.dissolve)
        for t in [-1,0,0.98,1.02,Double.nan,Double.infinity] {XCTAssertEqual(WarriorBastionEffectFrame.sample(at:t).alpha,0)}
        XCTAssertEqual(WarriorBastionEffectFrame.sample(at:0.58,reduced:true).alpha,0)
    }
}
