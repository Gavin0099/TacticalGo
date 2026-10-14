import XCTest

@MainActor final class PlayableGameTests: XCTestCase {

    /// A real opening, with no persistent instruction block above or below the board.
    /// The independent screen budget checks all four edges and actual tap targets.
    func testBoardFocusOpeningPreviewHelpAndCancel() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--play-bot", "--bot-delayed"])
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        let openingFrame = game.otherElements["playArena"].frame
        let confirmFrame = game.buttons["playConfirm"].frame
        func fit(_ phase: String) {
            let window = game.windows.firstMatch.frame, arena = game.otherElements["playArena"].frame
            XCTAssertEqual(game.scrollViews.count, 0)
            XCTAssertTrue(window.contains(arena))
            XCTAssertEqual(arena.height / arena.width, 1.125, accuracy: 0.02)
            let minimumFraction: CGFloat = window.height > 800 ? 0.99 : 0.86
            XCTAssertGreaterThanOrEqual(arena.width, window.width * minimumFraction, "Use screen width while preserving on-screen controls on short phones")
            assertUnchangedFrame(arena, openingFrame, phase)
            assertUnchangedFrame(game.buttons["playConfirm"].frame, confirmFrame, phase + " confirm")
            for id in ["mode-soldier", "mode-summon", "mode-skill", "playConfirm", "undoOrCancel", "playEndTurn", "actionHelp"] {
                let button = game.buttons[id]
                XCTAssertTrue(button.isHittable)
                XCTAssertTrue(window.contains(button.frame))
                XCTAssertGreaterThanOrEqual(button.frame.width, 44)
                XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                XCTAssertLessThanOrEqual(button.frame.maxY, window.maxY - (window.height > 800 ? 46 : 12))
            }
            let data: [String: Any] = ["phase":phase, "window":[window.width,window.height],
                "arena":[arena.minX,arena.minY,arena.width,arena.height],
                "areaFraction":arena.width * arena.height / (window.width * window.height)]
            let note = XCTAttachment(data: try! JSONSerialization.data(withJSONObject:data, options:[.prettyPrinted,.sortedKeys]), uniformTypeIdentifier:"public.json")
            note.name = "BOARD-1023-" + phase + "-geometry"; note.lifetime = .keepAlways; add(note)
            shot(game, "BOARD-1023-" + phase)
        }
        XCTAssertFalse(game.staticTexts["matchRulesSummary"].exists)
        XCTAssertFalse(game.staticTexts["sellPhase"].exists)
        XCTAssertFalse(game.descendants(matching:.any)["botStatus"].exists)
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "新版技能")
        fit("01-opening")
        game.buttons["actionHelp"].tap()
        XCTAssertTrue(game.staticTexts["actionHelpText"].waitForExistence(timeout:5))
        XCTAssertTrue(game.staticTexts["actionHelpText"].label.contains("1 AP"))
        game.buttons["actionHelpDone"].tap()
        tap(game,3,4)
        XCTAssertEqual(game.staticTexts["sellPreviewEffect"].label, "於 D5 放置士兵")
        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP")
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        fit("02-preview")
        game.buttons["undoOrCancel"].tap()
        XCTAssertFalse(game.staticTexts["sellPreviewCost"].exists)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        fit("03-cancel")
        tap(game,3,1) // Real opening's occupied white commander.
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["playMessage"].exists)
        fit("04-illegal")
        game.buttons["undoOrCancel"].tap()
        tap(game,2,4); XCTAssertEqual(game.otherElements["playArena"].value as? String,"C5")
        tap(game,3,4); XCTAssertEqual(game.otherElements["playArena"].value as? String,"D5")
        game.buttons["playConfirm"].tap()
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(game.descendants(matching:.any)["botStatus"].waitForExistence(timeout:5))
        assertUnchangedFrame(game.otherElements["playArena"].frame, openingFrame, "bot handoff")
        shot(game,"BOARD-1023-05-bot-handoff")
    }

    private func assertUnchangedFrame(_ frame: CGRect, _ reference: CGRect, _ phase: String) {
        XCTAssertEqual(frame.minX,reference.minX,accuracy:1,phase + " left")
        XCTAssertEqual(frame.minY,reference.minY,accuracy:1,phase + " top")
        XCTAssertEqual(frame.width,reference.width,accuracy:1,phase + " width")
        XCTAssertEqual(frame.height,reference.height,accuracy:1,phase + " height")
    }

    func testBoardFrameStableWithPreferredReceiptTextSizes() {
        XCUIDevice.shared.orientation = .portrait
        for category in ["UICTContentSizeCategoryXXXL", "UICTContentSizeCategoryXS"] {
            let game = app(["--cozy-demo", "-UIPreferredContentSizeCategoryName", category])
            XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout:10))
            let reference = game.otherElements["playArena"].frame
            let confirm = game.buttons["playConfirm"].frame
            for id in ["mode-soldier", "mode-summon", "mode-skill"] {
                XCTAssertGreaterThanOrEqual(game.buttons[id].frame.height,44,category + " minimum touch height")
            }
            tap(game,4,3); game.buttons["push-Up"].tap()
            XCTAssertEqual(game.staticTexts["sellPreviewCost"].label,"消耗 1 AP · 2 能量")
            XCTAssertTrue(game.staticTexts["sellPreviewConsequence"].label.contains("對局結束"))
            assertUnchangedFrame(game.otherElements["playArena"].frame,reference,category + " capture preview")
            assertUnchangedFrame(game.buttons["playConfirm"].frame,confirm,category + " confirm")
            let window = game.windows.firstMatch.frame
            for id in ["sellPreviewEffect","sellPreviewCost","sellPreviewConsequence"] {
                XCTAssertTrue(window.contains(game.staticTexts[id].frame))
            }
            for direction in ["Up", "Down", "Left", "Right"] {
                XCTAssertGreaterThanOrEqual(game.buttons["push-" + direction].frame.height,44)
            }
            XCTAssertTrue(game.buttons["playConfirm"].isHittable)
            XCTAssertTrue(game.buttons["undoOrCancel"].isHittable)
            shot(game,"BOARD-1023-" + category + "-capture-cost-and-consequence")
            game.buttons["undoOrCancel"].tap()
            assertUnchangedFrame(game.otherElements["playArena"].frame,reference,category + " cancel")
            XCTAssertTrue(game.staticTexts["2 AP"].exists)
            game.terminate()
        }
    }

    /// Legal reviewed class fixtures exercise different controls and receipt lengths.
    func testBoardFrameStableAcrossSkillStages() {
        XCUIDevice.shared.orientation = .portrait
        for flags in [["--skill-screenshot","--candidate-skills"],
                      ["--skill-screenshot","--candidate-skills","--mage-redeploy"],
                      ["--cozy-demo"]] {
            let game = app(flags)
            XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout:10))
            let reference = game.otherElements["playArena"].frame
            let confirm = game.buttons["playConfirm"].frame
            func stable(_ phase:String) {
                assertUnchangedFrame(game.otherElements["playArena"].frame,reference,phase)
                assertUnchangedFrame(game.buttons["playConfirm"].frame,confirm,phase + " confirm")
                XCTAssertTrue(game.windows.firstMatch.frame.contains(reference))
                XCTAssertTrue(game.buttons["playConfirm"].isHittable)
                XCTAssertTrue(game.buttons["undoOrCancel"].isHittable)
                shot(game,"BOARD-1023-skill-" + phase)
            }
            stable("initial")
            if flags.contains("--mage-redeploy") {
                tap(game,3,2); stable("mage-source")
                tap(game,1,1); stable("mage-redeploy-preview")
                XCTAssertEqual(game.staticTexts["sellPreviewCost"].label,"消耗 1 AP · 2 能量")
                game.buttons["undoOrCancel"].tap(); stable("mage-cancel")
                game.buttons["mode-soldier"].tap(); stable("mage-mode-change")
            } else if flags.contains("--candidate-skills") {
                tap(game,6,4); stable("warrior-first")
                tap(game,6,6); stable("warrior-two-targets")
                XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
                XCTAssertEqual(game.staticTexts["sellPreviewCost"].label,"消耗 1 AP · 2 能量")
                game.buttons["undoOrCancel"].tap(); stable("warrior-cancel")
            } else {
                tap(game,4,3); stable("mage-direction")
                game.buttons["push-Up"].tap(); stable("mage-capture-preview")
                XCTAssertTrue(game.staticTexts["sellPreviewConsequence"].exists)
                XCTAssertEqual(game.staticTexts["sellPreviewCost"].label,"消耗 1 AP · 2 能量")
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.buttons["undoOrCancel"].tap(); stable("mage-capture-cancel")
            }
            game.terminate()
        }
    }

    /// The result is a new interaction state, not a disabled action form.
    /// Use the existing reviewed eight-action real-opening capture sequence.
    func testResultTableReplayUndoAndRematchFromRealOpening() {
        XCUIDevice.shared.orientation = .portrait
        let game = app()
        startSetupMatch(game)
        let actions = [(3,0), (0,6), (1,6), (2,1), (4,1), (0,5), (1,5), (3,2)]
        for (index, point) in actions.enumerated() {
            tap(game, point.0, point.1)
            XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
            XCTAssertFalse(game.otherElements["matchResult"].exists)
            game.buttons["playConfirm"].tap()
            if index < actions.count - 1 { waitForBattleReady(game) }
        }
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["resultTitle"].label, "黑方獲勝")
        XCTAssertEqual(game.staticTexts["resultReason"].label, "白方主將已被包圍提走。")
        assertResultControls(game)
        assertTerminalBoardIsReadOnly(game)
        shot(game, "RESULT-1021-real-opening-win")
        game.buttons["resultRecords"].tap()
        let replay = game.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'replay-'")).firstMatch
        XCTAssertTrue(replay.waitForExistence(timeout: 5))
        replay.tap()
        XCTAssertTrue(game.staticTexts["replayStep"].waitForExistence(timeout: 5))
        game.buttons["replayLast"].tap()
        XCTAssertTrue(game.staticTexts["replayStep"].label.contains("8／8"))
        game.buttons["存局與棋譜"].tap()
        game.buttons["recordsDone"].tap()
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["resultTitle"].label, "黑方獲勝")
        assertResultControls(game)
        assertTerminalBoardIsReadOnly(game)
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.buttons["mode-soldier"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.otherElements["matchResult"].exists)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        tap(game, 3, 2); game.buttons["playConfirm"].tap()
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        game.buttons["resultRematch"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "新版技能")
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        XCTAssertFalse(game.otherElements["matchResult"].exists)
        XCTAssertTrue(game.buttons["mode-soldier"].isEnabled)
        shot(game, "RESULT-1021-rematch-new-default")
    }

    func testResultTableDrawUndoAndExitKeepsExistingNavigation() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--play-draw"])
        game.buttons["playEndTurn"].tap()
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["resultTitle"].label, "和局")
        XCTAssertTrue(game.staticTexts["resultReason"].label.contains("回合上限"))
        assertResultControls(game)
        shot(game, "RESULT-1021-draw")
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.buttons["playEndTurn"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.otherElements["matchResult"].exists)
        game.buttons["playEndTurn"].tap()
        XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
        game.buttons["返回選角"].tap()
        game.buttons["留在對戰"].tap()
        XCTAssertTrue(game.buttons["resultRematch"].isHittable)
        game.buttons["返回選角"].tap()
        game.buttons["exitMatchConfirmed"].tap()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.otherElements["playArena"].exists)
    }

    func testResultTableTabletLandscapeAndLargeType() {
        for large in [false, true] {
            XCUIDevice.shared.orientation = large ? .portrait : .landscapeLeft
            var flags = ["--cozy-demo", "--white-caster", "--cozy-reduced", "--mage-body-review"]
            if large { flags += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
            let game = app(flags)
            tap(game, 4, 3); game.buttons["push-Up"].tap(); game.buttons["playConfirm"].tap()
            XCTAssertTrue(game.staticTexts["resultTitle"].waitForExistence(timeout: 5))
            XCTAssertEqual(game.staticTexts["resultTitle"].label, "白方獲勝")
            for id in ["mode-soldier", "mode-summon", "mode-skill", "playConfirm", "playEndTurn"] {
                XCTAssertFalse(game.buttons[id].exists)
            }
            if large { game.swipeUp() }
            XCTAssertTrue(game.buttons["resultRematch"].isHittable)
            XCTAssertTrue(game.buttons["resultRecords"].isHittable)
            XCTAssertGreaterThanOrEqual(game.buttons["resultRematch"].frame.height, 44)
            shot(game, "RESULT-1021-ipad-" + (large ? "large-type" : "landscape"))
            game.buttons["undoOrCancel"].tap()
            XCTAssertFalse(game.otherElements["matchResult"].exists)
            game.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    private func assertResultControls(_ game: XCUIApplication) {
        for id in ["mode-soldier", "mode-summon", "mode-skill", "playConfirm", "playEndTurn", "actionHelp"] {
            XCTAssertFalse(game.buttons[id].exists, "Terminal state must not advertise an action that cannot be taken")
        }
        XCTAssertFalse(game.staticTexts["0 AP"].exists)
        XCTAssertFalse(game.staticTexts["1 AP"].exists)
        XCTAssertFalse(game.staticTexts["2 AP"].exists)
        let window = game.windows.firstMatch.frame
        let arena = game.otherElements["playArena"].frame
        XCTAssertTrue(window.contains(arena))
        XCTAssertGreaterThan(arena.width, 220)
        XCTAssertEqual(arena.height / arena.width, 1.125, accuracy: 0.02)
        XCTAssertEqual(game.scrollViews.count, 0)
        for id in ["resultRematch", "resultRecords", "undoOrCancel"] {
            let button = game.buttons[id]
            XCTAssertTrue(button.isHittable)
            XCTAssertTrue(window.contains(button.frame))
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertLessThanOrEqual(button.frame.maxY, window.maxY - (window.height > 800 ? 46 : 12))
        }
    }

    private func assertTerminalBoardIsReadOnly(_ game: XCUIApplication) {
        let arena = game.otherElements["playArena"]
        XCTAssertEqual(arena.value as? String, "終局棋盤")
        tap(game, 0, 0)
        XCTAssertEqual(arena.value as? String, "終局棋盤", "A terminal tap must not create a selected target")
        XCTAssertFalse(game.buttons["playConfirm"].exists)
        game.buttons["以格點清單操作棋盤"].tap()
        XCTAssertTrue(game.navigationBars["終局棋盤"].waitForExistence(timeout: 5))
        // Independently reviewed eight-action opening: D2's commander was
        // captured, and the winning eighth soldier occupies D3.
        XCTAssertTrue(game.buttons["cell-3-1"].label.contains("空點"))
        XCTAssertFalse(game.buttons["cell-3-1"].isEnabled)
        let placed = game.buttons["cell-3-2"]
        for _ in 0..<3 {
            if placed.exists { break }
            game.swipeUp()
        }
        XCTAssertTrue(placed.waitForExistence(timeout: 5))
        if placed.exists { XCTAssertTrue(placed.label.contains("黑方 士兵")) }
        XCTAssertFalse(game.staticTexts["可選"].exists)
        game.buttons["完成"].tap()
        XCTAssertTrue(game.buttons["resultRematch"].isHittable)
    }

    /// The adopted rule set must be used by a real new game, not merely by
    /// screenshot fixtures or updated labels. Both targets below are beyond
    /// adjacency to the hero but beside its pre-cast connected group.
    func testAdoptedSkillsDefaultConnectedBastionAndUndo() {
        XCUIDevice.shared.orientation = .portrait
        let game = app()
        openLobbySettings(game)
        XCTAssertFalse(game.segmentedControls["matchRules"].exists)
        game.buttons["lobbyOptionsDone"].tap()
        game.descendants(matching: .any)["lobbySkillDetails"].tap()
        XCTAssertTrue(game.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "相連")).firstMatch.waitForExistence(timeout: 5))
        startSetupMatch(game)
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "新版技能")
        tap(game, 2, 5); game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        game.buttons["playEndTurn"].tap()
        game.buttons["mode-summon"].tap(); tap(game, 2, 4); game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        game.buttons["mode-soldier"].tap(); tap(game, 2, 3); game.buttons["playConfirm"].tap()
        waitForBattleReady(game)
        game.buttons["playEndTurn"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        game.buttons["mode-skill"].tap(); tap(game, 2, 2); tap(game, 1, 3)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        tap(game, 2, 2); tap(game, 1, 3); game.buttons["playConfirm"].tap()
        XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout: 5))
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        game.buttons["對戰選單"].tap(); game.buttons["matchRecords"].tap()
        XCTAssertTrue(game.staticTexts["新版技能"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.staticTexts["舊版規則"].exists)
        shot(game, "1020-new-default-record")
    }

    func testLegacyResumeDoesNotChangeNextNewGameRules() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--original-rules"])
        startSetupMatch(game)
        tap(game, 2, 5); game.buttons["playConfirm"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "舊版規則")
        game.terminate()
        game.launchArguments.removeAll { $0 == "--original-rules" }
        game.launch()
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 5))
        game.buttons["resumeMatch"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "舊版規則")
        game.buttons["mode-skill"].tap()
        XCTAssertFalse(game.segmentedControls["mageOperation"].exists)
        game.buttons["返回選角"].tap(); game.buttons["exitMatchConfirmed"].tap()
        startSetupMatch(game)
        XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "新版技能")
        game.buttons["對戰選單"].tap(); game.buttons["matchRecords"].tap()
        XCTAssertTrue(game.staticTexts["舊版規則"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.staticTexts["新版技能"].exists)
        shot(game, "1020-legacy-and-new-records")
    }

    /// Owner's actual phone report: the board and the final action row must be
    /// fully visible together, without scrolling to reach confirmation.
    func testPhoneBattleFullViewportWithoutScrolling() {
        XCUIDevice.shared.orientation = .portrait
        let cases: [(String, [String])] = [
            ("7-original", ["--cozy-demo", "--cozy-no-capture", "--mage-body-review"]),
            ("9-dense", ["--cozy-demo", "--cozy-nine", "--cozy-dense", "--mage-body-review"]),
            ("7-candidate-mage", ["--skill-screenshot", "--candidate-skills", "--mage-redeploy"]),
            ("7-candidate-warrior", ["--skill-screenshot", "--candidate-skills"]),
            ("7-computer", ["--play-bot", "--bot-delayed"]),
            ("7-computer-candidate", ["--play-bot", "--bot-delayed"])
        ]
        for (name, flags) in cases {
            let game = app(flags)
            XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
            if name == "7-computer-candidate" {
                XCTAssertEqual(game.staticTexts["currentTurn"].value as? String, "新版技能")
                XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("黑方"))
                game.buttons["mode-skill"].tap()
            }
            let window = game.windows.firstMatch.frame
            let arena = game.otherElements["playArena"].frame
            XCTAssertEqual(game.scrollViews.count, 0, "Normal combat has no vertical scrolling: \(name)")
            XCTAssertTrue(window.contains(arena), "The entire board is visible: \(name)")
            XCTAssertGreaterThan(arena.width, 220, "Preserve a usable board; do not collapse it to hide overflow")
            XCTAssertEqual(arena.height / arena.width, 1.125, accuracy: 0.02)
            for id in ["mode-soldier", "mode-summon", "mode-skill", "playConfirm", "undoOrCancel", "playEndTurn", "actionHelp"] {
                let button = game.buttons[id]
                XCTAssertTrue(button.isHittable, "\(name): \(id) needs no scroll")
                XCTAssertTrue(window.contains(button.frame))
                XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                XCTAssertGreaterThanOrEqual(button.frame.width, 44)
                XCTAssertLessThanOrEqual(button.frame.maxY, window.maxY - (window.height > 800 ? 46 : 12))
            }
            XCTAssertLessThanOrEqual(arena.maxY, game.buttons["playConfirm"].frame.minY)
            if name == "7-original" {
                game.buttons["actionHelp"].tap()
                XCTAssertTrue(game.staticTexts["actionHelpText"].waitForExistence(timeout: 5))
                game.buttons["actionHelpDone"].tap()
                XCTAssertTrue(game.buttons["playEndTurn"].isHittable)
                tap(game, 4, 3); game.buttons["push-Up"].tap()
                XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
                XCTAssertTrue(game.buttons["playConfirm"].isHittable)
                XCTAssertTrue(game.buttons["undoOrCancel"].isHittable)
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
            }
            shot(game, "PHONE-FIT-1016-" + name)
            game.terminate()
        }
    }

    /// Home is navigation, not a new-match command. The existing record and
    /// setup choices must survive opening, backing out, and returning from teaching.
    func testSell03HomeHierarchyNavigationAndResume() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(openSetup: false)
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.buttons["lobbyNewGame"].isHittable)
        XCTAssertFalse(game.buttons["choose-warrior"].exists)
        XCTAssertFalse(game.segmentedControls["matchMode"].exists)
        XCTAssertFalse(game.buttons["resumeMatch"].exists)
        XCTAssertFalse(game.otherElements["playArena"].exists)
        for id in ["lobbyNewGame", "startOnboarding", "lobbyChallenges", "lobbyTools"] {
            XCTAssertGreaterThanOrEqual(game.buttons[id].frame.height, 44)
            XCTAssertTrue(game.buttons[id].isHittable)
        }
        shot(game, "SELL03-R2-01-home")
        game.buttons["lobbyTools"].tap()
        game.buttons["聲音"].tap()
        XCTAssertTrue(game.switches["musicEnabled"].waitForExistence(timeout: 5))
        let music = game.switches["musicEnabled"].value as? String
        let voice = game.switches["voiceEnabled"].value as? String
        game.buttons["audioSettingsDone"].tap()
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupLocal"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["choose-warrior"].exists)
        shot(game, "SELL03-R3-mode-only")
        game.buttons["setupLocal"].tap()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 5))
        game.buttons["choose-rogue"].tap()
        shot(game, "SELL03-R2-02-setup")
        game.buttons["lobbyHomeBack"].tap()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["resumeMatch"].exists, "Opening setup must not create a match record")
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupLocal"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["choose-warrior"].exists)
        shot(game, "SELL03-R3-mode-only")
        game.buttons["setupLocal"].tap()
        XCTAssertTrue(game.buttons["choose-rogue"].isSelected)
        game.buttons["startMatch"].tap()
        XCTAssertTrue(game.staticTexts["白方選擇英雄"].exists)
        XCTAssertFalse(game.otherElements["playArena"].exists)
        shot(game, "SELL03-R3-white-hero")
        game.buttons["lobbyPreviousStep"].tap()
        XCTAssertTrue(game.buttons["choose-rogue"].isSelected)
        startSetupMatch(game)
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        tap(game, 0, 0); game.buttons["playConfirm"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        game.buttons["返回選角"].tap()
        // iOS 26 exposes one alert action as nested buttons with the same identifier.
        let exitAlert = game.alerts["離開目前對戰？"]
        XCTAssertTrue(exitAlert.waitForExistence(timeout: 5))
        exitAlert.buttons["exitMatchConfirmed"].firstMatch.tap()
        game.buttons["lobbyHomeBack"].tap()
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 5))
        shot(game, "SELL03-R2-03-home-saved")
        game.buttons["startOnboarding"].tap()
        XCTAssertTrue(game.staticTexts["onboardTitle"].waitForExistence(timeout: 5))
        game.buttons["onboardExit"].tap()
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "英雄技能入門")
        game.buttons["challengeChapter-advanced"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        game.buttons["challengeBack"].tap()
        XCTAssertTrue(game.buttons["resumeMatch"].waitForExistence(timeout: 5))
        game.buttons["lobbyTools"].tap(); game.buttons["recordLibrary"].tap()
        XCTAssertTrue(game.buttons["recordsDone"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.staticTexts["盜賊 vs 法師 · 7×7"].exists)
        game.buttons["recordsDone"].tap()
        game.buttons["lobbyTools"].tap(); game.buttons["聲音"].tap()
        XCTAssertTrue(game.switches["musicEnabled"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.switches["musicEnabled"].value as? String, music)
        XCTAssertEqual(game.switches["voiceEnabled"].value as? String, voice)
        game.buttons["audioSettingsDone"].tap()
        game.buttons["resumeMatch"].tap()
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        shot(game, "SELL03-R2-04-resume")
    }

    func testSell03SimpleComputerNeedsOnlyOwnHero() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(openSetup: false)
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupComputer"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.segmentedControls["matchRules"].exists)
        shot(game, "SELL03-R3-mode")
        game.buttons["setupComputer"].tap()
        XCTAssertTrue(game.staticTexts["選擇你的英雄"].exists)
        game.buttons["choose-mage"].tap()
        XCTAssertTrue(game.buttons["startMatch"].label.contains("開始對局"))
        XCTAssertFalse(game.otherElements["playArena"].exists)
        XCTAssertFalse(game.staticTexts["lobbySkillDescription"].exists)
        shot(game, "SELL03-R3-own-hero")
        startSetupMatch(game)
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到黑方法師")
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        tap(game,0,0);game.buttons["playConfirm"].tap()
        waitForBot(game,turns: 1)
        XCTAssertEqual(game.staticTexts["currentTurn"].label,"輪到黑方法師")
        shot(game, "SELL03-R3-computer-turn-complete")
    }

    func testSell03LobbySettingsSelectionAndSavedResume() {
        XCUIDevice.shared.orientation = .portrait
        let game = app()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.buttons["startMatch"].isHittable, "The next action is visible without scrolling through settings")
        XCTAssertEqual(game.buttons["lobbyMatchOptions"].value as? String, "已收起")
        XCTAssertFalse(game.segmentedControls["matchMode"].exists)
        shot(game, "SELL03-01-lobby")
        game.buttons["choose-rogue"].tap()
        game.buttons["startMatch"].tap() // Real next step: choose the white hero.
        game.buttons["choose-mage"].tap()
        openLobbySettings(game)
        XCTAssertFalse(game.segmentedControls["matchRules"].exists)
        revealLobbyControl(game, game.segmentedControls["playBoardSize"])
        game.segmentedControls["playBoardSize"].buttons["9 × 9"].tap()
        shot(game, "SELL03-02-settings-candidate-nine")
        game.buttons["lobbyOptionsDone"].tap()
        game.descendants(matching: .any)["lobbySkillDetails"].tap()
        XCTAssertTrue(game.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "調度")).firstMatch.waitForExistence(timeout: 5))
        let windowBounds = game.windows.firstMatch.frame
        XCUIDevice.shared.press(.home); game.activate()
        waitForRestoredLobby(game, windowBounds: windowBounds)
        openLobbySettings(game)
        XCTAssertFalse(game.segmentedControls["matchRules"].exists)
        XCTAssertTrue(game.segmentedControls["playBoardSize"].buttons["9 × 9"].isSelected)
        startSetupMatch(game)
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到黑方盜賊")
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        XCTAssertTrue(game.staticTexts["新版技能 · 沿棋群築壘／法師調度己兵"].exists)
        tap(game, 0, 0, size: 9); game.buttons["playConfirm"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        game.buttons["返回選角"].tap(); game.buttons["exitMatchConfirmed"].tap()
        game.buttons["lobbyHomeBack"].tap()
        for _ in 0..<4 { if game.buttons["resumeMatch"].isHittable { break }; game.swipeDown() }
        XCTAssertTrue(game.buttons["resumeMatch"].isHittable)
        shot(game, "SELL03-03-resume-priority")
        game.buttons["lobbyTools"].tap(); game.buttons["聲音"].tap()
        XCTAssertTrue(game.switches["musicEnabled"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.switches["audioMute"].exists)
        let music = game.switches["musicEnabled"].value as? String
        let muted = game.switches["audioMute"].value as? String
        XCTAssertNotNil(music); XCTAssertNotNil(muted)
        game.buttons["audioSettingsDone"].tap()
        game.buttons["lobbyTools"].tap(); game.buttons["聲音"].tap()
        XCTAssertTrue(game.switches["musicEnabled"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.switches["musicEnabled"].value as? String, music)
        XCTAssertEqual(game.switches["audioMute"].value as? String, muted)
        game.buttons["audioSettingsDone"].tap()
        let settingsDismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: game.buttons["audioSettingsDone"])
        XCTAssertEqual(XCTWaiter.wait(for: [settingsDismissed], timeout: 5), .completed)
        for _ in 0..<4 {
            if game.buttons["resumeMatch"].isHittable { break }
            game.swipeDown()
        }
        let hierarchy = XCTAttachment(string: game.debugDescription)
        hierarchy.name = "1020-home-after-sound-settings"; hierarchy.lifetime = .keepAlways; add(hierarchy)
        shot(game, "1020-home-after-sound-settings")
        XCTAssertTrue(game.buttons["resumeMatch"].isHittable)
        game.buttons["resumeMatch"].tap()
        XCTAssertTrue(game.staticTexts["currentTurn"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        tap(game, 1, 0, size: 9)
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "B1")
        shot(game, "SELL03-04-resumed-nine-preview")
    }

    func testSell03LobbySmallAccessibilityAndTeachingEntry() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--cozy-reduced", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.buttons["startMatch"].isHittable)
        for id in ["startMatch", "choose-warrior", "choose-mage", "choose-rogue", "lobbySoundSettings"] {
            XCTAssertGreaterThanOrEqual(game.buttons[id].frame.height, 44)
            XCTAssertGreaterThanOrEqual(game.buttons[id].frame.width, 44)
        }
        game.buttons["lobbyHomeBack"].tap()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(game.buttons["lobbyNewGame"].frame.height, 44)
        XCTAssertTrue(game.buttons["startOnboarding"].isHittable)
        XCTAssertTrue(game.buttons["lobbyChallenges"].isHittable)
        XCTAssertGreaterThanOrEqual(game.buttons["lobbyChallenges"].frame.height, 44)
        XCTAssertLessThanOrEqual(game.buttons["lobbyChallenges"].frame.maxX, game.windows.firstMatch.frame.maxX - 16)
        shot(game, "SELL03-R2-small-larger-text")
        game.buttons["startOnboarding"].tap()
        XCTAssertTrue(game.staticTexts["onboardTitle"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["onboardTitle"].label, "保護主將，包圍對手")
        game.buttons["onboardExit"].tap()
        XCTAssertTrue(game.buttons["lobbyNewGame"].waitForExistence(timeout: 5))
        game.buttons["lobbyNewGame"].tap()
        XCTAssertTrue(game.buttons["setupLocal"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["choose-warrior"].exists)
        shot(game, "SELL03-R3-mode-only")
        game.buttons["setupLocal"].tap()
        XCTAssertTrue(game.buttons["startMatch"].waitForExistence(timeout: 5))
        startSetupMatch(game)
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到黑方戰士")
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
    }

    // On iPad, activation returns while the system is still scaling the window back
    // from Home. Wait for stable full-window geometry before synthesizing a tap.
    private func waitForRestoredLobby(_ app: XCUIApplication, windowBounds: CGRect) {
        var previous = CGRect.zero
        var stableSince = Date()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let window = app.windows.firstMatch.frame
            let button = app.buttons["startMatch"]
            let current = button.frame
            guard abs(window.width - windowBounds.width) < 1,
                  abs(window.height - windowBounds.height) < 1,
                  button.isHittable else { stableSince = Date(); return false }
            if current != previous { previous = current; stableSince = Date(); return false }
            return Date().timeIntervalSince(stableSince) >= 0.8
        }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 8), .completed)
    }

    private func revealLobbyControl(_ app: XCUIApplication, _ element: XCUIElement) {
        func fullyVisible() -> Bool {
            guard element.exists && element.isHittable else { return false }
            let visible = app.scrollViews.firstMatch.frame.insetBy(dx: 0, dy: 2)
            return visible.contains(element.frame)
        }
        for _ in 0..<18 {
            if fullyVisible() { break }
            let scroll = app.scrollViews.firstMatch
            let goesDown = element.exists && element.frame.minY < scroll.frame.minY
            let from = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: goesDown ? 0.35 : 0.65))
            let to = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: goesDown ? 0.65 : 0.35))
            from.press(forDuration: 0.1, thenDragTo: to)
        }
        let geometry = XCTAttachment(string: "control=\(element.identifier); controlFrame=\(element.frame); scrollFrame=\(app.scrollViews.firstMatch.frame)")
        geometry.name = "Lobby-control-geometry"; geometry.lifetime = .keepAlways; add(geometry)
        XCTAssertTrue(fullyVisible(), "Scroll the whole control above the fixed start action before tapping")
    }
    private func openLobbySettings(_ app: XCUIApplication) {
        if !app.buttons["lobbyOptionsDone"].exists { app.buttons["lobbyMatchOptions"].tap() }
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout: 5))
    }
    private func waitForBattleReady(_ app: XCUIApplication) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
    }
    private func startSetupMatch(_ app: XCUIApplication) {
        if app.buttons["lobbyOptionsDone"].exists { app.buttons["lobbyOptionsDone"].tap() }
        if app.buttons["setupLocal"].exists { app.buttons["setupLocal"].tap() }
        let next = app.buttons["startMatch"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        if next.label.contains("下一步") { next.tap() }
        XCTAssertTrue(app.buttons["startMatch"].label.contains("開始對局"))
        app.buttons["startMatch"].tap()
    }

    /// Reviewed Magic Hand fixture: black has 2 AP / 4 Mana; E4 may push up.
    /// These are receipt expectations, independent of the new presentation styling.
    func testSell01CFourStatesAndInputSafety() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--cozy-demo", "--cozy-no-capture", "--mage-body-review"])
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        func comfortableBottom(_ state: String) {
            let frame = game.buttons["playConfirm"].frame, screen = game.windows.firstMatch.frame
            let clearance: CGFloat = screen.height > 800 ? 46 : 16
            XCTAssertLessThanOrEqual(frame.maxY, screen.maxY - clearance, "\(state): confirmation stays clear of system bottom area")
            let note = XCTAttachment(string: "state=\(state); screen=\(screen); confirm=\(frame); requiredBottomClearance=\(clearance)")
            note.name = "SELL01C-R1-bottom-" + state; note.lifetime = .keepAlways; add(note)
        }
        game.buttons["mode-soldier"].tap()
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.buttons["playConfirm"].isHittable, "Confirmation must remain on screen even before selection")
        comfortableBottom("01-no-selection"); shot(game, "SELL01C-R1-01-no-selection")
        game.buttons["mode-skill"].tap()
        XCTAssertTrue((game.buttons["mode-skill"].value as? String ?? "").contains("等待目標"))
        comfortableBottom("02-skill-awaiting-target"); shot(game, "SELL01C-R1-02-skill-awaiting-target")
        tap(game, 4, 3); game.buttons["push-Up"].tap()
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "E4")
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(game.staticTexts["sellPreviewEffect"].label, "將 E4 士兵推至 E3")
        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
        XCTAssertTrue(game.buttons["playConfirm"].label.contains("確認施法"))
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.staticTexts["能量 4/6 · 4 氣"].exists)
        comfortableBottom("03-legal-preview"); shot(game, "SELL01C-R1-03-legal-preview")
        game.buttons["undoOrCancel"].tap()
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "")
        XCTAssertTrue(game.staticTexts["能量 4/6 · 4 氣"].exists)
        tap(game, 4, 3); game.buttons["push-Up"].tap()
        game.buttons["playConfirm"].doubleTap()
        XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.staticTexts["能量 2/6 · 4 氣"].exists)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: game.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        XCTAssertTrue((game.buttons["mode-skill"].value as? String ?? "").contains("落定"))
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        comfortableBottom("04-confirmed-settled"); shot(game, "SELL01C-R1-04-confirmed-settled")
        for id in ["mode-soldier", "playConfirm", "undoOrCancel", "playEndTurn", "actionHelp"] {
            XCTAssertGreaterThanOrEqual(game.buttons[id].frame.width, 44)
            XCTAssertGreaterThanOrEqual(game.buttons[id].frame.height, 44)
        }
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.staticTexts["能量 4/6 · 4 氣"].exists)
        game.buttons["mode-soldier"].tap()
        tap(game, 3, 1) // Reviewed fixture's white commander: occupied targets cannot awaken confirmation.
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        tap(game, 0, 0); XCTAssertEqual(game.otherElements["playArena"].value as? String, "A1")
        tap(game, 1, 0); XCTAssertEqual(game.otherElements["playArena"].value as? String, "B1")
        XCTAssertEqual(game.staticTexts["sellPreviewEffect"].label, "於 B1 放置士兵")
        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP")
        cozyConfirm(game)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        game.buttons["playEndTurn"].tap()
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
        comfortableBottom("05-handoff"); shot(game, "SELL01C-R1-05-handoff")
    }

    func testSell01CReceiptSummarySummonAndCandidate() {
        let summon = app(["--summon-demo", "--hero", "mage", "--mage-body-review"])
        XCTAssertTrue(summon.staticTexts["2 AP"].waitForExistence(timeout: 10))
        tap(summon, 3, 4)
        XCTAssertEqual(summon.staticTexts["sellPreviewEffect"].label, "於 D5 召喚英雄")
        XCTAssertEqual(summon.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 3 能量")
        summon.buttons["undoOrCancel"].tap()
        XCTAssertFalse(summon.staticTexts["sellPreviewCost"].exists)
        XCTAssertTrue(summon.staticTexts["2 AP"].exists)
        summon.terminate()
        let candidate = app(["--skill-screenshot", "--candidate-skills", "--mage-redeploy"])
        XCTAssertTrue(candidate.otherElements["playArena"].waitForExistence(timeout: 10))
        tap(candidate, 3, 2); tap(candidate, 1, 1)
        XCTAssertEqual(candidate.staticTexts["sellPreviewEffect"].label, "調度 D3 己兵至 B2")
        XCTAssertEqual(candidate.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
        XCTAssertTrue(candidate.buttons["playConfirm"].isEnabled)
        candidate.buttons["undoOrCancel"].tap()
        XCTAssertFalse(candidate.staticTexts["sellPreviewCost"].exists)
    }

    /// UI expectations use the reviewed ANIM-01 fixture and published grid coordinates.
    func testSell01ANativeSelectionPreviewCancelCommitAndHandoff() {
        let game = app(["--cozy-demo", "--cozy-no-capture", "--mage-body-review"])
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.staticTexts["能量 4/6 · 4 氣"].exists)
        shot(game, "SELL01A-7-before")
        tap(game, 4, 3)
        game.buttons["push-Up"].tap()
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(game.staticTexts["2 AP"].exists, "Preview does not spend AP")
        XCTAssertTrue(game.staticTexts["能量 4/6 · 4 氣"].exists, "Preview does not spend Mana")
        shot(game, "SELL01A-7-preview")
        game.buttons["undoOrCancel"].tap()
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "")
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        tap(game, 4, 3); game.buttons["push-Up"].tap(); game.buttons["playConfirm"].doubleTap()
        XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.staticTexts["能量 2/6 · 4 氣"].exists)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: game.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        shot(game, "SELL01A-7-after-push")
        game.buttons["mode-soldier"].tap()
        tap(game, 0, 0); XCTAssertEqual(game.otherElements["playArena"].value as? String, "A1")
        tap(game, 1, 0); XCTAssertEqual(game.otherElements["playArena"].value as? String, "B1", "Adjacent taps select distinct intersections")
        cozyConfirm(game)
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        shot(game, "SELL01A-7-handoff")
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        game.buttons["返回選角"].tap()
        shot(game, "SELL01A-exit-dialog")
        XCTAssertTrue(game.buttons["留在對戰"].waitForExistence(timeout: 5))
        game.buttons["留在對戰"].tap()
        XCTAssertTrue(game.staticTexts["1 AP"].exists, "Cancelled exit preserves the match")
        XCUIDevice.shared.press(.home)
        let background = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in game.state == .runningBackground }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [background], timeout: 5), .completed)
        game.activate()
        let foreground = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in game.state == .runningForeground }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [foreground], timeout: 5), .completed)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        shot(game, "SELL01A-after-background")
        game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
    }

    func testSell01ASmallDenseLargerTextAndReducedMotion() {
        let dense = app(["--cozy-demo", "--cozy-nine", "--cozy-dense", "--cozy-320", "--mage-body-review"])
        let arena = dense.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        XCTAssertEqual(arena.frame.width / arena.frame.height, 8/9.0, accuracy: 0.02)
        for id in ["mode-soldier", "playConfirm", "undoOrCancel", "playEndTurn", "actionHelp"] {
            let control = dense.buttons[id]
            XCTAssertGreaterThanOrEqual(control.frame.width, 44)
            XCTAssertGreaterThanOrEqual(control.frame.height, 44)
        }
        dense.buttons["mode-soldier"].tap(); tap(dense, 0, 0, size: 9); tap(dense, 1, 0, size: 9)
        XCTAssertEqual(arena.value as? String, "B1")
        dense.buttons["undoOrCancel"].tap()
        shot(dense, "SELL01A-320-9-dense"); dense.terminate()
        let large = app(["--cozy-demo", "--cozy-no-capture", "--cozy-reduced", "--mage-body-review", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(large.otherElements["playArena"].waitForExistence(timeout: 10))
        large.buttons["actionHelp"].tap()
        XCTAssertTrue(large.staticTexts["actionHelpText"].exists)
        shot(large, "SELL01A-accessibility-largest-help")
        large.buttons["actionHelp"].tap()
        for _ in 0..<4 { if large.otherElements["playArena"].isHittable { break }; large.swipeDown() }
        tap(large, 4, 3)
        for _ in 0..<5 { if large.buttons["push-Up"].isHittable { break }; large.swipeUp() }
        large.buttons["push-Up"].tap(); cozyConfirm(large)
        XCTAssertTrue(large.staticTexts["1 AP"].waitForExistence(timeout: 5))
        shot(large, "SELL01A-accessibility-largest-reduced-result")
    }

    func testSell01ATabletRotationRetainsSelection() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let game = app(["--cozy-demo", "--cozy-no-capture", "--mage-body-review"])
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
        shot(game, "SELL01A-ipad-portrait")
        tap(game, 4, 3); game.buttons["push-Up"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(game.buttons["playConfirm"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "E4")
        XCTAssertGreaterThanOrEqual(game.buttons["playConfirm"].frame.minX, game.otherElements["playArena"].frame.maxX)
        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
        XCTAssertTrue(game.buttons["playConfirm"].isHittable)
        shot(game, "SELL01C-R1-ipad-landscape-preview")
        XCUIDevice.shared.orientation = .portrait
        XCTAssertEqual(game.otherElements["playArena"].value as? String, "E4")
        cozyConfirm(game); XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout: 5))
        game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
    }

    func testThreeClassVFXReceiptAndNativeAudit() {
        let game = app(["--vfx-demo","--hero","warrior","--hero-body-review","--vfx-audit","--cozy-390"])
        let status = game.staticTexts["skillVFXAudit"]
        XCTAssertTrue(status.waitForExistence(timeout:10))
        let done = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label BEGINSWITH 'PASS'"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[done],timeout:100),.completed)
        shot(game,"VFX-receipt-render-safety-audit")
    }
    func testThreeClassVFXNativeRecordingWalkthrough() {
        func hold(_ t:Double) {let w = XCTNSPredicateExpectation(predicate:NSPredicate{_,_ in false},object:nil);_ = XCTWaiter.wait(for:[w],timeout:t)}
        for hero in ["warrior","mage","rogue"] {
            for scenario in ["black","capture","whiteCapture","dense","reduced","white"] {
                var flags = ["--vfx-demo","--hero",hero,"--hero-body-review","--audio-trace","--vfx-record-marker"]
                if scenario == "capture" || scenario == "whiteCapture" {flags += ["--vfx-capture"]}
                if ["whiteCapture","dense","reduced","white"].contains(scenario) {flags += ["--white-caster"]}
                let dense = scenario == "dense" || scenario == "reduced"
                flags += dense ? ["--cozy-nine","--cozy-320","--vfx-dense"] : ["--cozy-390"]
                if scenario == "reduced" {flags += ["--cozy-reduced"]}
                if scenario == "white" && hero == "mage" {flags += ["--vfx-enemy"]}
                let game = app(flags),size = dense ? 9 : 7
                XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout:10))
                XCTAssertEqual(game.otherElements["playArena"].frame.width/game.otherElements["playArena"].frame.height,8/9.0,accuracy:0.02)
                func select() {
                    if hero == "warrior" {tap(game,2,3,size:size);tap(game,4,3,size:size)}
                    else {tap(game,4,3,size:size)}
                    if hero == "mage" {
                        let up = game.buttons["push-Up"]
                        for _ in 0..<3 {if up.isHittable {break};game.swipeUp()}
                        XCTAssertTrue(up.isEnabled);up.tap()
                    }
                }
                select();XCTAssertTrue(game.staticTexts["2 AP"].exists);shot(game,"VFX-\(hero)-\(scenario)-preview")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                select();cozyConfirm(game);hold(2.2)
                if scenario == "capture" || scenario == "whiteCapture" {
                    XCTAssertTrue(game.staticTexts[scenario == "whiteCapture" ? "白方獲勝" : "黑方獲勝"].waitForExistence(timeout: 5))
                    XCTAssertFalse(game.staticTexts["1 AP"].exists)
                } else { XCTAssertTrue(game.staticTexts["1 AP"].exists) }
                shot(game,"VFX-\(hero)-\(scenario)-settled")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home);game.activate();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
    }
    func testThreeClassVFX320DenseNormalReducedAndBackground() {
        for hero in ["warrior","mage","rogue"] {for reduced in [false,true] {
            var flags = ["--vfx-demo","--hero",hero,"--vfx-dense","--cozy-nine","--cozy-320","--hero-body-review"]
            if reduced {flags += ["--white-caster","--cozy-reduced"]}
            let game = app(flags),arena = game.otherElements["playArena"]
            XCTAssertTrue(arena.waitForExistence(timeout:10));XCTAssertEqual(arena.frame.width,312,accuracy:1)
            XCTAssertEqual(arena.frame.width/arena.frame.height,8/9.0,accuracy:0.02)
            if hero == "warrior" {tap(game,2,3,size:9);tap(game,4,3,size:9)} else {tap(game,4,3,size:9)}
            if hero == "mage" {
                let up = game.buttons["push-Up"]
                for _ in 0..<3 {if up.isHittable {break};game.swipeUp()};up.tap()
            }
            cozyConfirm(game);XCUIDevice.shared.press(.home);game.activate()
            XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout:5))
            shot(game,"VFX-320-9-\(hero)-background-reduced-\(reduced)")
            game.buttons["mode-soldier"].tap();tap(game,1,1,size:9);cozyConfirm(game)
            XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout:5))
            game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["1 AP"].exists)
            game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists);game.terminate()
        }}
    }

    func testHeroBodySharedReceiptAndCancellationAudit() {
        let game = app(["--hero-body-demo","--hero","warrior","--hero-body-review","--mage-no-effects","--hero-body-audit"])
        let status = game.staticTexts["heroBodyAudit"]
        XCTAssertTrue(status.waitForExistence(timeout:10))
        let done = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label BEGINSWITH 'PASS'"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[done],timeout:80),.completed)
        shot(game,"HERO-body-receipt-cancellation-audit")
    }
    func testWarriorRogueNativeRecordingWalkthrough() {
        recordHeroBodyWalkthrough(["warrior","rogue"])
    }
    func testWarriorBody02NativeRecordingWalkthrough() {
        recordHeroBodyWalkthrough(["warrior"])
    }
    private func recordHeroBodyWalkthrough(_ heroes: [String]) {
        func hold(_ t:Double) { let w = XCTNSPredicateExpectation(predicate:NSPredicate{_,_ in false},object:nil);_ = XCTWaiter.wait(for:[w],timeout:t) }
        for hero in heroes {
            for scenario in ["summon","black","capture","white","dense","reduced"] {
                var flags = ["--hero-body-demo","--hero",hero,"--hero-body-review","--mage-no-effects","--audio-trace"]
                if scenario == "summon" {flags += ["--hero-body-summon"]}
                if scenario == "capture" || scenario == "white" {flags += ["--hero-body-capture"]}
                if scenario == "white" || scenario == "dense" || scenario == "reduced" {flags += ["--white-caster"]}
                let dense = scenario == "dense" || scenario == "reduced"
                if dense {flags += ["--cozy-nine","--cozy-320","--hero-body-dense"]}
                else {flags += ["--cozy-390"]}
                if scenario == "reduced" {flags += ["--cozy-reduced"]}
                let game = app(flags),size = dense ? 9 : 7
                XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout:10))
                XCTAssertEqual(game.otherElements["playArena"].frame.width/game.otherElements["playArena"].frame.height,8/9.0,accuracy:0.02)
                func select() {
                    if scenario == "summon" {tap(game,3,4,size:size)}
                    else if hero == "warrior" {tap(game,2,3,size:size);tap(game,4,3,size:size)}
                    else {tap(game,4,3,size:size)}
                }
                select();XCTAssertTrue(game.staticTexts["2 AP"].exists);shot(game,"HERO-\(hero)-\(scenario)-preview")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                select();cozyConfirm(game);hold(2.2)
                if scenario == "capture" || scenario == "white" {
                    XCTAssertTrue(game.staticTexts[scenario == "white" ? "白方獲勝" : "黑方獲勝"].waitForExistence(timeout: 5))
                    XCTAssertFalse(game.staticTexts["1 AP"].exists)
                } else { XCTAssertTrue(game.staticTexts["1 AP"].exists) }
                shot(game,"HERO-\(hero)-\(scenario)-settled")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home);game.activate();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
        let gallery = app(["--hero-pose-review"])
        XCTAssertTrue(gallery.buttons["heroPoseCast"].waitForExistence(timeout:10))
        gallery.buttons["heroPoseSummon"].tap();hold(1.2);gallery.buttons["heroPoseCast"].tap();hold(1.2)
        if heroes.contains("rogue") {
            gallery.segmentedControls["heroPoseClass"].buttons["盜賊"].tap();gallery.buttons["heroPoseCast"].tap();hold(1.2)
        }
        shot(gallery,"HERO-closeup-supplement")
    }
    func testHeroBody320NineDenseNormalAndReduced() {
        for hero in ["warrior","rogue"] {for reduced in [false,true] {
            var flags = ["--hero-body-demo","--hero",hero,"--hero-body-dense","--cozy-nine","--cozy-320","--hero-body-review","--mage-no-effects"]
            if reduced {flags += ["--white-caster","--cozy-reduced"]}
            let game = app(flags),arena = game.otherElements["playArena"]
            XCTAssertTrue(arena.waitForExistence(timeout:10));XCTAssertEqual(arena.frame.width,312,accuracy:1)
            XCTAssertEqual(arena.frame.width/arena.frame.height,8/9.0,accuracy:0.02)
            if hero == "warrior" {tap(game,2,3,size:9);tap(game,4,3,size:9)} else {tap(game,4,3,size:9)}
            XCTAssertTrue(game.staticTexts["2 AP"].exists);cozyConfirm(game)
            XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout:5));shot(game,"HERO-320-9-\(hero)-reduced-\(reduced)")
            game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists);game.terminate()
        }}
    }
    func testHeroBodySecondAPAndBackgroundRemainPlayable() {
        for hero in ["warrior","rogue"] {
            let game = app(["--hero-body-demo","--hero",hero,"--hero-body-review","--mage-no-effects"])
            if hero == "warrior" {tap(game,2,3);tap(game,4,3)} else {tap(game,4,3)}
            cozyConfirm(game)
            let enabled = XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:game.buttons["mode-soldier"])
            XCTAssertEqual(XCTWaiter.wait(for:[enabled],timeout:5),.completed)
            game.buttons["mode-soldier"].tap();tap(game,0,0);cozyConfirm(game)
            XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout:5));XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"))
            game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["1 AP"].exists)
            game.terminate()
        }
    }

    func testMageBodySharedTimelineAndCancellationNativeAudit() {
        let game = app(["--cozy-demo","--mage-body-review","--mage-no-effects","--mage-body-audit"])
        let status = game.staticTexts["mageBodyAudit"]
        XCTAssertTrue(status.waitForExistence(timeout:10))
        let done = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label BEGINSWITH 'PASS'"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[done],timeout:80),.completed)
        shot(game,"MAGE-body-actual-owner-audit")
    }
    func testMageBody320DenseBothFactionsEffectsAndReducedMotion() {
        for reduced in [false,true] {
            var flags = ["--cozy-demo","--cozy-nine","--cozy-320","--mage-dense","--white-caster","--mage-body-review"]
            if reduced { flags += ["--cozy-reduced","--mage-no-effects"] }
            let game = app(flags)
            let arena = game.otherElements["playArena"]
            XCTAssertTrue(arena.waitForExistence(timeout:10))
            XCTAssertEqual(arena.frame.width/arena.frame.height,8/9.0,accuracy:0.02)
            tap(game,4,3,size:9)
            for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
            game.buttons["push-Up"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
            cozyConfirm(game); XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout:5))
            shot(game,"MAGE-320-9-dense-white-\(reduced)")
            game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
            game.terminate()
        }
    }
    func testMageBodyNativeRecordingWalkthrough() {
        func hold(_ t: Double) {
            let wait = XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in false },object:nil)
            _ = XCTWaiter.wait(for:[wait],timeout:t)
        }
        for compact in [false,true] {
            let extra = compact ? ["--mage-compact"] : []
            let summon = app(["--summon-demo","--hero","mage","--mage-body-review","--mage-no-effects","--audio-trace"]+extra)
            XCTAssertTrue(summon.staticTexts["2 AP"].waitForExistence(timeout:10))
            tap(summon,3,4); cozyConfirm(summon); hold(1.3)
            XCTAssertTrue(summon.staticTexts["1 AP"].exists); shot(summon,"MAGE-summon-no-fx-\(compact)")
            summon.buttons["undoOrCancel"].tap(); XCTAssertTrue(summon.staticTexts["2 AP"].exists); summon.terminate()
            for capture in [false,true] {
                let flags = capture ? [] : ["--cozy-no-capture"]
                let game = app(["--cozy-demo","--cozy-390","--mage-body-review","--mage-no-effects","--audio-trace"]+extra+flags)
                tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap(); shot(game,"MAGE-preview-original-no-fx")
                game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.swipeDown(); tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap(); cozyConfirm(game); hold(1.3)
                if capture {
                    XCTAssertTrue(game.staticTexts["黑方獲勝"].waitForExistence(timeout: 5))
                    XCTAssertFalse(game.staticTexts["1 AP"].exists)
                } else { XCTAssertTrue(game.staticTexts["1 AP"].exists) }
                shot(game,"MAGE-push-no-fx-\(capture)-\(compact)")
                game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home); game.activate(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
        let pose = app(["--mage-pose-review"])
        XCTAssertTrue(pose.buttons["magePoseSummon"].waitForExistence(timeout:10))
        pose.buttons["magePoseSummon"].tap(); hold(1.2)
        pose.buttons["magePoseCast"].tap(); hold(1.2)
        shot(pose,"MAGE-closeup-no-fx-pose-gallery")
    }
    func testMageM3SameBoardM2M3Recording() {
        func hold(_ t: Double) {
            let wait = XCTNSPredicateExpectation(predicate:NSPredicate { _,_ in false },object:nil)
            _ = XCTWaiter.wait(for:[wait],timeout:t)
        }
        for mode in ["m2-full","m3-full","m3-compact"] {
            var extra: [String] = []
            if mode == "m2-full" { extra += ["--mage-m2-reference"] }
            else { extra += ["--mage-m3-reference"] }
            if mode == "m3-compact" { extra += ["--mage-compact"] }
            let summon = app(["--summon-demo","--hero","mage","--mage-body-review","--mage-no-effects","--audio-trace"]+extra)
            XCTAssertTrue(summon.staticTexts["2 AP"].waitForExistence(timeout:10))
            tap(summon,3,4);cozyConfirm(summon);hold(1.2)
            XCTAssertTrue(summon.staticTexts["1 AP"].exists);shot(summon,"M3-"+mode+"-summon")
            summon.buttons["undoOrCancel"].tap();XCTAssertTrue(summon.staticTexts["2 AP"].exists);summon.terminate()
            for capture in [false,true] {
                let flags = capture ? [] : ["--cozy-no-capture"]
                let game = app(["--cozy-demo","--cozy-390","--mage-body-review","--mage-no-effects","--audio-trace"]+extra+flags)
                tap(game,4,3);game.buttons["push-Up"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists);shot(game,"M3-"+mode+"-preview")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                tap(game,4,3);game.buttons["push-Up"].tap();cozyConfirm(game);hold(1.2)
                if capture {
                    XCTAssertTrue(game.staticTexts["黑方獲勝"].waitForExistence(timeout: 5))
                    XCTAssertFalse(game.staticTexts["1 AP"].exists)
                } else { XCTAssertTrue(game.staticTexts["1 AP"].exists) }
                shot(game,"M3-"+mode+"-push-\(capture)")
                game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home);game.activate();XCTAssertTrue(game.staticTexts["2 AP"].exists);game.terminate()
            }
        }
        let fx = app(["--cozy-demo","--cozy-390","--mage-body-review","--audio-trace"])
        tap(fx,4,3);fx.buttons["push-Up"].tap();cozyConfirm(fx);hold(1.2)
        XCTAssertTrue(fx.staticTexts["黑方獲勝"].exists);shot(fx,"M3-directed-fx-after-success");fx.terminate()
        let review = app(["--mage-pose-review"])
        XCTAssertTrue(review.buttons["magePoseCast"].waitForExistence(timeout:10))
        review.buttons["magePoseCast"].tap();hold(1.2);shot(review,"M3-closeup-supplement")
    }
    func testMageR1ReferenceNormalSpeedRecording() { mageR1Walkthrough(reference: true) }
    func testMageR1CandidateNormalSpeedRecording() { mageR1Walkthrough(reference: false) }
    /// AM1-04: the reviewed capture fixture has one opposing commander whose
    /// last liberty is (4,2). The actual friendly push must win, then undo.
    func testMageR1Continuation04WinBothFactionsNormalAndReduced() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        for white in [false, true] {
            for reduced in [false, true] {
                let row = "AM1-04-\(white ? "white" : "black")-\(reduced ? "reduced" : "normal")"
                var flags = ["--cozy-demo", "--mage-body-review", "--audio-trace", "--vfx-record-marker"]
                if white { flags.append("--white-caster") }
                if reduced { flags.append("--cozy-reduced") }
                let game = app(flags)
                XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 10))
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                let winner = white ? "白方獲勝" : "黑方獲勝"
                XCTAssertFalse(game.staticTexts[winner].exists)
                shot(game, row + "-ready")
                tap(game, 4, 3); game.buttons["push-Up"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
                XCTAssertFalse(game.staticTexts[winner].exists, "A winning preview is not a committed win")
                shot(game, row + "-preview")
                game.buttons["playConfirm"].tap()
                // One native accessibility snapshot is internally consistent;
                // do not compare a phase query with a later result query while
                // the 950ms animation may finish between them. XCTest may idle
                // until completion, so raw marker-registered video also remains
                // mandatory evidence for the full temporal clause.
                let stageSnapshot = game.debugDescription
                let activeStageObserved = stageSnapshot.contains("label: '行動演出中'")
                if !reduced && activeStageObserved {
                    XCTAssertFalse(stageSnapshot.contains("identifier: 'matchResult'"))
                    XCTAssertFalse(stageSnapshot.contains(winner))
                    XCTAssertFalse(stageSnapshot.contains("label: '對戰結束'"))
                }
                if reduced { XCTAssertFalse(activeStageObserved) }
                let stageAttachment = XCTAttachment(string: stageSnapshot)
                stageAttachment.name = row + "-post-confirm-accessibility.txt"
                stageAttachment.lifetime = .keepAlways; add(stageAttachment)
                XCTAssertTrue(game.staticTexts[winner].waitForExistence(timeout: 5))
                XCTAssertFalse(game.staticTexts["1 AP"].exists)
                XCTAssertFalse(game.buttons["playConfirm"].exists)
                XCTAssertFalse(game.buttons["playEndTurn"].exists)
                shot(game, row + "-committed-win")
                // Keep the already asserted result visible for the raw native
                // recording before undo. This does not alter playback speed or
                // assert a wall-clock phase; the encoded AP marker registers it.
                let reviewHold = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in false }, object: nil)
                _ = XCTWaiter.wait(for: [reviewHold], timeout: 1.25)
                mageContinuationRow(row, game: game, metadata: [
                    "contract": "AM1-04", "caster": white ? "white" : "black", "reducedMotion": reduced,
                    "boardSize": 7, "fixture": "Anim01Fixture.state(capture:true)",
                    "expectedAction": "(4,3) up to (4,2)", "expectedCapturedCommander": [3,2],
                    "expectedWinner": white ? "two" : "one", "expectedAPBefore": 2, "expectedAPAfter": 1,
                    "activeStageObservedInAccessibility": activeStageObserved,
                    "source": "Real Simulator UI; the separate native receipt supplies board, resources and event order"
                ])
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCTAssertFalse(game.staticTexts[winner].exists)
                XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
                shot(game, row + "-undo-restored")
                game.terminate()
            }
        }
    }
    /// AM1-07: 16 scenarios per device, not 16 independent XCTest methods.
    /// iPhone's shipped orientation contract is portrait-only. A landscape
    /// device rotation proves stability there, not an unsupported landscape UI.
    func testMageR1Continuation07DeviceBoardFactionMotionMatrix() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        for landscape in [false, true] {
            for size in [7, 9] {
                for white in [false, true] {
                    for reduced in [false, true] {
                        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
                        let row = "AM1-07-\(landscape ? "device-landscape" : "portrait")-\(size)-\(white ? "white" : "black")-\(reduced ? "reduced" : "normal")"
                        var flags = ["--cozy-demo", "--cozy-no-capture", "--mage-body-review", "--audio-trace"]
                        if size == 9 { flags += ["--cozy-nine", "--mage-dense"] }
                        if white { flags.append("--white-caster") }
                        if reduced { flags.append("--cozy-reduced") }
                        let game = app(flags)
                        let arena = game.otherElements["playArena"]
                        XCTAssertTrue(arena.waitForExistence(timeout: 10))
                        let initial = game.windows.firstMatch.frame
                        let tablet = min(initial.width, initial.height) > 600
                        let landscapeRender = tablet && landscape
                        let oriented = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                            let frame = game.windows.firstMatch.frame
                            return landscapeRender ? frame.width > frame.height : frame.width < frame.height
                        }, object: nil)
                        XCTAssertEqual(XCTWaiter.wait(for: [oriented], timeout: 8), .completed)
                        let window = game.windows.firstMatch.frame
                        XCTAssertTrue(window.contains(arena.frame), "The actual board fits the native viewport: \(row)")
                        XCTAssertEqual(arena.frame.height / arena.frame.width, 1.125, accuracy: 0.02)
                        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains(white ? "白方" : "黑方"))
                        XCTAssertTrue(game.staticTexts["2 AP"].exists)
                        for id in ["mode-skill", "playConfirm", "undoOrCancel", "playEndTurn"] {
                            let button = game.buttons[id]
                            XCTAssertTrue(button.isHittable, "\(row): \(id) remains accessible")
                            XCTAssertTrue(window.contains(button.frame))
                            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
                            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                        }
                        shot(game, row + "-ready")
                        tap(game, 4, 3, size: size); game.buttons["push-Up"].tap()
                        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
                        XCTAssertEqual(game.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
                        XCTAssertTrue(game.staticTexts["2 AP"].exists)
                        shot(game, row + "-preview")
                        game.buttons["undoOrCancel"].tap()
                        XCTAssertTrue(game.staticTexts["2 AP"].exists)
                        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
                        tap(game, 4, 3, size: size); game.buttons["push-Up"].tap()
                        game.buttons["playConfirm"].tap()
                        let recovered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: game.buttons["mode-soldier"])
                        XCTAssertEqual(XCTWaiter.wait(for: [recovered], timeout: 5), .completed)
                        XCTAssertTrue(game.staticTexts["1 AP"].exists)
                        XCTAssertFalse(game.staticTexts["黑方獲勝"].exists)
                        XCTAssertFalse(game.staticTexts["白方獲勝"].exists)
                        shot(game, row + "-landed")
                        mageContinuationRow(row, game: game, metadata: [
                            "contract": "AM1-07", "boardSize": size, "caster": white ? "white" : "black",
                            "reducedMotion": reduced, "requestedDeviceOrientation": landscape ? "landscapeLeft" : "portrait",
                            "renderedOrientation": landscapeRender ? "landscape" : "portrait", "tablet": tablet,
                            "coverage": !tablet && landscape ? "phone rotation stability; landscape rendering unsupported" : "supported native render",
                            "fixture": size == 9 ? "Anim01Fixture.denseState(caster)" : "Anim01Fixture.state(capture:false)",
                            "expectedAction": "(4,3) up to (4,2)", "expectedAPBefore": 2, "expectedAPAfter": 1,
                            "humanReadability": "NOT ACCEPTED; real-size screenshots are review material"
                        ])
                        game.buttons["undoOrCancel"].tap()
                        XCTAssertTrue(game.staticTexts["2 AP"].exists)
                        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
                        shot(game, row + "-undo-restored")
                        game.terminate()
                    }
                }
            }
        }
    }
    private func mageContinuationRow(_ row: String, game: XCUIApplication, metadata: [String: Any]) {
        var value = metadata
        let window = game.windows.firstMatch.frame, arena = game.otherElements["playArena"].frame
        value["row"] = row
        value["window"] = [window.minX, window.minY, window.width, window.height]
        value["arena"] = [arena.minX, arena.minY, arena.width, arena.height]
        let ap = game.staticTexts.matching(NSPredicate(format: "label == %@", "1 AP")).firstMatch
        value["APLabelVisible"] = ap.exists
        value["APLabel"] = ap.exists ? ap.label : "hidden after terminal playback"
        value["currentTurnLabel"] = game.staticTexts["currentTurn"].label
        if let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) {
            let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
            attachment.name = row + "-row.json"; attachment.lifetime = .keepAlways; add(attachment)
        } else { XCTFail("Unable to attach native matrix metadata: \(row)") }
    }
    func testMageR1TabletRotationRetainsPreviewAndReceiptPlayback() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = .portrait }
        let game = app(["--cozy-demo", "--cozy-no-capture", "--mage-body-review", "--mage-no-effects", "--audio-trace"])
        let arena = game.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(arena.frame.width, 500)
        tap(game, 4, 3); game.buttons["push-Up"].tap()
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        func screen(_ name: String) {
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
        }
        screen("ANIM01R-ipad-portrait-preview")
        XCUIDevice.shared.orientation = .landscapeLeft
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            game.windows.firstMatch.frame.width > game.windows.firstMatch.frame.height &&
            game.buttons["playConfirm"].frame.minX >= arena.frame.maxX
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed)
        XCTAssertGreaterThan(arena.frame.width, 500)
        XCTAssertTrue(game.staticTexts["2 AP"].exists, "Rotation only presents the existing preview")
        XCTAssertTrue(game.buttons["playConfirm"].isEnabled)
        screen("ANIM01R-ipad-landscape-preview")
        cozyConfirm(game)
        let unlocked = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: game.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for: [unlocked], timeout: 5), .completed)
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        XCTAssertFalse(game.staticTexts["黑方獲勝"].exists)
        screen("ANIM01R-ipad-landscape-landed")
        game.buttons["undoOrCancel"].tap()
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCUIDevice.shared.orientation = .portrait
        let portrait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            game.windows.firstMatch.frame.width < game.windows.firstMatch.frame.height
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [portrait], timeout: 10), .completed)
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertFalse(game.buttons["playConfirm"].isEnabled)
        screen("ANIM01R-ipad-restored-after-undo")
    }
    private func mageR1Walkthrough(reference: Bool) {
        func hold(_ t: Double) {
            let wait = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in false }, object: nil)
            _ = XCTWaiter.wait(for: [wait], timeout: t)
        }
        let revision = reference ? "M3-reference" : "R1-candidate"
        let extra = reference ? ["--mage-m3-reference"] : []
        XCUIDevice.shared.orientation = .portrait
        let summon = app(["--summon-demo", "--hero", "mage", "--mage-body-review", "--mage-no-effects", "--audio-trace"] + extra)
        XCTAssertTrue(summon.staticTexts["2 AP"].waitForExistence(timeout: 10))
        shot(summon, "ANIM01R-" + revision + "-summon-before"); hold(0.6)
        tap(summon, 3, 4); cozyConfirm(summon); hold(1.2)
        XCTAssertTrue(summon.staticTexts["1 AP"].exists)
        shot(summon, "ANIM01R-" + revision + "-summon-after")
        summon.buttons["undoOrCancel"].tap(); XCTAssertTrue(summon.staticTexts["2 AP"].exists); summon.terminate()
        for capture in [false, true] {
            let game = app(["--cozy-demo", "--cozy-390", "--mage-body-review", "--mage-no-effects", "--audio-trace"] + extra + (capture ? [] : ["--cozy-no-capture"]))
            shot(game, "ANIM01R-" + revision + "-before-\(capture)"); hold(0.6)
            tap(game, 4, 3); game.buttons["push-Up"].tap()
            XCTAssertTrue(game.staticTexts["2 AP"].exists)
            shot(game, "ANIM01R-" + revision + "-preview-\(capture)")
            game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
            tap(game, 4, 3); game.buttons["push-Up"].tap(); cozyConfirm(game); hold(1.2)
            if capture {
                XCTAssertTrue(game.staticTexts["黑方獲勝"].waitForExistence(timeout: 5))
                XCTAssertFalse(game.staticTexts["1 AP"].exists)
            } else { XCTAssertTrue(game.staticTexts["1 AP"].exists) }
            shot(game, "ANIM01R-" + revision + "-after-\(capture)")
            game.buttons["undoOrCancel"].tap(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
            XCUIDevice.shared.press(.home); game.activate(); XCTAssertTrue(game.staticTexts["2 AP"].exists)
            game.terminate()
        }
    }
    func testMageM3TwoAPRemainsPlayableAfterPresentation() {
        let game = app(["--cozy-demo","--cozy-no-capture","--mage-body-review","--mage-no-effects"])
        tap(game,4,3);game.buttons["push-Up"].tap();cozyConfirm(game)
        XCTAssertTrue(game.staticTexts["1 AP"].waitForExistence(timeout:5))
        let unlocked = XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:game.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for:[unlocked],timeout:5),.completed)
        game.buttons["mode-soldier"].tap();tap(game,0,0);cozyConfirm(game)
        XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout:5))
        XCTAssertTrue(game.staticTexts["currentTurn"].label.contains("白方"),"Core ends the turn automatically after the second AP")
        shot(game,"M3-second-ap-after-mage-recovery")
        game.buttons["undoOrCancel"].tap();XCTAssertTrue(game.staticTexts["1 AP"].exists)
    }
    private func cozyConfirm(_ app: XCUIApplication) {
        for _ in 0..<5 { if app.buttons["playConfirm"].isHittable { break }; app.swipeUp() }
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        app.buttons["playConfirm"].tap()
    }
    func testCozyUnconstrainedNativeDevicePushCaptureAndUndo() {
        let app = app(["--cozy-demo"])
        let arena = app.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        XCTAssertEqual(arena.frame.width / arena.frame.height, 1024/1152.0, accuracy: 0.02)
        shot(app, "cozy-native-device-before")
        tap(app, 4, 3)
        for _ in 0..<5 { if app.buttons["push-Up"].isHittable { break }; app.swipeUp() }
        app.buttons["push-Up"].tap(); cozyConfirm(app)
        XCTAssertTrue(app.staticTexts["黑方獲勝"].waitForExistence(timeout: 10))
        shot(app, "cozy-native-device-captured")
        app.buttons["undoOrCancel"].tap()
        XCTAssertTrue(app.staticTexts["2 AP"].exists)
        XCTAssertTrue(app.staticTexts["能量 4/6 · 4 氣"].exists)
        shot(app, "cozy-native-device-undo")
    }
    func testCozy390RealPushCapturePreviewUndoAndBackground() {
        let app = app(["--cozy-demo", "--cozy-390"])
        let before = app.staticTexts.matching(identifier: "blueResources").allElementsBoundByIndex.map(\.label).joined(separator: " ")
        XCTAssertFalse(before.isEmpty)
        shot(app, "cozy-390-7-before")
        tap(app, 4, 3)
        for _ in 0..<4 { if app.buttons["push-Up"].isHittable { break }; app.swipeUp() }
        app.buttons["push-Up"].tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "blueResources").allElementsBoundByIndex.map(\.label).joined(separator: " "), before)
        XCTAssertEqual(app.staticTexts["sellPreviewCost"].label, "消耗 1 AP · 2 能量")
        XCTAssertTrue(app.staticTexts["sellPreviewConsequence"].label.contains("對局結束"))
        shot(app, "SELL01C-R1-capture-preview")
        cozyConfirm(app)
        XCTAssertTrue(app.staticTexts["黑方獲勝"].waitForExistence(timeout: 5))
        shot(app, "cozy-390-7-captured")
        app.buttons["undoOrCancel"].tap()
        XCTAssertEqual(app.staticTexts.matching(identifier: "blueResources").allElementsBoundByIndex.map(\.label).joined(separator: " "), before)
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertEqual(app.staticTexts.matching(identifier: "blueResources").allElementsBoundByIndex.map(\.label).joined(separator: " "), before)
    }
    func testCozy320NineDenseAndReducedResult() {
        let dense = app(["--cozy-demo", "--cozy-nine", "--cozy-320", "--cozy-dense"])
        let arena = dense.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 10))
        XCTAssertEqual(arena.frame.width / arena.frame.height, 1024/1152.0, accuracy: 0.02)
        shot(dense, "cozy-320-9-dense")
        dense.terminate()
        let reduced = app(["--cozy-demo", "--cozy-nine", "--cozy-320", "--cozy-reduced"])
        tap(reduced, 4, 3, size: 9)
        for _ in 0..<4 { if reduced.buttons["push-Up"].isHittable { break }; reduced.swipeUp() }
        reduced.buttons["push-Up"].tap(); cozyConfirm(reduced)
        XCTAssertTrue(reduced.staticTexts["黑方獲勝"].waitForExistence(timeout: 5))
        reduced.swipeDown(); shot(reduced, "cozy-320-9-reduced-captured")
    }
    func testCozyActualVisibleAudioOwnerCancellationAudit() {
        let app = app(["--cozy-demo", "--cozy-audit", "--cozy-390"])
        let result = app.staticTexts["cozyAudit"]
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        XCTAssertTrue(result.waitForExistence(timeout: 10))
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH 'PASS'"), object: result)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 30), .completed)
        shot(app, "cozy-real-owner-audit")
    }
    func testHeroVoiceActualOwnerSixEventsSettingsAndCancellation() {
        let app = app(["--cozy-demo", "--voice-audit", "--voice-bgm-audit"])
        let status = app.staticTexts["voiceAudit"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH 'PASS'"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [done], timeout: 90), .completed)
        shot(app, "VO-01-actual-owner-six-events-and-settings")
    }
    func testThreeHeroSummonsAreRealNativeActionsWithVoiceAndUndo() {
        for hero in ["warrior", "mage", "rogue"] {
            let game = app(["--summon-demo", "--hero", hero, "--voice-review"])
            XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout: 10))
            shot(game,"SUMMON-" + hero + "-before")
            tap(game,3,4)
            XCTAssertTrue(game.staticTexts["2 AP"].exists)
            shot(game,"SUMMON-" + hero + "-preview-original-board")
            cozyConfirm(game)
            let voice = game.staticTexts["heroStage"]
            let spoken = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "voice-" + hero + "-summon"),object: voice)
            XCTAssertEqual(XCTWaiter.wait(for: [spoken],timeout: 5), .completed)
            XCTAssertTrue(game.staticTexts["1 AP"].exists)
            shot(game,"SUMMON-" + hero + "-settled")
            game.buttons["undoOrCancel"].tap()
            XCTAssertTrue(game.staticTexts["2 AP"].exists)
            game.terminate()
        }
    }
    func testMageR1BothOwnersBothTargetsWithoutVoicePreviewCancelConfirmAndUndo() {
        for white in [false,true] {
            for enemy in [false,true] {
                var flags = ["--cozy-demo","--cozy-no-capture","--mage-body-review"]
                if white { flags.append("--white-caster") }
                if enemy { flags.append("--enemy-target") }
                let game = app(flags)
                XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout: 10))
                tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                shot(game,"MAGIC-\(white)-\(enemy)-preview-source-and-empty-destination")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.swipeDown(); tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap(); cozyConfirm(game)
                XCTAssertTrue(game.staticTexts["1 AP"].exists)
                shot(game,"MAGIC-\(white)-\(enemy)-committed-landed")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home); game.activate()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
    }
    func testMagicHandBothOwnersBothTargetsPreviewCancelConfirmAndUndo() {
        for white in [false,true] {
            for enemy in [false,true] {
                var flags = ["--cozy-demo","--cozy-no-capture","--voice-review"]
                if white { flags.append("--white-caster") }
                if enemy { flags.append("--enemy-target") }
                let game = app(flags)
                XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout: 10))
                tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                shot(game,"MAGIC-\(white)-\(enemy)-preview-source-and-empty-destination")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCTAssertNotEqual(game.staticTexts["heroStage"].label,"voice-mage-skill")
                game.swipeDown(); tap(game,4,3)
                for _ in 0..<5 { if game.buttons["push-Up"].isHittable { break }; game.swipeUp() }
                game.buttons["push-Up"].tap(); cozyConfirm(game)
                XCTAssertTrue(game.staticTexts["1 AP"].exists)
                XCTAssertEqual(game.staticTexts["heroStage"].label,"voice-mage-skill")
                shot(game,"MAGIC-\(white)-\(enemy)-committed-landed")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                XCUIDevice.shared.press(.home); game.activate()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
    }
    func testWarriorAndRogueNativeSkillsBothOwnersCancelAndUndo() {
        for hero in ["warrior","rogue"] {
            for white in [false,true] {
                var flags = ["--hero-skill-demo","--hero",hero,"--voice-review"]
                if white { flags.append("--white-caster") }
                let game = app(flags)
                XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout: 10))
                if hero == "warrior" { tap(game,2,3) }
                tap(game,4,3)
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                shot(game,"SKILL-\(hero)-\(white)-preview")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.swipeDown()
                if hero == "warrior" { tap(game,2,3) }
                tap(game,4,3); cozyConfirm(game)
                XCTAssertTrue(game.staticTexts["1 AP"].exists)
                XCTAssertEqual(game.staticTexts["heroStage"].label,"voice-" + hero + "-skill")
                shot(game,"SKILL-\(hero)-\(white)-settled")
                game.buttons["undoOrCancel"].tap()
                XCTAssertTrue(game.staticTexts["2 AP"].exists)
                game.terminate()
            }
        }
    }
    func testGameFeelCommittedFrameTimingCaptureAndReducedAudioAudit() {
        let game = app(["--cozy-demo","--game-feel-audit"])
        let status = game.staticTexts["gameFeelAudit"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let done = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label BEGINSWITH 'PASS'"),object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [done],timeout: 30), .completed)
        shot(game,"GAME-FEEL-real-receipt-frame-audit")
    }
    func testGameFeelNativeSixLineRecordingWalkthrough() {
        for hero in ["warrior","mage","rogue"] {
            let summon = app(["--summon-demo","--hero",hero,"--audio-trace","--demo-audio-defaults"])
            XCTAssertTrue(summon.staticTexts["2 AP"].waitForExistence(timeout: 10))
            tap(summon,3,4); cozyConfirm(summon)
            XCTAssertTrue(summon.staticTexts["1 AP"].exists)
            shot(summon,"FILM-\(hero)-summon")
            let hold = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in false },object: nil)
            _ = XCTWaiter.wait(for:[hold],timeout: 2)
            summon.terminate()
            let skill = app(hero == "mage" ? ["--cozy-demo","--cozy-no-capture","--audio-trace","--demo-audio-defaults"] : ["--hero-skill-demo","--hero",hero,"--audio-trace","--demo-audio-defaults"])
            XCTAssertTrue(skill.staticTexts["2 AP"].waitForExistence(timeout: 10))
            if hero == "warrior" { tap(skill,2,3) }
            tap(skill,4,3)
            if hero == "mage" {
                for _ in 0..<5 { if skill.buttons["push-Up"].isHittable { break }; skill.swipeUp() }
                skill.buttons["push-Up"].tap()
            }
            cozyConfirm(skill); XCTAssertTrue(skill.staticTexts["1 AP"].exists)
            shot(skill,"FILM-\(hero)-skill")
            let holdSkill = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in false },object: nil)
            _ = XCTWaiter.wait(for:[holdSkill],timeout: 2)
            skill.terminate()
        }
        let capture = app(["--cozy-demo","--audio-trace","--demo-audio-defaults"])
        tap(capture,4,3)
        for _ in 0..<5 { if capture.buttons["push-Up"].isHittable { break }; capture.swipeUp() }
        capture.buttons["push-Up"].tap(); cozyConfirm(capture)
        XCTAssertTrue(capture.staticTexts["黑方獲勝"].waitForExistence(timeout: 10))
        shot(capture,"FILM-conditional-capture-victory")
        let hold = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in false },object: nil)
        _ = XCTWaiter.wait(for:[hold],timeout: 3)
    }
    func testGameFeelNativeOrdinaryDropCaptureRecording() {
        let game = app(["--play-win","--audio-trace","--demo-audio-defaults"])
        XCTAssertTrue(game.staticTexts["2 AP"].waitForExistence(timeout: 10))
        tap(game,3,3)
        XCTAssertFalse(game.staticTexts["黑方獲勝"].exists)
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        cozyConfirm(game)
        XCTAssertTrue(game.staticTexts["黑方獲勝"].waitForExistence(timeout: 10))
        shot(game,"FILM-ordinary-drop-commander-capture")
        let hold = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in false },object: nil)
        _ = XCTWaiter.wait(for:[hold],timeout: 3)
        game.buttons["undoOrCancel"].tap()
        XCTAssertFalse(game.staticTexts["黑方獲勝"].exists)
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
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
        XCTAssertTrue(app.buttons["lobbyNewGame"].waitForExistence(timeout: 10))
        app.buttons["lobbyNewGame"].tap()
        app.buttons["setupLocal"].tap()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 5))
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
        startSetupMatch(app)
        tap(app, 2, 5); app.buttons["playConfirm"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["返回選角"].tap()
        XCTAssertTrue(app.buttons["留在對戰"].waitForExistence(timeout: 5))
        app.buttons["留在對戰"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到白方法師")
        app.buttons["返回選角"].tap()
        XCTAssertTrue(app.buttons["exitMatchConfirmed"].waitForExistence(timeout: 5))
        app.buttons["exitMatchConfirmed"].tap()
        app.buttons["lobbyHomeBack"].tap()
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
    private func app(_ args: [String] = [], openSetup: Bool = true) -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = args + ["--record-isolation", UUID().uuidString]
        if ProcessInfo.processInfo.environment["TACTICALGO_ATTACH_RUNNING"] == "1" { app.activate() }
        else { app.launch() }
        if openSetup && app.buttons["lobbyNewGame"].exists {
            app.buttons["lobbyNewGame"].tap()
            app.buttons["setupLocal"].tap()
        }
        return app
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
        let status = app.descendants(matching: .any)["tabletopMatch"]
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
        openLobbySettings(app)
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout: 10))
        openLobbySettings(app)
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        startSetupMatch(app)
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
        XCTAssertEqual(candidate.staticTexts["currentTurn"].value as? String, "新版技能")
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
        XCTAssertTrue(app.buttons["mageOperation"].waitForExistence(timeout: 10))
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
        app.buttons["mageOperation"].tap(); app.buttons["推動"].tap()
        tap(app, 3, 2)
        XCTAssertTrue(app.buttons["push-Up"].exists)
        XCTAssertFalse(app.buttons["push-Up"].isEnabled) // dense own soldiers still block original push
    }
    func testOriginalMatchCandidateCopyKeepsBothSavedRuleVersionsAndResumes() {
        let app = app(["--original-rules"])
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        startSetupMatch(app)
        tap(app, 2, 5); app.buttons["playConfirm"].tap()
        app.buttons["對戰選單"].tap(); app.buttons["candidateCopy"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].value as? String, "新版技能")
        app.buttons["對戰選單"].tap(); app.buttons["matchRecords"].tap()
        XCTAssertTrue(app.staticTexts["舊版規則"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["新版技能"].exists)
        shot(app, "original-and-candidate-records-preserved")
        app.buttons["recordsDone"].tap()
        // Relaunch without resetting the isolated record namespace.
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["resumeMatch"].waitForExistence(timeout: 10))
        app.buttons["resumeMatch"].tap()
        XCTAssertEqual(app.staticTexts["currentTurn"].value as? String, "新版技能")
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
        startSetupMatch(app)
        XCTAssertFalse(app.staticTexts["r2Banner"].exists)
        XCTAssertTrue(app.staticTexts["1 AP"].exists)
    }
    func testSavedMatchRestartsWithResourcesAndUndo() {
        let app = app()
        for _ in 0..<4 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        startSetupMatch(app)
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
        startSetupMatch(app)
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
        openLobbySettings(app)
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        XCTAssertTrue(app.segmentedControls["botDifficulty"].buttons["簡單"].isSelected)
        shot(app, "iPad-native-portrait-lobby")
        if !app.buttons["startMatch"].isHittable { app.swipeUp() }
        startSetupMatch(app)
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
        XCTAssertGreaterThan(boardFrame.width, 500)
        XCTAssertGreaterThan(boardFrame.width * 0.74 / 8, 44, "Even a 9×9 tablet row retains a comfortable point spacing")
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
        startSetupMatch(app)
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
        for _ in 0..<4 { if app.sliders["musicVolume"].isHittable { break }; app.swipeUp() }
        XCTAssertTrue(app.sliders["musicVolume"].isHittable)
        shot(app, "iPad-native-sound-sheet")
        app.buttons["audioSettingsDone"].tap()
        XCTAssertTrue(app.buttons["playEndTurn"].waitForExistence(timeout: 10))
    }
    func testRestoredMusicControlsAndPreferencesSurviveNormalRelaunch() {
        let app = app(["--play-bot", "--restore-play-audio"])
        func settings() {
            app.buttons["對戰選單"].tap(); app.buttons["聲音設定"].tap()
            XCTAssertTrue(app.switches["audioMute"].waitForExistence(timeout: 5))
        }
        func music() -> XCUIElement {
            for _ in 0..<5 { if app.switches["musicEnabled"].isHittable { break }; app.swipeUp() }
            return app.switches["musicEnabled"]
        }
        settings()
        XCTAssertEqual(app.switches["voiceEnabled"].value as? String, "0")
        XCTAssertEqual(app.switches["audioMute"].value as? String, "0")
        let enabled = music()
        XCTAssertTrue(enabled.isEnabled, "一般對戰不能再被驗收用 gate 鎖住音樂")
        XCTAssertEqual(enabled.value as? String, "1")
        enabled.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        let oldVolume = app.sliders["musicVolume"].value as? String ?? ""
        app.sliders["musicVolume"].adjust(toNormalizedSliderPosition: 0.2)
        let volumeChanged = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != %@", oldVolume), object: app.sliders["musicVolume"])
        XCTAssertEqual(XCTWaiter.wait(for: [volumeChanged], timeout: 5), .completed)
        let savedVolume = app.sliders["musicVolume"].value as? String
        app.buttons["audioSettingsDone"].tap(); app.terminate()
        app.launchArguments = app.launchArguments.filter { $0 != "--restore-play-audio" }; app.launch()
        settings()
        XCTAssertEqual(app.switches["voiceEnabled"].value as? String, "0")
        XCTAssertEqual(music().value as? String, "0", "一般重開不能強制啟用已關閉的音樂")
        XCTAssertEqual(app.sliders["musicVolume"].value as? String, savedVolume)
        music().coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        app.buttons["audioSettingsDone"].tap(); app.terminate()
        app.launchArguments.append("--hero-body-review"); app.launch(); settings()
        let reviewMusic = music()
        XCTAssertFalse(reviewMusic.isEnabled)
        XCTAssertEqual(reviewMusic.value as? String, "1", "動作檢視不能覆寫已儲存的音樂開關")
        app.buttons["audioSettingsDone"].tap(); app.terminate()
        app.launchArguments = app.launchArguments.filter { $0 != "--hero-body-review" }
        app.launch(); settings()
        XCTAssertTrue(music().isEnabled)
        XCTAssertEqual(music().value as? String, "1")
        app.buttons["audioSettingsDone"].tap()
        shot(app, "audio-restored-normal-game")
    }
    func testIntegratedNativeAudioCancellationAndReplay() {
        // Use the visible match fixture, the same native audit entry as the
        // retained-owner check, instead of relying on a lobby-only launch.
        let app = app(["--cozy-demo", "--integrated-audio-audit"])
        let status = app.staticTexts["integratedAudioAudit"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        let passed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "PASS"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [passed], timeout: 90), .completed)
        shot(app, "BOT-03a-integrated-native-audio-audit")
    }
    func testIntegratedIndependentSoundVolumesNativePlayers() {
        let app = app(["--integrated-volume-audit"])
        let status = app.staticTexts["integratedAudioAudit"]
        XCTAssertTrue(status.waitForExistence(timeout:10))
        let passed = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","PASS"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[passed],timeout:30),.completed)
        shot(app,"P29B-native-independent-volume-audit")
    }
    func testIntegratedCharacterVoiceCadenceNativePlayers() {
        let app = app(["--integrated-cadence-audit"])
        let status = app.staticTexts["integratedAudioAudit"]
        XCTAssertTrue(status.waitForExistence(timeout:10))
        let passed = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","PASS"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[passed],timeout:30),.completed)
        shot(app,"Q35-native-voice-cadence-audit")
    }
    func testIntegratedSoundSheetIndependentVolumesPersist() {
        #if DEBUG
        let app = app(["--integrated-practice","mage"])
        #else
        let app = app()
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        app.buttons["玩法練習"].tap();app.buttons["法師 · 擴充技能"].tap()
        #endif
        let arena = app.otherElements["playArena"]
        XCTAssertTrue(arena.waitForExistence(timeout:10));let frame = arena.frame
        func open() { app.buttons["對戰選單"].tap();app.buttons["聲音設定"].tap() }
        open()
        XCTAssertTrue(app.staticTexts["soundSettingsTitle"].waitForExistence(timeout:5))
        XCTAssertTrue(app.sliders["sfxVolume"].waitForExistence(timeout:5))
        XCTAssertTrue(app.sliders["voiceVolume"].isHittable)
        if app.switches["castVoice"].value as? String == "0" {
            app.switches["castVoice"].coordinate(withNormalizedOffset:CGVector(dx:0.92,dy:0.5)).tap()
        }
        let sfx = app.staticTexts["sfxVolumeValue"].label,voice = app.staticTexts["voiceVolumeValue"].label
        let enabled = app.switches["castVoice"].value as? String
        shot(app,"P29B-settings-default")
        app.sliders["sfxVolume"].adjust(toNormalizedSliderPosition:0.25)
        app.sliders["voiceVolume"].adjust(toNormalizedSliderPosition:0.45)
        let changedSFX = app.staticTexts["sfxVolumeValue"].label,changedVoice = app.staticTexts["voiceVolumeValue"].label
        XCTAssertNotEqual(changedSFX,sfx);XCTAssertNotEqual(changedVoice,voice)
        app.switches["castVoice"].coordinate(withNormalizedOffset:CGVector(dx:0.92,dy:0.5)).tap()
        let changed = app.switches["castVoice"].value as? String
        XCTAssertNotEqual(changed,enabled)
        XCTAssertEqual(app.staticTexts["voiceVolumeValue"].label,"語音已關閉")
        app.swipeUp()
        XCTAssertTrue(app.sliders["musicVolume"].isHittable)
        app.sliders["musicVolume"].adjust(toNormalizedSliderPosition:0.20)
        shot(app,"P29B-settings-independent-controls")
        app.buttons["audioSettingsDone"].tap()
        XCTAssertTrue(app.buttons["playConfirm"].waitForExistence(timeout:5))
        XCTAssertEqual(arena.frame,frame)
        app.terminate();app.launch()
        #if !DEBUG
        XCTAssertTrue(app.buttons["resumeExpansion"].waitForExistence(timeout:15))
        app.buttons["resumeExpansion"].tap()
        #endif
        open()
        XCTAssertEqual(app.staticTexts["sfxVolumeValue"].label,changedSFX)
        XCTAssertEqual(app.switches["castVoice"].value as? String,changed)
        app.switches["castVoice"].coordinate(withNormalizedOffset:CGVector(dx:0.92,dy:0.5)).tap()
        XCTAssertEqual(app.staticTexts["voiceVolumeValue"].label,changedVoice)
        // XCTest drag positions are approximate; return near baseline on this simulator.
        app.sliders["sfxVolume"].adjust(toNormalizedSliderPosition:0.80)
        app.sliders["voiceVolume"].adjust(toNormalizedSliderPosition:0.85)
        app.swipeUp();app.sliders["musicVolume"].adjust(toNormalizedSliderPosition:0.30)
        app.buttons["audioSettingsDone"].tap()
        XCTAssertEqual(arena.frame,frame)
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
        for _ in 0..<4 { if app.sliders["musicVolume"].isHittable { break }; app.swipeUp() }
        app.sliders["musicVolume"].adjust(toNormalizedSliderPosition: 0.20)
        app.swipeDown()
        let voice = app.switches["voiceEnabled"]
        let originalVoice = voice.value as? String
        voice.coordinate(withNormalizedOffset: CGVector(dx: 0.92,dy: 0.5)).tap()
        let changedVoice = voice.value as? String
        XCTAssertNotEqual(originalVoice,changedVoice)
        app.sliders["voiceVolume"].adjust(toNormalizedSliderPosition: 0.40)
        let changedVoiceVolume = app.sliders["voiceVolume"].value as? String
        shot(app, "BOT-03a-integrated-sound-settings")
        app.buttons["audioSettingsDone"].tap()
        app.terminate(); app.launch()
        app.buttons["對戰選單"].tap(); app.buttons["聲音設定"].tap()
        XCTAssertEqual(app.switches["audioMute"].value as? String, changed)
        XCTAssertEqual(app.switches["voiceEnabled"].value as? String,changedVoice)
        XCTAssertEqual(app.sliders["voiceVolume"].value as? String,changedVoiceVolume)
        app.switches["voiceEnabled"].coordinate(withNormalizedOffset: CGVector(dx: 0.92,dy: 0.5)).tap()
        app.swipeDown()
        app.switches["audioMute"].coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
        app.buttons["audioSettingsDone"].tap()
    }
    func testEasyDefaultDifficultyAndSwitchDuringComputerPreview() {
        let app = app(["--bot-step-review"])
        openLobbySettings(app)
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        XCTAssertTrue(app.segmentedControls["botDifficulty"].buttons["簡單"].isSelected)
        app.segmentedControls["botDifficulty"].buttons["標準"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        startSetupMatch(app)
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
        openLobbySettings(app)
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        XCTAssertTrue(app.segmentedControls["choosingTeam"].buttons["你 · 白方 ○"].isSelected)
        app.buttons["lobbyOptionsDone"].tap()
        app.buttons["choose-warrior"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        shot(app, "BOT-03a-white-human-easy-picker")
        startSetupMatch(app)
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
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("白方"))
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
        // The 1014 SELL layout hides redundant playMessage text after handover.
        // Verify the actual persistent human-turn HUD and absence of stale Bot text.
        XCTAssertTrue(app.staticTexts["currentTurn"].label.contains("黑方"))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "電腦第 ")).firstMatch.exists)
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
        XCTAssertTrue(app.staticTexts["白方獲勝"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["botStatus"].exists)
        shot(app, "BOT-01-mage-push-place-capture-victory")
    }
    func testSoloModeComputerCompletesTurnAndUndoReturnsHumanDecision() {
        let app = app()
        openLobbySettings(app)
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout: 10))
        openLobbySettings(app)
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.buttons["choose-rogue"].tap()
        for _ in 0..<3 { if app.buttons["startMatch"].isHittable { break }; app.swipeUp() }
        XCTAssertFalse(app.segmentedControls["playBoardSize"].buttons["9 × 9"].isEnabled)
        startSetupMatch(app)
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
    /// Reviewed official43-action Rogue/Mage root: black AP1, safe continuation G7.
    /// Use the real planner and explicit presentation permits, not a fake action.
    func testBotMaterialCandidateWitnessCommitsG7AndHandsToWhiteMage() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--bot-material-witness", "--bot-material-candidate", "--bot-step-review", "--audio-trace"])
        waitForStep(game, 1, landed: false, count: 1)
        XCTAssertTrue(game.staticTexts["playMessage"].label.contains("G7"))
        XCTAssertTrue(game.staticTexts["1 AP"].exists)
        shot(game, "BOT-MATERIAL-native-G7-prepared")
        game.buttons["botReviewAdvance"].tap()
        waitForStep(game, 1, landed: true, count: 1)
        shot(game, "BOT-MATERIAL-native-G7-landed")
        game.buttons["botReviewAdvance"].tap(); waitForBot(game, turns: 1)
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.buttons["mode-soldier"].isEnabled)
        shot(game, "BOT-MATERIAL-native-white-mage-handover-full390")
        game.buttons["以格點清單操作棋盤"].tap()
        for _ in 0..<10 {
            if game.buttons["cell-6-6"].exists { break }
            game.swipeUp()
        }
        XCTAssertTrue(game.buttons["cell-6-6"].exists)
        XCTAssertTrue(game.buttons["cell-6-6"].label.replacingOccurrences(of: " ", with: "").contains("黑方士兵"))
        shot(game, "BOT-MATERIAL-native-real-black-G7-cell")
        game.buttons["完成"].tap()
        game.buttons["對戰選單"].tap(); game.buttons["電腦決策紀錄"].tap()
        let log = game.staticTexts["botDecisionLog"]
        XCTAssertTrue(log.waitForExistence(timeout: 5))
        XCTAssertTrue(log.label.contains("策略：安全續攻候選"))
        XCTAssertTrue(log.label.contains("提兵"))
        let explanation = XCTAttachment(string: log.label)
        explanation.name = "BOT-MATERIAL-native-candidate-decision.txt"; explanation.lifetime = .keepAlways; add(explanation)
        shot(game, "BOT-MATERIAL-native-candidate-decision")
    }

    func testBotMaterialCandidateThinkingUndoDiscardsLateWitnessResult() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--bot-material-witness", "--bot-material-candidate", "--bot-late-result", "--audio-trace"])
        XCTAssertTrue(game.staticTexts["電腦思考中"].waitForExistence(timeout: 5))
        XCTAssertFalse(game.buttons["mode-soldier"].isEnabled)
        game.buttons["undoOrCancel"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        let expired = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完成0／作廢1"), object: game.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [expired], timeout: 50), .completed)
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertTrue(game.buttons["mode-soldier"].isEnabled)
        shot(game, "BOT-MATERIAL-native-late-candidate-discarded")
        game.buttons["以格點清單操作棋盤"].tap()
        for _ in 0..<10 {
            if game.buttons["cell-6-6"].exists { break }
            game.swipeUp()
        }
        XCTAssertTrue(game.buttons["cell-6-6"].exists)
        XCTAssertTrue(game.buttons["cell-6-6"].label.contains("空點"), "Late G7 must never commit after the human undo boundary")
        shot(game, "BOT-MATERIAL-native-no-late-G7")
    }

    func testBotMaterialPolicySelectorPreservesBoardAndResources() {
        XCUIDevice.shared.orientation = .portrait
        let game = app(["--play-bot", "--audio-trace"])
        game.buttons["對戰選單"].tap()
        XCTAssertTrue(game.buttons["difficulty-easy"].label.contains("✓"))
        game.buttons["aiPolicyMenu"].tap()
        XCTAssertTrue(game.buttons["ai-original"].label.contains("✓"))
        game.buttons["ai-original"].tap()
        game.buttons["對戰選單"].tap(); game.buttons["difficulty-standard"].tap()
        game.buttons["對戰選單"].tap()
        XCTAssertTrue(game.buttons["difficulty-standard"].label.contains("✓"))
        game.buttons["difficulty-standard"].tap()
        let turnBefore = game.staticTexts["currentTurn"].label
        // Official newGame black opening has1AP, unlike the reviewed23ply root.
        func hudAP() -> String {
            let boardTop = game.otherElements["playArena"].frame.minY
            let values = game.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+ AP")).allElementsBoundByIndex.filter { $0.frame.maxY <= boardTop }
            XCTAssertEqual(values.count, 1, "Read the unique AP header above the board; action-cost cards are below it")
            return values.first?.label ?? "MISSING NATIVE HUD"
        }
        XCTAssertEqual(hudAP(), "1 AP")
        func resources() -> [String] {
            game.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "能量 ")).allElementsBoundByIndex.map { $0.label }.sorted()
        }
        func boardCells() -> [String: String] {
            game.buttons["以格點清單操作棋盤"].tap()
            var cells: [String: String] = [:]
            for _ in 0..<12 {
                for cell in game.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cell-")).allElementsBoundByIndex {
                    if cell.exists { cells[cell.identifier] = cell.label }
                }
                if cells.count == 49 { break }
                game.swipeUp()
            }
            XCTAssertEqual(cells.count, 49, "Compare the complete observable7x7 board, not just a selection value")
            game.buttons["完成"].tap()
            return cells
        }
        let energyBefore = resources(), boardBefore = boardCells()
        XCTAssertEqual(energyBefore.count, 2)
        game.buttons["對戰選單"].tap(); game.buttons["aiPolicyMenu"].tap(); game.buttons["ai-material-threat"].tap()
        game.buttons["對戰選單"].tap(); game.buttons["aiPolicyMenu"].tap()
        XCTAssertTrue(game.buttons["ai-material-threat"].label.contains("✓"))
        game.buttons["ai-material-threat"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turnBefore)
        XCTAssertEqual(hudAP(), "1 AP")
        XCTAssertEqual(resources(), energyBefore)
        XCTAssertEqual(boardCells(), boardBefore)
        shot(game, "BOT-MATERIAL-native-selector-candidate-no-state-mutation")
        game.buttons["對戰選單"].tap(); game.buttons["aiPolicyMenu"].tap(); game.buttons["ai-original"].tap()
        game.buttons["對戰選單"].tap(); game.buttons["aiPolicyMenu"].tap()
        XCTAssertTrue(game.buttons["ai-original"].label.contains("✓"))
        XCTAssertFalse(game.buttons["ai-material-threat"].label.contains("✓"))
        game.buttons["ai-original"].tap()
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turnBefore)
        XCTAssertEqual(hudAP(), "1 AP")
        XCTAssertEqual(resources(), energyBefore)
        XCTAssertEqual(boardCells(), boardBefore)
        shot(game, "BOT-MATERIAL-native-selector-returned-to-original")
        let state = XCTAttachment(string: "AP=\(hudAP())\nresources=\(energyBefore)\nboard=\(boardBefore.sorted { $0.key < $1.key })")
        state.name = "BOT-MATERIAL-native-selector-unchanged-board-resources.txt"; state.lifetime = .keepAlways; add(state)
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
        startSetupMatch(app)
        let secondExpired = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "完成0／作廢1"), object: app.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for: [secondExpired], timeout: 50), .completed)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "輪到黑方戰士")
        shot(app, "BOT-01-stale-result-rejected-after-restart-and-exit")
    }
    func testVisualPackConnectionPreservesPreviewCancelCommitAndUndo() {
        let app = app(["--visual-pack-fixture"])
        XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout: 10))
        startSetupMatch(app)
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
        startSetupMatch(app)
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
        openLobbySettings(app)
        app.segmentedControls["choosingTeam"].buttons["白方 ○"].tap()
        app.buttons["lobbyOptionsDone"].tap()
        app.buttons["choose-mage"].tap()
        startSetupMatch(app)
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
        startSetupMatch(app)
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
        startSetupMatch(app)
        // Independent cooperative match: cover all four liberties of red D2.
        // Red spends each intervening turn away from its commander.
        for (x, y) in [(3,0), (0,6), (1,6), (2,1), (4,1), (0,5), (1,5), (3,2)] {
            tap(app, x, y)
            XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
            app.buttons["playConfirm"].tap()
        }
        XCTAssertTrue(app.staticTexts["黑方獲勝"].exists)
        XCTAssertEqual(app.staticTexts["currentTurn"].label, "對戰結束")
        XCTAssertFalse(app.buttons["playEndTurn"].exists)
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
        XCTAssertFalse(win.buttons["playEndTurn"].exists)
        shot(win, "A0-win")
        win.buttons["undoOrCancel"].tap()
        XCTAssertFalse(win.staticTexts["黑方獲勝"].exists)
        win.terminate()
        let draw = app(["--play-draw"])
        XCTAssertTrue(draw.buttons["playEndTurn"].waitForExistence(timeout: 10))
        draw.buttons["playEndTurn"].tap()
        XCTAssertTrue(draw.staticTexts["和局"].exists)
        XCTAssertFalse(draw.buttons["playEndTurn"].exists)
        shot(draw, "A0-draw")
        draw.buttons["resultReplay"].tap()
        XCTAssertFalse(draw.staticTexts["和局"].exists)
        XCTAssertTrue(draw.staticTexts["1 AP"].exists)
    }
}
