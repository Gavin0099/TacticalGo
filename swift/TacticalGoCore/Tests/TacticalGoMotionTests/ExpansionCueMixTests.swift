import XCTest
import TacticalGoMotion

final class ExpansionCueMixTests: XCTestCase {
    func testImpactRetainsAccepted1108ReferenceInBothVoiceModes() {
        // Existing native baseline/SCHEDULES: hero impact .30 voiced, .65 with voice off.
        XCTAssertEqual(ExpansionCueMix(voiceEnabled:true).impact,0.30)
        XCTAssertEqual(ExpansionCueMix(voiceEnabled:false).impact,0.65)
        XCTAssertEqual(ExpansionCueMix.monsterImpact,0.65)
    }
    func testSecondaryCuesAreBelowMainContactAndAllLevelsAreUsable() {
        for voice in [true,false] {
            let mix = ExpansionCueMix(voiceEnabled:voice)
            XCTAssertLessThan(mix.preparation,mix.motion);XCTAssertLessThan(mix.motion,mix.impact)
            for level in [mix.preparation,mix.motion,mix.impact] { XCTAssertTrue((0...1).contains(level));XCTAssertGreaterThan(level,0) }
        }
        XCTAssertLessThan(ExpansionCueMix.monsterPreparation,ExpansionCueMix.monsterMotion)
        XCTAssertLessThan(ExpansionCueMix.monsterMotion,ExpansionCueMix.monsterImpact)
    }
}
