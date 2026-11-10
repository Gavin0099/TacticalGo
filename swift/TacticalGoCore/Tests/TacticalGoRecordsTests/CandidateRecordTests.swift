import Foundation
import Testing
import TacticalGoCore
@testable import TacticalGoRecords

enum SourceReceiptTamper: Sendable, CustomTestStringConvertible {
    case mana
    case events
    case actor

    var testDescription: String {
        switch self {
        case .mana: "mana"
        case .events: "events"
        case .actor: "actor"
        }
    }

    func apply(to steps: inout [[String: Any]]) throws {
        switch self {
        case .mana:
            var after = try #require(steps[0]["after"] as? [String: Any])
            after["mana"] = [999, 999]
            steps[0]["after"] = after
        case .events:
            steps[0]["events"] = ["ResourcesSpent:0:1:999"]
        case .actor:
            steps[0]["actor"] = 1
        }
    }
}

enum MalformedRedeployWire: Sendable, CustomTestStringConvertible {
    case emptyPoints
    case onePoint
    case threePoints
    case directionIncluded
    case negativeCoordinate
    case identicalPoints

    var testDescription: String {
        switch self {
        case .emptyPoints: "no points"
        case .onePoint: "one point"
        case .threePoints: "three points"
        case .directionIncluded: "direction included"
        case .negativeCoordinate: "negative coordinate"
        case .identicalPoints: "identical points"
        }
    }

    var action: [String: Any] {
        switch self {
        case .emptyPoints:
            ["kind": "redeploy", "points": []]
        case .onePoint:
            ["kind": "redeploy", "points": [["x": 3, "y": 4]]]
        case .threePoints:
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 2, "y": 3], ["x": 1, "y": 3]]]
        case .directionIncluded:
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 2, "y": 3]], "direction": "Left"]
        case .negativeCoordinate:
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": -1, "y": 3]]]
        case .identicalPoints:
            ["kind": "redeploy", "points": [["x": 3, "y": 4], ["x": 3, "y": 4]]]
        }
    }
}

enum CandidateReceiptTamper: Sendable, CustomTestStringConvertible {
    case ap
    case events

    var testDescription: String {
        switch self {
        case .ap: "ap"
        case .events: "events"
        }
    }

    func apply(to steps: inout [[String: Any]], last: Int) throws {
        switch self {
        case .ap:
            var after = try #require(steps[last]["after"] as? [String: Any])
            after["ap"] = 999
            steps[last]["after"] = after
        case .events:
            steps[last]["events"] = ["PiecePushed:0:3,4:2,3:1:0"]
        }
    }
}

@Suite("Candidate records", .tags(.records, .candidate))
struct CandidateRecordTests {
    /// No synthetic boards: the complete official source is retained in RecordStep receipts.
    private func mageSource(size: Int = 7, rules: RecordRules = .original, computer: Player? = .two) throws -> (MatchRecord, GameSession) {
        var record = MatchRecord(
            size: size, one: .mage, two: .warrior, computer: size == 9 ? nil : computer,
            difficulty: "standard", rules: rules
        )
        var session = try record.rebuild().0
        let x = size / 2
        for action in [
            GameAction.placeSoldier(Point(x, size - 3)), .endTurn,
            .summonHero(Point(x, size - 4)), .placeSoldier(Point(0, 0)), .endTurn
        ] {
            try append(action, record: &record, session: &session)
        }
        return (record, session)
    }

    private func append(_ action: GameAction, record: inout MatchRecord, session: inout GameSession) throws {
        let before = session.state
        let outcome = session.apply(action)
        #expect(outcome.success, "Official newGame fixture action \(action) rejected: \(outcome.reason)")
        guard outcome.success else { throw RecordError.invalidAction(record.steps.count) }
        let index = record.steps.count
        record.steps.append(RecordStep(
            action: action, before: before, outcome: outcome,
            difficulty: index.isMultiple(of: 2) ? "standard" : "easy",
            decision: "reviewed fixture step \(index)"
        ))
    }

    private func redeploy(_ size: Int) -> GameAction {
        .castFriendlyRedeploy(Point(size / 2, size - 3), Point(size / 2 - 1, size - 4))
    }

