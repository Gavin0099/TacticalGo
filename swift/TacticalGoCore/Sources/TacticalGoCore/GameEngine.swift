public enum GameSetup {
    public static func newGame(config: RuleConfig = RuleConfig(), classOne: HeroClass = .none, classTwo: HeroClass = .none) throws -> GameState {
        guard config.boardSize > 1, config.apPerTurn > 0, (config.firstTurnAp ?? config.apPerTurn) > 0,
              config.initialMana >= 0, config.manaGainPerTurn >= 0, config.manaCap >= 0, config.maxPlies > 0 else { throw SetupError.invalidConfiguration }
        var board = Board(size: config.boardSize)
        guard board.contains(config.commanderOneStart), board.contains(config.commanderTwoStart),
              config.commanderOneStart != config.commanderTwoStart else { throw SetupError.invalidConfiguration }
        board[config.commanderOneStart] = Piece(.one, .commander)
        board[config.commanderTwoStart] = Piece(.two, .commander)
        var state = GameState(config: config, board: board, classes: [classOne, classTwo], mana: [config.initialMana, config.initialMana], summoned: [false, false])
        state.apRemaining = config.firstTurnAp ?? config.apPerTurn
        state.mana[0] = min(config.manaCap, state.mana[0] + config.manaGainPerTurn)
        return state
    }
    public static func fromDiagram(config: RuleConfig = RuleConfig(), diagram: String, classOne: HeroClass = .none,
                                   classTwo: HeroClass = .none, current: Player = .one, manaOne: Int = 3, manaTwo: Int = 3,
                                   ap: Int? = nil, ply: Int = 1, summonedOne: Bool = false, summonedTwo: Bool = false) throws -> GameState {
        let board = try Board.parse(diagram)
        var config = config; config.boardSize = board.size
        var state = GameState(config: config, board: board, classes: [classOne, classTwo], mana: [manaOne, manaTwo],
                              summoned: [summonedOne || board.find(.one, .hero) != nil, summonedTwo || board.find(.two, .hero) != nil])
        state.current = current; state.apRemaining = ap ?? config.apPerTurn; state.ply = ply
        return state
    }
}
public enum GameEngine {
    /// Value semantics: both success and rejection leave the supplied state intact.
    public static func apply(_ state: GameState, _ action: GameAction) -> ActionOutcome {
        func reject(_ reason: IllegalReason) -> ActionOutcome { ActionOutcome(state: state, events: [], reason: reason) }
        guard state.status == .ongoing else { return reject(.gameOver) }
        var next = state
        var events: [ActionEvent] = []
        if action == .endTurn {
            endTurn(&next, &events)
            return ActionOutcome(state: next, events: events, reason: .none)
        }
        guard state.apRemaining > 0 else { return reject(.noActionPoints) }
        let me = state.current
        var trial = state.board
        var placements: [(Point, PieceKind)] = []
        var pushed: (Point, Point, Piece)?
        var swap: (Point, Point)?
        var seal: SealEffect?
        var manaCost = 0
        var isSkill = false
        func placeable(_ p: Point) -> IllegalReason? {
            if !trial.contains(p) { return .outOfBounds }
            if trial[p] != nil { return .occupied }
            if state.isSealed(p, for: me) { return .sealed }
            return nil
        }
        func skillGate(_ required: HeroClass) -> IllegalReason? {
            if state.heroClass(of: me) != required { return .wrongClass }
            if state.board.find(me, .hero) == nil { return .noHeroOnBoard }
            if state.skillUsedThisTurn { return .skillAlreadyUsed }
            if state.mana(of: me) < state.config.skillManaCost { return .notEnoughMana }
            return nil
        }
        switch action {
        case .placeSoldier(let p):
            if let error = placeable(p) { return reject(error) }
            trial[p] = Piece(me, .soldier); placements = [(p, .soldier)]
        case .summonHero(let p):
            let heroClass = state.heroClass(of: me)
            guard heroClass != .none else { return reject(.noHeroClass) }
            guard trial.find(me, .hero) == nil else { return reject(.heroAlreadyOnBoard) }
            guard !state.hasSummonedHero(me) || state.config.allowResummon else { return reject(.heroAlreadySummoned) }
            manaCost = state.config.summonCost(heroClass)
            guard state.mana(of: me) >= manaCost else { return reject(.notEnoughMana) }
            if let error = placeable(p) { return reject(error) }
            guard trial.neighbors(of: p).contains(where: { trial[$0]?.owner == me }) else { return reject(.notAdjacentToFriend) }
            trial[p] = Piece(me, .hero); placements = [(p, .hero)]
        case .castBastion(let a, let b):
            if let error = skillGate(.warrior) { return reject(error) }
            let hero = trial.find(me, .hero)!
            guard a != b else { return reject(.duplicateTarget) }
            // Snapshot before either placement: the first stone cannot extend the second target's range.
            let frontier = Set(trial.group(at: hero).flatMap { trial.neighbors(of: $0) })
            for p in [a, b] {
                guard trial.contains(p) else { return reject(.outOfBounds) }
                let inRange = state.config.bastionScope == .heroAdjacent ? hero.distance(to: p) == 1 : frontier.contains(p)
                guard inRange else { return reject(.outOfRange) }
                if let error = placeable(p) { return reject(error) }
            }
            trial[a] = Piece(me, .soldier); trial[b] = Piece(me, .soldier)
            placements = [(a, .soldier), (b, .soldier)]; isSkill = true; manaCost = state.config.skillManaCost
        case .castSeal(let p):
            if let error = skillGate(.mage) { return reject(error) }
            guard state.config.mageSkill == .seal else { return reject(.skillNotSelected) }
            guard trial.contains(p) else { return reject(.outOfBounds) }
            let distance = trial.find(me, .hero)!.distance(to: p)
            guard distance >= 1 && distance <= state.config.sealRange else { return reject(.outOfRange) }
            guard trial[p] == nil else { return reject(.occupied) }
            guard !state.isSealed(p, for: me.opponent) else { return reject(.invalidTarget) }
            seal = SealEffect(at: p, caster: me, blockedPlayer: me.opponent)
            isSkill = true; manaCost = state.config.skillManaCost
        case .castSwap(let p):
            if let error = skillGate(.rogue) { return reject(error) }
            guard trial.contains(p) else { return reject(.outOfBounds) }
            let hero = trial.find(me, .hero)!
            guard hero.distance(to: p) == 1 else { return reject(.outOfRange) }
            guard let victim = trial[p], victim.owner != me, victim.kind == .soldier else { return reject(.invalidTarget) }
            trial[hero] = victim; trial[p] = Piece(me, .hero)
            swap = (hero, p); isSkill = true; manaCost = state.config.skillManaCost
        case .castMagicHand(let target, let direction):
            if let error = skillGate(.mage) { return reject(error) }
            guard state.config.mageSkill == .magicHand else { return reject(.skillNotSelected) }
            guard trial.contains(target) else { return reject(.outOfBounds) }
            guard trial.find(me, .hero)!.distance(to: target) <= state.config.magicHandRange else { return reject(.outOfRange) }
            guard let victim = trial[target], victim.kind == .soldier else { return reject(.invalidTarget) }
            guard direction != .invalid else { return reject(.invalidDirection) }
            let destination = direction.destination(from: target)
            guard trial.contains(destination) else { return reject(.outOfBounds) }
            // Movement keeps ownership. Seals restrict placement, not this movement.
            if let occupant = trial[destination] {
                guard state.config.magicHandDestination == .opposingSoldierExchange else { return reject(.occupied) }
                guard occupant.kind == .soldier, occupant.owner != victim.owner else { return reject(.invalidTarget) }
                trial[target] = occupant; trial[destination] = victim
                swap = (target, destination)
            } else {
                trial[target] = nil; trial[destination] = victim
                pushed = (target, destination, victim)
            }
            isSkill = true; manaCost = state.config.skillManaCost
        case .castFriendlyRedeploy(let source, let destination):
            return applyExperimentalRedeployment(state, FriendlyRedeployment(from: source, to: destination))
        case .endTurn: preconditionFailure("Handled above")
        }
        return settle(state, trial: trial, placements: placements, pushed: pushed, swap: swap,
                      seal: seal, manaCost: manaCost, isSkill: isSkill)
    }
    /// Shared candidate action adapter. All settlement uses the same rules as original actions.
    public static func applyExperimentalRedeployment(_ state: GameState, _ command: FriendlyRedeployment) -> ActionOutcome {
        func reject(_ reason: IllegalReason) -> ActionOutcome { ActionOutcome(state: state, events: [], reason: reason) }
        guard state.status == .ongoing else { return reject(.gameOver) }
        guard state.apRemaining > 0 else { return reject(.noActionPoints) }
        guard state.config.experimentalFriendlyRedeploy, state.config.mageSkill == .magicHand else { return reject(.skillNotSelected) }
        let me = state.current
        guard state.heroClass(of: me) == .mage else { return reject(.wrongClass) }
        guard let hero = state.board.find(me, .hero) else { return reject(.noHeroOnBoard) }
        guard !state.skillUsedThisTurn else { return reject(.skillAlreadyUsed) }
        guard state.mana(of: me) >= state.config.skillManaCost else { return reject(.notEnoughMana) }
        let source = command.source, destination = command.destination
        guard state.board.contains(source), state.board.contains(destination) else { return reject(.outOfBounds) }
        guard source != destination else { return reject(.duplicateTarget) }
        guard state.board[source] == Piece(me, .soldier) else { return reject(.invalidTarget) }
        guard hero.distance(to: source) <= state.config.magicHandRange else { return reject(.outOfRange) }
        let group = Set(state.board.group(at: hero))
        guard group.contains(source) else { return reject(.notAdjacentToFriend) }
        guard state.board[destination] == nil else { return reject(.occupied) }
        let frontier = Set(group.flatMap { state.board.neighbors(of: $0) })
        guard frontier.contains(destination) else { return reject(.outOfRange) }
        var trial = state.board
        let soldier = Piece(me, .soldier)
        trial[source] = nil; trial[destination] = soldier
        return settle(state, trial: trial, pushed: (source, destination, soldier),
                      manaCost: state.config.skillManaCost, isSkill: true)
    }
    /// Domain-validated commands for compatibility with existing fixed-position probes.
    public static func legalExperimentalRedeployments(_ state: GameState) -> [FriendlyRedeployment] {
        redeploymentCandidates(state).filter { applyExperimentalRedeployment(state, $0).success }
    }
    /// Geometric candidates only. Every consumer must validate each through Core settlement once.
    private static func redeploymentCandidates(_ state: GameState) -> [FriendlyRedeployment] {
        guard state.status == .ongoing, state.apRemaining > 0, state.config.experimentalFriendlyRedeploy,
              state.config.mageSkill == .magicHand, state.heroClass(of: state.current) == .mage,
              !state.skillUsedThisTurn, state.mana(of: state.current) >= state.config.skillManaCost,
              let hero = state.board.find(state.current, .hero) else { return [] }
        let group = state.board.group(at: hero)
        let frontier: Set<Point> = Set(group.flatMap { state.board.neighbors(of: $0) })
        let emptyFrontier: [Point] = frontier.filter { state.board[$0] == nil }
        let destinations = emptyFrontier.sorted { a, b in a.y == b.y ? a.x < b.x : a.y < b.y }
        let sources = group.filter { state.board[$0] == Piece(state.current, .soldier) && hero.distance(to: $0) <= state.config.magicHandRange }
            .sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
        return sources.flatMap { from in destinations.map { FriendlyRedeployment(from: from, to: $0) } }
    }
    private static func settle(_ state: GameState, trial initialBoard: Board,
                               placements: [(Point, PieceKind)] = [], pushed: (Point, Point, Piece)? = nil,
                               swap: (Point, Point)? = nil, seal: SealEffect? = nil,
                               manaCost: Int, isSkill: Bool) -> ActionOutcome {
        func reject(_ reason: IllegalReason) -> ActionOutcome { ActionOutcome(state: state, events: [], reason: reason) }
        var next = state, trial = initialBoard
        let me = state.current
        var events: [ActionEvent] = []
        var captured: [CapturedPiece] = []
        if seal == nil {
            var seen: Set<Point> = []
            for p in trial.points {
                guard let piece = trial[p], piece.owner != me, !seen.contains(p) else { continue }
                let group = trial.group(at: p); seen.formUnion(group)
                if trial.liberties(at: p).isEmpty {
                    for g in group.sorted(by: { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }) {
                        captured.append(CapturedPiece(at: g, piece: trial[g]!)); trial[g] = nil
                    }
                }
            }
            for p in trial.points where trial[p]?.owner == me {
                if trial.liberties(at: p).isEmpty { return reject(.suicide) }
            }
            guard !state.history.contains(trial.diagram) else { return reject(.ko) }
            next.board = trial; next.history.insert(trial.diagram)
        }
        next.apRemaining -= 1; next.mana[me.rawValue] -= manaCost
        if isSkill { next.skillUsedThisTurn = true }
        events.append(.resourcesSpent(me, ap: 1, mana: manaCost))
        for (p, kind) in placements {
            events.append(.piecePlaced(me, p, kind))
            if kind == .hero { next.heroSummoned[me.rawValue] = true }
        }
        if let (a, b) = swap { events.append(.piecesSwapped(me, a, b)) }
        if let (from, to, piece) = pushed { events.append(.piecePushed(caster: me, from: from, to: to, piece: piece)) }
        if let seal {
            next.seals.append(seal); events.append(.sealPlaced(caster: seal.caster, blocked: seal.blockedPlayer, at: seal.at))
        }
        if !captured.isEmpty { events.append(.piecesCaptured(me, captured)) }
        if captured.contains(where: { $0.piece.kind == .commander && $0.piece.owner != me }) {
            next.status = .won; next.winner = me; events.append(.gameWon(me))
        } else if next.apRemaining == 0 { endTurn(&next, &events) }
        return ActionOutcome(state: next, events: events, reason: .none)
    }
    public static func validate(_ state: GameState, _ action: GameAction) -> IllegalReason { apply(state, action).reason }
    public static func legalActions(_ state: GameState) -> [GameAction] {
        guard state.status == .ongoing else { return [] }
        var candidates: [GameAction] = []
        if state.apRemaining > 0 {
            for p in state.board.points where state.board[p] == nil {
                candidates.append(.placeSoldier(p)); candidates.append(.summonHero(p))
            }
            if let hero = state.board.find(state.current, .hero) {
                switch state.heroClass(of: state.current) {
                case .warrior:
                    let range = state.config.bastionScope == .heroAdjacent ? state.board.neighbors(of: hero)
                        : Array(Set(state.board.group(at: hero).flatMap { state.board.neighbors(of: $0) }))
                            .sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }
                    let around = range.filter { state.board[$0] == nil }
                    for i in around.indices { for j in around.indices where j > i { candidates.append(.castBastion(around[i], around[j])) } }
                case .mage:
                    if state.config.mageSkill == .seal {
                        candidates += state.board.points.filter { state.board[$0] == nil }.map { .castSeal($0) }
                    } else {
                        for p in state.board.points where state.board[p]?.kind == .soldier && hero.distance(to: p) <= state.config.magicHandRange {
                            candidates += PushDirection.allCases.map { .castMagicHand(p, $0) }
                        }
                        candidates += redeploymentCandidates(state).map { .castFriendlyRedeploy($0.source, $0.destination) }
                    }
                case .rogue: candidates += state.board.neighbors(of: hero).map { .castSwap($0) }
                case .none: break
                }
            }
        }
        return candidates.filter { validate(state, $0) == .none } + [.endTurn]
    }
    private static func endTurn(_ state: inout GameState, _ events: inout [ActionEvent]) {
        events.append(.turnEnded(state.current, ply: state.ply))
        for seal in state.seals where seal.blockedPlayer == state.current { events.append(.sealExpired(seal.at)) }
        state.seals.removeAll { $0.blockedPlayer == state.current }
        if state.ply >= state.config.maxPlies {
            state.status = .drawn; events.append(.gameDrawn("Turn limit reached (\(state.config.maxPlies) plies).")); return
        }
        state.current = state.current.opponent; state.ply += 1; state.apRemaining = state.config.apPerTurn
        state.skillUsedThisTurn = false
        let index = state.current.rawValue
        state.mana[index] = min(state.config.manaCap, state.mana[index] + state.config.manaGainPerTurn)
        events.append(.turnStarted(state.current, ply: state.ply, ap: state.apRemaining, mana: state.mana[index]))
    }
}
public struct GameSession: Sendable {
    public private(set) var state: GameState
    public private(set) var log: [GameAction] = []
    private var snapshots: [GameState] = []
    public init(_ initial: GameState) { state = initial }
    @discardableResult public mutating func apply(_ action: GameAction) -> ActionOutcome {
        let outcome = GameEngine.apply(state, action)
        if outcome.success { snapshots.append(state); log.append(action); state = outcome.state }
        return outcome
    }
    public var canUndo: Bool { !snapshots.isEmpty }
    /// Restores resources, seals, summon flags AND superko history, not only the diagram.
    @discardableResult public mutating func undo() -> Bool {
        guard let previous = snapshots.popLast() else { return false }
        state = previous; log.removeLast(); return true
    }
}
