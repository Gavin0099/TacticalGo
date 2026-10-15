import XCTest
import TacticalGoCore
import TacticalGoContent

final class MonsterPresentationPracticeTests: XCTestCase {
    func testAllFourReplayFromNormalOpeningAndUndo() throws {
        for fixture in MonsterPresentationPractice.allCases {
            var session = try fixture.session();let before = session.state
            XCTAssertEqual(before.current,.one);XCTAssertEqual(before.status,.ongoing)
            XCTAssertEqual(before.config.bastionScope,.connectedGroup);XCTAssertTrue(before.config.experimentalFriendlyRedeploy)
            let preview = GameEngine.apply(before,fixture.action)
            XCTAssertTrue(preview.success);XCTAssertEqual(session.state,before)
            XCTAssertTrue(session.apply(fixture.action).success);XCTAssertEqual(session.state,preview.state)
            var replay = GameSession(try GameSetup.newGame(config:before.config,classOne:.warrior,classTwo:.mage))
            for a in session.log { XCTAssertTrue(replay.apply(a).success) }
            XCTAssertEqual(replay.state,session.state)
            XCTAssertTrue(session.undo());XCTAssertEqual(session.state,before)
        }
    }
    func testHuntsOnlyRemoveSelectedMonsterAndGrantTheSpecifiedReward() throws {
        for fixture in [MonsterPresentationPractice.slimeHunt,.wolfHunt] {
            let before = try fixture.session().state
            XCTAssertTrue(before.board.monsters.contains(Point(4,4)))
            let result = GameEngine.apply(before,fixture.action)
            XCTAssertTrue(result.success);XCTAssertTrue(result.state.board.monsters.isEmpty)
            let reward: MonsterAbility = fixture == .slimeHunt ? .stickyBounce : .shadowStep
            XCTAssertEqual(result.state.loot(of:.one,ability:reward)?.unlockPly,before.ply+2)
            XCTAssertTrue(result.events.contains(.resourcesSpent(.one,ap:1,mana:0)))
            for p in before.board.points { XCTAssertEqual(before.board[p],result.state.board[p]) }
        }
    }
    func testLootUsesDifferentObjectsAfterActualRewardUnlock() throws {
        for fixture in [MonsterPresentationPractice.slimeLoot,.wolfLoot] {
            let before = try fixture.session().state
            let reward: MonsterAbility = fixture == .slimeLoot ? .stickyBounce : .shadowStep
            let loot = try XCTUnwrap(before.loot(of:.one,ability:reward))
            XCTAssertGreaterThanOrEqual(before.ply,loot.unlockPly)
            let result = GameEngine.apply(before,fixture.action)
            XCTAssertTrue(result.success);XCTAssertNil(result.state.loot(of:.one,ability:reward))
            XCTAssertTrue(result.events.contains(.resourcesSpent(.one,ap:1,mana:0)))
            if fixture == .slimeLoot {
                XCTAssertEqual(before.board[Point(3,4)],Piece(.one,.soldier))
                XCTAssertNil(result.state.board[Point(3,4)])
                XCTAssertEqual(result.state.board[Point(3,5)],Piece(.one,.soldier))
                XCTAssertEqual(result.state.board[Point(3,3)],before.board[Point(3,3)])
            } else {
                XCTAssertEqual(before.board[Point(3,4)],Piece(.one,.hero))
                XCTAssertNil(result.state.board[Point(3,4)])
                XCTAssertEqual(result.state.board[Point(3,2)],Piece(.one,.hero))
                XCTAssertEqual(result.state.board[Point(3,5)],before.board[Point(3,5)])
            }
        }
    }
}
