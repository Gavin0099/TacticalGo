import Foundation
import XCTest
import TacticalGoCore
@testable import TacticalGoBot

final class MaterialContinuationTests: XCTestCase {
    private func fixture(_ name: String) throws -> Any {
        let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    }
    private func action(_ raw: [String: Any]) throws -> GameAction {
        func point(_ key: String) throws -> Point {
            let p = try XCTUnwrap(raw[key] as? [Int]); XCTAssertEqual(p.count, 2)
            return Point(p[0], p[1])
        }
        if let points = raw["points"] as? [[String: Int]] {
            func p(_ i: Int) -> Point { Point(points[i]["x"]!, points[i]["y"]!) }
            switch raw["kind"] as? String {
            case "soldier": return .placeSoldier(p(0))
            case "summon": return .summonHero(p(0))
            case "push": return .castMagicHand(p(0), try XCTUnwrap(PushDirection(rawValue: raw["direction"] as! String)))
            case "end": return .endTurn
            default: throw NSError(domain: "material fixture action", code: 1)
            }
        }
        switch raw["kind"] as? String {
        case "placeSoldier": return try .placeSoldier(point("at"))
        case "summonHero": return try .summonHero(point("at"))
        case "castBastion": return try .castBastion(point("a"), point("b"))
        case "castMagicHand": return try .castMagicHand(point("at"), XCTUnwrap(PushDirection(rawValue: raw["direction"] as! String)))
        case "castFriendlyRedeploy": return try .castFriendlyRedeploy(point("from"), point("to"))
        case "castSwap": return try .castSwap(point("at"))
        case "castSeal": return try .castSeal(point("at"))
        case "endTurn": return .endTurn
        default: throw NSError(domain: "material fixture action", code: 2)
        }
    }
    private func receipt(_ raw: [String: Any], _ state: GameState) {
        XCTAssertEqual(raw["diagram"] as? String, state.board.diagram)
        XCTAssertEqual(raw["ap"] as? Int, state.apRemaining)
        XCTAssertEqual(raw["current"] as? Int, state.current.rawValue)
        XCTAssertEqual(raw["ply"] as? Int, state.ply)
        XCTAssertEqual(raw["mana"] as? [Int], [state.mana(of: .one), state.mana(of: .two)])
        XCTAssertEqual(raw["status"] as? String, state.status.rawValue)
        XCTAssertEqual(raw["skillUsed"] as? Bool, state.skillUsedThisTurn)
        XCTAssertEqual(raw["summoned"] as? [Bool], [state.hasSummonedHero(.one), state.hasSummonedHero(.two)])
        XCTAssertTrue(state.seals.isEmpty)
        XCTAssertNil(state.winner)
    }
    private func source(maxPlies: Int = 100) throws -> GameState {
        let control = try XCTUnwrap(fixture("material-rogue-source") as? [String: Any])
        var config = RuleConfig.board(size: 7); config.maxPlies = maxPlies
        var state = try GameSetup.newGame(config: config, classOne: .rogue, classTwo: .mage)
        let rows = try XCTUnwrap(control["source"] as? [[String: Any]])
        XCTAssertEqual(rows.count, 43, "Reviewed official newGame source, including the actual accepted A7 first action")
        for row in rows {
            receipt(try XCTUnwrap(row["before"] as? [String: Any]), state)
            let out = GameEngine.apply(state, try action(XCTUnwrap(row["action"] as? [String: Any])))
            XCTAssertTrue(out.success)
            receipt(try XCTUnwrap(row["after"] as? [String: Any]), out.state)
            XCTAssertEqual(out.events.map { String(reflecting: $0) }, row["events"] as? [String])
            state = out.state
        }
        receipt(try XCTUnwrap(control["root"] as? [String: Any]), state)
        return state
    }
    private struct Turn { let actions: [GameAction]; let state: GameState; let captures: Int }
    // Independent recursive Core replay. Expected branches/captures come from the
    // saved reviewed probe, rather than the candidate's own trace strings.
    private func completeTurns(_ root: GameState) -> [Turn] {
        if root.status != .ongoing { return [] }
        var rows: [Turn] = []
        func visit(_ state: GameState, _ actions: [GameAction], _ captures: Int) {
            if state.current != root.current || state.status != .ongoing {
                rows.append(Turn(actions: actions, state: state, captures: captures)); return
            }
            XCTAssertLessThan(actions.count, 2)
            for a in GameEngine.legalActions(state) {
                let out = GameEngine.apply(state, a); XCTAssertTrue(out.success)
                var count = captures
                for event in out.events {
                    if case .piecesCaptured(let owner, let pieces) = event, owner == .one {
                        count += pieces.filter { $0.piece == Piece(.two, .soldier) }.count
                    }
                }
                visit(out.state, actions + [a], count)
            }
        }
        visit(root, [], 0); return rows
    }
    private func run(_ root: GameState, _ actions: [GameAction]) throws -> Turn {
        var state = root, captures = 0
        for a in actions {
            XCTAssertEqual(state.current, root.current); XCTAssertEqual(state.status, .ongoing)
            let out = GameEngine.apply(state, a); XCTAssertTrue(out.success)
            for event in out.events {
                if case .piecesCaptured(let owner, let pieces) = event, owner == .one {
                    captures += pieces.filter { $0.piece == Piece(.two, .soldier) }.count
                }
            }
            state = out.state
        }
        XCTAssertTrue(state.current != root.current || state.status != .ongoing)
        return Turn(actions: actions, state: state, captures: captures)
    }
    func testRealBaselinePassBecomesNewSafeMaterialThreatAndAllReviewedRepliesReplay() throws {
        let root = try source()
        let baseline = try XCTUnwrap(BotPlanner.planTurn(root))
        XCTAssertEqual(baseline.actions, [.endTurn]); XCTAssertEqual(baseline.score, -1228)
        XCTAssertEqual(baseline.stats.domainTransitions, 144)
        let candidate = try XCTUnwrap(BotPlanner.planTurn(root, policy: .materialThreatContinuation))
        let traced = try XCTUnwrap(BotPlanner.planTurn(root, diagnostics: true, policy: .materialThreatContinuation))
        XCTAssertEqual(candidate.actions, traced.actions)
        XCTAssertEqual(candidate.score, traced.score)
        XCTAssertEqual(candidate.reasons, traced.reasons)
        XCTAssertEqual(candidate.stats.domainTransitions, traced.stats.domainTransitions)
        XCTAssertEqual(candidate.stats.legalEnumerations, traced.stats.legalEnumerations)
        XCTAssertEqual(candidate.stats.continuationComparisons, traced.stats.continuationComparisons)
        XCTAssertEqual(candidate.actions, [.placeSoldier(Point(6,6))])
        XCTAssertEqual(candidate.stats.continuationComparisons.filter { $0.hasPrefix("material-proved-reply:") }.count, 35)
        XCTAssertTrue(candidate.stats.continuationComparisons.contains { $0.hasPrefix("material-accepted:") })
        XCTAssertLessThanOrEqual(candidate.stats.domainTransitions, 6000); XCTAssertFalse(candidate.stats.budgetExhausted)
        let after = try run(root, candidate.actions).state
        XCTAssertEqual(after.status, .ongoing); XCTAssertNil(after.winner)
        XCTAssertEqual(after.mana(of: .one), root.mana(of: .one), "Ordinary placement spends no Mana")
        let replies = completeTurns(after)
        XCTAssertEqual(replies.count, 35)
        let saved = try XCTUnwrap(fixture("material-reviewed-witnesses") as? [[String: Any]])
        XCTAssertEqual(saved.count, replies.count)
        var seen: Set<String> = []
        for row in saved {
            let enemy = try (row["enemy"] as! [[String: Any]]).map(action)
            let key = enemy.map(botActionDescription).joined(separator: "/")
            XCTAssertTrue(seen.insert(key).inserted)
            let reply = try run(after, enemy)
            XCTAssertTrue(replies.contains { $0.actions == enemy && $0.state == reply.state })
            XCTAssertNotNil(reply.state.board.find(.one, .commander)); XCTAssertNotEqual(reply.state.winner, .two)
            let capture = try run(reply.state, (row["capture"] as! [[String: Any]]).map(action))
            XCTAssertGreaterThan(capture.captures, 0)
            // Some replies defend or relocate G6 but lose other soldiers (or the
            // commander group). The gate is actual material capture, not identity.
            XCTAssertNotEqual(capture.state.status, .drawn)
            for counter in completeTurns(capture.state) {
                XCTAssertNotNil(counter.state.board.find(.one, .commander)); XCTAssertNotEqual(counter.state.winner, .two)
            }
        }
        let waiting = try run(root, [.endTurn]).state
        let waitingPassive = try run(waiting, [.endTurn]).state
        XCTAssertTrue(completeTurns(waitingPassive).allSatisfy { $0.captures == 0 }, "Waiting + enemy Pass has no next-own actual soldier capture")
        let passive = try run(after, [.endTurn]).state
        let capture = try run(passive, [.placeSoldier(Point(6,4)), .placeSoldier(Point(5,5))])
        XCTAssertEqual(capture.captures, 1); XCTAssertNil(capture.state.board[Point(6,5)])
        // An existential witness does not prove the running planner will play it.
        // Verify the real next decision and submit all its chosen Core actions.
        let followup = try XCTUnwrap(BotPlanner.planTurn(passive, policy: .materialThreatContinuation))
        let played = try run(passive, followup.actions)
        XCTAssertGreaterThan(played.captures, 0, "Actual next-turn planner must execute material progress after enemy Pass")
        XCTAssertNotNil(played.state.board.find(.one, .commander))
        XCTAssertNotEqual(played.state.winner, .two)
        for counter in completeTurns(played.state) {
            XCTAssertNotNil(counter.state.board.find(.one, .commander)); XCTAssertNotEqual(counter.state.winner, .two)
        }
    }
    func testDefaultOldForcingAndEasyRemainIsolated() throws {
        let root = try source()
        let old = try XCTUnwrap(BotPlanner.planTurn(root))
        let baseline = try XCTUnwrap(BotPlanner.planTurn(root, policy: .baseline))
        let forcing = try XCTUnwrap(BotPlanner.planTurn(root, policy: .forcingContinuation))
        XCTAssertEqual(old.actions, baseline.actions); XCTAssertEqual(old.stats.domainTransitions, baseline.stats.domainTransitions)
        XCTAssertEqual(forcing.actions, [.endTurn])
        XCTAssertFalse(forcing.stats.continuationComparisons.contains { $0.hasPrefix("material-") })
        let easy = try XCTUnwrap(BotPlanner.planTurn(root, difficulty: .easy))
        let option = try XCTUnwrap(BotPlanner.planTurn(root, difficulty: .easy, policy: .materialThreatContinuation))
        XCTAssertEqual(easy.actions, option.actions); XCTAssertEqual(easy.stats.domainTransitions, option.stats.domainTransitions)
    }
    func testIncompleteProofBudgetAndCancellationCannotPublishCandidate() throws {
        let root = try source()
        for budget in [1, 145, 200, 500] {
            let limits = BotLimits(maxDomainTransitions: budget)
            let baseline = try XCTUnwrap(BotPlanner.planTurn(root, limits: limits))
            let option = try XCTUnwrap(BotPlanner.planTurn(root, limits: limits, policy: .materialThreatContinuation))
            XCTAssertEqual(option.actions, baseline.actions)
            XCTAssertLessThanOrEqual(option.stats.domainTransitions, budget)
            XCTAssertFalse(option.stats.continuationComparisons.contains { $0.hasPrefix("material-accepted:") })
        }
        XCTAssertNil(BotPlanner.planTurn(root, policy: .materialThreatContinuation, cancelled: { true }))
        let baseline = try XCTUnwrap(BotPlanner.planTurn(root))
        let after = try run(root, [.placeSoldier(Point(6,6))]).state
        for stop in [2, 5, 25] {
            let token = MaterialCancellation(stop)
            var proof = BotMaterialContinuation(root: root, baseline: baseline, limits: .standard,
                candidates: [BotTurnCandidate(state: after, actions: [.placeSoldier(Point(6,6))])], cancelled: { token.next() })
            XCTAssertNil(proof.run()); XCTAssertFalse(proof.stats.continuationComparisons.contains { $0.hasPrefix("material-accepted:") })
        }
    }
    func testCaptureAtDrawBoundaryCannotAuthorizeContinuation() throws {
        let root = try source(maxPlies: 25)
        let baseline = try XCTUnwrap(BotPlanner.planTurn(root))
        let after = try run(root, [.placeSoldier(Point(6,6))]).state
        var proof = BotMaterialContinuation(root: root, baseline: baseline, limits: .standard,
            candidates: [BotTurnCandidate(state: after, actions: [.placeSoldier(Point(6,6))])], cancelled: { false })
        let result = try XCTUnwrap(proof.run())
        XCTAssertEqual(result.actions, baseline.actions)
        XCTAssertFalse(result.stats.continuationComparisons.contains { $0.hasPrefix("material-accepted:") })
    }
    private func reviewed(_ ply: Int) throws -> GameState {
        let doc = try XCTUnwrap(fixture("material-reviewed-source") as? [String: Any])
        let setup = doc["setup"] as! [String: Any]
        XCTAssertEqual(setup["rules"] as? String, "candidate")
        var config = RuleConfig.board(size: 7); config.bastionScope = .connectedGroup; config.experimentalFriendlyRedeploy = true
        var state = try GameSetup.newGame(config: config, classOne: .warrior, classTwo: .mage)
        for turn in doc["turns"] as! [[String: Any]] {
            if state.ply == ply { return state }
            XCTAssertEqual(turn["ply"] as? Int, state.ply); XCTAssertEqual(turn["boardBefore"] as? String, state.board.diagram)
            for row in turn["actions"] as! [[String: Any]] {
                let out = GameEngine.apply(state, try action(row["action"] as! [String: Any])); XCTAssertTrue(out.success)
                XCTAssertEqual(row["boardAfter"] as? String, out.state.board.diagram)
                XCTAssertEqual(row["apAfter"] as? Int, out.state.apRemaining)
                XCTAssertEqual(row["currentAfter"] as? Int, out.state.current.rawValue)
                XCTAssertEqual(row["plyAfter"] as? Int, out.state.ply)
                XCTAssertEqual(row["manaOneAfter"] as? Int, out.state.mana(of: .one))
                XCTAssertEqual(row["manaTwoAfter"] as? Int, out.state.mana(of: .two))
                XCTAssertEqual(row["eventPayloads"] as? [String], out.events.map { String(reflecting: $0) })
                state = out.state
            }
        }
        throw NSError(domain: "reviewed material fixture", code: 1)
    }
    func testReviewedDangerous40AndUnresolved55StillUseBaselinePass() throws {
        for ply in [40, 55] {
            let root = try reviewed(ply)
            let baseline = try XCTUnwrap(BotPlanner.planTurn(root))
            let option = try XCTUnwrap(BotPlanner.planTurn(root, policy: .materialThreatContinuation))
            XCTAssertEqual(baseline.actions, [.endTurn]); XCTAssertEqual(option.actions, baseline.actions)
            XCTAssertFalse(option.stats.continuationComparisons.contains { $0.hasPrefix("material-accepted:") })
            XCTAssertLessThanOrEqual(option.stats.domainTransitions, 6000)
        }
        let danger = try reviewed(40)
        let attacked = try run(danger, [.placeSoldier(Point(0,0)), .castMagicHand(Point(2,2), .up)]).state
        let loss = GameEngine.apply(attacked, .placeSoldier(Point(2,2)))
        XCTAssertTrue(loss.success); XCTAssertEqual(loss.state.winner, danger.current.opponent)
    }
}
private final class MaterialCancellation: @unchecked Sendable {
    let lock = NSLock(); var calls = 0; let stop: Int
    init(_ stop: Int) { self.stop = stop }
    func next() -> Bool { lock.lock(); defer { lock.unlock() }; calls += 1; return calls >= stop }
}
