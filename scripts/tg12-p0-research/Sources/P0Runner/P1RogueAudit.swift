import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import P0Metrics

/// P1R: focused, research-only continuation from P1 V2.
/// Scope: one pinned natural 9x9 Rogue root, no product/Bot/rule changes.
/// All opponent replies originate from actual Core states with their full superko histories.
private struct RogueReply {
    let actions: [GameAction]
    let final: GameState
    let enemySoldiersTaken: Int
    var sources: [String]
}

private func rogueActionsKey(_ actions: [GameAction]) -> String {
    actions.map { String(reflecting:$0) }.joined(separator:"|")
}
private func rogueActionObject(_ actions: [GameAction]) throws -> [[String:Any]] {
    try actions.map { try object(ExpansionMatchRecord.Action($0)) as! [String:Any] }
}
private func rogueDomain(_ actions: [[String:Any]]) throws -> [GameAction] {
    try actions.map { try JSONDecoder().decode(ExpansionMatchRecord.Action.self,
        from:JSONSerialization.data(withJSONObject:$0)).domain() }
}
private func rogueSoldiers(_ s:GameState) -> [GameAction] {
    s.board.points.filter { s.board.isEmpty($0) && GameEngine.validate(s,.placeSoldier($0)) == .none }
        .map(GameAction.placeSoldier)
}
private func rogueLiberties(_ s:GameState, owner:Player, kind:PieceKind) -> Int {
    s.board.find(owner,kind).map { s.board.liberties(at:$0).count } ?? 0
}

/// Verification traverses the uncapped Core action tree independently of the
/// generator's soldier/skill partition. This proves only this pinned one-turn set.
private func rogueCensus(_ start:GameState, soldiersOnly:Bool) throws -> Set<String> {
    let mover=start.current
    var keys=Set<String>(), visits=0
    func visit(_ state:GameState,_ prefix:[GameAction]) throws {
        if state.status != .ongoing || state.current != mover {
            keys.insert(rogueActionsKey(prefix));return
        }
        guard prefix.count < 2 else { throw StudyError.invalid("P1R census exceeds pinned two AP") }
        for action in GameEngine.legalActions(state) where P0Metrics.isInCurrentMode(action,config:state.config) {
            if soldiersOnly {
                if case .placeSoldier = action {} else if action != .endTurn { continue }
            }
            visits += 1
            guard visits <= 10_000 else { throw StudyError.invalid("P1R verification census incomplete") }
            let result=GameEngine.apply(state,action)
            guard result.success else { throw StudyError.invalid("P1R census illegal action") }
            try visit(result.state,prefix+[action])
        }
    }
    try visit(start,[])
    return keys
}

private func rogueFields(_ actual:[String:Any],_ expected:[String:Any],_ label:String) throws {
    for (key,value) in expected {
        guard let stored=actual[key], NSDictionary(dictionary:["v":stored]).isEqual(to:["v":value]) else {
            throw StudyError.invalid("P1R \(label) field \(key)")
        }
    }
}
private func rogueAdvanced(_ s:GameState, owner:Player) -> Bool {
    guard s.status == .ongoing,s.current == owner,s.mana(of:owner) >= s.config.expansionSkillManaCost,
          s.board.find(owner,.hero) != nil,!s.skillUsedThisTurn else { return false }
    // Rogue's only advanced action is ChainSwap; check its complete adjacent geometry
    // directly through Core instead of enumerating every unrelated ability per reply.
    guard s.heroClass(of:owner) == .rogue,let hero=s.board.find(owner,.hero) else { return false }
    let enemy=Piece(owner.opponent,.soldier)
    for first in s.board.neighbors(of:hero) where s.board[first] == enemy {
        for second in s.board.neighbors(of:first) where s.board[second] == enemy {
            if GameEngine.validate(s,.castChainSwap(first:first,second:second)) == .none { return true }
        }
    }
    return false
}
private func rogueApply(_ start:GameState,_ moves:[GameAction],
                        mover:Player) throws -> (GameState,Int) {
    var s=start, taken=0
    for (i,action) in moves.enumerated() {
        guard s.status == .ongoing,s.current == mover else { throw StudyError.invalid("Rogue reply wrong player") }
        let o=GameEngine.apply(s,action)
        guard o.success else { throw StudyError.invalid("Rogue reply illegal \(action) \(o.reason)") }
        taken += captured(o,by:mover)
        s=o.state
        if i+1 < moves.count, s.status != .ongoing || s.current != mover {
            throw StudyError.invalid("Rogue action after handover")
        }
    }
    guard s.status != .ongoing || s.current == mover.opponent else {
        throw StudyError.invalid("Rogue turn not complete")
    }
    return (s,taken)
}

