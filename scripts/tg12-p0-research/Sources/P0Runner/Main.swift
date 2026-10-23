import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoContent
import TacticalGoRecords
import P0Metrics
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

enum StudyError: Error { case invalid(String) }

func log(_ value: String) { FileHandle.standardOutput.write(Data((value + "\n").utf8)) }
func object<T: Encodable>(_ value: T) throws -> Any {
    try JSONSerialization.jsonObject(with: JSONEncoder().encode(value))
}
func write(_ value: Any, _ path: URL) throws {
    try JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys])
        .write(to: path, options: .atomic)
}
func readObject(_ path: URL) throws -> [String: Any] {
    guard let result = try JSONSerialization.jsonObject(with: Data(contentsOf:path)) as? [String:Any]
    else { throw StudyError.invalid("JSON object required") }
    return result
}
func skillAvailability(_ s: GameState) -> [String:Any] {
    // Basic enumeration is complete. The advanced cap is used only for finding a positive witness.
    // If it finds no advanced witness despite sufficient resources, enumerate uncapped before saying none.
    var raw = GameEngine.legalActions(s, expansionCandidateLimit: 256)
    var legal = raw.filter { P0Metrics.isInCurrentMode($0, config: s.config) }
    let heroPresent = s.board.find(s.current, .hero) != nil
    let advancedFunded = heroPresent && !s.skillUsedThisTurn && s.apRemaining > 0
        && s.mana(of:s.current) >= s.config.expansionSkillManaCost
    var mode = "bounded-positive-witness-or-resource-gated"
    if advancedFunded && !legal.contains(where:P0Metrics.isAdvanced) {
        raw = GameEngine.legalActions(s)
        legal = raw.filter { P0Metrics.isInCurrentMode($0, config: s.config) }
        mode = "uncapped-fallback-to-confirm-absence"
    }
    let basic = legal.filter(P0Metrics.isBasic), advanced = legal.filter(P0Metrics.isAdvanced)
    return ["heroPresent":heroPresent,"heroAlreadySummoned":s.hasSummonedHero(s.current),
            "basicFunded":s.mana(of:s.current) >= s.config.skillManaCost,
            "advancedFunded":s.mana(of:s.current) >= s.config.expansionSkillManaCost,
            "basicLegal":!basic.isEmpty,"advancedLegal":!advanced.isEmpty,
            "basicLegalCount":basic.count,"advancedWitnessCountLowerBound":advanced.count,
            "advancedEnumeration":mode,"compatibilityActionsExcluded":raw.count-legal.count,
            "basicKinds":Array(Set(basic.map { String(describing:$0).components(separatedBy:"(")[0] })).sorted(),
            "advancedKinds":Array(Set(advanced.map { String(describing:$0).components(separatedBy:"(")[0] })).sorted()]
}
func captured(_ outcome: ActionOutcome, by mover: Player) -> Int {
    outcome.events.reduce(0) { n,event in
        guard case .piecesCaptured(let owner,let pieces) = event, owner == mover else { return n }
        return n + pieces.filter { $0.piece == Piece(mover.opponent,.soldier) }.count
    }
}
func manaSpent(_ events:[ActionEvent]) -> Int {
    events.reduce(0) { n,event in if case .resourcesSpent(_,_,let mana) = event { return n+mana }; return n }
}
func snapshot(_ value: Any) throws -> ExpansionMatchRecord.Snapshot {
    try JSONDecoder().decode(ExpansionMatchRecord.Snapshot.self,
        from:JSONSerialization.data(withJSONObject:value))
}

