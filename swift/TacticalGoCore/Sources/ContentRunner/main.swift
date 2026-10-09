import Foundation
import TacticalGoCore
import TacticalGoContent

func point(_ p: Point) -> [Int] { [p.x, p.y] }
func maybePoint(_ p: Point?) -> Any { p.map(point) ?? NSNull() as Any }
func points(_ list: [Point]) -> [[Int]] { list.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }.map(point) }
func piece(_ p: Piece) -> [String: Any] { ["owner": p.owner.rawValue, "kind": p.kind.rawValue] }
func action(_ a: GameAction) -> [String: Any] {
    switch a {
    case .placeSoldier(let p): ["type": "placeSoldier", "point": point(p)]
    case .summonHero(let p): ["type": "summonHero", "point": point(p)]
    case .castBastion(let a, let b): ["type": "castBastion", "points": [point(a), point(b)]]
    case .castMagicHand(let p, let d): ["type": "castMagicHand", "point": point(p), "direction": d.rawValue]
    case .castFriendlyRedeploy(let from, let to): ["type": "castFriendlyRedeploy", "from": point(from), "to": point(to)]
    case .castSwap(let p): ["type": "castSwap", "point": point(p)]
    case .castSeal(let p): ["type": "castSeal", "point": point(p)]
    case .endTurn: ["type": "endTurn"]
    }
}
func event(_ e: ActionEvent) -> [String: Any] {
    var row: [String: Any] = ["type": e.name]
    switch e {
    case .resourcesSpent(let p, let ap, let mana): row.merge(["player": p.rawValue, "ap": ap, "mana": mana]) { _, new in new }
    case .piecePlaced(let p, let at, let kind): row.merge(["player": p.rawValue, "at": point(at), "kind": kind.rawValue]) { _, new in new }
    case .piecesSwapped(let p, let a, let b): row.merge(["player": p.rawValue, "from": point(a), "to": point(b)]) { _, new in new }
    case .piecePushed(let caster, let from, let to, let victim): row.merge(["player": caster.rawValue, "from": point(from), "to": point(to), "piece": piece(victim)]) { _, new in new }
    case .sealPlaced(let p, let blocked, let at): row.merge(["player": p.rawValue, "blocked": blocked.rawValue, "at": point(at)]) { _, new in new }
    case .sealExpired(let p): row["at"] = point(p)
    case .piecesCaptured(let p, let captured): row["player"] = p.rawValue; row["pieces"] = captured.map { ["at": point($0.at), "piece": piece($0.piece)] as [String: Any] }
    case .turnEnded(let p, let ply): row["player"] = p.rawValue; row["ply"] = ply
    case .turnStarted(let p, let ply, let ap, let mana): row.merge(["player": p.rawValue, "ply": ply, "ap": ap, "mana": mana]) { _, new in new }
    case .gameWon(let p): row["player"] = p.rawValue
    case .gameDrawn(let why): row["reason"] = why
    }
    return row
}
func state(_ s: GameState) -> [String: Any] {
    var groups: [[String: Any]] = [], seen = Set<Point>()
    for at in s.board.points where s.board[at] != nil && !seen.contains(at) {
        let group = s.board.group(at: at); seen.formUnion(group)
        groups.append(["owner": s.board[at]!.owner.rawValue, "points": points(group), "liberties": points(Array(s.board.liberties(at: at)))])
    }
    return ["diagram": s.board.diagram, "boardSize": s.board.size, "current": s.current.rawValue, "ply": s.ply,
            "ap": s.apRemaining, "mana": [s.mana(of: .one), s.mana(of: .two)], "skillUsedThisTurn": s.skillUsedThisTurn,
            "heroSummoned": [s.hasSummonedHero(.one), s.hasSummonedHero(.two)], "status": s.status.rawValue,
            "winner": s.winner.map { $0.rawValue as Any } ?? NSNull(),
            "commanderOne": maybePoint(s.board.find(.one, .commander)), "commanderTwo": maybePoint(s.board.find(.two, .commander)),
            "heroOne": maybePoint(s.board.find(.one, .hero)), "heroTwo": maybePoint(s.board.find(.two, .hero)), "groups": groups]
}
func assessment(_ a: TutorialAssessment) -> [String: Any] {
    switch a { case .completed: ["status": a.label]; case .incomplete(let why), .failed(let why): ["status": a.label, "reason": why] }
}
enum EvidenceFailure: Error { case illegal(String), mismatch(String), usage }

