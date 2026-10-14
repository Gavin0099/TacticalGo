import Foundation
import TacticalGoCore

func action(_ a: GameAction) -> [String: Any] {
    switch a {
    case .placeSoldier(let p): ["kind": "placeSoldier", "at": [p.x, p.y]]
    case .useStickyBounce(let a, let b): ["kind": "stickyBounce", "anchor": [a.x,a.y], "target": [b.x,b.y]]
    case .useShadowStep(let p): ["kind": "shadowStep", "at": [p.x,p.y]]
    case .summonHero(let p): ["kind": "summonHero", "at": [p.x,p.y]]
    case .huntMonster(let p): ["kind": "huntMonster", "at": [p.x, p.y]]
    case .endTurn: ["kind": "endTurn"]
    default: ["kind": "notUsedByProbe"]
    }
}
func receipt(_ s: GameState) -> [String: Any] {
    ["diagram": s.board.diagram, "current": s.current.name, "ply": s.ply, "ap": s.apRemaining,
     "mana": Player.allCases.map { s.mana(of: $0) },
     "loot": Player.allCases.map { player -> Any in
         guard s.lootInventory(of: player).count == 1, let loot = s.loot(of: player) else { return NSNull() }
         return ["ability": loot.ability.rawValue, "unlockPly": loot.unlockPly] as [String: Any]
     }, "lootInventory": Player.allCases.map { player in s.lootInventory(of: player).map { ["ability": $0.ability.rawValue, "unlockPly": $0.unlockPly] as [String:Any] } },
     "monsters": s.board.points.filter { s.board.monsters.contains($0) }.map { [$0.x,$0.y] },
     "awaitingFreeHunt": s.awaitingFreeHunt,
     "monster": (s.board.monsters.count == 1 ? s.board.monsters.first : nil).map { [$0.x, $0.y] as Any } ?? NSNull(), "status": s.status.rawValue]
}
func probe(cost: Int, at: Point, branch: String) throws -> [String: Any] {
    var c = RuleConfig.board(size: 9); c.monsterBattlefield = MonsterBattlefield(at: at, huntAPCost: cost)
    let initial = try GameSetup.newGame(config: c, classOne: .warrior, classTwo: .mage)
    var session = GameSession(initial)
    let opening: [GameAction] = [.placeSoldier(Point(at.x - 1, at.y)), .placeSoldier(Point(0, 0)),
                                 .endTurn, .placeSoldier(Point(at.x + 1, at.y))]
    var tail: [GameAction]
    switch branch {
    case "hunt": tail = [.huntMonster(at)]
    case "keep": tail = [.placeSoldier(Point(4, 6)), .endTurn]
    case "last-ap-hunt": tail = [.placeSoldier(Point(4, 6)), .huntMonster(at)]
    default: tail = []
    }
    var steps: [[String: Any]] = []
    for a in opening + tail {
        let before = session.state, o = session.apply(a)
        guard o.success else { throw NSError(domain: "MonsterProbeIllegalAction", code: 3, userInfo: ["reason": o.reason.rawValue]) }
        steps.append(["action": action(a), "actor": before.current.name, "accepted": o.success,
                      "reason": o.reason.rawValue, "events": o.events.map(\.name), "after": receipt(o.state)])
        // In the paid model, the last normal action hands over immediately; don't execute a hunt as white.
        if (branch == "last-ap-hunt" || branch == "keep") && steps.count == opening.count + 1 && o.state.current != .one { break }
    }
    let expected = session.state
    var replay = GameSession(initial)
    for a in session.log { guard replay.apply(a).success else { throw NSError(domain: "MonsterProbeReplay", code: 1) } }
    guard replay.state == expected else { throw NSError(domain: "MonsterProbeReceipt", code: 2) }
    return ["position": [at.x, at.y], "huntAPCost": cost, "branch": branch,
            "initial": receipt(initial), "steps": steps, "successfulReplay": true]
}
func lootProbe(kind: MonsterKind, cost: Int, at: Point, blocked: Bool) throws -> [String: Any] {
    var c = RuleConfig.board(size: 9)
    c.monsterBattlefield = MonsterBattlefield(at: at, huntAPCost: cost, kind: kind, awardsLoot: true)
    let initial = try GameSetup.newGame(config: c, classOne: .warrior, classTwo: .mage)
    var session = GameSession(initial)
    var steps: [[String: Any]] = []
    func step(_ a: GameAction, expected: IllegalReason = .none) throws {
        let before = session.state, o = session.apply(a)
        guard o.reason == expected else { throw NSError(domain: "LootProbeUnexpectedReason", code: 4, userInfo: ["reason": o.reason.rawValue]) }
        if expected != .none {
            guard o.state == before, o.events.isEmpty else { throw NSError(domain: "LootProbeRejectedMutation", code: 5) }
        }
        steps.append(["action": action(a), "actor": before.current.name, "accepted": o.success,
                      "reason": o.reason.rawValue, "events": o.events.map(\.name), "after": receipt(o.state)])
    }
    let opening: [GameAction] = kind == .slime
        ? [.placeSoldier(Point(at.x-1,4)), .placeSoldier(Point(0,0)), .endTurn, .placeSoldier(Point(at.x+1,4))]
        : [.placeSoldier(Point(at.x-1,5)), .placeSoldier(Point(0,0)), .endTurn, .summonHero(Point(at.x-1,4)), .endTurn, .endTurn, .placeSoldier(Point(at.x+1,4))]
    for a in opening { try step(a) }
    try step(.huntMonster(at))
    if cost == 0 { try step(.endTurn) }
    let destination = kind == .slime ? Point(at.x+2,4) : Point(at.x-1,2)
    if blocked { try step(.placeSoldier(destination)) }
    try step(.endTurn)
    if kind == .slime { try step(.placeSoldier(at)) }
    let ability: GameAction = kind == .slime ? .useStickyBounce(anchor: at, target: Point(at.x+1,4)) : .useShadowStep(destination)
    try step(ability, expected: blocked ? .occupied : .none)
    if blocked { guard session.state.loot(of: .one) != nil else { throw NSError(domain:"LootLost",code:6) } }
    else { guard session.state.loot(of: .one) == nil else { throw NSError(domain:"LootNotConsumed",code:7) } }
    var replay = GameSession(initial)
    for a in session.log { guard replay.apply(a).success else { throw NSError(domain: "LootProbeReplay", code: 8) } }
    guard replay.state == session.state else { throw NSError(domain: "LootProbeState", code: 9) }
    return ["kind":kind.rawValue,"position":[at.x,at.y],"huntAPCost":cost,"branch":blocked ? "opponent-block" : "use-loot",
            "initial":receipt(initial),"steps":steps,"successfulReplay":true]
}
func dualProbe(cost: Int, wolfFirst: Bool, branch: String) throws -> [String:Any] {
    let slime = Point(2,4), wolf = Point(6,4)
    var c = RuleConfig.board(size:9)
    c.monsterBattlefield = MonsterBattlefield(monsters:[MonsterSpawn(.slime,at:slime),MonsterSpawn(.shadowWolf,at:wolf)],huntAPCost:cost,awardsLoot:true)
    let initial = try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage)
    var session = GameSession(initial), steps: [[String:Any]] = []
    func require(_ value: Bool, _ message: String) throws {
        if !value { throw NSError(domain:message,code:10) }
    }
    func step(_ a: GameAction, expected: IllegalReason = .none) throws {
        let before = session.state, o = session.apply(a)
        try require(o.reason == expected,"DualUnexpectedReason_\(o.reason.rawValue)")
        if !o.success { try require(o.state == before && o.events.isEmpty,"DualRejectedMutation") }
        steps.append(["action":action(a),"actor":before.current.name,"accepted":o.success,"reason":o.reason.rawValue,"events":o.events.map(\.name),"after":receipt(o.state)])
    }
    for a: GameAction in [.placeSoldier(Point(1,4)),.placeSoldier(Point(0,0)),.endTurn,.placeSoldier(Point(3,4)),.placeSoldier(Point(5,5)),.endTurn,.summonHero(Point(5,4)),.placeSoldier(Point(7,4)),.endTurn] {
        if a == .endTurn && session.state.awaitingFreeHunt { try step(.endTurn) }
        try step(a)
    }
    let order = wolfFirst ? [wolf,slime] : [slime,wolf]
    if branch.hasPrefix("free-") {
        try step(.placeSoldier(Point(0,1))); try step(.placeSoldier(Point(0,2)))
        try require(session.state.awaitingFreeHunt && session.state.apRemaining == 0,"DualFreeWindowMissing")
        try step(.huntMonster(order[0]))
        try require(session.state.awaitingFreeHunt && session.state.board.monsters == Set([order[1]]),"DualFirstHuntWrong")
        try step(.placeSoldier(Point(0,3)),expected:.noActionPoints)
        let before = session.state
        try step(branch == "free-skip" ? .endTurn : .huntMonster(order[1]))
        let final = session.state
        try require(session.undo() && session.state == before,"DualWindowUndo")
        try require(session.apply(branch == "free-skip" ? .endTurn : .huntMonster(order[1])).success && session.state == final,"DualWindowRedo")
        try require(final.current == .two && !final.awaitingFreeHunt,"DualWindowHandoff")
        try require(final.lootInventory(of:.one).count == (branch == "free-skip" ? 1 : 2),"DualWindowLootCount")
    } else {
        for p in order { try step(.huntMonster(p)) }
        if cost == 0 { try step(.endTurn) }
        try step(.endTurn)
        for a: GameAction in [.placeSoldier(Point(1,5)),.endTurn,.endTurn] { try step(a) }
        try require(session.state.lootInventory(of:.one).count == 2 && session.state.lootInventory(of:.two).isEmpty,"DualInventoryOverwrite")
        let before = session.state
        let bounce = GameAction.useStickyBounce(anchor:Point(1,5),target:Point(1,4))
        let shadow = GameAction.useShadowStep(Point(5,2))
        let ability = branch == "bounce" ? bounce : shadow
        try step(ability)
        try require(session.state.lootInventory(of:.one).map(\.ability) == [branch == "bounce" ? .shadowStep : .stickyBounce],"DualWrongTokenConsumed")
        try step(branch == "bounce" ? shadow : bounce,expected:.skillAlreadyUsed)
        let final = session.state
        try require(session.undo() && session.state == before,"DualAbilityUndo")
        try require(session.apply(ability).success && session.state == final,"DualAbilityRedo")
    }
    var replay = GameSession(initial)
    for a in session.log { try require(replay.apply(a).success,"DualReplayIllegal") }
    try require(replay.state == session.state,"DualReplayState")
    return ["huntAPCost":cost,"wolfFirst":wolfFirst,"branch":branch,"initial":receipt(initial),"steps":steps,"successfulReplay":true,"successfulUndo":true]
}

