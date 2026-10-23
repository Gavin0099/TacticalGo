import XCTest
import TacticalGoCore
@testable import P0Metrics

final class MetricsTests: XCTestCase {
    func testModeFilterKeepsLegacyModesAndOtherActions() {
        let push = GameAction.castMagicHand(Point(3,3), .right)
        let redeploy = GameAction.castFriendlyRedeploy(Point(3,3), Point(3,2))
        var config = RuleConfig.board(size: 7)
        config.expansionSkills = true; config.experimentalFriendlyRedeploy = true
        XCTAssertFalse(P0Metrics.isInCurrentMode(push, config: config))
        XCTAssertTrue(P0Metrics.isInCurrentMode(redeploy, config: config))
        XCTAssertTrue(P0Metrics.isInCurrentMode(.placeSoldier(Point(0,0)), config: config))
        config.expansionSkills = false
        XCTAssertTrue(P0Metrics.isInCurrentMode(push, config: config))
        config.experimentalFriendlyRedeploy = false
        XCTAssertTrue(P0Metrics.isInCurrentMode(push, config: config))
    }
    func testOnlyPurePassCounts() {
        XCTAssertTrue(P0Metrics.isPurePass([.endTurn]))
        XCTAssertFalse(P0Metrics.isPurePass([.placeSoldier(Point(0,0)), .endTurn]))
        XCTAssertFalse(P0Metrics.isPurePass([]))
    }
    func testStreakBreaksAfterRealAction() {
        XCTAssertEqual(P0Metrics.longestPassRun([true,true,false,true,true,true,false,true]), 3)
        XCTAssertEqual(P0Metrics.longestPassRun([]), 0)
    }
    func testPriestBasicAndSecondSkillsAreIncluded() {
        XCTAssertTrue(P0Metrics.isBasic(.castOffering(Point(1,1))))
        XCTAssertTrue(P0Metrics.isAdvanced(.castSanctum(sacrifice: Point(1,1), destination: Point(1,2))))
        XCTAssertTrue(P0Metrics.isAdvanced(.castChainSwap(first: Point(1,1), second: Point(1,2))))
        XCTAssertFalse(P0Metrics.isClassSkill(.summonHero(Point(1,1))))
    }
    func testTwoActionOrdersRemainDifferent() {
        let s = GameAction.castSwap(Point(1,1)), p = GameAction.placeSoldier(Point(1,2))
        XCTAssertEqual(P0Metrics.pattern([s,p]), "skill+soldier")
        XCTAssertEqual(P0Metrics.pattern([p,s]), "soldier+skill")
        XCTAssertEqual(P0Metrics.pattern([p,p]), "soldier+soldier")
    }
    func testTruncatedGameIsNeverRelabelledDrawn() {
        XCTAssertEqual(P0Metrics.result(.ongoing), "incomplete")
        XCTAssertEqual(P0Metrics.result(.drawn), "drawn")
        XCTAssertEqual(P0Metrics.result(.won), "won")
    }
}
