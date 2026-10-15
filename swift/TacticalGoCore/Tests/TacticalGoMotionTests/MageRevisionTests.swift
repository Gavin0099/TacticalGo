import XCTest
import TacticalGoCore
import TacticalGoMotion

final class MageRevisionTests: XCTestCase {
    func testR1ReleaseRemainsVisibleUntilTheSharedMoveStart() {
        for tempo in MageTempo.allCases {
            let t=tempo.timing
            let released=MageBodyPose.cast(at:t.release,timing:t,revision:.r1)
            for time in [t.release + 0.01,(t.release+t.moveStart)/2,t.moveStart] {
                let hold=MageBodyPose.cast(at:time,timing:t,revision:.r1)
                XCTAssertEqual(hold.shoulder,released.shoulder)
                XCTAssertEqual(hold.elbow,released.elbow)
                XCTAssertEqual(hold.heldX,released.heldX)
                XCTAssertEqual(hold.torsoX,released.torsoX)
            }
            let old=MageBodyPose.cast(at:t.moveStart,timing:t,revision:.m3)
            XCTAssertLessThan(old.shoulder,released.shoulder)
            XCTAssertGreaterThan(old.torsoX,released.torsoX)
            XCTAssertEqual(MageBodyPose.cast(at:t.recoveryEnd,timing:t,revision:.r1),.rest)
        }
    }
    func testR1IsContinuousBoundedAndFinishesBeforeUnlockWithoutChangingTiming() {
        for tempo in MageTempo.allCases {
            let t=tempo.timing
            for boundary in [0,t.anticipationEnd * 0.60,t.anticipationEnd,t.release,t.moveStart,t.arrival,t.recoveryEnd-0.10,t.recoveryEnd] {
                let a=MageBodyPose.cast(at:boundary-0.000001,timing:t,revision:.r1)
                let b=MageBodyPose.cast(at:boundary+0.000001,timing:t,revision:.r1)
                XCTAssertLessThan(abs(a.shoulder-b.shoulder),0.001)
                XCTAssertLessThan(abs(a.torsoX-b.torsoX),0.001)
                XCTAssertLessThan(abs(a.cape-b.cape),0.001)
            }
            for n in 0...240 {
                let pose=MageBodyPose.cast(at:Double(n)*t.recoveryEnd/240,timing:t,revision:.r1)
                XCTAssertLessThanOrEqual(abs(pose.shoulder+pose.elbow),25)
                XCTAssertLessThanOrEqual(abs(pose.torsoX),44)
                XCTAssertEqual(pose.lift,0)
                XCTAssertEqual(pose.opacity,1)
            }
            XCTAssertEqual(t.recoveryEnd,tempo == .full ? 0.95:0.76)
            XCTAssertEqual(t.arrival,tempo == .full ? 0.60:0.48)
        }
    }
    func testReducedMotionIsNeutralAndSummonHandSettlesBeforeCape() {
        for tempo in MageTempo.allCases {
            let t=tempo.timing
            for time in [0,t.anticipationEnd,t.release,t.moveStart,t.arrival,t.recoveryEnd] {
                XCTAssertEqual(MageBodyPose.cast(at:time,timing:t,reduced:true,revision:.r1),.rest)
                XCTAssertEqual(MageBodyPose.summon(at:time,timing:t,reduced:true,revision:.r1),.rest)
            }
            let handStable=MageBodyPose.summon(at:t.summonEnd * 0.82,timing:t,revision:.r1)
            XCTAssertEqual(handStable.shoulder,0,accuracy:0.00001)
            XCTAssertEqual(handStable.heldX,0,accuracy:0.00001)
            XCTAssertNotEqual(handStable.cape,0)
            XCTAssertEqual(MageBodyPose.summon(at:t.summonEnd,timing:t,revision:.r1),.rest)
        }
    }
}
