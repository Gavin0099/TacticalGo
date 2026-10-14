import Foundation
import Observation
import TacticalGoAccess

@MainActor @Observable final class PlayAccess {
    let purchase = UnlockPurchase()
    private(set) var remainingTrialMatches = 3
    private(set) var rewardCredits = 0
    private(set) var errorMessage: String?
    @ObservationIgnored private var ledger: AccessLedgerStore?

    init() {
        var directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/Access-v1", isDirectory: true)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        // UI tests must never overwrite the owner's real trial ledger.
        if let i = args.firstIndex(of: "--record-isolation"), args.indices.contains(i + 1), let id = UUID(uuidString: args[i + 1]) {
            directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/TestAccess/" + id.uuidString, isDirectory: true)
        }
        #endif
        do {
            ledger = try AccessLedgerStore(storage: FileAccessLedgerPersistence(fileURL: directory.appendingPathComponent("ledger.json")))
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--monetization-exhausted"), directory.path.contains("/TestAccess/") {
                for _ in 0..<(ledger?.snapshot.remainingTrialMatches ?? 0) {
                    let id = UUID()
                    _ = try ledger?.beginMatch(id: id, kind: .battle, isUnlocked: false)
                    _ = try ledger?.completeMatch(id: id)
                }
            }
            #endif
            updateSnapshot()
        } catch {
            errorMessage = "無法讀取遊玩額度；資料已保留。既有存局仍可續玩，也可恢復購買。"
        }
    }

    var canStartMatch: Bool {
        if purchase.isUnlocked { return true }
        guard let ledger, errorMessage == nil else { return false }
        return ledger.newMatchAccess(isUnlocked: false) != .requiresRewardOrPurchase
    }

    func authorizeNewMatch(id: UUID) throws {
        // A verified permanent owner can play even when the unrelated trial file is damaged.
        if purchase.isUnlocked { return }
        guard let ledger else { throw AccessLedgerError.corruptData }
        _ = try ledger.beginMatch(id: id, kind: .battle, isUnlocked: false)
        updateSnapshot()
    }

    /// nil when the ledger cannot be read (then no recovery decision may be taken from it).
    func registration(of id: UUID) -> Bool? {
        guard let ledger, errorMessage == nil else { return nil }
        return ledger.isRegistered(id: id)
    }

    /// C0 / M6 (a): a playable copy continues its parent's admission; it never takes a second one.
    func continueMatch(copy id: UUID, of parent: UUID) throws {
        guard let ledger else { throw AccessLedgerError.corruptData }
        _ = try ledger.beginContinuation(id: id, of: parent)
        updateSnapshot()
    }

    func completedMatch(id: UUID) {
        guard let ledger else { return }
        do { _ = try ledger.completeMatch(id: id); updateSnapshot() }
        catch { errorMessage = "本局額度未能保存；原棋局已保留。請稍後重試。" }
    }

    /// These IDs come only from validated, persisted terminal records. Unknown
    /// legacy IDs remain unmetered; this retries a completion interrupted after
    /// the chess record was saved but before the separate ledger write finished.
    func reconcileCompletedMatches(ids: [UUID]) {
        guard let ledger else { return }
        do {
            for id in ids { _ = try ledger.completeMatch(id: id) }
            updateSnapshot()
        } catch { errorMessage = "完成對局的額度尚未能保存；存局已保留。請稍後重試。" }
    }

    func earnedReward(requestID: UUID) throws {
        guard let ledger else { throw AccessLedgerError.corruptData }
        _ = try ledger.grantReward(requestID: requestID)
        updateSnapshot()
    }

    private func updateSnapshot() {
        guard let ledger else { return }
        remainingTrialMatches = ledger.snapshot.remainingTrialMatches
        rewardCredits = ledger.snapshot.rewardCredits
        errorMessage = nil
    }
}
