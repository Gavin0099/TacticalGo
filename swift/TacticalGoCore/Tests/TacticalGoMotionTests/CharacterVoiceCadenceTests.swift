import XCTest
import TacticalGoCore
import TacticalGoMotion

final class CharacterVoiceCadenceTests: XCTestCase {
    func testBalancedReviewedSequenceSpeaksFirstFourthAndSeventh() {
        var cadence = CharacterVoiceCadence()
        let times: [Double] = [0,3,6,12,15,18,24]
        let observed = times.map { cadence.shouldSpeak(player:.one,hero:.mage,at:$0,eligible:true) }
        XCTAssertEqual(observed, [true,false,false,true,false,false,true])
    }
    func testCalmDeferredOpportunityWaitsForEighteenSeconds() {
        var cadence = CharacterVoiceCadence(profile:.calm)
        let times: [Double] = [0,3,6,9,12,18,21,24,27,30,33,36]
        let observed = times.map { cadence.shouldSpeak(player:.one,hero:.warrior,at:$0,eligible:true) }
        XCTAssertEqual(observed, [true,false,false,false,false,true,false,false,false,false,false,true])
    }
    func testBothPlayersHaveFirstLineWithGlobalQuietGap() {
        var cadence = CharacterVoiceCadence()
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.mage,at:0,eligible:true))
        XCTAssertFalse(cadence.shouldSpeak(player:.two,hero:.warrior,at:1,eligible:true))
        XCTAssertTrue(cadence.shouldSpeak(player:.two,hero:.warrior,at:3,eligible:true))
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:6,eligible:true))
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:9,eligible:true))
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.mage,at:12,eligible:true))
    }
    func testDisabledAndInvalidClockPreserveFirstOpportunity() {
        var cadence = CharacterVoiceCadence();let initial = cadence
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:0,eligible:false))
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.none,at:0,eligible:true))
        for time in [Double.nan, .infinity, -.infinity, -1] {
            XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:time,eligible:true))
        }
        XCTAssertEqual(cadence,initial)
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.mage,at:0,eligible:true))
    }
    func testBackwardClockDoesNotConsumeAnEligibleCast() {
        var cadence = CharacterVoiceCadence()
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.rogue,at:100,eligible:true))
        let before = cadence
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.rogue,at:99,eligible:true))
        XCTAssertEqual(cadence,before)
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.rogue,at:104,eligible:true))
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.rogue,at:108,eligible:true))
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.rogue,at:112,eligible:true))
    }
    func testBackwardClockAfterQuietCastDoesNotAdvanceOpportunity() {
        var cadence = CharacterVoiceCadence()
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.mage,at:0,eligible:true))
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:6,eligible:true))
        let before = cadence
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:5,eligible:true))
        XCTAssertEqual(cadence,before)
        XCTAssertFalse(cadence.shouldSpeak(player:.one,hero:.mage,at:9,eligible:true))
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.mage,at:12,eligible:true))
    }
    func testNewMatchResetRestoresFirstLineWithoutDelayedPlayback() {
        var cadence = CharacterVoiceCadence()
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.priest,at:100,eligible:true))
        cadence.reset()
        XCTAssertEqual(cadence,CharacterVoiceCadence())
        XCTAssertTrue(cadence.shouldSpeak(player:.one,hero:.priest,at:0,eligible:true))
    }
}
