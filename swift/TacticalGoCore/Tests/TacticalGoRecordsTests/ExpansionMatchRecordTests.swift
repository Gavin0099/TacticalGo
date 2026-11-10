import Foundation
import Testing
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

enum ExpansionPayloadRejection: Sendable, CustomTestStringConvertible {
    case version
    case rules
    case size
    case advancedMana
    case classOne
    case monsters
    case endWithPoints
    case invalidDirection
    case emptyDoublePull
    case tooManyActions
    case emptyActions
    case manaSnapshot

    var testDescription: String {
        switch self {
        case .version: "version 2"
        case .rules: "original rules"
        case .size: "size 1000000"
        case .advancedMana: "advanced mana 0"
        case .classOne: "class None"
        case .monsters: "dragon monster"
        case .endWithPoints: "end action with points"
        case .invalidDirection: "invalid hand direction"
        case .emptyDoublePull: "double pull without points"
        case .tooManyActions: "501 end actions"
        case .emptyActions: "empty actions"
        case .manaSnapshot: "expected mana 99"
        }
    }

    func apply(_ object: inout [String: Any]) throws {
        switch self {
        case .version: object["version"] = 2
        case .rules: object["rules"] = "original"
        case .size: object["size"] = 1000000
        case .advancedMana: object["advancedMana"] = 0
        case .classOne: object["classOne"] = "None"
        case .monsters:
            object["monsters"] = [["kind": "dragon", "at": ["x": 4, "y": 4]]]
            object["huntAP"] = 1
        case .endWithPoints:
            object["actions"] = [["kind": "end", "points": [["x": 0, "y": 0]]]]
        case .invalidDirection:
            object["actions"] = [["kind": "hand", "points": [["x": 0, "y": 0]], "direction": "Invalid"]]
        case .emptyDoublePull:
            object["actions"] = [["kind": "doublePull", "points": []]]
        case .tooManyActions:
            object["actions"] = Array(repeating: ["kind": "end", "points": []], count: 501)
        case .emptyActions:
            object["actions"] = []
        case .manaSnapshot:
            var expected = try #require(object["expected"] as? [String: Any])
            expected["mana"] = [99, 99]
            object["expected"] = expected
        }
    }
}

@Suite("Expansion match records", .tags(.records, .expansion))
struct ExpansionMatchRecordTests {
    @Test("Solo computer and difficulty round-trip", arguments: Player.allCases, ["easy", "standard"])
    func soloMetadataRoundTrip(player: Player, difficulty: String) throws {
        let session = try ExpansionPractice.mage.session()
        let bytes = try ExpansionMatchRecord(session: session, computer: player, difficulty: difficulty).data()
        let record = try ExpansionMatchRecord.read(bytes)
        #expect(record.computer == player)
        #expect(record.difficulty == difficulty)
        #expect(try record.rebuild().state == session.state)
    }

