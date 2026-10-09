import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class MotionPlanTests: XCTestCase {
    func testCapeFollowThroughHasDelayedPeakAndSettlesWithoutInwardSwing() {
        for t in [-1.0, 0, 0.25, 1, 2] { XCTAssertEqual(MotionCurves.capeFollowThrough(t), 0) }
        XCTAssertEqual(MotionCurves.capeFollowThrough(0.70), 1)
        XCTAssertEqual(MotionCurves.capeFollowThrough(0.475), 0.5, accuracy: 0.000001)
        XCTAssertEqual(MotionCurves.capeFollowThrough(0.85), 0.5, accuracy: 0.000001)
        XCTAssertEqual(MotionCurves.capeFollowThrough(0.835, lateImpact: true), 1, accuracy: 0.000001)
        for t in [-1.0, 0, 0.5875, 1, 2] { XCTAssertEqual(MotionCurves.capeFollowThrough(t, lateImpact: true), 0, accuracy: 0.000001) }
        for i in 0...1000 {
            let value = MotionCurves.capeFollowThrough(Double(i) / 1000)
            XCTAssertTrue((0...1).contains(value))
            XCTAssertTrue((0...1).contains(MotionCurves.capeFollowThrough(Double(i) / 1000, lateImpact: true)))
        }
    }
    private func setup(_ diagram: String, one: HeroClass = .warrior, two: HeroClass = .mage) throws -> GameState {
        try GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram, classOne: one, classTwo: two, manaOne: 6, manaTwo: 6, ap: 2)
    }
    func testIllegalActionAndReducedMotionNeverProducePlayback() throws {
        let state = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let occupied = Point(3, 5), action = GameAction.placeSoldier(occupied)
        let result = GameEngine.apply(state, action)
        XCTAssertEqual(result.reason, .occupied)
        XCTAssertEqual(MotionPlan.make(before: state, action: action, outcome: result), .empty)
        let legal = GameAction.placeSoldier(Point(4, 4)), success = GameEngine.apply(state, legal)
        XCTAssertTrue(success.success)
        XCTAssertEqual(MotionPlan.make(before: state, action: legal, outcome: success, reducedMotion: true), .empty)
    }
    func testBastionHasOneWindupAndTwoSynchronizedDrops() throws {
        let state = try setup(".......\n...O...\n.......\n...H...\n.......\n...X...\n.......")
        let action = GameAction.castBastion(Point(2, 3), Point(4, 3)), outcome = GameEngine.apply(state, action)
        XCTAssertTrue(outcome.success)
        let plan = MotionPlan.make(before: state, action: action, outcome: outcome)
        XCTAssertEqual(plan.cues.filter { $0.kind == .bastion }.count, 1)
        let drops = plan.cues.filter { $0.kind == .drop(.soldier) }
        XCTAssertEqual(Set(drops.flatMap(\.points)), Set([Point(2, 3), Point(4, 3)]))
        XCTAssertEqual(drops.map(\.start), [0.18, 0.18])
        XCTAssertEqual(plan.duration, 0.48, accuracy: 0.0001)
        XCTAssertEqual(outcome.state.mana(of: .one), 4)
    }
    func testCaptureAndWinFollowLandingWithoutInventingPieces() throws {
        let state = try setup(".......\n...o...\n..oXo..\n.......\n.......\n...O...\n.......")
        // One cannot capture its own commander. Explicit target source is the opponent fixture.
        let action = GameAction.placeSoldier(Point(3, 4)), outcome = GameEngine.apply(state, action)
        let plan = MotionPlan.make(before: state, action: action, outcome: outcome)
        XCTAssertTrue(outcome.success)
        XCTAssertEqual(plan.cues.filter { if case .capture = $0.kind { return true }; return false }.count, 0)
        XCTAssertEqual(plan.cues.filter { if case .win = $0.kind { return true }; return false }.count, 0)
        // A surrounded enemy commander with one empty liberty is independent rule evidence.
        let winState = try setup(".......\n...x...\n..xOx..\n.......\n.......\n...X...\n.......")
        let winAction = GameAction.placeSoldier(Point(3, 3)), win = GameEngine.apply(winState, winAction)
        XCTAssertEqual(win.state.status, .won)
        let winPlan = MotionPlan.make(before: winState, action: winAction, outcome: win)
        XCTAssertTrue(winPlan.cues.contains(MotionCue(.capture(Piece(.two, .commander)), [Point(3, 2)], start: 0.30, duration: 0.28)))
        let victory = try XCTUnwrap(winPlan.cues.first { $0.kind == .win(.one) })
        XCTAssertEqual(victory.start, 0.58, accuracy: 0.000001)
        XCTAssertEqual(victory.duration, 0.58, accuracy: 0.000001)
    }
    func testCurveEndpointsAndOutOfRangeValuesSettleExactly() {
        XCTAssertEqual(MotionCurves.dropHeight(-2), 1.2)
        XCTAssertEqual(MotionCurves.dropHeight(1), 0)
        XCTAssertEqual(MotionCurves.squash(0), 1)
        XCTAssertEqual(MotionCurves.squash(1), 1)
        XCTAssertEqual(MotionCurves.swapProgress(-1), 0)
        XCTAssertEqual(MotionCurves.swapProgress(2), 1)
        XCTAssertEqual(MotionCurves.anticipation(0), 0)
        XCTAssertEqual(MotionCurves.anticipation(1), 0)
        XCTAssertEqual(MotionCurves.shieldStrike(0), 0)
        XCTAssertEqual(MotionCurves.shieldStrike(1), 0)
        XCTAssertEqual(MotionCurves.shieldStrike(0.18 / 0.48), -0.16, accuracy: 0.000001)
        XCTAssertEqual(MotionCurves.shieldStrike(0.39 / 0.48), 0.24, accuracy: 0.000001)
        for i in 0...100 { XCTAssertGreaterThanOrEqual(MotionCurves.dropHeight(Double(i)/100), 0) }
    }
    func testAllReviewPositionsAreLegalAndMatchIndependentStoryBeats() throws {
        for example in MotionExample.allCases {
            let before = try example.initialState(), result = GameEngine.apply(before, example.action)
            XCTAssertTrue(result.success, example.rawValue)
            let plan = MotionPlan.make(before: before, action: example.action, outcome: result)
            XCTAssertGreaterThan(plan.duration, 0)
            switch example {
            case .drop: XCTAssertEqual(result.state.board[Point(4, 3)], Piece(.one, .soldier))
            case .summon: XCTAssertEqual(result.state.board[Point(3, 4)], Piece(.one, .hero))
            case .capture:
                XCTAssertNil(result.state.board[Point(3, 2)])
                XCTAssertTrue(plan.cues.contains { $0.kind == .capture(Piece(.two, .soldier)) && $0.points == [Point(3, 2)] })
            case .bastion:
                XCTAssertEqual(result.state.board[Point(2, 3)], Piece(.one, .soldier))
                XCTAssertEqual(result.state.board[Point(4, 3)], Piece(.one, .soldier))
            case .seal:
                XCTAssertTrue(result.state.isSealed(Point(4, 3), for: .two))
                XCTAssertTrue(plan.cues.contains { $0.kind == .seal && $0.points == [Point(3, 3), Point(4, 3)] })
            case .swap:
                XCTAssertEqual(result.state.board[Point(4, 3)], Piece(.one, .hero))
                XCTAssertEqual(result.state.board[Point(3, 3)], Piece(.two, .soldier))
                XCTAssertTrue(plan.cues.contains { $0.kind == .swap && $0.points == [Point(3, 3), Point(4, 3)] })
            case .victory: XCTAssertEqual(result.state.winner, .one)
            case .expire:
                XCTAssertTrue(before.isSealed(Point(4, 3), for: .two))
                XCTAssertEqual(before.current, .two)
                XCTAssertFalse(result.state.isSealed(Point(4, 3), for: .two))
                XCTAssertEqual(result.state.current, .one)
                XCTAssertTrue(plan.cues.contains(MotionCue(.sealExpired, [Point(4, 3)], start: 0, duration: 0.22)))
            }
        }
    }
    func testDrawWaitsForTheFinalPlacementAndRejectsFurtherPlayback() throws {
        var config = RuleConfig.board(size: 7); config.maxPlies = 2
        let before = try GameSetup.fromDiagram(config: config,
            diagram: ".......\n...O...\n.......\n.......\n.......\n...X...\n.......",
            classOne: .warrior, classTwo: .mage, ap: 1, ply: 2)
        let action = GameAction.placeSoldier(Point(4, 3)), result = GameEngine.apply(before, action)
        XCTAssertTrue(result.success); XCTAssertEqual(result.state.status, .drawn)
        XCTAssertNil(result.state.winner)
        let plan = MotionPlan.make(before: before, action: action, outcome: result)
        XCTAssertTrue(plan.cues.contains(MotionCue(.drop(.soldier), [Point(4, 3)], start: 0, duration: 0.30)))
        XCTAssertTrue(plan.cues.contains(MotionCue(.draw, start: 0.30, duration: 0.28)))
        XCTAssertEqual(plan.duration, 0.58, accuracy: 0.000001)
        XCTAssertFalse(plan.cues.contains { if case .win = $0.kind { return true }; return false })
        let rejected = GameEngine.apply(result.state, .endTurn)
        XCTAssertEqual(rejected.reason, .gameOver)
        XCTAssertEqual(MotionPlan.make(before: result.state, action: .endTurn, outcome: rejected), .empty)
        XCTAssertEqual(MotionPlan.make(before: before, action: action, outcome: result, reducedMotion: true), .empty)
    }
    func testExplicitLastTurnDrawHasNoNewPlayerPulse() throws {
        var config = RuleConfig.board(size: 7); config.maxPlies = 2
        let before = try GameSetup.fromDiagram(config: config,
            diagram: ".......\n...O...\n.......\n.......\n.......\n...X...\n.......",
            classOne: .warrior, classTwo: .mage, ap: 2, ply: 2)
        let result = GameEngine.apply(before, .endTurn)
        XCTAssertEqual(result.state.status, .drawn)
        XCTAssertEqual(result.state.current, before.current)
        XCTAssertEqual(result.state.mana(of: .two), before.mana(of: .two))
        XCTAssertEqual(MotionPlan.make(before: before, action: .endTurn, outcome: result).cues,
                       [MotionCue(.draw, start: 0, duration: 0.28)])
    }
    func testCommanderCaptureAtTurnLimitStillShowsVictory() throws {
        var config = RuleConfig.board(size: 7); config.maxPlies = 2
        let before = try GameSetup.fromDiagram(config: config,
            diagram: ".......\n...x...\n..xOx..\n.......\n.......\n...X...\n.......",
            classOne: .warrior, classTwo: .mage, ap: 1, ply: 2)
        let action = GameAction.placeSoldier(Point(3, 3)), result = GameEngine.apply(before, action)
        XCTAssertEqual(result.state.status, .won); XCTAssertEqual(result.state.winner, .one)
        let plan = MotionPlan.make(before: before, action: action, outcome: result)
        XCTAssertTrue(plan.cues.contains { $0.kind == .win(.one) })
        XCTAssertFalse(plan.cues.contains { $0.kind == .draw })
    }

}
