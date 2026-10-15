import XCTest

/// Opt-in network checks. These use Google's real Debug test ad, never a reward injection.
/// A provider/consent failure is a failed completion check, not a successful rewarded-ad run.
@MainActor final class RewardedAdNetworkUITests: XCTestCase {
    func testRealSDKAdvertisementCompletionOpensOneMatch() throws {
        continueAfterFailure = false
        let game = openExhaustedTrial()
        game.buttons["watchRewardedAd"].tap()

        // Google-owned test creative varies. Keep the original hierarchy as evidence;
        // never tap a guessed screen coordinate or accept a timer as a reward.
        // Observed Google end card exposes its visible close as WebView StaticText,
        // while a separate native "Close Advertisement" button may stay disabled.
        let closeLabels = ["Close Advertisement", "Close", "Close ad", "Close button", "關閉", "關閉廣告"]
        let closeControls = closeLabels.map { game.buttons.matching(identifier: $0).firstMatch }
            + closeLabels.map { game.webViews.staticTexts.matching(identifier: $0).firstMatch }
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            game.staticTexts["Test mode"].exists
                && closeControls.contains { $0.exists && $0.isEnabled && $0.isHittable }
        }, object: game)
        let appeared = XCTWaiter.wait(for: [ready], timeout: 60) == .completed
        capture(game, "REWARDED-1024-provider-presentation")
        if !appeared {
            let providerMessage = game.staticTexts["accessMessage"].exists
                ? game.staticTexts["accessMessage"].label : "SDK creative has no accessible close control"
            XCTFail("Actual rewarded advertisement unavailable/uninspectable: " + providerMessage)
            return
        }

        // Give this real test creative playback time. Completion is still determined exclusively
        // by the SDK callback plus the persisted access layer, and asserted below.
        let wait = expectation(description: "real test creative playback")
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) { wait.fulfill() }
        waitForExpectations(timeout: 30)
        let usable = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            closeControls.contains { $0.exists && $0.isEnabled && $0.isHittable }
        }, object: game)
        XCTAssertEqual(XCTWaiter.wait(for: [usable], timeout: 20), .completed,
                       "Google's close control must be usable")
        // Query by stable label again after playback: Google's creative may replace its
        // web end card with a native close control, changing the number/order of AX nodes.
        let close = closeControls.first { $0.exists && $0.isEnabled && $0.isHittable }!
        close.tap()
        try waitForPlayableBattle(game)
        makeFirstSoldierMoveAndExpectWhite(game)
        capture(game, "REWARDED-1024-real-completion-new-match")

        // Starting a second new match without another advertisement must hit the same gate.
        game.buttons["對戰選單"].tap()
        XCTAssertTrue(game.buttons["重新開始"].waitForExistence(timeout: 5))
        game.buttons["重新開始"].tap()
        XCTAssertTrue(game.staticTexts["unlockTitle"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["accessContinue"].exists)
        capture(game, "REWARDED-1024-exactly-one-match")
    }

    func testRealSDKRequestBackgroundCannotStartAnExpiredMatch() {
        continueAfterFailure = false
        let game = openExhaustedTrial()
        game.buttons["watchRewardedAd"].tap()
        XCUIDevice.shared.press(.home)
        game.activate()
        XCTAssertTrue(game.staticTexts["unlockTitle"].waitForExistence(timeout: 10))
        XCTAssertFalse(game.otherElements["playArena"].exists,
                       "A backgrounded request cannot automatically start its old navigation target")
        capture(game, "REWARDED-1024-background-no-auto-start")
        // No completion or privacy approval is claimed by this cancellation-only scenario.
    }

    private func openExhaustedTrial() -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString, "--monetization-exhausted"]
        game.launch()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 10))
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupLocal"].waitForExistence(timeout: 5))
        game.buttons["setupLocal"].tap()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 5))
        if game.buttons["startMatch"].label.contains("下一步") { game.buttons["startMatch"].tap() }
        XCTAssertTrue(game.buttons["startMatch"].label.contains("開始對局"))
        game.buttons["startMatch"].tap()
        XCTAssertTrue(game.staticTexts["unlockTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.staticTexts["monetizationTestNotice"].exists)
        XCTAssertTrue(game.buttons["watchRewardedAd"].isEnabled)
        return game
    }

    private enum FlowFailure: Error {
        case rewardedBattleDidNotBecomeInteractive
    }

    private func waitForPlayableBattle(_ game: XCUIApplication) throws {
        // A board underneath a dismissing access sheet is not a completed reward handoff.
        let expectations = [
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: game.staticTexts["unlockTitle"]),
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true"), object: game.otherElements["playArena"]),
            XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == true AND hittable == true AND enabled == true"), object: game.buttons["mode-soldier"])
        ]
        guard XCTWaiter.wait(for: expectations, timeout: 15) == .completed else {
            throw FlowFailure.rewardedBattleDidNotBecomeInteractive
        }
    }

    private func makeFirstSoldierMoveAndExpectWhite(_ game: XCUIApplication) {
        // Reviewed opening: black starts with one AP; a legal A1 placement consumes it
        // and hands off to white with two AP. Use the existing renderer's A1 projection.
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        game.otherElements["playArena"].coordinate(withNormalizedOffset: CGVector(dx: 0.13, dy: 0.18)).tap()
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        game.buttons["playConfirm"].tap()
        let ready = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND enabled == true"),
            object: game.buttons["mode-soldier"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"),
                      "The SDK-earned match must accept an actual committed board action")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
    }

    private func capture(_ game: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: game.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
        let hierarchy = XCTAttachment(string: game.debugDescription)
        hierarchy.name = name + "-hierarchy"; hierarchy.lifetime = .keepAlways; add(hierarchy)
    }
}
