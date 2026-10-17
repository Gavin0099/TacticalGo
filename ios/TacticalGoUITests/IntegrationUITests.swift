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
        XCTAssertFalse(app.descendants(matching: .any)["playStyle"].exists, "Owner 2026-10-17: no play-style choice")
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists, "four heroes")
        XCTAssertTrue(app.descendants(matching: .any)["matchMonsters"].exists, "monster battlefield")
    }

    // Owner decision 2026-10-17 (TestFlight 1114): no play-style choice; new matches always use the latest rules.
    func testFullGameHasNoPlayStyleChoiceAndAlwaysUsesTheLatestRules() {
        let app = launchFullGame()
        XCTAssertFalse(app.descendants(matching: .any)["playStyle"].exists)
        XCTAssertFalse(app.descendants(matching: .any)["matchRules"].exists, "no original/new skill picker either")
        XCTAssertTrue(app.descendants(matching: .any)["matchMonsters"].exists)
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists, "four heroes")
    }

    // Owner TestFlight 1114: the priest's card was shorter than the other three (no second-skill line).
    func testHeroCardsHaveTheSameHeight() {
        let app = launchFullGame()
        for _ in 0..<4 where !app.buttons["choose-priest"].isHittable { app.swipeUp() }
        let heights = ["warrior", "mage", "rogue", "priest"].map { app.buttons["choose-" + $0].frame.height }
        XCTAssertGreaterThan(heights[0], 0)
        for h in heights { XCTAssertEqual(h, heights[0], accuracy: 0.5, "\(heights)") }
    }

    // Owner TestFlight 1114: 「怪物的技能不知道怎麼用」 — choosing a monster battlefield explains hunting and the reward.
    func testMonsterChoiceExplainsHuntingAndTheReward() {
        let app = launchFullGame()
        XCTAssertFalse(app.staticTexts["monsterGuide"].exists)
        app.descendants(matching: .any)["matchMonsters"].firstMatch.tap()
        XCTAssertTrue(app.buttons["雙怪"].waitForExistence(timeout: 5))
        app.buttons["雙怪"].tap()
        let guide = app.staticTexts["monsterGuide"]
        XCTAssertTrue(guide.waitForExistence(timeout: 5))
        for part in ["討伐", "黏彈", "影步", "暗影狼還要己方英雄"] { XCTAssertTrue(guide.label.contains(part), part) }
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

    // A resumed original save restarts with its own rules, but the lobby afterwards is back on the latest rules.
    func testLeavingAResumedOriginalSaveReturnsTheLobbyToTheLatestRules() {
        let app = launchFullGame(extra: ["--seed-unmarked-start"])
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 10))
        app.buttons["resumeMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        app.buttons["返回選角"].tap()
        XCTAssertTrue(app.buttons["exitMatchConfirmed"].waitForExistence(timeout: 5))
        app.buttons["exitMatchConfirmed"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.descendants(matching: .any)["matchMonsters"].exists, "back on the latest rules")
        for _ in 0..<4 where !app.buttons["choose-priest"].exists { app.swipeUp() }
        XCTAssertTrue(app.buttons["choose-priest"].exists)
    }

    // Owner TestFlight 1114 report: 「購買與恢復」 opened 「選擇繼續遊玩的方式」 with only 「返回遊戲」 while free matches remained.
    func testPurchaseEntryOffersThePurchaseWhileFreeMatchesRemain() {
        let app = launchFullGame()
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3")
        app.buttons["purchaseSettings"].tap()
        XCTAssertTrue(app.staticTexts["unlockTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["unlockTitle"].label, "購買與恢復")
        XCTAssertTrue(app.buttons["unlockPurchase"].exists, "the purchase is offered from the purchase entry")
        XCTAssertTrue(app.buttons["restorePurchases"].exists)
        XCTAssertFalse(app.buttons["watchRewardedAd"].exists, "free matches remain, so no ad is needed")
        XCTAssertTrue(app.buttons["accessContinue"].exists)
        app.buttons["accessContinue"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["playArena"].exists, "returning from the purchase entry starts nothing")
        XCTAssertEqual(app.staticTexts["accessStatus"].label, "免費完整對局剩餘 3／3")
    }

    // The rules sheet named the old skills and left out the priest while the lobby showed the new ones.
    func testRulesSheetFollowsTheExpansionSkills() {
        let app = launchFullGame()
        for _ in 0..<4 where !app.buttons["遊戲規則"].isHittable { app.swipeUp() }
        app.buttons["遊戲規則"].tap()
        XCTAssertTrue(app.staticTexts["戰士 · 沿棋群築壘"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["法師 · 調度己兵"].exists)
        XCTAssertFalse(app.staticTexts["戰士 · 築壘"].exists)
        let heroes = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "法師與牧師需 3")).firstMatch
        XCTAssertTrue(heroes.exists, "the priest is a fourth hero in the expansion")
        // The sheet is a lazy List: the monster section only exists once scrolled into view.
        let monsters = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "黏彈")).firstMatch
        for _ in 0..<8 where !monsters.exists { app.swipeUp() }
        XCTAssertTrue(monsters.exists, "monster rewards are explained")
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "驗證職業特色")).firstMatch.exists, "no internal wording")
    }

    // PRIEST-S2-P0 (Beta candidate): the priest has a second skill, 聖所.
    func testPriestShowsSanctumAsItsSecondSkill() {
        let app = launchFullGame()
        let priest = app.buttons["choose-priest"]
        for _ in 0..<4 where !priest.isHittable { app.swipeUp() }
        XCTAssertTrue(priest.label.contains("聖所"), priest.label)
        priest.tap()
        let second = app.staticTexts["lobbyAdvancedSkill"]
        XCTAssertTrue(second.waitForExistence(timeout: 5))
        XCTAssertTrue(second.label.contains("聖所"), second.label)
    }

    // The 7x7 lesson in the real shell: pick the sacrifice and the exit, see the liberty preview, confirm.
    func testSanctumPracticeIsPlayableWithALibertyPreview() {
        let app = launchFullGame()
        let practice = app.buttons["玩法練習"]
        for _ in 0..<6 where !practice.isHittable { app.swipeUp() }
        practice.tap()
        let lesson = app.buttons["牧師 · 聖所救援（7×7）"]
        XCTAssertTrue(lesson.waitForExistence(timeout: 5)); lesson.tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["mode-advanced"].isSelected, "the lesson opens on the second skill")
        app.buttons["play-cell-1-5"].tap(); app.buttons["play-cell-3-6"].tap()
        let message = app.staticTexts["playMessage"]
        let preview = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "犧牲後氣 1→3"), object: message)
        XCTAssertEqual(XCTWaiter.wait(for: [preview], timeout: 5), .completed, message.label)
        app.buttons["playConfirm"].tap()
        let placed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "士兵"), object: app.buttons["play-cell-3-6"])
        XCTAssertEqual(XCTWaiter.wait(for: [placed], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["play-cell-1-5"].label.contains("空點"))
    }
}
