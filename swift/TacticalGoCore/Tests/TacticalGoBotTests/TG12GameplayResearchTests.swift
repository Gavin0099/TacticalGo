import Foundation
import XCTest
import TacticalGoCore
import TacticalGoBot

/// TG12 P0 / guarded P1. Research-only: no changes to Core, Bot, or shipping configuration.
/// Positions are reached from formal newGame through the existing standard Bot.
final class TG12GameplayResearchTests: XCTestCase {
    private struct Fixture {
        let id: String
        let size: Int
        let black: HeroClass
        let white: HeroClass
        let plyLimit: Int
    }
    private func isSkill(_ action: GameAction) -> Bool {
        switch action {
        case .placeSoldier, .summonHero, .huntMonster, .endTurn: return false
        default: return true
        }
    }
    private func isPlacement(_ action: GameAction) -> Bool {
        if case .placeSoldier = action { return true }
        return false
    }
    private func ownedLiberties(_ state: GameState, _ player: Player) -> Int {
        state.board.find(player, .commander).map { state.board.liberties(at: $0).count } ?? 0
    }
    private func kind(_ action: GameAction) -> String {
        switch action {
        case .endTurn: return "pass"
        case .placeSoldier: return "place"
        case .summonHero: return "summon"
        case .huntMonster: return "hunt"
        default: return "skill"
        }
    }
    private func record(_ start: GameState, _ actions: [GameAction]) -> GameState? {
        var state = start
        for action in actions {
            let next = GameEngine.apply(state, action)
            guard next.success else { return nil }
            state = next.state
        }
        return state
    }
    private func sampled<T>(_ values: [T], cap: Int) -> [T] {
        guard values.count > cap, cap > 1 else { return Array(values.prefix(cap)) }
        return (0..<cap).map { values[$0 * (values.count - 1) / (cap - 1)] }
    }
    /// P1 gate proves the existence of structurally different legal two-AP choices, not optimality.
    /// Retain original GameState history: reconstructing from board diagrams would lose superko.
    private func probeP1(_ state: GameState, id: String) -> [String: Any]? {
        guard state.apRemaining == 2, state.status == .ongoing else { return nil }
        let actions = GameEngine.legalActions(state, expansionCandidateLimit: 256)
        let skills = actions.filter(isSkill)
        let places = actions.filter(isPlacement)
        guard !skills.isEmpty, places.count >= 2 else { return nil }
        var candidates: [(label: String, moves: [GameAction], final: GameState)] = []
        func accept(_ label: String, _ moves: [GameAction]) {
            guard let end = record(state, moves), end.status != .ongoing || end.current != state.current else { return }
            candidates.append((label, moves, end))
        }
        for skill in sampled(skills, cap: 6) {
            guard let afterSkill = record(state, [skill]), afterSkill.status == .ongoing,
                  afterSkill.current == state.current else { continue }
            let second = GameEngine.legalActions(afterSkill, expansionCandidateLimit: 256).filter(isPlacement)
            for move in sampled(second, cap: 4) { accept("skill-place", [skill, move]) }
        }
        for place in sampled(places, cap: 6) {
            guard let afterPlace = record(state, [place]), afterPlace.status == .ongoing,
                  afterPlace.current == state.current else { continue }
            let second = GameEngine.legalActions(afterPlace, expansionCandidateLimit: 256).filter(isSkill)
            for move in sampled(second, cap: 4) { accept("place-skill", [place, move]) }
            let two = GameEngine.legalActions(afterPlace, expansionCandidateLimit: 256).filter(isPlacement)
            for move in sampled(two, cap: 4) { accept("place-place", [place, move]) }
        }
        let groups = ["skill-place", "place-skill", "place-place"]
        var summary: [[String: Any]] = []
        for group in groups {
            let subset = candidates.filter { $0.label == group }
            let geometry = Set(subset.map { $0.final.board.diagram })
            let myLibs = subset.map { ownedLiberties($0.final, state.current) }
            let enemyLibs = subset.map { ownedLiberties($0.final, state.current.opponent) }
            summary.append(["type": group, "sampledLegalPlans": subset.count,
                            "distinctBoards": geometry.count,
                            "myCommanderLibertiesRange": myLibs.isEmpty ? [] : [myLibs.min()!, myLibs.max()!],
                            "enemyCommanderLibertiesRange": enemyLibs.isEmpty ? [] : [enemyLibs.min()!, enemyLibs.max()!]])
        }
        let canCompare = groups.allSatisfy { group in candidates.contains { $0.label == group } }
        guard canCompare else { return nil }
        return ["id": id, "ply": state.ply, "actor": state.current.rawValue,
                "hero": state.heroClass(of: state.current).rawValue,
                "boardBefore": state.board.diagram, "manaBefore": state.mana(of: state.current),
                "legalSkillsInBoundedEnumeration": skills.count,
                "legalPlacements": places.count, "groups": summary,
                "method": "6 evenly-spaced root choices per type x up to 4 legal second actions; Core settlement and full history preserved",
                "claim": "legal two-AP alternatives exist; no dominance, safety, or fun proven"]
    }