/// Adds one complete reply without merging distinct action histories. Every reply is
/// verified through GameEngine.apply, never reconstructed from its board string.
private func rogueReplySet(_ after:GameState, expected:[GameAction],
                           checkAllPriestSkills:Bool) throws
    -> ([RogueReply],[String:Int],Bool,Bool,Int) {
    guard after.status == .ongoing else { return ([],[:],true,false,0) }
    let defender=after.current
    var replies:[RogueReply]=[],index:[String:Int]=[:],visits=0,exhaustive=true
    func include(_ moves:[GameAction],source:String) throws {
        let key=rogueActionsKey(moves)
        if let existing=index[key] {
            if !replies[existing].sources.contains(source) { replies[existing].sources.append(source) }
            return
        }
        let (final,taken)=try rogueApply(after,moves,mover:defender)
        index[key]=replies.count
        replies.append(.init(actions:moves,final:final,enemySoldiersTaken:taken,sources:[source]))
    }
    try include(expected,source:"p1_standard_reply")
    if let easy=BotPlanner.planTurn(after,difficulty:.easy,policy:.baseline) {
        try include(easy.actions,source:"easy_bot")
    }
    let retained=BotPlanner.candidateTurns(after,
        limits:BotLimits(maxDomainTransitions:3_000,ownBeamWidth:8,replyBeamWidth:2,replyCandidates:8),
        difficulty:.standard)
    for candidate in retained {
        try include(candidate.actions,source:"bounded_standard_retained")
        guard replies[index[rogueActionsKey(candidate.actions)]!].final == candidate.state else {
            throw StudyError.invalid("retained candidate full state differs")
        }
    }
    // Complete every placement-only enemy response where both AP are spent on
    // ordinary soldiers, plus an early endTurn. This exhaustive statement
    // intentionally excludes enemy skills, summon and resource/loot actions.
    try include([.endTurn],source:"all_soldier_only_replies")
    for first in rogueSoldiers(after) {
        let o=GameEngine.apply(after,first);visits += 1
        guard o.success else { throw StudyError.invalid("Rogue first soldier invalid") }
        if o.state.status != .ongoing || o.state.current != defender {
            try include([first],source:"all_soldier_only_replies")
            continue
        }
        try include([first,.endTurn],source:"all_soldier_only_replies")
        for second in rogueSoldiers(o.state) {
            visits += 1
            if visits > 10_000 { exhaustive=false;break }
            try include([first,second],source:"all_soldier_only_replies")
        }
        if !exhaustive { break }
    }
    // P1R+ for the pinned 9x9 Rogue positive only: every enemy Priest skill as
    // first action followed by any legal ordinary placement/pass, and every
    // ordinary placement followed by every legal Priest skill.
    // Together with the placement-only sweep this covers all current-mode
    // complete turns if there are no other kinds and the cap is not reached.
    var skillComplete=checkAllPriestSkills, skillEnumerated=0
    if checkAllPriestSkills {
        guard after.heroClass(of:defender) == .priest else {
            throw StudyError.invalid("P1R skill census expected an enemy Priest")
        }
        let fullFirst=GameEngine.legalActions(after)
            .filter { P0Metrics.isInCurrentMode($0,config:after.config) }
        for first in fullFirst {
            if first == .endTurn { continue }
            let firstIsSoldier:Bool
            if case .placeSoldier = first { firstIsSoldier=true }
            else if P0Metrics.isClassSkill(first) { firstIsSoldier=false }
            else {
                // Summon, loot or any future new action is NOT silently assumed covered.
                skillComplete=false;continue
            }
            let one=GameEngine.apply(after,first)
            guard one.success else { throw StudyError.invalid("P1R census first action invalid") }
            if one.state.status != .ongoing || one.state.current != defender {
                try include([first],source:"all_priest_skills_ordered")
                continue
            }
            let second=GameEngine.legalActions(one.state)
                .filter { P0Metrics.isInCurrentMode($0,config:one.state.config) }
                .filter { move in
                    if firstIsSoldier { return P0Metrics.isClassSkill(move) }
                    if move == .endTurn { return true }
                    if case .placeSoldier = move { return true }
                    return false
                }
            for move in second {
                skillEnumerated += 1
                if skillEnumerated > 8_000 { skillComplete=false;break }
                try include([first,move],source:"all_priest_skills_ordered")
            }
            if skillEnumerated > 8_000 { break }
        }
    }
    var counts:[String:Int]=[:]
    for reply in replies { for name in reply.sources { counts[name,default:0] += 1 } }
    return (replies,counts,exhaustive,skillComplete,skillEnumerated)
}

