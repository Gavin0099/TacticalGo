import XCTest
import TacticalGoCore
@testable import TacticalGoMotion

final class BattleMusicTests: XCTestCase {
    func testThreatUsesEitherCommanderActualLiberties() throws {
        func board(_ row: String) throws -> GameState {
            try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...x...\n..xO\(row)..\n.......\n.......\n.......\n...X...\n.......",
                classOne: .warrior, classTwo: .mage)
        }
        XCTAssertEqual(BattleMusicMix.threat(try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)), .normal)
        XCTAssertEqual(BattleMusicMix.threat(try board(".")), .focus) // Empty right and below.
        XCTAssertEqual(BattleMusicMix.threat(try board("x")), .danger) // Only below.
    }
    func testEscalationRampAndDeescalationStability() {
        var m = BattleMusicMix(); m.request(.danger, at: 10)
        XCTAssertEqual(m.level, .danger); XCTAssertEqual(m.layers(at: 10), [1,0,0])
        XCTAssertEqual(m.layers(at: 12.4)[1], 0.5, accuracy: 1e-9)
        XCTAssertEqual(m.layers(at: 14.8), [1,1,1])
        m.request(.normal, at: 20); m.advance(at: 21.19); XCTAssertEqual(m.level,.danger)
        m.request(.danger, at: 21.2); m.advance(at: 24); XCTAssertEqual(m.level,.danger)
        m.request(.focus, at: 30); m.advance(at: 31.21); XCTAssertEqual(m.level,.focus)
        XCTAssertEqual(m.layers(at: 36.1),[1,1,0])
    }
    func testInterruptedRampDoesNotJump() {
        var m = BattleMusicMix(); m.request(.focus, at: 1)
        let before = m.layers(at: 3); m.request(.danger,at: 3)
        XCTAssertEqual(m.layers(at: 3),before)
    }
    func testDuckAttackHoldReleaseAndCancel() {
        var m = BattleMusicMix(); m.duck(through: 12,at: 10)
        let target = pow(10.0,-5.0/20.0)
        XCTAssertEqual(m.duckGain(at: 10),1)
        XCTAssertEqual(m.duckGain(at: 10.06),(1+target)/2,accuracy:1e-9)
        XCTAssertEqual(m.duckGain(at: 10.12),target,accuracy:1e-9)
        XCTAssertEqual(m.duckGain(at: 12),target,accuracy:1e-9)
        XCTAssertEqual(m.duckGain(at: 12.375),(1+target)/2,accuracy:1e-9)
        XCTAssertEqual(m.duckGain(at: 12.75),1,accuracy:1e-9)
        m.duck(through: 20,at: 13); m.cancelDuck(); XCTAssertEqual(m.duckGain(at: 14),1)
    }
    func testTerminalDoesNotReviveOrRestartFade() {
        var m = BattleMusicMix();m.finish(at: 2);m.finish(at: 3)
        XCTAssertEqual(m.loopGain(at:2.6),0.5,accuracy:1e-9)
        XCTAssertEqual(m.loopGain(at:3.21),0)
        m.request(.danger,at:8); XCTAssertEqual(m.level,.normal);XCTAssertTrue(m.ended)
        m = BattleMusicMix();XCTAssertFalse(m.ended);XCTAssertEqual(m.loopGain(at:9),1)
    }
}
