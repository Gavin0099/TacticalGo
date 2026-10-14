import XCTest

/// 1.0 + 1.1 integration: the expansion shell is an explicit entry from the 1.0 lobby and sits behind the SAME access
/// ledger. These tests drive the real app on a simulator with an isolated record/ledger directory.
/// They do not claim anything about purchases, advertising or play quality.
@MainActor final class IntegrationUITests: XCTestCase {
    private func launch(extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = extra + ["--record-isolation", UUID().uuidString, "--cozy-reduced"]
        app.launch()
        XCTAssertTrue(app.buttons["lobbyNewGame"].waitForExistence(timeout: 20), "1.0 lobby must be the entry")
        XCTAssertTrue(app.staticTexts["accessStatus"].waitForExistence(timeout: 5))
        return app
    }

    func testExpansionIsAnExplicitEntryAndReturnsToTheOriginalShell() {
        let app = launch()
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3")
        XCTAssertTrue(app.buttons["lobbyExpansion"].exists, "expansion must be opened on purpose, from the lobby")
        app.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10), "expansion shell lobby")
        XCTAssertTrue(app.buttons["closeExpansion"].exists)
        app.buttons["closeExpansion"].tap()
        XCTAssertTrue(app.buttons["lobbyNewGame"].waitForExistence(timeout: 10), "back in the 1.0 shell")
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3",
                       "opening the expansion shell must not consume anything")
    }

    func testExpansionStartIsGatedByTheSameLedgerWhenTheTrialIsExhausted() {
        let app = launch(extra: ["--monetization-exhausted"])
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 0／3")
        app.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.staticTexts["unlockTitle"].waitForExistence(timeout: 15), "same unlock sheet as the original shell")
        XCTAssertTrue(app.buttons["watchRewardedAd"].exists)
        XCTAssertTrue(app.buttons["unlockDismiss"].isHittable)
        app.buttons["unlockDismiss"].tap()
        // Declining must leave the player in the lobby with no match started.
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["playArena"].exists)
    }

    func testExpansionStartIsAdmittedWhileTrialRemains() {
        let app = launch()
        app.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        XCTAssertFalse(app.staticTexts["unlockTitle"].waitForExistence(timeout: 3), "no gate while a trial remains")
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15), "the expansion match board is shown")
    }

    func testOriginalShellStillStartsTheOriginalMatchUnchanged() {
        let app = launch()
        app.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(app.buttons["setupLocal"].waitForExistence(timeout: 5))
        app.buttons["setupLocal"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        if app.buttons["startMatch"].label.contains("下一步") { app.buttons["startMatch"].tap() }
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["currentTurn"].exists)
    }

    // C0 / R1: a stop between "record saved" and "ledger written".
    func testInterruptedStartIsNotOfferedAsAFreeResumableMatch() {
        let app = launch(extra: ["--seed-interrupted-start"])
        XCTAssertFalse(app.buttons["resumeMatch"].exists, "an unauthorized, unplayed start must not become a free match")
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3", "recovery must not charge anything")
    }

    func testLegacyUnmarkedRecordStaysResumable() {
        let app = launch(extra: ["--seed-unmarked-start"])
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 5), "records without a marker are legacy and untouched")
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3")
    }

    // C0 / M6 (a): creating a playable copy of an admitted match must not use another admission.
    func testCandidateCopyOfAnAdmittedMatchDoesNotTakeAnotherAdmission() {
        let app = launch(extra: ["--original-rules"])
        app.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(app.buttons["setupLocal"].waitForExistence(timeout: 5))
        app.buttons["setupLocal"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        if app.buttons["startMatch"].label.contains("下一步") { app.buttons["startMatch"].tap() }
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        app.buttons["對戰選單"].tap()
        XCTAssertTrue(app.buttons["candidateCopy"].waitForExistence(timeout: 5))
        app.buttons["candidateCopy"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].value as? String, "新版技能", "the copy is a playable new branch")
        XCTAssertFalse(app.staticTexts["unlockTitle"].exists, "a copy is never gated")
    }
}
