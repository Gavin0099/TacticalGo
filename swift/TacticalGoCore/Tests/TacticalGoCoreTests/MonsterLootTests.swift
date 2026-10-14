import XCTest
@testable import TacticalGoCore

final class MonsterLootTests: XCTestCase {
    let center = Point(4, 4)
    func config(_ kind: MonsterKind = .slime, cost: Int = 1, awards: Bool = true) -> RuleConfig {
        var c = RuleConfig.board(size: 9)
        c.monsterBattlefield = MonsterBattlefield(huntAPCost: cost, kind: kind, awardsLoot: awards)
        return c
    }
    func position(_ stones: [(Point, Character)] = [], kind: MonsterKind = .slime,
                  ready: Bool = true, monster: Bool = false, hero: HeroClass = .warrior) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"; rows[1][4] = "O"
        if monster { rows[4][4] = "M" }
        for (p, s) in stones { rows[p.y][p.x] = s }
        var s = try GameSetup.fromDiagram(config: config(kind), diagram: rows.map { String($0) }.joined(separator: "\n"),
                                          classOne: hero, manaOne: 0, ap: 2)
        if ready { s.monsterLoot[0] = [MonsterLoot(kind == .slime ? .stickyBounce : .shadowStep, unlockPly: 1)] }
        return s
    }
    func rejected(_ s: GameState, _ a: GameAction, _ reason: IllegalReason, file: StaticString = #filePath, line: UInt = #line) {
        let o = GameEngine.apply(s, a)
        XCTAssertEqual(o.reason, reason, file: file, line: line)
        XCTAssertEqual(o.state, s, file: file, line: line); XCTAssertTrue(o.events.isEmpty, file: file, line: line)
    }
    func opening(_ kind: MonsterKind, cost: Int = 1, at: Point = Point(4,4)) throws -> GameSession {
        var c = config(kind, cost: cost); c.monsterBattlefield = MonsterBattlefield(at: at, huntAPCost: cost, kind: kind, awardsLoot: true)
        var s = GameSession(try GameSetup.newGame(config: c, classOne: .warrior, classTwo: .mage))
        let actions: [GameAction] = kind == .slime
            ? [.placeSoldier(Point(at.x-1,4)), .placeSoldier(Point(0,0)), .endTurn, .placeSoldier(Point(at.x+1,4))]
            : [.placeSoldier(Point(at.x-1,5)), .placeSoldier(Point(0,0)), .endTurn, .summonHero(Point(at.x-1,4)), .endTurn, .endTurn, .placeSoldier(Point(at.x+1,4))]
        for a in actions { XCTAssertTrue(s.apply(a).success) }
        return s
    }
    func testHuntAwardsOnlyHunterAndUnlocksNextOwnTurnForBothCosts() throws {
        for cost in [0, 1] {
            var s = try opening(.slime, cost: cost); let before = s.state
            let o = s.apply(.huntMonster(center)); XCTAssertTrue(o.success)
            XCTAssertEqual(s.state.loot(of: .one), MonsterLoot(.stickyBounce, unlockPly: 5))
            XCTAssertNil(s.state.loot(of: .two))
            XCTAssertTrue(o.events.contains(.monsterLootGranted(.one, .stickyBounce, unlockPly: 5)))
            if cost == 0 {
                rejected(s.state, .useStickyBounce(anchor: Point(3,4), target: Point(5,4)), .monsterLootLocked)
                XCTAssertTrue(s.apply(.endTurn).success)
            }
            rejected(s.state, .useStickyBounce(anchor: Point(0,0), target: Point(3,4)), .noMonsterLoot)
            XCTAssertTrue(s.apply(.endTurn).success)
            XCTAssertEqual(s.state.ply, 5)
            XCTAssertTrue(s.undo()); XCTAssertTrue(s.undo())
            if cost == 0 { XCTAssertTrue(s.undo()) }
            XCTAssertEqual(s.state, before)
        }
    }
    func testAwardSwitchOffAndFailureDoesNotGrantLoot() throws {
        var c = config(awards: false)
        let bare = try GameSetup.fromDiagram(config: c, diagram: ".........\n....O....\n.........\n.........\n...xMx...\n.........\n.........\n....X....\n.........")
        let o = GameEngine.apply(bare, .huntMonster(center)); XCTAssertTrue(o.success)
        XCTAssertNil(o.state.loot(of: .one)); XCTAssertEqual(o.events.count, 2)
        c.monsterBattlefield = nil
        rejected(try GameSetup.newGame(config: c), .useShadowStep(Point(3,3)), .monsterModeDisabled)
        let uncontrolled = try GameSetup.newGame(config: config())
        rejected(uncontrolled, .huntMonster(center), .insufficientMonsterControl)
        XCTAssertNil(uncontrolled.loot(of: .one))
    }
    func testBounceFourDirectionsAndBothOwnersNoHeroNoMana() throws {
        for (anchor, target, destination) in [(Point(3,4),center,Point(5,4)),(Point(5,4),center,Point(3,4)),
                                             (Point(4,3),center,Point(4,5)),(Point(4,5),center,Point(4,3))] {
            for symbol: Character in ["x","o"] {
                let s = try position([(anchor,"x"),(target,symbol)], hero: .none)
                let o = GameEngine.apply(s, .useStickyBounce(anchor: anchor, target: target)); XCTAssertTrue(o.success)
                XCTAssertNil(o.state.board[target]); XCTAssertEqual(o.state.board[destination], Piece(symbol == "x" ? .one : .two, .soldier))
                XCTAssertEqual(o.state.apRemaining, 1); XCTAssertEqual(o.state.mana(of: .one), 0)
                XCTAssertTrue(o.state.skillUsedThisTurn); XCTAssertNil(o.state.loot(of: .one))
                XCTAssertEqual(o.events, [.resourcesSpent(.one, ap: 1, mana: 0), .piecePushed(caster: .one, from: target, to: destination, piece: Piece(symbol == "x" ? .one : .two, .soldier)), .monsterAbilityUsed(.one, .stickyBounce)])
                rejected(o.state, .useStickyBounce(anchor: anchor, target: destination), .noMonsterLoot)
            }
        }
    }
    func testBounceRejectsInvalidContactTargetsBoundariesAndOccupiedDestination() throws {
        let s = try position([(Point(3,4),"x"),(center,"o"),(Point(2,2),"H"),(Point(2,3),"x")])
        rejected(s, .useStickyBounce(anchor: Point(2,3), target: center), .outOfRange)
        rejected(s, .useStickyBounce(anchor: center, target: Point(3,4)), .invalidTarget)
        rejected(s, .useStickyBounce(anchor: Point(2,3), target: Point(2,2)), .invalidTarget)
        rejected(s, .useStickyBounce(anchor: Point(-1,4), target: center), .outOfBounds)
        for symbol: Character in ["x","o","H"] {
            let blocked = try position([(Point(3,4),"x"),(center,"o"),(Point(5,4),symbol)])
            rejected(blocked, .useStickyBounce(anchor: Point(3,4), target: center), .occupied)
        }
        let neutral = try position([(Point(2,4),"x"),(Point(3,4),"o")], monster: true)
        rejected(neutral, .useStickyBounce(anchor: Point(2,4), target: Point(3,4)), .occupied)
        let edge = try position([(Point(7,3),"x"),(Point(8,3),"o")])
        rejected(edge, .useStickyBounce(anchor: Point(7,3), target: Point(8,3)), .outOfBounds)
    }
    func testSkillBudgetIsSharedInBothOrdersButHuntDoesNotUseIt() throws {
        let s = try position([(Point(3,4),"H"),(center,"x")])
        let used = GameEngine.apply(s, .useStickyBounce(anchor: Point(3,4), target: center)).state
        rejected(used, .castBastion(Point(3,3), Point(2,4)), .skillAlreadyUsed)
        var heroFirst = s; heroFirst.mana[0] = 6
        let bastion = GameEngine.apply(heroFirst, .castBastion(Point(3,3), Point(2,4)))
        XCTAssertTrue(bastion.success)
        rejected(bastion.state, .useStickyBounce(anchor: Point(3,4), target: center), .skillAlreadyUsed)
        var noAP = s; noAP.apRemaining = 0
        rejected(noAP, .useStickyBounce(anchor: Point(3,4), target: center), .noActionPoints)
    }
    func testBounceSuicideKoAndCaptureSettleAtomically() throws {
        let action = GameAction.useStickyBounce(anchor: Point(3,4), target: center)
        let trapped = try position([(Point(3,4),"x"),(center,"o"),(Point(6,4),"x"),(Point(6,3),"o"),(Point(7,4),"o"),(Point(6,5),"o")])
        rejected(trapped, action, .suicide)
        var s = try position([(Point(3,4),"x"),(center,"x")])
        var repeated = s.board; repeated[center] = nil; repeated[Point(5,4)] = Piece(.one,.soldier); s.history.insert(repeated.diagram)
        rejected(s, action, .ko)
        // Pushing our soldier completes the north stone's surround: hand-reviewed one-stone capture.
        let capture = try position([(Point(3,4),"x"),(center,"x"),(Point(5,3),"o"),(Point(4,3),"x"),(Point(6,3),"x"),(Point(5,2),"x")])
        let o = GameEngine.apply(capture, action); XCTAssertTrue(o.success); XCTAssertNil(o.state.board[Point(5,3)])
        XCTAssertEqual(o.events.last, .piecesCaptured(.one,[CapturedPiece(at: Point(5,3),piece: Piece(.two,.soldier))]))
    }
    func testWolfHuntRequiresAdjacentHeroThenAwardsShadowStep() throws {
        let noHero = try position([(Point(3,4),"x"),(Point(5,4),"x"),(Point(2,3),"H")], kind: .shadowWolf, ready: false, monster: true)
        rejected(noHero, .huntMonster(center), .noHeroOnBoard)
        let s = try position([(Point(3,4),"H"),(Point(5,4),"x")], kind: .shadowWolf, ready: false, monster: true)
        let o = GameEngine.apply(s, .huntMonster(center)); XCTAssertTrue(o.success)
        XCTAssertEqual(o.state.loot(of: .one), MonsterLoot(.shadowStep, unlockPly: 3))
        XCTAssertNil(o.state.loot(of: .two))
    }
    func testShadowStepOneOrTwoStraightSpacesAndOwnership() throws {
        for p in [Point(4,3),Point(4,2),Point(6,4),Point(5,4),Point(4,5),Point(4,6),Point(3,4),Point(2,4)] {
            let s = try position([(center,"H")], kind: .shadowWolf)
            let o = GameEngine.apply(s, .useShadowStep(p)); XCTAssertTrue(o.success)
            XCTAssertNil(o.state.board[center]); XCTAssertEqual(o.state.board[p], Piece(.one,.hero))
            XCTAssertEqual(o.state.apRemaining,1); XCTAssertEqual(o.state.mana(of: .one),0)
            XCTAssertTrue(o.state.skillUsedThisTurn); XCTAssertNil(o.state.loot(of: .one))
        }
    }
    func testShadowStepRejectsDiagonalDistanceBlockedPathAndMissingHero() throws {
        let s = try position([(center,"H")], kind: .shadowWolf)
        for p in [center,Point(5,5),Point(4,1)] { rejected(s,.useShadowStep(p),.outOfRange) }
        rejected(s,.useShadowStep(Point(-1,4)),.outOfBounds)
        for p in [Point(5,4),Point(6,4)] {
            let blocked = try position([(center,"H"),(p,"o")], kind: .shadowWolf)
            rejected(blocked,.useShadowStep(Point(6,4)),.occupied)
        }
        let neutral = try position([(Point(3,4),"H")], kind: .shadowWolf, monster: true)
        rejected(neutral,.useShadowStep(Point(5,4)),.occupied)
        rejected(try position(kind:.shadowWolf),.useShadowStep(Point(5,4)),.noHeroOnBoard)
        rejected(s,.useStickyBounce(anchor:center,target:Point(5,4)),.noMonsterLoot)
    }
    func testShadowStepCannotJumpEnemiesAndSupportsKoVictoryUndo() throws {
        let action = GameAction.useShadowStep(Point(4,2))
        let trapped = try position([(center,"H"),(Point(3,2),"o"),(Point(5,2),"o"),(Point(4,3),"o")], kind: .shadowWolf)
        rejected(trapped,action,.occupied) // intervening enemy; cannot jump it
        var s = try position([(center,"H")],kind:.shadowWolf)
        var repeated = s.board; repeated[center] = nil; repeated[Point(4,2)] = Piece(.one,.hero); s.history.insert(repeated.diagram)
        rejected(s,action,.ko)
        let winning = try position([(center,"H"),(Point(3,1),"x"),(Point(5,1),"x"),(Point(4,0),"x")],kind:.shadowWolf)
        var session = GameSession(winning); let o = session.apply(action)
        XCTAssertTrue(o.success); XCTAssertEqual(o.state.status,.won); XCTAssertEqual(o.state.winner,.one)
        XCTAssertEqual(o.events.last,.gameWon(.one)); XCTAssertNil(o.state.loot(of:.one))
        XCTAssertTrue(session.undo()); XCTAssertEqual(session.state,winning)
    }
    func testBothLootKindsAreReachableFromLegalOpeningIncludingUndoAndReplay() throws {
        for kind in MonsterKind.allCases { for cost in [0,1] { for at in [center,Point(3,4)] {
            var s = try opening(kind,cost:cost,at:at)
            XCTAssertTrue(s.apply(.huntMonster(at)).success)
            if s.state.current == .one { XCTAssertTrue(s.apply(.endTurn).success) }
            XCTAssertTrue(s.apply(.endTurn).success)
            if kind == .slime { XCTAssertTrue(s.apply(.placeSoldier(at)).success) }
            let before = s.state
            let a: GameAction = kind == .slime ? .useStickyBounce(anchor:at,target:Point(at.x+1,4)) : .useShadowStep(Point(at.x-1,2))
            XCTAssertTrue(GameEngine.legalActions(before).contains(a)); XCTAssertTrue(s.apply(a).success)
            XCTAssertTrue(s.undo()); XCTAssertEqual(s.state,before); XCTAssertTrue(s.apply(a).success)
            var replay = GameSession(try GameSetup.newGame(config: s.state.config,classOne:.warrior,classTwo:.mage))
            for a in s.log { XCTAssertTrue(replay.apply(a).success) }
            XCTAssertEqual(replay.state,s.state)
        } } }
    }
    func testOpponentCanBlockRewardDestinationBeforeUnlockFromLegalOpening() throws {
        for kind in MonsterKind.allCases {
            var s = try opening(kind); XCTAssertTrue(s.apply(.huntMonster(center)).success)
            let blocked = kind == .slime ? Point(6,4) : Point(3,2)
            XCTAssertTrue(s.apply(.placeSoldier(blocked)).success); XCTAssertTrue(s.apply(.endTurn).success)
            if kind == .slime { XCTAssertTrue(s.apply(.placeSoldier(center)).success) }
            let a: GameAction = kind == .slime ? .useStickyBounce(anchor:center,target:Point(5,4)) : .useShadowStep(blocked)
            rejected(s.state,a,.occupied)
            XCTAssertNotNil(s.state.loot(of:.one))
        }
    }
}
