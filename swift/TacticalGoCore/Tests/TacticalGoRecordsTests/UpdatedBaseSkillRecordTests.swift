import Foundation
import Testing
import TacticalGoCore
import TacticalGoContent
@testable import TacticalGoRecords

enum RejectedBaseSkills: Sendable, CustomTestStringConvertible {
    case unknown
    case original
    case missingKey

    var testDescription: String {
        switch self {
        case .unknown: "unknown"
        case .original: "original"
        case .missingKey: "missing baseSkills"
        }
    }

    func apply(to object: inout [String: Any]) {
        switch self {
        case .unknown: object["baseSkills"] = "unknown"
        case .original: object["baseSkills"] = "original"
        case .missingKey: object.removeValue(forKey: "baseSkills")
        }
    }
}

@Suite("Updated base-skill records", .tags(.records, .expansion))
struct UpdatedBaseSkillRecordTests {
    @Test("A new mage profile round-trips, undoes, and keeps the redeployment marker")
    func newMageProfileActionRoundtripAndUndo() throws {
        var session = try ExpansionPractice.mage.session(updatedBaseSkills: true)
        let before = session.state
        #expect(session.apply(.castFriendlyRedeploy(Point(4, 5), Point(5, 5))).success)
        let data = try ExpansionMatchRecord(session: session, computer: .two, difficulty: "standard").data()
        let record = try ExpansionMatchRecord.read(data)
        #expect(record.baseSkills == "redeployment")
        var rebuilt = try record.rebuild()
        #expect(rebuilt.state == session.state)
        let undone = rebuilt.undo()
        #expect(undone)
        #expect(rebuilt.state == before)
    }

    @Test("Unknown, original, and missing base-skill profiles are rejected", arguments: [
        RejectedBaseSkills.unknown, .original, .missingKey
    ])
    func tamperedBaseSkillsProfileIsRejected(_ rejection: RejectedBaseSkills) throws {
        var session = try ExpansionPractice.mage.session(updatedBaseSkills: true)
        #expect(session.apply(.castFriendlyRedeploy(Point(4, 5), Point(5, 5))).success)
        let data = try ExpansionMatchRecord(session: session, computer: .two, difficulty: "standard").data()
        var changed = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        rejection.apply(to: &changed)
        let payload = try JSONSerialization.data(withJSONObject: changed)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
    }

    @Test("An absent profile keeps original rules and replays a push")
    func absentProfileRetainsOriginalRulesAndPushReplay() throws {
        var session = try ExpansionPractice.mage.session()
        #expect(session.apply(.castMagicHand(Point(4, 5), .right)).success)
        let data = try ExpansionMatchRecord(session: session).data()
        let record = try ExpansionMatchRecord.read(data)
        #expect(record.baseSkills == nil)
        #expect(try record.config().experimentalFriendlyRedeploy == false)
        #expect(try record.rebuild().state == session.state)
    }
}
