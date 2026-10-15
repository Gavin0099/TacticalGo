import XCTest

@MainActor final class PlayableGameTests: XCTestCase {
    private func challengeButton(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id]
        for _ in 0..<4 { if button.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5)); XCTAssertTrue(button.isHittable); button.tap()
    }
    private func challengePoint(_ app: XCUIApplication, _ x: Int, _ y: Int) {
        let arena = app.otherElements["challengeArena"]
        for _ in 0..<3 { if arena.isHittable && arena.frame.minY >= 0 && arena.frame.maxY <= app.frame.maxY { break }; app.swipeDown() }
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        let row = Double(y) / 6, inset = 0.13 - 0.06 * row
        arena.coordinate(withNormalizedOffset: CGVector(dx: inset + (1 - inset * 2) * Double(x) / 6, dy: 0.18 + 0.65 * row)).tap()
    }
    func testChallengeSixRealSolutionsAndImmediateCompletionLock() {
        let app = app(["--challenges"])
        XCTAssertTrue(app.staticTexts["challengeCatalog"].waitForExistence(timeout: 10))
        let ids = ["warrior-rescue", "warrior-counterattack", "mage-split", "mage-rescue", "rogue-shape", "rogue-finish"]
        let targets = [[(0,1),(1,0),(2,0)],[(3,2),(4,3),(5,3)],[(4,2),(4,2)],[(2,2),(2,2)],[(4,3),(5,2)],[(3,2),(4,1)]]
        for i in 0..<6 {
            challengeButton(app, "challenge-" + ids[i])
            XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("黑方 · 2 AP"))
            XCTAssertFalse(app.descendants(matching: .any)["botStatus"].exists)
            challengeButton(app, "challengeSkill")
            challengePoint(app, targets[i][0].0, targets[i][0].1)
            if i < 2 { challengePoint(app, targets[i][1].0, targets[i][1].1) }
            if i == 2 || i == 3 { challengeButton(app, "challengeDirection-Down") }
            let before = app.staticTexts["challengeResources"].label
            XCTAssertTrue(app.buttons["challengeConfirm"].isEnabled)
            shot(app, "challenge-" + ids[i] + "-core-preview")
            XCTAssertEqual(app.staticTexts["challengeResources"].label, before)
            challengeButton(app, "challengeConfirm")
            XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 1／2"))
            challengeButton(app, "challengeSoldier")
            challengePoint(app, targets[i].last!.0, targets[i].last!.1)
            challengeButton(app, "challengeConfirm")
            XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["challengeResult"].label.hasPrefix("挑戰完成"))
            XCTAssertTrue(app.staticTexts["challengeResources"].label.hasPrefix("本關已結束 · 黑方"))
            XCTAssertFalse(app.staticTexts["challengeResources"].label.contains("白方"))
            XCTAssertFalse(app.buttons["challengeConfirm"].exists)
            let done = app.staticTexts["challengeResources"].label
            challengePoint(app, 6, 6)
            XCTAssertEqual(app.staticTexts["challengeResources"].label, done)
            shot(app, "challenge-" + ids[i] + "-completed-lock")
            app.buttons["challengeBack"].tap()
        }
        XCTAssertEqual(app.staticTexts["challengeProgress"].label, "6／6 已完成")
    }
    func testChallengeFailureUndoRetryAndHintsAreOptional() {
        let app = app(["--challenges"])
        challengeButton(app, "challenge-rogue-finish")
        let initial = app.staticTexts["challengeResources"].label
        challengeButton(app, "challengeSoldier")
        challengePoint(app, 3, 3) // Occupied hero is not a legal placement.
        XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["challengeResources"].label, initial)
        challengeButton(app, "challengeCancel")
        challengeButton(app, "challengeSkill"); challengePoint(app, 3, 2); challengeButton(app, "challengeConfirm")
        challengeButton(app, "challengeSoldier"); challengePoint(app, 6, 6); challengeButton(app, "challengeConfirm")
        XCTAssertTrue(app.staticTexts["challengeResult"].label.hasPrefix("挑戰失敗"))
        XCTAssertFalse(app.buttons["challengeConfirm"].exists)
        shot(app, "challenge-failed-lock-no-opponent")
        challengeButton(app, "challengeUndo")
        XCTAssertFalse(app.staticTexts["challengeResult"].exists)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 1／2"))
        challengePoint(app, 4, 1); challengeButton(app, "challengeConfirm")
        XCTAssertTrue(app.staticTexts["challengeResult"].label.hasPrefix("挑戰完成"))
        challengeButton(app, "challengeRetry")
        XCTAssertEqual(app.staticTexts["challengeResources"].label, initial)
        challengeButton(app, "challengeHint")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "切斷它與主將的連接")).firstMatch.exists)
        shot(app, "challenge-retry-optional-hint")
    }
    func testChallengeResumeReplaysJournalAndAccessiblePicker() {
        let app = app(["--challenges"])
        challengeButton(app, "challenge-rogue-finish")
        challengeButton(app, "challengeSkill"); challengePoint(app, 3, 2); challengeButton(app, "challengeConfirm")
        let one = app.staticTexts["challengeResources"].label
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["challengeTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["challengeResources"].label, one)
        challengeButton(app, "challengeSoldier"); challengeButton(app, "challengePoints")
        let point = app.buttons["challengePoint-4-1"]
        XCTAssertTrue(point.waitForExistence(timeout: 5)); XCTAssertGreaterThanOrEqual(point.frame.height, 44)
        point.tap(); XCTAssertEqual(app.staticTexts["challengeResources"].label, one)
        challengeButton(app, "challengeCancel"); XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled)
        challengePoint(app, 4, 1); challengeButton(app, "challengeConfirm")
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.hasPrefix("挑戰完成"))
        challengeButton(app, "challengeUndo")
        XCTAssertEqual(app.staticTexts["challengeResources"].label, one)
        shot(app, "challenge-relaunch-completion-undo-replay")
    }
    func testChallengesKeepOriginalSavedMatchAndTabletRotationOperable() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let app = app()
        challengeButton(app, "startMatch")
        tap(app, 2, 5); app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["返回選角"].tap(); app.buttons["exitMatchConfirmed"].tap()
        challengeButton(app, "startChallenges")
        challengeButton(app, "challenge-warrior-rescue")
        challengeButton(app, "challengeSkill")
        challengePoint(app, 0, 1); challengePoint(app, 1, 0)
        let resources = app.staticTexts["challengeResources"].label
        if app.frame.width > 600 {
            XCUIDevice.shared.orientation = .landscapeLeft
            let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: app)
            XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
            XCTAssertEqual(app.staticTexts["challengeResources"].label, resources)
            let arena = app.otherElements["challengeArena"]
            XCTAssertGreaterThan(arena.frame.height / arena.frame.width, 0.75) // Dense rows must not be flattened into each other.
            shot(app, "challenge-iPad-landscape-preview")
        }
        challengeButton(app, "challengeConfirm")
        challengeButton(app, "challengeSoldier"); challengePoint(app, 2, 0); challengeButton(app, "challengeConfirm")
        XCTAssertTrue(app.staticTexts["challengeResult"].label.hasPrefix("挑戰完成"))
        app.buttons["challengeBack"].tap(); app.buttons["challengeBack"].tap()
        for _ in 0..<5 { if app.buttons["resumeMatch"].isHittable { break }; app.swipeDown() }
        challengeButton(app, "resumeMatch")
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        tap(app, 2, 5)
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled) // Original occupied C6 remains occupied.
        shot(app, "challenge-original-match-still-retained")
    }
    private func tapTutorial(_ app: XCUIApplication, _ x: Int, _ y: Int) {
        let arena = app.otherElements["onboardArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        let row = Double(y) / 6, inset = 0.13 - 0.06 * Double(y) / 6
        arena.coordinate(withNormalizedOffset: CGVector(dx: inset + (1 - inset * 2) * Double(x) / 6, dy: 0.18 + 0.65 * row)).tap()
    }
    private func tutorialNext(_ app: XCUIApplication) {
        for _ in 0..<3 { if app.buttons["onboardNext"].isHittable { break }; app.swipeUp() }
        app.buttons["onboardNext"].tap()
        app.swipeDown()
    }
    func testOnboardingFiveLessonsRealPreviewLibertiesCaptureAndRescue() {
        let app = app(["--onboard"])
        XCTAssertTrue(app.staticTexts["onboardTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "保護主將，包圍對手")
        let before = app.staticTexts["onboardResources"].label
        tapTutorial(app, 3, 2)
        XCTAssertTrue(app.staticTexts["onboardFeedback"].label.contains("主將"))
        XCTAssertEqual(app.staticTexts["onboardResources"].label, before)
        app.buttons["onboardCancel"].tap()
        XCTAssertFalse(app.buttons["onboardConfirm"].isEnabled)
        tapTutorial(app, 3, 2); app.buttons["onboardConfirm"].tap()
        XCTAssertTrue(app.staticTexts["onboardFeedback"].label.contains("黑方獲勝"))
        shot(app, "onboard-1-real-commander-win")
        app.buttons["onboardUndo"].tap()
        XCTAssertEqual(app.staticTexts["onboardResources"].label, before)
        tapTutorial(app, 3, 2); app.buttons["onboardConfirm"].tap(); tutorialNext(app)
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "放下一顆士兵")
        XCTAssertTrue(app.staticTexts["onboardResources"].label.contains("黑方 · 1 AP"))
        tapTutorial(app, 2, 5); app.buttons["onboardConfirm"].tap()
        XCTAssertTrue(app.staticTexts["onboardResources"].label.contains("白方 · 2 AP")); tutorialNext(app)
        tapTutorial(app, 4, 3); XCTAssertFalse(app.buttons["onboardConfirm"].isEnabled)
        tapTutorial(app, 2, 3)
        XCTAssertEqual(app.staticTexts["onboardInspection"].label, "黑方 · 棋群 2 子 · 6 氣")
        shot(app, "onboard-3-shared-six-liberties")
        tapTutorial(app, 4, 3); app.buttons["onboardConfirm"].tap()
        XCTAssertEqual(app.staticTexts["onboardInspection"].label, "黑方 · 棋群 3 子 · 8 氣"); tutorialNext(app)
        tapTutorial(app, 3, 2)
        XCTAssertEqual(app.staticTexts["onboardInspection"].label, "白方 · 棋群 1 子 · 1 氣")
        tapTutorial(app, 3, 3)
        XCTAssertTrue(app.staticTexts["onboardFeedback"].label.contains("將提白方 1 顆"))
        XCTAssertTrue(app.staticTexts["onboardInspection"].label.hasPrefix("目前（預覽前）"))
        shot(app, "onboard-4-before-capture-no-spend")
        app.buttons["onboardConfirm"].tap()
        XCTAssertTrue(app.staticTexts["onboardFeedback"].label.contains("還沒有分出勝負")); tutorialNext(app)
        XCTAssertTrue(app.staticTexts["onboardDanger"].label.contains("黑方主將只剩 1 氣"))
        tapTutorial(app, 3, 4)
        XCTAssertEqual(app.staticTexts["onboardInspection"].label, "黑方 · 棋群 1 子 · 1 氣")
        tapTutorial(app, 3, 3); app.buttons["onboardConfirm"].tap()
        XCTAssertFalse(app.staticTexts["onboardDanger"].exists)
        XCTAssertEqual(app.staticTexts["onboardInspection"].label, "黑方 · 棋群 2 子 · 3 氣")
        shot(app, "onboard-5-real-commander-rescue"); tutorialNext(app)
        XCTAssertTrue(app.buttons["onboardFinish"].exists)
        app.buttons["onboardFinish"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
    }
    func testOnboardingJournalRelaunchBackgroundAndLargeTargets() {
        let app = app(["--onboard"])
        XCTAssertTrue(app.buttons["onboardPoints"].waitForExistence(timeout: 10))
        app.buttons["onboardPoints"].tap()
        let point = app.buttons["onboardPoint-3-2"]
        XCTAssertTrue(point.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(point.frame.height, 44); XCTAssertGreaterThanOrEqual(point.frame.width, 44)
        point.tap()
        let before = app.staticTexts["onboardResources"].label
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertFalse(app.buttons["onboardConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["onboardResources"].label, before)
        tapTutorial(app, 3, 2); app.buttons["onboardConfirm"].tap(); tutorialNext(app)
        app.terminate(); app.launch()
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "放下一顆士兵")
        app.buttons["onboardExit"].tap()
        for _ in 0..<4 { if app.buttons["startOnboarding"].isHittable { break }; app.swipeUp() }
        app.buttons["startOnboarding"].tap()
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "放下一顆士兵")
        shot(app, "onboard-resume-independent-journal")
        app.buttons["onboardRestart"].tap()
        XCTAssertTrue(app.buttons["保留進度"].waitForExistence(timeout: 5))
        app.buttons["保留進度"].tap()
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "放下一顆士兵")
        app.buttons["onboardRestart"].tap()
        XCTAssertTrue(app.buttons["onboardRestartConfirmed"].waitForExistence(timeout: 5))
        app.buttons["onboardRestartConfirmed"].tap()
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "保護主將，包圍對手")
        app.terminate(); app.launch()
        XCTAssertEqual(app.staticTexts["onboardTitle"].label, "保護主將，包圍對手")
    }
    func testOnboardingDoesNotChangeOriginalSavedMatch() {
        let app = app()
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        tap(app, 2, 5); app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["返回選角"].tap()
        XCTAssertTrue(app.buttons["留在對戰"].waitForExistence(timeout: 5))
        app.buttons["留在對戰"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["返回選角"].tap()
        XCTAssertTrue(app.buttons["exitMatchConfirmed"].waitForExistence(timeout: 5))
        app.buttons["exitMatchConfirmed"].tap()
        for _ in 0..<4 { if app.buttons["startOnboarding"].isHittable { break }; app.swipeUp() }
        app.buttons["startOnboarding"].tap()
        tapTutorial(app, 3, 2); app.buttons["onboardConfirm"].tap()
        app.buttons["onboardExit"].tap()
        app.swipeDown()
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 5))
        app.buttons["resumeMatch"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        shot(app, "onboard-original-match-retained")
    }
    private func app(_ args: [String] = []) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = args + ["--record-isolation", UUID().uuidString]; app.launch(); return app
    }
    private func tap(_ app: XCUIApplication, _ x: Int, _ y: Int, size: Int = 7) {
        let arena = app.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        // Independent published trapezoid projection, not production helper calls.
        let row = Double(y) / Double(size - 1)
        let inset = 0.13 - 0.06 * row
        let px = inset + (1 - inset * 2) * Double(x) / Double(size - 1)
        let py = 0.18 + 0.65 * row
        arena.coordinate(withNormalizedOffset: CGVector(dx: px, dy: py)).tap()
    }
    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func waitForBot(_ app: XCUIApplication, turns: Int, timeout: TimeInterval = 20) {
        let status = app.descendants(matching: .any)["botStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "已完成\(turns)電腦回合"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: timeout), .completed)
    }
    private func waitForStep(_ app: XCUIApplication, _ index: Int, landed: Bool, count: Int = 2) {
        let value = "\(index)/\(count) \(landed ? "落定" : "準備")"
        let phase = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", value), object: app.staticTexts["playMessage"])
        XCTAssertEqual(XCTWaiter.wait(for: [phase], timeout: 20), .completed)
    }
    private func reviewBotMatch() -> XCUIApplication {
        let app = app(["--bot-step-review"])
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout: 10))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        tap(app, 3, 4)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled, "D5 必須先成功選取，才測電腦演出")
        XCTAssertEqual(app.otherElements["playArena"].value as? String, "D5")
        app.buttons["playConfirm"].tap()
        return app
    }

    func testCandidateWarriorScreenshotPlacesBothFrontierPointsAndUndo() {
        let original = app(["--skill-screenshot"])
        tap(original, 6, 4); tap(original, 6, 6)
        XCTAssertFalse(original.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(original.staticTexts["playMessage"].label.contains("範圍"))
        original.terminate()
        let candidate = app(["--skill-screenshot", "--candidate-skills"])
        XCTAssertTrue(candidate.staticTexts["candidateRulesBanner"].waitForExistence(timeout: 10))
        tap(candidate, 6, 4); tap(candidate, 6, 6)
        XCTAssertTrue(candidate.buttons["playConfirm"].isEnabled)
        shot(candidate, "candidate-warrior-owner-G5-G7-preview")
        candidate.buttons["playConfirm"].tap()
        XCTAssertTrue(candidate.staticTexts["1 AP"].exists)
        shot(candidate, "candidate-warrior-owner-G6-captured")
        candidate.buttons["undoOrCancel"].tap()
        XCTAssertTrue(candidate.staticTexts["2 AP"].exists)
        tap(candidate, 6, 4); tap(candidate, 6, 6)
        XCTAssertTrue(candidate.buttons["playConfirm"].isEnabled)
    }
    func testCandidateMageDenseRedeployPreviewCancelUndoAndOriginalPushSwitch() {
        let app = app(["--skill-screenshot", "--candidate-skills", "--mage-redeploy"])
        XCTAssertTrue(app.segmentedControls["mageOperation"].waitForExistence(timeout: 10))
        tap(app, 3, 2); tap(app, 1, 1)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        shot(app, "candidate-mage-dense-redeploy-preview")
        app.buttons["undoOrCancel"].tap()
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        tap(app, 3, 2); tap(app, 1, 1); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "candidate-mage-dense-redeploy-confirmed")
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.segmentedControls["mageOperation"].buttons["推動"].tap()
        tap(app, 3, 2)
        XCTAssertTrue(app.buttons["push-Up"].exists)
        XCTAssertFalse(app.buttons["push-Up"].isEnabled) // dense own soldiers still block original push
    }
    func testOriginalMatchCandidateCopyKeepsBothSavedRuleVersionsAndResumes() {
        let app = app()
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        tap(app, 2, 5); app.buttons["playConfirm"].tap()
        app.buttons["對戰選單"].tap(); app.buttons["candidateCopy"].tap()
        XCTAssertTrue(app.staticTexts["candidateRulesBanner"].waitForExistence(timeout: 10))
        app.buttons["對戰選單"].tap(); app.buttons["matchRecords"].tap()
        XCTAssertTrue(app.staticTexts["原版規則"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["候選技能"].exists)
        shot(app, "original-and-candidate-records-preserved")
        app.buttons["recordsDone"].tap()
        // Relaunch without resetting the isolated record namespace.
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 10))
        app.buttons["resumeMatch"].tap()
        XCTAssertTrue(app.staticTexts["candidateRulesBanner"].waitForExistence(timeout: 10))
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
    }

    func testR2MageExchangePreviewAndUndo() {
        let app = app()
        for _ in 0..<4 { if app.buttons["r2Lab"].isHittable { break }; app.swipeUp() }
        app.buttons["r2Lab"].tap(); app.buttons["r2Mage"].tap()
        app.segmentedControls["r2Variant"].buttons["C"].tap(); app.buttons["startR2"].tap()
        XCTAssertTrue(app.staticTexts["r2Banner"].label.contains("R2 C"))
        tap(app,3,2); XCTAssertTrue(app.buttons["push-Left"].isEnabled)
        app.buttons["push-Left"].tap()
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(app.otherElements["playArena"].value as? String,"D3")
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app,"r2-mage-dense-exchange")
        app.buttons["undoOrCancel"].tap(); XCTAssertTrue(app.staticTexts["2 AP"].exists)
    }
    func testR2WarriorOriginalAndConnectedScopeRemainSeparate() {
        let app = app()
        for _ in 0..<4 { if app.buttons["r2Lab"].isHittable { break }; app.swipeUp() }
        app.buttons["r2Lab"].tap()
        app.buttons["startR2"].tap()
        XCTAssertTrue(app.staticTexts["r2Banner"].label.contains("R2 A"))
        tap(app,1,2); tap(app,3,2)
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("範圍"))
        app.buttons["返回選角"].tap(); app.buttons.matching(identifier:"返回選角").allElementsBoundByIndex.last!.tap()
        for _ in 0..<4 { if app.buttons["r2Lab"].isHittable { break }; app.swipeUp() }
        app.buttons["r2Lab"].tap(); app.segmentedControls["r2Variant"].buttons["B"].tap()
        app.buttons["startR2"].tap()
        XCTAssertTrue(app.staticTexts["r2Banner"].label.contains("R2 B"))
        tap(app,1,2); tap(app,3,2)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        shot(app,"r2-warrior-connected-scope-undo")
        app.terminate(); app.launch()
        XCTAssertFalse(app.buttons["resumeMatch"].exists,"R2 probe must not replace the real saved game")
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        XCTAssertFalse(app.staticTexts["r2Banner"].exists)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
    }
    func testSavedMatchRestartsWithResourcesAndUndo() {
        let app = app()
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        tap(app,0,0); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout:10))
        app.buttons["resumeMatch"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.buttons["以格點清單操作棋盤"].tap()
        XCTAssertTrue(app.buttons["cell-0-0"].label.contains("黑方"))
        app.buttons["完成"].tap()
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("黑方"))
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app,"saved-match-relaunch-and-undo")
        app.terminate(); app.launch(); app.buttons["resumeMatch"].tap()
        app.buttons["以格點清單操作棋盤"].tap()
        XCTAssertTrue(app.buttons["cell-0-0"].label.contains("空點"))
    }
    func testSavedComputerCommittedStepResumesRemainingAP() {
        let app = reviewBotMatch()
        waitForStep(app,1,landed:false)
        app.buttons["botReviewAdvance"].tap(); waitForStep(app,1,landed:true)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.terminate(); app.launch()
        app.buttons["resumeMatch"].tap()
        waitForStep(app,1,landed:false,count:1)
        XCTAssertTrue(app.staticTexts["1 AP"].exists,"Resume cannot restore already consumed computer AP")
        app.buttons["botReviewAdvance"].tap(); waitForStep(app,1,landed:true,count:1)
        app.buttons["botReviewAdvance"].tap(); waitForBot(app,turns:1)
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("黑方"))
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists,"Undo after disk restore must reach before the human first turn")
        shot(app,"saved-computer-resume-remaining-ap")
    }
    func testReplayReadOnlyExportAndReturnToLiveGame() {
        let app = app()
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        tap(app,0,0); app.buttons["playConfirm"].tap()
        tap(app,1,0); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["對戰選單"].tap(); app.buttons["存局與棋譜"].tap()
        let replay = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@", "replay-")).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout:10)); replay.tap()
        XCTAssertTrue(app.staticTexts["replayStep"].label.contains("第 0／2"))
        app.buttons["replayNext"].tap()
        XCTAssertTrue(app.staticTexts["replayStep"].label.contains("黑方 落子 A1"))
        app.buttons["replayLast"].tap()
        XCTAssertTrue(app.staticTexts["replayResources"].label.contains("1 AP"))
        app.buttons["exportReplay"].tap()
        XCTAssertTrue(app.buttons["shareReplay"].waitForExistence(timeout:10))
        shot(app,"replay-last-frame-and-export")
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["recordsDone"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
    }
    func testTabletNativePortraitLandscapeAndSelectionSurviveRotation() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertGreaterThanOrEqual(app.windows.firstMatch.frame.width, 700, "Native tablet window must not be an iPhone compatibility canvas")
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        XCTAssertTrue(app.segmentedControls["botDifficulty"].buttons["簡單"].isSelected)
        shot(app, "iPad-native-portrait-lobby")
        if !app.buttons["startMatch"].isHittable { app.swipeUp() }
        app.buttons["startMatch"].tap()
        waitForBot(app, turns: 1, timeout: 30)
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(app.buttons["playConfirm"].isHittable)
        let portraitBoard = app.otherElements["playArena"].frame
        XCTAssertGreaterThan(portraitBoard.width, 500)
        XCTAssertGreaterThan(portraitBoard.height, 400)
        shot(app, "iPad-native-portrait-match")
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 10))
        let boardFrame = app.otherElements["playArena"].frame
        let confirmFrame = app.buttons["playConfirm"].frame
        XCTAssertGreaterThan(boardFrame.width, 550)
        XCTAssertGreaterThan(boardFrame.height, 450)
        XCTAssertGreaterThanOrEqual(confirmFrame.minX, boardFrame.maxX, "Actions belong beside the board")
        XCTAssertTrue(app.buttons["playEndTurn"].isHittable)
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        tap(app, 0, 0)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(app.otherElements["playArena"].value as? String, "A1")
        shot(app, "iPad-native-landscape-match")
        XCUIDevice.shared.orientation = .portrait
        let portraitRotation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.windows.firstMatch.frame.width < app.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portraitRotation], timeout: 10), .completed)
        XCTAssertEqual(app.otherElements["playArena"].value as? String, "A1", "Rotation must retain preview")
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        shot(app, "iPad-rotation-commit-undo")
    }
    func testTabletLandscapeLobbyStartsMatch() {
        XCUIDevice.shared.orientation = .landscapeLeft
        let app = app()
        defer { XCUIDevice.shared.orientation = .portrait }
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["choose-warrior"].isHittable)
        XCTAssertTrue(app.buttons["startMatch"].isHittable)
        shot(app, "iPad-native-landscape-lobby")
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["playEndTurn"].isHittable)
        tap(app, 0, 0)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
    }
    func testTabletNineBoardLandscapeTouchAndSoundSettings() {
        XCUIDevice.shared.orientation = .landscapeRight
        let app = app(["--play-nine"])
        defer { XCUIDevice.shared.orientation = .portrait }
        let arena = app.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        XCTAssertEqual(arena.label, "9乘9棋盤")
        XCTAssertTrue(app.buttons["playEndTurn"].isHittable)
        tap(app, 0, 0, size: 9)
        XCTAssertEqual(arena.value as? String, "A1")
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("黑方"))
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "iPad-native-nine-landscape")
        app.buttons["對戰選單"].tap(); app.buttons["聲音設定"].tap()
        XCTAssertTrue(app.switches["audioMute"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.sliders["musicVolume"].isHittable)
        shot(app, "iPad-native-sound-sheet")
        app.buttons["audioSettingsDone"].tap()
        XCTAssertTrue(app.buttons["playEndTurn"].waitForExistence(timeout: 10))
    }
    func testIntegratedNativeAudioCancellationAndReplay() {
        let app = app(["--integrated-audio-audit"])
        let status = app.staticTexts["integratedAudioAudit"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let passed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "PASS"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [passed], timeout: 90), .completed)
        shot(app, "BOT-03a-integrated-native-audio-audit")
    }
    func testSoundSettingsPersistInComputerMatch() {
        let app = app(["--play-bot"])
        app.buttons["對戰選單"].tap(); app.buttons["聲音設定"].tap()
        let toggle = app.switches["audioMute"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        let original = toggle.value as? String
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let changed = toggle.value as? String
        XCTAssertNotEqual(original, changed)
        app.sliders["sfxVolume"].adjust(toNormalizedSliderPosition: 0.35)
        app.sliders["musicVolume"].adjust(toNormalizedSliderPosition: 0.20)
        shot(app, "BOT-03a-integrated-sound-settings")
        app.buttons["audioSettingsDone"].tap()
        app.terminate(); app.launch()
        app.buttons["對戰選單"].tap(); app.buttons["聲音設定"].tap()
        XCTAssertEqual(app.switches["audioMute"].value as? String, changed)
        app.switches["audioMute"].coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        app.buttons["audioSettingsDone"].tap()
    }
    func testEasyDefaultDifficultyAndSwitchDuringComputerPreview() {
        let app = app(["--bot-step-review"])
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        XCTAssertTrue(app.segmentedControls["botDifficulty"].buttons["簡單"].isSelected)
        app.segmentedControls["botDifficulty"].buttons["標準"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        waitForStep(app, 1, landed: false)
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.buttons["對戰選單"].tap(); app.buttons["改為簡單"].tap()
        waitForStep(app, 1, landed: false)
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.buttons["對戰選單"].tap()
        XCTAssertTrue(app.buttons["難度：簡單 ✓"].exists)
        app.buttons["難度：簡單 ✓"].tap() // Dismiss by selecting the already-active mode.
        shot(app, "BOT-03a-easy-replaces-standard-before-commit")
        app.buttons["botReviewAdvance"].tap(); waitForStep(app, 1, landed: true)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["對戰選單"].tap(); app.buttons["改為標準"].tap()
        waitForStep(app, 1, landed: false, count: 1)
        XCTAssertTrue(app.staticTexts["1 AP"].exists, "切換難度不能補回已消耗的 AP")
        shot(app, "BOT-03a-standard-replans-only-remaining-1AP")
        app.buttons["botReviewAdvance"].tap(); waitForStep(app, 1, landed: true, count: 1)
        app.buttons["botReviewAdvance"].tap(); waitForBot(app, turns: 1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
    }
    func testWhiteHumanGetsComputerBlackOpeningAndHumanUndo() {
        let app = app(["--bot-step-review"])
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        XCTAssertTrue(app.segmentedControls["choosingTeam"].buttons["你 · 白方 ○"].isSelected)
        app.buttons["choose-warrior"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        shot(app, "BOT-03a-white-human-easy-picker")
        app.buttons["startMatch"].tap()
        waitForStep(app, 1, landed: false, count: 1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        XCTAssertFalse(app.buttons["undoOrCancel"].isEnabled)
        app.buttons["botReviewAdvance"].tap(); waitForStep(app, 1, landed: true, count: 1)
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        app.buttons["botReviewAdvance"].tap(); waitForBot(app, turns: 1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方戰士")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        XCTAssertTrue(app.buttons["mode-soldier"].isEnabled)
        XCTAssertFalse(app.buttons["undoOrCancel"].isEnabled)
        XCTAssertTrue(app.descendants(matching: .any)["botStatus"].label.contains("白方"))
        shot(app, "BOT-03a-white-human-after-computer-first-1AP")
        app.buttons["以格點清單操作棋盤"].tap()
        XCTAssertTrue(app.buttons["cell-0-0"].label.contains("空點"))
        app.buttons["cell-0-0"].tap()
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方戰士")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        XCTAssertFalse(app.buttons["undoOrCancel"].isEnabled)
        shot(app, "BOT-03a-white-human-undo-preserves-computer-opening")
    }
    func testComputerActionsArePresentedSeparatelyBeforeHandover() {
        let app = reviewBotMatch()
        waitForStep(app, 1, landed: false)
        let firstAction = app.staticTexts["playMessage"].label
        XCTAssertTrue(firstAction.hasPrefix("電腦第 1 步："))
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        shot(app, "BOT-01-step-1-target-before-commit")
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 1, landed: true)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        shot(app, "BOT-01-step-1-action-landed")
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: false)
        XCTAssertTrue(app.staticTexts["playMessage"].label.hasPrefix("電腦第 2 步："))
        XCTAssertNotEqual(firstAction, app.staticTexts["playMessage"].label)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "BOT-01-step-2-target-before-commit")
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: true)
        // Core has handed over, while presentation still owns the input lock.
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        shot(app, "BOT-01-step-2-action-landed")
        app.buttons["botReviewAdvance"].tap()
        waitForBot(app, turns: 1)
        XCTAssertTrue(app.buttons["mode-soldier"].isEnabled)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
    }
    func testUndoAfterFirstComputerActionCancelsRemainingPlayback() {
        let app = reviewBotMatch()
        waitForStep(app, 1, landed: false)
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 1, landed: true)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        XCTAssertTrue(app.buttons["mode-soldier"].isEnabled)
        let stale = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", "輪到黑方戰士"), object: app.staticTexts["currentTurn"])
        stale.isInverted = true
        // A cancelled phase must not advance without its review permit or commit later.
        XCTAssertEqual(XCTWaiter.wait(for: [stale], timeout: 11), .completed)
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        shot(app, "BOT-01-undo-between-computer-actions")
    }
    func testBackgroundDuringFinalLandingRestoresHumanTurnMessage() {
        let app = reviewBotMatch()
        waitForStep(app, 1, landed: false); app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 1, landed: true); app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: false); app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: true)
        XCUIDevice.shared.press(.home)
        app.activate()
        waitForBot(app, turns: 1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.buttons["mode-soldier"].isEnabled)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("輪到你"))
        shot(app, "BOT-01-background-final-landing-restored")
    }
    func testMagePushAndCaptureArePresentedFromRealBotEvents() {
        let app = app(["--bot-mage-motion-review", "--bot-step-review", "--bot-delayed"])
        waitForStep(app, 1, landed: false)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("魔法之手"))
        shot(app, "BOT-01-mage-push-target-and-arrow")
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 1, landed: true)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "BOT-01-mage-push-landed")
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: false)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("放士兵"))
        app.buttons["botReviewAdvance"].tap()
        waitForStep(app, 2, landed: true)
        XCTAssertFalse(app.staticTexts["白方獲勝"].exists)
        app.buttons["botReviewAdvance"].tap()
        waitForBot(app, turns: 1)
        XCTAssertTrue(app.staticTexts["白方獲勝"].exists)
        shot(app, "BOT-01-mage-push-place-capture-victory")
    }
    func testSoloModeComputerCompletesTurnAndUndoReturnsHumanDecision() {
        let app = app()
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout: 10))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.buttons["choose-rogue"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        XCTAssertFalse(app.segmentedControls["playBoardSize"].buttons["9 × 9"].isEnabled)
        app.buttons["startMatch"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        tap(app, 3, 4)
        let started = Date()
        app.buttons["playConfirm"].tap()
        waitForBot(app, turns: 1)
        let elapsed = Date().timeIntervalSince(started)
        print("BOT-01 native observed confirm-to-reply seconds: \(elapsed)")
        XCTAssertLessThan(elapsed, 20)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        XCTAssertTrue(app.buttons["mode-soldier"].isEnabled)
        shot(app, "BOT-01-real-computer-turn")
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        shot(app, "BOT-01-undo-human-boundary")
    }
    func testThinkingUndoDiscardsEvenNonCooperativeLateResult() {
        let app = app(["--play-bot", "--bot-delayed", "--bot-late-result"])
        tap(app, 3, 4); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["電腦思考中"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        let started = Date()
        app.buttons["undoOrCancel"].tap()
        XCTAssertLessThan(Date().timeIntervalSince(started), 3)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        let expired = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完成0／作廢1"), object: app.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [expired], timeout: 50), .completed)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "BOT-01-stale-result-rejected-after-undo")
    }
    func testRestartAndExitInvalidatePendingComputerTurn() {
        let app = app(["--play-bot", "--bot-delayed", "--bot-late-result"])
        tap(app, 3, 4); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["電腦思考中"].waitForExistence(timeout: 5))
        app.buttons["對戰選單"].tap(); app.buttons["重新開始"].tap()
        let expired = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完成0／作廢1"), object: app.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [expired], timeout: 50), .completed)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["電腦思考中"].waitForExistence(timeout: 5))
        app.buttons["返回選角"].tap(); app.buttons.matching(identifier: "返回選角").allElementsBoundByIndex.last!.tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
        // Starting another match changes both generation and complete state identity.
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        app.buttons["startMatch"].tap()
        let secondExpired = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完成0／作廢1"), object: app.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [secondExpired], timeout: 50), .completed)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        shot(app, "BOT-01-stale-result-rejected-after-restart-and-exit")
    }
    func testVisualPackConnectionPreservesPreviewCancelCommitAndUndo() {
        let app = app(["--visual-pack-fixture"])
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        XCTAssertEqual(app.staticTexts["visualPackStatus"].label, "素材接線：a0-interface-fixture")
        app.buttons["mode-summon"].tap(); tap(app, 3, 4)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        shot(app, "V2-interface-summon-preview")
        app.buttons["undoOrCancel"].tap()
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        tap(app, 3, 4); app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        shot(app, "V2-interface-committed")
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
    }
    func testMissingVisualAssetRejectsWholePackAndGameRemainsPlayable() {
        let app = app(["--visual-pack-invalid-fixture"])
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        XCTAssertEqual(app.staticTexts["visualPackStatus"].label, "素材拒絕，保留原圖")
        tap(app, 3, 4); XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        shot(app, "V2-interface-rejected-pack-original-fallback")
    }
    func testChooseClassesSummonBothSidesPreviewCancelAndUndo() {
        let app = app()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        shot(app, "A0-class-picker")
        app.buttons["choose-rogue"].tap()
        app.segmentedControls["choosingTeam"].buttons["白方 ○"].tap()
        app.buttons["choose-mage"].tap()
        app.buttons["startMatch"].tap()
        XCTAssertTrue(app.staticTexts["盜賊 · 換位"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        app.buttons["mode-summon"].tap()
        tap(app, 3, 4)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        shot(app, "A0-summon-preview")
        app.buttons["undoOrCancel"].tap()
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        tap(app, 3, 4); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["法師 · 魔法之手"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(app.staticTexts["行動中"].exists)
        XCTAssertTrue(app.staticTexts["等待"].exists)
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        app.buttons["mode-summon"].tap(); tap(app, 3, 2); app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
        shot(app, "A0-two-heroes-match")
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["mode-soldier"].tap(); tap(app, 3, 1)
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["playMessage"].label, "這裡已有棋子。")
        app.buttons["undoOrCancel"].tap()
        app.buttons["playEndTurn"].tap()
        XCTAssertTrue(app.staticTexts["盜賊 · 換位"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方盜賊")
    }
    func testSameClassHeroesStillIdentifyBlackAndWhite() {
        let app = app()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["choose-mage"].tap() // both sides are Mage
        app.buttons["startMatch"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方法師")
        app.buttons["mode-summon"].tap(); tap(app, 3, 4); app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["mode-summon"].tap(); tap(app, 3, 2); app.buttons["playConfirm"].tap()
        shot(app, "A0-black-white-same-mage")
        app.buttons["以格點清單操作棋盤"].tap()
        let white = app.buttons["cell-3-2"]
        for _ in 0..<8 { if white.exists { break }; app.swipeUp() }
        XCTAssertTrue(white.waitForExistence(timeout: 5))
        XCTAssertTrue(white.label.contains("白方 法師"))
        // Grid labels are backed by actual ownership, even with identical source art.
        let black = app.buttons["cell-3-4"]
        for _ in 0..<8 { if black.exists { break }; app.swipeUp() }
        XCTAssertTrue(black.waitForExistence(timeout: 5))
        XCTAssertTrue(black.label.contains("黑方 法師"))
    }
    func testCompleteMatchFromNewGameAndWinningMoveUndo() {
        let app = app()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        app.buttons["startMatch"].tap()
        // Independent cooperative match: cover all four liberties of red D2.
        // Red spends each intervening turn away from its commander.
        for (x, y) in [(3,0), (0,6), (1,6), (2,1), (4,1), (0,5), (1,5), (3,2)] {
            tap(app, x, y)
            XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
            app.buttons["playConfirm"].tap()
        }
        XCTAssertTrue(app.staticTexts["黑方獲勝"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "對戰結束")
        XCTAssertFalse(app.buttons["playEndTurn"].isEnabled)
        shot(app, "A0-complete-match-real-new-game")
        app.buttons["undoOrCancel"].tap()
        XCTAssertFalse(app.staticTexts["黑方獲勝"].exists)
        tap(app, 3, 2)
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
        XCTAssertTrue(app.staticTexts["黑方獲勝"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "對戰結束")
    }
    func testFourPlayablePracticeLessonsAndUndo() {
        for name in ["包圍與提子", "戰士築壘", "法師魔法之手", "盜賊換位"] {
            let app = app(["--practice", name])
            XCTAssertTrue(app.otherElements["playArena"].waitForExistence(timeout: 10))
            XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
            switch name {
            case "包圍與提子": tap(app, 3, 3)
            case "戰士築壘":
                tap(app, 2, 3); XCTAssertFalse(app.buttons["playConfirm"].isEnabled); tap(app, 4, 3)
            case "法師魔法之手":
                tap(app, 4, 3); XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
                XCTAssertFalse(app.buttons["push-Left"].isEnabled)
                app.buttons["push-Up"].tap()
            default: tap(app, 4, 3)
            }
            XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
            XCTAssertTrue(app.staticTexts["2 AP"].exists)
            shot(app, "A0-" + name + "-preview")
            app.buttons["playConfirm"].tap()
            XCTAssertTrue(app.staticTexts["練習完成"].exists)
            shot(app, "A0-" + name + "-completed")
            app.buttons["undoOrCancel"].tap()
            XCTAssertFalse(app.staticTexts["練習完成"].exists)
            XCTAssertTrue(app.staticTexts["2 AP"].exists)
            app.terminate()
        }
    }
    func testNineBoardAccessibleGridWinAndDraw() {
        let nine = app(["--play-nine"])
        XCTAssertTrue(nine.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(nine.otherElements["playArena"].label, "9乘9棋盤")
        tap(nine, 4, 6, size: 9)
        XCTAssertTrue(nine.buttons["playConfirm"].isEnabled)
        shot(nine, "A0-nine-board-preview")
        nine.buttons["playConfirm"].tap()
        XCTAssertTrue(nine.staticTexts["2 AP"].exists)
        nine.buttons["以格點清單操作棋盤"].tap()
        XCTAssertTrue(nine.buttons["cell-0-0"].waitForExistence(timeout: 5))
        nine.buttons["cell-0-0"].tap()
        XCTAssertTrue(nine.buttons["playConfirm"].isEnabled)
        nine.terminate()
        let win = app(["--play-win"])
        tap(win, 3, 3); win.buttons["playConfirm"].tap()
        XCTAssertTrue(win.staticTexts["黑方獲勝"].exists)
        XCTAssertFalse(win.buttons["playEndTurn"].isEnabled)
        shot(win, "A0-win")
        win.buttons["undoOrCancel"].tap()
        XCTAssertFalse(win.staticTexts["黑方獲勝"].exists)
        win.terminate()
        let draw = app(["--play-draw"])
        XCTAssertTrue(draw.buttons["playEndTurn"].waitForExistence(timeout: 10))
        draw.buttons["playEndTurn"].tap()
        XCTAssertTrue(draw.staticTexts["和局"].exists)
        XCTAssertFalse(draw.buttons["playEndTurn"].isEnabled)
        shot(draw, "A0-draw")
        draw.buttons["再玩一局"].tap()
        XCTAssertFalse(draw.staticTexts["和局"].exists)
        XCTAssertTrue(draw.staticTexts["1 AP"].exists)
    }
}
