import Foundation
import Testing
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoRecords

@Suite
struct UpdatedBaseSkillRecordTests {
    @Test(.tags(.roundTrip, .rejection))
    func testNewMageProfileActionRoundtripUndoAndRejectTampering() throws {
        var s = try ExpansionPractice.mage.session(updatedBaseSkills: true)
        let before = s.state
        #expect(s.apply(.castFriendlyRedeploy(Point(4, 5), Point(5, 5))).success)
        let data = try ExpansionMatchRecord(session: s, computer: .two, difficulty: "standard").data()
        let record = try ExpansionMatchRecord.read(data)
        #expect(record.baseSkills == "redeployment")
        var rebuilt = try record.rebuild()
        #expect(rebuilt.state == s.state)
        let didUndo = rebuilt.undo()
        #expect(didUndo)
        #expect(rebuilt.state == before)
        let original = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        var missing = original
        missing.removeValue(forKey: "baseSkills")
        let payload = try JSONSerialization.data(withJSONObject: missing)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
    }

    @Test(.tags(.rejection), arguments: ["unknown", "original"])
    func testTamperedBaseSkillsProfileIsRejected(_ value: String) throws {
        var s = try ExpansionPractice.mage.session(updatedBaseSkills: true)
        #expect(s.apply(.castFriendlyRedeploy(Point(4, 5), Point(5, 5))).success)
        let data = try ExpansionMatchRecord(session: s, computer: .two, difficulty: "standard").data()
        var changed = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        changed["baseSkills"] = value
        let payload = try JSONSerialization.data(withJSONObject: changed)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
    }

    @Test(.tags(.roundTrip))
    func testAbsentProfileRetainsOriginalRulesAndPushReplay() throws {
        var s = try ExpansionPractice.mage.session()
        #expect(s.apply(.castMagicHand(Point(4, 5), .right)).success)
        let data = try ExpansionMatchRecord(session: s).data()
        let record = try ExpansionMatchRecord.read(data)
        #expect(record.baseSkills == nil)
        #expect(try record.config().experimentalFriendlyRedeploy == false)
        #expect(try record.rebuild().state == s.state)
    }
}
