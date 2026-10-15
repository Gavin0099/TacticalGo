import TacticalGoCore

/// Strategy depth, not a change to game rules or resources.
public enum BotDifficulty: String, Sendable, CaseIterable {
    case easy, standard
}

/// Work limits are deterministic, rather than elapsed-time cutoffs. This keeps replay choices stable.
public struct BotLimits: Sendable {
    /// Caps explicit apply calls; Core.legalActions also performs bounded internal validation.
    public let maxDomainTransitions: Int
    public let ownBeamWidth: Int
    public let replyBeamWidth: Int
    public let replyCandidates: Int
    public init(maxDomainTransitions: Int = 6_000, ownBeamWidth: Int = 10,
                replyBeamWidth: Int = 3, replyCandidates: Int = 8) {
        self.maxDomainTransitions = max(1, maxDomainTransitions)
        self.ownBeamWidth = max(1, min(32, ownBeamWidth))
        self.replyBeamWidth = max(1, min(8, replyBeamWidth))
        self.replyCandidates = max(1, min(32, replyCandidates))
    }
    public static let standard = BotLimits()
    public static let easy = BotLimits(maxDomainTransitions: 1_600, ownBeamWidth: 4,
                                       replyBeamWidth: 1, replyCandidates: 4)
}
/// Optional, observational search trace. Rank is within the stated stage/context only.
public struct BotCandidateTrace: Codable, Equatable, Sendable {
    public let stage: String
    public let context: String
    public let rank: Int?
    public let actionKey: String
    public let score: Int?
    public let retained: Bool
    public let reason: String
}
public struct BotSearchStats: Sendable {
    public internal(set) var candidateTrace: [BotCandidateTrace] = []
    public internal(set) var traceTruncated = false
    public internal(set) var difficulty: BotDifficulty = .standard
    /// Whether this strategy includes bounded opponent-turn search; not a claim every reply completed.
    public internal(set) var searchesOpponentTurn = true
    public internal(set) var domainTransitions = 0
    public internal(set) var legalEnumerations = 0
    public internal(set) var turnCandidates = 0
    public internal(set) var replyCandidates = 0
    public internal(set) var budgetExhausted = false
    /// Standard reports only fully evaluated replies; easy reports own-turn scores without replies.
    public internal(set) var candidateComparisons: [String] = []
    /// All evaluated legal first actions, including pass; bounded by the explicit transition budget.
    public internal(set) var rootActionComparisons: [String] = []
    /// Retained complete own turns before opponent-response pruning.
    public internal(set) var ownTurnComparisons: [String] = []
    /// Why passing won the bounded comparison, with actual retained-candidate values.
    public internal(set) var passDiagnostics: [String] = []
}
public struct BotTurnPlan: Sendable {
    /// Stops exactly at victory, draw, or the handover to the opponent.
    public let actions: [GameAction]
    public let reasons: [String]
    public let stats: BotSearchStats
    public let score: Int
}
public enum BotPlanner {
    public static func planTurn(_ state: GameState, limits: BotLimits = .standard,
                                difficulty: BotDifficulty = .standard, diagnostics: Bool = false,
                                cancelled: @Sendable () -> Bool = { false }) -> BotTurnPlan? {
        guard state.status == .ongoing, !cancelled() else { return nil }
        let effectiveLimits = difficulty == .easy
            ? BotLimits(maxDomainTransitions: min(limits.maxDomainTransitions, BotLimits.easy.maxDomainTransitions),
                        ownBeamWidth: min(limits.ownBeamWidth, BotLimits.easy.ownBeamWidth),
                        replyBeamWidth: 1, replyCandidates: 4)
            : limits
        return withoutActuallyEscaping(cancelled) { callback in
            var search = Search(root: state, limits: effectiveLimits, difficulty: difficulty, diagnostics: diagnostics, cancelled: callback)
            return search.run()
        }
    }
}

