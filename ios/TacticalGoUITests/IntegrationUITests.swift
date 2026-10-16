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

    // INTEG-ACCESS-01 / P1: the ledger accepted a reward-credit start; the process stops before the first move.
    func testRewardAdmittedExpansionStartSurvivesAStopBeforeTheFirstMove() {
        continueAfterFailure = false
        let isolation = UUID().uuidString
        let base = ["--record-isolation", isolation, "--cozy-reduced", "--monetization-exhausted", "--monetization-reward-credit"]
        let first = XCUIApplication()
        first.launchArguments = base + ["--expansion-stop-after-authorize"]
        first.launch()
        XCTAssertTrue(first.buttons["lobbyExpansion"].waitForExistence(timeout: 20))
        XCTAssertEqual(first.staticTexts["accessStatus"].label, "免費完整對局剩餘 0／3")
        first.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(first.buttons["startMatch"].waitForExistence(timeout: 10))
        first.buttons["startMatch"].tap()
        XCTAssertTrue(first.wait(for: .notRunning, timeout: 20), "the hook stops the app right after the ledger write")

        let second = XCUIApplication()
        second.launchArguments = base
        second.launch()
        XCTAssertTrue(second.buttons["lobbyExpansion"].waitForExistence(timeout: 20))
        second.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(second.buttons["resumeExpansion"].waitForExistence(timeout: 10),
                      "a start that already used the reward credit must leave a match the player can resume")
        second.buttons["resumeExpansion"].tap()
        XCTAssertTrue(second.otherElements["playArena"].waitForExistence(timeout: 15))
        // The credit was used exactly once: after another relaunch a further start is gated again, not silently free,
        // and the recovered match is still the one saved.
        second.terminate()
        let third = XCUIApplication()
        third.launchArguments = base
        third.launch()
        XCTAssertTrue(third.buttons["lobbyExpansion"].waitForExistence(timeout: 20))
        third.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(third.buttons["resumeExpansion"].waitForExistence(timeout: 10))
        XCTAssertTrue(third.buttons["startMatch"].waitForExistence(timeout: 5))
        third.buttons["startMatch"].tap()
        XCTAssertTrue(third.staticTexts["unlockTitle"].waitForExistence(timeout: 15), "no second free start")
    }

    // INTEG-ACCESS-01 / P2: a finished expansion match whose completion never reached the ledger.
    func testFinishedExpansionMatchIsReconciledWithoutOpeningTheExpansionShell() {
        let app = launch(extra: ["--seed-expansion-terminal-unreconciled"])
        let settled = NSPredicate(format: "label == %@", "免費完整對局剩餘 2／3")
        expectation(for: settled, evaluatedWith: app.staticTexts["accessStatus"])
        waitForExpectations(timeout: 8)
    }

    // Tester report 2026-10-15 (build 1113): the ORIGINAL shell showed two extra tabs (第二技能 / 戰利能力) that only exist in
    // the expansion shell, which squeezed every tab label ("放…", "召…") and hid the AP/description line.
    func testOriginalShellOffersOnlyTheThreeOriginalModes() {
        let app = launch()
        app.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(app.buttons["setupLocal"].waitForExistence(timeout: 5))
        app.buttons["setupLocal"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        if app.buttons["startMatch"].label.contains("下一步") { app.buttons["startMatch"].tap() }
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["mode-soldier"].exists)
        XCTAssertTrue(app.buttons["mode-summon"].exists)
        XCTAssertTrue(app.buttons["mode-skill"].exists)
        XCTAssertFalse(app.buttons["mode-advanced"].exists, "第二技能 belongs to the expansion shell only")
        XCTAssertFalse(app.buttons["mode-loot"].exists, "戰利能力 belongs to the expansion shell only")
    }

    // The expansion entry carries what the original shell deliberately does not: the priest and the monster battlefield.
    func testExpansionLobbyOffersPriestAndMonsters() {
        let app = launch()
        app.buttons["lobbyExpansion"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists, "four heroes incl. the priest")
        XCTAssertTrue(app.buttons["matchMonsters"].exists || app.segmentedControls["matchMonsters"].exists
                      || app.otherElements["matchMonsters"].exists || app.descendants(matching: .any)["matchMonsters"].exists,
                      "monster battlefield option")
    }

    // Owner decision 2026-10-15: the full game is the default start path; the original rules are an option.
    func testPrimaryStartOpensTheFullGameAndOriginalRulesAreAnOption() {
        let app = launch()
        let primary = app.buttons["lobbyExpansion"]
        XCTAssertTrue(primary.exists)
        XCTAssertEqual(primary.label, "開始對戰", "the big start button is the full game")
        XCTAssertEqual(app.buttons["lobbyNewGame"].label, "原版規則", "original rules stay one tap away")
        // Primary -> full game lobby with the priest and the monster battlefield.
        primary.tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists)
        app.buttons["closeExpansion"].tap()
        // Option -> the original setup, three heroes, no expansion tabs.
        XCTAssertTrue(app.buttons["lobbyNewGame"].waitForExistence(timeout: 10))
        app.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(app.buttons["setupLocal"].waitForExistence(timeout: 5))
    }

    // MARK: Owner decision 2026-10-15 ("use 1.1 for everything"): the 1.1 shell is the app root (`--full-game` in Debug).

    private func launchFullGame(extra: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = extra + ["--full-game", "--record-isolation", UUID().uuidString, "--cozy-reduced"]
        app.launch()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 20), "the 1.1 lobby is the entry")
        return app
    }

    func testFullGameRootShowsTheProductLayerAndTheFullGame() {
        let app = launchFullGame()
        XCTAssertFalse(app.buttons["lobbyNewGame"].exists, "no separate original-shell lobby")
        XCTAssertFalse(app.buttons["r2Lab"].exists, "the skill lab (技能試驗) is an engineering tool, not part of the product lobby")
        XCTAssertTrue(app.staticTexts["皇冠戰略"].exists)
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3")
        for id in ["lobbyChallenges", "purchaseSettings", "privacySupport", "startOnboarding"] {
            XCTAssertTrue(app.buttons[id].exists || app.otherElements[id].exists || app.descendants(matching: .any)[id].exists, id)
        }
        XCTAssertTrue(app.segmentedControls["playStyle"].exists || app.descendants(matching: .any)["playStyle"].exists)
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists, "four heroes")
        XCTAssertTrue(app.descendants(matching: .any)["matchMonsters"].exists, "monster battlefield")
    }

    func testOriginalRulesAreAnOptionInsideTheFullGameShell() {
        let app = launchFullGame()
        let style = app.segmentedControls["playStyle"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.buttons["原版規則"].tap()
        XCTAssertFalse(app.buttons["choose-priest"].exists, "original rules offer the three original heroes only")
        XCTAssertFalse(app.descendants(matching: .any)["matchMonsters"].exists)
        XCTAssertTrue(app.buttons["choose-warrior"].exists)
        style.buttons["擴充玩法"].tap()
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists)
    }

    func testFullGameStartIsGatedBySharedLedgerAndPurchaseEntryDoesNotStartAMatch() {
        let app = launchFullGame(extra: ["--monetization-exhausted"])
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 0／3")
        // Purchase entry from the lobby bar: opens the sheet, must not start anything.
        app.buttons["purchaseSettings"].tap()
        XCTAssertTrue(app.staticTexts["unlockTitle"].waitForExistence(timeout: 10))
        app.buttons["unlockDismiss"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["playArena"].exists)
        // Starting a match is gated by the same ledger.
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.staticTexts["unlockTitle"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["watchRewardedAd"].exists)
        app.buttons["unlockDismiss"].tap()
        XCTAssertFalse(app.otherElements["playArena"].exists)
    }

    func testFullGameStartWithTrialRemainingOpensTheMatchAndChallengesAreReachable() {
        let app = launchFullGame()
        app.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(app.buttons["英雄技能入門 · 六關"].waitForExistence(timeout: 5))
        app.buttons["英雄技能入門 · 六關"].tap()
        XCTAssertTrue(app.buttons["challengeBack"].waitForExistence(timeout: 10))
        app.buttons["challengeBack"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
    }

    // Codex review of PR #11 (P2): resuming a 1.0 save inside the full-game shell must keep the original rules on restart.
    func testResumedOriginalSaveRestartsWithOriginalRulesNotAnExpansionMatch() {
        let app = launchFullGame(extra: ["--seed-unmarked-start"])
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 10), "the 1.0-style save is offered")
        app.buttons["resumeMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["mode-soldier"].exists)
        XCTAssertFalse(app.buttons["mode-advanced"].exists, "resumed original match has no second skill")
        app.buttons["對戰選單"].tap()
        XCTAssertTrue(app.buttons["重新開始"].waitForExistence(timeout: 5))
        app.buttons["重新開始"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["mode-soldier"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["mode-advanced"].exists, "restart keeps the original rules")
    }

    // Codex review of PR #11 (P2): the original-rules option must default to the Owner-adopted rules, like the old shell.
    func testOriginalRulesOptionDefaultsToTheAdoptedSkillRules() {
        let app = launchFullGame()
        let style = app.segmentedControls["playStyle"]
        XCTAssertTrue(style.waitForExistence(timeout: 5))
        style.buttons["原版規則"].tap()
        let rules = app.segmentedControls["matchRules"]
        XCTAssertTrue(rules.waitForExistence(timeout: 5))
        XCTAssertTrue(rules.buttons["候選技能"].isSelected, "adopted default (.redeployment), not the legacy skills")
        XCTAssertFalse(rules.buttons["原版"].isSelected)
    }
}