    private func json(_ record: MatchRecord) throws -> [String: Any] {
        try #require(JSONSerialization.jsonObject(with: try record.encoded()) as? [String: Any])
    }

    private func rawRecord(_ value: [String: Any]) throws -> MatchRecord {
        try JSONDecoder().decode(MatchRecord.self, from: JSONSerialization.data(withJSONObject: value))
    }

    private func expectReceiptMismatch(step: Int, _ body: () throws -> Void) {
        let error = #expect(throws: (any Error).self) {
            try body()
        }
        guard let error else { return }
        guard case RecordError.receiptMismatch(let actual) = error else {
            Issue.record("Expected receiptMismatch, got \(error)")
            return
        }
        #expect(actual == step)
    }

    @Test("Candidate rules enable redeploy and do not enable exchange", arguments: [7, 9])
    func candidateRulesExplicitlyEnableRedeployWithoutExchange(size: Int) {
        let config = RecordRules.redeployment.config(size: size)
        #expect(config.boardSize == size)
        #expect(config.bastionScope == .connectedGroup)
        #expect(config.mageSkill == .magicHand)
        #expect(config.magicHandDestination == .emptyOnly)
        #expect(config.experimentalFriendlyRedeploy)
        #expect(RecordRules.original.config(size: size).experimentalFriendlyRedeploy == false)
    }

    @Test("A candidate copy preserves every step and metadata under a new identity", arguments: [7, 9])
    func candidateCopyPreservesAllStepsAndMetadataWithNewIdentity(size: Int) throws {
        let (original, originalSession) = try mageSource(size: size)
        let originalBytes = try original.encoded()
        let candidate = try original.candidateCopy()
        #expect(candidate.id != original.id)
        #expect(candidate.created != original.created)
        #expect(candidate.created == candidate.updated)
        #expect(candidate.rules == .redeployment)
        #expect(candidate.schema == original.schema)
        #expect(candidate.engineVersion == original.engineVersion)
        #expect(candidate.size == original.size)
        #expect(candidate.one == original.one)
        #expect(candidate.two == original.two)
        #expect(candidate.computer == original.computer)
        #expect(candidate.difficulty == original.difficulty)
        #expect(candidate.steps == original.steps) // Includes actor, receipt, events, step difficulty and decision.
        #expect(try original.encoded() == originalBytes)
        #expect(try original.rebuild().0.state == originalSession.state)
        #expect(StateReceipt(try candidate.rebuild().0.state) == StateReceipt(originalSession.state))
        #expect(try MatchRecord.decode(candidate.encoded()).steps == original.steps)
    }

    @Test("A human-only source stays human-only after candidate copy")
    func candidateCopyOfHumanOnlyMatchHasNoComputer() throws {
        let (humanOnly, _) = try mageSource(computer: nil)
        #expect(try humanOnly.candidateCopy().computer == nil)
    }

    @Test("Candidate redeploy replays, undoes once, and keeps a real superko", arguments: [7, 9])
    func candidateRedeployOfficialReplayUndoAPManaOnceAndRealSuperko(size: Int) throws {
        let (original, _) = try mageSource(size: size)
        var candidate = try original.candidateCopy()
        var session = try candidate.rebuild().0
        let before = session.state
        let command = redeploy(size)
        #expect(before.apRemaining == 2)
        #expect(before.mana(of: .one) == 3)
        try append(command, record: &candidate, session: &session)
        #expect(session.state.apRemaining == 1)
        #expect(session.state.mana(of: .one) == 1)
        #expect(session.state.skillUsedThisTurn)
        #expect(session.state.hasSummonedHero(.one))
        #expect(GameEngine.validate(session.state, command) == .skillAlreadyUsed)
        let encoded = try candidate.encoded()
        let decoded = try MatchRecord.decode(encoded)
        var restored = try decoded.rebuild().0
        #expect(restored.state == session.state) // Equality includes exact historical boards.
        let undone = restored.undo()
        #expect(undone)
        #expect(restored.state == before)
        #expect(restored.apply(command).success)
        #expect(restored.state == session.state)
        let events = try #require(decoded.rebuild().1.last).events
        let movement = try #require(events.first { event in
            if case .piecePushed = event { return true }
            return false
        })
        #expect(movement == .piecePushed(
            caster: .one,
            from: Point(size / 2, size - 3),
            to: Point(size / 2 - 1, size - 4),
            piece: Piece(.one, .soldier)
        ))
        for action in [GameAction.endTurn, .endTurn] {
            try append(action, record: &candidate, session: &session)
        }
        let reverse = GameAction.castFriendlyRedeploy(Point(size / 2 - 1, size - 4), Point(size / 2, size - 3))
        let replay = try MatchRecord.decode(candidate.encoded()).rebuild().0
        #expect(replay.state == session.state)
        #expect(replay.state.mana(of: .one) == 2)
        #expect(replay.state.skillUsedThisTurn == false)
        let rejected = GameEngine.apply(replay.state, reverse)
        #expect(rejected.reason == .ko, "A real prior official-source board is reconstructed, not injected")
        #expect(rejected.state == replay.state)
        #expect(rejected.events.isEmpty)
        #expect(GameEngine.apply(session.state, reverse) == rejected)
    }

    @Test("The v1 redeploy wire is stable and old actions need no migration")
    func stableV1RedeployWireAndOldActionsNeedNoMigration() throws {
        let command = GameAction.castFriendlyRedeploy(Point(3, 4), Point(2, 3))
        let wire = RecordedAction(command)
        #expect(wire.kind == "redeploy")
        #expect(wire.points == [Point(3, 4), Point(2, 3)])
        #expect(wire.direction == nil)
        #expect(wire.label == "重新部署 D5、C4")
        #expect(try wire.action() == command)
        let encoded = try JSONEncoder().encode(wire)
        let object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(Set(object.keys) == Set(["kind", "points"]))
        let old = Data(#"{"kind":"push","points":[{"x":3,"y":4}],"direction":"Left"}"#.utf8)
        #expect(try JSONDecoder().decode(RecordedAction.self, from: old).action() == .castMagicHand(Point(3, 4), .left))
        let (original, _) = try mageSource()
        #expect(original.schema == 1)
        #expect(original.engineVersion == "tacticalgo-actions-v1")
        #expect(try MatchRecord.decode(original.encoded()).steps == original.steps)
    }

    @Test("A repeated candidate copy throws alreadyCandidate and does not rewrite bytes")
    func repeatedCandidateCopyThrowsAlreadyCandidate() throws {
        let (original, _) = try mageSource()
        let candidate = try original.candidateCopy()
        let bytes = try candidate.encoded()
        let error = #expect(throws: (any Error).self) {
            try candidate.candidateCopy()
        }
        if let error {
            if case RecordError.alreadyCandidate = error {
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
        #expect(try candidate.encoded() == bytes)
    }

    @Test("Original rules reject redeploy and cannot import candidate receipts")
    func originalRulesRejectRedeployAndCannotImportCandidateReceipts() throws {
        let (original, source) = try mageSource()
        let rejected = GameEngine.apply(source.state, redeploy(7))
        #expect(rejected.reason == .skillNotSelected)
        #expect(rejected.state == source.state)
        #expect(rejected.events.isEmpty)
        var candidate = try original.candidateCopy()
        var session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        var value = try json(candidate)
        value["rules"] = "original"
        let payload = try JSONSerialization.data(withJSONObject: value)
        let error = #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
        if let error {
            if case RecordError.invalidAction(let index) = error {
                #expect(index == original.steps.count)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
    }

    @Test("An R2 exchange source rejects candidate conversion without rewriting")
    func r2ExchangeSourceRejectsCandidateConversionWithoutRewriting() throws {
        var original = MatchRecord(size: 7, one: .mage, two: .warrior, computer: .two, difficulty: "standard", rules: .mage)
        var session = try original.rebuild().0
        for action in [
            GameAction.placeSoldier(Point(3, 4)), .placeSoldier(Point(5, 3)), .endTurn,
            .summonHero(Point(3, 3)), .placeSoldier(Point(4, 3)), .endTurn, .castMagicHand(Point(4, 3), .right)
        ] {
            try append(action, record: &original, session: &session)
        }
        #expect(session.state.board[Point(4, 3)] == Piece(.two, .soldier))
        #expect(session.state.board[Point(5, 3)] == Piece(.one, .soldier))
        let bytes = try original.encoded()
        #expect(try MatchRecord.decode(bytes).rebuild().0.state == session.state)
        let error = #expect(throws: (any Error).self) {
            try original.candidateCopy()
        }
        if let error {
            if case RecordError.invalidAction(let index) = error {
                #expect(index == original.steps.count - 1)
            } else {
                Issue.record("Unexpected error: \(error)")
            }
        }
        #expect(try original.encoded() == bytes)
    }

    @Test("Candidate copy validates source receipts, events, and actor before copying", arguments: [
        SourceReceiptTamper.mana, .events, .actor
    ])
    func candidateCopyValidatesSourceReceiptsEventsAndActorBeforeCopying(_ tamper: SourceReceiptTamper) throws {
        let (original, _) = try mageSource()
        var value = try json(original)
        var steps = try #require(value["steps"] as? [[String: Any]])
        try tamper.apply(to: &steps)
        value["steps"] = steps
        let tampered = try rawRecord(value)
        let bytes = try tampered.encoded()
        expectReceiptMismatch(step: 0) { _ = try tampered.candidateCopy() }
        #expect(try tampered.encoded() == bytes)
    }

    @Test("Malformed redeploy wire is rejected", arguments: [
        MalformedRedeployWire.emptyPoints,
        .onePoint,
        .threePoints,
        .directionIncluded,
        .negativeCoordinate,
        .identicalPoints
    ])
    func malformedRedeployWireIsRejected(_ wire: MalformedRedeployWire) throws {
        let (original, _) = try mageSource()
        var candidate = try original.candidateCopy()
        var session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        var value = try json(candidate)
        var steps = try #require(value["steps"] as? [[String: Any]])
        steps[steps.count - 1]["action"] = wire.action
        value["steps"] = steps
        let payload = try JSONSerialization.data(withJSONObject: value)
        #expect(throws: (any Error).self) {
            try MatchRecord.decode(payload)
        }
    }

    @Test("A tampered candidate redeploy receipt is rejected", arguments: [CandidateReceiptTamper.ap, .events])
    func tamperedCandidateReceiptIsRejected(_ tamper: CandidateReceiptTamper) throws {
        let (original, _) = try mageSource()
        var candidate = try original.candidateCopy()
        var session = try candidate.rebuild().0
        try append(redeploy(7), record: &candidate, session: &session)
        var value = try json(candidate)
        var steps = try #require(value["steps"] as? [[String: Any]])
        let last = steps.count - 1
        try tamper.apply(to: &steps, last: last)
        value["steps"] = steps
        let payload = try JSONSerialization.data(withJSONObject: value)
        expectReceiptMismatch(step: last) { _ = try MatchRecord.decode(payload) }
    }

    @Test("Saving a candidate leaves the original disk bytes untouched and reloads both", .tags(.records, .candidate, .persistence))
    func savingCandidateLeavesOriginalDiskBytesUntouchedAndReloadsBoth() throws {
        try TemporaryDirectory.withURL(prefix: "candidate") { directory in
            let repository = RecordRepository(directory: directory)
            let (original, _) = try mageSource()
            try repository.save(original)
            let originalBytes = try Data(contentsOf: repository.url(original.id))
            var candidate = try original.candidateCopy()
            var session = try candidate.rebuild().0
            try append(redeploy(7), record: &candidate, session: &session)
            try repository.save(candidate)
            #expect(repository.url(candidate.id) != repository.url(original.id))
            #expect(try Data(contentsOf: repository.url(original.id)) == originalBytes)
            #expect(try original.encoded() == originalBytes)
            let listing = try RecordRepository(directory: directory).list()
            #expect(listing.rejected == 0)
            #expect(Set(listing.records.map(\.id)) == Set([original.id, candidate.id]))
            let savedCandidate = try #require(listing.records.first { $0.id == candidate.id })
            #expect(try savedCandidate.rebuild().0.state == session.state)
            #expect(Array(savedCandidate.steps.prefix(original.steps.count)) == original.steps)
        }
    }
}
