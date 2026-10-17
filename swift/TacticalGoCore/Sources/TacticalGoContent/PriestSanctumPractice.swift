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