private struct Node {
    let state: GameState
    let actions: [GameAction]
    let score: Int
    var key: String { actions.map(actionKey).joined(separator: "/") }
}
private struct Search {
    let root: GameState
    let limits: BotLimits
    let difficulty: BotDifficulty
    let diagnostics: Bool
    let cancelled: @Sendable () -> Bool
    var stats = BotSearchStats()
    var interrupted = false
    var me: Player { root.current }
    let win = 1_000_000

    mutating func apply(_ state: GameState, _ action: GameAction) -> ActionOutcome? {
        if cancelled() { interrupted = true; return nil }
        guard stats.domainTransitions < limits.maxDomainTransitions else {
            stats.budgetExhausted = true; return nil
        }
        stats.domainTransitions += 1
        let result = GameEngine.apply(state, action)
        return result.success ? result : nil
    }
    mutating func ranked(_ state: GameState, perspective: Player, stage: String, context: String) -> [Node] {
        if cancelled() { interrupted = true; return [] }
        guard stats.domainTransitions < limits.maxDomainTransitions else { stats.budgetExhausted = true; return [] }
        // Core is the sole source of move legality, including suicide, ko, resources and skill gates.
        stats.legalEnumerations += 1
        let legal = GameEngine.legalActions(state)
        var nodes: [Node] = []
        for (index, action) in legal.enumerated() {
            guard let result = apply(state, action) else {
                if diagnostics {
                    for pending in legal[index...] {
                        if stats.candidateTrace.count >= 50_000 { stats.traceTruncated = true; break }
                        stats.candidateTrace.append(BotCandidateTrace(stage: stage, context: context, rank: nil,
                            actionKey: actionKey(pending), score: nil, retained: false,
                            reason: interrupted ? "cancelled-before-evaluation" : "transition-budget-before-evaluation"))
                    }
                }
                break
            }
            nodes.append(Node(state: result.state, actions: [action], score: evaluate(result.state, for: perspective)))
        }
        return nodes.sorted(by: better)
    }
    mutating func trace(_ nodes: [Node], retained: [Node], stage: String, context: String,
                        kept: String, dropped: String) {
        guard diagnostics else { return }
        let keys = Set(retained.map(\.key))
        for (index, node) in nodes.enumerated() {
            guard stats.candidateTrace.count < 50_000 else { stats.traceTruncated = true; return }
            let included = keys.contains(node.key)
            stats.candidateTrace.append(BotCandidateTrace(stage: stage, context: context, rank: index + 1,
                actionKey: node.key, score: node.score, retained: included, reason: included ? kept : dropped))
        }
    }
    func better(_ a: Node, _ b: Node) -> Bool {
        a.score == b.score ? a.key < b.key : a.score > b.score
    }
    func terminal(_ state: GameState, player: Player) -> Bool {
        state.status != .ongoing || state.current != player
    }
    mutating func finish(_ node: Node, player: Player) -> Node? {
        if terminal(node.state, player: player) { return node }
        guard let result = apply(node.state, .endTurn) else { return nil }
        return Node(state: result.state, actions: node.actions + [.endTurn], score: evaluate(result.state, for: player))
    }
    func beam(_ nodes: [Node], width: Int) -> [Node] {
        // Preserve a useful summon/skill option as well as ordinary moves when short-term scores tie.
        // This is candidate diversity, not a rule: all nodes were already accepted by Core.
        var result = Array(nodes.prefix(width))
        let predicates: [@Sendable (GameAction) -> Bool] = [isSummon, isSkill]
        for predicate in predicates {
            if !result.contains(where: { $0.actions.contains(where: predicate) }),
               let node = nodes.first(where: { $0.actions.contains(where: predicate) }) {
                if result.count >= width { result.removeLast() }
                result.append(node)
            }
        }
        return result.sorted(by: better)
    }
    mutating func run() -> BotTurnPlan? {
        stats.difficulty = difficulty
        stats.searchesOpponentTurn = difficulty == .standard
        // Reserve a verified fallback inside the transition budget, including a one-node budget.
        guard let fallback = apply(root, .endTurn) else { return nil }
        let first = ranked(root, perspective: me, stage: "own-first", context: "root")
        stats.rootActionComparisons = first.map { "\($0.key) own=\($0.score)" }
        if interrupted { return nil }
        // Direct victories always outrank heuristic scores and candidate pruning.
        if let won = first.first(where: { $0.state.winner == me }) {
            trace(first, retained: [won], stage: "own-first", context: "root", kept: "direct-victory", dropped: "not-expanded-after-direct-victory")
            return plan(won, worstReply: nil)
        }
        var completed: [Node] = []
        var ownFirst = beam(first, width: limits.ownBeamWidth)
        // Do not let the ordinary beam discard a cut/first placement that leaves a one-liberty
        // enemy commander. Examine its entire second-action list before heuristic reply search.
        for node in first {
            if let commander = node.state.board.find(me.opponent, .commander),
               node.state.board.liberties(at: commander).count == 1,
               !ownFirst.contains(where: { $0.actions == node.actions }) { ownFirst.append(node) }
        }
        ownFirst.sort(by: better)
        trace(first, retained: ownFirst, stage: "own-first", context: "root",
              kept: "beam-or-summon-skill-diversity-or-commander-threat", dropped: "outside-first-beam")
        for node in ownFirst {
            if terminal(node.state, player: me) { completed.append(node); continue }
            let seconds = ranked(node.state, perspective: me, stage: "own-second", context: node.key)
            if interrupted { return nil }
            if let won = seconds.first(where: { $0.state.winner == me }) {
                trace(seconds, retained: [won], stage: "own-second", context: node.key, kept: "direct-victory", dropped: "not-expanded-after-direct-victory")
                return plan(Node(state: won.state, actions: node.actions + won.actions, score: win), worstReply: nil)
            }
            trace(seconds, retained: Array(seconds.prefix(limits.ownBeamWidth)), stage: "own-second", context: node.key,
                  kept: "within-second-beam", dropped: "outside-second-beam")
            for second in seconds.prefix(limits.ownBeamWidth) {
                let combined = Node(state: second.state, actions: node.actions + second.actions, score: second.score)
                if let finished = finish(combined, player: me) { completed.append(finished) }
            }
        }
        if interrupted { return nil }
        if completed.isEmpty {
            // A tiny budget still needs a legal complete turn, never a partial plan with stale ownership.
            guard !cancelled() else { return nil }
            return BotTurnPlan(actions: [.endTurn], reasons: ["搜尋預算不足，合法結束回合"] + difficultyReasons,
                               stats: stats, score: evaluate(fallback.state, for: me))
        }
        // At full Mana, a pure pass gains no resource. A modest initiative preference
        // breaks otherwise near-equal dense-board stalemates, never overriding wins/losses.
        if root.mana(of: me) == root.config.manaCap {
            completed = completed.map { node in
                node.actions.allSatisfy({ $0 == .endTurn }) && node.state.status == .ongoing
                    ? Node(state: node.state, actions: node.actions, score: node.score - 60) : node
            }
        }
        // Different move orders can lead to the same board/resources; keep a stable representative.
        // History is deliberately not merged: superko can distinguish otherwise identical states.
        completed.sort(by: better)
        stats.turnCandidates = completed.count
        stats.ownTurnComparisons = completed.map { "\($0.key) own=\($0.score)" }
        if let pass = completed.first(where: { $0.actions.allSatisfy { $0 == .endTurn } }) {
            let nonPass = completed.first(where: { $0.actions.contains { $0 != .endTurn } })
            stats.passDiagnostics = ["已評估非pass首手 \(first.filter { $0.actions.contains { $0 != .endTurn } }.count)，完整己方候選 \(completed.count)",
                "pass己方分數 \(pass.score)，最佳非pass己方分數 \(nonPass.map { String($0.score) } ?? "無已完成候選")；反擊分數另列"]
        }
        trace(completed, retained: Array(completed.prefix(difficulty == .easy ? completed.count : limits.replyCandidates)),
              stage: "complete-turn", context: "root", kept: difficulty == .easy ? "own-only-difficulty" : "selected-for-reply-search",
              dropped: "outside-complete-turn-reply-cap")
        if difficulty == .easy {
            guard !cancelled() else { return nil }
            stats.candidateComparisons = completed.prefix(limits.ownBeamWidth).map { "\($0.key) own=\($0.score)" }
            let best = completed[0]
            // Keep basic tactical wins/rescues, but do not always choose the most precise
            // pressure among close own-turn candidates. Deterministic, same legal rules.
            let alternatives = completed.dropFirst().filter { node in
                node.actions != best.actions && node.score >= best.score - 120 &&
                node.actions.contains(where: { $0 != .endTurn }) &&
                node.state.board.find(me, .commander).map { node.state.board.liberties(at: $0).count >= 3 } == true &&
                (root.board.find(me, .hero) == nil || node.state.board.find(me, .hero) != nil)
            }
            if let relaxed = alternatives.first {
                stats.candidateComparisons.append("easy-relaxed gap=\(best.score - relaxed.score), max=120")
                return plan(relaxed, worstReply: nil)
            }
            return plan(best, worstReply: nil)
        }
        var best: Node?
        var bestValue = Int.min
        var bestReply: Int?
        var compared: [Node] = []
        for node in completed.prefix(limits.replyCandidates) {
            guard let reply = worstReply(after: node.state, context: node.key) else {
                if interrupted { return nil }; break
            }
            if interrupted { return nil }
            // An opponent win dominates all material or resource preferences.
            let value = reply <= -win ? -win : (node.score * 2 + reply) / 3
            stats.candidateComparisons.append("\(node.key) own=\(node.score) reply=\(reply) combined=\(value)")
            if diagnostics { compared.append(Node(state: node.state, actions: node.actions, score: value)) }
            if value > bestValue || (value == bestValue && (best == nil || node.key < best!.key)) {
                best = node; bestValue = value; bestReply = reply
            }
        }
        guard !cancelled() else { return nil }
        guard let best else {
            return plan(completed[0], worstReply: nil)
        }
        trace(compared.sorted(by: better), retained: [best], stage: "reply-comparison", context: "root",
              kept: "selected-after-fully-evaluated-reply", dropped: "lower-combined-score-or-tie-break")
        return plan(Node(state: best.state, actions: best.actions, score: bestValue), worstReply: bestReply)
    }
    mutating func worstReply(after state: GameState, context: String) -> Int? {
        if state.status != .ongoing { return evaluate(state, for: me) }
        let enemy = me.opponent
        let first = ranked(state, perspective: enemy, stage: "reply-first", context: context)
        if let won = first.first(where: { $0.state.winner == enemy }) {
            trace(first, retained: [won], stage: "reply-first", context: context, kept: "opponent-direct-victory", dropped: "not-expanded-after-opponent-victory")
            return -win
        }
        if stats.budgetExhausted || interrupted { return nil }
        var worst = evaluate(state, for: me)
        let replyFirst = beam(first, width: limits.replyBeamWidth)
        trace(first, retained: replyFirst, stage: "reply-first", context: context, kept: "reply-beam-or-diversity", dropped: "outside-reply-first-beam")
        for node in replyFirst {
            if terminal(node.state, player: enemy) { worst = min(worst, evaluate(node.state, for: me)); continue }
            let seconds = ranked(node.state, perspective: enemy, stage: "reply-second", context: context + " | " + node.key)
            if let won = seconds.first(where: { $0.state.winner == enemy }) {
                trace(seconds, retained: [won], stage: "reply-second", context: context + " | " + node.key,
                      kept: "opponent-direct-victory", dropped: "not-expanded-after-opponent-victory")
                return -win
            }
            if stats.budgetExhausted || interrupted { return nil }
            trace(seconds, retained: Array(seconds.prefix(limits.replyBeamWidth)), stage: "reply-second", context: context + " | " + node.key,
                  kept: "within-reply-second-beam", dropped: "outside-reply-second-beam")
            for second in seconds.prefix(limits.replyBeamWidth) {
                stats.replyCandidates += 1
                worst = min(worst, evaluate(second.state, for: me))
                if second.state.winner == enemy { return -win }
            }
        }
        return worst
    }
    func evaluate(_ state: GameState, for player: Player) -> Int {
        if state.status == .won { return state.winner == player ? win : -win }
        if state.status == .drawn { return 0 }
        func faction(_ owner: Player) -> Int {
            var score = state.mana(of: owner) * 7
            var seen: Set<Point> = []
            for p in state.board.points {
                guard let piece = state.board[p], piece.owner == owner else { continue }
                score += piece.kind == .soldier ? 30 : piece.kind == .hero ? 160 : 0
                if piece.kind == .soldier, let enemyCommander = state.board.find(owner.opponent, .commander) {
                    score += max(0, 9 - p.distance(to: enemyCommander)) * 3
                }
                if seen.contains(p) { continue }
                let group = state.board.group(at: p)
                seen.formUnion(group)
                let libertyPoints = state.board.liberties(at: p)
                let liberties = libertyPoints.count
                let hasCommander = group.contains { state.board[$0]?.kind == .commander }
                let hasHero = group.contains { state.board[$0]?.kind == .hero }
                if hasCommander {
                    score += min(liberties, 6) * 75
                    // Beyond six liberties, the old flat score made closing the group's
                    // remaining frontier appear free. Keep a modest diminishing buffer.
                    score += min(max(0, liberties - 6), 6) * 20
                    if liberties == 1 { score -= owner == player ? 20_000 : 4_000 }
                    if liberties == 2 {
                        // Geometry only: two locally surrounded spaces differ from an
                        // exposed frontier. This does not declare a group alive or decide
                        // move legality; direct captures and replies still come from Core.
                        let sheltered = libertyPoints.allSatisfy { liberty in
                            state.board.neighbors(of: liberty).allSatisfy { state.board[$0]?.owner == owner }
                        }
                        if !sheltered { score -= owner == player ? 5_000 : 900 }
                    }
                } else {
                    score += min(liberties, 4) * 9
                    if liberties == 1 { score -= (hasHero ? 230 : 45) + group.count * 25 }
                    if liberties == 2 && hasHero { score -= 75 }
                }
            }
            if let hero = state.board.find(owner, .hero) {
                let ownCommander = state.board.find(owner, .commander)
                let enemyCommander = state.board.find(owner.opponent, .commander)
                // Hero presence matters when it can participate in a front or cover the commander.
                if let enemyCommander { score += max(0, 7 - hero.distance(to: enemyCommander)) * 14 }
                if let ownCommander { score += max(0, 4 - hero.distance(to: ownCommander)) * 5 }
                // Local open space is a positioning heuristic, not a skill-legality test.
                // The original fixed-position heroes lose participation when allies seal
                // every adjacent point; preserve room before the dense position locks.
                score += min(state.board.neighbors(of: hero).filter { state.board[$0] == nil }.count, 3) * 32
            }
            return score
        }
        return faction(player) - faction(player.opponent)
    }
    func plan(_ node: Node, worstReply: Int?) -> BotTurnPlan {
        var reasons = difficultyReasons
        if node.state.winner == me { reasons.append("本回合提吃敵方主將") }
        if let commander = root.board.find(me, .commander), root.board.liberties(at: commander).count <= 2,
           let after = node.state.board.find(me, .commander) {
            reasons.append("主將生存空格 \(root.board.liberties(at: commander).count) → \(node.state.board.liberties(at: after).count)")
        }
        if node.actions.contains(where: isSummon) { reasons.append("召喚英雄支援攻守位置") }
        if node.actions.contains(where: isSkill) { reasons.append("使用職業技能重組棋形") }
        let enemyBefore = root.board.points.filter { root.board[$0]?.owner == me.opponent }.count
        let enemyAfter = node.state.board.points.filter { node.state.board[$0]?.owner == me.opponent }.count
        if enemyAfter < enemyBefore { reasons.append("提掉敵方棋子 \(enemyBefore - enemyAfter) 枚") }
        if let before = root.board.find(me.opponent, .commander), let after = node.state.board.find(me.opponent, .commander),
           root.board.liberties(at: before).count != node.state.board.liberties(at: after).count {
            reasons.append("敵主將生存空格 \(root.board.liberties(at: before).count) → \(node.state.board.liberties(at: after).count)")
        }
        if root.mana(of: me) != node.state.mana(of: me) {
            reasons.append("Mana \(root.mana(of: me)) → \(node.state.mana(of: me))")
        }
        reasons.append("完整回合 \(node.actions.filter { $0 != .endTurn }.count) 次行動；攻守分數 \(node.score)")
        if let worstReply { reasons.append("有限對手反應分數 \(worstReply)") }
        if stats.candidateComparisons.contains(where: { $0.hasPrefix("easy-relaxed") }) {
            reasons.append("簡單：選擇接近最佳的合法候選，減少精準施壓；不保證玩家獲勝")
        }
        if node.actions.allSatisfy({ $0 == .endTurn }), root.mana(of: me) == root.config.manaCap {
            reasons.append("能量已滿，有限候選比較後仍選擇結束回合")
        }
        if node.actions.allSatisfy({ $0 == .endTurn }) {
            reasons.append(contentsOf: stats.passDiagnostics)
        }
        if stats.budgetExhausted {
            if difficulty == .easy { reasons.append("已達簡單搜尋預算，採用已驗證合法的完整己方回合") }
            else { reasons.append(worstReply == nil && node.state.winner != me ? "已達搜尋預算；此候選合法，但對手反應未完成驗證" : "已達搜尋預算，使用已完成對手反應比較的候選") }
        }
        return BotTurnPlan(actions: node.actions, reasons: reasons, stats: stats, score: node.score)
    }
    var difficultyReasons: [String] {
        difficulty == .easy ? ["簡單：有限己方回合搜尋，不搜尋對手完整回合反擊"] : []
    }
}
private func isSummon(_ action: GameAction) -> Bool {
    if case .summonHero = action { return true }; return false
}
private func isSkill(_ action: GameAction) -> Bool {
    switch action {
    case .castBastion, .castMagicHand, .castFriendlyRedeploy, .castSwap, .castSeal: true
    default: false
    }
}
/// Stable keys are also used by the offline match recorder; no randomized hash iteration affects choice.
public func botActionDescription(_ action: GameAction) -> String { actionKey(action) }
private func actionKey(_ action: GameAction) -> String {
    func p(_ point: Point) -> String { "\(point.y),\(point.x)" }
    switch action {
    case .placeSoldier(let point): return "1-place:\(p(point))"
    case .summonHero(let point): return "2-summon:\(p(point))"
    case .castBastion(let a, let b): return "3-bastion:\(p(a)): \(p(b))"
    case .castMagicHand(let point, let direction): return "4-push:\(p(point)):\(direction.rawValue)"
    case .castFriendlyRedeploy(let source, let destination): return "7-redeploy:\(p(source)):\(p(destination))"
    case .castSwap(let point): return "5-swap:\(p(point))"
    case .castSeal(let point): return "6-seal:\(p(point))"
    case .endTurn: return "9-end"
    }
}
