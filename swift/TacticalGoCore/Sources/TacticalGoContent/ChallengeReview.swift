import TacticalGoCore
import TacticalGoRecords

/// Descriptive review from accepted receipts. It never asserts optimality or player intent.
public struct ChallengeReview: Equatable, Sendable {
    public let playerActions: Int
    public let manaSpent: Int
    public let captured: Int
    public let commanderLiberties: Int
    public let heroLiberties: Int
    public let timeline: [String]

    public init(session: TutorialSession) throws {
        var state = try TutorialReplay.start(session.scenario)
        var spent = 0, taken = 0, lines: [String] = []
        for (index, action) in session.actions.enumerated() {
            let outcome = GameEngine.apply(state, action)
            guard outcome.success else { throw ChallengeError.corrupt }
            var ap = 0, mana = 0, captures = 0
            for event in outcome.events {
                if case .resourcesSpent(_, let a, let m) = event { ap += a; mana += m }
                if case .piecesCaptured(_, let pieces) = event { captures += pieces.count }
            }
            if state.current == .one { spent += mana; taken += captures }
            lines.append("\(index + 1). \(state.current == .one ? "黑" : "白")：\(RecordedAction(action).label) · \(ap) AP／\(mana) 能量／提 \(captures) 子")
            state = outcome.state
        }
        playerActions = session.playerActionCount; manaSpent = spent; captured = taken
        commanderLiberties = state.board.find(.one, .commander).map { state.board.liberties(at: $0).count } ?? 0
        heroLiberties = state.board.find(.one, .hero).map { state.board.liberties(at: $0).count } ?? 0
        timeline = lines
    }
    public var summary: String {
        "本次 \(playerActions) 次行動、消耗 \(manaSpent) 能量、提 \(captured) 子；結束時主將 \(commanderLiberties) 氣、英雄 \(heroLiberties) 氣。氣數不是生命值，也不保證安全。"
    }
}
