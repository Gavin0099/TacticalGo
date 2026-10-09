import TacticalGoCore

public struct CombatSoundCue: Equatable, Sendable {
    public let key: String
    public let start: Double
    public init(_ key: String, at start: Double) { self.key = key; self.start = start }
}

/// Presentation timing only; never changes a board or predicts a capture.
public struct CombatFeedbackPlan: Equatable, Sendable {
    public let cues: [CombatSoundCue]
    public let duration: Double
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome,
                            reducedMotion: Bool = false) -> Self {
        guard outcome.success else { return Self(cues: [], duration: 0) }
        // Audio retains its timing in Reduce Motion; the renderer uses stationary outlines.
        var cues: [CombatSoundCue] = []
        var landing = 0.0
        var capture = 0.12
        var duration = 0.38
        switch action {
        case .castMagicHand, .castFriendlyRedeploy:
            // Only an actual pushed event can authorize the mage success sound.
            if outcome.events.contains(where: { if case .piecePushed = $0 { return true }; return false }) {
                cues.append(.init("mage", at: 0)); landing = 0.56; capture = 0.62; duration = 0.9
            }
        case .castBastion:
            if outcome.events.contains(where: { if case .piecePlaced = $0 { return true }; return false }) {
                cues.append(.init("warrior", at: 0)); landing = 0.39; capture = 0.48; duration = 0.76
            }
        case .castSwap:
            if outcome.events.contains(where: { if case .piecesSwapped = $0 { return true }; return false }) {
                cues.append(.init("rogue", at: 0)); landing = 0.42; capture = 0.42; duration = 0.7
            }
        case .castSeal:
            if outcome.events.contains(where: { if case .sealPlaced = $0 { return true }; return false }) {
                cues.append(.init("mage", at: 0)); capture = 0.6; duration = 0.88
            }
        case .summonHero: landing = 0; capture = 0.46; duration = 0.74
        case .placeSoldier: landing = 0.21; capture = 0.30
        case .endTurn: duration = 0
        }
        var landed = false, captured = false
        for event in outcome.events {
            switch event {
            case .piecePlaced(_, _, let kind):
                if !landed { cues.append(.init(kind == .hero ? "summon" : "place", at: landing)); landed = true }
            case .piecePushed, .piecesSwapped:
                if !landed { cues.append(.init("place", at: landing)); landed = true }
            case .piecesCaptured(_, let pieces):
                if !captured && !pieces.isEmpty { cues.append(.init("capture", at: capture)); captured = true }
            case .gameWon:
                let start = max(0.96, capture + 0.34)
                cues.append(.init("victory", at: start)); duration = max(duration, start + 0.59)
            case .gameDrawn:
                let start = captured ? capture + 0.28 : 0
                cues.append(.init("draw", at: start)); duration = max(duration, start + 0.4)
            default: break
            }
        }
        // One warning on entry into danger, not on every preview or repeat action.
        if outcome.state.status == .ongoing {
            let enteredDanger = Player.allCases.contains { player in
                guard let old = before.board.find(player, .commander), let new = outcome.state.board.find(player, .commander) else { return false }
                return before.board.liberties(at: old).count > 1 && outcome.state.board.liberties(at: new).count == 1
            }
            if enteredDanger { cues.append(.init("danger", at: captured ? capture + 0.28 : landing + 0.12)); duration = max(duration, 0.9) }
        }
        return Self(cues: cues.sorted { $0.start < $1.start }, duration: duration)
    }
}

/// An explicit playable demonstration position using the existing game rules.
/// Not a new-game setup, balance fixture, or additional combat system.
public enum CombatDemo {
    public static let action: GameAction = .castMagicHand(Point(4, 3), .up)
    public static func initialState(size: Int = 7) throws -> GameState {
        precondition(size == 7 || size == 9)
        var rows = Array(repeating: Array(repeating: Character("."), count: size), count: size)
        rows[1][3] = "x"; rows[2][2] = "x"; rows[2][3] = "O"
        rows[3][3] = "H"; rows[3][4] = "x"; rows[size - 2][3] = "X"
        return try GameSetup.fromDiagram(config: .board(size: size), diagram: rows.map { String($0) }.joined(separator: "\n"),
            classOne: .mage, classTwo: .warrior, manaOne: 4, manaTwo: 4, ap: 2)
    }
}
