import Foundation
import TacticalGoCore

// Independent bounded tactical witness enumeration, without the production beam or evaluator.
// Core still owns all rules. No win witness in the next enemy turn is not long-term safety.
enum AuditError: Error { case replay, illegal }
func decode(_ v: [String:Any]) throws -> GameAction {
    func p(_ key: String) -> Point { let a = v[key] as! [Int]; return Point(a[0],a[1]) }
    switch v["kind"] as! String {
    case "placeSoldier": return .placeSoldier(p("at"))
    case "summonHero": return .summonHero(p("at"))
    case "castBastion": return .castBastion(p("a"),p("b"))
    case "castMagicHand": return .castMagicHand(p("at"),PushDirection(rawValue:v["direction"] as! String)!)
    case "castFriendlyRedeploy": return .castFriendlyRedeploy(p("from"),p("to"))
    case "castSwap": return .castSwap(p("at"))
    case "castSeal": return .castSeal(p("at"))
    case "endTurn": return .endTurn
    default: throw AuditError.replay
    }
}
let args = CommandLine.arguments
let source = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[1]))) as! [String:Any]
let setup = source["setup"] as! [String:Any], target = Int(args[2])!
var config = RuleConfig.board(size: 7)
if setup["rules"] as? String == "candidate" { config.bastionScope = .connectedGroup; config.experimentalFriendlyRedeploy = true }
var root = try GameSetup.newGame(config:config,classOne:HeroClass(rawValue:setup["classOne"] as! String)!,classTwo:HeroClass(rawValue:setup["classTwo"] as! String)!)
for turn in source["turns"] as! [[String:Any]] {
    if root.ply == target {break}
    for item in turn["actions"] as! [[String:Any]] {
        let result = GameEngine.apply(root,try decode(item["action"] as! [String:Any]))
        guard result.success, result.state.board.diagram == item["boardAfter"] as! String,
              result.events.map({String(reflecting:$0)}) == item["eventPayloads"] as! [String] else {throw AuditError.replay}
        root = result.state
    }
}
guard root.ply == target, root.apRemaining <= 2 else {throw AuditError.replay}
let me = root.current
var turns: [(GameState,[GameAction])] = []
for first in GameEngine.legalActions(root) {
    let a = GameEngine.apply(root,first); guard a.success else {throw AuditError.illegal}
    if a.state.status != .ongoing || a.state.current != me { turns.append((a.state,[first])); continue }
    for second in GameEngine.legalActions(a.state) {
        let b = GameEngine.apply(a.state,second); guard b.success else {throw AuditError.illegal}
        guard b.state.status != .ongoing || b.state.current != me else {throw AuditError.replay}
        turns.append((b.state,[first,second]))
    }
}
var rows: [[String:Any]] = [], checks = 0
for (after, actions) in turns {
    var witness: [GameAction] = []
    if after.status == .ongoing {
        for first in GameEngine.legalActions(after) {
            let a = GameEngine.apply(after,first); checks += 1
            if a.state.winner == me.opponent { witness = [first]; break }
            if a.state.status == .ongoing && a.state.current == me.opponent {
                for second in GameEngine.legalActions(a.state) {
                    let b = GameEngine.apply(a.state,second); checks += 1
                    if b.state.winner == me.opponent { witness = [first,second]; break }
                }
            }
            if !witness.isEmpty {break}
        }
    }
    rows.append(["actions":actions.map{String(reflecting:$0)},"board":after.board.diagram,
        "eventsEndState":String(reflecting:after.status),"commanderLiberties":after.board.find(me,.commander).map{after.board.liberties(at:$0).count} ?? 0,
        "ownHeroPresent":after.board.find(me,.hero) != nil,"enemyWinWitness":witness.map{String(reflecting:$0)},
        "immediateOwnWin":after.winner == me,"mana":after.mana(of:me)])
}
let noWitness = rows.filter{ ($0["enemyWinWitness"] as! [String]).isEmpty }
let report: [String:Any] = ["source":args[1],"ply":target,"board":root.board.diagram,"completeOwnTurns":rows.count,
    "withoutEnemyNextTurnWinWitness":noWitness.count,"replyApplyChecks":checks,"rows":rows,
    "scope":"All legal own turns of up to two actions, including voluntary endTurn; for every turn all enemy up-to-two-action replies until first win witness. No heuristic pruning. No witness is only absence of a next-turn commander capture, not proof of safety or strategic quality."]
try JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]).write(to:URL(fileURLWithPath:args[3]))
print("PASS ply \(target): \(rows.count) full own turns; \(noWitness.count) without next enemy turn win witness; \(checks) reply checks")