private func rogueContinue(_ afterEnemy:GameState, mover:Player,
                            capturedMe:Int, capturedThem:Int) throws -> [String:Any] {
    guard afterEnemy.status == .ongoing,afterEnemy.current == mover else {
        return ["applicable":false,"reason":"terminal_or_wrong_owner"]
    }
    let startMana=afterEnemy.mana(of:mover)
    let startedAdvanced=rogueAdvanced(afterEnemy,owner:mover)
    guard let ours=BotPlanner.planTurn(afterEnemy,difficulty:.standard,policy:.baseline) else {
        throw StudyError.invalid("Rogue continuation missing own Bot plan")
    }
    let (afterOwn,moreMine)=try rogueApply(afterEnemy,ours.actions,mover:mover)
    var s=afterOwn, otherActions:[GameAction]=[],moreEnemy=0
    if s.status == .ongoing,s.current == mover.opponent {
        guard let enemy=BotPlanner.planTurn(s,difficulty:.standard,policy:.baseline) else {
            throw StudyError.invalid("Rogue continuation missing enemy Bot plan")
        }
        otherActions=enemy.actions
        (s,moreEnemy)=try rogueApply(s,otherActions,mover:mover.opponent)
    }
    return ["applicable":true, "initialManaOnNextOwnTurn":startMana,
        "advancedSkillAvailableAtNextOwnTurn":startedAdvanced,
        "nextOwnActions":try rogueActionObject(ours.actions),
        "nextEnemyActions":try rogueActionObject(otherActions),
        "captureCountAtTwoCycles":capturedMe+moreMine-capturedThem-moreEnemy,
        "newEnemySoldiersTakenByRogue":moreMine,
        "newRogueSoldiersTakenByEnemy":moreEnemy,
        "ourCommanderAlive":s.board.find(mover,.commander) != nil,
        "ourHeroAlive":s.board.find(mover,.hero) != nil,
        "manaAtTwoCycleEndpoint":s.mana(of:mover),
        "ourCommanderLibertiesAtEndpoint":rogueLiberties(s,owner:mover,kind:.commander),
        "enemyCommanderLibertiesAtEndpoint":rogueLiberties(s,owner:mover.opponent,kind:.commander),
        "endpoint":try object(ExpansionMatchRecord.Snapshot(s)),
        "scope":"Standard Bot two-ply continuation after a sampled enemy reply, NOT optimal play"]
}

