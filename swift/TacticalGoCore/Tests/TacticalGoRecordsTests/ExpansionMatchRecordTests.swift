import XCTest
import Foundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords
final class ExpansionMatchRecordTests: XCTestCase {
    func testSoloMetadataRoundtripLegacyDefaultAndInvalidMetadataReject() throws {
        let session = try ExpansionPractice.mage.session()
        for player in Player.allCases { for difficulty in ["easy","standard"] {
            let bytes = try ExpansionMatchRecord(session:session,computer:player,difficulty:difficulty).data()
            let record = try ExpansionMatchRecord.read(bytes)
            XCTAssertEqual(record.computer,player);XCTAssertEqual(record.difficulty,difficulty)
            XCTAssertEqual(try record.rebuild().state,session.state)
        } }
        let bytes = try ExpansionMatchRecord(session:session).data()
        XCTAssertNil(try ExpansionMatchRecord.read(bytes).computer)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with:bytes) as? [String:Any])
        object["difficulty"] = "cheat"
        XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:object)))
        object.removeValue(forKey:"difficulty");object["computer"] = 7
        XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:object)))
    }
    func testLegacySanctuaryReplayKeepsReinforcementWhileOfferingDoesNot() throws {
        let before = try ExpansionPractice.priest.session()
        var old = before
        XCTAssertTrue(old.apply(.castSanctuary(sacrifice:Point(4,5),destination:Point(4,6))).success)
        let bytes = try ExpansionMatchRecord(session:old).data()
        let replay = try ExpansionMatchRecord.read(bytes).rebuild()
        XCTAssertEqual(replay.state,old.state);XCTAssertEqual(replay.state.board[Point(4,6)],Piece(.one,.soldier))
        var current = before;XCTAssertTrue(current.apply(.castOffering(Point(4,5))).success)
        XCTAssertNil(current.state.board[Point(4,6)])
        XCTAssertEqual(try ExpansionMatchRecord.read(ExpansionMatchRecord(session:current).data()).rebuild().state,current.state)
        var malformed = try XCTUnwrap(JSONSerialization.jsonObject(with:ExpansionMatchRecord(session:current).data()) as? [String:Any])
        var actions = malformed["actions"] as! [[String:Any]]
        actions[actions.count-1]["points"] = [["x":4,"y":5],["x":4,"y":6]]
        malformed["actions"] = actions
        XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:malformed)))
    }
    func testAllNewSkillsReachableRoundtripStateHistoryAndUndo() throws {
        for f in ExpansionPractice.allCases { for cost in [4,5] {
            var s = try f.session(cost:cost); let before = s.state
            XCTAssertTrue(s.apply(f.action).success)
            let r = try ExpansionMatchRecord(session:s),data = try r.data()
            var loaded = try ExpansionMatchRecord.read(data).rebuild()
            XCTAssertEqual(loaded.state,s.state); XCTAssertEqual(loaded.log,s.log)
            XCTAssertTrue(loaded.undo()); XCTAssertEqual(loaded.state,before)
            XCTAssertEqual(loaded.apply(f.action),GameEngine.apply(before,f.action))
        } }
        var challenge = try PriestSanctuaryChallenge.session()
        XCTAssertTrue(challenge.apply(PriestSanctuaryChallenge.action).success)
        XCTAssertEqual(try ExpansionMatchRecord.read(ExpansionMatchRecord(session:challenge).data()).rebuild().state,challenge.state)
    }
    func testMonsterOccupancyHuntDelayedLootAndSpendSurviveReloadBothCosts() throws {
        for ap in [0,1] {
            var c = RuleConfig.board(size:9);c.expansionSkills = true;c.monsterBattlefield = .init(huntAPCost:ap,awardsLoot:true)
            var s = GameSession(try GameSetup.newGame(config:c,classOne:.mage,classTwo:.rogue))
            for a in [GameAction.placeSoldier(Point(4,3)),.endTurn,.placeSoldier(Point(3,4)),.huntMonster(Point(4,4))] { XCTAssertTrue(s.apply(a).success) }
            XCTAssertFalse(s.state.board.monsters.contains(Point(4,4)))
            XCTAssertEqual(s.state.lootInventory(of:.one).count,1)
            var loaded = try ExpansionMatchRecord.read(ExpansionMatchRecord(session:s).data()).rebuild()
            XCTAssertEqual(loaded.state,s.state)
            while loaded.state.current != .one || loaded.state.ply < loaded.state.lootInventory(of:.one)[0].unlockPly { XCTAssertTrue(loaded.apply(.endTurn).success) }
            // F4 is empty: support D5/E5? Retain exact two adjacent placements first.
            XCTAssertTrue(loaded.apply(.placeSoldier(Point(4,2))).success)
            while loaded.state.current != .one { XCTAssertTrue(loaded.apply(.endTurn).success) }
            let action = GameAction.useStickyBounce(anchor:Point(4,2),target:Point(4,3))
            XCTAssertTrue(loaded.apply(action).success)
            XCTAssertTrue(loaded.state.lootInventory(of:.one).isEmpty)
            XCTAssertEqual(try ExpansionMatchRecord.read(ExpansionMatchRecord(session:loaded).data()).rebuild().state,loaded.state)
        }
    }
    func testMalformedVersionRulesDimensionsActionsAndSnapshotRejectWithoutMutatingOwner() throws {
        let session = try ExpansionPractice.mage.session()
        let data = try ExpansionMatchRecord(session:session).data(),before = session.state
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with:data) as? [String:Any])
        func reject(_ mutate: (inout [String:Any])->Void) throws {
            var object = original;mutate(&object)
            XCTAssertThrowsError(try ExpansionMatchRecord.read(JSONSerialization.data(withJSONObject:object)))
            XCTAssertEqual(session.state,before)
        }
        try reject { $0["version"] = 2 }
        try reject { $0["rules"] = "original" }
        try reject { $0["size"] = 1000000 }
        try reject { $0["advancedMana"] = 0 }
        try reject { $0["classOne"] = "None" }
        try reject { $0["monsters"] = [["kind":"dragon","at":["x":4,"y":4]]];$0["huntAP"] = 1 }
        try reject { $0["actions"] = [["kind":"end","points":[["x":0,"y":0]]]] }
        try reject { $0["actions"] = [["kind":"hand","points":[["x":0,"y":0]],"direction":"Invalid"]] }
        try reject { $0["actions"] = [["kind":"doublePull","points":[]]] }
        try reject { $0["actions"] = Array(repeating:["kind":"end","points":[]],count:501) }
        try reject { $0["actions"] = [] }
        try reject { var expected = $0["expected"] as! [String:Any];expected["mana"] = [99,99];$0["expected"] = expected }
        XCTAssertThrowsError(try ExpansionMatchRecord.read(Data(repeating:32,count:ExpansionMatchRecord.byteLimit+1)))
    }
    func testDiagramFixturesNonCandidateRulesAndLegacySchemaCannotBeSilentlySaved() throws {
        var c = RuleConfig.board(size:9);c.expansionSkills = true
        let fixture = try GameSetup.fromDiagram(config:c,diagram:".........\n....O....\n.........\n.........\n...H.....\n.........\n.........\n....X....\n.........",classOne:.mage,classTwo:.rogue)
        XCTAssertThrowsError(try ExpansionMatchRecord(session:GameSession(fixture)))
        var old = RuleConfig.board(size:7)
        XCTAssertThrowsError(try ExpansionMatchRecord(session:GameSession(GameSetup.newGame(config:old,classOne:.warrior,classTwo:.mage))))
        old.expansionSkills = true;old.manaCap = 9
        XCTAssertThrowsError(try ExpansionMatchRecord(session:GameSession(GameSetup.newGame(config:old,classOne:.warrior,classTwo:.mage))))
        XCTAssertThrowsError(try ExpansionMatchRecord.read(Data(#"{"version":1}"#.utf8)))
    }
}
