import Foundation
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import P0Metrics

/// P1 counterfactual study. All states come from verified official-opening P0 records.
/// No product Core/Bot/UI changes and no assumption that a heuristic move is optimal.
private struct P1Plan {
    let group: String
    let actions: [GameAction]
    let after: GameState
    let manaSpent: Int
    let enemySoldiersCaptured: Int
    let isAdvanced: Bool
    let origin: String
}

private func spaced<T>(_ values: [T], _ wanted: Int) -> [T] {
    let n = min(values.count, max(0, wanted))
    if n == 0 { return [] }
    if n == 1 { return [values[0]] }
    return (0..<n).map { values[$0 * (values.count - 1) / (n - 1)] }
}

private func currentMoves(_ state: GameState, cap: Int = 256) -> [GameAction] {
    var result = GameEngine.legalActions(state, expansionCandidateLimit: cap)
        .filter { P0Metrics.isInCurrentMode($0, config: state.config) }
    // A negative priest-Sanctum observation must not be caused by truncation of advanced pairs.
    if state.heroClass(of: state.current) == .priest,
       state.config.expansionSkills, state.apRemaining > 0,
       state.board.find(state.current, .hero) != nil,
       !state.skillUsedThisTurn,
       state.mana(of: state.current) >= state.config.expansionSkillManaCost,
       !result.contains(where: { if case .castSanctum = $0 { return true }; return false }) {
        result = GameEngine.legalActions(state)
            .filter { P0Metrics.isInCurrentMode($0, config: state.config) }
    }
    return result
}

private func isSoldier(_ action: GameAction) -> Bool {
    if case .placeSoldier = action { return true }
    return false
}

private func planKey(_ actions: [GameAction]) -> String {
    actions.map { String(reflecting: $0) }.joined(separator: "|")
}

private func commanderLiberties(_ state: GameState, for player: Player) -> Int {
    state.board.find(player, .commander).map { state.board.liberties(at: $0).count } ?? 0
}

private func heroLiberties(_ state: GameState, for player: Player) -> Int {
    state.board.find(player, .hero).map { state.board.liberties(at: $0).count } ?? 0
}

private func responseSample(_ state: GameState) -> [GameAction] {
    let actions = currentMoves(state, cap: 48)
    // Sample both normal moves and skills. Core's ordering alone would systematically
    // select soldier placements and could miss every enemy skill.
    return spaced(actions.filter(isSoldier), 8)
        + spaced(actions.filter(P0Metrics.isBasic), 3)
        + spaced(actions.filter(P0Metrics.isAdvanced), 3)
        + actions.filter { $0 == .endTurn }
}

/// Positive risk witnesses are exact legal Core actions; negative findings are never a
/// certificate of safety because advanced pairs and response lists are intentionally bounded.
private func immediateCounterexample(_ root: GameState, against originalMover: Player) -> [String: Any] {
    guard root.status == .ongoing, root.current == originalMover.opponent else {
        return ["verdict": root.winner == originalMover ? "player_already_won" : "no_opponent_turn",
                "explicitApplies": 0]
    }
    let opponent = root.current
    var attempts = 0
    for first in responseSample(root) {
        let firstOutcome = GameEngine.apply(root, first)
        attempts += 1
        guard firstOutcome.success else { continue }
        if firstOutcome.state.winner == opponent {
            return ["verdict": "opponent_can_win", "explicitApplies": attempts,
                    "witness": [String(reflecting:first)]]
        }
        guard firstOutcome.state.status == .ongoing,
              firstOutcome.state.current == opponent else { continue }
        for second in responseSample(firstOutcome.state) {
            let secondOutcome = GameEngine.apply(firstOutcome.state, second)
            attempts += 1
            guard secondOutcome.success else { continue }
            if secondOutcome.state.winner == opponent {
                return ["verdict": "opponent_can_win", "explicitApplies": attempts,
                        "witness": [String(reflecting:first), String(reflecting:second)]]
            }
        }
    }
    return ["verdict": "not_found_within_bounded_reply_sample",
            "explicitApplies": attempts, "provesSafe": false,
            "method": "up to 8 soldier + 3 basic skill + 3 advanced skill + pass, per AP, Core verified"]
}