func run() throws {
    let args = Array(CommandLine.arguments.dropFirst())
    guard args.isEmpty || (args.count == 2 && args[0] == "--output") else { throw EvidenceFailure.usage }
    var rows: [[String: Any]] = []
    for scenario in try TutorialCatalog.all() {
        var core = try GameSetup.newGame(config: scenario.config, classOne: scenario.heroClass, classTwo: .none)
        let initial = state(core)
        var source: [[String: Any]] = []
        for (index, a) in scenario.sourceActions.enumerated() {
            let before = core, result = GameEngine.apply(core, a)
            guard result.success else { throw EvidenceFailure.illegal("source \(scenario.id)/\(index): \(result.reason)") }
            core = result.state
            source.append(["index": index, "actor": before.current.rawValue, "action": action(a), "before": state(before), "after": state(core), "events": result.events.map(event), "reason": result.reason.rawValue])
        }
        guard core == (try TutorialReplay.start(scenario)) else { throw EvidenceFailure.mismatch("source \(scenario.id)") }
        var branches: [[String: Any]] = []
        for branch in scenario.branches {
            var session = try TutorialSession(scenario), replay = core
            var steps: [[String: Any]] = []
            for (index, a) in branch.actions.enumerated() {
                let before = replay, expected = GameEngine.apply(replay, a), result = session.apply(a)
                guard expected.success && result == expected else { throw EvidenceFailure.illegal("branch \(scenario.id)/\(branch.name)/\(index): \(result.reason)") }
                replay = result.state
                steps.append(["index": index, "actor": before.current.rawValue, "action": action(a), "before": state(before), "after": state(replay), "events": result.events.map(event), "assessment": assessment(session.assessment), "playerActions": session.playerActionCount, "reason": result.reason.rawValue])
            }
            guard session.assessment.label == branch.expected else { throw EvidenceFailure.mismatch("goal \(scenario.id)/\(branch.name)") }
            branches.append(["name": branch.name, "explanation": branch.explanation, "expected": branch.expected, "assessment": assessment(session.assessment), "steps": steps])
        }
        rows.append(["id": scenario.id, "title": scenario.title, "instructions": scenario.instructions, "heroClass": scenario.heroClass.rawValue, "goal": scenario.goal.rawValue, "optionalHints": scenario.optionalHints, "canonicalSolution": scenario.canonicalSolution.map(action), "canonicalSkillHint": action(scenario.openingSkill), "initial": initial, "source": source, "lessonStart": state(core), "branches": branches])
    }
    let report: [String: Any] = ["schema": "tacticalgo-content-evidence-v2", "coordinateConvention": "zero-based x,y; Player one=0/two=1; soldier=0/commander=1/hero=2", "provenance": "GameSetup.newGame with RuleConfig.board(size:7), classTwo:none; every source and branch step applied to unchanged Core", "rules": ["boardSize": 7, "apPerTurn": 2, "firstTurnAp": 1, "mageSkill": "MagicHand", "bastionScope": "heroAdjacent", "magicHandDestination": "emptyOnly", "skillManaCost": 2, "allowResummon": false], "goalContract": "Any legal selected-class skill plus another non-endTurn player action, in either order, on the original lesson-start ply, satisfying observable Core group/liberty/capture outcomes. Canonical examples do not gate completion; no unique soldier identity is invented.", "scope": "Mechanical replay legality and objective evidence. No UI, autonomous enemy, human enjoyment or balance claim.", "scenarios": rows]
    let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    if args.count == 2 {
        try data.write(to: URL(fileURLWithPath: args[1]), options: .atomic)
        print("PASS: \(rows.count) official sources, \(rows.reduce(0) { $0 + (($1["branches"] as? [[String: Any]])?.count ?? 0) }) Core-validated branches; evidence: \(args[1])")
    } else { FileHandle.standardOutput.write(data); FileHandle.standardOutput.write(Data("\n".utf8)) }
}
do { try run() }
catch { FileHandle.standardError.write(Data("CONTENT-01 failed: \(error)\nUsage: tacticalgo-content [--output path]\n".utf8)); exit(1) }