@main struct P0Runner {
    static func main() {
        do { try run() }
        catch {
            FileHandle.standardError.write(Data("P0Runner: \(error)\n".utf8))
            exit(1)
        }
    }
    static func run() throws {
        let a=CommandLine.arguments
        guard a.count >= 3 else { throw StudyError.invalid("matrix out board | verify gameDir | probe gameDir turn | audit gameDir turn") }
        switch a[1] {
        case "verify-record":
            let record = try ExpansionMatchRecord.read(Data(contentsOf: URL(fileURLWithPath:a[2])))
            _ = try record.rebuild()
            log("PASS official-opening record: \(record.actions.count) actions")
        case "reobserve": try reobserve(URL(fileURLWithPath:a[2]))
        case "cohort":
            guard a.count == 3 else { throw StudyError.invalid("cohort out") }
            let out=URL(fileURLWithPath:a[2]);try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
            let pairs:[(HeroClass,HeroClass)]=[(.warrior,.mage),(.mage,.warrior),(.rogue,.priest),(.priest,.rogue)]
            for size in [7,9] { for (one,two) in pairs {
                let dir=out.appendingPathComponent("b\(size)-\(one.rawValue)-\(two.rawValue)")
                if FileManager.default.fileExists(atPath:dir.appendingPathComponent("summary.json").path) {
                    _ = try verify(dir);log("verified existing \(dir.lastPathComponent)");continue
                }
                try runGame(size:size,one:one,two:two,dir:dir)
            } }
        case "matrix":
            guard a.count == 4,let size=Int(a[3]),[7,9].contains(size) else { throw StudyError.invalid("board") }
            let out=URL(fileURLWithPath:a[2]);try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
            for one in [HeroClass.warrior,.mage,.rogue,.priest] {
                for two in [HeroClass.warrior,.mage,.rogue,.priest] {
                    let dir=out.appendingPathComponent("b\(size)-\(one.rawValue)-\(two.rawValue)")
                    if FileManager.default.fileExists(atPath:dir.appendingPathComponent("summary.json").path) {
                        _ = try verify(dir);log("verified existing \(dir.lastPathComponent)");continue
                    }
                    try runGame(size:size,one:one,two:two,dir:dir)
                }
            }
        case "verify": _ = try verify(URL(fileURLWithPath:a[2])); log("PASS serialized receipts and official-opening replay")
        case "probe":
            guard a.count == 4,let turn=Int(a[3]) else { throw StudyError.invalid("turn") }
            try probe(URL(fileURLWithPath:a[2]),turn:turn)
        case "audit":
            guard a.count == 4,let turn=Int(a[3]) else { throw StudyError.invalid("turn") }
            try audit(URL(fileURLWithPath:a[2]),turn:turn)
        case "p1":
            guard a.count == 5 || a.count == 6 else { throw StudyError.invalid("p1 complete-games-dir selection.json output.json [maxPositions]") }
            let limit = a.count == 6 ? (Int(a[5]) ?? 0) : 4
            guard (1...16).contains(limit) else { throw StudyError.invalid("P1 maxPositions 1...16") }
            try p1Audit(cohort:URL(fileURLWithPath:a[2]),
                        selectionFile:URL(fileURLWithPath:a[3]),
                        output:URL(fileURLWithPath:a[4]),maxPositions:limit)
        case "rogue":
            guard a.count == 5 else { throw StudyError.invalid("rogue complete-games-dir p1-results-v2.json output.json") }
            try rogueAudit(cohort:URL(fileURLWithPath:a[2]),p1:URL(fileURLWithPath:a[3]),
                           output:URL(fileURLWithPath:a[4]))
        case "rogue-verify":
            guard a.count == 4 || (a.count == 5 && a[4] == "--negative-controls") else {
                throw StudyError.invalid("rogue-verify complete-games-dir rogue-results.json [--negative-controls]")
            }
            try rogueVerify(cohort:URL(fileURLWithPath:a[2]),output:URL(fileURLWithPath:a[3]),negativeControls:a.count == 5)
        case "p2-diagnose":
            guard a.count == 5 || (a.count == 6 && a[5] == "--short") else {
                throw StudyError.invalid("p2-diagnose complete-games-dir P1-results-v2.json output.json [--short]")
            }
            try p2Diagnose(cohort:URL(fileURLWithPath:a[2]),p1:URL(fileURLWithPath:a[3]),
                           output:URL(fileURLWithPath:a[4]),short:a.count == 6)
        case "p2-safety":
            guard a.count == 4 else { throw StudyError.invalid("p2-safety complete-games-dir result.json") }
            try p2SafetyProbe(cohort:URL(fileURLWithPath:a[2]),output:URL(fileURLWithPath:a[3]))
        case "p2-match":
            guard a.count == 6 else { throw StudyError.invalid("p2-match complete-games-dir game-name clone|diverse output-dir") }
            try p2Match(cohort:URL(fileURLWithPath:a[2]),game:a[3],variant:a[4],
                        out:URL(fileURLWithPath:a[5]))
        default: throw StudyError.invalid("command")
        }
    }
    static func runGame(size:Int,one:HeroClass,two:HeroClass,dir:URL) throws {
        try FileManager.default.createDirectory(at:dir,withIntermediateDirectories:true)
        let config=TacticalHints.updatedConfig(size:size,advancedCost:4)
        var session=GameSession(try GameSetup.newGame(config:config,classOne:one,classTwo:two))
        var turns:[[String:Any]]=[],frames:[[String:Any]]=[],passFlags:[Bool]=[]
        var lastCaptureTurn:Int?,totalCaptures=0
        let started=ProcessInfo.processInfo.systemUptime
        log("START \(dir.lastPathComponent)")
        while session.state.status == .ongoing && turns.count < 120 {
            let root=session.state,mover=root.current,index=turns.count
            let availability=skillAvailability(root)
            let t=ProcessInfo.processInfo.systemUptime
            guard let plan=BotPlanner.planTurn(root,difficulty:.standard,policy:.baseline),!plan.actions.isEmpty
            else { throw StudyError.invalid("missing plan") }
            let seconds=ProcessInfo.processInfo.systemUptime-t
            var captures=0,spent=0
            for (i,action) in plan.actions.enumerated() {
                guard session.state.status == .ongoing,session.state.current == mover else { throw StudyError.invalid("action after turn") }
                let before=session.state,available=i == 0 ? availability:skillAvailability(before)
                let outcome=session.apply(action)
                guard outcome.success else { throw StudyError.invalid("illegal \(action)") }
                let n=captured(outcome,by:mover);captures += n;spent += manaSpent(outcome.events)
                frames.append(["turn":index,"actionIndex":i,"action":try object(ExpansionMatchRecord.Action(action)),
                    "availability":available,"before":try object(ExpansionMatchRecord.Snapshot(before)),
                    "after":try object(ExpansionMatchRecord.Snapshot(outcome.state)),
                    "events":outcome.events.map { String(reflecting:$0) },"enemySoldiersCaptured":n,
                    "manaSpent":manaSpent(outcome.events)])
            }
            guard session.state.current != mover || session.state.status != .ongoing else { throw StudyError.invalid("partial turn") }
            let pure=P0Metrics.isPurePass(plan.actions);passFlags.append(pure)
            if captures > 0 { lastCaptureTurn=index };totalCaptures += captures
            turns.append(["index":index,"ply":root.ply,"player":mover.rawValue,"heroClass":root.heroClass(of:mover).rawValue,
                "ap":root.apRemaining,"mana":root.mana(of:mover),"availability":availability,
                "purePass":pure,"pattern":P0Metrics.pattern(plan.actions),
                "usedBasic":plan.actions.contains(where:P0Metrics.isBasic),"usedAdvanced":plan.actions.contains(where:P0Metrics.isAdvanced),
                "actions":try plan.actions.map { try object(ExpansionMatchRecord.Action($0)) },
                "enemySoldiersCaptured":captures,"manaSpent":spent,"seconds":seconds,
                "explicitPlannerTransitions":plan.stats.domainTransitions,"plannerLegalEnumerations":plan.stats.legalEnumerations,
                "plannerBudgetExhausted":plan.stats.budgetExhausted])
            if turns.count % 20 == 0 { log("PROGRESS \(dir.lastPathComponent) \(turns.count) turns") }
        }
        try write(["boardSize":size,"classOne":one.rawValue,"classTwo":two.rawValue,
            "opening":"official GameSetup.newGame; no random opening or handcrafted placement",
            "difficulty":"standard","policy":"baseline","turns":turns,"frames":frames],dir.appendingPathComponent("trace.json"))
        guard session.state.status != .ongoing else { throw StudyError.invalid("incomplete; not a draw") }
        let record=try ExpansionMatchRecord(session:session,difficulty:"standard")
        try record.data().write(to:dir.appendingPathComponent("record.json"),options:.atomic)
        let replayed=try verify(dir)
        guard replayed.state == session.state else { throw StudyError.invalid("full GameState including history mismatch") }
        let summary:[String:Any]=["id":dir.lastPathComponent,"boardSize":size,"classOne":one.rawValue,"classTwo":two.rawValue,
            "result":P0Metrics.result(session.state.status),"winner":session.state.winner?.rawValue as Any? ?? NSNull(),
            "turns":turns.count,"atomicActions":frames.count,"purePassTurns":passFlags.filter{$0}.count,
            "longestPurePassRun":P0Metrics.longestPassRun(passFlags),"enemySoldierCaptures":totalCaptures,
            "turnsAfterLastCapture":lastCaptureTurn.map { turns.count-1-$0 } as Any? ?? NSNull(),
            "finalSnapshot":try object(ExpansionMatchRecord.Snapshot(session.state)),
            "fullReplayIncludingHistoryEqual":true,"serializedReceiptsVerified":true,
            "secondsIncludingObservation":ProcessInfo.processInfo.systemUptime-started,
            "timingScope":"observed Mac Release time under ambient host load; not iPhone latency acceptance"]
        try write(summary,dir.appendingPathComponent("summary.json"))
        log("DONE \(dir.lastPathComponent) \(summary["result"]!) turns=\(turns.count) passes=\(summary["purePassTurns"]!) longest=\(summary["longestPurePassRun"]!)")
    }
    static func verify(_ dir:URL) throws -> GameSession {
        let record=try ExpansionMatchRecord.read(Data(contentsOf:dir.appendingPathComponent("record.json")))
        let trace=try readObject(dir.appendingPathComponent("trace.json"))
        guard let frames=trace["frames"] as? [[String:Any]],frames.count == record.actions.count else { throw StudyError.invalid("trace count") }
        var replay=GameSession(try GameSetup.newGame(config:record.config(),classOne:record.classOne,classTwo:record.classTwo))
        for (i,frame) in frames.enumerated() {
            let action=try JSONDecoder().decode(ExpansionMatchRecord.Action.self,from:JSONSerialization.data(withJSONObject:frame["action"]!))
            guard try action.domain() == record.actions[i].domain(),
                try ExpansionMatchRecord.Snapshot(replay.state) == snapshot(frame["before"]!) else { throw StudyError.invalid("before/action receipt \(i)") }
            let result=replay.apply(try action.domain())
            guard result.success,try ExpansionMatchRecord.Snapshot(result.state) == snapshot(frame["after"]!),
                result.events.map({String(reflecting:$0)}) == frame["events"] as? [String]
            else { throw StudyError.invalid("after/event receipt \(i)") }
        }
        guard try record.rebuild().state == replay.state else { throw StudyError.invalid("record history replay") }
        return replay
    }
    static func stateAt(_ dir:URL,turn:Int) throws -> (GameState,[String:Any]) {
        _ = try verify(dir)
        let record=try ExpansionMatchRecord.read(Data(contentsOf:dir.appendingPathComponent("record.json")))
        let trace=try readObject(dir.appendingPathComponent("trace.json"))
        let rows=trace["turns"] as! [[String:Any]],frames=trace["frames"] as! [[String:Any]]
        guard rows.indices.contains(turn) else { throw StudyError.invalid("turn range") }
        var session=GameSession(try GameSetup.newGame(config:record.config(),classOne:record.classOne,classTwo:record.classTwo))
        for (i,frame) in frames.enumerated() where (frame["turn"] as! Int) < turn {
            guard try session.apply(record.actions[i].domain()).success else { throw StudyError.invalid("prefix") }
        }
        return (session.state,rows[turn])
    }
    static func reobserve(_ dir:URL) throws {
        _ = try verify(dir)
        let record = try ExpansionMatchRecord.read(Data(contentsOf:dir.appendingPathComponent("record.json")))
        let path = dir.appendingPathComponent("trace.json")
        let backup = dir.appendingPathComponent("trace-core-compatibility.json")
        if !FileManager.default.fileExists(atPath:backup.path) { try FileManager.default.copyItem(at:path,to:backup) }
        var trace = try readObject(path)
        var frames = trace["frames"] as! [[String:Any]], turns = trace["turns"] as! [[String:Any]]
        var replay = GameSession(try GameSetup.newGame(config:record.config(),classOne:record.classOne,classTwo:record.classTwo))
        for i in frames.indices {
            let available = skillAvailability(replay.state)
            frames[i]["availability"] = available
            if frames[i]["actionIndex"] as! Int == 0 { turns[frames[i]["turn"] as! Int]["availability"] = available }
            guard try replay.apply(record.actions[i].domain()).success else { throw StudyError.invalid("reobserve replay") }
        }
        trace["frames"] = frames; trace["turns"] = turns
        trace["availabilityRule"] = "Current human/Bot repertoire; compatibility-only MagicHand excluded in updated expansion"
        try write(trace,path)
        _ = try verify(dir)
        log("REOBSERVED \(dir.lastPathComponent); actual actions unchanged")
    }
    static func probe(_ dir:URL,turn:Int) throws {
        let (root,row)=try stateAt(dir,turn:turn),me=root.current
        let candidates=BotPlanner.candidateTurns(root)
        var reports:[[String:Any]]=[]
        for candidate in candidates {
            var state=root,spent=0,captures=0
            for action in candidate.actions {
                let outcome=GameEngine.apply(state,action)
                guard outcome.success else { throw StudyError.invalid("candidate") }
                spent += manaSpent(outcome.events);captures += captured(outcome,by:me);state=outcome.state
            }
            guard state == candidate.state else { throw StudyError.invalid("candidate full state") }
            reports.append(["pattern":P0Metrics.pattern(candidate.actions),"ownTurnHeuristicScore":candidate.ownScore,
                "actions":try candidate.actions.map { try object(ExpansionMatchRecord.Action($0)) },
                "enemySoldiersCaptured":captures,"manaSpent":spent,
                "ownCommanderLiberties":state.board.find(me,.commander).map { state.board.liberties(at:$0).count } ?? 0,
                "enemyCommanderLiberties":state.board.find(me.opponent,.commander).map { state.board.liberties(at:$0).count } ?? 0,
                "ownHeroPresent":state.board.find(me,.hero) != nil,"immediateWin":state.winner == me,
                "after":try object(ExpansionMatchRecord.Snapshot(state))])
        }
        try write(["game":dir.lastPathComponent,"turn":turn,"sourceTurn":row,
            "scope":"bounded planner-retained own turns; scores are heuristic, not dominance or complete-reply proof",
            "candidates":reports],dir.appendingPathComponent("probe-\(turn).json"))
        log("PROBE \(dir.lastPathComponent) turn=\(turn) retained=\(reports.count)")
    }
}
