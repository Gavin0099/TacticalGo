import Testing
import Foundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

/// C0 / S4: an expansion match carries the identity of THE MATCH (not of one save). The identity is optional so that
/// candidate files written before the integration still load, and such a file is never given an identity while being
/// decoded - it stays unregistered in the access ledger and is not retroactively charged.
@Suite
struct ExpansionMatchIdentityTests {
    @Test(.tags(.roundTrip))
    func testIdentityRoundTripsAndEveryResaveKeepsIt() throws {
        let id = UUID()
        var session = try ExpansionPractice.mage.session()
        let first = try ExpansionMatchRecord(session: session, matchID: id)
        #expect(first.matchID == id)
        let loaded = try ExpansionMatchRecord.read(first.data())
        #expect(loaded.matchID == id)
        // Play on, save again from the rebuilt session: still the same match.
        session = try loaded.rebuild()
        let second = try ExpansionMatchRecord(session: session, matchID: loaded.matchID)
        #expect(try ExpansionMatchRecord.read(second.data()).matchID == id)
    }

    @Test(.tags(.roundTrip))
    func testLegacyFileWithoutIdentityStillLoadsAndRebuildsAndStaysUnregistered() throws {
        let session = try ExpansionPractice.priest.session()
        let bytes = try ExpansionMatchRecord(session: session, matchID: UUID()).data()
        var object = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        #expect(object["matchID"] != nil)
        object.removeValue(forKey: "matchID")          // what a pre-integration candidate file looks like
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let record = try ExpansionMatchRecord.read(legacy)
        #expect(record.matchID == nil, "decoding must not invent an identity")
        #expect(try record.rebuild().state == session.state)
        // Decoding twice must never produce two different identities for the same legacy bytes.
        #expect(try ExpansionMatchRecord.read(legacy).matchID == nil)
    }

    @Test(.tags(.rejection))
    func testMalformedIdentityIsRejectedNotIgnored() throws {
        let session = try ExpansionPractice.warrior.session()
        let bytes = try ExpansionMatchRecord(session: session, matchID: UUID()).data()
        var object = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        object["matchID"] = "not-a-uuid"
        let textID = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(textID)
        }
        object["matchID"] = 12
        let numericID = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(numericID)
        }
    }

    @Test
    func testTwoIndependentMatchesWithIdenticalContentKeepDistinctIdentities() throws {
        // Identity is never derived from board content: two separate games can look exactly the same.
        let session = try ExpansionPractice.rogue.session()
        let a = try ExpansionMatchRecord(session: session, matchID: UUID())
        let b = try ExpansionMatchRecord(session: session, matchID: UUID())
        #expect(a.matchID != b.matchID)
        #expect(a.expected == b.expected)
    }

    @Test(.tags(.roundTrip))
    func testUnknownKeysFromANewerWriterDoNotBreakAnOlderReader() throws {
        // An older 1.1 build reading a file with matchID simply ignores the key (forward compatibility).
        let session = try ExpansionPractice.mage.session()
        let bytes = try ExpansionMatchRecord(session: session, matchID: UUID()).data()
        var object = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        object["futureField"] = ["x": 1]
        let payload = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: Never.self) {
            try ExpansionMatchRecord.read(payload)
        }
    }
}
