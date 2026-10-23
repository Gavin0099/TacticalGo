import Foundation
import TacticalGoCore
import TacticalGoRecords
import P0Metrics

private enum AuditLimit: Error { case exhausted }
private final class SafetyAudit {
    let started=ProcessInfo.processInfo.systemUptime
    var explicitApplies=0,legalEnumerations=0,activeOwnTurns=0,rejectedActiveTurns=0
    var passSafe:Bool?,safeWitness:[GameAction]?,safeAfter:GameState?
    func check() throws {
        if explicitApplies >= 60_000 || ProcessInfo.processInfo.systemUptime-started > 30 { throw AuditLimit.exhausted }
    }
    func legal(_ s:GameState) throws -> [GameAction] {
        try check();legalEnumerations += 1
        let result=GameEngine.legalActions(s).filter { P0Metrics.isInCurrentMode($0,config:s.config) }
        // No enumeration cap or merging of different superko histories. Same action set as the current UI/Bot.
        try check();return result
    }
    func apply(_ s:GameState,_ a:GameAction) throws -> GameState {
        try check();explicitApplies += 1
        let result=GameEngine.apply(s,a)
        guard result.success else { throw StudyError.invalid("audit illegal action") };return result.state
    }
    func opponentCanWin(_ s:GameState,against me:Player) throws -> Bool {
        guard s.status == .ongoing else { return s.winner == me.opponent }
        guard s.current == me.opponent else { throw StudyError.invalid("audit needs completed own turn") }
        let enemy=s.current
        for first in try legal(s) {
            let one=try apply(s,first)
            if one.winner == enemy { return true }
            guard one.status == .ongoing,one.current == enemy else { continue }
            for second in try legal(one) {
                if try apply(one,second).winner == enemy { return true }
            }
        }
        return false
    }
    func inspect(_ actions:[GameAction],_ after:GameState,me:Player) throws -> Bool {
        activeOwnTurns += 1
        if try opponentCanWin(after,against:me) { rejectedActiveTurns += 1;return false }
        safeWitness=actions;safeAfter=after;return true
    }
    func run(_ root:GameState) throws {
        let me=root.current
        let passed=try apply(root,.endTurn)
        passSafe = try !opponentCanWin(passed,against:me)
        for first in try legal(root) where first != .endTurn {
            let one=try apply(root,first)
            if one.status != .ongoing || one.current != me {
                if try inspect([first],one,me:me) { return };continue
            }
            for second in try legal(one) {
                let two=try apply(one,second)
                guard two.status != .ongoing || two.current != me else { throw StudyError.invalid("audit partial turn") }
                if try inspect([first,second],two,me:me) { return }
            }
        }
    }
}

extension P0Runner {
    static func audit(_ dir:URL,turn:Int) throws {
        let (root,row)=try stateAt(dir,turn:turn)
        guard row["purePass"] as? Bool == true,root.ply <= root.config.maxPlies-4 else {
            throw StudyError.invalid("audit requires actual pure pass away from turn-cap boundary")
        }
        let audit=SafetyAudit()
        var completed=true
        do { try audit.run(root) } catch AuditLimit.exhausted { completed=false }
        let verdict:String
        if audit.safeWitness != nil { verdict="safe_nonpass_exists_for_one_complete_enemy_reply" }
        else if !completed { verdict="unknown_budget_or_time_limit" }
        else if audit.passSafe == true { verdict="only_pure_pass_survives_one_complete_enemy_reply" }
        else { verdict="all_complete_turns_allow_immediate_commander_loss" }
        try write(["game":dir.lastPathComponent,"turn":turn,"ply":root.ply,"sourceTurn":row,
            "verdict":verdict,"diagnosticCompletedWithinLimits":completed,
            "ownTurnsExhaustivelyEnumerated":completed && audit.safeWitness == nil,
            "passSurvivesOneReply":audit.passSafe as Any? ?? NSNull(),
            "activeOwnTurnsInspected":audit.activeOwnTurns,"activeTurnsWithWinningEnemyReply":audit.rejectedActiveTurns,
            "safeNonpassWitness":try audit.safeWitness.map { try $0.map { try object(ExpansionMatchRecord.Action($0)) } } as Any? ?? NSNull(),
            "safeAfter":try audit.safeAfter.map { try object(ExpansionMatchRecord.Snapshot($0)) } as Any? ?? NSNull(),
            "explicitApplies":audit.explicitApplies,"legalEnumerations":audit.legalEnumerations,
            "seconds":ProcessInfo.processInfo.systemUptime-audit.started,
            "limits":["explicitApplyCalls":60000,"seconds":30],
            "scope":"full official-opening superko history, uncapped current-mode legal actions, no state deduplication; immediate commander survival only",
            "notClaimed":["permanent stalemate","globally optimal play","safe witness is strategically better than pass","total Core work bounded by explicit applies"]],dir.appendingPathComponent("pass-audit-\(turn).json"))
        log("AUDIT \(dir.lastPathComponent) turn=\(turn) \(verdict) explicitApplies=\(audit.explicitApplies)")
    }
}
