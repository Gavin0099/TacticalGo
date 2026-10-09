import Foundation
import TacticalGoCore

public struct GoldenFailure: Error, CustomStringConvertible {
    public let description: String
}
public enum GoldenReplay {
    public static func run(directory: URL, transcript: URL? = nil, defaultMageSkill: MageSkill = .magicHand) throws -> (fixtures: Int, steps: Int) {
        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        guard files.count >= 23 else { throw GoldenFailure(description: "Expected at least 23 canonical fixtures; got \(files.count)") }
        var steps = 0
        var records: [[String: Any]] = []
        for file in files { steps += try replay(file, records: &records, defaultMageSkill: defaultMageSkill) }
        if let transcript {
            try JSONSerialization.data(withJSONObject: records, options: [.sortedKeys, .prettyPrinted]).write(to: transcript)
        }
        return (files.count, steps)
    }
    public static func replay(_ file: URL, defaultMageSkill: MageSkill = .magicHand) throws -> Int {
        var records: [[String: Any]] = []
        return try replay(file, records: &records, defaultMageSkill: defaultMageSkill)
    }
    private static func replay(_ file: URL, records: inout [[String: Any]], defaultMageSkill: MageSkill) throws -> Int {
        let root = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        var config = RuleConfig(); config.mageSkill = defaultMageSkill
        for (key, value) in root["config"] as! [String: Any] {
            switch key {
            case "mageSkill": config.mageSkill = MageSkill(rawValue: value as! String)!
            case "magicHandRange": config.magicHandRange = value as! Int
            case "boardSize": config.boardSize = value as! Int
            case "apPerTurn": config.apPerTurn = value as! Int
            case "firstTurnAp": config.firstTurnAp = value is NSNull ? nil : value as? Int
            case "maxPlies": config.maxPlies = value as! Int
            case "manaCap": config.manaCap = value as! Int
            case "allowResummon": config.allowResummon = value as! Bool
            default: throw GoldenFailure(description: "Unknown config: \(key)")
            }
        }
        let setup = root["setup"] as! [String: Any]
        let classes = (setup["classes"] as! [String]).map { HeroClass(rawValue: $0)! }
        var state: GameState
        if setup["newGame"] as? Bool == true {
            state = try GameSetup.newGame(config: config, classOne: classes[0], classTwo: classes[1])
        } else {
            var rows = (setup["diagram"] as! [String]).map { $0.filter { !$0.isWhitespace } }
            while rows.count < config.boardSize { rows.append("") }
            rows = rows.map { $0.padding(toLength: config.boardSize, withPad: ".", startingAt: 0) }
            let mana = setup["mana"] as! [Int], summoned = setup["heroSummoned"] as! [Bool]
            state = try GameSetup.fromDiagram(config: config, diagram: rows.joined(separator: "\n"),
                classOne: classes[0], classTwo: classes[1], current: setup["current"] as! String == "One" ? .one : .two,
                manaOne: mana[0], manaTwo: mana[1], ap: setup["ap"] as? Int, summonedOne: summoned[0], summonedTwo: summoned[1])
        }
        if let expected = root["expectInitial"] as? [String: Any] { try check(expected, state, nil, file.lastPathComponent + " initial") }
        records.append(snapshot(file.lastPathComponent, 0, state, nil))
        let steps = root["steps"] as! [[String: Any]]
        for (i, step) in steps.enumerated() {
            let a = step["action"] as! [String: Any]
            func at(_ key: String) -> Point { let xy = a[key] as! [Int]; return Point(xy[0], xy[1]) }
            let action: GameAction
            switch a["type"] as! String {
            case "PlaceSoldier": action = .placeSoldier(at("at"))
            case "SummonHero": action = .summonHero(at("at"))
            case "CastBastion": action = .castBastion(at("first"), at("second"))
            case "CastSeal": action = .castSeal(at("at"))
            case "CastSwap": action = .castSwap(at("target"))
            case "CastMagicHand": action = .castMagicHand(at("target"), PushDirection(rawValue: a["direction"] as! String) ?? .invalid)
            case "EndTurn": action = .endTurn
            default: throw GoldenFailure(description: "Unknown action")
            }
            let before = state
            let outcome = GameEngine.apply(state, action)
            if !outcome.success && (outcome.state != before || !outcome.events.isEmpty) {
                throw GoldenFailure(description: "\(file.lastPathComponent) step \(i + 1): rejection mutated state/history or emitted events")
            }
            state = outcome.state
            try check(step["expect"] as! [String: Any], state, outcome, "\(file.lastPathComponent) step \(i + 1)")
            records.append(snapshot(file.lastPathComponent, i + 1, state, outcome))
        }
        return steps.count
    }
    private static func xy(_ p: Point) -> [Int] { [p.x, p.y] }
    private static func event(_ e: ActionEvent) -> [String: Any] {
        var d: [String: Any] = ["type": e.name]
        switch e {
        case .resourcesSpent(let p, let ap, let mana): d.merge(["player": p.name, "ap": ap, "mana": mana]) { _, b in b }
        case .piecePlaced(let p, let at, let kind): d.merge(["player": p.name, "at": xy(at), "kind": kind.rawValue]) { _, b in b }
        case .piecesSwapped(let p, let a, let b): d.merge(["player": p.name, "a": xy(a), "b": xy(b)]) { _, b in b }
        case .sealPlaced(let caster, let blocked, let at): d.merge(["caster": caster.name, "blocked": blocked.name, "at": xy(at)]) { _, b in b }
        case .sealExpired(let at): d["at"] = xy(at)
        case .piecePushed(let caster, let from, let to, let piece):
            d.merge(["caster": caster.name, "from": xy(from), "to": xy(to), "owner": piece.owner.name, "kind": piece.kind.rawValue]) { _, b in b }
        case .piecesCaptured(let p, let pieces):
            d["player"] = p.name
            d["pieces"] = pieces.map { ["at": xy($0.at), "owner": $0.piece.owner.name, "kind": $0.piece.kind.rawValue] as [String: Any] }
        case .turnEnded(let p, let ply): d.merge(["player": p.name, "ply": ply]) { _, b in b }
        case .turnStarted(let p, let ply, let ap, let mana): d.merge(["player": p.name, "ply": ply, "ap": ap, "mana": mana]) { _, b in b }
        case .gameWon(let p): d["winner"] = p.name
        case .gameDrawn(let reason): d["reason"] = reason
        }
        return d
    }
    private static func snapshot(_ file: String, _ step: Int, _ s: GameState, _ o: ActionOutcome?) -> [String: Any] {
        ["fixture": file, "step": step, "ok": o?.success ?? true, "reason": o?.reason.rawValue ?? "None",
         "diagram": s.board.diagram, "current": s.current.name, "ply": s.ply, "ap": s.apRemaining,
         "mana": [s.mana(of: .one), s.mana(of: .two)], "classes": [s.heroClass(of: .one).rawValue, s.heroClass(of: .two).rawValue],
         "summoned": [s.hasSummonedHero(.one), s.hasSummonedHero(.two)], "skill": s.skillUsedThisTurn,
         "status": s.status.rawValue, "winner": s.winner?.name as Any? ?? NSNull(),
         "seals": s.seals.map { ["at": xy($0.at), "caster": $0.caster.name, "blocked": $0.blockedPlayer.name] as [String: Any] },
         "events": o?.events.map(event) ?? []]
    }
    private static func check(_ expected: [String: Any], _ s: GameState, _ o: ActionOutcome?, _ context: String) throws {
        for (key, value) in expected {
            let actual: Any
            switch key {
            case "ok": actual = o!.success
            case "reason": actual = o!.reason.rawValue
            case "current": actual = s.current.name
            case "ply": actual = s.ply
            case "ap": actual = s.apRemaining
            case "status": actual = s.status.rawValue
            case "winner": actual = s.winner?.name as Any? ?? NSNull()
            case "mana": actual = [s.mana(of: .one), s.mana(of: .two)]
            case "seals":
                let expectedPoints = (value as! [[Int]]).map { "\($0[0]),\($0[1])" }.sorted()
                let actualPoints = s.seals.map { "\($0.at.x),\($0.at.y)" }.sorted()
                guard expectedPoints == actualPoints else { throw GoldenFailure(description: "\(context) seals: \(actualPoints) != \(expectedPoints)") }
                continue
            case "groups":
                for (xy, points) in value as! [String: [[Int]]] {
                    let p = xy.split(separator: ",").map { Int($0)! }
                    let expected = Set(points.map { Point($0[0], $0[1]) })
                    guard Set(s.board.group(at: Point(p[0], p[1]))) == expected else { throw GoldenFailure(description: context + " group mismatch " + xy) }
                }; continue
            case "skillUsed": actual = s.skillUsedThisTurn
            case "liberties":
                for (xy, count) in value as! [String: Int] {
                    let p = xy.split(separator: ",").map { Int($0)! }
                    guard s.board.liberties(at: Point(p[0], p[1])).count == count else { throw GoldenFailure(description: context + " liberty mismatch " + xy) }
                }; continue
            case "events": actual = o!.events.map(\.name)
            case "cells":
                for (xy, symbol) in value as! [String: String] {
                    let p = xy.split(separator: ",").map { Int($0)! }
                    let actual = String(Board.symbol(s.board[Point(p[0], p[1])]))
                    guard actual == symbol else { throw GoldenFailure(description: "\(context) cell \(xy): \(actual) != \(symbol)") }
                }
                continue
            default: throw GoldenFailure(description: "\(context): unknown expectation \(key)")
            }
            guard (actual as! NSObject).isEqual(value) else { throw GoldenFailure(description: "\(context) \(key): \(actual) != \(value)") }
        }
    }
}
