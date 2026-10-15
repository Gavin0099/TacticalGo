import Foundation
import TacticalGoCore
import TacticalGoBot

@main struct BotRunner {
    static func main() throws {
        let arguments = CommandLine.arguments
        if arguments.count > 4, arguments[1] == "--layer-trace" {
            try layerTrace(arguments[2], ply: Int(arguments[3])!, out: arguments[4]); return
        }
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
        if arguments.count > 4, arguments[1] == "--p1-probes" {
            try p1Probes(arguments[2], ply: Int(arguments[3])!, out: arguments[4]); return
        }
        if arguments.count > 4, arguments[1] == "--p1-pass-witness" {
            try p1PassWitness(arguments[2], ply: Int(arguments[3])!, out: arguments[4]); return
        }
        let out = arguments.count > 1 ? arguments[1] : "bot-match.json"
        let classOne = arguments.count > 2 ? HeroClass(rawValue: arguments[2]) ?? .warrior : .warrior
        let classTwo = arguments.count > 3 ? HeroClass(rawValue: arguments[3]) ?? .mage : .mage
        let difficulty = arguments.count > 4 ? BotDifficulty(rawValue: arguments[4]) ?? .standard : .standard
        let ruleName = arguments.count > 5 ? arguments[5] : "original"
        let ruleConfig = p1Config(ruleName)
        var state = try GameSetup.newGame(config: ruleConfig, classOne: classOne, classTwo: classTwo)
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
                actions.append(["action": encoded(action), "events": outcome.events.map(\.name), "eventPayloads": outcome.events.map { String(reflecting: $0) }, "boardAfter": outcome.state.board.diagram,
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
        var replay = try GameSetup.newGame(config: ruleConfig, classOne: classOne, classTwo: classTwo)
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
        let report: [String: Any] = ["setup": ["boardSize": 7, "classOne": classOne.rawValue, "classTwo": classTwo.rawValue, "defaultRules": ruleName == "original", "rules": ruleName, "difficulty": difficulty.rawValue],
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
        var state = try GameSetup.newGame(config: p1Config(setup["rules"] as? String ?? "original"), classOne: classOne, classTwo: classTwo)
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
                      outcome.events.map(\.name) == item["events"] as! [String],
                      (item["eventPayloads"] == nil || outcome.events.map { String(reflecting:$0) } == item["eventPayloads"] as! [String]) else { throw RunnerError.replay }
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
        var state = try GameSetup.newGame(config: p1Config(setup["rules"] as? String ?? "original"), classOne: HeroClass(rawValue: setup["classOne"] as! String)!, classTwo: HeroClass(rawValue: setup["classTwo"] as! String)!)
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
        var state = try GameSetup.newGame(config: p1Config(setup["rules"] as? String ?? "original"), classOne: HeroClass(rawValue: setup["classOne"] as! String)!, classTwo: HeroClass(rawValue: setup["classTwo"] as! String)!)
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
    static func p1Config(_ name: String) -> RuleConfig {
        precondition(name == "original" || name == "candidate")
        var c = RuleConfig.board(size: 7)
        if name == "candidate" { c.bastionScope = .connectedGroup; c.experimentalFriendlyRedeploy = true }
        return c
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

extension BotRunner {
    static func p1Probes(_ path: String, ply: Int, out: String) throws {
        let report = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath:path))) as! [String:Any]
        let setup = report["setup"] as! [String:Any]
        let classes = (HeroClass(rawValue:setup["classOne"] as! String)!, HeroClass(rawValue:setup["classTwo"] as! String)!)
        var original = try GameSetup.newGame(config:p1Config("original"),classOne:classes.0,classTwo:classes.1)
        var candidate = try GameSetup.newGame(config:p1Config("candidate"),classOne:classes.0,classTwo:classes.1)
        var sourceSteps=0
        for turn in report["turns"] as! [[String:Any]] {
            if original.ply == ply { break }
            for item in turn["actions"] as! [[String:Any]] {
                let action = try decoded(item["action"] as! [String:Any])
                let a=GameEngine.apply(original,action), b=GameEngine.apply(candidate,action)
                guard a.success,b.success,a.state.board==b.state.board,a.events==b.events else { throw RunnerError.replay }
                original=a.state;candidate=b.state;sourceSteps += 1
            }
        }
        guard original.ply==ply else { throw RunnerError.replay }
        func liberties(_ state:GameState, _ who:Player, _ kind:PieceKind)->Int {
            guard let point=state.board.find(who,kind) else { return -1 }
            return state.board.liberties(at:point).count
        }
        func summary(_ state:GameState)->[String:Any] {
            ["board":state.board.diagram,"ply":state.ply,"current":state.current.rawValue,"ap":state.apRemaining,
             "manaOne":state.mana(of:.one),"manaTwo":state.mana(of:.two),"status":state.status.rawValue,
             "ownCommanderLiberties":liberties(state,original.current,.commander),
             "ownHeroLiberties":liberties(state,original.current,.hero)]
        }
        var variants:[[String:Any]]=[]
        for (name,state) in [("original",original),("candidate",candidate)] {
            let legal=GameEngine.legalActions(state)
            let skills=legal.filter { action in switch action {case .castBastion,.castMagicHand,.castFriendlyRedeploy,.castSwap:return true;default:return false} }
            var options:[[String:Any]]=[]
            for action in skills {
                let outcome=GameEngine.apply(state,action)
                guard outcome.success else { throw RunnerError.illegal }
                var handedOver=outcome.state
                if handedOver.status == .ongoing && handedOver.current == state.current { handedOver=GameEngine.apply(handedOver,.endTurn).state }
                let replyWins=handedOver.status != .ongoing ? [] : GameEngine.legalActions(handedOver).filter { GameEngine.apply(handedOver,$0).state.winner == handedOver.current }
                var row:[String:Any]=["action":encoded(action),"result":summary(outcome.state),"eventsPayloads":outcome.events.map{String(reflecting:$0)},"enemyOneActionWinsAfterOptionalEndTurn":replyWins.map(encoded)]
                if case .castBastion(let a,let b)=action {
                    var ordinary:[[String:Any]]=[]
                    for order in [[a,b],[b,a]] {
                        var s=state;var errors:[String]=[]
                        for point in order {
                            let result=GameEngine.apply(s,.placeSoldier(point));errors.append(result.reason.rawValue)
                            if !result.success { break };s=result.state
                        }
                        ordinary.append(["points":order.map{[$0.x,$0.y]},"errors":errors,"bothLegal":errors.count==2 && errors.allSatisfy{$0=="None"},"result":summary(s)])
                    }
                    row["ordinaryTwoOrders"]=ordinary
                }
                options.append(row)
            }
            var plans:[[String:Any]]=[]
            for difficulty in [BotDifficulty.easy,.standard] {
                guard let plan=BotPlanner.planTurn(state,difficulty:difficulty) else { throw RunnerError.noPlan }
                var s=state
                for action in plan.actions {let result=GameEngine.apply(s,action);guard result.success else {throw RunnerError.illegal};s=result.state}
                plans.append(["difficulty":difficulty.rawValue,"actions":plan.actions.map(encoded),"reasons":plan.reasons,
                    "score":plan.score,"result":summary(s),"budgetExhausted":plan.stats.budgetExhausted,
                    "rootActionComparisons":plan.stats.rootActionComparisons,"ownTurnComparisons":plan.stats.ownTurnComparisons,
                    "candidateComparisons":plan.stats.candidateComparisons,"passDiagnostics":plan.stats.passDiagnostics])
            }
            variants.append(["variant":name,"initial":summary(state),"legalSkills":skills.count,"options":options,"plans":plans])
        }
        let output:[String:Any]=["formalSource":path,"sourceSteps":sourceSteps,"sourcePly":ply,"variants":variants,
            "notClaimed":["human enjoyment","best play","balanced","two-action opponent proof"]]
        try JSONSerialization.data(withJSONObject:output,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:out))
        print("PASS paired formal probes ply \(ply), \(sourceSteps) source steps")
    }
}

extension BotRunner {
    static func p1PassWitness(_ path:String,ply:Int,out:String)throws {
        let report=try JSONSerialization.jsonObject(with:Data(contentsOf:URL(fileURLWithPath:path))) as! [String:Any]
        let setup=report["setup"] as! [String:Any]
        var state=try GameSetup.newGame(config:p1Config(setup["rules"] as? String ?? "original"),classOne:HeroClass(rawValue:setup["classOne"] as! String)!,classTwo:HeroClass(rawValue:setup["classTwo"] as! String)!)
        var steps=0
        for turn in report["turns"] as! [[String:Any]] {
            if state.ply==ply {break}
            for item in turn["actions"] as! [[String:Any]] {
                let r=GameEngine.apply(state,try decoded(item["action"] as! [String:Any]))
                guard r.success,r.state.board.diagram==item["boardAfter"] as! String,r.events.map({String(reflecting:$0)})==item["eventPayloads"] as! [String] else {throw RunnerError.replay}
                state=r.state;steps += 1
            }
        }
        guard state.ply==ply else {throw RunnerError.replay}
        let me=state.current
        var rows:[[String:Any]]=[]
        for action in GameEngine.legalActions(state) {
            let move=GameEngine.apply(state,action)
            var hand=move.state
            if hand.status == .ongoing && hand.current==me {hand=GameEngine.apply(hand,.endTurn).state}
            let wins=hand.status != .ongoing ? [] : GameEngine.legalActions(hand).compactMap { a -> [String:Any]? in
                let r=GameEngine.apply(hand,a)
                return r.state.winner==me.opponent ? ["reply":encoded(a),"boardAfter":r.state.board.diagram,"fullEvents":r.events.map{String(reflecting:$0)}] : nil
            }
            var twoActionWitness: [[String:Any]]=[]
            if hand.status == .ongoing {
                for first in GameEngine.legalActions(hand) {
                    let a=GameEngine.apply(hand,first)
                    if a.state.winner==me.opponent {twoActionWitness.append(["actions":[encoded(first)],"boardAfter":a.state.board.diagram]);break}
                    if a.state.status == .ongoing && a.state.current==me.opponent {
                        if let second=GameEngine.legalActions(a.state).first(where:{GameEngine.apply(a.state,$0).state.winner==me.opponent}) {
                            let b=GameEngine.apply(a.state,second)
                            twoActionWitness.append(["actions":[encoded(first),encoded(second)],"boardAfter":b.state.board.diagram,"fullEvents":b.events.map{String(reflecting:$0)}]);break
                        }
                    }
                }
            }
            rows.append(["action":encoded(action),"boardAfter":move.state.board.diagram,"ownCommanderLiberties":move.state.board.find(me,.commander).map{move.state.board.liberties(at:$0).count} ?? -1,"enemyOneActionWinAfterEndTurn":wins,"enemyUpToTwoActionsWinAfterEndTurn":twoActionWitness])
        }
        try JSONSerialization.data(withJSONObject:["formalSource":path,"sourceSteps":steps,"ply":ply,"rows":rows,"scope":"First action followed by voluntary endTurn; exhaustive enemy up-to-two legal actions, first win witness only; does not exclude a better two-action own plan"],options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:out))
        print("PASS independent Core witnesses ply \(ply), \(rows.count) first actions")
    }
    static func layerTrace(_ path: String, ply: Int, out: String) throws {
        func summary(_ state: GameState) -> [String:Any] {
            ["board":state.board.diagram,"ply":state.ply,"current":state.current.rawValue,
             "ap":state.apRemaining,"status":String(describing:state.status)]
        }
        let data = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String:Any]
        let setup = data["setup"] as! [String:Any]
        var state = try GameSetup.newGame(config: p1Config(setup["rules"] as? String ?? "original"),
            classOne: HeroClass(rawValue: setup["classOne"] as! String)!, classTwo: HeroClass(rawValue: setup["classTwo"] as! String)!)
        var steps = 0
        for turn in data["turns"] as! [[String:Any]] {
            if state.ply == ply { break }
            for item in turn["actions"] as! [[String:Any]] {
                let result = GameEngine.apply(state, try decoded(item["action"] as! [String:Any]))
                guard result.success, result.state.board.diagram == item["boardAfter"] as! String,
                      result.events.map({String(reflecting:$0)}) == item["eventPayloads"] as! [String] else { throw RunnerError.replay }
                state = result.state; steps += 1
            }
        }
        guard state.ply == ply else { throw RunnerError.replay }
        let modes: [(String,BotLimits)] = [
            ("baseline", .standard),
            ("own-width-only", BotLimits(maxDomainTransitions:30_000,ownBeamWidth:32,replyBeamWidth:3,replyCandidates:8)),
            ("complete-cap-only", BotLimits(maxDomainTransitions:30_000,ownBeamWidth:10,replyBeamWidth:3,replyCandidates:32)),
            ("reply-width-only", BotLimits(maxDomainTransitions:30_000,ownBeamWidth:10,replyBeamWidth:8,replyCandidates:8)),
            ("wide-all", BotLimits(maxDomainTransitions:30_000,ownBeamWidth:32,replyBeamWidth:8,replyCandidates:32))]
        var runs: [[String:Any]] = []
        for (name, limits) in modes {
            guard let plain = BotPlanner.planTurn(state, limits:limits),
                  let plan = BotPlanner.planTurn(state, limits:limits,diagnostics:true) else { throw RunnerError.noPlan }
            guard plain.actions == plan.actions, plain.score == plan.score, plain.reasons == plan.reasons,
                  plain.stats.domainTransitions == plan.stats.domainTransitions,
                  plain.stats.candidateComparisons == plan.stats.candidateComparisons else { throw RunnerError.replay }
            var after = state; var accepted: [[String:Any]] = []
            for action in plan.actions {
                guard after.current == state.current, after.status == .ongoing else { throw RunnerError.crossedTurn }
                let result = GameEngine.apply(after,action); guard result.success else {throw RunnerError.illegal}
                accepted.append(["action":encoded(action),"events":result.events.map{String(reflecting:$0)},"result":summary(result.state)])
                after = result.state
            }
            var witness: [GameAction] = []; var replyChecks = 0
            if after.status == .ongoing {
                for first in GameEngine.legalActions(after) {
                    let a = GameEngine.apply(after,first); replyChecks += 1
                    if a.state.winner == state.current.opponent { witness=[first]; break }
                    if a.state.status == .ongoing && a.state.current == state.current.opponent {
                        for second in GameEngine.legalActions(a.state) {
                            let b = GameEngine.apply(a.state,second); replyChecks += 1
                            if b.state.winner == state.current.opponent { witness=[first,second];break }
                        }
                    }
                    if !witness.isEmpty {break}
                }
            }
            let trace = try JSONSerialization.jsonObject(with:JSONEncoder().encode(plan.stats.candidateTrace))
            runs.append(["mode":name,"limits":["own":limits.ownBeamWidth,"reply":limits.replyBeamWidth,"complete":limits.replyCandidates,"transitions":limits.maxDomainTransitions],
                "actions":accepted,"score":plan.score,"comparisons":plan.stats.candidateComparisons,"reason":plan.reasons,
                "transitions":plan.stats.domainTransitions,"budgetExhausted":plan.stats.budgetExhausted,"traceTruncated":plan.stats.traceTruncated,
                "trace":trace,"traceDoesNotChangeDecision":true,"enemyUpToTwoActionWin":witness.map(encoded),"independentReplyChecks":replyChecks])
            print("\(name) ply \(ply): \(plan.actions.map(botActionDescription)), score \(plan.score), trace \(plan.stats.candidateTrace.count)")
        }
        let report:[String:Any] = ["source":path,"sourceSteps":steps,"rules":setup["rules"] as? String ?? "original","ply":ply,
            "board":state.board.diagram,"runs":runs,"classification":"undetermined-pending-complete-turn-comparison",
            "scope":"Fixed production evaluation; only configured widths differ. Independent enemy up-to-two-turn-actions wins enumerated; no absence-of-witness absolute safety claim."]
        try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:out))
    }

}
