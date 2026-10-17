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

/// What a priest sacrifice (Offering or Sanctum) does to the own group beside the vacated point, for the preview line.
public struct PriestSacrificeInsight: Equatable, Sendable {
    public let libertiesBefore: Int
    public let libertiesAfter: Int
    /// The vacated point is surrounded on all four sides by own pieces or the board edge.
    public let eyeFormed: Bool

    /// nil unless `action` is a legal Offering or Sanctum in `state`.
    public init?(_ state: GameState, _ action: GameAction) {
        let source: Point
        switch action {
        case .castOffering(let p): source = p
        case .castSanctum(let p, _): source = p
        default: return nil
        }
        let outcome = GameEngine.apply(state, action)
        guard outcome.success else { return nil }
        let me = state.current, after = outcome.state.board, before = state.board
        // The own group that gains the vacated point; prefer the commander's group when several touch it.
        let touching = after.neighbors(of: source).filter { after[$0]?.owner == me }
        let groups = touching.map { Set(after.group(at: $0)) }
        guard let group = groups.first(where: { g in g.contains { after[$0]?.kind == .commander } })
                ?? groups.max(by: { $0.count < $1.count }) else { return nil }
        let stoneBefore = group.first { before[$0]?.owner == me } ?? source
        libertiesBefore = before.liberties(at: stoneBefore).count
        libertiesAfter = after.liberties(at: group.first!).count
        eyeFormed = after.isEmpty(source) && after.neighbors(of: source).allSatisfy { after[$0]?.owner == me }
    }
    public var summary: String {
        // One line in the phone dock: keep it short.
        "犧牲後氣 \(libertiesBefore)→\(libertiesAfter)" + (eyeFormed ? "・成眼" : "")
    }
}
