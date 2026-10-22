import XCTest
import TacticalGoContent

final class PlaytestObservationTests: XCTestCase {
    func testBackgroundAndPostResultTimeExcludedAndUndoRestartsClock() throws {
        var o = PlaytestObservation()
        o.begin("a",at:100); o.record("hint",at:110); o.pause(at:120)
        o.resume(at:200); o.finish("failed",at:205); o.finish("failed",at:210)
        XCTAssertEqual(o.events.filter{$0.kind == "result"}.count,1)
        XCTAssertEqual(o.events.last?.activeSeconds,25)
        o.undo(at:300);o.finish("completed",at:310)
        XCTAssertEqual(o.events.last?.activeSeconds,35)
        o.begin("a",at:400,retry:true)
        XCTAssertEqual(o.events.last?.kind,"retry");XCTAssertEqual(o.events.last?.activeSeconds,0)
        XCTAssertTrue(try o.report().contains("completed"))
    }
    func testInvalidTimesNoAttemptAndBoundedEvents() {
        var o=PlaytestObservation()
        o.record("hint",at:0);o.begin("a",at:.nan)
        XCTAssertTrue(o.events.isEmpty)
        o.begin("a",at:10);o.record("hint",at:5)
        XCTAssertEqual(o.events.last?.activeSeconds,0)
        o.record("hint",at:.infinity)
        XCTAssertEqual(o.events.count,2)
        for i in 0..<600 { o.record("hint",at:Double(i)) }
        XCTAssertEqual(o.events.count,500)
    }
}
