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
private func rogueReplySet(_ after:GameState, expected:[GameAction]) throws
    -> ([RogueReply],[String:Int],Bool) {
    guard after.status == .ongoing else { return ([],[:],true) }
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
    var counts:[String:Int]=[:]
    for reply in replies { for name in reply.sources { counts[name,default:0] += 1 } }
    return (replies,counts,exhaustive)
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
            let (responses,counts,allSoldiers)=try rogueReplySet(after,expected:rogueDomain(knownReply))
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
            let selected=Array(Set([knownIndex,worstIndex,libIndex].compactMap{$0})).sorted()
            var continuations:[[String:Any]]=[]
            for idx in selected {
                let response=responses[idx]
                continuations.append(["replyIndex":idx,"chosenBecause":idx==knownIndex ? "standard"
                    : idx==worstIndex ? "minimum_observed_net_captures" : "minimum_commander_liberties",
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
                "All legal placement-only complete enemy turns are enumerated (if complete flag true) via uncapped placeSoldier legality plus pass; this is NOT all enemy skills",
                "Other responses include Standard, Easy and bounded Standard candidateTurns, NOT a complete hostile policy space",
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
    static func rogueVerify(cohort:URL,output:URL) throws {
        let data=try readObject(output)
        guard data["study"] as? String == "TG12_P1_ROGUE_COUNTERPLAY_V1",
              let branches=data["branches"] as? [[String:Any]],
              branches.count == 6 else { throw StudyError.invalid("P1R invalid report") }
        let (root,_)=try stateAt(cohort.appendingPathComponent("b9-Priest-Rogue"),turn:59)
        guard try ExpansionMatchRecord.Snapshot(root) == snapshot(data["root"]!) else {
            throw StudyError.invalid("P1R root mismatch")
        }
        var checks=0
        for branch in branches {
            let plan=try rogueDomain(branch["ownActions"] as? [[String:Any]] ?? [])
            let (after,ours)=try rogueApply(root,plan,mover:.two)
            guard try ExpansionMatchRecord.Snapshot(after) == snapshot(branch["ownAfter"]!),
                  ours == branch["ourSoldiersTakenFromEnemy"] as? Int else {
                throw StudyError.invalid("P1R own receipt")
            }
            checks += 1
            guard let replies=branch["replies"] as? [[String:Any]] else {
                throw StudyError.invalid("P1R responses missing")
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
                checks += 1
            }
            guard let continuations=branch["twoCycleContinuations"] as? [[String:Any]] else {
                throw StudyError.invalid("P1R continuations missing")
            }
            for continuation in continuations {
                guard let idx=continuation["replyIndex"] as? Int,replies.indices.contains(idx),
                      let sim=continuation["simulation"] as? [String:Any] else {
                    throw StudyError.invalid("P1R continuation metadata")
                }
                let sampled=replies[idx]
                let (start,taken)=try rogueApply(after,rogueDomain(sampled["actions"] as! [[String:Any]]),mover:.one)
                if sim["applicable"] as? Bool == true {
                    let (afterOwn,more)=try rogueApply(start,rogueDomain(sim["nextOwnActions"] as! [[String:Any]]),mover:.two)
                    var result=afterOwn,secondEnemy=0
                    let opponentActions=try rogueDomain(sim["nextEnemyActions"] as! [[String:Any]])
                    if !opponentActions.isEmpty {
                        (result,secondEnemy)=try rogueApply(result,opponentActions,mover:.one)
                    }
                    guard try ExpansionMatchRecord.Snapshot(result) == snapshot(sim["endpoint"]!),
                          ours+more-taken-secondEnemy == sim["captureCountAtTwoCycles"] as? Int else {
                        throw StudyError.invalid("P1R two-cycle mismatch")
                    }
                    checks += 1
                }
            }
        }
        log("PASS P1R replay verified \(checks) own/reply/continuation receipts")
    }
}