private func followStandardReply(_ after: GameState, originalMover: Player) throws -> [String: Any] {
    guard after.status == .ongoing, after.current == originalMover.opponent else {
        return ["applicable": false, "reason": "terminal_or_no_handoff"]
    }
    let defender = originalMover.opponent
    guard let choice = BotPlanner.planTurn(after, difficulty:.standard, policy:.baseline) else {
        throw StudyError.invalid("P1 opponent Standard plan unavailable")
    }
    var replay = after
    var capturedByEnemy = 0
    for action in choice.actions {
        let step = GameEngine.apply(replay, action)
        guard step.success else { throw StudyError.invalid("P1 enemy reply illegal") }
        capturedByEnemy += captured(step, by:defender)
        replay = step.state
    }
    guard replay.status != .ongoing || replay.current == originalMover else {
        throw StudyError.invalid("P1 enemy reply stopped before complete turn")
    }
    return ["applicable": true, "actions": choice.actions.map { String(reflecting:$0) },
            "standardBotCapturedOurSoldiers": capturedByEnemy,
            "ourCommanderAliveAfterStandardReply": replay.board.find(originalMover,.commander) != nil,
            "ourCommanderLibertiesAfterStandardReply": commanderLiberties(replay, for:originalMover),
            "ourHeroAliveAfterStandardReply": replay.board.find(originalMover,.hero) != nil,
            "outcome": replay.status.rawValue,
            "opponentSearchBudgetExhausted": choice.stats.budgetExhausted,
            "scope": "One actual Standard/Baseline Bot complete reply; not minimax or best counterplay"]
}

extension P0Runner {
    private static func construct(_ root: GameState, group: String, actions: [GameAction],
                                  origin: String) throws -> P1Plan? {
        let mover = root.current
        var state = root, spent = 0, taken = 0
        for (index, action) in actions.enumerated() {
            let step = GameEngine.apply(state, action)
            guard step.success else { return nil }
            spent += manaSpent(step.events)
            taken += captured(step, by:mover)
            state = step.state
            if index < actions.count - 1 && (state.status != .ongoing || state.current != mover) {
                return nil
            }
        }
        guard state.status != .ongoing || state.current != mover else { return nil }
        return P1Plan(group:group,actions:actions,after:state,manaSpent:spent,
                      enemySoldiersCaptured:taken,
                      isAdvanced:actions.contains(where:P0Metrics.isAdvanced),origin:origin)
    }

    /// These are deterministic representative probes, NOT all legal turn pairs.
    /// Same initial state, resources, historical positions and Bot policy for every plan.
    private static func candidates(_ root:GameState, original: [GameAction]) throws -> [P1Plan] {
        let first=currentMoves(root)
        let places=first.filter(isSoldier)
        let basic=first.filter(P0Metrics.isBasic)
        let advanced=first.filter(P0Metrics.isAdvanced)
        var raw:[P1Plan]=[],seen=Set<String>()
        func consider(_ group:String,_ actions:[GameAction],origin:String) throws {
            let key=planKey(actions)
            guard seen.insert(key).inserted else { return }
            if let plan=try construct(root, group:group, actions:actions, origin:origin) { raw.append(plan) }
        }
        // Include the observed Bot action even if it is not retained by the sampling algorithm.
        if !original.isEmpty {
            let kind=P0Metrics.pattern(original)
            let category:String
            switch kind {
            case "skill+soldier": category="skill_then_soldier"
            case "soldier+skill": category="soldier_then_skill"
            case "soldier+soldier": category="two_soldiers"
            default: category="observed_other"
            }
            try consider(category, original, origin:"P0_observed_Bot_plan")
        }
        let firstSkills=spaced(basic,3) + spaced(advanced,3)
        for skill in firstSkills {
            let one=GameEngine.apply(root,skill)
            guard one.success,one.state.status == .ongoing,one.state.current == root.current else { continue }
            for second in spaced(currentMoves(one.state).filter(isSoldier),4) {
                try consider("skill_then_soldier",[skill,second],origin:"bounded_representative")
            }
        }
        for place in spaced(places,5) {
            let one=GameEngine.apply(root,place)
            guard one.success,one.state.status == .ongoing,one.state.current == root.current else { continue }
            let legal=currentMoves(one.state)
            for skill in spaced(legal.filter(P0Metrics.isBasic),3) + spaced(legal.filter(P0Metrics.isAdvanced),3) {
                try consider("soldier_then_skill",[place,skill],origin:"bounded_representative")
            }
            for second in spaced(legal.filter(isSoldier),4) {
                try consider("two_soldiers",[place,second],origin:"bounded_representative")
            }
        }
        // Preserve different information axes rather than collapsing into an ungrounded
        // single 'best move' score: observed, lowest mana, highest actual capture, advanced.
        var final:[P1Plan]=[]
        for group in ["skill_then_soldier","soldier_then_skill","two_soldiers"] {
            let groupPlans=raw.filter { $0.group == group }
            var chosen:[P1Plan]=[],identifiers=Set<String>()
            func include(_ plan:P1Plan?) {
                guard let plan,chosen.count < 4 else { return }
                if identifiers.insert(planKey(plan.actions)).inserted { chosen.append(plan) }
            }
            include(groupPlans.first { $0.origin == "P0_observed_Bot_plan" })
            include(groupPlans.min { $0.manaSpent == $1.manaSpent ? planKey($0.actions) < planKey($1.actions) : $0.manaSpent < $1.manaSpent })
            include(groupPlans.max { $0.enemySoldiersCaptured == $1.enemySoldiersCaptured
                ? planKey($0.actions) > planKey($1.actions)
                : $0.enemySoldiersCaptured < $1.enemySoldiersCaptured })
            include(groupPlans.first { $0.isAdvanced })
            for plan in groupPlans { include(plan) }
            final += chosen
        }
        final += raw.filter { $0.group == "observed_other" }.prefix(1)
        return final
    }

