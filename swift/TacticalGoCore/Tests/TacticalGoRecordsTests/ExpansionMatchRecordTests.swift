import Testing
import Foundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

@Suite
struct ExpansionMatchRecordTests {
    @Test(.tags(.roundTrip), arguments: Player.allCases, ["easy", "standard"])
    func testSoloMetadataRoundtrip(_ player: Player, _ difficulty: String) throws {
        let session = try ExpansionPractice.mage.session()
        let bytes = try ExpansionMatchRecord(session: session, computer: player, difficulty: difficulty).data()
        let record = try ExpansionMatchRecord.read(bytes)
        #expect(record.computer == player)
        #expect(record.difficulty == difficulty)
        #expect(try record.rebuild().state == session.state)
    }

    @Test(.tags(.rejection))
    func testLegacyDefaultAndInvalidMetadataReject() throws {
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
        let badComputer = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(badComputer)
        }
    }

    @Test(.tags(.roundTrip))
    func testLegacySanctuaryReplayKeepsReinforcementWhileOfferingDoesNot() throws {
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
        #expect(try ExpansionMatchRecord.read(ExpansionMatchRecord(session: current).data()).rebuild().state == current.state)
        var malformed = try #require(JSONSerialization.jsonObject(with: ExpansionMatchRecord(session: current).data()) as? [String: Any])
        var actions = malformed["actions"] as! [[String: Any]]
        actions[actions.count - 1]["points"] = [["x": 4, "y": 5], ["x": 4, "y": 6]]
        malformed["actions"] = actions
        let payload = try JSONSerialization.data(withJSONObject: malformed)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(payload)
        }
    }

    // PRIEST-S2-P0: the second skill records as its own kind and replays with the second-skill cost.
    @Test(.tags(.roundTrip))
    func testSanctumRecordsAsItsOwnKindAndReplaysWithTheSecondSkillCost() throws {
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
        let kinds = (object["actions"] as? [[String: Any]] ?? []).compactMap { $0["kind"] as? String }
        #expect(kinds.contains("sanctum"))
        #expect(kinds.contains("sanctuary") == false)
        let replay = try ExpansionMatchRecord.read(bytes).rebuild()
        #expect(replay.state == session.state)
    }

    @Test(.tags(.roundTrip), arguments: ExpansionPractice.allCases, [4, 5])
    func testAllNewSkillsReachableRoundtripStateHistoryAndUndo(_ practice: ExpansionPractice, _ cost: Int) throws {
        var s = try practice.session(cost: cost)
        let before = s.state
        #expect(s.apply(practice.action).success)
        let r = try ExpansionMatchRecord(session: s), data = try r.data()
        var loaded = try ExpansionMatchRecord.read(data).rebuild()
        #expect(loaded.state == s.state)
        #expect(loaded.log == s.log)
        let didUndo = loaded.undo()
        #expect(didUndo)
        #expect(loaded.state == before)
        #expect(loaded.apply(practice.action) == GameEngine.apply(before, practice.action))
    }

    @Test(.tags(.roundTrip))
    func testPriestSanctuaryChallengeRoundTrips() throws {
        var challenge = try PriestSanctuaryChallenge.session()
        #expect(challenge.apply(PriestSanctuaryChallenge.action).success)
        #expect(try ExpansionMatchRecord.read(ExpansionMatchRecord(session: challenge).data()).rebuild().state == challenge.state)
    }

    @Test(.tags(.roundTrip), arguments: [0, 1])
    func testMonsterOccupancyHuntDelayedLootAndSpendSurviveReloadBothCosts(_ ap: Int) throws {
        var c = RuleConfig.board(size: 9)
        c.expansionSkills = true
        c.monsterBattlefield = .init(huntAPCost: ap, awardsLoot: true)
        var s = GameSession(try GameSetup.newGame(config: c, classOne: .mage, classTwo: .rogue))
        for a in [GameAction.placeSoldier(Point(4, 3)), .endTurn, .placeSoldier(Point(3, 4)), .huntMonster(Point(4, 4))] {
            #expect(s.apply(a).success)
        }
        #expect(s.state.board.monsters.contains(Point(4, 4)) == false)
        #expect(s.state.lootInventory(of: .one).count == 1)
        var loaded = try ExpansionMatchRecord.read(ExpansionMatchRecord(session: s).data()).rebuild()
        #expect(loaded.state == s.state)
        while loaded.state.current != .one || loaded.state.ply < loaded.state.lootInventory(of: .one)[0].unlockPly {
            #expect(loaded.apply(.endTurn).success)
        }
        // F4 is empty: support D5/E5? Retain exact two adjacent placements first.
        #expect(loaded.apply(.placeSoldier(Point(4, 2))).success)
        while loaded.state.current != .one { #expect(loaded.apply(.endTurn).success) }
        let action = GameAction.useStickyBounce(anchor: Point(4, 2), target: Point(4, 3))
        #expect(loaded.apply(action).success)
        #expect(loaded.state.lootInventory(of: .one).isEmpty)
        #expect(try ExpansionMatchRecord.read(ExpansionMatchRecord(session: loaded).data()).rebuild().state == loaded.state)
    }

    @Test(.tags(.rejection))
    func testMalformedVersionRulesDimensionsActionsAndSnapshotRejectWithoutMutatingOwner() throws {
        let session = try ExpansionPractice.mage.session()
        let data = try ExpansionMatchRecord(session: session).data(), before = session.state
        let original = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        func reject(_ mutate: (inout [String: Any]) -> Void) throws {
            var object = original
            mutate(&object)
            let payload = try JSONSerialization.data(withJSONObject: object)
            #expect(throws: (any Error).self) {
                try ExpansionMatchRecord.read(payload)
            }
            #expect(session.state == before)
        }
        try reject { $0["version"] = 2 }
        try reject { $0["rules"] = "original" }
        try reject { $0["size"] = 1000000 }
        try reject { $0["advancedMana"] = 0 }
        try reject { $0["classOne"] = "None" }
        try reject { $0["monsters"] = [["kind": "dragon", "at": ["x": 4, "y": 4]]]; $0["huntAP"] = 1 }
        try reject { $0["actions"] = [["kind": "end", "points": [["x": 0, "y": 0]]]] }
        try reject { $0["actions"] = [["kind": "hand", "points": [["x": 0, "y": 0]], "direction": "Invalid"]] }
        try reject { $0["actions"] = [["kind": "doublePull", "points": []]] }
        try reject { $0["actions"] = Array(repeating: ["kind": "end", "points": []], count: 501) }
        try reject { $0["actions"] = [] }
        try reject { var expected = $0["expected"] as! [String: Any]; expected["mana"] = [99, 99]; $0["expected"] = expected }
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(Data(repeating: 32, count: ExpansionMatchRecord.byteLimit + 1))
        }
    }

    @Test(.tags(.rejection))
    func testDiagramFixturesNonCandidateRulesAndLegacySchemaCannotBeSilentlySaved() throws {
        var c = RuleConfig.board(size: 9)
        c.expansionSkills = true
        let fixture = try GameSetup.fromDiagram(config: c, diagram: ".........\n....O....\n.........\n.........\n...H.....\n.........\n.........\n....X....\n.........", classOne: .mage, classTwo: .rogue)
        let diagramSession = GameSession(fixture)
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: diagramSession)
        }
        var old = RuleConfig.board(size: 7)
        let classicConfig = old
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: GameSession(try GameSetup.newGame(config: classicConfig, classOne: .warrior, classTwo: .mage)))
        }
        old.expansionSkills = true
        old.manaCap = 9
        let legacyManaConfig = old
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord(session: GameSession(try GameSetup.newGame(config: legacyManaConfig, classOne: .warrior, classTwo: .mage)))
        }
        #expect(throws: (any Error).self) {
            try ExpansionMatchRecord.read(Data(#"{"version":1}"#.utf8))
        }
    }
}
