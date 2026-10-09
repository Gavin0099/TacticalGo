import XCTest
@testable import TacticalGoCore
import TacticalGoGolden

final class CoreTests: XCTestCase {
    func testSharedGoldenFixtures() throws {
        var repo = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { repo.deleteLastPathComponent() }
        let result = try GoldenReplay.run(directory: repo.appendingPathComponent("tests/golden"), defaultMageSkill: .seal)
        XCTAssertGreaterThanOrEqual(result.fixtures, 23)
    }
    func testSevenAndNineBoardsUndoAndReplay() throws {
        for size in [7, 9] {
            let initial = try GameSetup.newGame(config: .board(size: size), classOne: .warrior, classTwo: .mage)
            var session = GameSession(initial)
            let summon = GameAction.summonHero(Point(size / 2, size - 3))
            XCTAssertTrue(session.apply(summon).success)
            XCTAssertEqual(session.state.current, .two)
            XCTAssertEqual(session.state.mana(of: .one), 2)
            XCTAssertEqual(session.state.mana(of: .two), 4)
            XCTAssertTrue(session.state.hasSummonedHero(.one))
            XCTAssertTrue(session.undo())
            XCTAssertEqual(session.state, initial)
            XCTAssertTrue(session.apply(summon).success) // undo MUST remove the superko entry
            let replayed = GameEngine.apply(initial, summon)
            XCTAssertEqual(session.state, replayed.state)
            XCTAssertEqual(replayed.events, [.resourcesSpent(.one, ap: 1, mana: 2),
                .piecePlaced(.one, Point(size / 2, size - 3), .hero), .turnEnded(.one, ply: 1),
                .turnStarted(.two, ply: 2, ap: 2, mana: 4)])
        }
    }
    func testCaptureEventPayloadAndImmediateWin() throws {
        let s = try GameSetup.fromDiagram(diagram: "xO.\n.x.\nX..", ap: 1)
        let o = GameEngine.apply(s, .placeSoldier(Point(2, 0)))
        XCTAssertEqual(o.state.status, .won)
        XCTAssertEqual(o.state.winner, .one)
        XCTAssertEqual(o.events, [.resourcesSpent(.one, ap: 1, mana: 0), .piecePlaced(.one, Point(2, 0), .soldier),
            .piecesCaptured(.one, [CapturedPiece(at: Point(1, 0), piece: Piece(.two, .commander))]), .gameWon(.one)])
        XCTAssertEqual(s.board[Point(1, 0)], Piece(.two, .commander))
        XCTAssertEqual(GameEngine.apply(o.state, .endTurn).reason, .gameOver)
    }
    func testSealPayloadUndoAndLiberties() throws {
        var config = RuleConfig(); config.mageSkill = .seal
        let s = try GameSetup.fromDiagram(config: config, diagram: "...\n.H.\n...", classOne: .mage, manaOne: 4)
        var session = GameSession(s)
        let o = session.apply(.castSeal(Point(1, 0)))
        XCTAssertEqual(o.events, [.resourcesSpent(.one, ap: 1, mana: 2), .sealPlaced(caster: .one, blocked: .two, at: Point(1, 0))])
        XCTAssertEqual(o.state.board.liberties(at: Point(1, 1)).count, 4)
        XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state, s)
        XCTAssertFalse(session.undo())
    }
    func testSkillGateFailureDoesNotSpendOrEmit() throws {
        let s = try GameSetup.fromDiagram(diagram: "...\n.H.\n...", classOne: .warrior, manaOne: 1)
        let o = GameEngine.apply(s, .castBastion(Point(0, 1), Point(2, 1)))
        XCTAssertEqual(o.reason, .notEnoughMana)
        XCTAssertEqual(o.state, s)
        XCTAssertTrue(o.events.isEmpty)
        XCTAssertEqual(GameEngine.validate(s, .castSeal(Point(0, 1))), .wrongClass)
    }
    func testProjectionRoundTripsAndRejectsOutsideBoard() {
        for size in [7, 9] {
            let projection = BoardProjection(size: size)
            for y in 0..<size { for x in 0..<size {
                let p = Point(x, y), anchor = projection.center(p)
                XCTAssertEqual(projection.hit(x: anchor.x, y: anchor.y), p)
            } }
            XCTAssertNil(projection.hit(x: 0.5, y: 0.01))
            XCTAssertNil(projection.hit(x: 0.01, y: 0.5))
            // Hand-calculated front-left and rear-right anchors, shared by both renderers.
            let near = projection.center(Point(0, size - 1))
            XCTAssertEqual(near.x, 0.07, accuracy: 0.0001)
            XCTAssertEqual(near.y, 0.83, accuracy: 0.0001)
            let far = projection.center(Point(size - 1, 0))
            XCTAssertEqual(far.x, 0.87, accuracy: 0.0001)
            XCTAssertEqual(far.y, 0.18, accuracy: 0.0001)
        }
    }
    func testMalformedSetupFailsExplicitly() {
        XCTAssertThrowsError(try Board.parse("..\n..."))
        XCTAssertThrowsError(try Board.parse("?"))
        var config = RuleConfig(); config.boardSize = 7 // default commander at y=7 is invalid
        XCTAssertThrowsError(try GameSetup.newGame(config: config))
    }
}
