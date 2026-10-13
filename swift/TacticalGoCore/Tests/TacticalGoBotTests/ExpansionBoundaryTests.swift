import XCTest
@testable import TacticalGoCore
import TacticalGoBot

final class ExpansionBoundaryTests: XCTestCase {
    private func execute(_ s: GameState,_ p: BotTurnPlan) -> GameState {
        var result = s
        for action in p.actions {
            XCTAssertEqual(result.current,s.current);XCTAssertEqual(result.status,.ongoing)
            let o = GameEngine.apply(result,action);XCTAssertTrue(o.success,"\(action): \(o.reason)");result = o.state
        }
        XCTAssertTrue(result.current != s.current || result.status != .ongoing)
        return result
    }
    private func fixture(_ hero: HeroClass,_ rows: String, ap: Int = 1, monster: MonsterKind? = nil, cost: Int = 1) throws -> GameState {
        var c = RuleConfig.board(size:9);c.expansionSkills = true
        if let monster { c.monsterBattlefield = .init(huntAPCost:cost,kind:monster,awardsLoot:true) }
        return try GameSetup.fromDiagram(config:c,diagram:rows,classOne:hero,classTwo:.mage,manaOne:6,manaTwo:6,ap:ap)
    }
    func testAllFourClassesBothDifficultiesPlanLegalDeterministicExpandedOpenings() throws {
        var c = RuleConfig.board(size:7);c.expansionSkills = true
        for hero in HeroClass.allCases where hero != .none { for difficulty in BotDifficulty.allCases {
            let s = try GameSetup.newGame(config:c,classOne:hero,classTwo:hero)
            let a = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty)), b = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty))
            XCTAssertEqual(a.actions,b.actions);XCTAssertEqual(a.stats.domainTransitions,b.stats.domainTransitions)
            let after = execute(s,a);XCTAssertNotNil(after.board.find(.one,.hero))
        } }
    }
    func testReformationWinsRemoteTwoLibertyCommanderInOneAP() throws {
        // E2/F2 enemy group has exactly E3/F3. D5 hero cannot build there;
        // connected E4/F4 soldiers can transfer to the frontier. One placement cannot win.
        let s = try fixture(.warrior,"....xx...\n...xOox..\n...x..x..\n...xxx...\n...H.....\n.........\n.........\n....X....\n.........")
        XCTAssertEqual(s.board.liberties(at:Point(4,1)),Set([Point(4,2),Point(5,2)]))
        let witness = GameAction.castReformation(.init(Point(4,3),Point(4,2)),.init(Point(5,3),Point(5,2)))
        XCTAssertEqual(GameEngine.apply(s,witness).state.winner,.one)
        XCTAssertFalse(GameEngine.legalActions(s).contains { action in
            if case .castReformation = action { return false };return GameEngine.apply(s,action).state.winner == .one
        })
        for difficulty in BotDifficulty.allCases {
            let p = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty))
            XCTAssertTrue(p.actions.contains { if case .castReformation = $0 { return true };return false })
            XCTAssertEqual(execute(s,p).winner,.one)
        }
    }
    func testOtherNewSkillsAreActuallyEvaluatedInRootComparison() throws {
        for (hero,rows,key) in [
            (HeroClass.mage,".........\n....O....\n.........\n...o.....\n...Hx....\n.........\n.........\n....X....\n.........","8-pull:"),
            (.rogue,".........\n....O....\n.........\n.........\n...Hoo...\n.........\n.........\n....X....\n.........","8-chain:"),
            (.priest,".........\n....O....\n.........\n.........\n...Hx....\n.........\n.........\n....X....\n.........","8-offering:")
        ] {
            let s = try fixture(hero,rows)
            let p = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
            XCTAssertTrue(p.stats.rootActionComparisons.contains { $0.hasPrefix(key) },"\(hero)")
            _ = execute(s,p)
        }
    }
    func testHuntsBothMonstersAndHandlesZeroAPWindowWithDelayedReward() throws {
        for kind in MonsterKind.allCases { for cost in [0,1] {
            var s = try fixture(.warrior,".........\n....O....\n.........\n.........\n...HMx...\n.........\n.........\n....X....\n.........",monster:kind,cost:cost)
            if cost == 0 { s.apRemaining = 0;s.awaitingFreeHunt = true }
            for difficulty in BotDifficulty.allCases {
                let p = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty)),after = execute(s,p)
                XCTAssertTrue(p.actions.contains(.huntMonster(Point(4,4))),"\(kind) cost=\(cost) \(difficulty): \(p.actions.map(botActionDescription))\n\(p.stats.candidateComparisons)\n\(p.stats.rootActionComparisons.filter { $0.hasPrefix("8-hunt:") })")
                XCTAssertFalse(after.board.monsters.contains(Point(4,4)))
                XCTAssertEqual(after.lootInventory(of:.one).count,1)
                if let loot = after.lootInventory(of:.one).first { XCTAssertGreaterThan(loot.unlockPly,s.ply) }
            }
        } }
    }
    func testCommanderRescueOutranksMonsterReward() throws {
        let s = try fixture(.warrior,".........\n....O....\n.........\n.........\n...HMx...\n....o....\n...oXo...\n.........\n.........",monster:.slime)
        XCTAssertEqual(s.board.liberties(at:Point(4,6)),Set([Point(4,7)]))
        XCTAssertTrue(GameEngine.apply(s,.huntMonster(Point(4,4))).success)
        for difficulty in BotDifficulty.allCases {
            let p = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:difficulty))
            XCTAssertFalse(p.actions.contains(.huntMonster(Point(4,4))))
            let after = execute(s,p),commander = try XCTUnwrap(after.board.find(.one,.commander))
            XCTAssertGreaterThan(after.board.liberties(at:commander).count,1,"\(difficulty): \(p.actions.map(botActionDescription))\n\(after.board.diagram)\n\(p.stats.candidateComparisons)")
        }
    }
    func testLootIsEvaluatedAndLockedLootIsNeverUsed() throws {
        for (kind,ability,rows,key) in [
            (MonsterKind.slime,MonsterAbility.stickyBounce,".........\n....O....\n.........\n.........\n...xo....\n.........\n.........\n....X....\n.........","8-bounce:"),
            (.shadowWolf,.shadowStep,".........\n....O....\n.........\n.........\n...H.....\n.........\n.........\n....X....\n.........","8-step:")
        ] {
            var s = try fixture(.warrior,rows,monster:kind)
            s.monsterLoot[0] = [MonsterLoot(ability,unlockPly:s.ply)]
            let plan = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
            XCTAssertTrue(plan.stats.rootActionComparisons.contains { $0.hasPrefix(key) });_ = execute(s,plan)
            s.monsterLoot[0] = [MonsterLoot(ability,unlockPly:s.ply+2)]
            let locked = try XCTUnwrap(BotPlanner.planTurn(s,difficulty:.easy))
            XCTAssertFalse(locked.stats.rootActionComparisons.contains { $0.hasPrefix(key) });_ = execute(s,locked)
        }
    }
    func testSearchEnumerationCapPreservesDomainLegalityAndCompleteDefault() throws {
        let s = try fixture(.mage,".........\n....O....\n.........\n...o.....\n...Hx....\n.........\n.........\n....X....\n.........")
        let complete = GameEngine.legalActions(s)
        let capped = GameEngine.legalActions(s,expansionCandidateLimit:1)
        XCTAssertTrue(capped.allSatisfy { complete.contains($0) && GameEngine.apply(s,$0).success })
        let isPull: (GameAction) -> Bool = { if case .castDoublePull = $0 { return true };return false }
        XCTAssertGreaterThan(complete.filter(isPull).count,1)
        XCTAssertLessThanOrEqual(capped.filter(isPull).count,1)
        XCTAssertTrue(capped.contains(.endTurn))
    }
    func testCancellationTinyBudgetTerminalAndSharedSkillGate() throws {
        let s = try fixture(.mage,".........\n....O....\n.........\n...o.....\n...Hx....\n.........\n.........\n....X....\n.........",ap:2)
        XCTAssertNil(BotPlanner.planTurn(s,cancelled:{true}))
        let tiny = try XCTUnwrap(BotPlanner.planTurn(s,limits:.init(maxDomainTransitions:1)))
        XCTAssertEqual(tiny.actions,[.endTurn]);_ = execute(s,tiny)
        var used = s;used.skillUsedThisTurn = true
        let p = try XCTUnwrap(BotPlanner.planTurn(used,difficulty:.easy))
        XCTAssertFalse(p.stats.rootActionComparisons.contains { $0.hasPrefix("8-pull:") || $0.hasPrefix("4-push:") })
        _ = execute(used,p)
        var terminal = s;terminal.status = .won;terminal.winner = .one
        XCTAssertNil(BotPlanner.planTurn(terminal))
    }
}
