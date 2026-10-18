import TacticalGoCore

/// PRIEST-S2-P0 (Beta candidate) lessons for the priest's second skill (`castSanctum`): rescues where it is the only
/// answer, and comparisons where something cheaper works, Sanctum backfires, or nothing helps. Black always has 1 AP
/// and 4 mana. Hand-placed teaching positions, not balance proof; every claim (`kind`) is verified by exhaustive
/// search in `PriestSanctumPracticeTests` (every Black action × every White reply of up to two actions).
public enum PriestSanctumPractice: String, Sendable, CaseIterable {
    case seven, nine, centerNine, wideExitNine, twoEyesSeven, tooLateSeven

    public enum Kind: Sendable, Equatable {
        /// Sanctum is the only single action that keeps the commander alive through White's turn.
        case onlySanctum
        /// An ordinary stone at the exit already survives White's turn (the commander is left in atari afterwards);
        /// Sanctum costs 4 mana to keep one more liberty. A trade-off, not a requirement.
        case placementEnough
        /// Offering (2 mana) makes two eyes; Sanctum's reinforcement fills an own eye and loses.
        case offeringEnough
        /// No single action saves the commander, Sanctum included.
        case nothingSaves
    }

    public var kind: Kind {
        switch self {
        case .seven, .nine, .centerNine: .onlySanctum
        case .wideExitNine: .placementEnough
        case .twoEyesSeven: .offeringEnough
        case .tooLateSeven: .nothingSaves
        }
    }
    public var size: Int { [.nine, .centerNine, .wideExitNine].contains(self) ? 9 : 7 }
    public var diagram: String {
        let rows: [String]
        switch self {
        case .seven:
            rows = [".......", "...O...", ".......", ".......", "oo.....", "Hxo....", "xxX...."]
        case .nine:
            rows = [".........", "....O....", ".........", ".........", ".........", ".........",
                    ".......oo", "......oxH", "......Xxx"]
        case .centerNine:
            // A ring around the enclosed soldier E5 keeps the priest and commander connected after the sacrifice.
            rows = [".........", "....O....", ".........", "...ooo...", "..oHxX...", "..oxxxo..",
                    "...ooo...", ".........", "........."]
        case .wideExitNine:
            rows = [".........", "....O....", ".........", "...ooo...", "..oHxX...", "..oxxo...",
                    "...oo....", ".........", "........."]
        case .twoEyesSeven:
            rows = [".......", "...O...", ".......", ".......", "ooooo..", "xxHxo..", ".Xxxo.."]
        case .tooLateSeven:
            rows = [".......", "...O...", ".......", ".......", "oo.....", "Hxoo...", "xxX...."]
        }
        return rows.joined(separator: "\n")
    }
    public var sacrifice: Point {
        switch self {
        case .seven, .tooLateSeven: Point(1,5)
        case .nine: Point(7,7)
        case .centerNine, .wideExitNine: Point(4,4)
        case .twoEyesSeven: Point(2,6)
        }
    }
    public var destination: Point {
        switch self {
        case .seven, .tooLateSeven: Point(3,6)
        case .nine: Point(5,8)
        case .centerNine, .wideExitNine: Point(6,4)
        case .twoEyesSeven: Point(0,6)
        }
    }
    /// The Sanctum this lesson is about (the rescue, or the tempting mistake).
    public var action: GameAction { .castSanctum(sacrifice: sacrifice, destination: destination) }
    /// What the lesson teaches to play; nil when nothing saves the commander.
    public var recommended: GameAction? {
        switch kind {
        case .onlySanctum: action
        case .placementEnough: .placeSoldier(destination)
        case .offeringEnough: .castOffering(sacrifice)
        case .nothingSaves: nil
        }
    }
    /// The skill rail the lesson opens on; comparisons do not pre-select the answer.
    public var startsOnSecondSkill: Bool { kind == .onlySanctum || kind == .nothingSaves }
    public var title: String {
        switch self {
        case .seven: "聖所救援 · 角落（7×7）"
        case .nine: "聖所救援 · 角落（9×9）"
        case .centerNine: "聖所救援 · 中腹（9×9）"
        case .wideExitNine: "比較 · 落子也能撐一回合（9×9）"
        case .twoEyesSeven: "比較 · 做兩眼用奉獻（7×7）"
        case .tooLateSeven: "比較 · 聖所也救不了（7×7）"
        }
    }
    public var instruction: String {
        let opening = "黑方只剩 1 AP，主將棋群只剩 1 口氣。"
        switch self {
        case .seven, .nine:
            return opening + "普通落子或奉獻都只能留下 2 口氣，白方兩手就能提掉主將。"
                + "用聖所：先點被己子包住的士兵犧牲，再點主將旁的出口補兵，一手同時多出一口氣並向外延伸。"
        case .centerNine:
            return opening + "棋群在中腹，包住 E5 的己子圍成一圈，犧牲 E5 也不會把牧師和主將拆開。"
                + "犧牲 E5、在出口 G5 補兵，氣會變成 3；普通落子或奉獻都只有 2。"
        case .wideExitNine:
            return opening + "這次出口 G5 外面有三個空點：直接落子就有 3 口氣，白方這回合提不掉，能量全部留著。"
                + "但白方填兩手後主將只剩 1 口氣，下回合要繼續補；用聖所多花 4 能量，白方回應後還有 2 口氣。兩種都可以，看你要不要換。"
        case .twoEyesSeven:
            return "黑方只剩 1 AP，主將棋群被完全包圍，只剩 A7 一個眼。奉獻 C7 就能做出第二個真眼（2 能量）。"
                + "聖所反而只能把兵補在 A7，填掉自己的眼，主將會被提。"
        case .tooLateSeven:
            return opening + "出口外只剩一個空點：聖所補兵後也只有 2 口氣，白方兩手仍能提掉。"
                + "聖所不是萬能，這一局要更早補強。"
        }
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
