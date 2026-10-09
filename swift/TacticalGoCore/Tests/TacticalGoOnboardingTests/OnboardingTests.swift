import XCTest
import Foundation
@testable import TacticalGoCore
@testable import TacticalGoOnboarding

final class OnboardingTests: XCTestCase {
    func session(_ index: Int) throws -> OnboardingSession {
        var s = try OnboardingSession()
        while s.progress.lessonIndex < index {
            let lesson = s.lesson!
            if lesson.id == "breathing" { s.observe(Point(2, 3)) }
            XCTAssertTrue(try s.commit(lesson.recommended).success)
            XCTAssertTrue(s.completed)
            try s.advance()
        }
        return s
    }
    func testEveryFixtureIsOriginalAndEveryExistingGroupHasAir() throws {
        let lessons = try OnboardingLesson.catalog()
        XCTAssertEqual(lessons.map(\.id), ["goal", "place", "breathing", "capture", "rescue"])
        for lesson in lessons {
            let s = try lesson.initialState()
            XCTAssertFalse(s.config.experimentalFriendlyRedeploy)
            XCTAssertEqual(s.config.bastionScope, .heroAdjacent)
            XCTAssertEqual(s.config.magicHandDestination, .emptyOnly)
            XCTAssertEqual(s.heroClass(of: .one), .none)
            for p in s.board.points where s.board[p] != nil { XCTAssertFalse(s.board.liberties(at: p).isEmpty, lesson.id) }
            XCTAssertTrue(GameEngine.apply(s, .placeSoldier(lesson.recommended)).success, lesson.id)
        }
    }
    func testGoalActuallyCapturesCommanderAndWins() throws {
        var s = try session(0)
        let o = try s.commit(Point(3, 2))
        XCTAssertEqual(o.state.status, .won); XCTAssertEqual(o.state.winner, .one)
        XCTAssertEqual(o.state.board[Point(3, 1)], nil)
        XCTAssertEqual(o.state.board[Point(3, 5)], Piece(.one, .commander))
        XCTAssertTrue(o.events.contains(.piecesCaptured(.one, [CapturedPiece(at: Point(3, 1), piece: Piece(.two, .commander))])))
        XCTAssertTrue(o.events.contains(.gameWon(.one))); XCTAssertTrue(s.completed)
    }
    func testFormalOpeningAndAlternateLegalPointUsesFirstTurnContract() throws {
        var s = try session(1)
        XCTAssertEqual(s.state.ply, 1); XCTAssertEqual(s.state.apRemaining, 1)
        let result = try s.commit(Point(4, 5))
        XCTAssertTrue(result.success); XCTAssertTrue(s.completed)
        XCTAssertEqual(s.state.current, .two); XCTAssertEqual(s.state.apRemaining, 2)
        // Reviewed opening contract: initial 3 + first-turn gain 1; ordinary placement costs 0.
        XCTAssertEqual(s.state.mana(of: .one), 4); XCTAssertEqual(s.state.mana(of: .two), 4)
        XCTAssertTrue(result.events.contains(.resourcesSpent(.one, ap: 1, mana: 0)))
    }
    func testHandReviewedSharedSixLibertiesThenEight() throws {
        var s = try session(2)
        let inspection = GroupInspection.read(s.state, at: Point(2, 3))!
        XCTAssertEqual(inspection.group, [Point(2, 3), Point(3, 3)])
        XCTAssertEqual(inspection.liberties, [Point(2, 2), Point(3, 2), Point(1, 3), Point(4, 3), Point(2, 4), Point(3, 4)])
        s.observe(Point(3, 3)); XCTAssertTrue(try s.commit(Point(4, 3)).success)
        XCTAssertEqual(GroupInspection.read(s.state, at: Point(2, 3))!.liberties.count, 8)
        XCTAssertTrue(s.completed)
    }
    func testBreathingRequiresObservationAndAcceptsAlternateConnection() throws {
        var s = try session(2); let before = s.state
        XCTAssertThrowsError(try s.commit(Point(4, 3)))
        XCTAssertEqual(s.state, before)
        s.observe(Point(3, 5)) // Commander is a different group; does not meet the learning step.
        XCTAssertNil(s.progress.observed[2])
        s.observe(Point(2, 3))
        XCTAssertTrue(try s.commit(Point(2, 4)).success)
        XCTAssertTrue(s.completed)
        XCTAssertEqual(s.state.board.group(at: Point(2, 3)).count, 3)
    }
    func testCornerEdgeAndDiagonalAreCoreQueries() throws {
        let s = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "x......\n.x.....\nx......\n.......\n.......\n.......\n.......")
        XCTAssertEqual(GroupInspection.read(s, at: Point(0, 0))!.group, [Point(0, 0)])
        XCTAssertEqual(GroupInspection.read(s, at: Point(0, 0))!.liberties, [Point(1, 0), Point(0, 1)])
        XCTAssertEqual(GroupInspection.read(s, at: Point(0, 2))!.liberties, [Point(0, 1), Point(1, 2), Point(0, 3)])
        XCTAssertNil(GroupInspection.read(s, at: Point(-1, 0)))
        XCTAssertNil(GroupInspection.read(s, at: Point(6, 6)))
    }
    func testCapturePreviewHasExactPayloadAndNoSpendUntilCommit() throws {
        var s = try session(3); let initial = s.state; let journal = s.progress
        let preview = s.preview(Point(3, 3))!
        XCTAssertEqual(s.state, initial); XCTAssertEqual(s.progress, journal)
        XCTAssertEqual(preview.events, [.resourcesSpent(.one, ap: 1, mana: 0), .piecePlaced(.one, Point(3, 3), .soldier),
            .piecesCaptured(.one, [CapturedPiece(at: Point(3, 2), piece: Piece(.two, .soldier))])])
        XCTAssertEqual(try s.commit(Point(3, 3)), preview)
        XCTAssertEqual(s.state.apRemaining, 1); XCTAssertEqual(s.state.mana(of: .one), 3)
        XCTAssertEqual(s.state.status, .ongoing)
    }
    func testRescueLastLibertyBecomesThreeWithoutChangingWinRules() throws {
        var s = try session(4)
        XCTAssertEqual(s.state.board.liberties(at: Point(3, 4)), [Point(3, 3)])
        XCTAssertTrue(try s.commit(Point(3, 3)).success)
        XCTAssertEqual(s.state.board.liberties(at: Point(3, 4)), [Point(3, 2), Point(2, 3), Point(4, 3)])
        XCTAssertEqual(s.state.board[Point(3, 4)], Piece(.one, .commander))
        XCTAssertTrue(s.completed)
    }
    func testIllegalActionDoesNotSpendEmitOrWriteJournal() throws {
        var s = try session(3); let initial = s.state; let journal = s.progress
        let rejected = try s.commit(Point(3, 2))
        XCTAssertEqual(rejected.reason, .occupied); XCTAssertTrue(rejected.events.isEmpty)
        XCTAssertEqual(s.state, initial); XCTAssertEqual(s.progress, journal)
        let outside = try s.commit(Point(7, 7))
        XCTAssertEqual(outside.reason, .outOfBounds); XCTAssertEqual(s.state, initial)
    }
    func testUndoRestoresResourcesHistoryAndCompletionThenReapplySameResult() throws {
        var s = try session(0); let before = s.state; let beforeProgress = s.progress
        let result = try s.commit(Point(3, 2)); XCTAssertTrue(s.completed)
        XCTAssertThrowsError(try s.commit(Point(6, 6)))
        XCTAssertTrue(s.undo()); XCTAssertFalse(s.completed)
        XCTAssertEqual(s.state, before); XCTAssertEqual(s.progress, beforeProgress)
        XCTAssertEqual(try s.commit(Point(3, 2)), result)
    }
    func testEntireCurriculumRestoresMidLessonAndFinalCompletion() throws {
        var s = try session(2); s.observe(Point(2, 3))
        let restored = try OnboardingSession(progress: s.progress)
        XCTAssertEqual(restored.state, s.state); XCTAssertFalse(restored.completed)
        s = try session(4); _ = try s.commit(Point(3, 3)); try s.advance()
        XCTAssertTrue(s.finished)
        let final = try OnboardingSession(progress: s.progress)
        XCTAssertTrue(final.finished); XCTAssertEqual(final.state, s.state)
    }
    func testRepositoryCannotOverwriteFormalRecordAndReplaysProgress() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let originalDirectory = root.appendingPathComponent("Records-v1")
        try FileManager.default.createDirectory(at: originalDirectory, withIntermediateDirectories: true)
        let original = originalDirectory.appendingPathComponent("original.json")
        let bytes = Data("original-game-unchanged".utf8); try bytes.write(to: original)
        let repository = OnboardingRepository(directory: root.appendingPathComponent("Onboarding"))
        let s = try session(3); try repository.save(s.progress)
        XCTAssertEqual(try repository.load().state, s.state)
        XCTAssertEqual(try Data(contentsOf: original), bytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: originalDirectory.path), ["original.json"])
    }
    func testCorruptVersionForgedCompletionAndIllegalHistoryRejectWithoutOverwrite() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = OnboardingRepository(directory: root)
        try repository.save(OnboardingProgress()); let original = try Data(contentsOf: repository.file)
        var bad = OnboardingProgress(); bad.version = 9
        XCTAssertThrowsError(try repository.save(bad)); XCTAssertEqual(try Data(contentsOf: repository.file), original)
        bad = OnboardingProgress(); bad.lessonIndex = 5
        XCTAssertThrowsError(try repository.save(bad)); XCTAssertEqual(try Data(contentsOf: repository.file), original)
        bad = OnboardingProgress(); bad.actions[0] = [Point(3, 1)]
        XCTAssertThrowsError(try repository.save(bad)); XCTAssertEqual(try Data(contentsOf: repository.file), original)
        bad = try session(2).progress
        bad.actions[2] = [Point(4, 3)] // Legal placement, but no recorded observation beforehand.
        XCTAssertThrowsError(try repository.save(bad)); XCTAssertEqual(try Data(contentsOf: repository.file), original)
        let corrupted = Data("not-json".utf8); try corrupted.write(to: repository.file)
        XCTAssertThrowsError(try repository.load()); XCTAssertEqual(try Data(contentsOf: repository.file), corrupted)
    }
}
