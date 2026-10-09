import Foundation
import XCTest
import TacticalGoCore
import TacticalGoBot

final class PassHistoryTests: XCTestCase {
    private func recordedState(_ id: String, ply: Int) throws -> GameState {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "history-fixtures", withExtension: "json", subdirectory: "Fixtures"))
        let document = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
        let trace = try XCTUnwrap((document["traces"] as! [[String: Any]]).first { $0["id"] as! String == id })
        var state = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        for turn in trace["turns"] as! [[String: Any]] {
            XCTAssertEqual(state.ply, turn["ply"] as! Int)
            XCTAssertEqual(state.current.rawValue, turn["player"] as! Int)
            XCTAssertEqual(state.board.diagram, turn["boardBefore"] as! String)
            if state.ply == ply { return state }
            for item in turn["actions"] as! [[String: Any]] {
                let result = GameEngine.apply(state, try action(item["action"] as! [String: Any]))
                XCTAssertTrue(result.success)
                XCTAssertEqual(result.state.board.diagram, item["boardAfter"] as! String)
                XCTAssertEqual(result.state.apRemaining, item["apAfter"] as! Int)
                XCTAssertEqual(result.state.current.rawValue, item["currentAfter"] as! Int)
                XCTAssertEqual(result.state.mana(of: .one), item["manaOneAfter"] as! Int)
                XCTAssertEqual(result.state.mana(of: .two), item["manaTwoAfter"] as! Int)
                XCTAssertEqual(result.events.map(\.name), item["events"] as! [String])
                state = result.state
            }
        }
        throw NSError(domain: "history fixture", code: 1)
    }
    private func action(_ object: [String: Any]) throws -> GameAction {
        func point(_ key: String) -> Point { let pair = object[key] as! [Int]; return Point(pair[0], pair[1]) }
        switch object["kind"] as! String {
        case "placeSoldier": return .placeSoldier(point("at"))
        case "summonHero": return .summonHero(point("at"))
        case "castBastion": return .castBastion(point("a"), point("b"))
        case "castMagicHand": return .castMagicHand(point("at"), try XCTUnwrap(PushDirection(rawValue: object["direction"] as! String)))
        case "castSwap": return .castSwap(point("at"))
        case "castSeal": return .castSeal(point("at"))
        case "endTurn": return .endTurn
        default: throw NSError(domain: "history action", code: 2)
        }
    }
    private func execute(_ initial: GameState, _ plan: BotTurnPlan) throws -> GameState {
        var state = initial
        for action in plan.actions {
            XCTAssertEqual(state.current, initial.current)
            XCTAssertEqual(state.status, .ongoing)
            let result = GameEngine.apply(state, action)
            XCTAssertTrue(result.success)
            state = result.state
        }
        XCTAssertTrue(state.current != initial.current || state.status != .ongoing)
        XCTAssertLessThanOrEqual(plan.stats.domainTransitions, plan.stats.difficulty == .easy ? 1_600 : 6_000)
        return state
    }
    func testDangerousSealedPositionStillPassesRatherThanSacrificingCommander() throws {
        // Reachable source white commander has only A2/B1. Every non-pass action
        // leaves one liberty; Core independently shows the enemy can take the last.
        let s = try recordedState("easy", ply: 54)
        let commander = try XCTUnwrap(s.board.find(s.current, .commander))
        XCTAssertEqual(s.board.liberties(at: commander).count, 2)
        let legal = GameEngine.legalActions(s)
        XCTAssertEqual(legal.filter { $0 != .endTurn }.count, 2)
        for move in legal where move != .endTurn {
            let first = GameEngine.apply(s, move)
            XCTAssertTrue(first.success)
            let handed = GameEngine.apply(first.state, .endTurn)
            XCTAssertTrue(handed.success)
            XCTAssertTrue(GameEngine.legalActions(handed.state).contains { GameEngine.apply(handed.state, $0).state.winner == s.current.opponent })
        }
        for difficulty in BotDifficulty.allCases {
            let plan = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: difficulty))
            XCTAssertEqual(plan.actions, [.endTurn])
            XCTAssertFalse(plan.stats.budgetExhausted)
            XCTAssertEqual(plan.stats.rootActionComparisons.count, legal.count)
            XCTAssertFalse(plan.stats.passDiagnostics.isEmpty)
            let result = try execute(s, plan)
            XCTAssertNotNil(result.board.find(s.current, .hero))
            XCTAssertEqual(result.board.liberties(at: commander).count, 2)
        }
    }
    func testMidAndLateGamePlansAreDeterministicLegalAndPreserveCommanderAndHero() throws {
        for (trace, ply) in [("standard", 20), ("standard", 30), ("standard", 41), ("standard", 42), ("easy", 55)] {
            let s = try recordedState(trace, ply: ply)
            for difficulty in BotDifficulty.allCases {
                let a = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: difficulty))
                let b = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: difficulty))
                XCTAssertEqual(a.actions, b.actions)
                XCTAssertEqual(a.reasons, b.reasons)
                let result = try execute(s, a)
                XCTAssertNotNil(result.board.find(s.current, .commander))
                XCTAssertNotNil(result.board.find(s.current, .hero))
                if difficulty == .standard && result.status == .ongoing {
                    XCTAssertFalse(GameEngine.legalActions(result).contains { GameEngine.apply(result, $0).state.winner == s.current.opponent }, "\(trace)/\(ply) immediate loss")
                }
            }
        }
    }
    func testLegalRootValuesAreRecordedAndSafeMidgameProgressIsNotBlanketBanned() throws {
        let s = try recordedState("standard", ply: 20)
        for difficulty in BotDifficulty.allCases {
            let plan = try XCTUnwrap(BotPlanner.planTurn(s, difficulty: difficulty))
            XCTAssertFalse(plan.stats.budgetExhausted)
            XCTAssertEqual(plan.stats.rootActionComparisons.count, GameEngine.legalActions(s).count)
            XCTAssertTrue(plan.stats.rootActionComparisons.contains { $0.hasPrefix("9-end own=") })
            XCTAssertFalse(plan.stats.ownTurnComparisons.isEmpty)
            XCTAssertTrue(plan.actions.contains { $0 != .endTurn })
            _ = try execute(s, plan)
        }
    }
}