    static func p1Audit(cohort:URL,selectionFile:URL,output:URL,maxPositions:Int) throws {
        let raw=try JSONSerialization.jsonObject(with:Data(contentsOf:selectionFile))
        guard let indices=raw as? [[String:Any]] else { throw StudyError.invalid("P1 selection array") }
        var all:[[String:Any]]=[]
        for entry in indices.prefix(max(1,maxPositions)) {
            guard let game=entry["game"] as? String,let turn=entry["turn"] as? Int,
                  !game.contains("/") && !game.contains("..") else { throw StudyError.invalid("P1 selection index") }
            let dir=cohort.appendingPathComponent(game)
            let (root,row)=try stateAt(dir,turn:turn)
            let serialized=row["actions"] as? [[String:Any]] ?? []
            let actual=try serialized.map { try JSONDecoder().decode(ExpansionMatchRecord.Action.self,
                from:JSONSerialization.data(withJSONObject:$0)).domain() }
            let plans=try candidates(root,original:actual)
            var outcomes:[[String:Any]]=[]
            for plan in plans {
                let botReply=try followStandardReply(plan.after,originalMover:root.current)
                let boundedCounterexample=immediateCounterexample(plan.after,against:root.current)
                outcomes.append([
                    "group":plan.group,"origin":plan.origin,
                    "actions":try plan.actions.map { try object(ExpansionMatchRecord.Action($0)) },
                    "advancedSkillUsed":plan.isAdvanced,
                    "manaSpent":plan.manaSpent,"manaRemaining":plan.after.mana(of:root.current),
                    "enemySoldiersCaptured":plan.enemySoldiersCaptured,
                    "ourCommanderLiberties":commanderLiberties(plan.after,for:root.current),
                    "enemyCommanderLiberties":commanderLiberties(plan.after,for:root.current.opponent),
                    "ourHeroLiberties":heroLiberties(plan.after,for:root.current),
                    "ourHeroPresent":plan.after.board.find(root.current,.hero) != nil,
                    "immediateWin":plan.after.winner == root.current,
                    "after":try object(ExpansionMatchRecord.Snapshot(plan.after)),
                    "reply":botReply, "immediateLossProbe":boundedCounterexample
                ])
            }
            let groupCounts=Dictionary(grouping:outcomes,by:{ $0["group"] as? String ?? "unknown" })
                .mapValues { $0.count }
            all.append(["game":game,"turn":turn,"ply":root.ply,
                "sourceSelectionReason":entry["reason"] as? String ?? "unknown",
                "hero":root.heroClass(of:root.current).rawValue,
                "actor":root.current.rawValue,
                "before":try object(ExpansionMatchRecord.Snapshot(root)),
                "originalBotActions":serialized,
                "startingRootBasicSkillLegal":currentMoves(root).contains(where:P0Metrics.isBasic),
                "startingRootAdvancedSkillLegal":currentMoves(root).contains(where:P0Metrics.isAdvanced),
                "sampledCounts":groupCounts,"alternatives":outcomes])
            log("P1 \(game) turn=\(turn) hero=\(root.heroClass(of:root.current).rawValue) candidates=\(outcomes.count)")
        }
        let report:[String:Any]=[
            "study":"TG12_P1_SAME_STATE_COUNTERFACTUAL_V1",
            "source":"P0 official-opening archived records; full receipt and superko replay verified before each comparison",
            "positions":all,
            "semantics":[
                "same-root":"all candidates replay from the same P0 GameState, not independently reconstructed diagrams",
                "classes":"skill-then-soldier, soldier-then-skill, two-soldiers; up to four representatives per category",
                "sampling":"up to 3 basic skills + 3 advanced skills + 5 soldier first actions; up to 3-4 followups each; representative lowest-mana, max-capture, observed and advanced where available",
                "opponent":"one complete Standard/Baseline Bot reply plus bounded Core-valid immediate-win counterexample search",
                "negative-result":"no winning reply found is UNKNOWN rather than proof of safety",
                "best-move":"not claimed; no exhaustive P1 dominance or multi-turn minimax guarantee",
                "advanced-enumeration":"256 cap for initial candidate search; priest fallback uncapped if no Sanctum found",
                "privacy":"no identifiers, network transmission or device data"
            ],
            "notClaimed":["skill value proven","human fun","balance","optimal enemy reply",
                          "all legal two-action alternatives enumerated","stale or modified product policy"]
        ]
        try write(report,output)
        log("P1 result written \(output.path), \(all.count) verified positions")
    }
}