    @Test("A missing computer stays nil, and invalid metadata is rejected")
    func legacyDefaultAndInvalidMetadataReject() throws {
        let session = try ExpansionPractice.mage.session()
        let bytes = try ExpansionMatchRecord(session: session).data()
        #expect(try ExpansionMatchRecord.read(bytes).computer == nil)
        var object = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        object["difficulty"] = "cheat"
        let cheat = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(cheat)
        }
        object.removeValue(forKey: "difficulty")
        object["computer"] = 7
        let computer = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(computer)
        }
    }

    @Test("Legacy sanctuary replay keeps reinforcement, and offering does not")
    func legacySanctuaryReplayKeepsReinforcementWhileOfferingDoesNot() throws {
        let before = try ExpansionPractice.priest.session()
        var old = before
        #expect(old.apply(.castSanctuary(sacrifice: Point(4, 5), destination: Point(4, 6))).success)
        let bytes = try ExpansionMatchRecord(session: old).data()
        let replay = try ExpansionMatchRecord.read(bytes).rebuild()
        #expect(replay.state == old.state)
        #expect(replay.state.board[Point(4, 6)] == Piece(.one, .soldier))
        var current = before
        #expect(current.apply(.castOffering(Point(4, 5))).success)
        #expect(current.state.board[Point(4, 6)] == nil)
        let offering = try ExpansionMatchRecord(session: current).data()
        #expect(try ExpansionMatchRecord.read(offering).rebuild().state == current.state)
        var malformed = try #require(JSONSerialization.jsonObject(with: offering) as? [String: Any])
        var actions = try #require(malformed["actions"] as? [[String: Any]])
        actions[actions.count - 1]["points"] = [["x": 4, "y": 5], ["x": 4, "y": 6]]
        malformed["actions"] = actions
        let payload = try JSONSerialization.data(withJSONObject: malformed)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
    }

    // PRIEST-S2-P0: the second skill records as its own kind and replays with the second-skill cost.
    @Test("Sanctum records as its own kind and replays with the second-skill cost")
    func sanctumRecordsAsItsOwnKindAndReplaysWithTheSecondSkillCost() throws {
        // Records replay from a real opening, so this uses the legal priest opening rather than the diagram lesson.
        var session = try ExpansionPractice.priest.session()
        while session.state.mana(of: .one) < 4 {
            #expect(session.apply(.endTurn).success)
            #expect(session.apply(.endTurn).success)
        }
        let manaBefore = session.state.mana(of: .one)
        #expect(session.apply(.castSanctum(sacrifice: Point(4, 5), destination: Point(4, 6))).success)
        #expect(session.state.mana(of: .one) == manaBefore - 4)
        let bytes = try ExpansionMatchRecord(session: session).data()
        let object = try #require(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        let actions = try #require(object["actions"] as? [[String: Any]])
        let kinds = actions.compactMap { $0["kind"] as? String }
        #expect(kinds.contains("sanctum"))
        #expect(kinds.contains("sanctuary") == false)
        let replay = try ExpansionMatchRecord.read(bytes).rebuild()
        #expect(replay.state == session.state)
    }

    @Test("Each new skill round-trips state, history, and undo", arguments: ExpansionPractice.allCases, [4, 5])
    func allNewSkillsReachableRoundtripStateHistoryAndUndo(practice: ExpansionPractice, cost: Int) throws {
        var session = try practice.session(cost: cost)
        let before = session.state
        #expect(session.apply(practice.action).success)
        let data = try ExpansionMatchRecord(session: session).data()
        var loaded = try ExpansionMatchRecord.read(data).rebuild()
        #expect(loaded.state == session.state)
        #expect(loaded.log == session.log)
        let undone = loaded.undo()
        #expect(undone)
        #expect(loaded.state == before)
        #expect(loaded.apply(practice.action) == GameEngine.apply(before, practice.action))
    }

    @Test("The priest sanctuary challenge round-trips")
    func priestSanctuaryChallengeRoundTrips() throws {
        var challenge = try PriestSanctuaryChallenge.session()
        #expect(challenge.apply(PriestSanctuaryChallenge.action).success)
        let data = try ExpansionMatchRecord(session: challenge).data()
        #expect(try ExpansionMatchRecord.read(data).rebuild().state == challenge.state)
    }

    @Test("Monster occupancy, hunt, delayed loot, and spend survive reload", arguments: [0, 1])
    func monsterOccupancyHuntDelayedLootAndSpendSurviveReload(huntAPCost: Int) throws {
        var config = RuleConfig.board(size: 9)
        config.expansionSkills = true
        config.monsterBattlefield = .init(huntAPCost: huntAPCost, awardsLoot: true)
        var session = GameSession(try GameSetup.newGame(config: config, classOne: .mage, classTwo: .rogue))
        for action in [GameAction.placeSoldier(Point(4, 3)), .endTurn, .placeSoldier(Point(3, 4)), .huntMonster(Point(4, 4))] {
            #expect(session.apply(action).success)
        }
        #expect(session.state.board.monsters.contains(Point(4, 4)) == false)
        #expect(session.state.lootInventory(of: .one).count == 1)
        var loaded = try ExpansionMatchRecord.read(ExpansionMatchRecord(session: session).data()).rebuild()
        #expect(loaded.state == session.state)
        while loaded.state.current != .one || loaded.state.ply < loaded.state.lootInventory(of: .one)[0].unlockPly {
            #expect(loaded.apply(.endTurn).success)
        }
        // F4 is empty: support D5/E5? Retain exact two adjacent placements first.
        #expect(loaded.apply(.placeSoldier(Point(4, 2))).success)
        while loaded.state.current != .one {
            #expect(loaded.apply(.endTurn).success)
        }
        let action = GameAction.useStickyBounce(anchor: Point(4, 2), target: Point(4, 3))
        #expect(loaded.apply(action).success)
        #expect(loaded.state.lootInventory(of: .one).isEmpty)
        let reloaded = try ExpansionMatchRecord.read(ExpansionMatchRecord(session: loaded).data()).rebuild()
        #expect(reloaded.state == loaded.state)
    }

    @Test("A malformed payload is rejected without mutating the owner session", arguments: [
        ExpansionPayloadRejection.version,
        .rules,
        .size,
        .advancedMana,
        .classOne,
        .monsters,
        .endWithPoints,
        .invalidDirection,
        .emptyDoublePull,
        .tooManyActions,
        .emptyActions,
        .manaSnapshot
    ])
    func malformedVersionRulesDimensionsActionsAndSnapshotRejectWithoutMutatingOwner(_ rejection: ExpansionPayloadRejection) throws {
        let session = try ExpansionPractice.mage.session()
        let data = try ExpansionMatchRecord(session: session).data()
        let before = session.state
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        try rejection.apply(&object)
        let payload = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
        #expect(session.state == before)
    }

    @Test("Bytes over the record limit are rejected")
    func oversizedRecordIsRejected() {
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(Data(repeating: 32, count: ExpansionMatchRecord.byteLimit + 1))
        }
    }

    @Test("Diagram fixtures, non-candidate rules, and a legacy schema cannot be silently saved")
    func diagramFixturesNonCandidateRulesAndLegacySchemaCannotBeSilentlySaved() throws {
        var config = RuleConfig.board(size: 9)
        config.expansionSkills = true
        let fixture = try GameSetup.fromDiagram(
            config: config,
            diagram: ".........\n....O....\n.........\n.........\n...H.....\n.........\n.........\n....X....\n.........",
            classOne: .mage,
            classTwo: .rogue
        )
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: GameSession(fixture))
        }
        var old = RuleConfig.board(size: 7)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: GameSession(GameSetup.newGame(config: old, classOne: .warrior, classTwo: .mage)))
        }
        old.expansionSkills = true
        old.manaCap = 9
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: GameSession(GameSetup.newGame(config: old, classOne: .warrior, classTwo: .mage)))
        }
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(Data(#"{"version":1}"#.utf8))
        }
    }
}