extension P0Runner {
    static func rogueAudit(cohort:URL, p1:URL, output:URL) throws {
        let report=try readObject(p1)
        guard report["study"] as? String == "TG12_P1_SAME_STATE_COUNTERFACTUAL_V2",
              let positions=report["positions"] as? [[String:Any]],
              let source=positions.first(where: { ($0["game"] as? String) == "b9-Priest-Rogue" &&
                  ($0["turn"] as? Int) == 59 && ($0["ply"] as? Int) == 60 }),
              source["actor"] as? Int == 1,source["hero"] as? String == "Rogue",
              let alternatives=source["alternatives"] as? [[String:Any]],alternatives.count == 12
        else { throw StudyError.invalid("P1R pinned source not found or changed") }
        let (root,row)=try stateAt(cohort.appendingPathComponent("b9-Priest-Rogue"),turn:59)
        guard root.current == .two,root.ply == 60,root.apRemaining == 2,root.mana(of:.two) == 6,
              root.heroClass(of:.two) == .rogue,
              try ExpansionMatchRecord.Snapshot(root) == snapshot(source["before"]!),
              source["originalBotActions"] as? [[String:Any]] != nil,
              row["actions"] as? [[String:Any]] != nil else {
            throw StudyError.invalid("P1R source provenance failed")
        }
        // Candidate #5 is the observed finite counterexample, not a best-move claim.
        let indices=[0,5,8,9,10,11]
        var branches:[[String:Any]]=[]
        for id in indices {
            let old=alternatives[id]
            let moves=try rogueDomain(old["actions"] as? [[String:Any]] ?? [])
            guard moves.count == 2, let expected=old["after"] else {
                throw StudyError.invalid("P1R missing actions or own after")
            }
            let (after,ours)=try rogueApply(root,moves,mover:.two)
            guard try ExpansionMatchRecord.Snapshot(after) == snapshot(expected),
                  ours == old["enemySoldiersCaptured"] as? Int,
                  root.mana(of:.two)-after.mana(of:.two) == old["manaSpent"] as? Int,
                  let standard=old["reply"] as? [String:Any],standard["applicable"] as? Bool == true,
                  let knownReply=standard["recordActions"] as? [[String:Any]]
            else { throw StudyError.invalid("P1R P1 candidate altered") }
            let (responses,counts,allSoldiers,allPriestSkills,skillCases)=try rogueReplySet(
                after,expected:rogueDomain(knownReply),checkAllPriestSkills:id == 5)
            var written:[[String:Any]]=[]
            var worstNet=Int.max,minLibs=Int.max
            var worstIndex:Int?,libIndex:Int?,knownIndex:Int?,losses=0,heroLosses=0
            for (i,response) in responses.enumerated() {
                let next=response.final,net=ours-response.enemySoldiersTaken
                let libs=rogueLiberties(next,owner:.two,kind:.commander)
                if net<worstNet { worstNet=net;worstIndex=i }
                if libs<minLibs { minLibs=libs;libIndex=i }
                if response.sources.contains("p1_standard_reply") { knownIndex=i
                    guard let expectedAfter=standard["after"],
                          try ExpansionMatchRecord.Snapshot(next) == snapshot(expectedAfter) else {
                        throw StudyError.invalid("P1R Standard reply replay differs")
                    }
                }
                if next.winner == .one { losses += 1 }
                if next.board.find(.two,.hero) == nil { heroLosses += 1 }
                written.append(["sources":response.sources,
                    "actions":try rogueActionObject(response.actions),
                    "after":try object(ExpansionMatchRecord.Snapshot(next)),
                    "enemySoldiersTaken":response.enemySoldiersTaken,
                    "netSoldiersAfterReply":net,
                    "ourCommanderLiberties":libs,
                    "ourHeroAlive":next.board.find(.two,.hero) != nil,
                    "opponentImmediateWin":next.winner == .one,
                    "ourManaAtHandover":next.mana(of:.two),
                    "advancedAffordableNextTurn":next.mana(of:.two) >= 4,
                    "advancedActuallyLegalNextTurn":rogueAdvanced(next,owner:.two)])
            }
            guard let knownIndex else { throw StudyError.invalid("P1R missing standard reply") }
            // Equal material and Commander liberties are common in this example.
            // Without deliberate diversity, "worst" and "least liberties" select
            // the Standard reply again and never test a second future.
            let heroLow=responses.indices.min { a,b in
                let aa=rogueLiberties(responses[a].final,owner:.two,kind:.hero)
                let bb=rogueLiberties(responses[b].final,owner:.two,kind:.hero)
                return aa == bb ? a < b : aa < bb
            }
            let retainedDifferent=responses.indices.first {
                $0 != knownIndex && responses[$0].sources.contains("bounded_standard_retained")
            }
            let priestOffering=responses.indices.first {
                responses[$0].actions.contains(where:{ if case .castOffering = $0 { return true };return false })
            }
            let priestSanctum=responses.indices.first {
                responses[$0].actions.contains(where:{ if case .castSanctum = $0 { return true };return false })
            }
            let purePass=responses.indices.first {
                responses[$0].actions.count == 1 && responses[$0].actions[0] == .endTurn
            }
            let selected=Array(Set([knownIndex,worstIndex,libIndex,heroLow,retainedDifferent,
                                    priestOffering,priestSanctum,purePass].compactMap{$0})).sorted()
            var continuations:[[String:Any]]=[]
            for idx in selected {
                let response=responses[idx]
                let why:String
                if idx == knownIndex { why="standard" }
                else if idx == priestSanctum { why="priest_sanctum_counterplay" }
                else if idx == priestOffering { why="priest_offering_counterplay" }
                else if idx == purePass { why="enemy_pass_resource_counterfactual" }
                else if idx == heroLow { why="minimum_hero_liberties" }
                else if idx == retainedDifferent { why="different_retained_bot_reply" }
                else if idx == worstIndex { why="minimum_observed_net_captures" }
                else { why="minimum_commander_liberties" }
                continuations.append(["replyIndex":idx,"chosenBecause":why,
                    "simulation":try rogueContinue(response.final,mover:.two,
                                                   capturedMe:ours,capturedThem:response.enemySoldiersTaken)])
            }
            branches.append(["p1AlternativeIndex":id, "group":old["group"]!,
                "origin":old["origin"]!,
                "ownActions":old["actions"]!,
                "ownAfter":try object(ExpansionMatchRecord.Snapshot(after)),
                "ourSoldiersTakenFromEnemy":ours,
                "manaSpent":root.mana(of:.two)-after.mana(of:.two),
                "responseFamilies":counts, "allLegalPlacementOnlyReplyTurnsCovered":allSoldiers,
                "allOrderedPriestSkillReplyTurnsCovered":id == 5 ? allPriestSkills : false,
                "priestSkillSecondActionCandidatesInspected":skillCases,
                "responsesEnumerated":responses.count,
                "observedNetMaterialRange":[worstNet,
                   written.map { $0["netSoldiersAfterReply"] as! Int }.max() ?? worstNet],
                "minimumOurCommanderLibertiesAmongResponses":minLibs,
                "knownImmediateLossResponses":losses,
                "knownHeroLostResponses":heroLosses,
                "standardReplyIndex":knownIndex,
                "standardReplyNetSoldiers":written[knownIndex]["netSoldiersAfterReply"]!,
                "standardReplyManaNextTurn":written[knownIndex]["ourManaAtHandover"]!,
                "standardReplyAdvancedSkillActuallyLegalNextTurn":written[knownIndex]["advancedActuallyLegalNextTurn"]!,
                "replies":written, "twoCycleContinuations":continuations])
            log("ROGUE P1R branch \(id) replies=\(responses.count) allTwoSoldier=\(allSoldiers) materialMin=\(worstNet) kingMinLib=\(minLibs) instantWins=\(losses)")
        }
        let outcomes:[String:Any]=["study":"TG12_P1_ROGUE_COUNTERPLAY_V1",
            "source":"P0 official-opening b9-Priest-Rogue turn59 / P1 V2 candidate5; all Core history retained",
            "root":try object(ExpansionMatchRecord.Snapshot(root)),
            "selectedIndices":indices, "branches":branches,
            "boundaries":[
                "All legal placement-only complete enemy turns are enumerated with a complete flag; candidate5 separately enumerates both orders of ALL current-mode enemy Priest skills under 8k second-action cap",
                "Other responses include Standard, Easy and bounded Standard candidateTurns. Do not claim all skill responses if the Priest completeness flag is false or unsupported action kinds are encountered",
                "Counterexample means one real legal reply; lack of one remains UNKNOWN",
                "Two-cycle continuations use Standard Bot only, not minimax or proof of persistent benefit",
                "Each response and each selected two-cycle includes record-format actions and snapshots",
                "Mana at next own turn includes the official regeneration and cap; skill eligibility includes board conditions",
                "No product Core, Bot, fee, save, billing, release or UI code changed"
            ],
            "notClaimed":["best counterplay","guaranteed tactical safety","long-term dominance","full P1 pass",
                          "balanced skills","human fun","iPhone performance","C# parity"]]
        try write(outcomes,output)
        log("P1R research written \(output.path) with \(branches.count) branches")
    }

