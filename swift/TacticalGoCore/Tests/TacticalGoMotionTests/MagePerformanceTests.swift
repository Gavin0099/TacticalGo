import XCTest
import TacticalGoCore
import TacticalGoMotion

final class MagePerformanceTests: XCTestCase {
    func testSoldierWaitsForCastingPoseThenArrivesAtLandingCue() throws {
        for tempo in MageTempo.allCases {
            let before = try Anim01Fixture.state(capture:false)
            let result = GameEngine.apply(before,Anim01Fixture.action)
            let clip = try XCTUnwrap(Anim01MagicHand.make(before:before,action:Anim01Fixture.action,outcome:result,tempo:tempo))
            let t = clip.timing
            XCTAssertLessThan(t.release,t.moveStart)
            XCTAssertEqual(clip.progress(at:t.release),0)
            XCTAssertEqual(clip.progress(at:t.moveStart),0)
            XCTAssertEqual(clip.progress(at:(t.moveStart+t.arrival)/2),0.5,accuracy:1e-8)
            XCTAssertEqual(clip.progress(at:t.arrival),1,accuracy:1e-8)
            let pose = MageBodyPose.cast(at:t.release,timing:t)
            XCTAssertGreaterThan(pose.shoulder,12)
            XCTAssertLessThan(MageBodyPose.cast(at:t.anticipationEnd,timing:t).shoulder,-8)
            let cues = CombatFeedbackPlan.anim01(before:before,action:Anim01Fixture.action,outcome:result,tempo:tempo).cues
            XCTAssertEqual(cues,[.init("mage",at:t.release),.init("place",at:t.arrival)])
            XCTAssertEqual(MageBodyPose.cast(at:clip.duration,timing:t),.rest)
            XCTAssertEqual(result.state.apRemaining,1)
            XCTAssertEqual(result.state.mana(of:before.current),2)
        }
    }
    func testActualCaptureAndVictoryShareTimelineAndPayload() throws {
        for tempo in MageTempo.allCases {
            for owner in Player.allCases {
                let before = try Anim01Fixture.state(caster:owner,pushedOwner:owner)
                let outcome = GameEngine.apply(before,Anim01Fixture.action)
                let clip = try XCTUnwrap(Anim01MagicHand.make(before:before,action:Anim01Fixture.action,outcome:outcome,tempo:tempo))
                XCTAssertEqual(clip.captures.count,1)
                XCTAssertEqual(clip.captures.first?.at,Point(3,2))
                XCTAssertEqual(clip.captures.first?.piece,Piece(owner.opponent,.commander))
                let cues = CombatFeedbackPlan.anim01(before:before,action:Anim01Fixture.action,outcome:outcome,tempo:tempo).cues
                XCTAssertEqual(cues,[.init("mage",at:clip.timing.release),.init("place",at:clip.timing.arrival),.init("capture",at:clip.timing.captureStart),.init("victory",at:clip.duration)])
                XCTAssertGreaterThanOrEqual(clip.duration,clip.timing.captureEnd)
                XCTAssertEqual(clip.winner,owner)
            }
        }
    }
    func testReducedMotionAndExpiredTimeRestoreExactNeutralPose() {
        for tempo in MageTempo.allCases {
            let t = tempo.timing
            for time in [-10.0,0,t.anticipationEnd,t.release,t.arrival,t.recoveryEnd,100] {
                XCTAssertEqual(MageBodyPose.cast(at:time,timing:t,reduced:true),.rest)
                XCTAssertEqual(MageBodyPose.summon(at:time,timing:t,reduced:true),.rest)
            }
            XCTAssertEqual(MageBodyPose.summon(at:t.summonEnd,timing:t),.rest)
            XCTAssertEqual(MageBodyPose.cast(at:t.recoveryEnd,timing:t),.rest)
        }
    }
    func testPoseIsContinuousAcrossKeyFramesAndBoundedForBoardCells() {
        for tempo in MageTempo.allCases {
            let t = tempo.timing
            for boundary in [t.anticipationEnd,t.release,t.arrival,t.recoveryEnd-0.10,t.recoveryEnd] {
                let a = MageBodyPose.cast(at:boundary-0.00001,timing:t,revision:.m2),b = MageBodyPose.cast(at:boundary+0.00001,timing:t,revision:.m2)
                XCTAssertLessThan(abs(a.shoulder-b.shoulder),0.01)
                XCTAssertLessThan(abs(a.cape-b.cape),0.01)
                XCTAssertLessThan(abs(a.torsoY-b.torsoY),0.01)
            }
            for n in 0...100 {
                let pose = MageBodyPose.cast(at:Double(n)*t.recoveryEnd/100,timing:t,revision:.m2)
                XCTAssertLessThanOrEqual(abs(pose.shoulder),24)
                XCTAssertLessThanOrEqual(abs(pose.torso),2)
                XCTAssertLessThanOrEqual(abs(pose.head),2)
                XCTAssertLessThanOrEqual(abs(pose.torsoY),7)
            }
        }
    }
    func testDenseNineBoardHasLiveGroupsAndRealSkill() throws {
        for owner in Player.allCases {
            let state = try Anim01Fixture.denseState(caster: owner)
            XCTAssertGreaterThan(state.board.points.filter { state.board[$0] != nil }.count,35)
            for point in state.board.points where state.board[point] != nil { XCTAssertFalse(state.board.liberties(at:point).isEmpty) }
            let result = GameEngine.apply(state,Anim01Fixture.action)
            XCTAssertTrue(result.success)
            XCTAssertEqual(result.state.board[Point(4,2)],Piece(owner,.soldier))
            XCTAssertNil(result.state.board[Point(4,3)])
            XCTAssertNotNil(Anim01MagicHand.make(before:state,action:Anim01Fixture.action,outcome:result))
        }
    }
    func testSummonHasSeparateGroundingAndDelayedCape() {
        let t = MageTempo.full.timing
        let early = MageBodyPose.summon(at:0,timing:t)
        let ground = MageBodyPose.summon(at:t.summonEnd*0.38,timing:t)
        let late = MageBodyPose.summon(at:t.summonEnd*0.72,timing:t)
        XCTAssertEqual(early.opacity,0)
        XCTAssertLessThan(early.lift,0)
        XCTAssertEqual(ground.lift,0,accuracy:1e-8)
        XCTAssertGreaterThan(ground.torsoY,0)
        XCTAssertEqual(late.torsoY,0,accuracy:1e-8)
        XCTAssertNotEqual(late.cape,0)
        XCTAssertEqual(MageBodyPose.summon(at:t.summonEnd,timing:t),.rest)
    }
    func testM3WeightShiftIsVisibleAtActualCellScaleWithoutChangingClock() {
        for tempo in MageTempo.allCases {
            let timing = tempo.timing
            let anticipation = MageBodyPose.cast(at:timing.anticipationEnd,timing:timing)
            let release = MageBodyPose.cast(at:timing.release,timing:timing)
            // Reviewed design bound: a 46.56pt board cell must have at least
            // 5pt of body travel; no whole-token scale participates.
            XCTAssertGreaterThan((anticipation.torsoX-release.torsoX)*0.92*46.56/512,5)
            XCTAssertLessThanOrEqual(abs(anticipation.torsoX),45)
            XCTAssertLessThanOrEqual(abs(release.torsoX),45)
            XCTAssertLessThanOrEqual(abs(release.shoulder+release.elbow),25)
            XCTAssertLessThan(release.heldX,0) // held pixels offset away from face
            XCTAssertEqual(MageBodyPose.cast(at:timing.recoveryEnd,timing:timing),.rest)
            XCTAssertEqual(tempo == .full ? 0.95 : 0.76,timing.recoveryEnd)
            for boundary in [timing.anticipationEnd,timing.release,timing.arrival,timing.recoveryEnd] {
                let a = MageBodyPose.cast(at:boundary-0.00001,timing:timing)
                let b = MageBodyPose.cast(at:boundary+0.00001,timing:timing)
                XCTAssertLessThan(abs(a.torsoX-b.torsoX),0.02)
                XCTAssertLessThan(abs(a.heldX-b.heldX),0.02)
                XCTAssertLessThan(abs(a.cape-b.cape),0.02)
            }
        }
    }
    func testM2ReferenceAndM3UseSameDomainOutcomeAndReducedBoundary() throws {
        let before = try Anim01Fixture.state(capture:false)
        let result = GameEngine.apply(before,Anim01Fixture.action)
        let timing = MageTempo.full.timing
        let m2 = MageBodyPose.cast(at:timing.release,timing:timing,revision:.m2)
        let m3 = MageBodyPose.cast(at:timing.release,timing:timing,revision:.m3)
        XCTAssertEqual(m2.torsoX,0)
        XCTAssertNotEqual(m2,m3)
        for revision in MageArtRevision.allCases {
            XCTAssertEqual(MageBodyPose.cast(at:timing.release,timing:timing,reduced:true,revision:revision),.rest)
            XCTAssertEqual(MageBodyPose.summon(at:timing.summonEnd,timing:timing,revision:revision),.rest)
        }
        XCTAssertEqual(result.state.apRemaining,1)
        XCTAssertEqual(result.state.mana(of:.one),2)
        XCTAssertEqual(result.state.board[Point(4,2)],Piece(.one,.soldier))
    }

}