    func testP0NormalOpeningAndConditionalP1Witnesses() throws {
        let fixtures: [Fixture] = [
            .init(id: "7-w-m", size: 7, black: .warrior, white: .mage, plyLimit: 44),
            .init(id: "7-m-w", size: 7, black: .mage, white: .warrior, plyLimit: 44),
            .init(id: "7-r-p", size: 7, black: .rogue, white: .priest, plyLimit: 44),
            .init(id: "7-p-r", size: 7, black: .priest, white: .rogue, plyLimit: 44),
            .init(id: "9-w-m", size: 9, black: .warrior, white: .mage, plyLimit: 16)
        ]
        let env = ProcessInfo.processInfo.environment
        // Defaults bounded for CI; controlled reruns can reduce, not silently expand, the cohort.
        let gameCount = max(1, min(fixtures.count, Int(env["TG12_GAME_COUNT"] ?? "") ?? fixtures.count))
        let plyCap = max(4, min(100, Int(env["TG12_PLY_CAP"] ?? "") ?? 100))
        var turns: [[String: Any]] = []
        var games: [[String: Any]] = []
        var witnesses: [[String: Any]] = []
        var totals: [String: Int] = [:]
        let startClock = ProcessInfo.processInfo.systemUptime

        for fixture in fixtures.prefix(gameCount) {
            var config = RuleConfig.board(size: fixture.size)
            config.expansionSkills = true
            config.expansionSkillManaCost = 4
            config.bastionScope = .connectedGroup
            config.experimentalFriendlyRedeploy = true
            let initial = try GameSetup.newGame(config: config, classOne: fixture.black, classTwo: fixture.white)
            var state = initial
            var observed: [(action: GameAction, state: GameState)] = []
            var thisGameTurns = 0
            var thisGamePasses = 0
            var longestPassStreak = 0
            var consecutivePasses = 0
            while state.status == .ongoing, state.ply <= min(fixture.plyLimit, plyCap) {
                let before = state
                let actions = GameEngine.legalActions(before, expansionCandidateLimit: 256)
                let legalSkills = actions.filter(isSkill)
                let ordinaryLegal = actions.filter(isPlacement)
                let heroPresent = before.board.find(before.current, .hero) != nil
                let plan = try XCTUnwrap(BotPlanner.planTurn(before, difficulty: .standard), "\(fixture.id) ply \(before.ply)")
                let chosenSkill = plan.actions.contains(where: isSkill)
                let chosenPlacement = plan.actions.contains(where: isPlacement)
                let purePass = plan.actions.allSatisfy { $0 == .endTurn }
                let selected = plan.actions.map(kind)
                let fullMana = before.mana(of: before.current) == before.config.manaCap
                if purePass { consecutivePasses += 1; thisGamePasses += 1 }
                else { consecutivePasses = 0 }
                longestPassStreak = max(longestPassStreak, consecutivePasses)
                thisGameTurns += 1
                totals["turns", default: 0] += 1
                if heroPresent { totals["heroPresentTurns", default: 0] += 1 }
                if !legalSkills.isEmpty { totals["skillLegalTurns", default: 0] += 1 }
                if chosenSkill { totals["skillChosenTurns", default: 0] += 1 }
                if chosenSkill && chosenPlacement { totals["skillAndPlaceTurns", default: 0] += 1 }
                if purePass { totals["purePassTurns", default: 0] += 1 }
                if purePass && fullMana { totals["purePassAtFullMana", default: 0] += 1 }
                if purePass && actions.filter({ $0 != .endTurn }).count > 0 { totals["passDespiteOtherLegalAction", default: 0] += 1 }
                if witnesses.count < 6, let witness = probeP1(before, id: fixture.id) {
                    witnesses.append(witness)
                }
                turns.append(["game": fixture.id, "ply": before.ply, "actor": before.current.rawValue,
                              "hero": before.heroClass(of: before.current).rawValue,
                              "heroPresent": heroPresent, "mana": before.mana(of: before.current),
                              "legalSkillsBounded": legalSkills.count, "legalOrdinaryPlacements": ordinaryLegal.count,
                              "skillUsed": chosenSkill, "skillAndPlace": chosenSkill && chosenPlacement,
                              "selectedKinds": selected, "purePass": purePass, "fullMana": fullMana,
                              "otherLegalWhenPassed": actions.filter({ $0 != .endTurn }).count,
                              "myCommanderLiberties": ownedLiberties(before, before.current),
                              "enemyCommanderLiberties": ownedLiberties(before, before.current.opponent)])
                for action in plan.actions {
                    let next = GameEngine.apply(state, action)
                    XCTAssertTrue(next.success, "\(fixture.id) ply \(state.ply) \(action): \(next.reason)")
                    guard next.success else { return }
                    observed.append((action, next.state))
                    state = next.state
                }
                XCTAssertTrue(state.status != .ongoing || state.current != before.current,
                              "Bot returned incomplete turn: \(fixture.id), ply \(before.ply)")
            }
            var replay = initial
            for (action, expectedState) in observed {
                let next = GameEngine.apply(replay, action)
                XCTAssertTrue(next.success, "Replay must accept every legal bot receipt")
                XCTAssertEqual(next.state, expectedState, "Full Core state and superko history must match")
                replay = next.state
            }
            XCTAssertEqual(replay, state)
            totals["games", default: 0] += 1
            if state.status == .drawn { totals["coreDraws", default: 0] += 1 }
            if state.status == .won { totals["coreWins", default: 0] += 1 }
            games.append(["id": fixture.id, "size": fixture.size, "classOne": fixture.black.rawValue,
                          "classTwo": fixture.white.rawValue, "turns": thisGameTurns,
                          "passes": thisGamePasses, "longestConsecutiveBothSidesPass": longestPassStreak,
                          "finalPly": state.ply, "finalStatus": state.status.rawValue,
                          "censoredAtPlyCap": state.status == .ongoing,
                          "replayedFullState": replay == state])
        }
        let output: [String: Any] = [
            "kind": "TG12_GAMEPLAY_P0_P1_RESEARCH_V1", "origin": "formal newGame; baseline Standard Bot both colours",
            "config": ["expansionSkills": true, "advancedCost": 4, "bastionScope": "connectedGroup",
                       "experimentalFriendlyRedeploy": true, "difficulty": "standard", "gameCount": gameCount,
                       "perGamePlyCap": plyCap, "skillEnumerationLimit": 256],
            "summary": totals, "games": games, "turns": turns, "p1NaturalWitnesses": witnesses,
            "p1Gate": witnesses.isEmpty ? "HOLD: no mixed legal plans found in this sample" : "CANDIDATE: factual legal alternatives only; reply safety and human value unproven",
            "seconds": ProcessInfo.processInfo.systemUptime - startClock,
            "limits": ["only fixed pairings and Standard Bot", "game caps censor outcomes",
                       "legal advanced candidate enumeration limited to 256 per state",
                       "P1 sampled choices cannot prove strategy dominance", "no human playtest"]
        ]
        let data = try JSONSerialization.data(withJSONObject: output, options: [.sortedKeys])
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))
        print("TG12_P0_RESULT_JSON_BEGIN")
        print(json)
        print("TG12_P0_RESULT_JSON_END")
        XCTAssertEqual(games.count, gameCount)
        XCTAssertGreaterThan(totals["turns", default: 0], 0)
    }
}
