import Foundation
import TacticalGoRecords

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("Usage: tacticalgo-records <exported-match.json>\n".utf8))
    exit(2)
}
do {
    let record = try MatchRecord.decode(Data(contentsOf:URL(fileURLWithPath:CommandLine.arguments[1])))
    let replay = try record.rebuild()
    let result: [String: Any] = [
        "validated": true, "schema": record.schema, "rules": record.rules.rawValue,
        "actions": record.steps.count, "frames": replay.1.count,
        "status": replay.0.state.status.rawValue, "current": replay.0.state.current.rawValue,
        "ap": replay.0.state.apRemaining, "manaOne": replay.0.state.mana(of:.one), "manaTwo": replay.0.state.mana(of:.two),
        "canUndo": replay.0.canUndo, "finalBoard": replay.0.state.board.diagram,
        "steps": record.steps.enumerated().map { i,s in
            ["index":i+1,"actor":s.actor.rawValue,"action":s.action.label,"difficulty":s.difficulty,"events":s.events,"decision":s.decision ?? ""] as [String:Any]
        }
    ]
    FileHandle.standardOutput.write(try JSONSerialization.data(withJSONObject:result,options:[.prettyPrinted,.sortedKeys]))
    print("")
} catch {
    FileHandle.standardError.write(Data("Record rejected: \(error)\n".utf8))
    exit(1)
}
