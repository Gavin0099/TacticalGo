import TacticalGoCore

/// Experimental policies are opt-in; baseline remains the default and fallback.
/// Forcing continuation proves a Core win after every complete enemy reply.
/// Material continuation proves a new safe soldier capture after every reply.
/// Missing search is never safety; neither policy changes the game rules.
public enum BotPolicy: String, Sendable, CaseIterable { case baseline, forcingContinuation, materialThreatContinuation }

struct BotTurnCandidate {
    let state: GameState
    let actions: [GameAction]
    /// The planner's own-turn heuristic score; observation only, not used by the continuation policies.
    var score = 0
    var key: String { actions.map(botActionDescription).joined(separator: "/") }
}

/// Opt-in material continuation. Ordering proposes at most one hypothesis; only
/// actual Core capture events and exhaustive complete replies can authorize it.
/// This does not prove a next-turn win or repair every dense-board Pass.
struct BotMaterialContinuation {
    let root: GameState
    let baseline: BotTurnPlan
    let limits: BotLimits
    let candidates: [BotTurnCandidate]
    let cancelled: @Sendable () -> Bool
    var stats: BotSearchStats
    var incomplete = false
    var me: Player { root.current }

    init(root: GameState, baseline: BotTurnPlan, limits: BotLimits, candidates: [BotTurnCandidate],
         cancelled: @escaping @Sendable () -> Bool) {
        self.root = root; self.baseline = baseline; self.limits = limits
        self.candidates = candidates; self.cancelled = cancelled; stats = baseline.stats
    }
    private struct Turn {
        let state: GameState
        let actions: [GameAction]
        let capturedSoldiers: Int
        var key: String { actions.map(botActionDescription).joined(separator: "/") }
    }
    private mutating func apply(_ state: GameState, _ action: GameAction) -> ActionOutcome? {
        if cancelled() { incomplete = true; return nil }
        guard stats.domainTransitions < limits.maxDomainTransitions else {
            incomplete = true; stats.budgetExhausted = true; return nil
        }
        stats.domainTransitions += 1
        let result = GameEngine.apply(state, action)
        guard result.success else { incomplete = true; return nil }
        return result
    }
    private mutating func legal(_ state: GameState) -> [GameAction]? {
        if cancelled() { incomplete = true; return nil }
        guard stats.domainTransitions < limits.maxDomainTransitions else {
            incomplete = true; stats.budgetExhausted = true; return nil
        }
        stats.legalEnumerations += 1
        return GameEngine.legalActions(state)
    }
    private func captures(_ outcome: ActionOutcome) -> Int {
        outcome.events.reduce(0) { count, event in
            guard case .piecesCaptured(let owner, let pieces) = event, owner == me else { return count }
            return count + pieces.filter { $0.piece == Piece(me.opponent, .soldier) }.count
        }
    }
    /// No beam, board/history merging, or omitted early Pass in a proof turn.
    private mutating func turns(_ state: GameState) -> [Turn]? {
        guard state.status == .ongoing else { return [] }
        guard (1...2).contains(state.apRemaining), let actions = legal(state) else {
            incomplete = true; return nil
        }
        let owner = state.current
        var rows: [Turn] = []
        for first in actions {
            guard let out = apply(state, first) else { return nil }
            if out.state.current != owner || out.state.status != .ongoing {
                rows.append(Turn(state: out.state, actions: [first], capturedSoldiers: captures(out)))
                continue
            }
            guard let seconds = legal(out.state) else { return nil }
            for second in seconds {
                guard let end = apply(out.state, second) else { return nil }
                guard end.state.current != owner || end.state.status != .ongoing else {
                    incomplete = true; return nil
                }
                rows.append(Turn(state: end.state, actions: [first, second],
                    capturedSoldiers: captures(out) + captures(end)))
            }
        }
        return rows
    }
    private func commanderSafe(_ state: GameState) -> Bool {
        state.board.find(me, .commander) != nil && state.winner != me.opponent
    }
    /// A witnessed soldier capture must also survive every complete following
    /// enemy turn. Fewer liberties or a heuristic gain alone are never success.
    private mutating func safeCapture(_ state: GameState) -> (turn: Turn, counters: Int)? {
        guard state.status == .ongoing, state.current == me, let ownTurns = turns(state) else { return nil }
        for own in ownTurns where own.capturedSoldiers > 0 && commanderSafe(own.state) && own.state.status != .drawn {
            guard let counters = turns(own.state) else { return nil }
            if counters.allSatisfy({ commanderSafe($0.state) }) { return (own, counters.count) }
        }
        return nil
    }
    private func commanderLiberties(_ state: GameState) -> Int {
        state.board.find(me, .commander).map { state.board.liberties(at: $0).count } ?? 0
    }
    private func pressure(_ state: GameState) -> Int {
        // Ordering only: strongest reduction in an existing enemy soldier group's
        // liberties. Capture itself and commander groups belong to other tactics.
        var seen: Set<Point> = [], result = 0
        for p in root.board.points where root.board[p] == Piece(me.opponent, .soldier) && !seen.contains(p) {
            let group = root.board.group(at: p); seen.formUnion(group)
            guard !group.contains(where: { root.board[$0]?.kind == .commander }),
                  state.board[p] == root.board[p] else { continue }
            result = max(result, root.board.liberties(at: p).count - state.board.liberties(at: p).count)
        }
        return result
    }
    mutating func run() -> BotTurnPlan? {
        guard !cancelled() else { return nil }
        guard baseline.actions.allSatisfy({ $0 == .endTurn }), root.board.size == 7 else { return baseline }
        let ordered = candidates.enumerated().filter {
            $0.element.actions.contains(where: { $0 != .endTurn }) && pressure($0.element.state) > 0 &&
            $0.element.state.status == .ongoing && $0.element.state.current == me.opponent &&
            commanderSafe($0.element.state)
        }.sorted { a, b in
            let ap = pressure(a.element.state), bp = pressure(b.element.state)
            if ap != bp { return ap > bp }
            let al = commanderLiberties(a.element.state), bl = commanderLiberties(b.element.state)
            if al != bl { return al > bl }
            return a.offset < b.offset // Stable unchanged baseline ordering breaks ties.
        }
        guard let candidate = ordered.first?.element else {
            return fallback("no-soldier-pressure-hypothesis; unassessed plans remain baseline")
        }
        // Prove novelty against unchanged baseline waiting with enemy Pass. An
        // equivalent safe next-own soldier capture means this hypothesis adds no
        // demonstrated capture, even if it might save Mana.
        guard let wait = apply(root, .endTurn), let passive = apply(wait.state, .endTurn) else {
            return fallback("waiting-comparison-incomplete")
        }
        if safeCapture(passive.state) != nil { return fallback("waiting-already-has-safe-soldier-capture") }
        if incomplete { return fallback("waiting-comparison-incomplete") }
        stats.continuationComparisons.append("material-waiting-pass: no-safe-next-own-soldier-capture")
        guard let replies = turns(candidate.state) else { return fallback("complete-enemy-turn-proof-incomplete") }
        guard !replies.isEmpty else { return fallback("no-complete-enemy-turns") }
        var witnesses: [String] = []
        for reply in replies {
            guard commanderSafe(reply.state), reply.state.status == .ongoing, reply.state.current == me else {
                return fallback("\(candidate.key) rejected-by \(reply.key): commander-loss-or-no-continuation")
            }
            guard let capture = safeCapture(reply.state) else {
                return fallback(incomplete ? "next-own-capture-proof-incomplete" : "\(candidate.key) no-safe-capture-after \(reply.key)")
            }
            witnesses.append("material-proved-reply: \(reply.key) => \(capture.turn.key); soldiers=\(capture.turn.capturedSoldiers); complete-safe-counters=\(capture.counters)")
        }
        guard !cancelled(), !incomplete else { return fallback("proof-incomplete") }
        stats.continuationComparisons += witnesses
        stats.continuationComparisons.append("material-accepted: \(candidate.key); complete-enemy-turns=\(replies.count); explicit-applies=\(stats.domainTransitions); legal-enumerations=\(stats.legalEnumerations)")
        return BotTurnPlan(actions: candidate.actions,
            reasons: baseline.reasons + ["安全續攻候選：每個完整敵方回合後都有實際提兵見證，且提兵後每個完整敵方回合都保住己方主將；原版等待對敵方等待未找到同等安全提兵；不是即勝證明"],
            stats: stats, score: baseline.score)
    }
    private mutating func fallback(_ reason: String) -> BotTurnPlan? {
        guard !cancelled() else { return nil }
        stats.continuationComparisons.append("material-fallback: " + reason)
        return BotTurnPlan(actions: baseline.actions,
            reasons: baseline.reasons + ["安全續攻候選：未完成新增安全提兵證明，保留原決策（\(reason)）"],
            stats: stats, score: baseline.score)
    }
}

