import TacticalGoCore

/// TENSION-01 (observation only): does a position offer more than one defensible complete turn?
///
/// Candidate turns are the planner's own retained turns (a bounded set, not every legal turn). Two facts about each
/// are exact, taken from Core and independent of the planner's heuristic: whether it captures the enemy commander, and
/// whether the opponent has any complete reply that captures ours. "Close" alternatives are judged by the planner's own
/// own-turn score, so that part is bot-relative. Nothing here changes rules, bot choices or save formats.
public struct TensionTurn: Sendable {
    public enum Kind: String, Sendable { case win, capture, skill, summon, build, pass }
    public let actions: [GameAction]
    public let kind: Kind
    public let ownScore: Int
    public let capturedSoldiers: Int
    public let opponentCanWin: Bool
    public let opponentMaxCapture: Int
    public let ownCommanderLiberties: Int
    public let enemyCommanderLiberties: Int
    public let manaSpent: Int
    public var key: String { actions.map(botActionDescription).joined(separator: "/") }
    /// Outcome shape, not location: two turns with the same signature are the same plan for this purpose.
    public var signature: String {
        "\(kind.rawValue)|cap\(capturedSoldiers)|enemyLib\(min(enemyCommanderLiberties, 4))|ownLib\(min(ownCommanderLiberties, 4))|risk\(min(opponentMaxCapture, 3))"
    }
}

public struct TensionPosition: Sendable {
    public let candidates: [TensionTurn]
    public let closeGap: Int
    /// Candidates considered (retained by the planner), before exact checks.
    public var candidateCount: Int { candidates.count }
    public var hasWinningTurn: Bool { candidates.contains { $0.kind == .win } }
    public var safe: [TensionTurn] { candidates.filter { !$0.opponentCanWin } }
    public var bestSafeScore: Int? { safe.map(\.ownScore).max() }
    /// Safe, non-pass turns within `closeGap` of the best safe score, one per distinct outcome signature.
    public var closeDistinct: [TensionTurn] {
        guard let best = bestSafeScore else { return [] }
        var seen: Set<String> = [], rows: [TensionTurn] = []
        for turn in safe.sorted(by: { $0.ownScore > $1.ownScore }) where turn.ownScore >= best - closeGap {
            if turn.kind == .pass && safe.contains(where: { $0.kind != .pass && $0.ownScore >= best - closeGap }) { continue }
            if seen.insert(turn.signature).inserted { rows.append(turn) }
        }
        return rows
    }
    public enum Verdict: String, Sendable {
        /// A complete turn captures the enemy commander.
        case winningTurn
        /// Every retained turn loses to some reply, or exactly one does not: the choice is forced.
        case forcedDefense
        /// One plan stands out, or all close turns share one outcome shape.
        case obvious
        /// At least two safe, close turns with different outcome shapes.
        case twoPlans
    }
    public var verdict: Verdict {
        if hasWinningTurn { return .winningTurn }
        if safe.count <= 1 { return .forcedDefense }
        return closeDistinct.count >= 2 ? .twoPlans : .obvious
    }
}

public enum TensionProbe {
    public static func analyze(_ state: GameState, limits: BotLimits = .standard, maxCandidates: Int = 16,
                               closeGap: Int = 120) -> TensionPosition? {
        guard state.status == .ongoing else { return nil }
        let me = state.current
        var seen: Set<String> = [], turns: [TensionTurn] = []
        for candidate in BotPlanner.candidateTurns(state, limits: limits).sorted(by: { $0.ownScore > $1.ownScore }) {
            // Different move orders to the same board and resources are one candidate.
            let identity = candidate.state.board.diagram + "|\(candidate.state.mana(of: me))|\(candidate.state.current.rawValue)|\(candidate.state.status.rawValue)"
            guard seen.insert(identity).inserted else { continue }
            guard let turn = describe(state, candidate) else { continue }
            turns.append(turn)
            if turns.count >= maxCandidates { break }
        }
        return turns.isEmpty ? nil : TensionPosition(candidates: turns, closeGap: closeGap)
    }

