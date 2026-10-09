public enum Player: Int, Sendable, Codable, CaseIterable {
    case one, two
    public var opponent: Player { self == .one ? .two : .one }
    public var name: String { self == .one ? "One" : "Two" }
}
public enum PieceKind: Int, Sendable, Codable { case soldier, commander, hero }
public enum HeroClass: String, Sendable, Codable, CaseIterable {
    case none = "None", warrior = "Warrior", mage = "Mage", rogue = "Rogue"
}
public enum GameStatus: String, Sendable, Codable { case ongoing = "Ongoing", won = "Won", drawn = "Drawn" }
public struct Point: Hashable, Sendable, Codable {
    public let x: Int
    public let y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
    public func distance(to other: Point) -> Int { abs(x - other.x) + abs(y - other.y) }
}
public struct Piece: Equatable, Sendable, Codable {
    public let owner: Player
    public let kind: PieceKind
    public init(_ owner: Player, _ kind: PieceKind) { self.owner = owner; self.kind = kind }
}
public struct CapturedPiece: Equatable, Sendable, Codable {
    public let at: Point
    public let piece: Piece
}
public struct SealEffect: Equatable, Sendable, Codable {
    public let at: Point
    public let caster: Player
    public let blockedPlayer: Player
}
public enum MageSkill: String, Sendable { case seal = "Seal", magicHand = "MagicHand" }
/// Rule experiments only. Defaults retain the reviewed, shipping candidate rules.
public enum BastionScope: Sendable { case heroAdjacent, connectedGroup }
public enum MagicHandDestination: Sendable { case emptyOnly, opposingSoldierExchange }
public enum PushDirection: String, Sendable, CaseIterable {
    case up = "Up", right = "Right", down = "Down", left = "Left", invalid = "Invalid"
    public static var allCases: [PushDirection] { [.up, .right, .down, .left] }
    public func destination(from p: Point) -> Point {
        switch self {
        case .up: Point(p.x, p.y - 1); case .right: Point(p.x + 1, p.y)
        case .down: Point(p.x, p.y + 1); case .left: Point(p.x - 1, p.y)
        case .invalid: p // Rejected by the engine before destination is used.
        }
    }
}
public struct RuleConfig: Equatable, Sendable {
    public var boardSize = 9
    public var apPerTurn = 2
    public var firstTurnAp: Int? = 1
    public var allowResummon = false
    public var initialMana = 3
    public var manaGainPerTurn = 1
    public var manaCap = 6
    public var skillManaCost = 2
    public var summonCostWarrior = 2
    public var summonCostMage = 3
    public var summonCostRogue = 2
    public var sealRange = 2
    public var mageSkill: MageSkill = .magicHand
    public var magicHandRange = 2
    public var bastionScope: BastionScope = .heroAdjacent
    public var magicHandDestination: MagicHandDestination = .emptyOnly
    /// Explicit candidate mode; original saved games and new-game defaults keep this disabled.
    public var experimentalFriendlyRedeploy = false
    public var maxPlies = 100
    public var commanderOneStart = Point(4, 7)
    public var commanderTwoStart = Point(4, 1)
    public init() {}
    /// Explicit small-board setup; the reference engine's 9×9 defaults remain unchanged.
    public static func board(size: Int) -> RuleConfig {
        var config = RuleConfig()
        config.boardSize = size
        config.commanderOneStart = Point(size / 2, size - 2)
        config.commanderTwoStart = Point(size / 2, 1)
        return config
    }
    public func summonCost(_ hero: HeroClass) -> Int {
        switch hero { case .warrior: summonCostWarrior; case .mage: summonCostMage; case .rogue: summonCostRogue; case .none: Int.max }
    }
}
public struct Board: Equatable, Sendable {
    public let size: Int
    private var cells: [Piece?]
    public init(size: Int) {
        precondition(size > 0)
        self.size = size
        cells = Array(repeating: nil, count: size * size)
    }
    public func contains(_ p: Point) -> Bool { p.x >= 0 && p.y >= 0 && p.x < size && p.y < size }
    public internal(set) subscript(_ p: Point) -> Piece? {
        get { precondition(contains(p)); return cells[p.y * size + p.x] }
        set { precondition(contains(p)); cells[p.y * size + p.x] = newValue }
    }
    public var points: [Point] { (0..<size).flatMap { y in (0..<size).map { Point($0, y) } } }
    public func neighbors(of p: Point) -> [Point] {
        [Point(p.x, p.y - 1), Point(p.x + 1, p.y), Point(p.x, p.y + 1), Point(p.x - 1, p.y)].filter(contains)
    }
    public func find(_ owner: Player, _ kind: PieceKind) -> Point? { points.first { self[$0] == Piece(owner, kind) } }
    public func group(at start: Point) -> [Point] {
        guard contains(start), let owner = self[start]?.owner else { return [] }
        var group = [start], seen: Set<Point> = [start], i = 0
        while i < group.count {
            for n in neighbors(of: group[i]) where self[n]?.owner == owner {
                if seen.insert(n).inserted { group.append(n) }
            }
            i += 1
        }
        return group
    }
    public func liberties(at point: Point) -> Set<Point> {
        Set(group(at: point).flatMap { neighbors(of: $0) }.filter { self[$0] == nil })
    }
    public var diagram: String {
        (0..<size).map { y in String((0..<size).map { Self.symbol(self[Point($0, y)]) }) }.joined(separator: "\n")
    }
    public static func symbol(_ p: Piece?) -> Character {
        guard let p else { return "." }
        switch (p.owner, p.kind) {
        case (.one, .soldier): return "x"
        case (.one, .commander): return "X"
        case (.one, .hero): return "H"
        case (.two, .soldier): return "o"
        case (.two, .commander): return "O"
        case (.two, .hero): return "Q"
        }
    }
    public static func parse(_ diagram: String) throws -> Board {
        let rows = diagram.split(separator: "\n").map { $0.filter { !$0.isWhitespace } }.filter { !$0.isEmpty }
        guard !rows.isEmpty, rows.allSatisfy({ $0.count == rows.count }) else { throw SetupError.invalidDiagram }
        var board = Board(size: rows.count)
        for (y, row) in rows.enumerated() {
            for (x, c) in row.enumerated() {
                let p: Piece?
                switch c {
                case ".": p = nil
                case "x": p = Piece(.one, .soldier)
                case "X": p = Piece(.one, .commander)
                case "H": p = Piece(.one, .hero)
                case "o": p = Piece(.two, .soldier)
                case "O": p = Piece(.two, .commander)
                case "Q": p = Piece(.two, .hero)
                default: throw SetupError.invalidDiagram
                }
                board[Point(x, y)] = p
            }
        }
        return board
    }
}
public enum SetupError: Error { case invalidDiagram, invalidConfiguration }
public struct GameState: Equatable, Sendable {
    public let config: RuleConfig
    public internal(set) var board: Board
    public internal(set) var current: Player = .one
    public internal(set) var ply = 1
    public internal(set) var apRemaining = 0
    public internal(set) var skillUsedThisTurn = false
    public internal(set) var status: GameStatus = .ongoing
    public internal(set) var winner: Player?
    public internal(set) var seals: [SealEffect] = []
    internal var mana: [Int]
    internal var classes: [HeroClass]
    internal var heroSummoned: [Bool]
    // Exact placement equality avoids hash collisions; boards here have at most 81 points.
    internal var history: Set<String>
    internal init(config: RuleConfig, board: Board, classes: [HeroClass], mana: [Int], summoned: [Bool]) {
        self.config = config; self.board = board; self.classes = classes; self.mana = mana
        heroSummoned = summoned; history = [board.diagram]
    }
    public func mana(of player: Player) -> Int { mana[player.rawValue] }
    public func heroClass(of player: Player) -> HeroClass { classes[player.rawValue] }
    public func hasSummonedHero(_ player: Player) -> Bool { heroSummoned[player.rawValue] }
    public func isSealed(_ point: Point, for player: Player) -> Bool { seals.contains { $0.at == point && $0.blockedPlayer == player } }
}
public enum GameAction: Equatable, Sendable {
    case placeSoldier(Point), summonHero(Point), castBastion(Point, Point), castSeal(Point), castSwap(Point), castMagicHand(Point, PushDirection), castFriendlyRedeploy(Point, Point), endTurn
}
public enum IllegalReason: String, Sendable, CaseIterable {
    case skillNotSelected = "SkillNotSelected", invalidDirection = "InvalidDirection"
    case none = "None", gameOver = "GameOver", noActionPoints = "NoActionPoints", outOfBounds = "OutOfBounds"
    case occupied = "Occupied", sealed = "Sealed", suicide = "Suicide", ko = "Ko", notEnoughMana = "NotEnoughMana"
    case noHeroClass = "NoHeroClass", heroAlreadyOnBoard = "HeroAlreadyOnBoard", notAdjacentToFriend = "NotAdjacentToFriend"
    case heroAlreadySummoned = "HeroAlreadySummoned", wrongClass = "WrongClass", noHeroOnBoard = "NoHeroOnBoard"
    case skillAlreadyUsed = "SkillAlreadyUsed", outOfRange = "OutOfRange", invalidTarget = "InvalidTarget", duplicateTarget = "DuplicateTarget"
}
public enum ActionEvent: Equatable, Sendable {
    case resourcesSpent(Player, ap: Int, mana: Int)
    case piecePlaced(Player, Point, PieceKind)
    case piecesSwapped(Player, Point, Point)
    case piecePushed(caster: Player, from: Point, to: Point, piece: Piece)
    case sealPlaced(caster: Player, blocked: Player, at: Point)
    case sealExpired(Point)
    case piecesCaptured(Player, [CapturedPiece])
    case turnEnded(Player, ply: Int)
    case turnStarted(Player, ply: Int, ap: Int, mana: Int)
    case gameWon(Player)
    case gameDrawn(String)
    public var name: String {
        switch self {
        case .resourcesSpent: "ResourcesSpent"; case .piecePlaced: "PiecePlaced"; case .piecesSwapped: "PiecesSwapped"
        case .piecePushed: "PiecePushed"; case .sealPlaced: "SealPlaced"; case .sealExpired: "SealExpired"; case .piecesCaptured: "PiecesCaptured"
        case .turnEnded: "TurnEnded"; case .turnStarted: "TurnStarted"; case .gameWon: "GameWon"; case .gameDrawn: "GameDrawn"
        }
    }
}
public struct ActionOutcome: Equatable, Sendable {
    public let state: GameState
    public let events: [ActionEvent]
    public let reason: IllegalReason
    public var success: Bool { reason == .none }
}

/// Compatibility command for fixed-position probes; persisted candidate actions delegate to the same Core API.
public struct FriendlyRedeployment: Equatable, Sendable {
    public let source: Point
    public let destination: Point
    public init(from source: Point, to destination: Point) {
        self.source = source; self.destination = destination
    }
}
