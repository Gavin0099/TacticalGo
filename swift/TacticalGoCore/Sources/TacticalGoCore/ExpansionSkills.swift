extension GameEngine {
    /// All geometric checks use the immutable pre-action board. Only settle resolves captures.
    static func applyExpansion(_ state: GameState, _ action: GameAction) -> ActionOutcome {
        func reject(_ reason: IllegalReason) -> ActionOutcome { .init(state: state, events: [], reason: reason) }
        guard state.config.expansionSkills else { return reject(.skillNotSelected) }
        let required: HeroClass
        switch action {
        case .castSanctuary, .castSanctum, .castOffering: required = .priest
        case .castDoublePull: required = .mage
        case .castReformation: required = .warrior
        case .castChainSwap: required = .rogue
        default: return reject(.invalidTarget)
        }
        let me = state.current
        guard state.heroClass(of: me) == required else { return reject(.wrongClass) }
        guard let hero = state.board.find(me, .hero) else { return reject(.noHeroOnBoard) }
        guard !state.skillUsedThisTurn else { return reject(.skillAlreadyUsed) }
        // Priest basic skills keep the basic cost; every second skill (now including the priest's sanctum) pays the expansion cost.
        let isSecondSkill: Bool = { if case .castSanctum = action { return true }; return required != .priest }()
        let cost = isSecondSkill ? state.config.expansionSkillManaCost : state.config.skillManaCost
        guard state.mana(of: me) >= cost else { return reject(.notEnoughMana) }
        let board = state.board
        var trial = board
        switch action {
        case .castOffering(let source):
            guard board.contains(source) else { return reject(.outOfBounds) }
            guard board[source] == Piece(me, .soldier) else { return reject(.invalidTarget) }
            guard hero.distance(to: source) <= 2 else { return reject(.outOfRange) }
            trial[source] = nil
            return settle(state, trial:trial, manaCost:cost, isSkill:true, sacrifice:source)
        case .castSanctuary(let source, let destination), .castSanctum(let source, let destination):
            guard board.contains(source), board.contains(destination) else { return reject(.outOfBounds) }
            guard source != destination else { return reject(.duplicateTarget) }
            guard board[source] == Piece(me, .soldier) else { return reject(.invalidTarget) }
            guard hero.distance(to: source) <= 2 else { return reject(.outOfRange) }
            guard board.isEmpty(destination) else { return reject(.occupied) }
            guard !state.isSealed(destination, for: me) else { return reject(.sealed) }
            let defenders = [hero] + (board.find(me, .commander).map { [$0] } ?? [])
            guard defenders.contains(where: { $0.distance(to: destination) == 1 }) else { return reject(.outOfRange) }
            trial[source] = nil; trial[destination] = Piece(me, .soldier)
            return settle(state, trial: trial, placements: [(destination, .soldier)], manaCost: cost, isSkill: true, sacrifice: source)
        case .castDoublePull(let a, let b), .castReformation(let a, let b):
            guard a.from != b.from, a.to != b.to else { return reject(.duplicateTarget) }
            let group = Set(board.group(at: hero))
            let frontier = Set(group.flatMap { board.neighbors(of: $0) })
            var transfers: [(Point, Point, Piece)] = []
            for shift in [a,b] {
                guard board.contains(shift.from), board.contains(shift.to) else { return reject(.outOfBounds) }
                guard let piece = board[shift.from], piece.kind == .soldier else { return reject(.invalidTarget) }
                guard board.isEmpty(shift.to) else { return reject(.occupied) }
                if required == .mage {
                    guard hero.distance(to: shift.from) <= state.config.magicHandRange,
                          shift.from.distance(to: shift.to) == 1 else { return reject(.outOfRange) }
                } else {
                    guard piece.owner == me else { return reject(.invalidTarget) }
                    guard group.contains(shift.from), frontier.contains(shift.to), hero.distance(to: shift.to) <= 4 else { return reject(.outOfRange) }
                }
                transfers.append((shift.from, shift.to, piece))
            }
            for (from, _, _) in transfers { trial[from] = nil }
            for (_, to, piece) in transfers { trial[to] = piece }
            return settle(state, trial: trial, manaCost: cost, isSkill: true, transfers: transfers)
        case .castChainSwap(let first, let second):
            guard board.contains(first), board.contains(second) else { return reject(.outOfBounds) }
            guard hero != first, hero != second, first != second else { return reject(.duplicateTarget) }
            guard hero.distance(to: first) == 1, first.distance(to: second) == 1 else { return reject(.outOfRange) }
            let enemy = Piece(me.opponent, .soldier), ownHero = Piece(me, .hero)
            guard board[first] == enemy, board[second] == enemy else { return reject(.invalidTarget) }
            trial[hero] = enemy; trial[first] = enemy; trial[second] = ownHero
            return settle(state, trial: trial, manaCost: cost, isSkill: true,
                          transfers: [(hero, second, ownHero), (first, hero, enemy), (second, first, enemy)])
        default: return reject(.invalidTarget)
        }
    }

    /// Canonical ordering avoids duplicate unordered move pairs. Consumers still validate via Core.
    static func expansionCandidates(_ state: GameState, advanced: Bool, limit: Int? = nil) -> [GameAction] {
        guard state.config.expansionSkills, !state.skillUsedThisTurn,
              let hero = state.board.find(state.current, .hero), state.apRemaining > 0 else { return [] }
        let board = state.board, me = state.current, kind = state.heroClass(of: me)
        let cost = advanced ? state.config.expansionSkillManaCost : state.config.skillManaCost
        guard state.mana(of: me) >= cost else { return [] }
        if !advanced {
            guard kind == .priest else { return [] }
            return board.points.filter { board[$0] == Piece(me, .soldier) && hero.distance(to: $0) <= 2 }
                .map(GameAction.castOffering)
        }
        if kind == .priest {
            // Sanctum: an own soldier within 2 of the priest, and an empty unsealed point next to the priest or own commander.
            let sources = board.points.filter { board[$0] == Piece(me, .soldier) && hero.distance(to: $0) <= 2 }
            let anchors = [hero] + (board.find(me, .commander).map { [$0] } ?? [])
            var destinations = board.points.filter { p in
                board.isEmpty(p) && !state.isSealed(p, for: me) && anchors.contains { $0.distance(to: p) == 1 }
            }
            if limit != nil, let commander = board.find(me, .commander) {
                // Search order only: points that refill the own commander first.
                destinations.sort { ($0.distance(to: commander), $0.y, $0.x) < ($1.distance(to: commander), $1.y, $1.x) }
            }
            var result: [GameAction] = []
            for d in destinations { for s in sources where s != d {
                result.append(.castSanctum(sacrifice: s, destination: d))
                if let limit, result.count >= max(1, limit) { return result }
            } }
            return result
        }
        if kind == .rogue {
            let enemy = Piece(me.opponent, .soldier)
            return board.neighbors(of: hero).filter { board[$0] == enemy }.flatMap { first in
                board.neighbors(of: first).filter { board[$0] == enemy }.map { .castChainSwap(first: first, second: $0) }
            }
        }
        guard kind == .mage || kind == .warrior else { return [] }
        let group = Set(board.group(at: hero))
        let frontier = Set(group.flatMap { board.neighbors(of: $0) })
        let destinations = board.points.filter { board.isEmpty($0) && frontier.contains($0) && hero.distance(to: $0) <= 4 }
        var shifts: [SoldierShift] = []
        for from in board.points where board[from]?.kind == .soldier {
            if kind == .mage, hero.distance(to: from) <= state.config.magicHandRange {
                shifts += board.neighbors(of: from).filter(board.isEmpty).map { SoldierShift(from, $0) }
            } else if kind == .warrior, board[from]?.owner == me, group.contains(from) {
                shifts += destinations.map { SoldierShift(from, $0) }
            }
        }
        if limit != nil {
            let enemyCommander = board.find(me.opponent,.commander)
            let ownCommander = board.find(me,.commander)
            func priority(_ shift: SoldierShift) -> Int {
                let target = min(enemyCommander.map { shift.to.distance(to:$0) } ?? 9,
                                 ownCommander.map { shift.to.distance(to:$0) } ?? 9)
                // Filling commander liberties is relevant; vacating an adjacent wall
                // generally undoes that threat. Geometry orders search, never legalizes it.
                let opensWall = [enemyCommander,ownCommander].compactMap { $0 }.contains { shift.from.distance(to:$0) == 1 }
                return target * 10 + (opensWall ? 100:0)
            }
            shifts.sort { a,b in
                let pa = priority(a),pb = priority(b)
                if pa != pb { return pa < pb }
                if a.from.y != b.from.y { return a.from.y < b.from.y }
                if a.from.x != b.from.x { return a.from.x < b.from.x }
                if a.to.y != b.to.y { return a.to.y < b.to.y }
                return a.to.x < b.to.x
            }
        }
        var result: [GameAction] = []
        for i in shifts.indices { for j in shifts.indices where j > i {
            let a = shifts[i], b = shifts[j]
            guard a.from != b.from, a.to != b.to else { continue }
            result.append(kind == .mage ? .castDoublePull(a,b) : .castReformation(a,b))
            if let limit,result.count >= max(1,limit) { return result }
        } }
        return result
    }
}
