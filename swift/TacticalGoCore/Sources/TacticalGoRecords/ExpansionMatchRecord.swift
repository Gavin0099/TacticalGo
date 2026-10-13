import Foundation
import TacticalGoCore

/// Candidate-only schema. Original 1.0 records are deliberately not migrated.
public struct ExpansionMatchRecord: Codable, Sendable {
    public static let rulesID = "tacticalgo-1.1-expansion-08-monsters-05"
    public static let byteLimit = 512 * 1024
    public let computer: Player?
    public let difficulty: String?
    public let version: Int
    public let rules: String
    public let size: Int
    public let classOne: HeroClass, classTwo: HeroClass
    public let advancedMana: Int
    public let huntAP: Int?
    public let monsters: [Spawn]
    public let actions: [Action]
    public let expected: Snapshot
    public struct Spawn: Codable, Sendable {
        public let kind: String, at: Point
    }
    public struct Action: Codable, Sendable {
        public let kind: String, points: [Point], direction: String?
        public init(_ a: GameAction) throws {
            direction = { if case .castMagicHand(_,let d) = a { return d.rawValue }; return nil }()
            switch a {
            case .placeSoldier(let p): kind = "soldier"; points = [p]
            case .summonHero(let p): kind = "summon"; points = [p]
            case .castBastion(let a,let b): kind = "bastion"; points = [a,b]
            case .castMagicHand(let p,_): kind = "hand"; points = [p]
            case .castSwap(let p): kind = "swap"; points = [p]
            case .castSanctuary(let a,let b): kind = "sanctuary"; points = [a,b]
            case .castOffering(let p): kind = "offering"; points = [p]
            case .castDoublePull(let a,let b): kind = "doublePull"; points = [a.from,a.to,b.from,b.to]
            case .castReformation(let a,let b): kind = "reformation"; points = [a.from,a.to,b.from,b.to]
            case .castChainSwap(let a,let b): kind = "chainSwap"; points = [a,b]
            case .huntMonster(let p): kind = "hunt"; points = [p]
            case .useStickyBounce(let a,let b): kind = "bounce"; points = [a,b]
            case .useShadowStep(let p): kind = "step"; points = [p]
            case .endTurn: kind = "end"; points = []
            case .castSeal,.castFriendlyRedeploy: throw RecordError.invalidSetup
            }
        }
        public func domain() throws -> GameAction {
            if kind == "hand",points.count == 1,let direction,let d = PushDirection(rawValue:direction),d != .invalid { return .castMagicHand(points[0],d) }
            guard direction == nil else { throw RecordError.invalidSetup }
            switch (kind,points.count) {
            case ("soldier",1): return .placeSoldier(points[0])
            case ("summon",1): return .summonHero(points[0])
            case ("bastion",2): return .castBastion(points[0],points[1])
            case ("swap",1): return .castSwap(points[0])
            case ("sanctuary",2): return .castSanctuary(sacrifice:points[0],destination:points[1])
            case ("offering",1): return .castOffering(points[0])
            case ("doublePull",4): return .castDoublePull(.init(points[0],points[1]),.init(points[2],points[3]))
            case ("reformation",4): return .castReformation(.init(points[0],points[1]),.init(points[2],points[3]))
            case ("chainSwap",2): return .castChainSwap(first:points[0],second:points[1])
            case ("hunt",1): return .huntMonster(points[0])
            case ("bounce",2): return .useStickyBounce(anchor:points[0],target:points[1])
            case ("step",1): return .useShadowStep(points[0])
            case ("end",0): return .endTurn
            default: throw RecordError.invalidSetup
            }
        }
    }
    public struct Snapshot: Codable, Equatable, Sendable {
        public struct Loot: Codable, Equatable, Sendable { let ability: String, unlockPly: Int }
        public let board: String, current: Player, ply: Int, ap: Int, skillUsed: Bool, freeHunt: Bool
        public let mana: [Int], summoned: [Bool], loot: [[Loot]], status: GameStatus, winner: Player?, seals: [SealEffect]
        public init(_ s: GameState) {
            board = s.board.diagram; current = s.current; ply = s.ply; ap = s.apRemaining
            skillUsed = s.skillUsedThisTurn; freeHunt = s.awaitingFreeHunt
            mana = Player.allCases.map { s.mana(of:$0) }; summoned = Player.allCases.map { s.hasSummonedHero($0) }
            loot = Player.allCases.map { s.lootInventory(of:$0).map { Loot(ability:$0.ability.rawValue,unlockPly:$0.unlockPly) } }
            status = s.status; winner = s.winner; seals = s.seals
        }
    }
    public init(session: GameSession, computer: Player? = nil, difficulty: String? = nil) throws {
        self.computer = computer; self.difficulty = difficulty
        let s = session.state, c = s.config
        version = 1; rules = Self.rulesID; size = c.boardSize
        classOne = s.heroClass(of:.one); classTwo = s.heroClass(of:.two)
        advancedMana = c.expansionSkillManaCost; huntAP = c.monsterBattlefield?.huntAPCost
        monsters = c.monsterBattlefield?.monsters.map { Spawn(kind:$0.kind.rawValue,at:$0.position) } ?? []
        actions = try session.log.map(Action.init); expected = Snapshot(s)
        guard try config() == c else { throw RecordError.invalidSetup }
        // A diagram fixture without its real opening cannot be saved as a legal match.
        guard try rebuild().state == s else { throw RecordError.receiptMismatch(actions.count) }
    }
    public func config() throws -> RuleConfig {
        guard difficulty == nil || ["easy","standard"].contains(difficulty!) else { throw RecordError.invalidSetup }
        guard version == 1,rules == Self.rulesID else { throw RecordError.unsupportedVersion }
        guard [7,9].contains(size),[4,5].contains(advancedMana),classOne != .none,classTwo != .none,
              actions.count <= 500,monsters.count <= 2 else { throw RecordError.invalidSetup }
        var c = RuleConfig.board(size:size); c.expansionSkills = true; c.expansionSkillManaCost = advancedMana
        if monsters.isEmpty { guard huntAP == nil else { throw RecordError.invalidSetup } }
        else {
            guard size == 9,let huntAP,[0,1].contains(huntAP) else { throw RecordError.invalidSetup }
            let spawns = try monsters.map { m -> MonsterSpawn in
                guard let kind = MonsterKind(rawValue:m.kind) else { throw RecordError.invalidSetup }
                return MonsterSpawn(kind,at:m.at)
            }
            c.monsterBattlefield = .init(monsters:spawns,huntAPCost:huntAP,awardsLoot:true)
        }
        // Reject invalid spawns before constructing any caller-controlled board.
        _ = try GameSetup.newGame(config:c,classOne:classOne,classTwo:classTwo)
        return c
    }
    public func rebuild() throws -> GameSession {
        var s = GameSession(try GameSetup.newGame(config:config(),classOne:classOne,classTwo:classTwo))
        for (i,a) in actions.enumerated() {
            let action: GameAction
            do { action = try a.domain() } catch { throw RecordError.invalidAction(i) }
            guard s.apply(action).success else { throw RecordError.invalidAction(i) }
        }
        guard Snapshot(s.state) == expected else { throw RecordError.receiptMismatch(actions.count) }
        return s
    }
    public func data() throws -> Data {
        _ = try rebuild()
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys,.prettyPrinted]
        let data = try encoder.encode(self)
        guard data.count <= Self.byteLimit else { throw RecordError.oversized }
        return data
    }
    public static func read(_ data: Data) throws -> Self {
        guard data.count <= byteLimit else { throw RecordError.oversized }
        let record = try JSONDecoder().decode(Self.self,from:data)
        _ = try record.rebuild(); return record
    }
}