    /// Recheck published response receipts and independent two-cycle continuations.
    /// No snapshot-only reconstruction: always obtain the full official opening history.
    static func rogueVerify(cohort:URL,output:URL,negativeControls:Bool=false) throws {
        let data=try readObject(output)
        let (root,row)=try stateAt(cohort.appendingPathComponent("b9-Priest-Rogue"),turn:59)
        let checks=try rogueVerifyData(data,root:root,sourceActions:row["actions"]!)
        log("PASS P1R replay verified \(checks) own/reply/continuation receipts; coverage and metrics verified")
        if negativeControls {
            // Mutate persisted evidence, not expected values derived from the producer.
            let cases=["reply-count","next-skill","missing-reply","duplicate-branch",
                       "suppressed-continuation","missing-continuations","duplicate-continuation",
                       "missing-second-enemy","endpoint","root"]
            for name in cases {
                var bad=data
                var branches=bad["branches"] as! [[String:Any]]
                switch name {
                case "reply-count": branches[1]["responsesEnumerated"]=0
                case "next-skill": branches[1]["standardReplyAdvancedSkillActuallyLegalNextTurn"]=true
                case "missing-reply":
                    var replies=branches[1]["replies"] as! [[String:Any]]
                    replies.removeLast();branches[1]["replies"]=replies
                case "duplicate-branch": branches[1]=branches[0]
                case "missing-continuations": branches[1]["twoCycleContinuations"]=[] as [[String:Any]]
                case "duplicate-continuation":
                    var continuations=branches[1]["twoCycleContinuations"] as! [[String:Any]]
                    continuations.append(continuations[0]);branches[1]["twoCycleContinuations"]=continuations
                case "missing-second-enemy":
                    var continuations=branches[1]["twoCycleContinuations"] as! [[String:Any]]
                    var sim=continuations[0]["simulation"] as! [String:Any]
                    sim["nextEnemyActions"]=[] as [[String:Any]]
                    continuations[0]["simulation"]=sim;branches[1]["twoCycleContinuations"]=continuations
                case "suppressed-continuation", "endpoint":
                    var continuations=branches[1]["twoCycleContinuations"] as! [[String:Any]]
                    var sim=continuations[0]["simulation"] as! [String:Any]
                    if name == "suppressed-continuation" { sim["applicable"]=false }
                    else {
                        var endpoint=sim["endpoint"] as! [String:Any]
                        endpoint["ap"]=99;sim["endpoint"]=endpoint
                    }
                    continuations[0]["simulation"]=sim;branches[1]["twoCycleContinuations"]=continuations
                default:
                    var snapshot=bad["root"] as! [String:Any]
                    snapshot["ap"]=99;bad["root"]=snapshot
                }
                bad["branches"]=branches
                var rejected=false
                do { _ = try rogueVerifyData(bad,root:root,sourceActions:row["actions"]!) }
                catch { rejected=true }
                guard rejected else { throw StudyError.invalid("P1R negative control accepted: \(name)") }
                log("PASS P1R rejects \(name)")
            }
            log("P1R_CONTRACT_CHECKS=\(cases.count)")
        }
    }

