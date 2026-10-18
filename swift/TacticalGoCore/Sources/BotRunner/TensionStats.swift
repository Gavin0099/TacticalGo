import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoContent

/// TENSION-01 and BOT-TENSION-01 batch tools. Observation only: nothing here changes a rule, a bot choice or a save.
extension BotRunner {
    struct SeededSetup {
        let config: RuleConfig, classOne: HeroClass, classTwo: HeroClass
        var label: String { "\(classOne.rawValue)-vs-\(classTwo.rawValue)" }
    }
    static func ruleConfig(size: Int, rules: String) -> (RuleConfig, [HeroClass]) {
        var config = RuleConfig.board(size: size)
        if rules == "expansion" {
            config.expansionSkills = true; config.expansionSkillManaCost = 4
            config.bastionScope = .connectedGroup; config.experimentalFriendlyRedeploy = true
            return (config, [.warrior, .mage, .rogue, .priest])
        }
        return (config, HeroClass.originalClasses)
    }
    /// Same class pairs in rotation, both colours; every game starts from seeded random soldiers for plies 1-4
    /// (seed = game index) so identical setups do not replay identical games, and the whole batch is reproducible.
    static func seededStart(game: Int, size: Int, rules: String) throws -> GameState {
        let (config, classes) = ruleConfig(size: size, rules: rules)
        let pairs = classes.flatMap { a in classes.map { b in (a, b) } }
        let pair = pairs[game % pairs.count]
        var state = try GameSetup.newGame(config: config, classOne: pair.0, classTwo: pair.1)
        var seed = UInt64(game &+ 1) &* 0x9E3779B97F4A7C15
        func random(_ n: Int) -> Int { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return Int((seed >> 33) % UInt64(n)) }
        while state.status == .ongoing, state.ply <= 4 {
            let spots = state.board.points.filter { GameEngine.validate(state, .placeSoldier($0)) == .none }
            let action: GameAction = spots.isEmpty ? .endTurn : .placeSoldier(spots[random(spots.count)])
            let outcome = GameEngine.apply(state, action)
            guard outcome.success else { throw RunnerError.illegal }
            state = outcome.state
        }
        return state
    }
    static func phase(_ ply: Int) -> String { ply <= 20 ? "opening(5-20)" : ply <= 50 ? "middle(21-50)" : "late(51+)" }