func splitProbe(cost: Int) throws -> [String:Any] {
    let slime = Point(2,4), wolf = Point(6,4)
    var c = RuleConfig.board(size:9)
    c.monsterBattlefield = MonsterBattlefield(monsters:[MonsterSpawn(.slime,at:slime),MonsterSpawn(.shadowWolf,at:wolf)],huntAPCost:cost,awardsLoot:true)
    let initial = try GameSetup.newGame(config:c,classOne:.warrior,classTwo:.mage)
    var session = GameSession(initial), steps: [[String:Any]] = []
    func step(_ a: GameAction, expected: IllegalReason = .none) throws {
        let before = session.state, o = session.apply(a)
        guard o.reason == expected && (o.success || (o.state == before && o.events.isEmpty)) else { throw NSError(domain:"SplitIllegal_\(o.reason.rawValue)",code:11) }
        steps.append(["action":action(a),"actor":before.current.name,"accepted":o.success,"reason":o.reason.rawValue,"events":o.events.map(\.name),"after":receipt(o.state)])
    }
    for a: GameAction in [.placeSoldier(Point(1,4)),.placeSoldier(Point(5,5)),.summonHero(Point(5,4)),.placeSoldier(Point(3,4)),.placeSoldier(Point(0,1))] { try step(a) }
    if cost == 0 { try step(.endTurn) }
    try step(.placeSoldier(Point(7,4))); try step(.huntMonster(wolf))
    if cost == 0 { try step(.endTurn) }
    try step(.huntMonster(slime))
    guard session.state.lootInventory(of:.one).map(\.ability) == [.stickyBounce], session.state.lootInventory(of:.two).map(\.ability) == [.shadowStep] else { throw NSError(domain:"SplitOwnership",code:12) }
    try step(.useShadowStep(Point(5,2)),expected:.noMonsterLoot)
    try step(.endTurn)
    try step(.useStickyBounce(anchor:Point(5,5),target:Point(7,4)),expected:.noMonsterLoot)
    try step(.useShadowStep(Point(5,2)))
    guard session.state.lootInventory(of:.two).isEmpty && session.state.lootInventory(of:.one).count == 1 else { throw NSError(domain:"SplitConsumedOpponent",code:13) }
    try step(.endTurn)
    try step(.placeSoldier(Point(1,5))); try step(.useStickyBounce(anchor:Point(1,5),target:Point(1,4)))
    guard Player.allCases.allSatisfy({ session.state.lootInventory(of:$0).isEmpty }) else { throw NSError(domain:"SplitUnconsumed",code:14) }
    var replay = GameSession(initial)
    for a in session.log { guard replay.apply(a).success else { throw NSError(domain:"SplitReplay",code:15) } }
    guard replay.state == session.state else { throw NSError(domain:"SplitReplayState",code:16) }
    return ["huntAPCost":cost,"branch":"split-ownership","initial":receipt(initial),"steps":steps,"successfulReplay":true]
}

