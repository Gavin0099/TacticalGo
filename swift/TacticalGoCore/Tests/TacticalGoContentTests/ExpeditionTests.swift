import XCTest
import Foundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

final class ExpeditionTests: XCTestCase {
    private let ordinary: [[GameAction]] = [
        [.placeSoldier(Point(4,5)),.placeSoldier(Point(5,5))],
        [.placeSoldier(Point(5,3)),.placeSoldier(Point(5,4))]
    ]
    private func start(_ index: Int) throws -> ChallengeController {
        var c = try ChallengeController(campaign: .expedition)
        try c.choose(c.catalog[index].id);return c
    }
    private func reply(_ c: inout ChallengeController) throws {
        var count = 0
        while let action = c.opponentAction {
            XCTAssertTrue(try c.commit(action).success)
            count += 1;XCTAssertLessThanOrEqual(count,3)
        }
    }
    private func human(_ c: inout ChallengeController, _ actions: [GameAction]) throws {
        for action in actions {
            XCTAssertEqual(c.session?.state.current,.one)
            XCTAssertTrue(try c.commit(action).success,"\(action)")
        }
    }
    private func play(_ index: Int, _ turns: [[GameAction]]) throws -> ChallengeController {
        var c=try start(index)
        for turn in turns { try human(&c,turn);try reply(&c) }
        return c
    }
    func testAllThreeStagesHaveLegalCompleteWitnessesAfterThirdReply() throws {
        let plans = [ordinary,
            [[.castMagicHand(Point(4,2),.down),.placeSoldier(Point(4,2))],
             [.castMagicHand(Point(3,2),.left),.placeSoldier(Point(3,2))],
             [.placeSoldier(Point(5,4)),.castMagicHand(Point(2,3),.up)]],
            [[.placeSoldier(Point(4,2)),.placeSoldier(Point(4,4))],
             [.placeSoldier(Point(6,2)),.placeSoldier(Point(6,4))],
             [.placeSoldier(Point(2,1)),.placeSoldier(Point(2,2))]]]
        for (index,plan) in plans.enumerated() {
            let c=try play(index,plan)
            XCTAssertEqual(c.assessment,.completed)
            let session=try XCTUnwrap(c.session)
            let initial=try TutorialReplay.start(session.scenario)
            XCTAssertGreaterThanOrEqual(session.state.ply,initial.ply+2 * session.scenario.expeditionTurns)
            XCTAssertEqual(session.playerActionCount,index == 0 ? 4 : 6)
            XCTAssertThrowsError(try {var frozen=c;try frozen.commit(.endTurn)}())
            let restored=try ChallengeController(progress:c.progress,campaign:.expedition)
            XCTAssertEqual(restored.session?.state,session.state)
            XCTAssertEqual(restored.assessment,.completed)
            print("FINAL-WITNESS",index,String(decoding:try JSONEncoder().encode(c.progress),as:UTF8.self))
        }
    }
    func testNeverCompletesBeforeFinalEnemyReplyAndReviewIsFactual() throws {
        var c=try start(0)
        for turn in ordinary.prefix(1) {try human(&c,turn);try reply(&c)}
        XCTAssertFalse(c.locked)
        try human(&c,ordinary[1])
        XCTAssertFalse(c.locked,"Success before last counterplay is a regression")
        let first=try XCTUnwrap(c.opponentAction);_ = try c.commit(first)
        XCTAssertFalse(c.locked)
        let restored=try ChallengeController(progress:c.progress,campaign:.expedition)
        XCTAssertEqual(restored.opponentAction,c.opponentAction)
        XCTAssertEqual(restored.session?.state,c.session?.state)
        try reply(&c);XCTAssertEqual(c.assessment,.completed)
        let review=try ChallengeReview(session:XCTUnwrap(c.session))
        XCTAssertEqual(review.playerActions,4);XCTAssertEqual(review.manaSpent,0)
        XCTAssertGreaterThanOrEqual(review.commanderLiberties,5)
        XCTAssertEqual(review.timeline.count,c.session?.actions.count)
        XCTAssertTrue(review.timeline.contains{$0.contains("白：")})
    }
    func testPassOnlyAndIllegalInputCannotMakeProgressOrSuccess() throws {
        var c=try start(0)
        let before=c.progress;let state=c.session?.state
        let invalid=try c.commit(.placeSoldier(Point(-1,0)))
        XCTAssertFalse(invalid.success);XCTAssertTrue(invalid.events.isEmpty)
        XCTAssertEqual(c.progress,before);XCTAssertEqual(c.session?.state,state)
        for _ in 0..<3 where !c.locked {try human(&c,[.endTurn]);try reply(&c)}
        XCTAssertEqual(c.assessment?.label,"failed")
        XCTAssertTrue(c.completedIDs.isEmpty)
    }
    func testRemoteBaitNoLongerDistractsRescueOpponent() throws {
        var c=try start(0)
        try human(&c,[.castBastion(Point(4,5),Point(3,6)),.placeSoldier(Point(5,5))]);try reply(&c)
        try human(&c,[.placeSoldier(Point(0,0)),.placeSoldier(Point(5,4))]);try reply(&c)
        XCTAssertEqual(c.session?.state.board[Point(0,0)],Piece(.one,.soldier),"Do not spend both replies capturing irrelevant A1")
    }
    func testUndoRetryAndOldJournalsAreIsolated() throws {
        let dir=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer {try? FileManager.default.removeItem(at:dir)}
        let old=ChallengeRepository(directory:dir,campaign:.advanced)
        let intro=ChallengeRepository(directory:dir)
        try old.save(ChallengeProgress());try intro.save(ChallengeProgress())
        let oldBytes=try Data(contentsOf:old.file),introBytes=try Data(contentsOf:intro.file)
        let repo=ChallengeRepository(directory:dir,campaign:.expedition)
        var c=try play(0,ordinary)
        try repo.save(c.progress);XCTAssertEqual(try repo.load().session?.state,c.session?.state)
        XCTAssertTrue(try c.undo());XCTAssertFalse(c.locked)
        XCTAssertEqual(c.session?.playerActionCount,3)
        XCTAssertTrue(c.completedIDs.contains("tg12-expedition-1"))
        try c.retry();XCTAssertEqual(c.session?.playerActionCount,0)
        XCTAssertTrue(c.completedIDs.contains("tg12-expedition-1"))
        try repo.save(c.progress)
        XCTAssertEqual(try Data(contentsOf:old.file),oldBytes)
        XCTAssertEqual(try Data(contentsOf:intro.file),introBytes)
        var corrupt=c.progress;corrupt.selectedID="not-a-scenario"
        XCTAssertThrowsError(try repo.save(corrupt))
        XCTAssertEqual(try repo.load().progress,c.progress)
        corrupt=c.progress;corrupt.runs["tg12-expedition-1"]=Array(repeating:RecordedAction(.endTurn),count:25)
        XCTAssertThrowsError(try ChallengeController(progress:corrupt,campaign:.expedition))
    }
    func testRescueHasTwoResourceAndFrontierTradeoffs() throws {
        let plain=try play(0,ordinary)
        let fort=try play(0,[
            [.castBastion(Point(4,5),Point(3,6)),.placeSoldier(Point(5,5))],
            [.placeSoldier(Point(5,3)),.placeSoldier(Point(5,4))]])
        XCTAssertEqual(plain.assessment,.completed);XCTAssertEqual(fort.assessment,.completed)
        let a=try ChallengeReview(session:XCTUnwrap(plain.session)),b=try ChallengeReview(session:XCTUnwrap(fort.session))
        XCTAssertEqual(a.manaSpent,0);XCTAssertEqual(b.manaSpent,2)
        XCTAssertGreaterThanOrEqual(a.commanderLiberties,5);XCTAssertGreaterThanOrEqual(b.commanderLiberties,3)
        XCTAssertEqual(fort.session?.state.board[Point(3,6)]?.owner,.one)
        XCTAssertEqual(plain.session?.state.board[Point(3,6)]?.owner,.two)
        print("FINAL-FORT",String(decoding:try JSONEncoder().encode(fort.progress),as:UTF8.self))
    }

    func testCaptureStagesAlsoAcceptAlternativePlans() throws {
        let mage=try play(1,[
            [.castMagicHand(Point(4,2),.down),.placeSoldier(Point(4,2))],
            [.placeSoldier(Point(6,1)),.placeSoldier(Point(6,3))],
            [.placeSoldier(Point(5,4)),.castMagicHand(Point(2,3),.up)]])
        XCTAssertEqual(mage.assessment,.completed)
        let rogue=try play(2,[
            [.castSwap(Point(4,3)),.placeSoldier(Point(6,3))],
            [.endTurn],
            [.placeSoldier(Point(2,1)),.placeSoldier(Point(2,2))]])
        XCTAssertEqual(rogue.assessment,.completed)
        print("FINAL-ALT-MAGE",String(decoding:try JSONEncoder().encode(mage.progress),as:UTF8.self))
        print("FINAL-ALT-ROGUE",String(decoding:try JSONEncoder().encode(rogue.progress),as:UTF8.self))
    }

}