    public static func describePublic(_ root: GameState, _ candidate: BotCandidateTurn) -> TensionTurn? { describe(root, candidate) }
    static func describe(_ root: GameState, _ candidate: BotCandidateTurn) -> TensionTurn? {
        let me = root.current
        var state = root, captured = 0, usesSkill = false, summons = false
        for action in candidate.actions where action != .endTurn {
            let result = GameEngine.apply(state, action)
            guard result.success else { return nil }
            captured += soldiersCaptured(result, by: me)
            switch action {
            case .placeSoldier, .endTurn, .huntMonster: break
            case .summonHero: summons = true
            default: usesSkill = true
            }
            state = result.state
        }
        let after = candidate.state
        let wins = after.winner == me
        let reply = wins ? (canWin: false, maxCapture: 0) : opponentReply(after)
        let kind: TensionTurn.Kind = wins ? .win : captured > 0 ? .capture : usesSkill ? .skill : summons ? .summon
            : candidate.actions.allSatisfy({ $0 == .endTurn }) ? .pass : .build
        return TensionTurn(
            actions: candidate.actions, kind: kind, ownScore: candidate.ownScore, capturedSoldiers: captured,
            opponentCanWin: reply.canWin, opponentMaxCapture: reply.maxCapture,
            ownCommanderLiberties: after.board.find(me, .commander).map { after.board.liberties(at: $0).count } ?? 0,
            enemyCommanderLiberties: after.board.find(me.opponent, .commander).map { after.board.liberties(at: $0).count } ?? 0,
            manaSpent: max(0, root.mana(of: me) - after.mana(of: me)))
    }

    public static func soldiersCapturedCount(_ outcome: ActionOutcome, by player: Player) -> Int { soldiersCaptured(outcome, by: player) }
    static func soldiersCaptured(_ outcome: ActionOutcome, by player: Player) -> Int {
        outcome.events.reduce(0) { count, event in
            guard case .piecesCaptured(let owner, let pieces) = event, owner == player else { return count }
            return count + pieces.filter { $0.piece == Piece(player.opponent, .soldier) }.count
        }
    }

    /// Exact over every legal complete reply (first action, then second action; ending early is the same position as
    /// the first action alone). Bounded only by Core's own expansion candidate limit, as in the planner.
    /// Exact check for a position where the opponent is to move: can any complete reply capture the commander?
    public static func opponentCanCaptureCommander(_ state: GameState) -> Bool { opponentReply(state).canWin }
    /// Every complete own turn (first action, then second action; a one-action turn that ends the turn counts once),
    /// de-duplicated by resulting board, resources and side to move. No beam, no heuristic.
    public static func allCompleteTurns(_ root: GameState, expansionCandidateLimit: Int = 256) -> [(actions: [GameAction], state: GameState)] {
        guard root.status == .ongoing else { return [] }
        let owner = root.current
        var seen: Set<String> = [], turns: [(actions: [GameAction], state: GameState)] = []
        func add(_ actions: [GameAction], _ state: GameState) {
            let id = state.board.diagram + "|\(state.mana(of: owner))|\(state.current.rawValue)|\(state.status.rawValue)"
            if seen.insert(id).inserted { turns.append((actions, state)) }
        }
        for first in GameEngine.legalActions(root, expansionCandidateLimit: expansionCandidateLimit) {
            let one = GameEngine.apply(root, first)
            guard one.success else { continue }
            if one.state.current != owner || one.state.status != .ongoing { add([first], one.state); continue }
            add([first, .endTurn], GameEngine.apply(one.state, .endTurn).state)
            for second in GameEngine.legalActions(one.state, expansionCandidateLimit: expansionCandidateLimit) {
                let two = GameEngine.apply(one.state, second)
                guard two.success else { continue }
                add([first, second], two.state)
            }
        }
        return turns
    }
    static func opponentReply(_ state: GameState) -> (canWin: Bool, maxCapture: Int) {
        guard state.status == .ongoing else { return (state.winner == state.current.opponent, 0) }
        let owner = state.current
        var best = 0
        for first in GameEngine.legalActions(state, expansionCandidateLimit: 256) {
            let one = GameEngine.apply(state, first)
            guard one.success else { continue }
            if one.state.winner == owner { return (true, best) }
            let firstCaptured = soldiersCaptured(one, by: owner)
            best = max(best, firstCaptured)
            guard one.state.status == .ongoing, one.state.current == owner else { continue }
            for second in GameEngine.legalActions(one.state, expansionCandidateLimit: 256) {
                let two = GameEngine.apply(one.state, second)
                guard two.success else { continue }
                if two.state.winner == owner { return (true, best) }
                best = max(best, firstCaptured + soldiersCaptured(two, by: owner))
            }
        }
        return (false, best)
    }
}
