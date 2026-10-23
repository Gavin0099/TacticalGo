import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import TacticalGoContent
import P2ResearchBot
import P0Metrics

/// A research-only switch. Original BotPlanner and Core are never altered.
private func p2ResearchLimits(diverse: Bool) -> P2Limits {
    P2Limits(maxDomainTransitions:6_000,ownBeamWidth:10,
             replyBeamWidth:3,replyCandidates:8,researchReplyDiversity:diverse)
}
private func p2Record(_ state:GameState,_ actions:[GameAction]) throws -> (GameState,Int,Int) {
    var result=state,themCaptured=0,spent=0
    for action in actions {
        let next=GameEngine.apply(result,action)
        guard next.success else { throw StudyError.invalid("P2 illegal suggested action") }
        themCaptured += captured(next,by:state.current)
        spent += manaSpent(next.events)
        result=next.state
    }
    guard result.status != .ongoing || result.current != state.current else {
        throw StudyError.invalid("P2 partial Bot turn")
    }
    return (result,themCaptured,spent)
}
private func p2Feature(_ state:GameState, _ actions:[GameAction]) throws -> [String:Any] {
    let (after,taken,spent)=try p2Record(state,actions)
    let me=state.current,enemy=me.opponent
    let beforeEnemy=state.board.find(enemy,.commander).map { state.board.liberties(at:$0).count } ?? 0
    let afterEnemy=after.board.find(enemy,.commander).map { after.board.liberties(at:$0).count } ?? 0
    let ownLib=after.board.find(me,.commander).map { after.board.liberties(at:$0).count } ?? 0
    return ["actions":try actions.map { try object(ExpansionMatchRecord.Action($0)) },
            "selectedKinds":P0Metrics.pattern(actions),"purePass":P0Metrics.isPurePass(actions),
            "capturedSoldiers":taken,"spent":spent,"enemyCommanderLibertiesBefore":beforeEnemy,
            "enemyCommanderLibertiesAfter":afterEnemy,"ownCommanderLibertiesAfter":ownLib,
            "coreWin":after.winner == me,"terminalStatus":after.status.rawValue,
            "after":try object(ExpansionMatchRecord.Snapshot(after))]
}
extension P0Runner {
    static func p2SafetyProbe(cohort:URL,output:URL) throws {
        let fixtures:[(String,Int,String)] = [
          ("b7-Priest-Rogue",33,"safe_active_but_not_better"),
          ("b7-Warrior-Mage",75,"forced_wait_exception"),
          ("b9-Priest-Rogue",59,"known_rogue_chain"),
          ("b9-Warrior-Mage",64,"unresolved_wait")
        ]
        var rows:[[String:Any]]=[]
        for (game,turn,name) in fixtures {
            let (root,original)=try stateAt(cohort.appendingPathComponent(game),turn:turn)
            guard let shipping=BotPlanner.planTurn(root,difficulty:.standard,policy:.baseline),
                  let replica=P2Planner.planTurn(root,limits:p2ResearchLimits(diverse:false),difficulty:.standard),
                  let candidate=P2Planner.planTurn(root,limits:p2ResearchLimits(diverse:true),difficulty:.standard)
            else { throw StudyError.invalid("P2 missing plan") }
            guard shipping.actions==replica.actions,shipping.score==replica.score,
                  shipping.stats.domainTransitions==replica.stats.domainTransitions,
                  shipping.stats.turnCandidates==replica.stats.turnCandidates else {
                throw StudyError.invalid("P2 research clone does not reproduce production baseline \(name)")
            }
            guard try p2Feature(root,shipping.actions)["actions"] != nil else {
                throw StudyError.invalid("P2 feature build failed")
            }
            let before=try p2Feature(root,shipping.actions)
            let after=try p2Feature(root,candidate.actions)
            let changed=shipping.actions != candidate.actions
            if name=="forced_wait_exception" && changed && !(candidate.actions.allSatisfy{$0 == .endTurn}) {
                // P0 exhausted every legal active turn at this exact historical state:
                // a change would be a proven immediate forced-loss regression.
                throw StudyError.invalid("P2 violated exhaustively proven forced-pass exception")
            }
            rows.append(["game":game,"turn":turn,"ply":root.ply,"case":name,
                "P0Recorded":original["actions"] as Any? ?? NSNull(),
                "baseline":before,"research":after,"changed":changed,
                "baselineScore":shipping.score,"researchScore":candidate.score,
                "baselineExplicitApply":shipping.stats.domainTransitions,
                "researchExplicitApply":candidate.stats.domainTransitions,
                "baselineSearchBudgetExhausted":shipping.stats.budgetExhausted,
                "researchSearchBudgetExhausted":candidate.stats.budgetExhausted,
                "replicaActionsAndScoreExact":true])
            log("P2P \(name) changed=\(changed) baselinePass=\(shipping.actions.allSatisfy{$0 == .endTurn}) researchPass=\(candidate.actions.allSatisfy{$0 == .endTurn}) apply=\(candidate.stats.domainTransitions)")
        }
        try write(["study":"TG12_P2_RESEARCH_BOT_FIXED_PROBES_V1",
              "changedDimension":"complete own-turn reply shortlist reserves at most one Core-measurable tactical plan outside top eight; no action score bonus",
              "scope":"four source-pinned historical full GameState positions including forced-pass and Rogue chain",
              "fixtures":rows,"noClaim":["increased true strength","no unsafe reply anywhere","long-term advantage",
                                         "human playtests","device performance","C# parity"]],output)
        log("P2P fixed probe receipt count \(rows.count)")
    }

