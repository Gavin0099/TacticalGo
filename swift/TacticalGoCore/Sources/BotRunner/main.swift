import Foundation
import TacticalGoCore
import TacticalGoBot

@main struct BotRunner {
    static func main() throws {
        let arguments = CommandLine.arguments
        if arguments.count > 3, arguments[1] == "--pass-audit" {
            try passAudit(arguments[2], out: arguments[3]); return
        }
        if arguments.count > 3, arguments[1] == "--diagnose" {
            try diagnoseFile(arguments[2], out: arguments[3]); return
        }
        if arguments.count > 2, arguments[1] == "--replay" {
            try replayFile(arguments[2]); return
        }
        if arguments.count > 2, arguments[1] == "--benchmark" {
            try benchmark(arguments[2], difficulty: arguments.count > 3 ? BotDifficulty(rawValue: arguments[3]) ?? .standard : .standard); return
        }
        let out = arguments.count > 1 ? arguments[1] : "bot-match.json"
        let classOne = arguments.count > 2 ? HeroClass(rawValue: arguments[2]) ?? .warrior : .warrior
        let classTwo = arguments.count > 3 ? HeroClass(rawValue: arguments[3]) ?? .mage : .mage
        let difficulty = arguments.count > 4 ? BotDifficulty(rawValue: arguments[4]) ?? .standard : .standard
        var state = try GameSetup.newGame(config: .board(size: 7), classOne: classOne, classTwo: classTwo)
        var records: [[String: Any]] = []
        var elapsed: [Double] = []
        while state.status == .ongoing {
            let start = ProcessInfo.processInfo.systemUptime
            guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
            let seconds = ProcessInfo.processInfo.systemUptime - start
            elapsed.append(seconds)
            let before = state
            let availability = skillAvailability(before)
            var actions: [[String: Any]] = []
            for action in plan.actions {
                guard state.current == before.current, state.status == .ongoing else { throw RunnerError.crossedTurn }
                let outcome = GameEngine.apply(state, action)
                guard outcome.success else { throw RunnerError.illegal }
                actions.append(["action": encoded(action), "events": outcome.events.map(\.name), "boardAfter": outcome.state.board.diagram,
                                "apAfter": outcome.state.apRemaining, "manaOneAfter": outcome.state.mana(of: .one), "manaTwoAfter": outcome.state.mana(of: .two),
                                "currentAfter": outcome.state.current.rawValue, "plyAfter": outcome.state.ply])
                state = outcome.state
            }
            records.append(["ply": before.ply, "player": before.current.rawValue, "boardBefore": before.board.diagram,
                            "actions": actions, "reasons": plan.reasons, "score": plan.score, "seconds": seconds,
                            "explicitDomainTransitions": plan.stats.domainTransitions, "legalEnumerations": plan.stats.legalEnumerations,
                            "candidateComparisons": plan.stats.candidateComparisons, "budgetExhausted": plan.stats.budgetExhausted,
                            "rootActionComparisons": plan.stats.rootActionComparisons, "ownTurnComparisons": plan.stats.ownTurnComparisons,
                            "passDiagnostics": plan.stats.passDiagnostics,
                            "skillAvailability": availability,
                            "difficulty": plan.stats.difficulty.rawValue, "searchesOpponentTurn": plan.stats.searchesOpponentTurn])
            print("ply \(before.ply): \(plan.actions.map(botActionDescription).joined(separator: " / ")) \(String(format: "%.3f", seconds))s")
            guard records.count <= 100 else { throw RunnerError.loop }
        }
        // Independently replay every recorded action from the formal setup; compare full states after every turn.
        var replay = try GameSetup.newGame(config: .board(size: 7), classOne: classOne, classTwo: classTwo)
        for record in records {
            for item in record["actions"] as! [[String: Any]] {
                let action = try decoded(item["action"] as! [String: Any])
                let outcome = GameEngine.apply(replay, action)
                guard outcome.success, outcome.state.board.diagram == item["boardAfter"] as! String,
                      outcome.state.apRemaining == item["apAfter"] as! Int,
                      outcome.state.mana(of: .one) == item["manaOneAfter"] as! Int,
                      outcome.state.mana(of: .two) == item["manaTwoAfter"] as! Int else { throw RunnerError.replay }
                replay = outcome.state
            }
        }
        guard replay == state else { throw RunnerError.replay }
        let report: [String: Any] = ["setup": ["boardSize": 7, "classOne": classOne.rawValue, "classTwo": classTwo.rawValue, "defaultRules": true, "difficulty": difficulty.rawValue],
                                    "turns": records, "status": state.status.rawValue, "winner": state.winner?.rawValue as Any? ?? NSNull(),
                                    "finalBoard": state.board.diagram, "replayFullStateEqual": true,
                                    "skillAvailabilitySummary": skillSummary(records.compactMap { $0["skillAvailability"] as? [String: Any] }),
                                    "maxSeconds": elapsed.max() ?? 0, "meanSeconds": elapsed.reduce(0,+) / Double(elapsed.count),
                                    "notClaimed": ["human fun acceptance", "balance", "strong AI", "iPhone performance"]]
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: URL(fileURLWithPath: out))
    }
    static func replayFile(_ path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let report = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let setup = report["setup"] as! [String: Any]
        let classOne = HeroClass(rawValue: setup["classOne"] as! String)!
        let classTwo = HeroClass(rawValue: setup["classTwo"] as! String)!
        var state = try GameSetup.newGame(config: .board(size: 7), classOne: classOne, classTwo: classTwo)
        var count = 0
        for record in report["turns"] as! [[String: Any]] {
            guard state.board.diagram == record["boardBefore"] as! String,
                  state.current.rawValue == record["player"] as! Int,
                  state.ply == record["ply"] as! Int else { throw RunnerError.replay }
            let owner = state.current
            for item in record["actions"] as! [[String: Any]] {
                guard state.status == .ongoing, state.current == owner else { throw RunnerError.crossedTurn }
                let outcome = GameEngine.apply(state, try decoded(item["action"] as! [String: Any]))
                guard outcome.success, outcome.state.board.diagram == item["boardAfter"] as! String,
                      outcome.state.apRemaining == item["apAfter"] as! Int,
                      outcome.state.mana(of: .one) == item["manaOneAfter"] as! Int,
                      outcome.state.mana(of: .two) == item["manaTwoAfter"] as! Int,
                      outcome.state.current.rawValue == item["currentAfter"] as! Int,
                      outcome.state.ply == item["plyAfter"] as! Int,
                      outcome.events.map(\.name) == item["events"] as! [String] else { throw RunnerError.replay }
                state = outcome.state; count += 1
            }
        }
        guard state.status.rawValue == report["status"] as! String,
              state.board.diagram == report["finalBoard"] as! String else { throw RunnerError.replay }
        print("PASS replay \(count) actions; status \(state.status.rawValue), ply \(state.ply)")
    }
    static func diagnoseFile(_ path: String, out: String) throws {
        let report = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any]
        let setup = report["setup"] as! [String: Any]
        let difficulty = BotDifficulty(rawValue: setup["difficulty"] as? String ?? "standard") ?? .standard
        var state = try GameSetup.newGame(config: .board(size: 7), classOne: HeroClass(rawValue: setup["classOne"] as! String)!, classTwo: HeroClass(rawValue: setup["classTwo"] as! String)!)
        for record in report["turns"] as! [[String: Any]] {
            let actions = record["actions"] as! [[String: Any]]
            let onlyPass = actions.count == 1 && (actions[0]["action"] as! [String: Any])["kind"] as! String == "endTurn"
            if onlyPass {
                let legal = GameEngine.legalActions(state)
                let nonPass = legal.filter { $0 != .endTurn }
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                let values: [String: Any] = ["ply": state.ply, "board": state.board.diagram, "player": state.current.rawValue,
                                            "legalNonPassCount": nonPass.count, "allLegalNonPassActions": nonPass.map(encoded),
                                            "chosen": plan.actions.map(encoded), "candidateComparisons": plan.stats.candidateComparisons,
                                            "replyCandidatesEvaluated": plan.stats.replyCandidates, "ownTurnCandidates": plan.stats.turnCandidates,
                                            "budgetExhausted": plan.stats.budgetExhausted,
                                            "scope": "All legal nonpass listed; score/replies compare only the bounded retained candidates, not proof of optimal play"]
                try JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out)); return
            }
            for item in actions {
                let outcome = GameEngine.apply(state, try decoded(item["action"] as! [String: Any]))
                guard outcome.success else { throw RunnerError.replay }; state = outcome.state
            }
        }
        throw RunnerError.noPlan
    }
    static func passAudit(_ path: String, out: String) throws {
        let report = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any]
        let setup = report["setup"] as! [String: Any]
        let difficulty = BotDifficulty(rawValue: setup["difficulty"] as? String ?? "standard") ?? .standard
        var state = try GameSetup.newGame(config: .board(size: 7), classOne: HeroClass(rawValue: setup["classOne"] as! String)!, classTwo: HeroClass(rawValue: setup["classTwo"] as! String)!)
        var seen: Set<Int> = [], rows: [[String: Any]] = [], availabilityRows: [[String: Any]] = []
        for record in report["turns"] as! [[String: Any]] {
            let items = record["actions"] as! [[String: Any]]
            let purePass = items.allSatisfy { ($0["action"] as! [String: Any])["kind"] as! String == "endTurn" }
            let legal = GameEngine.legalActions(state)
            availabilityRows.append(skillAvailability(state, legal: legal))
            let selected = (purePass && !seen.contains(state.current.rawValue)) || [20, 30, 40, 41, 42, 54, 55, 80].contains(state.ply)
            if selected {
                if purePass { seen.insert(state.current.rawValue) }
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                var probes: [[String: Any]] = []
                for action in legal {
                    let result = GameEngine.apply(state, action)
                    guard result.success else { throw RunnerError.illegal }
                    probes.append(["action": encoded(action), "after": result.state.board.diagram,
                                   "ownCommanderLiberties": result.state.board.find(state.current, .commander).map { result.state.board.liberties(at: $0).count } ?? 0,
                                   "enemyCommanderLiberties": result.state.board.find(state.current.opponent, .commander).map { result.state.board.liberties(at: $0).count } ?? 0,
                                   "ownHeroAlive": result.state.board.find(state.current, .hero) != nil,
                                   "manaAfter": result.state.mana(of: state.current), "events": result.events.map(\.name)])
                }
                rows.append(["ply": state.ply, "player": state.current.rawValue, "board": state.board.diagram,
                             "originalChosen": items.map { $0["action"]! }, "chosen": plan.actions.map(encoded),
                             "score": plan.score, "reasons": plan.reasons,
                             "allLegalFirstActions": probes, "rootActionComparisons": plan.stats.rootActionComparisons,
                             "ownTurnComparisons": plan.stats.ownTurnComparisons, "candidateComparisons": plan.stats.candidateComparisons,
                             "passDiagnostics": plan.stats.passDiagnostics,
                             "budgetExhausted": plan.stats.budgetExhausted,
                             "explicitDomainTransitions": plan.stats.domainTransitions, "legalEnumerations": plan.stats.legalEnumerations])
            }
            guard state.board.diagram == record["boardBefore"] as! String else { throw RunnerError.replay }
            for item in items {
                let outcome = GameEngine.apply(state, try decoded(item["action"] as! [String: Any]))
                guard outcome.success, outcome.state.board.diagram == item["boardAfter"] as! String,
                      outcome.events.map(\.name) == item["events"] as! [String],
                      outcome.state.apRemaining == item["apAfter"] as! Int,
                      outcome.state.current.rawValue == item["currentAfter"] as! Int,
                      outcome.state.ply == item["plyAfter"] as! Int else { throw RunnerError.replay }
                state = outcome.state
            }
        }
        let output: [String: Any] = ["sourceTrace": path, "difficulty": difficulty.rawValue, "fullSourceReplayVerified": true,
                                    "status": state.status.rawValue, "cases": rows,
                                    "skillAvailabilityByTurn": availabilityRows,
                                    "skillAvailabilitySummary": skillSummary(availabilityRows),
                                    "scope": "All Core legal first actions listed; own turns and replies are bounded retained candidates, not optimality proof"]
        try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
        print("PASS source replay and pass audit \(rows.count) cases, \(difficulty.rawValue)")
    }
    static func skillAvailability(_ state: GameState, legal: [GameAction]? = nil) -> [String: Any] {
        let legal = legal ?? GameEngine.legalActions(state)
        let skills = legal.filter { action in
            switch action { case .castBastion, .castMagicHand, .castFriendlyRedeploy, .castSwap, .castSeal: true; default: false }
        }
        return ["ply": state.ply, "player": state.current.rawValue, "heroClass": state.heroClass(of: state.current).rawValue,
                "heroPresent": state.board.find(state.current, .hero) != nil,
                "mana": state.mana(of: state.current), "manaEnough": state.mana(of: state.current) >= state.config.skillManaCost,
                "skillUnused": !state.skillUsedThisTurn, "ap": state.apRemaining,
                "legalSkillCount": skills.count, "legalSkills": skills.map(encoded), "board": state.board.diagram]
    }
    static func skillSummary(_ rows: [[String: Any]]) -> [[String: Any]] {
        HeroClass.allCases.filter { $0 != .none }.map { hero in
            let turns = rows.filter { $0["heroClass"] as! String == hero.rawValue }
            let present = turns.filter { $0["heroPresent"] as! Bool }
            let unavailable = present.filter { $0["manaEnough"] as! Bool && $0["skillUnused"] as! Bool && $0["ap"] as! Int > 0 && $0["legalSkillCount"] as! Int == 0 }
            return ["heroClass": hero.rawValue, "turns": turns.count, "heroPresentTurns": present.count,
                    "heroPresentManaEnoughButNoLegalSkillTurns": unavailable.count,
                    "representativeUnavailable": Array(unavailable.prefix(3)),
                    "representativeLateUnavailable": Array(unavailable.filter { $0["ply"] as! Int >= 20 }.suffix(3)),
                    "scope": "Actual Core skill legality for the actor. No claim original late-game skill constraints are solved."]
        }
    }
    static func benchmark(_ path: String, difficulty: BotDifficulty = .standard) throws {
        let first = try GameSetup.newGame(config: .board(size: 7), classOne: .warrior, classTwo: .mage)
        let normal = GameEngine.apply(first, .endTurn).state
        let fixtures: [(String, GameState)] = [
            ("formal-opening-first-1AP", first), ("formal-second-player-2AP", normal),
            ("commander-rescue", try GameSetup.fromDiagram(config: .board(size: 7), diagram: "..O....\n.......\n.......\n...o...\n..oXo..\n.......\n.......", classOne: .warrior, classTwo: .mage, manaOne: 5, ap: 2, ply: 15)),
            ("mage-two-action-capture", try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...x...\n..xOx..\n.H.o...\n.......\n.......\n...X...\n.......", classOne: .mage, manaOne: 5, ap: 2, ply: 15))
        ]
        var rows: [[String: Any]] = []
        for (name, state) in fixtures {
            let start = ProcessInfo.processInfo.systemUptime
            guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
            let seconds = ProcessInfo.processInfo.systemUptime - start
            rows.append(["name": name, "diagram": state.board.diagram, "actions": plan.actions.map(encoded), "reasons": plan.reasons,
                         "seconds": seconds, "explicitDomainTransitions": plan.stats.domainTransitions,
                         "legalEnumerations": plan.stats.legalEnumerations, "candidateComparisons": plan.stats.candidateComparisons, "budgetExhausted": plan.stats.budgetExhausted,
                         "difficulty": plan.stats.difficulty.rawValue, "searchesOpponentTurn": plan.stats.searchesOpponentTurn,
                         "opponentCandidatesEvaluated": plan.stats.replyCandidates])
        }
        let start = ProcessInfo.processInfo.systemUptime
        let cancelled = BotPlanner.planTurn(normal, difficulty: difficulty, cancelled: { ProcessInfo.processInfo.systemUptime - start >= 0.001 })
        let elapsed = ProcessInfo.processInfo.systemUptime - start
        let report: [String: Any] = ["platform": "macOS host; not iPhone", "cases": rows,
                                   "cancellation": ["requestedAfterSeconds": 0.001, "returnSeconds": elapsed, "returnedNil": cancelled == nil],
                                   "difficulty": difficulty.rawValue,
                                   "explicitTransitionBudget": (difficulty == .easy ? BotLimits.easy : BotLimits.standard).maxDomainTransitions,
                                   "budgetBoundary": "Core.legalActions internal validation calls are additional; legalEnumerations reported separately"]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: path))
        print("PASS benchmarks \(rows.count), cancel returnedNil \(cancelled == nil), \(elapsed)s")
    }
    enum RunnerError: Error { case noPlan, crossedTurn, illegal, loop, replay }
    static func encoded(_ action: GameAction) -> [String: Any] {
        func p(_ point: Point) -> [Int] { [point.x, point.y] }
        switch action {
        case .placeSoldier(let at): return ["kind": "placeSoldier", "at": p(at)]
        case .summonHero(let at): return ["kind": "summonHero", "at": p(at)]
        case .castBastion(let a, let b): return ["kind": "castBastion", "a": p(a), "b": p(b)]
        case .castMagicHand(let at, let direction): return ["kind": "castMagicHand", "at": p(at), "direction": direction.rawValue]
        case .castFriendlyRedeploy(let source, let destination): return ["kind": "castFriendlyRedeploy", "from": p(source), "to": p(destination)]
        case .castSwap(let at): return ["kind": "castSwap", "at": p(at)]
        case .castSeal(let at): return ["kind": "castSeal", "at": p(at)]
        case .endTurn: return ["kind": "endTurn"]
        }
    }
    static func decoded(_ value: [String: Any]) throws -> GameAction {
        func p(_ key: String) -> Point { let v = value[key] as! [Int]; return Point(v[0], v[1]) }
        switch value["kind"] as! String {
        case "placeSoldier": return .placeSoldier(p("at"))
        case "summonHero": return .summonHero(p("at"))
        case "castBastion": return .castBastion(p("a"), p("b"))
        case "castMagicHand": return .castMagicHand(p("at"), PushDirection(rawValue: value["direction"] as! String)!)
        case "castFriendlyRedeploy": return .castFriendlyRedeploy(p("from"), p("to"))
        case "castSwap": return .castSwap(p("at"))
        case "castSeal": return .castSeal(p("at"))
        case "endTurn": return .endTurn
        default: throw RunnerError.replay
        }
    }
}
