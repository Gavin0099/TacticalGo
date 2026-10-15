import XCTest
@testable import TacticalGoCore

final class DualMonsterTests: XCTestCase {
    let slime = Point(2,4), wolf = Point(6,4)
    func config(cost: Int = 1) -> RuleConfig {
        var c = RuleConfig.board(size: 9)
        c.monsterBattlefield = MonsterBattlefield(monsters: [MonsterSpawn(.slime, at: slime), MonsterSpawn(.shadowWolf, at: wolf)], huntAPCost: cost, awardsLoot: true)
        return c
    }
    func fixture(cost: Int = 1, ap: Int = 2, stones: [(Point,Character)] = [], monsters: Set<Point>? = nil) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        for p in monsters ?? Set([slime,wolf]) { rows[p.y][p.x] = "M" }
        for (p,ch) in stones { rows[p.y][p.x] = ch }
        return try GameSetup.fromDiagram(config: config(cost:cost), diagram: rows.map { String($0) }.joined(separator:"\n"), classOne:.warrior, manaOne:6, ap:ap)
    }
    var control: [(Point,Character)] { [(Point(1,4),"x"),(Point(3,4),"x"),(Point(5,4),"H"),(Point(7,4),"x")] }
    func reject(_ s: GameState, _ a: GameAction, _ reason: IllegalReason, file: StaticString = #filePath, line: UInt = #line) {
        let o = GameEngine.apply(s,a)
        XCTAssertEqual(o.reason,reason,file:file,line:line); XCTAssertEqual(o.state,s,file:file,line:line); XCTAssertTrue(o.events.isEmpty,file:file,line:line)
    }
    func testSetupRejectsEmptyDuplicateKindPositionThirdEdgeAndCommander() throws {
        let s = try GameSetup.newGame(config:config())
        XCTAssertEqual(s.board.monsters,Set([slime,wolf])); XCTAssertEqual(try Board.parse(s.board.diagram),s.board)
        for spawns in [[],[MonsterSpawn(.slime,at:slime),MonsterSpawn(.slime,at:wolf)],
                       [MonsterSpawn(.slime,at:slime),MonsterSpawn(.shadowWolf,at:slime)],
                       [MonsterSpawn(.slime,at:slime),MonsterSpawn(.shadowWolf,at:wolf),MonsterSpawn(.slime,at:Point(3,3))],
                       [MonsterSpawn(.slime,at:Point(0,4))], [MonsterSpawn(.slime,at:Point(4,7))]] as [[MonsterSpawn]] {
            var c = config(); c.monsterBattlefield = MonsterBattlefield(monsters:spawns)
            XCTAssertThrowsError(try GameSetup.newGame(config:c))
        }
        var unknown = s.board.diagram.split(separator:"\n").map { Array($0) }; unknown[3][3] = "M"
        XCTAssertThrowsError(try GameSetup.fromDiagram(config:config(),diagram:unknown.map { String($0) }.joined(separator:"\n")))
        XCTAssertThrowsError(try GameSetup.fromDiagram(diagram:s.board.diagram))
    }
    func testEachMonsterBlocksLibertiesAndOnlySelectedOneIsRemoved() throws {
        let s = try fixture(stones:control)
        XCTAssertFalse(s.board.isEmpty(slime)); XCTAssertFalse(s.board.isEmpty(wolf))
        XCTAssertFalse(s.board.liberties(at:Point(1,4)).contains(slime))
        XCTAssertFalse(s.board.liberties(at:Point(5,4)).contains(wolf))
        XCTAssertEqual(s.board.group(at:Point(1,4)),[Point(1,4)])
        for p in [slime,wolf] { reject(s,.placeSoldier(p),.occupied) }
        let o = GameEngine.apply(s,.huntMonster(slime)); XCTAssertTrue(o.success)
        XCTAssertEqual(o.state.board.monsters,Set([wolf])); XCTAssertTrue(o.state.board.isEmpty(slime))
        XCTAssertTrue(o.state.board.liberties(at:Point(1,4)).contains(slime))
        XCTAssertFalse(o.state.board.liberties(at:Point(5,4)).contains(wolf))
        XCTAssertEqual(o.state.lootInventory(of:.one),[MonsterLoot(.stickyBounce,unlockPly:3)])
    }
    func testWolfRequirementAndControlAreSpecificToTarget() throws {
        let s = try fixture(stones:[(Point(1,4),"H"),(Point(3,4),"x"),(Point(5,4),"x"),(Point(7,4),"x")])
        XCTAssertTrue(GameEngine.apply(s,.huntMonster(slime)).success)
        reject(s,.huntMonster(wolf),.noHeroOnBoard) // hero beside slime doesn't satisfy wolf
        let tie = try fixture(stones:control + [(Point(6,3),"o"),(Point(6,5),"o")])
        reject(tie,.huntMonster(wolf),.insufficientMonsterControl)
        XCTAssertTrue(GameEngine.apply(tie,.huntMonster(slime)).success)
    }
    func testBothLootOrdersRetainBothAndUndoSecondHunt() throws {
        for order in [[slime,wolf],[wolf,slime]] {
            var session = GameSession(try fixture(stones:control))
            XCTAssertTrue(session.apply(.huntMonster(order[0])).success); let before = session.state
            let second = session.apply(.huntMonster(order[1])); XCTAssertTrue(second.success)
            let expected: [MonsterAbility] = order[0] == slime ? [.stickyBounce,.shadowStep] : [.shadowStep,.stickyBounce]
            XCTAssertEqual(session.state.lootInventory(of:.one).map(\.ability),expected)
            XCTAssertTrue(session.state.lootInventory(of:.two).isEmpty)
            XCTAssertTrue(session.state.board.monsters.isEmpty)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,before)
        }
    }
    func testIndependentUnlockAndUseOnlyConsumesSelectedAbilityAndSharedBudget() throws {
        var s = try fixture(stones:[(Point(1,4),"x"),(Point(1,5),"x"),(Point(5,4),"H")],monsters:[])
        s.monsterLoot[0] = [MonsterLoot(.stickyBounce,unlockPly:1),MonsterLoot(.shadowStep,unlockPly:3)]
        reject(s,.useShadowStep(Point(5,2)),.monsterLootLocked)
        let bounce = GameAction.useStickyBounce(anchor:Point(1,5),target:Point(1,4))
        let o = GameEngine.apply(s,bounce); XCTAssertTrue(o.success)
        XCTAssertEqual(o.state.lootInventory(of:.one),[MonsterLoot(.shadowStep,unlockPly:3)])
        XCTAssertEqual(o.state.apRemaining,1); XCTAssertTrue(o.state.skillUsedThisTurn)
        s.monsterLoot[0][1] = MonsterLoot(.shadowStep,unlockPly:1)
        for ability in [bounce,.useShadowStep(Point(5,2))] {
            var session = GameSession(s); XCTAssertTrue(session.apply(ability).success)
            let other: GameAction = ability == bounce ? .useShadowStep(Point(5,2)) : bounce
            reject(session.state,other,.skillAlreadyUsed)
            XCTAssertEqual(session.state.lootInventory(of:.one).count,1)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,s)
        }
        reject(s,.useShadowStep(Point(6,3)),.outOfRange)
    }
    func testSplitOwnershipDoesNotBorrowOpponentsAbility() throws {
        let mixed = [(Point(1,4),Character("x")),(Point(3,4),"x"),(Point(5,4),"Q"),(Point(7,4),"o")]
        var session = GameSession(try fixture(stones:mixed))
        XCTAssertTrue(session.apply(.huntMonster(slime)).success)
        XCTAssertTrue(session.apply(.endTurn).success)
        XCTAssertTrue(session.apply(.huntMonster(wolf)).success)
        XCTAssertEqual(session.state.lootInventory(of:.one),[MonsterLoot(.stickyBounce,unlockPly:3)])
        XCTAssertEqual(session.state.lootInventory(of:.two),[MonsterLoot(.shadowStep,unlockPly:4)])
        reject(session.state,.useStickyBounce(anchor:Point(7,4),target:Point(5,4)),.noMonsterLoot)
        XCTAssertTrue(session.apply(.endTurn).success)
        reject(session.state,.useShadowStep(Point(5,2)),.noMonsterLoot)
    }
    func testZeroAPWindowCanHuntBothOrHuntOneThenSkipAndUndo() throws {
        for order in [[slime,wolf],[wolf,slime]] {
            var session = GameSession(try fixture(cost:0,ap:1,stones:control))
            XCTAssertTrue(session.apply(.placeSoldier(Point(0,0))).success)
            XCTAssertTrue(session.state.awaitingFreeHunt); XCTAssertEqual(session.state.apRemaining,0)
            XCTAssertTrue(session.apply(.huntMonster(order[0])).success)
            let oneLeft = session.state
            XCTAssertTrue(oneLeft.awaitingFreeHunt); XCTAssertEqual(oneLeft.current,.one)
            XCTAssertEqual(GameEngine.legalActions(oneLeft),[.huntMonster(order[1]),.endTurn])
            reject(oneLeft,.placeSoldier(Point(0,1)),.noActionPoints)
            XCTAssertTrue(session.apply(.huntMonster(order[1])).success)
            XCTAssertEqual(session.state.current,.two); XCTAssertFalse(session.state.awaitingFreeHunt)
            XCTAssertEqual(session.state.lootInventory(of:.one).count,2)
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,oneLeft)
            XCTAssertTrue(session.apply(.endTurn).success)
            XCTAssertEqual(session.state.board.monsters,Set([order[1]])); XCTAssertEqual(session.state.current,.two)
        }
    }
    func testFreeWindowChecksAllTargetsAndKoIncludesRemainingMonster() throws {
        var s = try fixture(cost:0,ap:1,stones:control)
        var repeated = s.board; repeated[Point(0,0)] = Piece(.one,.soldier); repeated.monsters.remove(slime)
        s.history.insert(repeated.diagram)
        let after = GameEngine.apply(s,.placeSoldier(Point(0,0))).state
        XCTAssertTrue(after.awaitingFreeHunt) // first target fails Ko; second remains legal
        reject(after,.huntMonster(slime),.ko)
        XCTAssertTrue(GameEngine.legalActions(after).contains(.huntMonster(wolf)))
        let hunted = GameEngine.apply(after,.huntMonster(wolf)); XCTAssertTrue(hunted.success)
        XCTAssertTrue(hunted.state.awaitingFreeHunt) // earlier key retained wolf, so slime is now a different board
        XCTAssertTrue(GameEngine.apply(hunted.state,.huntMonster(slime)).success)
    }
    func testOtherMonsterBlocksBothLootMovesWithoutConsumingEither() throws {
        var s = try fixture(stones:[(Point(4,4),"x"),(Point(5,4),"x"),(Point(7,4),"H")])
        s.monsterLoot[0] = [MonsterLoot(.stickyBounce,unlockPly:1),MonsterLoot(.shadowStep,unlockPly:1)]
        reject(s,.useStickyBounce(anchor:Point(4,4),target:Point(5,4)),.occupied)
        reject(s,.useShadowStep(Point(5,4)),.occupied)
        reject(s,.useShadowStep(wolf),.occupied)
        XCTAssertEqual(s.lootInventory(of:.one).count,2)
    }
    func testSeparateAcquisitionTurnsKeepDistinctUnlockTimes() throws {
        var session = GameSession(try fixture(stones:control))
        for a: GameAction in [.huntMonster(slime),.endTurn,.endTurn,.huntMonster(wolf)] { XCTAssertTrue(session.apply(a).success) }
        XCTAssertEqual(session.state.ply,3)
        XCTAssertEqual(session.state.lootInventory(of:.one),[MonsterLoot(.stickyBounce,unlockPly:3),MonsterLoot(.shadowStep,unlockPly:5)])
        reject(session.state,.useShadowStep(Point(5,2)),.monsterLootLocked)
    }
    func testCommanderVictoryPrecedesBothFreeHuntChoices() throws {
        let s = try fixture(cost:0,ap:1,stones:control + [(Point(3,1),"x"),(Point(5,1),"x"),(Point(4,0),"x")])
        let o = GameEngine.apply(s,.placeSoldier(Point(4,2)))
        XCTAssertTrue(o.success); XCTAssertEqual(o.state.status,.won); XCTAssertEqual(o.state.winner,.one)
        XCTAssertEqual(o.state.current,.one); XCTAssertFalse(o.state.awaitingFreeHunt)
        XCTAssertEqual(o.state.board.monsters,Set([slime,wolf])); XCTAssertTrue(o.state.lootInventory(of:.one).isEmpty)
        XCTAssertEqual(o.events.last,.gameWon(.one)); XCTAssertTrue(GameEngine.legalActions(o.state).isEmpty)
    }
    func testLegalOpeningBothOrdersCostsUseUndoAndReplay() throws {
        for cost in [0,1] { for order in [[slime,wolf],[wolf,slime]] {
            let initial = try GameSetup.newGame(config:config(cost:cost),classOne:.warrior,classTwo:.mage)
            var session = GameSession(initial)
            let opening: [GameAction] = [.placeSoldier(Point(1,4)),.placeSoldier(Point(0,0)),.endTurn,
                .placeSoldier(Point(3,4)),.placeSoldier(Point(5,5)),.endTurn,
                .summonHero(Point(5,4)),.placeSoldier(Point(7,4)),.endTurn]
            for a in opening {
                if a == .endTurn && session.state.awaitingFreeHunt { XCTAssertTrue(session.apply(.endTurn).success) }
                XCTAssertTrue(session.apply(a).success)
            }
            XCTAssertEqual(session.state.ply,7)
            for p in order { XCTAssertTrue(session.apply(.huntMonster(p)).success) }
            if cost == 0 { XCTAssertTrue(session.apply(.endTurn).success) }
            XCTAssertTrue(session.apply(.endTurn).success)
            for a: GameAction in [.placeSoldier(Point(1,5)),.endTurn,.endTurn] { XCTAssertTrue(session.apply(a).success) }
            let before = session.state
            let bounce = GameAction.useStickyBounce(anchor:Point(1,5),target:Point(1,4))
            let step = GameAction.useShadowStep(Point(5,2))
            XCTAssertTrue(GameEngine.legalActions(before).contains(bounce)); XCTAssertTrue(GameEngine.legalActions(before).contains(step))
            XCTAssertTrue(session.apply(step).success)
            XCTAssertEqual(session.state.lootInventory(of:.one).map(\.ability),[.stickyBounce])
            XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,before)
            XCTAssertTrue(session.apply(bounce).success)
            XCTAssertEqual(session.state.lootInventory(of:.one).map(\.ability),[.shadowStep])
            var replay = GameSession(initial)
            for a in session.log { XCTAssertTrue(replay.apply(a).success) }
            XCTAssertEqual(replay.state,session.state)
        } }
    }
}