    static func p2Match(cohort:URL,game:String,variant:String,out:URL) throws {
        let segments=game.split(separator:"-").map(String.init)
        guard segments.count==3,
              ["b7","b9"].contains(segments[0]),
              let one=HeroClass(rawValue:segments[1]),let two=HeroClass(rawValue:segments[2]),
              [.warrior,.mage,.rogue,.priest].contains(one),
              [.warrior,.mage,.rogue,.priest].contains(two),
              [( "Warrior","Mage"),("Mage","Warrior"),("Rogue","Priest"),("Priest","Rogue")]
                .contains(where:{$0.0==segments[1]&&$0.1==segments[2]}),
              ["clone","diverse"].contains(variant) else {
            throw StudyError.invalid("P2 match input must be one of 8 P0 class/board games and clone/diverse")
        }
        let size=segments[0]=="b7" ? 7:9
        let baselineDir=cohort.appendingPathComponent(game)
        let baseline=try readObject(baselineDir.appendingPathComponent("trace.json"))
        guard let baselineTurns=baseline["turns"] as? [[String:Any]] else {
            throw StudyError.invalid("P2 archived baseline trace missing")
        }
        let config=TacticalHints.updatedConfig(size:size,advancedCost:4)
        var session=GameSession(try GameSetup.newGame(config:config,classOne:one,classTwo:two))
        var turns:[[String:Any]]=[],frames:[[String:Any]]=[],passes:[Bool]=[]
        var previousCaptureTurn:Int?,captures=0,threatTurns=0,fullManaPass=0,skillTurns=0,mixedTurns=0
        var maxExplicit=0,budgets=0,firstDivergence:Int?
        let start=ProcessInfo.processInfo.systemUptime
        try FileManager.default.createDirectory(at:out,withIntermediateDirectories:true)
        while session.state.status == .ongoing && turns.count < 120 {
            let root=session.state,index=turns.count,mover=root.current
            let availability=skillAvailability(root)
            let t=ProcessInfo.processInfo.systemUptime
            guard let plan=P2Planner.planTurn(root,limits:p2ResearchLimits(diverse:variant=="diverse"),difficulty:.standard),
                  !plan.actions.isEmpty else { throw StudyError.invalid("P2 planner failed") }
            let seconds=ProcessInfo.processInfo.systemUptime-t
            if variant=="clone" {
                guard baselineTurns.indices.contains(index) else { throw StudyError.invalid("P2 baseline exceeds archive") }
                let old=try p2ActionsFromRaw(baselineTurns[index]["actions"])
                guard old==plan.actions else {
                    throw StudyError.invalid("P2 baseline replica diverged from P0 at turn \(index)")
                }
            }
            if firstDivergence==nil && baselineTurns.indices.contains(index) {
                let old=try p2ActionsFromRaw(baselineTurns[index]["actions"])
                if old != plan.actions { firstDivergence=index }
            }
            let beforeEnemy=root.board.find(mover.opponent,.commander)
                .map { root.board.liberties(at:$0).count } ?? 0
            var taken=0,spent=0
            for (i,action) in plan.actions.enumerated() {
                guard session.state.status == .ongoing,session.state.current == mover
                else { throw StudyError.invalid("P2 action after handover") }
                let before=session.state,available=i==0 ? availability:skillAvailability(before)
                let outcome=session.apply(action)
                guard outcome.success else { throw StudyError.invalid("P2 invalid core action \(action)") }
                let n=captured(outcome,by:mover)
                taken += n;spent += manaSpent(outcome.events)
                frames.append(["turn":index,"actionIndex":i,
                    "action":try object(ExpansionMatchRecord.Action(action)),
                    "availability":available,"before":try object(ExpansionMatchRecord.Snapshot(before)),
                    "after":try object(ExpansionMatchRecord.Snapshot(outcome.state)),
                    "events":outcome.events.map { String(reflecting:$0) },
                    "enemySoldiersCaptured":n,"manaSpent":manaSpent(outcome.events)])
            }
            guard session.state.status != .ongoing || session.state.current != mover else {
                throw StudyError.invalid("P2 incomplete full turn")
            }
            let pure=P0Metrics.isPurePass(plan.actions),manaBefore=root.mana(of:mover)
            let afterEnemy=session.state.board.find(mover.opponent,.commander)
                .map { session.state.board.liberties(at:$0).count } ?? 0
            if pure && manaBefore==root.config.manaCap { fullManaPass += 1 }
            if afterEnemy<beforeEnemy && session.state.status != .drawn { threatTurns += 1 }
            passes.append(pure)
            if taken>0 { captures += taken;previousCaptureTurn=index }
            let skill=plan.actions.contains(where:P0Metrics.isClassSkill)
            let mixed=skill && plan.actions.contains {
                if case .placeSoldier = $0 { return true };return false
            }
            if skill {skillTurns += 1};if mixed{mixedTurns += 1}
            maxExplicit=max(maxExplicit,plan.stats.domainTransitions)
            if plan.stats.budgetExhausted{budgets+=1}
            turns.append(["index":index,"ply":root.ply,"player":mover.rawValue,
                "heroClass":root.heroClass(of:mover).rawValue,
                "ap":root.apRemaining,"mana":manaBefore,"availability":availability,
                "purePass":pure,"pattern":P0Metrics.pattern(plan.actions),
                "usedBasic":plan.actions.contains(where:P0Metrics.isBasic),
                "usedAdvanced":plan.actions.contains(where:P0Metrics.isAdvanced),
                "actions":try plan.actions.map { try object(ExpansionMatchRecord.Action($0)) },
                "enemySoldiersCaptured":taken,"manaSpent":spent,"seconds":seconds,
                "enemyCommanderLibertiesBefore":beforeEnemy,"enemyCommanderLibertiesAfter":afterEnemy,
                "explicitPlannerTransitions":plan.stats.domainTransitions,
                "plannerLegalEnumerations":plan.stats.legalEnumerations,
                "plannerBudgetExhausted":plan.stats.budgetExhausted])
            if (index+1)%25==0 { log("P2MATCH \(game) \(variant) \(index+1) turns") }
        }
        guard session.state.status != .ongoing else { throw StudyError.invalid("P2 full match censored; not terminal") }
        try write(["boardSize":size,"classOne":one.rawValue,"classTwo":two.rawValue,
            "opening":"official GameSetup.newGame, same config as frozen P0 8 games",
            "difficulty":"standard","policy":"p2-research-\(variant)","turns":turns,"frames":frames],
            out.appendingPathComponent("trace.json"))
        let record=try ExpansionMatchRecord(session:session,difficulty:"standard")
        try record.data().write(to:out.appendingPathComponent("record.json"),options:.atomic)
        let replay=try verify(out)
        guard replay.state == session.state else { throw StudyError.invalid("P2 complete state/history mismatch") }
        let seconds=turns.compactMap {$0["seconds"] as? Double}.sorted()
        let median=seconds.isEmpty ? 0:seconds[seconds.count/2]
        let p95=seconds.isEmpty ? 0:seconds[min(seconds.count-1,Int(Double(seconds.count)*0.95))]
        let result:[String:Any]=[
            "study":"TG12_P2_BOT_FULL_MATCH_V1",
            "game":game,"variant":variant,"size":size,"heroOne":one.rawValue,"heroTwo":two.rawValue,
            "result":P0Metrics.result(session.state.status),"winner":session.state.winner?.rawValue as Any? ?? NSNull(),
            "turns":turns.count,"purePassTurns":passes.filter{$0}.count,
            "fullManaPurePassTurns":fullManaPass,"longestPassRun":P0Metrics.longestPassRun(passes),
            "skillTurns":skillTurns,"skillPlusSoldierTurns":mixedTurns,"threatTurns":threatTurns,
            "enemySoldierCaptures":captures,
            "turnsSinceLastCapture":previousCaptureTurn.map { turns.count-1-$0 } as Any? ?? NSNull(),
            "firstDivergenceFromP0":firstDivergence as Any? ?? NSNull(),
            "budgetExhaustionTurns":budgets,"maxExplicitApplies":maxExplicit,
            "medianPlannerSecondsLinux":median,"p95PlannerSecondsLinux":p95,
            "secondsIncludingObservation":ProcessInfo.processInfo.systemUptime-start,
            "fullRecordedReceiptReplay":true,"fullGameStateIncludingKoHistoryEqual":true,
            "recordActionCount":frames.count,
            "source":"P0 archived 8 original openings; source-pinned research planner clone",
            "limits":["one deterministic path only","not population win rate","opponent reply horizon bounded",
                      "threatTurns only tracks enemy Commander liberties lower after own turn",
                      "CPU times depend on GitHub-hosted Linux load; not iPhone performance"]]
        try write(result,out.appendingPathComponent("summary.json"))
        log("P2_MATCH_SUMMARY_JSON_BEGIN")
        log(String(decoding:try JSONSerialization.data(withJSONObject:result,options:[.sortedKeys]),as:UTF8.self))
        log("P2_MATCH_SUMMARY_JSON_END")
        log("P2MATCH DONE \(game) \(variant) turns=\(turns.count) purePass=\(passes.filter{$0}.count) fullManaPass=\(fullManaPass) captures=\(captures) \(result["result"]!)")
    }
}
private func p2ActionsFromRaw(_ raw:Any?) throws->[GameAction] {
    guard let actions=raw as? [[String:Any]] else {throw StudyError.invalid("P2 invalid archived actions")}
    return try actions.map { try JSONDecoder().decode(ExpansionMatchRecord.Action.self,
        from:JSONSerialization.data(withJSONObject:$0)).domain() }
}
