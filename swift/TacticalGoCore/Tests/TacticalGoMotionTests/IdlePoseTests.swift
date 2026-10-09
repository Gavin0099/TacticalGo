import Foundation
import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class IdlePoseTests: XCTestCase {
    func testHandAuthoredQuarterPhaseAndExactRestSeams() {
        for hero in [HeroClass.warrior, .mage, .rogue] {
            let rest = IdleHeroPose(hero: hero, phase: 0)
            XCTAssertEqual(rest, IdleHeroPose(hero: hero, phase: 1))
            XCTAssertEqual(rest.stance.depth, 0); XCTAssertEqual(rest.head, 0); XCTAssertEqual(rest.cape, 0)
            let quarter = IdleHeroPose(hero: hero, phase: 0.25)
            XCTAssertEqual(quarter.stance.depth, 0.002, accuracy: 1e-12)
            XCTAssertEqual(quarter.stance.rootPitch, 0.006, accuracy: 1e-12)
            XCTAssertEqual(quarter.head, -0.016, accuracy: 1e-12)
        }
        XCTAssertEqual(IdleHeroPose(hero: .warrior, phase: 0.25).leftArm, -0.025, accuracy: 1e-12)
        XCTAssertEqual(IdleHeroPose(hero: .mage, phase: 0.25).rightArm, -0.045, accuracy: 1e-12)
        XCTAssertEqual(IdleHeroPose(hero: .rogue, phase: 0.25).leftArm, 0.035, accuracy: 1e-12)
        XCTAssertEqual(IdleHeroPose(hero: .rogue, phase: 0.25).rightArm, -0.035, accuracy: 1e-12)
    }
    func testIndependentForwardKinematicsKeepsFootFlatThroughWholeCycle() {
        for hero in [HeroClass.warrior, .mage, .rogue] {
            for frame in 0...102 {
                let pose = IdleHeroPose(hero: hero, phase: Double(frame)/102), s = pose.stance
                let y = 0.35 - 0.12*cos(s.hip) - 0.12*cos(s.hip+s.knee)
                let z = -0.12*sin(s.hip) - 0.12*sin(s.hip+s.knee)
                XCTAssertEqual(y*cos(s.rootPitch)-z*sin(s.rootPitch)-s.depth, 0.11, accuracy: 1e-12)
                XCTAssertEqual(y*sin(s.rootPitch)+z*cos(s.rootPitch), 0, accuracy: 1e-12)
                XCTAssertEqual(s.rootPitch+s.hip+s.knee+s.ankle, 0, accuracy: 1e-12)
                XCTAssertLessThanOrEqual(abs(pose.head), 0.016)
                XCTAssertLessThanOrEqual(abs(pose.leftArm), 0.045)
                XCTAssertLessThanOrEqual(abs(pose.rightArm), 0.045)
                XCTAssertLessThanOrEqual(abs(pose.cape), 0.07)
                XCTAssertLessThanOrEqual(s.depth, 0.004000001)
            }
        }
    }
    func testNonFiniteOutOfRangeAndNoHeroRemainAtRest() {
        let rest = IdleHeroPose(hero: .mage, phase: 0)
        for phase in [Double.nan, .infinity, -.infinity, -5, 9] {
            XCTAssertEqual(IdleHeroPose(hero: .mage, phase: phase), rest)
        }
        XCTAssertEqual(IdleHeroPose(hero: .none, phase: 0.4).stance, GroundedLegPose(depth: 0))
        XCTAssertEqual(IdleHeroPose.duration, 3.4)
    }
}