struct BotContinuation {
    let root: GameState
    let baseline: BotTurnPlan
    let limits: BotLimits
    let cancelled: @Sendable () -> Bool
    var stats: BotSearchStats
    let candidates: [BotTurnCandidate]
    var me: Player { root.current }
    var incomplete = false

    init(root: GameState, baseline: BotTurnPlan, limits: BotLimits, candidates: [BotTurnCandidate], cancelled: @escaping @Sendable () -> Bool) {
        self.root = root; self.baseline = baseline; self.limits = limits; self.cancelled = cancelled
        stats = baseline.stats; self.candidates = candidates
    }
    mutating func apply(_ state: GameState, _ action: GameAction) -> ActionOutcome? {
        if cancelled() { incomplete = true; return nil }
        guard stats.domainTransitions < limits.maxDomainTransitions else {
            incomplete = true; stats.budgetExhausted = true; return nil
        }
        stats.domainTransitions += 1
        let result = GameEngine.apply(state, action)
        return result.success ? result : nil
    }
    mutating func legal(_ state: GameState) -> [GameAction]? {
        guard !cancelled(), stats.domainTransitions < limits.maxDomainTransitions else {
            incomplete = true; stats.budgetExhausted = stats.domainTransitions >= limits.maxDomainTransitions; return nil
        }
        stats.legalEnumerations += 1
        return GameEngine.legalActions(state)
    }
    /// Exhaustive one/two-action turns, with early Pass kept. No board/history merging.
    private mutating func turns(_ state: GameState) -> [BotTurnCandidate]? {
        guard state.status == .ongoing, (1...2).contains(state.apRemaining) else { return [] }
        let owner = state.current
        guard let actions = legal(state) else { return nil }
        var rows: [BotTurnCandidate] = []
        for first in actions {
            guard let out = apply(state, first) else { return nil }
            if out.state.current != owner || out.state.status != .ongoing {
                rows.append(BotTurnCandidate(state: out.state, actions: [first])); continue
            }
            guard let seconds = legal(out.state) else { return nil }
            for second in seconds {
                guard let end = apply(out.state, second) else { return nil }
                guard end.state.current != owner || end.state.status != .ongoing else {
                    incomplete = true; return nil // Unsupported AP shape, never call it complete.
                }
                rows.append(BotTurnCandidate(state: end.state, actions: [first, second]))
            }
        }
        return rows
    }
    /// One witnessed next-own-turn win is enough for a particular enemy reply. Failure
    /// to find one in the remaining budget rejects the candidate, not the opponent reply.
    mutating func winningReply(_ state: GameState) -> [GameAction]? {
        if state.winner == me { return [] }
        guard state.status == .ongoing, state.current == me, let legalActions = legal(state) else { return nil }
        let commander = state.board.find(me.opponent, .commander)
        let actions = legalActions.sorted { a, b in
            func distance(_ action: GameAction) -> Int {
                guard let commander else { return 100 }
                if case .placeSoldier(let p) = action { return p.distance(to: commander) }
                return 100
            }
            let da = distance(a), db = distance(b)
            return da == db ? botActionDescription(a) < botActionDescription(b) : da < db
        }
        for first in actions {
            guard let out = apply(state, first) else { return nil }
            if out.state.winner == me { return [first] }
            if out.state.current != me || out.state.status != .ongoing { continue }
            guard let seconds = legal(out.state) else { return nil }
            for second in seconds {
                guard let end = apply(out.state, second) else { return nil }
                if end.state.winner == me { return [first, second] }
            }
        }
        return nil
    }
    private func candidateOrder(_ a: BotTurnCandidate, _ b: BotTurnCandidate) -> Bool {
        func liberties(_ state: GameState, _ owner: Player) -> Int {
            state.board.find(owner, .commander).map { state.board.liberties(at: $0).count } ?? 0
        }
        // Only orders hypotheses. This score cannot authorize a changed plan.
        let aPressure = liberties(root, me.opponent) - liberties(a.state, me.opponent)
        let bPressure = liberties(root, me.opponent) - liberties(b.state, me.opponent)
        if aPressure != bPressure { return aPressure > bPressure }
        let aSafety = liberties(a.state, me), bSafety = liberties(b.state, me)
        if aSafety != bSafety { return aSafety > bSafety }
        return a.key < b.key
    }
    mutating func run() -> BotTurnPlan? {
        guard !cancelled() else { return nil }
        guard baseline.actions.allSatisfy({ $0 == .endTurn }), root.board.size == 7 else { return baseline }
        let enemyLiberties = root.board.find(me.opponent, .commander).map { root.board.liberties(at: $0).count } ?? 0
        let candidates = candidates.filter { candidate in
            guard candidate.actions.contains(where: { $0 != .endTurn }) else { return false }
            let afterLiberties = candidate.state.board.find(me.opponent, .commander).map { candidate.state.board.liberties(at: $0).count } ?? 0
            if afterLiberties < enemyLiberties { return true }
            // Limit this experiment to direct pressure or a hero maneuver. Quiet
            // connection/preparation plans remain unassessed, not proved useless.
            // This ordering gate cannot authorize an action or declare it safe.
            return candidate.actions.contains { action in
                switch action {
                case .summonHero, .castMagicHand, .castSwap, .castFriendlyRedeploy: return true
                default: return false
                }
            }
        }.sorted(by: candidateOrder)
        if candidates.isEmpty { stats.continuationComparisons.append("no-direct-pressure-or-hero-maneuver-hypothesis; quiet-preparation-unassessed") }
        // Reuse the complete turns already validated by the unchanged baseline search.
        // Passive defence is checked first; it disproves many optimistic pressure plans.
        // At most one low-risk hypothesis in this candidate; other plans remain offline research.
        for candidate in candidates.prefix(1) {
            if candidate.state.winner == me { return accepted(candidate, witnesses: []) }
            guard candidate.state.status == .ongoing, candidate.state.board.find(me, .commander) != nil else { continue }
            guard let pass = apply(candidate.state, .endTurn) else { return fallback("敵方等待驗證未完成，保留原決策") }
            guard let passiveWin = winningReply(pass.state) else {
                if incomplete { return fallback("被動反制驗證未完成，保留原決策") }
                stats.continuationComparisons.append("\(candidate.key) no-proved-win after 0-end")
                continue
            }
            guard let enemyReplies = turns(candidate.state) else { return fallback("未完成敵方回合，保留原決策") }
            var witnesses: [String] = [], disproved = false
            for enemy in enemyReplies {
                if enemy.state.winner == me.opponent || enemy.state.status == .drawn {
                    stats.continuationComparisons.append("\(candidate.key) rejected: \(enemy.key) terminal-counter")
                    disproved = true; break
                }
                let knownPass = enemy.actions == [.endTurn] ? passiveWin : nil
                guard let win = knownPass ?? winningReply(enemy.state) else {
                    if incomplete { return fallback("下一己方回合搜尋未完成，保留原決策") }
                    stats.continuationComparisons.append("\(candidate.key) no-proved-win after \(enemy.key)")
                    disproved = true; break
                }
                witnesses.append("\(enemy.key) => \(win.map(botActionDescription).joined(separator: "/"))")
            }
            if !disproved && !enemyReplies.isEmpty { return accepted(candidate, witnesses: witnesses) }
        }
        return fallback("檢查的計畫未證明比等待更有價值；不強迫落子")
    }
    private func accepted(_ candidate: BotTurnCandidate, witnesses: [String]) -> BotTurnPlan {
        var accepted = stats
        accepted.continuationComparisons += witnesses.map { "proved-reply: " + $0 }
        return BotTurnPlan(actions: candidate.actions,
            reasons: baseline.reasons + ["候選：每個合法敵方完整回合（含等待）都存在下一己方回合的 Core 斬首見證；不是當回合已獲勝"],
            stats: accepted, score: 500_000)
    }
    func fallback(_ reason: String) -> BotTurnPlan? {
        guard !cancelled() else { return nil }
        return BotTurnPlan(actions: baseline.actions, reasons: baseline.reasons + ["多回合候選：" + reason], stats: stats, score: baseline.score)
    }
}
