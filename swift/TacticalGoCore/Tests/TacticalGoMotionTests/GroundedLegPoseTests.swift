import Foundation
import XCTest
@testable import TacticalGoMotion

final class GroundedLegPoseTests: XCTestCase {
    func testForwardKinematicsKeepsPlantedAnkleAndFlatFoot() {
        for pitch in [-0.4, -0.24, 0, 0.24, 0.4] {
            for depth in [0.0, 0.018, 0.07, 0.12] {
                let pose = GroundedLegPose(depth: depth, rootPitch: pitch)
                // Independent FK from the authored rest skeleton dimensions.
                // Rotate each downward limb, then the resulting chain by root.
                let localY = 0.35 - 0.12 * cos(pose.hip) - 0.12 * cos(pose.hip + pose.knee)
                let localZ = -0.12 * sin(pose.hip) - 0.12 * sin(pose.hip + pose.knee)
                let worldY = localY * cos(pose.rootPitch) - localZ * sin(pose.rootPitch) - pose.depth
                let worldZ = localY * sin(pose.rootPitch) + localZ * cos(pose.rootPitch)
                XCTAssertEqual(worldY, 0.11, accuracy: 1e-12)
                XCTAssertEqual(worldZ, 0, accuracy: 1e-12)
                XCTAssertEqual(pose.rootPitch + pose.hip + pose.knee + pose.ankle, 0, accuracy: 1e-12)
            }
        }
    }
    func testRestAndRejectedNonFiniteOrExcessiveParametersStayBounded() {
        let rest = GroundedLegPose(depth: 0)
        XCTAssertEqual(rest.depth, 0); XCTAssertEqual(rest.hip, 0, accuracy: 1e-7)
        XCTAssertEqual(rest.knee, 0, accuracy: 1e-7); XCTAssertEqual(rest.ankle, 0, accuracy: 1e-7)
        XCTAssertEqual(GroundedLegPose(depth: -.infinity, rootPitch: .nan), rest)
        XCTAssertEqual(GroundedLegPose(depth: -10, rootPitch: .infinity), rest)
        let deep = GroundedLegPose(depth: 99, rootPitch: 99)
        XCTAssertEqual(deep.depth, 0.12); XCTAssertEqual(deep.rootPitch, 0.4)
        XCTAssertTrue(deep.hip.isFinite && deep.knee.isFinite && deep.ankle.isFinite)
        XCTAssertGreaterThan(GroundedLegPose(depth: 0, rootPitch: 0.4).depth, 0)
    }
}
