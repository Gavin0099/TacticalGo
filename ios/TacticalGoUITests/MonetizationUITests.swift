import Foundation
import StoreKit
import StoreKitTest
import XCTest

/// Local StoreKit transactions plus the same real board receipts used by ordinary play.
/// Run serially: SKTestSession controls the test StoreKit database for this simulator.
/// No test here claims production purchases, advertising reward validity or revenue.
@MainActor final class MonetizationUITests: XCTestCase {
    private let productID = "com.tacticalgo.crowntactics.unlock"

    func testThreeRealCompletedBattlesGateFourthAndCancelPreservesResult() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let game = launch()
        defer { game.terminate() }
        assertRemainingTrialMatches(game, 3)
        startLocalBattle(game)
        for completed in 1...3 {
            winFromFormalOpening(game)
            XCTAssertEqual(game.staticTexts["resultTitle"].label, "黑方獲勝")
            screenshot("ACCESS-1024-completed-\(completed)")
            if completed < 3 {
                game.buttons["resultRematch"].tap()
                XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
                XCTAssertFalse(game.staticTexts["unlockTitle"].exists)
            }
        }
        game.buttons["resultRematch"].tap()
        assertGate(game)
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        screenshot("ACCESS-1024-fourth-game-gated")
        game.buttons["unlockDismiss"].tap()
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["resultTitle"].label, "黑方獲勝")
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "終局棋盤")
        game.buttons["resultRecords"].tap()
        let replays = game.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'replay-'"))
        XCTAssertTrue(replays.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(replays.count, 3, "A declined new game must not overwrite or create a fourth record")
        game.buttons["recordsDone"].tap()
        exitToHome(game)
        assertRemainingTrialMatches(game, 0)
    }

    func testExhaustedGateCanCancelWithoutChangingExistingUnfinishedGame() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let isolation = UUID().uuidString
        let game = launch(isolation: isolation)
        defer { game.terminate() }
        startLocalBattle(game)
        tapBoard(game, 0, 0)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        let turn = game.staticTexts["currentTurn"].label
        XCTAssertTrue(turn.contains("白方"))
        exitToHome(game)
        game.terminate()
        game.launchArguments = arguments(isolation: isolation, extra: ["--monetization-exhausted"])
        game.launch()
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 10))
        assertRemainingTrialMatches(game, 0)
        startLocalBattle(game)
        assertGate(game)
        game.buttons["unlockDismiss"].tap()
        XCTAssertTrue(game.buttons["lobbyHomeBack"].waitForExistence(timeout: 5))
        game.buttons["lobbyHomeBack"].tap()
        game.buttons["resumeMatch"].tap()
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turn)
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        tapBoard(game, 0, 0)
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["playMessage"].label.contains("已有棋子"))
        screenshot("ACCESS-1024-gated-cancel-original-board-retained")
    }

    func testTeachingAndBothChallengeChaptersRemainReachableAfterTrial() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let game = launch(extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        assertRemainingTrialMatches(game, 0)
        game.buttons["startOnboarding"].tap()
        XCTAssertTrue(game.staticTexts["onboardTitle"].waitForExistence(timeout: 10))
        XCTAssertFalse(game.staticTexts["unlockTitle"].exists)
        game.buttons["onboardExit"].tap()
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "英雄技能入門")
        let challenge = game.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'challenge-'" )).firstMatch
        XCTAssertTrue(challenge.waitForExistence(timeout: 5))
        challenge.tap()
        XCTAssertTrue(game.otherElements["challengeArena"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.staticTexts["unlockTitle"].exists)
        game.buttons["challengeBack"].tap()
        game.buttons["challengeChapter-advanced"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        let advanced = game.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'challenge-'" )).firstMatch
        XCTAssertTrue(advanced.waitForExistence(timeout: 5))
        advanced.tap()
        XCTAssertTrue(game.otherElements["challengeArena"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.staticTexts["unlockTitle"].exists)
        game.buttons["challengeBack"].tap()
        game.buttons["challengeBack"].tap()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 5))
        assertRemainingTrialMatches(game, 0)
        screenshot("ACCESS-1024-teaching-and-challenges-free")
    }

    func testRealUIPurchaseUnlocksBattleAndVerifiedEntitlementSurvivesRelaunch() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let isolation = UUID().uuidString
        let game = launch(isolation: isolation, extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        startLocalBattle(game)
        assertGate(game)
        waitForEnabled(game.buttons["unlockPurchase"], timeout: 15)
        game.buttons["unlockPurchase"].tap()
        try waitForPlayableBattle(game, timeout: 20)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        let purchased = session.allTransactions().filter { $0.productIdentifier == productID && $0.state == .purchased }
        XCTAssertEqual(purchased.count, 1, "The app purchase must produce an actual local StoreKit transaction")
        tapBoard(game, 0, 0)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"), "A verified purchase must permit an actual committed first action")
        screenshot("ACCESS-1024-storekit-purchase-real-action")
        exitToHome(game)
        game.terminate()
        game.launchArguments = arguments(isolation: isolation, extra: ["--monetization-exhausted"])
        game.launch()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 10))
        startLocalBattle(game)
        try waitForPlayableBattle(game, timeout: 15)
    }

    /// INTEG-ACCESS-01 review P1: interrupted-start recovery discards unadmitted, unplayed starts. An owner is never
    /// metered, so for an owner it must wait for the StoreKit check instead of reading "not verified yet" as "not an owner".
    func testOwnerInterruptedStartIsKeptNotDiscardedByLaunchRecovery() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        _ = try await session.buyProduct(identifier: productID)
        let game = launch(extra: ["--seed-interrupted-start"])
        defer { game.terminate() }
        try waitForAccessLabel(game, "已永久解鎖")
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 5),
                      "the owner's unplayed start must survive launch recovery")
    }

    func testRealRestoreUpdatesEntitlementAndPermitsAnActualBattle() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let game = launch(extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        startLocalBattle(game)
        assertGate(game)
        let transaction = try await session.buyProduct(identifier: productID)
        XCTAssertEqual(transaction.productID, productID)
        XCTAssertEqual(transaction.productType, .nonConsumable)
        XCTAssertTrue(game.buttons["accessContinue"].waitForExistence(timeout: 15))
        game.buttons["restorePurchases"].tap()
        waitForMessage(game, containing: "已恢復購買", timeout: 15)
        game.buttons["accessContinue"].tap()
        try waitForPlayableBattle(game)
        tapBoard(game, 0, 0)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
        screenshot("ACCESS-1024-restored-owner-real-battle")
    }

    func testRefundRevokesNextNewGameWithoutInterruptingExistingSave() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        _ = try await session.buyProduct(identifier: productID)
        let isolation = UUID().uuidString
        let game = launch(isolation: isolation, extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        startLocalBattle(game)
        try waitForPlayableBattle(game)
        tapBoard(game, 0, 0)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        let turn = game.staticTexts["currentTurn"].label
        let transaction = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == productID })
        try session.refundTransaction(identifier: transaction.identifier)
        XCTAssertTrue(game.buttons["mode-soldier"].isEnabled, "Revocation must not interrupt this admitted match")
        exitToHome(game)
        game.terminate()
        game.launchArguments = arguments(isolation: isolation, extra: ["--monetization-exhausted"])
        game.launch()
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 10))
        startLocalBattle(game)
        assertGate(game)
        game.buttons["unlockDismiss"].tap()
        game.buttons["lobbyHomeBack"].tap()
        game.buttons["resumeMatch"].tap()
        try waitForPlayableBattle(game)
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turn)
        tapBoard(game, 0, 0)
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["playMessage"].label.contains("已有棋子"))
        screenshot("ACCESS-1024-refund-gates-new-game-keeps-old-save")
    }

    func testRefundUpdateRevokesNewGamesInSameSessionAndKeepsAdmittedBattlePlayable() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        _ = try await session.buyProduct(identifier: productID)
        let game = launch(extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        try waitForAccessLabel(game, "已永久解鎖")
        startLocalBattle(game)
        try waitForPlayableBattle(game)
        tapBoard(game, 0, 0)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        let turn = game.staticTexts["currentTurn"].label
        XCTAssertTrue(turn.contains("白方"))
        let transaction = try XCTUnwrap(session.allTransactions().first {
            $0.productIdentifier == productID && $0.state == .purchased
        })
        try session.refundTransaction(identifier: transaction.identifier)
        // Transaction.updates must revoke new-match access without killing the admitted game.
        // No app termination or launch-time entitlement refresh may hide a broken update listener.
        try waitForPlayableBattle(game)
        exitToHome(game)
        try waitForAccessLabel(game, "免費完整對局剩餘 0／3")
        startLocalBattle(game)
        assertGate(game)
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        game.buttons["unlockDismiss"].tap()
        XCTAssertTrue(game.buttons["lobbyHomeBack"].waitForExistence(timeout: 5))
        game.buttons["lobbyHomeBack"].tap()
        game.buttons["resumeMatch"].tap()
        try waitForPlayableBattle(game)
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turn)
        tapBoard(game, 0, 0)
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["playMessage"].label.contains("已有棋子"))
        screenshot("ACCESS-1024-same-session-refund-gates-new-keeps-admitted-board")
    }

    func testAskToBuyStaysLockedUntilStoreKitApprovalThenCanPlay() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        session.askToBuyEnabled = true
        let game = launch(extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        startLocalBattle(game)
        assertGate(game)
        waitForEnabled(game.buttons["unlockPurchase"], timeout: 15)
        game.buttons["unlockPurchase"].tap()
        waitForMessage(game, containing: "等待批准", timeout: 15)
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        XCTAssertTrue(game.staticTexts["unlockTitle"].exists)
        let pending = try XCTUnwrap(session.allTransactions().first {
            $0.productIdentifier == productID && $0.pendingAskToBuyConfirmation
        })
        screenshot("ACCESS-1024-ask-to-buy-pending-no-unlock")
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        XCTAssertTrue(game.buttons["accessContinue"].waitForExistence(timeout: 15))
        game.buttons["accessContinue"].tap()
        try waitForPlayableBattle(game)
        tapBoard(game, 0, 0)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
        screenshot("ACCESS-1024-ask-to-buy-approved-real-battle")
    }

    func testStoreKitCancelledAndNetworkFailedPurchaseNeverGrantAccess() async throws {
        let session = try storeKitSession()
        defer { session.clearTransactions(); session.resetToDefaultState() }
        let game = launch(extra: ["--monetization-exhausted"])
        defer { game.terminate() }
        startLocalBattle(game)
        assertGate(game)
        waitForEnabled(game.buttons["unlockPurchase"], timeout: 15)
        // Apple's local StoreKit error injection exercises the real purchase API, not a paid test flag.
        try await session.setSimulatedError(SKTestFailures.Purchase.generic(.userCancelled), forAPI: .purchase)
        game.buttons["unlockPurchase"].tap()
        waitForNonBusyPurchaseFailure(game)
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        XCTAssertTrue(game.staticTexts["unlockTitle"].exists)
        XCTAssertFalse(session.allTransactions().contains { $0.productIdentifier == productID && $0.state == .purchased })
        screenshot("ACCESS-1024-storekit-cancel-no-unlock")
        try await session.setSimulatedError(
            SKTestFailures.Purchase.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase
        )
        game.buttons["unlockPurchase"].tap()
        waitForNonBusyPurchaseFailure(game)
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        XCTAssertTrue(game.staticTexts["unlockTitle"].exists)
        XCTAssertFalse(session.allTransactions().contains { $0.productIdentifier == productID && $0.state == .purchased })
        screenshot("ACCESS-1024-storekit-network-failure-no-unlock")
        game.buttons["unlockDismiss"].tap()
        game.buttons["lobbyHomeBack"].tap()
        assertRemainingTrialMatches(game, 0)
        XCTAssertFalse(game.buttons["resumeMatch"].exists, "Failed purchases cannot create a battle record")
    }

    private func storeKitSession() throws -> SKTestSession {
        continueAfterFailure = false
        let configuration = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Monetization", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: configuration)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.storefront = "TWN"
        session.locale = Locale(identifier: "zh_TW")
        return session
    }

    private func arguments(isolation: String, extra: [String]) -> [String] {
        extra + ["--record-isolation", isolation, "--cozy-reduced"]
    }

    private func launch(isolation: String = UUID().uuidString, extra: [String] = []) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let game = XCUIApplication()
        game.launchArguments = arguments(isolation: isolation, extra: extra)
        game.launch()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 15))
        XCTAssertTrue(game.staticTexts["accessStatus"].exists)
        return game
    }

    private func startLocalBattle(_ game: XCUIApplication) {
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupLocal"].waitForExistence(timeout: 5))
        game.buttons["setupLocal"].tap()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 5))
        if game.buttons["startMatch"].label.contains("下一步") { game.buttons["startMatch"].tap() }
        XCTAssertTrue(game.buttons["startMatch"].label.contains("開始對局"))
        game.buttons["startMatch"].tap()
    }

    private func assertGate(_ game: XCUIApplication) {
        XCTAssertTrue(game.staticTexts["unlockTitle"].waitForExistence(timeout: 15))
        XCTAssertTrue(game.buttons["unlockDismiss"].isHittable)
        XCTAssertTrue(game.buttons["watchRewardedAd"].exists)
        XCTAssertTrue(game.buttons["restorePurchases"].exists)
        XCTAssertTrue(game.staticTexts["monetizationTestNotice"].exists)
    }

    private func assertRemainingTrialMatches(_ game: XCUIApplication, _ count: Int) {
        XCTAssertTrue(game.staticTexts["accessStatus"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["accessStatus"].label, "免費完整對局剩餘 \(count)／3")
    }

    private func winFromFormalOpening(_ game: XCUIApplication) {
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        // Existing reviewed eight-action opening: four black liberties around the white commander,
        // interleaved with distant, legal white placements. The engine creates the actual capture.
        let actions = [(3, 0), (0, 6), (1, 6), (2, 1), (4, 1), (0, 5), (1, 5), (3, 2)]
        for (index, point) in actions.enumerated() {
            tapBoard(game, point.0, point.1)
            XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
            game.buttons["playConfirm"].tap()
            if index < actions.count - 1 { waitForBattleReady(game) }
        }
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 10))
    }

    private func exitToHome(_ game: XCUIApplication) {
        game.buttons["返回選角"].tap()
        XCTAssertTrue(game.buttons["exitMatchConfirmed"].waitForExistence(timeout: 5))
        game.buttons["exitMatchConfirmed"].tap()
        XCTAssertTrue(game.buttons["lobbyHomeBack"].waitForExistence(timeout: 5))
        game.buttons["lobbyHomeBack"].tap()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 5))
    }

    private func tapBoard(_ game: XCUIApplication, _ x: Int, _ y: Int) {
        let arena = game.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        let row = Double(y) / 6
        let inset = 0.13 - 0.06 * row
        let point = CGVector(dx: inset + (1 - 2 * inset) * Double(x) / 6, dy: 0.18 + 0.65 * row)
        arena.coordinate(withNormalizedOffset: point).tap()
    }

    private func waitForBattleReady(_ game: XCUIApplication) {
        waitForEnabled(game.buttons["mode-soldier"], timeout: 10)
    }

    private enum FlowFailure: Error {
        case playableBattleDidNotBecomeInteractive
        case accessLabelDidNotUpdate(String)
    }

    private func waitForPlayableBattle(_ game: XCUIApplication, timeout: TimeInterval = 15) throws {
        // The board can enter the accessibility tree beneath a dismissing StoreKit/access sheet.
        // Existence alone does not establish a completed handoff or prove a player can act.
        let expectations = [
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: game.staticTexts["unlockTitle"]),
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"), object: game.otherElements["playArena"]),
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true AND enabled == true"), object: game.buttons["mode-soldier"])
        ]
        guard XCTWaiter.wait(for: expectations, timeout: timeout) == .completed else {
            // Throw stops this async method, preventing cascaded taps after an interrupted assertion.
            throw FlowFailure.playableBattleDidNotBecomeInteractive
        }
    }

    private func waitForAccessLabel(_ game: XCUIApplication, _ label: String, timeout: TimeInterval = 15) throws {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND label == %@", label),
            object: game.staticTexts["accessStatus"]
        )
        guard XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed else {
            throw FlowFailure.accessLabelDidNotUpdate(label)
        }
    }

    private func waitForEnabled(_ element: XCUIElement, timeout: TimeInterval) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND enabled == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    private func waitForMessage(_ game: XCUIApplication, containing text: String, timeout: TimeInterval) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND label CONTAINS %@", text), object: game.staticTexts["accessMessage"])
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    private func waitForNonBusyPurchaseFailure(_ game: XCUIApplication) {
        XCTAssertTrue(game.staticTexts["accessMessage"].waitForExistence(timeout: 15))
        waitForEnabled(game.buttons["unlockPurchase"], timeout: 15)
        let message = game.staticTexts["accessMessage"].label
        XCTAssertTrue(message.contains("取消") || message.contains("未完成"))
        XCTAssertFalse(game.descendants(matching: .any)["accessBusy"].exists)
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
