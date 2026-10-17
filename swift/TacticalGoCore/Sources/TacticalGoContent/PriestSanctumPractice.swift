import TacticalGoCore

/// PRIEST-S2-P0 (Beta candidate): positions where the priest's second skill (`castSanctum`) is the only single action
/// that keeps the commander alive. Black has 1 AP: the commander group's one liberty is the exit point; a normal stone
/// there or an Offering each leave 2 liberties, which White fills with its 2 AP. Sanctum sacrifices the fully enclosed
/// soldier (+1 liberty, no liberty lost) and reinforces the exit in the same AP, leaving 3. Hand-placed teaching
/// positions, not balance proof; `PriestSanctumPracticeTests` verifies the claim by exhaustive search.
public enum PriestSanctumPractice: String, Sendable, CaseIterable {
    case seven, nine

    public var size: Int { self == .seven ? 7 : 9 }
    public var diagram: String {
        switch self {
        case .seven:
            [".......",
             "...O...",
             ".......",
             ".......",
             "oo.....",
             "Hxo....",
             "xxX...."].joined(separator: "\n")
        case .nine:
            [".........",
             "....O....",
             ".........",
             ".........",
             ".........",
             ".........",
             ".......oo",
             "......oxH",
             "......Xxx"].joined(separator: "\n")
        }
    }
    public var sacrifice: Point { self == .seven ? Point(1,5) : Point(7,7) }
    public var destination: Point { self == .seven ? Point(3,6) : Point(5,8) }
    public var action: GameAction { .castSanctum(sacrifice: sacrifice, destination: destination) }
    public var title: String { self == .seven ? "牧師 · 聖所救援（7×7）" : "牧師 · 聖所救援（9×9）" }
    public var instruction: String {
        "黑方只剩 1 AP，主將棋群只剩 1 口氣。普通落子或奉獻都只能留下 2 口氣，白方兩手就能提掉主將。"
            + "用聖所：先點被己子包住的士兵犧牲，再點主將旁的出口補兵，一手同時多出一口氣並向外延伸。"
    }
    public func state() throws -> GameState {
        try GameSetup.fromDiagram(config: TacticalHints.updatedConfig(size: size), diagram: diagram,
                                  classOne: .priest, classTwo: .mage, current: .one, manaOne: 4, manaTwo: 3, ap: 1, ply: 9)
    }
}

/// What a priest sacrifice (Offering or Sanctum) does, for the preview: what is given up and placed, which own group it
/// is about, its liberties before and after, captures, whether groups split or join, and whether the vacated point looks
/// like an eye. Descriptive geometry only: it never claims a group is safe or alive.
public struct PriestSacrificeInsight: Equatable, Sendable {
    public enum Group: Equatable, Sendable { case commander, hero, soldiers }
    public enum Eye: Equatable, Sendable {
        case none
        /// Four own (or edge) neighbours, and diagonals pass the usual false-eye check.
        case likely
        /// Four own neighbours, but too many diagonals belong to the opponent or are empty: possibly a false eye.
        case possiblyFalse
    }
    public let sacrifice: Point
    public let reinforcement: Point?
    public let captured: Int
    public let group: Group
    public let libertiesBefore: Int
    public let libertiesAfter: Int
    /// After the sacrifice the vacated point touches two or more separate own groups (the sacrifice cut a group).
    public let split: Bool
    /// The reported group contains stones that were in different groups before (the reinforcement joined them).
    public let merged: Bool
    public let eye: Eye
    public var eyeFormed: Bool { eye == .likely }

    /// nil unless `action` is a legal Offering or Sanctum in `state`.
    public init?(_ state: GameState, _ action: GameAction) {
        let source: Point, placed: Point?
        switch action {
        case .castOffering(let p): source = p; placed = nil
        case .castSanctum(let p, let d): source = p; placed = d
        default: return nil
        }
        let outcome = GameEngine.apply(state, action)
        guard outcome.success else { return nil }
        let me = state.current, after = outcome.state.board, before = state.board
        let captures = outcome.events.reduce(0) { n, e in if case .piecesCaptured(_, let points) = e { return n + points.count }; return n }
        // Own groups that touch the vacated point afterwards (and the reinforcement's group).
        let anchors = after.neighbors(of: source).filter { after[$0]?.owner == me } + (placed.map { [$0] } ?? [])
        var groups: [Set<Point>] = []
        for p in anchors where after[p]?.owner == me && !groups.contains(where: { $0.contains(p) }) {
            groups.append(Set(after.group(at: p)))
        }
        func has(_ g: Set<Point>, _ kind: PieceKind) -> Bool { g.contains { after[$0]?.kind == kind } }
        guard let chosen = groups.first(where: { has($0, .commander) }) ?? groups.first(where: { has($0, .hero) })
                ?? groups.max(by: { $0.count < $1.count }) else { return nil }
        let touchingVacated = Set(after.neighbors(of: source).compactMap { p in
            after[p]?.owner == me ? groups.firstIndex { $0.contains(p) } : nil })
        // "Before" is the group that held the same key stone (commander, hero, or any stone that existed before).
        let key = chosen.first { after[$0]?.kind == .commander } ?? chosen.first { after[$0]?.kind == .hero }
            ?? chosen.first { before[$0]?.owner == me } ?? source
        let beforeGroup: Set<Point> = before[key]?.owner == me ? Set(before.group(at: key)) : []
        var eyeKind = Eye.none
        if after.isEmpty(source), after.neighbors(of: source).allSatisfy({ after[$0]?.owner == me }) {
            let diagonals = [(-1,-1),(1,-1),(-1,1),(1,1)].map { Point(source.x + $0.0, source.y + $0.1) }.filter(after.contains)
            let foreign = diagonals.filter { after[$0]?.owner != me }.count
            eyeKind = (diagonals.count < 4 ? foreign == 0 : foreign <= 1) ? .likely : .possiblyFalse
        }
        sacrifice = source; reinforcement = placed; captured = captures
        group = has(chosen, .commander) ? .commander : has(chosen, .hero) ? .hero : .soldiers
        split = touchingVacated.count > 1
        libertiesBefore = beforeGroup.isEmpty ? 0 : before.liberties(at: key).count
        libertiesAfter = after.liberties(at: chosen.first!).count
        merged = chosen.contains { p in before[p]?.owner == me && !beforeGroup.contains(p) }
        eye = eyeKind
    }
    public static func label(_ p: Point) -> String { String(UnicodeScalar(65 + p.x)!) + "\(p.y + 1)" }
    /// One phone line: the trade first, then the group's liberties, then what else changed.
    public var summary: String {
        let trade = "犧牲 \(Self.label(sacrifice))" + (reinforcement.map { "→補 \(Self.label($0))" } ?? "")
        let owner = switch group { case .commander: "主將"; case .hero: "牧師"; case .soldiers: "己兵" }
        var parts = [trade, "\(owner)氣 \(libertiesBefore)→\(libertiesAfter)"]
        if captured > 0 { parts.append("提 \(captured)") }
        var notes: [String] = []
        switch eye { case .likely: notes.append("成眼"); case .possiblyFalse: notes.append("可能假眼"); case .none: break }
        if split { notes.append("棋群分開") }
        if merged { notes.append("連成一群") }
        return parts.joined(separator: " · ") + notes.map { "・" + $0 }.joined()
    }
}
