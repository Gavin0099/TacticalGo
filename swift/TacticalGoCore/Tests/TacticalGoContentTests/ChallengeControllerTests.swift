import Foundation
import XCTest
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

final class ChallengeControllerTests: XCTestCase {
    func testAllSixSolutionsLockImmediatelyAndCannotSubmitAfterHandover() throws {
        for scenario in try TutorialCatalog.all() {
            var c = try ChallengeController(); try c.choose(scenario.id)
            XCTAssertTrue(c.visibleHints.isEmpty)
            XCTAssertFalse(c.locked)
            XCTAssertFalse(c.session!.state.config.experimentalFriendlyRedeploy)
            for action in scenario.canonicalSolution {
                let before = c.session!.state
                let preview = try XCTUnwrap(c.preview(action))
                XCTAssertEqual(c.session!.state, before)
                XCTAssertEqual(try c.commit(action), preview)
            }
            XCTAssertEqual(c.assessment, .completed, scenario.id)
            XCTAssertTrue(c.locked)
            let state = c.session!.state, progress = c.progress
            XCTAssertNil(c.preview(.endTurn))
            XCTAssertThrowsError(try c.commit(.endTurn))
            XCTAssertEqual(c.session!.state, state); XCTAssertEqual(c.progress, progress)
            XCTAssertTrue(c.completedIDs.contains(scenario.id))
            try c.retry(); XCTAssertFalse(c.locked); XCTAssertTrue(c.completedIDs.contains(scenario.id))
        }
    }
    func testEveryAlternateAndFailedBranchStopsAtTheAssessmentBoundary() throws {
        for scenario in try TutorialCatalog.all() {
            for branch in scenario.branches where ["solution", "alternate-correct", "player-error", "wrong-outcome"].contains(branch.name) {
                var c = try ChallengeController(); try c.choose(scenario.id)
                for action in branch.actions {
                    if c.locked { break }
                    XCTAssertTrue(try c.commit(action).success, scenario.id + branch.name)
                }
                XCTAssertEqual(c.assessment?.label, branch.expected)
                XCTAssertTrue(c.locked)
                XCTAssertThrowsError(try c.commit(.endTurn))
            }
        }
    }
    func testUndoRebuildsFullCoreHistoryResourcesAndSkillProgress() throws {
        for scenario in try TutorialCatalog.all() {
            var c = try ChallengeController(); try c.choose(scenario.id)
            let initial = c.session!.state
            _ = try c.commit(scenario.canonicalSolution[0])
            let one = c.session!.state
            _ = try c.commit(scenario.canonicalSolution[1])
            XCTAssertEqual(c.assessment, .completed)
            XCTAssertTrue(try c.undo()); XCTAssertEqual(c.session!.state, one); XCTAssertFalse(c.locked)
            XCTAssertTrue(try c.undo()); XCTAssertEqual(c.session!.state, initial)
            XCTAssertFalse(try c.undo())
            for action in scenario.canonicalSolution { _ = try c.commit(action) }
            XCTAssertEqual(c.assessment, .completed)
        }
    }
    func testIllegalSelectionAndCandidateActionDoNotChangeJournalOrSpend() throws {
        var c = try ChallengeController(); try c.choose("warrior-rescue")
        let before = c.session!.state, progress = c.progress
        let hero = try XCTUnwrap(before.board.find(.one, .hero))
        let occupied = try c.commit(.placeSoldier(hero))
        XCTAssertFalse(occupied.success); XCTAssertTrue(occupied.events.isEmpty)
        let candidate = try c.commit(.castFriendlyRedeploy(Point(1,2), Point(6,6)))
        XCTAssertFalse(candidate.success)
        XCTAssertEqual(c.session!.state, before); XCTAssertEqual(c.progress, progress)
    }
    func testIndependentPersistenceResumeHintsAndCompletionReceipts() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let formal = root.appendingPathComponent("formal.json"), onboard = root.appendingPathComponent("onboard.json")
        let sentinel = Data("other-save-unchanged".utf8); try sentinel.write(to: formal); try sentinel.write(to: onboard)
        let repo = ChallengeRepository(directory: root.appendingPathComponent("Challenges"))
        var c = try ChallengeController(); try c.choose("rogue-finish")
        XCTAssertTrue(c.revealHint()); _ = try c.commit(c.scenario!.canonicalSolution[0]); try repo.save(c.progress)
        var loaded = try repo.load(); XCTAssertEqual(loaded.session!.state, c.session!.state); XCTAssertEqual(loaded.visibleHints.count, 1)
        _ = try loaded.commit(loaded.scenario!.canonicalSolution[1]); try repo.save(loaded.progress)
        loaded = try repo.load(); XCTAssertEqual(loaded.assessment, .completed); XCTAssertTrue(loaded.locked)
        try loaded.retry(); XCTAssertTrue(loaded.completedIDs.contains("rogue-finish")); loaded.leave(); try repo.save(loaded.progress)
        loaded = try repo.load(); XCTAssertNil(loaded.session); try loaded.choose("rogue-finish"); XCTAssertFalse(loaded.locked)
        XCTAssertEqual(try Data(contentsOf: formal), sentinel); XCTAssertEqual(try Data(contentsOf: onboard), sentinel)
    }
    func testCorruptUnknownForgedAndPostCompletionJournalsPreserveOriginalFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repo = ChallengeRepository(directory: root)
        var c = try ChallengeController(); try c.choose("rogue-finish"); try repo.save(c.progress)
        let original = try Data(contentsOf: repo.file)
        var bad = c.progress; bad.version = 2
        XCTAssertThrowsError(try repo.save(bad))
        bad = c.progress; bad.selectedID = "unknown"; XCTAssertThrowsError(try repo.save(bad))
        bad = c.progress; bad.completed["rogue-finish"] = []; XCTAssertThrowsError(try repo.save(bad))
        for action in c.scenario!.canonicalSolution { _ = try c.commit(action) }
        bad = c.progress; bad.runs["rogue-finish"]!.append(RecordedAction(.endTurn)); XCTAssertThrowsError(try repo.save(bad))
        XCTAssertEqual(try Data(contentsOf: repo.file), original)
        let corrupt = Data("broken".utf8); try corrupt.write(to: repo.file)
        XCTAssertThrowsError(try repo.load()); XCTAssertEqual(try Data(contentsOf: repo.file), corrupt)
    }
}
