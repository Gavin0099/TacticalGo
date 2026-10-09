import XCTest
@testable import TacticalGoCore
import TacticalGoGolden

final class MagicHandTests: XCTestCase {
    func testReviewedWindowsGameplayFixtures() throws {
        var repo = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { repo.deleteLastPathComponent() }
        let result = try GoldenReplay.run(directory: repo.appendingPathComponent("tests/ios-golden"))
        XCTAssertEqual(result.fixtures, 38)
        XCTAssertEqual(result.steps, 99)
    }
    func testFriendlyAndEnemyPushPreserveOwnershipAndUndoCompleteState() throws {
        for owner in [Player.one, .two] {
            let diagram = owner == .one ? ".....\n..O..\n.Hx..\n.....\n..X.." : ".....\n..O..\n.Ho..\n.....\n..X.."
            let initial = try GameSetup.fromDiagram(diagram: diagram, classOne: .mage, manaOne: 4, ap: 2)
            var session = GameSession(initial)
            let result = session.apply(.castMagicHand(Point(2, 2), .right))
            XCTAssertTrue(result.success)
            XCTAssertNil(result.state.board[Point(2, 2)])
            XCTAssertEqual(result.state.board[Point(3, 2)], Piece(owner, .soldier))
            XCTAssertEqual(result.state.board[Point(1, 2)], Piece(.one, .hero))
            XCTAssertEqual(result.events, [.resourcesSpent(.one, ap: 1, mana: 2), .piecePushed(caster: .one, from: Point(2, 2), to: Point(3, 2), piece: Piece(owner, .soldier))])
            XCTAssertEqual(result.state.mana(of: .one), 2)
            XCTAssertEqual(result.state.apRemaining, 1)
            XCTAssertEqual(session.apply(.castMagicHand(Point(3, 2), .right)).reason, .skillAlreadyUsed)
            XCTAssertTrue(session.undo())
            XCTAssertEqual(session.state, initial)
            XCTAssertTrue(session.apply(.castMagicHand(Point(2, 2), .right)).success) // superko restored
        }
    }
    func testIllegalDirectionAndOccupiedDestinationDoNotMutateOrSpend() throws {
        let initial = try GameSetup.fromDiagram(diagram: ".....\n..O..\n.Hox.\n.....\n..X..", classOne: .mage, manaOne: 4)
        for (action, reason) in [(GameAction.castMagicHand(Point(2, 2), .right), IllegalReason.occupied), (.castMagicHand(Point(2, 2), .invalid), .invalidDirection), (.castSeal(Point(1, 1)), .skillNotSelected)] {
            let result = GameEngine.apply(initial, action)
            XCTAssertEqual(result.reason, reason)
            XCTAssertEqual(result.state, initial)
            XCTAssertTrue(result.events.isEmpty)
        }
    }
}
