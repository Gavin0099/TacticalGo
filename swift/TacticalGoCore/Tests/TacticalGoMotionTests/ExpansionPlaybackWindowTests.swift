import XCTest
import TacticalGoMotion

final class ExpansionPlaybackWindowTests: XCTestCase {
    func testOrdinaryActionUnlocksAtVisualEndAndKeepsLongVoiceTailSeparate() {
        // Existing rogue B voice: .06 start + 1.219s WAV, versus .70s visual clip.
        let p=ExpansionPlaybackWindow.make(visualEnd:0.70,lastSoundEnd:1.279,terminal:false)
        XCTAssertEqual(p.inputEnd,0.70);XCTAssertEqual(p.audioEnd,1.279)
        XCTAssertGreaterThan(p.audioEnd-p.inputEnd,0.57)
        XCTAssertEqual(ExpansionPlaybackWindow.make(visualEnd:1.02,lastSoundEnd:0.82,terminal:false).audioEnd,1.02)
    }
    func testTerminalKeepsEndingWindowAndMutedOrZeroDurationActionStaysBounded() {
        let p=ExpansionPlaybackWindow.make(visualEnd:1.02,lastSoundEnd:1.28,terminal:true,endingTail:0.8)
        XCTAssertEqual(p.inputEnd,1.82,accuracy:0.0001);XCTAssertEqual(p.audioEnd,p.inputEnd)
        let terminalVoice=ExpansionPlaybackWindow.make(visualEnd:0.70,lastSoundEnd:1.279,terminal:true)
        XCTAssertEqual(terminalVoice.inputEnd,1.279)
        let muted=ExpansionPlaybackWindow.make(visualEnd:0.94,lastSoundEnd:0,terminal:false)
        XCTAssertEqual(muted.inputEnd,0.94);XCTAssertEqual(muted.audioEnd,0.94)
        let turn=ExpansionPlaybackWindow.make(visualEnd:0,lastSoundEnd:0,terminal:false)
        XCTAssertEqual(turn.inputEnd,0);XCTAssertEqual(turn.audioEnd,0)
    }
    func testInvalidOrOverflowingDurationsCannotCreateInfiniteTaskSleep() {
        for bad in [-1,Double.nan,Double.infinity] {
            let a=ExpansionPlaybackWindow.make(visualEnd:bad,lastSoundEnd:1,terminal:false)
            let b=ExpansionPlaybackWindow.make(visualEnd:1,lastSoundEnd:bad,terminal:false)
            let c=ExpansionPlaybackWindow.make(visualEnd:1,lastSoundEnd:1,terminal:true,endingTail:bad)
            for p in [a,b,c] { XCTAssertEqual(p.inputEnd,0);XCTAssertEqual(p.audioEnd,0) }
        }
        let overflow=ExpansionPlaybackWindow.make(visualEnd:.greatestFiniteMagnitude,lastSoundEnd:1,terminal:true,endingTail:.greatestFiniteMagnitude)
        XCTAssertEqual(overflow.audioEnd,0)
    }
}
