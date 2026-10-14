import XCTest
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoRecords

final class UpdatedBaseSkillRecordTests: XCTestCase {
    func testNewMageProfileActionRoundtripUndoAndRejectTampering() throws {
        var s = try ExpansionPractice.mage.session(updatedBaseSkills:true)
        let before = s.state
        XCTAssertTrue(s.apply(.castFriendlyRedeploy(Point(4,5),Point(5,5))).success)
        let data = try ExpansionMatchRecord(session:s,computer:.two,difficulty:"standard").data()
        let record = try ExpansionMatchRecord.read(data)
        XCTAssertEqual(record.baseSkills,"redeployment")
        var rebuilt = try record.rebuild();XCTAssertEqual(rebuilt.state,s.state)
        XCTAssertTrue(rebuilt.undo());XCTAssertEqual(rebuilt.state,before)
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        for value in ["unknown","original"] {
            var changed = original;changed["baseSkills"] = value
            XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:changed)))
        }
        var missing = original;missing.removeValue(forKey:"baseSkills")
        XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:missing)))
    }
    func testAbsentProfileRetainsOriginalRulesAndPushReplay() throws {
        var s = try ExpansionPractice.mage.session()
        XCTAssertTrue(s.apply(.castMagicHand(Point(4,5),.right)).success)
        let data = try ExpansionMatchRecord(session:s).data()
        let record = try ExpansionMatchRecord.read(data)
        XCTAssertNil(record.baseSkills);XCTAssertFalse(try record.config().experimentalFriendlyRedeploy)
        XCTAssertEqual(try record.rebuild().state,s.state)
    }
}
