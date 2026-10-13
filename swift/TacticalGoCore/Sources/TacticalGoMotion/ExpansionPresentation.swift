import TacticalGoCore

public struct CombatTransfer: Equatable, Sendable {
    public let from: Point, to: Point
    public let piece: Piece
}
/// Shared 1.1 timeline: immutable Domain receipt in, visual parameters out.
/// Full receipt comparison prevents a forged event list from authorizing a successful performance.
public struct ExpansionPresentation: Equatable, Sendable {
    public let before: GameState, after: GameState
    public let action: GameAction
    public let transfers: [CombatTransfer]
    public let placements: [Point]
    public let sacrifices: [Point]
    public let hunted: [Point]
    public let captures: [CapturedPiece]
    public let release: Double, moveStart: Double, arrival: Double, captureStart: Double, duration: Double
    public var caster: Player { before.current }
    public var hero: Point? { before.board.find(caster,.hero) }
    /// The validated result and the human perspective choose the ending, never the acting side.
    public func terminalCue(computer: Player?) -> String? {
        switch after.status {
        case .ongoing: nil
        case .drawn: "draw"
        case .won: computer != nil && after.winner == computer ? "defeat" : "victory"
        }
    }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome, current: GameState) -> Self? {
        guard outcome.success, current == outcome.state,
              GameEngine.apply(before,action) == outcome else { return nil }
        let transfers = outcome.events.flatMap { event -> [CombatTransfer] in
            switch event {
            case .piecePushed(_,let a,let b,let p): return [.init(from:a,to:b,piece:p)]
            case .piecesSwapped(_,let a,let b):
                guard let first = before.board[a],let second = before.board[b] else { return [] }
                return [.init(from:a,to:b,piece:first),.init(from:b,to:a,piece:second)]
            default: return []
            }
        }
        let placements = outcome.events.compactMap { if case .piecePlaced(_,let at,_) = $0 { return at }; return nil }
        let sacrifices = outcome.events.compactMap { if case .pieceSacrificed(_,let at) = $0 { return at }; return nil }
        let hunted = outcome.events.compactMap { if case .monsterHunted(_,let at) = $0 { return at }; return nil }
        let captures = outcome.events.flatMap { event -> [CapturedPiece] in if case .piecesCaptured(_,let pieces) = event { return pieces }; return [] }
        let timing: (Double,Double,Double,Double,Double)
        switch action {
        case .castMagicHand, .castDoublePull: timing = (0.30,0.46,0.68,0.80,1.08)
        case .castBastion, .castReformation: timing = (0.34,0.35,0.58,0.68,1.02)
        case .castSwap, .castChainSwap: timing = (0.12,0.16,0.36,0.44,0.70)
        case .castSanctuary, .castOffering: timing = (0.20,0.32,0.58,0.68,0.94)
        case .useStickyBounce: timing = (0.14,0.22,0.44,0.54,0.76)
        case .useShadowStep: timing = (0.14,0.18,0.42,0.50,0.76)
        case .huntMonster: timing = (0.14,0.20,0.44,0.54,0.76)
        case .summonHero: timing = (0.10,0.10,0.34,0.44,0.72)
        case .placeSoldier: timing = (0,0,0.15,0.22,0.40)
        case .castSeal, .castFriendlyRedeploy: timing = (0.20,0.30,0.58,0.68,0.90)
        case .endTurn: timing = (0,0,0,0,0)
        }
        return .init(before:before,after:outcome.state,action:action,transfers:transfers,placements:placements,
            sacrifices:sacrifices,hunted:hunted,captures:captures,release:timing.0,moveStart:timing.1,
            arrival:timing.2,captureStart:timing.3,duration:timing.4)
    }
    public func board(at time: Double, reduced: Bool = false) -> Board {
        reduced || !time.isFinite || time >= arrival ? after.board : before.board
    }
    public func progress(at time: Double, reduced: Bool = false) -> Double {
        guard time.isFinite else { return 1 }
        return reduced ? 1 : MotionCurves.ease((time-moveStart)/max(0.001,arrival-moveStart))
    }
    public var isHeroSkill: Bool {
        switch action {
        case .castBastion,.castMagicHand,.castSwap,.castSanctuary,.castOffering,.castDoublePull,.castReformation,.castChainSwap,.castSeal,.castFriendlyRedeploy: true
        default: false
        }
    }
}
