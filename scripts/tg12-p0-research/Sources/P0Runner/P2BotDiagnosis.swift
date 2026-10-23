import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import P0Metrics

/// Read-only diagnosis: same official-opening P0 full-history roots.
/// Never changes Core, Bot selection, pass scoring or costs.
private struct P2DiagnosticCase {
    let game: String
    let turn: Int
    let caseID: String
    let target: [GameAction]
    let observed: [GameAction]
    let root: GameState
    let safety: String
}
private func p2Actions(_ raw: Any?) throws -> [GameAction] {
    guard let rows=raw as? [[String:Any]] else { throw StudyError.invalid("P2 record action array missing") }
    return try rows.map {
        try JSONDecoder().decode(ExpansionMatchRecord.Action.self,
            from:JSONSerialization.data(withJSONObject:$0)).domain()
    }
}
private func p2Trace(_ item:P2DiagnosticCase, limits:BotLimits, variant:String) throws -> [String:Any] {
    let root=item.root
    guard let bot=BotPlanner.planTurn(root,limits:limits,difficulty:.standard,diagnostics:true,policy:.baseline)
    else { throw StudyError.invalid("P2 nil bot plan") }
    let chosen=bot.actions.map(botActionDescription)
    let target=item.target.map(botActionDescription)
    guard let firstKey=target.first else { throw StudyError.invalid("P2 empty target") }
    let secondKey=target.count>1 ? target[1] : nil
    let completeKey=target.joined(separator:"/")
    let trace=bot.stats.candidateTrace
    func find(_ stage:String,_ context:String,_ key:String) -> BotCandidateTrace? {
        trace.first { $0.stage == stage && $0.context == context && $0.actionKey == key }
    }
    func encode(_ e:BotCandidateTrace?) -> [String:Any] {
        guard let e else { return ["observed":false] }
        return ["observed":true,"rank":e.rank as Any? ?? NSNull(),
                "ownScore":e.score as Any? ?? NSNull(),"retained":e.retained,"reason":e.reason]
    }
    let rootStep=find("own-first","root",firstKey)
    let secondStep=secondKey.flatMap { find("own-second",firstKey,$0) }
    let fullStep=find("complete-turn","root",completeKey)
    let paired=bot.stats.candidateComparisons.first { $0.hasPrefix(completeKey+" own=") }
    return ["case":item.caseID,"game":item.game,"turn":item.turn,
       "ply":root.ply,"variant":variant,"safety":item.safety,
       "baselineWasPass":item.observed.allSatisfy{$0 == .endTurn},
       "targetActions":target,"chosenActions":chosen,
       "chosenPurePass":bot.actions.allSatisfy{$0 == .endTurn},
       "targetWasChosen":target==chosen,
       "rootFirst":encode(rootStep),"ownSecond":encode(secondStep),
       "completed":encode(fullStep),"replyComparison":paired as Any? ?? NSNull(),
       "rootLegalCandidates":bot.stats.rootActionComparisons.count,
       "fullOwnCandidates":bot.stats.turnCandidates,
       "explicitApply":bot.stats.domainTransitions,
       "legalEnumerations":bot.stats.legalEnumerations,
       "budgetExhausted":bot.stats.budgetExhausted,
       "traceTruncated":bot.stats.traceTruncated,
       "chosenScore":bot.score,
       "passDiagnostics":bot.stats.passDiagnostics]
}
extension P0Runner {
    static func p2Diagnose(cohort:URL,p1:URL,output:URL,short:Bool) throws {
        let passes=[("b7-Priest-Rogue",33,"safe-active-witness"),
                    ("b7-Warrior-Mage",75,"forced-pass-exact"),
                    ("b9-Warrior-Mage",64,"pass-audit-timeout")]
        var cases:[P2DiagnosticCase]=[]
        for (game,turn,safety) in passes.prefix(short ? 2 : 3) {
            let dir=cohort.appendingPathComponent(game)
            let (state,row)=try stateAt(dir,turn:turn)
            let audit=try readObject(dir.appendingPathComponent("pass-audit-\(turn).json"))
            guard audit["ply"] as? Int == state.ply,audit["turn"] as? Int == turn,
                  row["purePass"] as? Bool == true else { throw StudyError.invalid("P2 pinned pass source drift") }
            let original=try p2Actions(row["actions"])
            let target:[GameAction]
            if audit["safeNonpassWitness"] is NSNull { target=original }
            else { target=try p2Actions(audit["safeNonpassWitness"]) }
            cases.append(.init(game:game,turn:turn,caseID:safety,target:target,observed:original,
                               root:state,safety:audit["verdict"] as? String ?? "unknown"))
        }
        let report=try readObject(p1)
        guard let positions=report["positions"] as? [[String:Any]],
              let rogue=positions.first(where:{$0["game"] as? String == "b9-Priest-Rogue" && $0["turn"] as? Int == 59}),
              let arms=rogue["alternatives"] as? [[String:Any]],arms.count == 12 else {
            throw StudyError.invalid("P2 Rogue P1 source drift")
        }
        let target=try p2Actions(arms[5]["actions"])
        let (state,row)=try stateAt(cohort.appendingPathComponent("b9-Priest-Rogue"),turn:59)
        guard state.ply == 60,state.current == .two,
              ExpansionMatchRecord.Snapshot(state) == (try snapshot(rogue["before"]!)),
              target.count == 2 else { throw StudyError.invalid("P2 Rogue root mismatch") }
        cases.append(.init(game:"b9-Priest-Rogue",turn:59,caseID:"rogue-two-action-validated",
                           target:target,observed:try p2Actions(row["actions"]),root:state,
                           safety:"complete-one-turn-survival-with-net-captures"))
        var samples:[[String:Any]]=[]
        for item in cases {
            let baseline=try p2Trace(item,limits:.standard,variant:"baseline-10-8")
            samples.append(baseline)
            log("P2D \(item.caseID) root=\(baseline["rootFirst"]!) second=\(baseline["ownSecond"]!) complete=\(baseline["completed"]!)")
            let alternatives:[(String,BotLimits)] = [
                ("own-beam-16", BotLimits(maxDomainTransitions:6000,ownBeamWidth:16,replyBeamWidth:3,replyCandidates:8)),
                ("reply-cap-16",BotLimits(maxDomainTransitions:6000,ownBeamWidth:10,replyBeamWidth:3,replyCandidates:16))]
            for (label,limits) in alternatives {
                let row=try p2Trace(item,limits:limits,variant:label)
                samples.append(row)
                log("P2D \(item.caseID) \(label) chosenPass=\(row["chosenPurePass"]!) budget=\(row["budgetExhausted"]!)")
            }
        }
        try write(["study":"TG12_P2_BOT_PRUNING_DIAG_V1",
              "scope":"read-only baseline + one-factor own beam / complete-reply-cap probes; exact P0 history",
              "source":["p0":"formal-opening P0 archived records; all eight games unchanged",
                        "p1":"P1 V2 Rogue case #5 with P1R complete one-reply coverage"],
              "cases":samples,"noClaims":["strategy dominance","safe witness is better than pass",
                "default bot includes a variant","human fun","iPhone speed","C# parity"]],output)
        log("P2D JSON written \(output.path) cases=\(samples.count)")
    }
}