    private static func rogueVerifyData(_ data:[String:Any],root:GameState,sourceActions:Any) throws -> Int {
        let indices=[0,5,8,9,10,11]
        guard data["study"] as? String == "TG12_P1_ROGUE_COUNTERPLAY_V1",
              let branches=data["branches"] as? [[String:Any]],
              data["selectedIndices"] as? [Int] == indices,
              branches.compactMap({$0["p1AlternativeIndex"] as? Int}) == indices
        else { throw StudyError.invalid("P1R invalid report") }
        guard try ExpansionMatchRecord.Snapshot(root) == snapshot(data["root"]!) else {
            throw StudyError.invalid("P1R root mismatch")
        }
        var checks=0
        for branch in branches {
            let id=branch["p1AlternativeIndex"] as! Int
            let plan=try rogueDomain(branch["ownActions"] as? [[String:Any]] ?? [])
            if id == 0 {
                guard try plan == rogueDomain(sourceActions as! [[String:Any]]) else {
                    throw StudyError.invalid("P1R observed source actions differ")
                }
            }
            let (after,ours)=try rogueApply(root,plan,mover:.two)
            guard try ExpansionMatchRecord.Snapshot(after) == snapshot(branch["ownAfter"]!),
                  ours == branch["ourSoldiersTakenFromEnemy"] as? Int else {
                throw StudyError.invalid("P1R own receipt")
            }
            checks += 1
            guard let replies=branch["replies"] as? [[String:Any]] else {
                throw StudyError.invalid("P1R responses missing")
            }
            var keys=Set<String>(),soldierKeys=Set<String>(),families:[String:Int]=[:]
            for reply in replies {
                let moves=try rogueDomain(reply["actions"] as? [[String:Any]] ?? [])
                guard keys.insert(rogueActionsKey(moves)).inserted,
                      let sources=reply["sources"] as? [String],!sources.isEmpty,
                      Set(sources).count == sources.count else { throw StudyError.invalid("P1R duplicate reply/source") }
                for source in sources { families[source,default:0] += 1 }
                if sources.contains("all_soldier_only_replies") { soldierKeys.insert(rogueActionsKey(moves)) }
            }
            guard try soldierKeys == rogueCensus(after,soldiersOnly:true) else {
                throw StudyError.invalid("P1R soldier coverage differs")
            }
            if id == 5 {
                guard try keys == rogueCensus(after,soldiersOnly:false) else {
                    throw StudyError.invalid("P1R complete Priest coverage differs")
                }
            }
            for reply in replies {
                let moves=try rogueDomain(reply["actions"] as? [[String:Any]] ?? [])
                let (afterReply,taken)=try rogueApply(after,moves,mover:.one)
                guard try ExpansionMatchRecord.Snapshot(afterReply) == snapshot(reply["after"]!),
                      taken == reply["enemySoldiersTaken"] as? Int,
                      ours-taken == reply["netSoldiersAfterReply"] as? Int,
                      afterReply.mana(of:.two) == reply["ourManaAtHandover"] as? Int else {
                    throw StudyError.invalid("P1R opponent reply receipt")
                }
                let advanced=GameEngine.legalActions(afterReply).contains {
                    if case .castChainSwap = $0 { return true };return false
                }
                try rogueFields(reply,[
                    "ourCommanderLiberties":rogueLiberties(afterReply,owner:.two,kind:.commander),
                    "ourHeroAlive":afterReply.board.find(.two,.hero) != nil,
                    "opponentImmediateWin":afterReply.winner == .one,
                    "advancedAffordableNextTurn":afterReply.mana(of:.two) >= afterReply.config.expansionSkillManaCost,
                    "advancedActuallyLegalNextTurn":afterReply.status == .ongoing && afterReply.current == .two && advanced
                ],"reply metrics")
                checks += 1
            }
            guard let standardIndex=branch["standardReplyIndex"] as? Int,replies.indices.contains(standardIndex),
                  (replies[standardIndex]["sources"] as? [String])?.contains("p1_standard_reply") == true else {
                throw StudyError.invalid("P1R Standard reply index")
            }
            let standard=replies[standardIndex]
            let net=replies.map{$0["netSoldiersAfterReply"] as! Int}
            try rogueFields(branch,[
                "responsesEnumerated":replies.count,"responseFamilies":families,
                "manaSpent":root.mana(of:.two)-after.mana(of:.two),
                "allLegalPlacementOnlyReplyTurnsCovered":true,
                "allOrderedPriestSkillReplyTurnsCovered":id == 5,
                "observedNetMaterialRange":[net.min()!,net.max()!],
                "minimumOurCommanderLibertiesAmongResponses":replies.map{$0["ourCommanderLiberties"] as! Int}.min()!,
                "knownImmediateLossResponses":replies.filter{$0["opponentImmediateWin"] as? Bool == true}.count,
                "knownHeroLostResponses":replies.filter{$0["ourHeroAlive"] as? Bool == false}.count,
                "standardReplyNetSoldiers":standard["netSoldiersAfterReply"]!,
                "standardReplyManaNextTurn":standard["ourManaAtHandover"]!,
                "standardReplyAdvancedSkillActuallyLegalNextTurn":standard["advancedActuallyLegalNextTurn"]!
            ],"branch summary")
            guard let continuations=branch["twoCycleContinuations"] as? [[String:Any]],!continuations.isEmpty,
                  continuations.compactMap({$0["replyIndex"] as? Int}).count == continuations.count,
                  Set(continuations.compactMap({$0["replyIndex"] as? Int})).count == continuations.count,
                  continuations.contains(where:{$0["replyIndex"] as? Int == standardIndex}) else {
                throw StudyError.invalid("P1R continuations missing")
            }
            for continuation in continuations {
                guard let idx=continuation["replyIndex"] as? Int,replies.indices.contains(idx),
                      let sim=continuation["simulation"] as? [String:Any] else {
                    throw StudyError.invalid("P1R continuation metadata")
                }
                let sampled=replies[idx]
                let (start,taken)=try rogueApply(after,rogueDomain(sampled["actions"] as! [[String:Any]]),mover:.one)
                try rogueFields(sim,["applicable":start.status == .ongoing && start.current == .two],"continuation")
                if sim["applicable"] as? Bool == true {
                    let (afterOwn,more)=try rogueApply(start,rogueDomain(sim["nextOwnActions"] as! [[String:Any]]),mover:.two)
                    var result=afterOwn,secondEnemy=0
                    let opponentActions=try rogueDomain(sim["nextEnemyActions"] as! [[String:Any]])
                    guard !opponentActions.isEmpty == (afterOwn.status == .ongoing && afterOwn.current == .one) else {
                        throw StudyError.invalid("P1R missing or spurious second enemy turn")
                    }
                    if !opponentActions.isEmpty {
                        (result,secondEnemy)=try rogueApply(result,opponentActions,mover:.one)
                    }
                    guard try ExpansionMatchRecord.Snapshot(result) == snapshot(sim["endpoint"]!),
                          ours+more-taken-secondEnemy == sim["captureCountAtTwoCycles"] as? Int else {
                        throw StudyError.invalid("P1R two-cycle mismatch")
                    }
                    let advanced=GameEngine.legalActions(start).contains {
                        if case .castChainSwap = $0 { return true };return false
                    }
                    try rogueFields(sim,[
                        "initialManaOnNextOwnTurn":start.mana(of:.two),
                        "advancedSkillAvailableAtNextOwnTurn":advanced,
                        "newEnemySoldiersTakenByRogue":more,"newRogueSoldiersTakenByEnemy":secondEnemy,
                        "ourCommanderAlive":result.board.find(.two,.commander) != nil,
                        "ourHeroAlive":result.board.find(.two,.hero) != nil,
                        "manaAtTwoCycleEndpoint":result.mana(of:.two),
                        "ourCommanderLibertiesAtEndpoint":rogueLiberties(result,owner:.two,kind:.commander),
                        "enemyCommanderLibertiesAtEndpoint":rogueLiberties(result,owner:.one,kind:.commander)
                    ],"continuation metrics")
                    checks += 1
                }
            }
        }
        return checks
    }
}
