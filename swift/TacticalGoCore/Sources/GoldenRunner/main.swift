import Foundation
import TacticalGoCore
import TacticalGoGolden

let arguments = Array(CommandLine.arguments.dropFirst())
let positional = arguments.filter { !$0.hasPrefix("--") }
let directory = URL(fileURLWithPath: positional.first ?? "tests/ios-golden")
do {
    let result = try GoldenReplay.run(directory: directory, transcript: positional.count > 1 ? URL(fileURLWithPath: positional[1]) : nil,
        defaultMageSkill: arguments.contains("--legacy-seal") ? .seal : .magicHand)
    print("PASS: \(result.fixtures) shared Golden fixtures, \(result.steps) steps (state, rejection and ordered events)")
} catch {
    print("FAIL: \(error)")
    exit(1)
}
