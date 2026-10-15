import Foundation
import XCTest
@testable import TacticalGoAccess

private enum StorageFailure: Error { case read, write }

private final class MemoryPersistence: AccessLedgerPersistence {
    var data: Data?
    var saveCount = 0
    var failRead = false
    var failWrite = false

    func load() throws -> Data? {
        if failRead { throw StorageFailure.read }
        return data
    }

    func save(_ data: Data) throws {
        if failWrite { throw StorageFailure.write }
        self.data = data
        saveCount += 1
    }
}

@MainActor
final class AccessLedgerTests: XCTestCase {
    private func finishTrial(_ store: AccessLedgerStore, id: UUID = UUID()) throws {
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .trial)
        XCTAssertTrue(try store.completeMatch(id: id))
    }

    private func exhaustedStore(_ storage: MemoryPersistence) throws -> AccessLedgerStore {
        let store = try AccessLedgerStore(storage: storage)
        for _ in 0..<3 { try finishTrial(store) }
        return store
    }

    func testFreshInstallationPersistsExactlyThreeCompletedGameAllowance() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        XCTAssertEqual(storage.saveCount, 1)
        XCTAssertNotNil(storage.data)
        XCTAssertEqual(store.snapshot.completedTrialMatches, 0)
        XCTAssertEqual(store.snapshot.remainingTrialMatches, 3)
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
        XCTAssertEqual(store.newMatchAccess(isUnlocked: false), .trial(remainingCompletedMatches: 3))
    }

    func testThirdActualCompletionGatesNewMatchWithoutChangingCounterOnBegin() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        for completed in 0..<3 {
            let id = UUID()
            XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .trial)
            XCTAssertEqual(store.snapshot.completedTrialMatches, completed)
            XCTAssertTrue(try store.completeMatch(id: id))
            XCTAssertEqual(store.snapshot.remainingTrialMatches, 2 - completed)
        }
        let before = storage.data
        XCTAssertEqual(store.newMatchAccess(isUnlocked: false), .requiresRewardOrPurchase)
        XCTAssertThrowsError(try store.beginMatch(id: UUID(), isUnlocked: false)) {
            XCTAssertEqual($0 as? AccessLedgerError, .accessRequired)
        }
        XCTAssertEqual(storage.data, before)
        XCTAssertEqual(store.snapshot.registeredMatches, 3)
    }

    func testUnfinishedOrAbandonedBattleDoesNotConsumeCompletedQuota() async throws {
        let store = try AccessLedgerStore(storage: MemoryPersistence())
        let unfinished = UUID()
        _ = try store.beginMatch(id: unfinished, isUnlocked: false)
        _ = try store.beginMatch(id: UUID(), isUnlocked: false)
        XCTAssertEqual(store.snapshot.remainingTrialMatches, 3)
        XCTAssertEqual(try store.beginMatch(id: unfinished, isUnlocked: false), .trial)
    }

    func testLegacyUnregisteredCompletionIsNotRetroactivelyChargedOrSaved() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let before = storage.data
        XCTAssertFalse(try store.completeMatch(id: UUID()))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 0)
        XCTAssertEqual(storage.saveCount, 1)
        XCTAssertEqual(storage.data, before)
    }

    func testTutorialAndChallengesRemainUnmeteredAfterTrialEnds() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        for kind: AccessMatchKind in [.tutorial, .challenge] {
            let id = UUID()
            XCTAssertEqual(try store.beginMatch(id: id, kind: kind, isUnlocked: false), .notMetered)
            XCTAssertTrue(try store.completeMatch(id: id))
        }
        XCTAssertEqual(store.snapshot.completedTrialMatches, 3)
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
    }

    func testRepeatedBeginOfSameUnfinishedIDDoesNotSaveOrConsumeAgain() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let id = UUID()
        _ = try store.beginMatch(id: id, isUnlocked: false)
        let saves = storage.saveCount
        for _ in 0..<4 { XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .trial) }
        XCTAssertEqual(storage.saveCount, saves)
        XCTAssertEqual(store.snapshot.registeredMatches, 1)
    }

    func testUndoAndRepeatedTerminalReceiptCannotChargeSameMatchTwiceAfterReload() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let id = UUID()
        try finishTrial(store, id: id)
        XCTAssertFalse(try store.completeMatch(id: id))
        let restored = try AccessLedgerStore(storage: storage)
        let before = storage.data
        XCTAssertFalse(try restored.completeMatch(id: id))
        XCTAssertEqual(restored.snapshot.completedTrialMatches, 1)
        XCTAssertEqual(storage.data, before)
    }

    func testCompletedUUIDCannotBeReusedToBypassNewGameGate() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let id = UUID()
        try finishTrial(store, id: id)
        XCTAssertThrowsError(try store.beginMatch(id: id, isUnlocked: false)) {
            XCTAssertEqual($0 as? AccessLedgerError, .completedMatchCannotRestart)
        }
    }

    func testPreviouslyAdmittedUnfinishedMatchCanResumeAfterThirdCompletion() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let continuing = UUID()
        _ = try store.beginMatch(id: continuing, isUnlocked: false)
        for _ in 0..<3 { try finishTrial(store) }
        let restored = try AccessLedgerStore(storage: storage)
        XCTAssertEqual(restored.newMatchAccess(isUnlocked: false), .requiresRewardOrPurchase)
        XCTAssertEqual(try restored.beginMatch(id: continuing, isUnlocked: false), .trial)
        XCTAssertTrue(try restored.completeMatch(id: continuing))
        XCTAssertEqual(restored.snapshot.remainingTrialMatches, 0)
    }

    func testMatchUUIDCannotChangeFromBattleToUnmeteredKind() async throws {
        let store = try AccessLedgerStore(storage: MemoryPersistence())
        let id = UUID()
        _ = try store.beginMatch(id: id, isUnlocked: false)
        XCTAssertThrowsError(try store.beginMatch(id: id, kind: .tutorial, isUnlocked: false)) {
            XCTAssertEqual($0 as? AccessLedgerError, .matchKindMismatch)
        }
    }

    func testVerifiedPurchaseDoesNotConsumeTrialOrPersistEntitlementForNextLaunch() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let id = UUID()
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: true), .unlocked)
        XCTAssertTrue(try store.completeMatch(id: id))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 3)
        let restored = try AccessLedgerStore(storage: storage)
        XCTAssertEqual(restored.newMatchAccess(isUnlocked: false), .requiresRewardOrPurchase)
        XCTAssertEqual(restored.newMatchAccess(isUnlocked: true), .unlocked)
        XCTAssertThrowsError(try restored.beginMatch(id: UUID(), isUnlocked: false))
    }

    func testRevocationDoesNotInterruptAlreadyAdmittedBattleOrSpendReservedAdCredit() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let request = UUID()
        XCTAssertTrue(try store.grantReward(requestID: request))
        let id = UUID()
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: true), .unlocked)
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .unlocked)
        XCTAssertEqual(store.snapshot.rewardCredits, 1)
        XCTAssertEqual(store.newMatchAccess(isUnlocked: false), .rewardCredit)
    }

    func testRewardRequestCanGrantOnlyOnceEvenAfterReservationAndReload() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let request = UUID()
        XCTAssertTrue(try store.grantReward(requestID: request))
        XCTAssertFalse(try store.grantReward(requestID: request))
        XCTAssertEqual(store.snapshot.rewardCredits, 1)
        XCTAssertEqual(try store.beginMatch(id: UUID(), isUnlocked: false), .rewarded)
        let restored = try AccessLedgerStore(storage: storage)
        let before = storage.data
        XCTAssertFalse(try restored.grantReward(requestID: request))
        XCTAssertEqual(restored.snapshot.rewardCredits, 0)
        XCTAssertEqual(storage.data, before)
    }

    func testRewardReservationIsIdempotentAndCannotAdmitSecondUUID() async throws {
        let store = try exhaustedStore(MemoryPersistence())
        _ = try store.grantReward(requestID: UUID())
        let id = UUID()
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .rewarded)
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .rewarded)
        XCTAssertThrowsError(try store.beginMatch(id: UUID(), isUnlocked: false))
        XCTAssertTrue(try store.completeMatch(id: id))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 3)
    }

    func testSeparateCompletedAdsGrantSeparateGamesNotOneReusableUnlock() async throws {
        let store = try exhaustedStore(MemoryPersistence())
        for _ in 0..<2 { XCTAssertTrue(try store.grantReward(requestID: UUID())) }
        XCTAssertEqual(store.snapshot.rewardCredits, 2)
        for expected in [1, 0] {
            let id = UUID()
            XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .rewarded)
            XCTAssertEqual(store.snapshot.rewardCredits, expected)
            XCTAssertTrue(try store.completeMatch(id: id))
        }
        XCTAssertEqual(store.newMatchAccess(isUnlocked: false), .requiresRewardOrPurchase)
    }

    func testTrialStartDoesNotSpendPreviouslyEarnedRewardCredit() async throws {
        let store = try AccessLedgerStore(storage: MemoryPersistence())
        _ = try store.grantReward(requestID: UUID())
        _ = try store.beginMatch(id: UUID(), isUnlocked: false)
        XCTAssertEqual(store.snapshot.rewardCredits, 1)
    }

    func testFailedBeginPersistenceDoesNotReserveCreditOrAdmitUUID() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        _ = try store.grantReward(requestID: UUID())
        let before = storage.data
        let snapshot = store.snapshot
        storage.failWrite = true
        let id = UUID()
        XCTAssertThrowsError(try store.beginMatch(id: id, isUnlocked: false))
        XCTAssertEqual(store.snapshot, snapshot)
        XCTAssertEqual(storage.data, before)
        storage.failWrite = false
        XCTAssertEqual(try store.beginMatch(id: id, isUnlocked: false), .rewarded)
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
    }

    func testFailedCompletionPersistenceKeepsQuotaAndAllowsRetryExactlyOnce() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let id = UUID()
        _ = try store.beginMatch(id: id, isUnlocked: false)
        let before = storage.data
        storage.failWrite = true
        XCTAssertThrowsError(try store.completeMatch(id: id))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 0)
        XCTAssertEqual(storage.data, before)
        storage.failWrite = false
        XCTAssertTrue(try store.completeMatch(id: id))
        XCTAssertFalse(try store.completeMatch(id: id))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 1)
    }

    func testFailedRewardPersistenceDoesNotGrantVolatileCreditOrMarkRequestUsed() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let request = UUID()
        let before = storage.data
        storage.failWrite = true
        XCTAssertThrowsError(try store.grantReward(requestID: request))
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
        XCTAssertEqual(storage.data, before)
        storage.failWrite = false
        XCTAssertTrue(try store.grantReward(requestID: request))
        XCTAssertFalse(try store.grantReward(requestID: request))
        XCTAssertEqual(store.snapshot.rewardCredits, 1)
    }

    func testFirstWriteFailureCannotGrantAnUnpersistedNewTrial() async throws {
        let storage = MemoryPersistence()
        storage.failWrite = true
        XCTAssertThrowsError(try AccessLedgerStore(storage: storage))
        XCTAssertNil(storage.data)
    }

    func testReadFailureCannotBeTreatedAsMissingInstallation() async throws {
        let storage = MemoryPersistence()
        storage.failRead = true
        XCTAssertThrowsError(try AccessLedgerStore(storage: storage))
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testCorruptExistingBytesArePreservedInsteadOfResetToFreeQuota() async throws {
        let storage = MemoryPersistence()
        storage.data = Data("invalid ledger".utf8)
        let before = storage.data
        XCTAssertThrowsError(try AccessLedgerStore(storage: storage)) {
            XCTAssertEqual($0 as? AccessLedgerError, .corruptData)
        }
        XCTAssertEqual(storage.data, before)
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testUnknownSchemaCannotSilentlyRewriteOrDowngradeLedger() async throws {
        let storage = MemoryPersistence()
        storage.data = Data(#"{"schemaVersion":99,"matches":[],"rewardRequests":[]}"#.utf8)
        let before = storage.data
        XCTAssertThrowsError(try AccessLedgerStore(storage: storage)) {
            XCTAssertEqual($0 as? AccessLedgerError, .unsupportedVersion(99))
        }
        XCTAssertEqual(storage.data, before)
        XCTAssertEqual(storage.saveCount, 0)
    }

    func testInvalidStoredAccountingInvariantsFailClosed() async throws {
        let matchID = "00000000-0000-0000-0000-000000000001"
        let rewardID = "00000000-0000-0000-0000-000000000002"
        let entry: [String: Any] = [
            "id": matchID, "kind": "battle", "authorization": "trial", "completed": false
        ]
        let invalidFixtures: [[String: Any]] = [
            ["schemaVersion": 1, "matches": [entry, entry], "rewardRequests": []],
            ["schemaVersion": 1, "matches": [], "rewardRequests": [rewardID, rewardID]],
            ["schemaVersion": 1, "matches": [[
                "id": matchID, "kind": "battle", "authorization": "notMetered", "completed": false
            ]], "rewardRequests": []],
            ["schemaVersion": 1, "matches": [[
                "id": matchID, "kind": "tutorial", "authorization": "trial", "completed": false
            ]], "rewardRequests": []],
            ["schemaVersion": 1, "matches": [[
                "id": matchID, "kind": "battle", "authorization": "rewarded", "completed": false,
                "rewardRequestID": rewardID
            ]], "rewardRequests": []],
            ["schemaVersion": 1, "matches": [[
                "id": matchID, "kind": "battle", "authorization": "trial", "completed": false,
                "rewardRequestID": rewardID
            ]], "rewardRequests": [rewardID]],
            ["schemaVersion": 1, "matches": [
                ["id": matchID, "kind": "battle", "authorization": "rewarded",
                 "completed": false, "rewardRequestID": rewardID],
                ["id": "00000000-0000-0000-0000-000000000003", "kind": "battle",
                 "authorization": "rewarded", "completed": false, "rewardRequestID": rewardID]
            ], "rewardRequests": [rewardID]]
        ]
        for fixture in invalidFixtures {
            let storage = MemoryPersistence()
            storage.data = try JSONSerialization.data(withJSONObject: fixture)
            let before = storage.data
            XCTAssertThrowsError(try AccessLedgerStore(storage: storage)) {
                XCTAssertEqual($0 as? AccessLedgerError, .corruptData)
            }
            XCTAssertEqual(storage.data, before)
            XCTAssertEqual(storage.saveCount, 0)
        }
    }

    func testRealAtomicFileRoundTripRetainsCompletedIDsAndReservedReward() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("access/ledger-v1.json")
        let storage = FileAccessLedgerPersistence(fileURL: url)
        let store = try AccessLedgerStore(storage: storage)
        for _ in 0..<3 { try finishTrial(store) }
        let request = UUID(), id = UUID()
        _ = try store.grantReward(requestID: request)
        _ = try store.beginMatch(id: id, isUnlocked: false)
        let restored = try AccessLedgerStore(storage: FileAccessLedgerPersistence(fileURL: url))
        XCTAssertEqual(restored.snapshot.completedTrialMatches, 3)
        XCTAssertEqual(restored.snapshot.rewardCredits, 0)
        XCTAssertEqual(try restored.beginMatch(id: id, isUnlocked: false), .rewarded)
        XCTAssertFalse(try restored.grantReward(requestID: request))
        XCTAssertTrue(try restored.completeMatch(id: id))
        let files = try FileManager.default.contentsOfDirectory(atPath: url.deletingLastPathComponent().path)
        XCTAssertEqual(files, ["ledger-v1.json"])
    }

    func testRealCorruptFileIsUntouchedAndNeverReinitialized() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("ledger.json")
        let corrupt = Data("broken existing installation".utf8)
        try corrupt.write(to: url)
        XCTAssertThrowsError(try AccessLedgerStore(storage: FileAccessLedgerPersistence(fileURL: url)))
        XCTAssertEqual(try Data(contentsOf: url), corrupt)
    }

    func testRealDiskInitializationFailurePreservesBlockingFileAndGrantsNoStore() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blockedDirectory = directory.appendingPathComponent("access")
        let existingBytes = Data("existing file cannot become a directory".utf8)
        try existingBytes.write(to: blockedDirectory)
        let storage = FileAccessLedgerPersistence(fileURL: blockedDirectory.appendingPathComponent("ledger.json"))
        XCTAssertThrowsError(try AccessLedgerStore(storage: storage))
        XCTAssertEqual(try Data(contentsOf: blockedDirectory), existingBytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["access"])
    }

    // MARK: C0 / M6 option (a): a playable copy continues its parent's single admission.

    func testTrialCopyIsTheSameAdmissionAndItsCompletionSettlesTheParentExactlyOnce() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let parent = UUID(), copy = UUID()
        XCTAssertEqual(try store.beginMatch(id: parent, isUnlocked: false), .trial)
        XCTAssertTrue(try store.beginContinuation(id: copy, of: parent))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 0)
        XCTAssertEqual(store.snapshot.remainingTrialMatches, 3, "creating the copy must not use the allowance")
        XCTAssertTrue(try store.completeMatch(id: copy))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 1, "one match, one admission")
        // Finishing the original too, or reloading, cannot charge a second time.
        XCTAssertFalse(try store.completeMatch(id: parent))
        let reloaded = try AccessLedgerStore(storage: storage)
        XCTAssertEqual(reloaded.snapshot.completedTrialMatches, 1)
        XCTAssertThrowsError(try reloaded.beginMatch(id: parent, isUnlocked: false)) {
            XCTAssertEqual($0 as? AccessLedgerError, .completedMatchCannotRestart)
        }
    }

    func testRewardedParentCopyNeverReservesASecondReward() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let request = UUID()
        XCTAssertTrue(try store.grantReward(requestID: request))
        let parent = UUID(), copy = UUID()
        XCTAssertEqual(try store.beginMatch(id: parent, isUnlocked: false), .rewarded)
        XCTAssertEqual(store.snapshot.rewardCredits, 0)
        XCTAssertTrue(try store.grantReward(requestID: UUID()))            // an unrelated, later reward
        XCTAssertTrue(try store.beginContinuation(id: copy, of: parent))
        XCTAssertEqual(store.snapshot.rewardCredits, 1, "the copy must not spend the later reward")
        XCTAssertEqual(try store.beginMatch(id: copy, isUnlocked: false), .rewarded, "same authorization as its parent")
        XCTAssertTrue(try store.completeMatch(id: copy))
        XCTAssertEqual(store.snapshot.rewardCredits, 1)
        XCTAssertEqual(store.snapshot.completedTrialMatches, 3)
    }

    func testCopyOfAnUnregisteredParentStaysUnmeteredAndWritesNothing() async throws {
        let storage = MemoryPersistence()
        let store = try exhaustedStore(storage)
        let before = storage.data
        XCTAssertFalse(try store.beginContinuation(id: UUID(), of: UUID()))
        XCTAssertEqual(storage.data, before)
    }

    func testCopyOfACompletedParentIsRejected() async throws {
        let store = try AccessLedgerStore(storage: MemoryPersistence())
        let parent = UUID()
        try finishTrial(store, id: parent)
        XCTAssertThrowsError(try store.beginContinuation(id: UUID(), of: parent)) {
            XCTAssertEqual($0 as? AccessLedgerError, .completedMatchCannotRestart)
        }
    }

    func testContinuationIsIdempotentAndChainsCollapseToTheOriginalAdmission() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let parent = UUID(), copy = UUID(), copyOfCopy = UUID()
        XCTAssertEqual(try store.beginMatch(id: parent, isUnlocked: false), .trial)
        XCTAssertTrue(try store.beginContinuation(id: copy, of: parent))
        let saved = storage.saveCount
        XCTAssertTrue(try store.beginContinuation(id: copy, of: parent))
        XCTAssertEqual(storage.saveCount, saved, "repeating the link must not write")
        XCTAssertThrowsError(try store.beginContinuation(id: copy, of: UUID()))
        XCTAssertTrue(try store.beginContinuation(id: copyOfCopy, of: copy))
        XCTAssertTrue(try store.completeMatch(id: copyOfCopy))
        XCTAssertEqual(store.snapshot.completedTrialMatches, 1)
        XCTAssertFalse(try store.completeMatch(id: parent), "the root was settled by the last copy")
    }

    func testFailedContinuationWriteLeavesNothingRegistered() async throws {
        let storage = MemoryPersistence()
        let store = try AccessLedgerStore(storage: storage)
        let parent = UUID(), copy = UUID()
        XCTAssertEqual(try store.beginMatch(id: parent, isUnlocked: false), .trial)
        storage.failWrite = true
        XCTAssertThrowsError(try store.beginContinuation(id: copy, of: parent))
        XCTAssertFalse(store.isRegistered(id: copy))
        storage.failWrite = false
        XCTAssertTrue(try store.beginContinuation(id: copy, of: parent), "retry succeeds exactly once")
    }

    func testStoredContinuationWithoutAMatchingParentFailsClosed() async throws {
        let matchID = "00000000-0000-0000-0000-000000000001"
        let orphan = "00000000-0000-0000-0000-000000000009"
        let fixtures: [[String: Any]] = [
            ["schemaVersion": 1, "matches": [[
                "id": matchID, "kind": "battle", "authorization": "trial", "completed": false, "continuationOf": orphan
            ]], "rewardRequests": []],
            ["schemaVersion": 1, "matches": [
                ["id": orphan, "kind": "battle", "authorization": "trial", "completed": false],
                ["id": matchID, "kind": "battle", "authorization": "unlocked", "completed": false, "continuationOf": orphan]
            ], "rewardRequests": []]
        ]
        for fixture in fixtures {
            let storage = MemoryPersistence()
            storage.data = try JSONSerialization.data(withJSONObject: fixture)
            XCTAssertThrowsError(try AccessLedgerStore(storage: storage)) {
                XCTAssertEqual($0 as? AccessLedgerError, .corruptData)
            }
        }
    }
}