    /// TENSION-01: sample natural positions from bot-vs-bot games and classify what the side to move can choose between.
    static func tensionStats(games: Int, out: String, difficulty: BotDifficulty, size: Int, rules: String, stride step: Int) throws {
        var counts: [String: Int] = [:]
        var byPhase: [String: [String: Int]] = [:], byClass: [String: [String: Int]] = [:]
        var samples: [String: [[String: Any]]] = [:]
        var rows: [[String: Any]] = []
        var closeCounts: [Int: Int] = [:]
        let started = ProcessInfo.processInfo.systemUptime
        // Shards: TENSION_FIRST offsets the game index (and so the seed), so parallel runs cover different games.
        let first = Int(ProcessInfo.processInfo.environment["TENSION_FIRST"] ?? "") ?? 0
        // The exact reply check grows steeply with the number of legal actions (tens of seconds per late position), so
        // sampling stops at TENSION_MAX_PLY (default 60). Late-game positions are therefore NOT covered by this study.
        let maxPly = Int(ProcessInfo.processInfo.environment["TENSION_MAX_PLY"] ?? "") ?? 60
        for game in first..<(first + games) {
            var state = try seededStart(game: game, size: size, rules: rules)
            let label = SeededSetup(config: state.config, classOne: state.heroClass(of: .one), classTwo: state.heroClass(of: .two)).label
            var turns = 0
            while state.status == .ongoing, turns < 120 {
                if turns % step == 0, state.ply <= maxPly {
                    let t0 = ProcessInfo.processInfo.systemUptime
                    let probe = TensionProbe.analyze(state, maxCandidates: 8)
                    let dt = ProcessInfo.processInfo.systemUptime - t0
                    if ProcessInfo.processInfo.environment["TENSION_TIMING"] != nil {
                        print("  probe ply \(state.ply) turn \(turns): \(String(format: "%.2f", dt))s, candidates \(probe?.candidateCount ?? 0)")
                    }
                    if let position = probe {
                    let verdict = position.verdict.rawValue
                    counts[verdict, default: 0] += 1; counts["positions", default: 0] += 1
                    byPhase[phase(state.ply), default: [:]][verdict, default: 0] += 1
                    byPhase[phase(state.ply), default: [:]]["positions", default: 0] += 1
                    byClass[label, default: [:]][verdict, default: 0] += 1
                    byClass[label, default: [:]]["positions", default: 0] += 1
                    closeCounts[position.closeDistinct.count, default: 0] += 1
                    let row: [String: Any] = ["game": game, "setup": label, "ply": state.ply, "player": state.current.rawValue,
                        "mana": state.mana(of: state.current), "ap": state.apRemaining, "board": state.board.diagram,
                        "verdict": verdict, "candidates": position.candidateCount, "safe": position.safe.count,
                        "closeDistinctSignatures": position.closeDistinct.map(\.signature),
                        "closeDistinctKeys": position.closeDistinct.map(\.key),
                        "bestSafeScore": position.bestSafeScore as Any? ?? NSNull()]
                    rows.append(row)
                    if samples[verdict, default: []].count < 4 { samples[verdict, default: []].append(row) }
                    }
                }
                let p0 = ProcessInfo.processInfo.systemUptime
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                if ProcessInfo.processInfo.environment["TENSION_TIMING"] != nil {
                    print("  plan ply \(state.ply): \(String(format: "%.2f", ProcessInfo.processInfo.systemUptime - p0))s")
                }
                for action in plan.actions {
                    let outcome = GameEngine.apply(state, action)
                    guard outcome.success else { throw RunnerError.illegal }
                    state = outcome.state
                }
                turns += 1
            }
            print("game \(game) \(label): \(state.status.rawValue) after \(turns) turns; positions so far \(counts["positions", default: 0])")
        }
        let report: [String: Any] = [
            "setup": ["games": games, "difficulty": difficulty.rawValue, "boardSize": size, "rules": rules, "sampleEveryNthTurn": step, "maxPly": maxPly,
                      "opening": "seeded random soldiers for plies 1-4 (seed = game index), then bot vs bot",
                      "candidateSet": "planner-retained complete own turns, up to 8 distinct outcomes (the best by the planner's own-turn score); not every legal turn",
                      "exactFacts": "captures enemy commander; opponent has some complete reply that captures ours (Core, bounded by expansionCandidateLimit 256)",
                      "botRelativeFact": "close = own-turn heuristic score within 120 of the best safe turn (the planner's easy-relaxed gap)"],
            "counts": counts, "byPhase": byPhase, "bySetup": byClass,
            "closeDistinctSignatureHistogram": closeCounts.sorted { $0.key < $1.key }.map { ["signatures": $0.key, "positions": $0.value] },
            "samples": samples, "positions": rows, "seconds": ProcessInfo.processInfo.systemUptime - started,
            "notClaimed": ["human decision quality", "that alternatives are equally good", "balance", "fun"]]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
        print("counts:", counts.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
    }
}

/// BOT-TENSION-01 step 1: describe how the computer actually plays whole games before anything about it is changed.
/// Everything is read from the engine's own events and board; no rating or heuristic is involved.
extension BotRunner {
    static func botBehavior(games: Int, out: String, difficulty: BotDifficulty, size: Int, rules: String) throws {
        let first = Int(ProcessInfo.processInfo.environment["TENSION_FIRST"] ?? "") ?? 0
        var rows: [[String: Any]] = []
        var totals: [String: Int] = [:]
        for game in first..<(first + games) {
            var state = try seededStart(game: game, size: size, rules: rules)
            let setup = "\(state.heroClass(of: .one).rawValue)-vs-\(state.heroClass(of: .two).rawValue)"
            var turns = 0, passTurns = 0, passFullMana = 0, passLowMana = 0, captures = 0, lastActiveTurn = 0
            var threats = 0, converted = 0
            var pendingThreat: [(player: Player, turn: Int)] = []
            var skillTurns = 0, summonTurns = 0
            while state.status == .ongoing, turns < 120 {
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                let mover = state.current, manaBefore = state.mana(of: mover)
                let enemyLibBefore = state.board.find(mover.opponent, .commander).map { state.board.liberties(at: $0).count } ?? 0
                let pure = plan.actions.allSatisfy { $0 == .endTurn }
                var capturedNow = 0, active = false, usedSkill = false, summoned = false
                for action in plan.actions {
                    let outcome = GameEngine.apply(state, action)
                    guard outcome.success else { throw RunnerError.illegal }
                    capturedNow += TensionProbe.soldiersCapturedCount(outcome, by: mover)
                    if action != .endTurn { active = true }
                    switch action { case .placeSoldier, .endTurn, .huntMonster: break; case .summonHero: summoned = true; default: usedSkill = true }
                    state = outcome.state
                }
                turns += 1
                if pure { passTurns += 1; if manaBefore >= state.config.manaCap { passFullMana += 1 } else { passLowMana += 1 } }
                if capturedNow > 0 { captures += capturedNow; lastActiveTurn = turns }
                if usedSkill { skillTurns += 1 }; if summoned { summonTurns += 1 }
                _ = active
                if state.status == .won, state.winner == mover { converted += pendingThreat.filter { $0.player == mover }.count; pendingThreat.removeAll { $0.player == mover } }
                let enemyLibAfter = state.board.find(mover.opponent, .commander).map { state.board.liberties(at: $0).count } ?? 0
                if state.status == .ongoing, enemyLibBefore > 2, enemyLibAfter <= 2, enemyLibAfter > 0 {
                    threats += 1; pendingThreat.append((mover, turns))
                }
                pendingThreat.removeAll { turns - $0.turn > 4 }
            }
            let drawn = state.status != .won
            let row: [String: Any] = ["game": game, "setup": setup, "result": drawn ? "drawn" : "won", "winner": state.winner?.rawValue as Any? ?? NSNull(),
                "turns": turns, "passTurns": passTurns, "passAtFullMana": passFullMana, "passBelowFullMana": passLowMana,
                "soldierCaptures": captures, "turnsSinceLastCapture": turns - lastActiveTurn, "skillTurns": skillTurns, "summonTurns": summonTurns,
                "commanderThreatsCreated": threats, "threatsConvertedToWinWithin4Turns": converted, "finalBoard": state.board.diagram]
            rows.append(row)
            for (k, v) in [("games", 1), ("drawn", drawn ? 1 : 0), ("passTurns", passTurns), ("passAtFullMana", passFullMana),
                           ("turns", turns), ("soldierCaptures", captures), ("threats", threats), ("converted", converted),
                           ("skillTurns", skillTurns), ("summonTurns", summonTurns)] { totals[k, default: 0] += v }
            print("game \(game) \(setup): \(drawn ? "drawn" : "won") in \(turns) turns, passes \(passTurns) (full mana \(passFullMana)), captures \(captures), last capture \(turns - lastActiveTurn) turns before end")
        }
        let report: [String: Any] = ["setup": ["games": games, "difficulty": difficulty.rawValue, "boardSize": size, "rules": rules,
                                                "opening": "seeded random soldiers for plies 1-4 (seed = game index), then bot vs bot",
                                                "turnCap": "Core draws at ply \(RuleConfig.board(size: size).maxPlies); the runner stops at 120 turns"],
                                     "totals": totals, "games": rows,
                                     "notClaimed": ["that passes or draws are mistakes", "balance", "human experience"]]
        try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
        print("totals:", totals.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
    }
}

/// TENSION-01 on the hand-made positions the product already ships: the three advanced challenges, the two priest
/// Sanctum rescues and the bot benchmark fixtures. These are teaching positions, so "forced" or "obvious" here is
/// information about the design, not a flaw.
extension BotRunner {
    static func tensionFixtures(out: String) throws {
        var fixtures: [(String, GameState)] = []
        for scenario in try AdvancedCatalog.all() {
            var state = try GameSetup.newGame(config: scenario.config, classOne: scenario.heroClass, classTwo: .none)
            for action in scenario.sourceActions {
                let result = GameEngine.apply(state, action)
                guard result.success else { throw RunnerError.illegal }
                state = result.state
            }
            fixtures.append(("advanced:" + scenario.id, state))
        }
        for practice in PriestSanctumPractice.allCases { fixtures.append(("sanctum-practice:" + practice.rawValue, try practice.state())) }
        fixtures.append(("benchmark:commander-rescue", try GameSetup.fromDiagram(config: .board(size: 7), diagram: "..O....\n.......\n.......\n...o...\n..oXo..\n.......\n.......", classOne: .warrior, classTwo: .mage, manaOne: 5, ap: 2, ply: 15)))
        fixtures.append(("benchmark:mage-two-action-capture", try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...x...\n..xOx..\n.H.o...\n.......\n.......\n...X...\n.......", classOne: .mage, manaOne: 5, ap: 2, ply: 15)))
        var rows: [[String: Any]] = []
        for (name, state) in fixtures {
            guard let position = TensionProbe.analyze(state, maxCandidates: 12) else { continue }
            rows.append(["name": name, "board": state.board.diagram, "player": state.current.rawValue, "ap": state.apRemaining,
                         "verdict": position.verdict.rawValue, "candidates": position.candidateCount, "safe": position.safe.count,
                         "closeDistinct": position.closeDistinct.map { ["key": $0.key, "signature": $0.signature, "score": $0.ownScore] } as [[String: Any]],
                         "unsafeExamples": position.candidates.filter(\.opponentCanWin).prefix(3).map(\.key)])
            print("\(name): \(position.verdict.rawValue); candidates \(position.candidateCount), safe \(position.safe.count), close distinct plans \(position.closeDistinct.count)")
        }
        try JSONSerialization.data(withJSONObject: ["fixtures": rows, "notClaimed": ["that retained candidates are all legal turns", "human difficulty"]], options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
    }
}

/// TENSION-01, multi-turn: the three shipped advanced challenges. For every first turn the planner retains for the
/// player, let the shipped scripted opponent answer, then try every retained second turn and read the product's own
/// assessment. Reports how many first plans can still succeed, how many are dead ends, and how different the
/// successful plans are. The candidate sets are bounded (not every legal turn), so "no success found" is not proof.
extension BotRunner {
    static func advancedAudit(out: String, maxFirst: Int, maxSecond: Int) throws {
        var rows: [[String: Any]] = []
        for scenario in try AdvancedCatalog.all() {
            let start = try TutorialSession(scenario)
            func finish(_ session: inout TutorialSession, _ actions: [GameAction]) {
                let owner = session.state.current
                for action in actions where session.state.current == owner && session.state.status == .ongoing { session.apply(action) }
                if session.state.current == owner, session.state.status == .ongoing { session.apply(.endTurn) }
            }
            func opponentReply(_ session: inout TutorialSession) {
                var guardCount = 0
                while session.state.current == .two, session.state.status == .ongoing, guardCount < 6 {
                    guardCount += 1
                    guard let next = session.plannedOpponentActions.first else { session.apply(.endTurn); continue }
                    session.apply(next)
                }
            }
            let firsts = BotPlanner.candidateTurns(start.state).prefix(maxFirst)
            var plans: [[String: Any]] = []
            var viable = 0, refuted = 0, deadEnd = 0
            var viableSignatures: Set<String> = []
            for first in firsts {
                guard let described = TensionProbe.describePublic(start.state, first) else { continue }
                var session = start
                finish(&session, first.actions)
                opponentReply(&session)
                var verdict = "deadEnd", successes = 0, tried = 0, reason = ""
                switch session.assessment {
                case .failed(let why): verdict = "refutedByReply"; reason = why
                case .completed: verdict = "completeAfterOneTurn"
                case .incomplete:
                    for second in BotPlanner.candidateTurns(session.state).prefix(maxSecond) {
                        tried += 1
                        var branch = session
                        finish(&branch, second.actions)
                        if branch.assessment == .completed { successes += 1 }
                    }
                    verdict = successes > 0 ? "viable" : "deadEnd"
                }
                if verdict == "viable" || verdict == "completeAfterOneTurn" { viable += 1; viableSignatures.insert(described.signature) }
                else if verdict == "refutedByReply" { refuted += 1 } else { deadEnd += 1 }
                plans.append(["first": described.key, "signature": described.signature, "verdict": verdict, "secondTurnsTried": tried,
                              "secondTurnsThatComplete": successes, "reason": reason])
            }
            rows.append(["challenge": scenario.id, "title": scenario.title, "firstPlansTried": plans.count, "viable": viable,
                         "refutedByScriptedReply": refuted, "deadEnd": deadEnd,
                         "distinctViableSignatures": viableSignatures.sorted(), "plans": plans])
            print("\(scenario.id): \(plans.count) first plans → viable \(viable), refuted by reply \(refuted), dead end \(deadEnd); distinct viable shapes \(viableSignatures.count)")
        }
        try JSONSerialization.data(withJSONObject: ["challenges": rows, "setup": ["firstCandidates": maxFirst, "secondCandidates": maxSecond,
            "opponent": "shipped AdvancedOpponent (deterministic)", "success": "the product's own TutorialSession.assessment == completed"],
            "notClaimed": ["that every legal plan was tried", "how hard these are for people", "that other opponents reply the same way"]],
            options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
    }
}

/// BOT-TENSION-01, difficulty tiers: does Standard actually beat Easy? Each class pairing is played with Standard as
/// Black and as White. A tier that cannot beat the weaker tier is a product question (what does the choice mean to a
/// player?), independent of how bot-vs-bot games of equal strength stall.
extension BotRunner {
    static func versus(games: Int, out: String, size: Int, rules: String) throws {
        let first = Int(ProcessInfo.processInfo.environment["TENSION_FIRST"] ?? "") ?? 0
        var rows: [[String: Any]] = []
        var totals: [String: Int] = [:]
        for game in first..<(first + games) {
            var state = try seededStart(game: game, size: size, rules: rules)
            let standardIsBlack = game % 2 == 0
            let standard: Player = standardIsBlack ? .one : .two
            var turns = 0, passesStandard = 0, passesEasy = 0
            while state.status == .ongoing, turns < 120 {
                let difficulty: BotDifficulty = state.current == standard ? .standard : .easy
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                if plan.actions.allSatisfy({ $0 == .endTurn }) { if difficulty == .standard { passesStandard += 1 } else { passesEasy += 1 } }
                for action in plan.actions {
                    let outcome = GameEngine.apply(state, action)
                    guard outcome.success else { throw RunnerError.illegal }
                    state = outcome.state
                }
                turns += 1
            }
            let result = state.status == .won ? (state.winner == standard ? "standardWon" : "easyWon") : "drawn"
            totals[result, default: 0] += 1; totals["games", default: 0] += 1
            rows.append(["game": game, "setup": "\(state.heroClass(of: .one).rawValue)-vs-\(state.heroClass(of: .two).rawValue)",
                         "standardColour": standardIsBlack ? "black" : "white", "result": result, "turns": turns,
                         "standardPasses": passesStandard, "easyPasses": passesEasy, "finalBoard": state.board.diagram])
            print("game \(game) standard=\(standardIsBlack ? "black" : "white") \(result) in \(turns) turns (standard passes \(passesStandard), easy passes \(passesEasy))")
        }
        try JSONSerialization.data(withJSONObject: ["setup": ["games": games, "boardSize": size, "rules": rules,
            "opening": "seeded random soldiers for plies 1-4 (seed = game index), then Standard vs Easy"], "totals": totals, "games": rows,
            "notClaimed": ["human strength", "balance", "that wins mean the standard bot is strong"]], options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
        print("totals:", totals.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
    }
}

/// Follow-up to TENSION-01: for the positions the sampler called forced (at most one retained turn survives), list
/// EVERY legal complete turn and check each exactly. This separates "the bot only looked at a few turns" from "the
/// position really has one safe turn". Boards come from the sampler's JSON; the side not to move gets full Mana (the
/// sampled stalls are positions where both sides were passing at full Mana) and no Ko history, so this is a close
/// reconstruction, not the original game state.
extension BotRunner {
    static func exactTurnsAudit(positions path: String, out: String) throws {
        let report = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: path))) as! [String: Any]
        let setup = report["setup"] as! [String: Any]
        let size = setup["boardSize"] as! Int, rules = setup["rules"] as! String
        var rows: [[String: Any]] = []
        for row in report["positions"] as! [[String: Any]] where row["verdict"] as? String == "forcedDefense" {
            let labels = (row["setup"] as! String).components(separatedBy: "-vs-")
            let (config, _) = ruleConfig(size: size, rules: rules)
            let mover = Player(rawValue: row["player"] as! Int)!
            var manaOne = 6, manaTwo = 6
            if mover == .one { manaOne = row["mana"] as! Int } else { manaTwo = row["mana"] as! Int }
            let state = try GameSetup.fromDiagram(config: config, diagram: row["board"] as! String, classOne: HeroClass(rawValue: labels[0])!, classTwo: HeroClass(rawValue: labels[1])!,
                                                  current: mover, manaOne: manaOne, manaTwo: manaTwo, ap: row["ap"] as? Int, ply: row["ply"] as! Int)
            let turns = TensionProbe.allCompleteTurns(state)
            var safe: [[String: Any]] = []
            for turn in turns where !(turn.state.winner == mover.opponent) {
                if turn.state.status != .ongoing || !TensionProbe.opponentCanCaptureCommander(turn.state) {
                    safe.append(["actions": turn.actions.map(botActionDescription).joined(separator: "/"), "status": turn.state.status.rawValue])
                }
            }
            rows.append(["game": row["game"] as Any, "ply": row["ply"] as Any, "setup": row["setup"] as Any, "board": row["board"] as Any,
                         "distinctCompleteTurns": turns.count, "exactSafeTurns": safe.count, "safe": safe,
                         "samplerRetained": row["candidates"] as Any, "samplerSafe": row["safe"] as Any])
            print("game \(row["game"]!) ply \(row["ply"]!) \(row["setup"]!): \(turns.count) distinct complete turns, \(safe.count) exactly safe (sampler saw \(row["candidates"]!), \(row["safe"]!) safe)")
        }
        try JSONSerialization.data(withJSONObject: ["rows": rows, "notClaimed": ["original Ko history", "the other side's exact Mana"]], options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
    }
}

/// BOT-TENSION-01: how often does the computer play a complete turn after which the opponent has a reply that captures
/// its commander, although another complete turn did not allow one? Both facts are exact (Core), taken on the real game
/// states of seeded bot-vs-bot games. A "blunder" here is only this immediate kind: it says nothing about slower mistakes.
extension BotRunner {
    static func blunderStats(games: Int, out: String, difficulty: BotDifficulty, size: Int, rules: String, maxPly: Int) throws {
        let first = Int(ProcessInfo.processInfo.environment["TENSION_FIRST"] ?? "") ?? 0
        var totals: [String: Int] = [:]
        var cases: [[String: Any]] = []
        for game in first..<(first + games) {
            var state = try seededStart(game: game, size: size, rules: rules)
            let label = "\(state.heroClass(of: .one).rawValue)-vs-\(state.heroClass(of: .two).rawValue)"
            var turns = 0
            while state.status == .ongoing, turns < 120 {
                guard let plan = BotPlanner.planTurn(state, difficulty: difficulty) else { throw RunnerError.noPlan }
                let before = state
                var after = state
                for action in plan.actions {
                    let outcome = GameEngine.apply(after, action)
                    guard outcome.success else { throw RunnerError.illegal }
                    after = outcome.state
                }
                if before.ply <= maxPly, after.status == .ongoing, after.current == before.current.opponent {
                    totals["checkedTurns", default: 0] += 1
                    if TensionProbe.opponentCanCaptureCommander(after) {
                        totals["unsafeChoices", default: 0] += 1
                        let all = TensionProbe.allCompleteTurns(before)
                        var safeExists = false, safeCount = 0
                        for turn in all {
                            if turn.state.winner == before.current { safeExists = true; safeCount += 1; continue }
                            if turn.state.status == .ongoing, !TensionProbe.opponentCanCaptureCommander(turn.state) { safeExists = true; safeCount += 1 }
                            if safeExists && safeCount >= 3 { break }
                        }
                        if safeExists { totals["unsafeWhileSafeExists", default: 0] += 1 }
                        cases.append(["game": game, "setup": label, "ply": before.ply, "player": before.current.rawValue, "board": before.board.diagram,
                                      "mana": [before.mana(of: .one), before.mana(of: .two)], "ap": before.apRemaining,
                                      "chosen": plan.actions.map(botActionDescription).joined(separator: "/"),
                                      "legalCompleteTurns": all.count, "safeTurnExists": safeExists, "safeTurnsFound(capped at 3)": safeCount,
                                      "reasons": plan.reasons])
                    }
                }
                state = after
                turns += 1
            }
            totals["games", default: 0] += 1
            print("game \(game) \(label): \(state.status.rawValue) in \(turns) turns; checked \(totals["checkedTurns", default: 0]), unsafe \(totals["unsafeChoices", default: 0]), unsafe while safe exists \(totals["unsafeWhileSafeExists", default: 0])")
        }
        try JSONSerialization.data(withJSONObject: ["setup": ["games": games, "difficulty": difficulty.rawValue, "boardSize": size, "rules": rules, "maxPly": maxPly,
            "opponentReplyBound": "Core legalActions with expansionCandidateLimit 256, first and second action, all of them"],
            "totals": totals, "cases": cases,
            "notClaimed": ["slower mistakes", "that a flagged position was lost", "human play"]], options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: out))
        print("totals:", totals.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " "))
    }
}
