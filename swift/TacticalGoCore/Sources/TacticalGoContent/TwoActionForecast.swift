import TacticalGoCore

/// Read-only counterfactual for up to two of the current player's actions.
///
/// A forecast never owns a GameSession and cannot write a match record. Each
/// intermediate state includes the original Core history and superko context.
public struct TwoActionForecast: Sendable {
    public let origin: GameState
    public private(set) var first: GameAction?
    public private(set) var second: GameAction?

    public init(origin: GameState) { self.origin = origin }

    public struct Step: Equatable, Sendable {
        public let action: GameAction
        public let before: GameState
        public let result: ActionOutcome

        public var after: GameState { result.state }
        public var actor: Player { before.current }
        public var manaBefore: Int { before.mana(of: actor) }
        public var manaAfter: Int { after.mana(of: actor) }
        public var apBefore: Int { before.apRemaining }
        /// When the action ends the turn, the next player's AP is not this player's balance.
        public var apAfter: Int? { after.current == actor && after.status == .ongoing ? after.apRemaining : nil }
        public var enemySoldiersCaptured: Int {
            result.events.reduce(0) { n, e in
                guard case .piecesCaptured(let capturer, let pieces) = e, capturer == actor else { return n }
                return n + pieces.filter { $0.piece == Piece(actor.opponent, .soldier) }.count
            }
        }
        public var ownSoldiersSacrificed: Int {
            result.events.reduce(0) { n, e in
                if case .pieceSacrificed(let owner, _) = e, owner == actor { return n + 1 }
                return n
            }
        }
        public var myCommanderLibertiesBefore: Int {
            before.board.find(actor, .commander).map { before.board.liberties(at: $0).count } ?? 0
        }
        public var myCommanderLibertiesAfter: Int {
            after.board.find(actor, .commander).map { after.board.liberties(at: $0).count } ?? 0
        }
        public var enemyCommanderLibertiesBefore: Int {
            before.board.find(actor.opponent, .commander).map { before.board.liberties(at: $0).count } ?? 0
        }
        public var enemyCommanderLibertiesAfter: Int {
            after.board.find(actor.opponent, .commander).map { after.board.liberties(at: $0).count } ?? 0
        }
    }

    /// Only successful Core outcomes are exposed as preview steps.
    public var firstStep: Step? {
        guard let first else { return nil }
        let result = GameEngine.apply(origin, first)
        return result.success ? Step(action: first, before: origin, result: result) : nil
    }

    public var secondBase: GameState? {
        guard let firstStep, firstStep.after.status == .ongoing,
              firstStep.after.current == origin.current,
              firstStep.after.apRemaining > 0 else { return nil }
        return firstStep.after
    }

    public var secondStep: Step? {
        guard let secondBase, let second else { return nil }
        let result = GameEngine.apply(secondBase, second)
        return result.success ? Step(action: second, before: secondBase, result: result) : nil
    }

    public var projectedState: GameState { secondStep?.after ?? firstStep?.after ?? origin }
    public var hasTwoActions: Bool { secondStep != nil }
    public var confirmedSteps: [Step] { [firstStep, secondStep].compactMap { $0 } }

    /// Invalid first actions leave the complete draft unchanged. Changing the
    /// first action never silently keeps a now-illegal second action.
    @discardableResult
    public mutating func chooseFirst(_ action: GameAction?) -> Bool {
        guard let action else { first = nil; second = nil; return true }
        let result = GameEngine.apply(origin, action)
        guard result.success else { return false }
        let previousSecond = second
        first = action
        second = nil
        if let previousSecond, let base = secondBase,
           GameEngine.apply(base, previousSecond).success {
            second = previousSecond
        }
        return true
    }

    @discardableResult
    public mutating func chooseSecond(_ action: GameAction?) -> Bool {
        guard let action else { second = nil; return true }
        guard let base = secondBase,
              GameEngine.apply(base, action).success else { return false }
        second = action
        return true
    }

    /// The trial is based on one exact match position, not a regenerated board.
    /// After the live match changes, discard this draft and start a new one.
    public func matches(_ live: GameState) -> Bool { live == origin }
}
