import XCTest
import TacticalGoCore
import TacticalGoBot

final class SearchTraceTests: XCTestCase {
    private func position() throws -> GameState {
        try GameSetup.fromDiagram(config: .board(size: 7), diagram: ".......\n...O...\n.......\n.......\n.......\n...X...\n.......", classOne: .warrior, classTwo: .mage, manaOne: 6, manaTwo: 6, ap: 2, ply: 3)
    }
    func testTracingPreservesDecisionsScoresReasonsAndWorkForBothDifficulties() throws {
        for difficulty in BotDifficulty.allCases {
            let state = try position()
            let plain = try XCTUnwrap(BotPlanner.planTurn(state, difficulty: difficulty))
            let traced = try XCTUnwrap(BotPlanner.planTurn(state, difficulty: difficulty, diagnostics: true))
            XCTAssertEqual(plain.actions, traced.actions)
            XCTAssertEqual(plain.score, traced.score)
            XCTAssertEqual(plain.reasons, traced.reasons)
            XCTAssertEqual(plain.stats.domainTransitions, traced.stats.domainTransitions)
            XCTAssertEqual(plain.stats.legalEnumerations, traced.stats.legalEnumerations)
            XCTAssertEqual(plain.stats.candidateComparisons, traced.stats.candidateComparisons)
            XCTAssertEqual(plain.stats.ownTurnComparisons, traced.stats.ownTurnComparisons)
            XCTAssertTrue(plain.stats.candidateTrace.isEmpty)
            XCTAssertFalse(traced.stats.candidateTrace.isEmpty)
            let comparison = traced.stats.candidateTrace.filter { $0.stage == "reply-comparison" }
            if difficulty == .standard {
                XCTAssertEqual(comparison.map(\.rank), (1...comparison.count).map { Optional($0) })
                XCTAssertEqual(comparison.filter(\.retained).count, 1)
                XCTAssertEqual(comparison.first?.score, traced.score)
                XCTAssertTrue(comparison.allSatisfy { $0.context == "root" })
            }
            XCTAssertEqual(state.apRemaining, 2)
        }
    }
    func testEveryLayerReportsRetainedAndPrunedCandidatesWithContext() throws {
        let state = try position()
        let limits = BotLimits(maxDomainTransitions: 6_000, ownBeamWidth: 2, replyBeamWidth: 1, replyCandidates: 1)
        let plan = try XCTUnwrap(BotPlanner.planTurn(state, limits: limits, diagnostics: true))
        let rows = plan.stats.candidateTrace
        XCTAssertFalse(plan.stats.budgetExhausted)
        XCTAssertEqual(Set(rows.map(\.stage)), ["own-first", "own-second", "complete-turn", "reply-first", "reply-second", "reply-comparison"])
        let roots = rows.filter { $0.stage == "own-first" }
        XCTAssertEqual(roots.count, GameEngine.legalActions(state).count)
        XCTAssertEqual(roots.map(\.rank), (1...roots.count).map { Optional($0) })
        for stage in ["own-first", "own-second", "complete-turn", "reply-first", "reply-second"] {
            let candidates = rows.filter { $0.stage == stage }
            XCTAssertTrue(candidates.contains { $0.retained }, stage)
            XCTAssertTrue(candidates.contains { !$0.retained }, stage)
            XCTAssertTrue(candidates.allSatisfy { !$0.context.isEmpty && !$0.reason.isEmpty && $0.score != nil }, stage)
        }
        XCTAssertTrue(rows.contains { $0.reason == "outside-complete-turn-reply-cap" })
        XCTAssertEqual(rows.filter { $0.stage == "reply-comparison" }.count, 1)
    }
    func testBudgetInsufficiencyIsNotReportedAsACompleteSearch() throws {
        let state = try position()
        let plan = try XCTUnwrap(BotPlanner.planTurn(state, limits: BotLimits(maxDomainTransitions: 3), diagnostics: true))
        XCTAssertTrue(plan.stats.budgetExhausted)
        XCTAssertTrue(plan.stats.candidateTrace.contains { $0.rank == nil && $0.score == nil && $0.reason == "transition-budget-before-evaluation" })
        var replay = state
        for action in plan.actions {
            let outcome = GameEngine.apply(replay, action); XCTAssertTrue(outcome.success); replay = outcome.state
        }
        XCTAssertNotEqual(replay.current, state.current)
    }
    func testDirectWinTraceDoesNotPretendOtherCandidatesWereSearchedFurther() throws {
        let state = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "xOx....\n.......\n.......\n.......\n.......\n...X...\n.......", ap: 2)
        let plan = try XCTUnwrap(BotPlanner.planTurn(state, diagnostics: true))
        XCTAssertEqual(plan.actions, [.placeSoldier(Point(1, 1))])
        XCTAssertTrue(plan.stats.candidateTrace.contains { $0.retained && $0.reason == "direct-victory" })
        XCTAssertTrue(plan.stats.candidateTrace.contains { !$0.retained && $0.reason == "not-expanded-after-direct-victory" })
        XCTAssertFalse(plan.stats.candidateTrace.contains { $0.stage == "reply-first" })
    }
}
