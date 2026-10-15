import XCTest
import TacticalGoCore
import TacticalGoMotion

final class Anim01Tests: XCTestCase {
    func testPausedLastFrameDisplaysCommittedResultWithoutCaptureGhost() throws {
        let before = try Anim01Fixture.state()
        let result = GameEngine.apply(before, Anim01Fixture.action)
        let clip = try XCTUnwrap(Anim01MagicHand.make(before: before, action: Anim01Fixture.action, outcome: result))
        XCTAssertEqual(clip.displayTime(elapsed: 0.55, animating: true, reducedMotion: false), 0.55)
        XCTAssertEqual(clip.displayTime(elapsed: 0.55, animating: false, reducedMotion: false), 0.95, accuracy: 1e-8)
        XCTAssertEqual(clip.displayTime(elapsed: 0, animating: true, reducedMotion: true), 0.95, accuracy: 1e-8)
        XCTAssertNil(result.state.board[Point(3, 2)])
        XCTAssertEqual(result.state.winner, .one)
    }
    func testSharedRealCaptureFixturesPreserveOwnerResourcesAndUndo() throws {
        for size in [7, 9] {
            for owner in Player.allCases {
                let before = try Anim01Fixture.state(size: size, caster: owner, pushedOwner: owner)
                XCTAssertTrue(before.board.points.filter { before.board[$0] != nil }.allSatisfy { !before.board.liberties(at: $0).isEmpty })
                XCTAssertEqual(before.board.liberties(at: Point(3, 2)), [Point(4, 2)])
                var session = GameSession(before)
                let result = session.apply(Anim01Fixture.action)
                let clip = try XCTUnwrap(Anim01MagicHand.make(before: before, action: Anim01Fixture.action, outcome: result))
                XCTAssertEqual(clip.from, Point(4, 3)); XCTAssertEqual(clip.to, Point(4, 2))
                XCTAssertEqual(clip.piece, Piece(owner, .soldier)); XCTAssertEqual(clip.caster, owner)
                XCTAssertEqual(clip.hero, Point(3, 3))
                XCTAssertEqual(clip.captures.count, 1); XCTAssertEqual(clip.captures.first?.at, Point(3, 2)); XCTAssertEqual(clip.captures.first?.piece, Piece(owner.opponent, .commander))
                XCTAssertEqual(clip.winner, owner); XCTAssertEqual(clip.duration, 0.95, accuracy: 1e-8)
                XCTAssertEqual(result.state.board[Point(4, 2)], Piece(owner, .soldier))
                XCTAssertNil(result.state.board[Point(4, 3)]); XCTAssertNil(result.state.board[Point(3, 2)])
                XCTAssertEqual(result.state.mana(of: owner), 2); XCTAssertEqual(result.state.apRemaining, 1)
                XCTAssertTrue(session.undo()); XCTAssertEqual(session.state, before)
            }
        }
    }
    func testAllDirectionsBothFactionSoldiersUseActualPushedPayload() throws {
        for size in [7, 9] {
            for caster in Player.allCases {
                for owner in Player.allCases {
                    for direction in PushDirection.allCases {
                        var rows = Array(repeating: Array(repeating: Character("."), count: size), count: size)
                        rows[4][3] = caster == .one ? "H" : "Q"
                        rows[2][3] = owner == .one ? "x" : "o"
                        rows[5][1] = "X"; rows[1][5] = "O"
                        let before = try GameSetup.fromDiagram(config: .board(size: size), diagram: rows.map { String($0) }.joined(separator: "\n"),
                            classOne: .mage, classTwo: .mage, current: caster, manaOne: 4, manaTwo: 4, ap: 2)
                        let action = GameAction.castMagicHand(Point(3, 2), direction)
                        let result = GameEngine.apply(before, action)
                        XCTAssertTrue(result.success)
                        let clip = try XCTUnwrap(Anim01MagicHand.make(before: before, action: action, outcome: result))
                        XCTAssertEqual(clip.to, direction.destination(from: Point(3, 2)))
                        XCTAssertEqual(clip.piece.owner, owner); XCTAssertEqual(clip.caster, caster)
                        XCTAssertEqual(clip.captures, []); XCTAssertNil(clip.winner)
                        XCTAssertEqual(result.state.board[clip.to], Piece(owner, .soldier))
                        XCTAssertEqual(clip.duration, 0.95, accuracy: 1e-8)
                        XCTAssertEqual(before.board[Point(3, 2)], Piece(owner, .soldier))
                    }
                }
            }
        }
    }
    func testRejectedActionsHaveNoPresentationOrResourceChange() throws {
        let initial = try Anim01Fixture.state()
        let poor = try GameSetup.fromDiagram(config: initial.config, diagram: initial.board.diagram, classOne: .mage, manaOne: 1, ap: 2)
        let cases: [(GameState, GameAction, IllegalReason)] = [
            (initial, .castMagicHand(Point(4, 3), .left), .occupied),
            (initial, .castMagicHand(Point(3, 3), .up), .invalidTarget),
            (initial, .castMagicHand(Point(4, 3), .invalid), .invalidDirection),
            (initial, .castMagicHand(Point(6, 6), .up), .outOfRange),
            (poor, Anim01Fixture.action, .notEnoughMana)
        ]
        for (before, action, reason) in cases {
            let result = GameEngine.apply(before, action)
            XCTAssertEqual(result.reason, reason); XCTAssertEqual(result.state, before); XCTAssertTrue(result.events.isEmpty)
            XCTAssertNil(Anim01MagicHand.make(before: before, action: action, outcome: result))
            XCTAssertEqual(CombatFeedbackPlan.anim01(before: before, action: action, outcome: result).cues, [])
        }
        let edge = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "xH.....\n.....O.\n.......\n.......\n.......\n.X.....\n.......", classOne: .mage, manaOne: 4, ap: 2)
        let outside = GameEngine.apply(edge, .castMagicHand(Point(0, 0), .up))
        XCTAssertEqual(outside.reason, .outOfBounds); XCTAssertEqual(outside.state, edge)
        XCTAssertNil(Anim01MagicHand.make(before: edge, action: .castMagicHand(Point(0, 0), .up), outcome: outside))
    }
    func testReviewedTimingAndReducedMotionNeverMutateFinalState() throws {
        let before = try Anim01Fixture.state(capture: false)
        let result = GameEngine.apply(before, Anim01Fixture.action)
        let clip = try XCTUnwrap(Anim01MagicHand.make(before: before, action: Anim01Fixture.action, outcome: result))
        XCTAssertEqual(clip.progress(at: 0), 0); XCTAssertEqual(clip.progress(at: 0.38), 0)
        XCTAssertEqual(clip.progress(at: 0.49), 0.5, accuracy: 1e-8)
        XCTAssertEqual(clip.progress(at: 0.60), 1); XCTAssertEqual(clip.progress(at: 0.70), 1)
        XCTAssertEqual(clip.progress(at: 0, reducedMotion: true), 1)
        XCTAssertEqual(CombatFeedbackPlan.anim01(before: before, action: Anim01Fixture.action, outcome: result).cues,
                       [.init("mage", at: 0.26), .init("place", at: 0.60)])
        XCTAssertEqual(result.state.board[Point(4, 2)], Piece(.one, .soldier))
        XCTAssertEqual(result.state.apRemaining, 1); XCTAssertEqual(result.state.mana(of: .one), 2)
    }
    func testLastAPUsesPrecommitCasterEvenAfterAutomaticTurn() throws {
        let before = try Anim01Fixture.state(capture: false, ap: 1)
        let result = GameEngine.apply(before, Anim01Fixture.action)
        XCTAssertEqual(result.state.current, .two)
        let clip = try XCTUnwrap(Anim01MagicHand.make(before: before, action: Anim01Fixture.action, outcome: result))
        XCTAssertEqual(clip.caster, .one); XCTAssertEqual(clip.hero, Point(3, 3)); XCTAssertEqual(clip.piece.owner, .one)
    }
}