do {
    var runs: [[String: Any]] = []
    let includeLoot = CommandLine.arguments.contains("--loot")
    let includeDual = CommandLine.arguments.contains("--dual")
    if includeDual {
        for cost in [0,1] { for wolfFirst in [false,true] { for branch in ["bounce","step"] {
            runs.append(try dualProbe(cost:cost,wolfFirst:wolfFirst,branch:branch))
        } } }
        for cost in [0,1] { runs.append(try splitProbe(cost:cost)) }
        for wolfFirst in [false,true] { for branch in ["free-both","free-skip"] {
            runs.append(try dualProbe(cost:0,wolfFirst:wolfFirst,branch:branch))
        } }
    } else if includeLoot {
        for kind in MonsterKind.allCases { for p in [Point(4,4),Point(3,4)] { for cost in [0,1] { for blocked in [false,true] {
            runs.append(try lootProbe(kind: kind, cost: cost, at: p, blocked: blocked))
        } } } }
    } else {
    for p in [Point(4, 4), Point(3, 4)] {
        for cost in [0, 1] {
            for branch in ["hunt", "keep", "last-ap-hunt"] { runs.append(try probe(cost: cost, at: p, branch: branch)) }
        }
    }
    }
    let report: [String: Any] = ["schema": includeDual ? "monster-dual-probe-v1" : includeLoot ? "monster-loot-probe-v1" : "monster-cost-probe-v1", "runs": runs,
        "claimBoundary": "Legal opening replay and observable cost/timing only; no balance, human preference or optimal-strategy claim."]
    let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    if CommandLine.arguments.count > 1 { try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1])) }
    else { print(String(decoding: data, as: UTF8.self)) }
    print("PASS: \(runs.count) legal-opening branch probes; this does not establish whether hunting is worthwhile.")
} catch { print("Monster probe failed: \(error)"); exit(1) }
