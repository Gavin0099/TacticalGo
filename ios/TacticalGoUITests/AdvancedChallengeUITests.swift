import XCTest
import UIKit

@MainActor final class AdvancedChallengeUITests: XCTestCase {
    /// TG12 product route, one tap per control; no retry helper can hide a missed tap.
    func testExpeditionProductEntryAndSeparateChapterProgress() {
        continueAfterFailure = false
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString]
        #if DEBUG
        // Debug defaults to the legacy home; select the same product root as Beta.
        game.launchArguments.append("--full-game")
        #endif
        game.launch()
        XCTAssertTrue(game.buttons["lobbyChallenges"].waitForExistence(timeout: 10))
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.buttons["openExpedition"].waitForExistence(timeout: 5))
        game.buttons["openExpedition"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "戰術遠征 · 試玩版")
        game.buttons["challenge-tg12-expedition-1"].tap()
        XCTAssertTrue(game.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeTitle"].label, "守住補給線")
        action(game, skill: false, points: [(4,5)])
        let resources = game.staticTexts["challengeResources"].label
        reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
        game.buttons["challengeChapter-advanced"].tap()
        XCTAssertEqual(game.staticTexts["challengeProgress"].label, "0／3 已完成")
        game.buttons["challengeChapter-expedition"].tap()
        game.buttons["challenge-tg12-expedition-1"].tap()
        XCTAssertEqual(game.staticTexts["challengeResources"].label, resources)
        reveal(game, game.buttons["challengeExportObservation"])
        XCTAssertTrue(game.buttons["challengeExportObservation"].exists)
    }

    /// The ordinary witnesses in artifacts/tg12/final-witnesses.json are the
    /// independent input plans. UI assertions cover the completed product flow,
    /// rather than recomputing legality or the objective in the test.
    func testExpeditionThreeStagesReviewRetryNextAndExport() {
        expeditionFlow(orientation: .portrait)
    }

    func testIPadExpeditionThreeStagesReviewRetryNextAndExport() {
        expeditionFlow(orientation: .landscapeLeft)
    }

    private func expeditionFlow(orientation: UIDeviceOrientation) {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = orientation
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString]
        #if DEBUG
        game.launchArguments.append("--full-game")
        #endif
        game.launch()
        XCTAssertTrue(game.buttons["lobbyChallenges"].waitForExistence(timeout: 15))
        if orientation.isLandscape {
            XCTAssertGreaterThan(game.windows.firstMatch.frame.width, game.windows.firstMatch.frame.height)
        }
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.buttons["openExpedition"].waitForExistence(timeout: 5))
        game.buttons["openExpedition"].tap()
        XCTAssertTrue(game.buttons["challenge-tg12-expedition-1"].waitForExistence(timeout: 5))
        game.buttons["challenge-tg12-expedition-1"].tap()

        func finished(_ count: Int, mana: Int, title: String, finalReply: String) {
            XCTAssertTrue(game.staticTexts["challengeResult"].waitForExistence(timeout: 20))
            XCTAssertEqual(game.staticTexts["challengeTitle"].label, title)
            XCTAssertTrue(game.staticTexts["challengeResult"].label.contains("挑戰完成"))
            let summary = game.staticTexts["challengeReviewSummary"]
            reveal(game, summary)
            XCTAssertTrue(summary.label.contains("本次 \(count) 次行動、消耗 \(mana) 能量"))
            XCTAssertFalse(game.buttons["challengeConfirm"].exists)
            let timeline = game.buttons["challengeReviewTimeline"]
            reveal(game, timeline)
            shot(game, "TG12-" + title + "-controls")
            XCTAssertGreaterThanOrEqual(timeline.frame.height, 44)
            timeline.tap()
            // Last enemy receipt from the reviewed witness, not just any reply.
            let lastReply = game.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", finalReply)).firstMatch
            XCTAssertTrue(lastReply.exists)
            reveal(game, lastReply)
            XCTAssertTrue(lastReply.isHittable)
            shot(game, "TG12-" + title + "-review")
        }
        func next(_ title: String) {
            let button = game.buttons["challengeNext"]
            reveal(game, button)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            button.tap()
            XCTAssertTrue(game.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
            XCTAssertEqual(game.staticTexts["challengeTitle"].label, title)
            ready(game)
            XCTAssertTrue(game.staticTexts["challengeResources"].label.contains("已用 0"))
        }

        // Retry after an accepted move; it must restore the initial stage state.
        action(game, points: [(4,5)])
        reveal(game, game.buttons["challengeRetry"]); game.buttons["challengeRetry"].tap()
        ready(game)
        XCTAssertTrue(game.staticTexts["challengeResources"].label.contains("已用 0"))
        action(game, points: [(4,5)]); action(game, points: [(5,5)])
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(game.wait(for: .runningBackground, timeout: 5)
            || game.state == .runningBackgroundSuspended)
        // Give the scene a real background interval before resuming it.
        Thread.sleep(forTimeInterval: 2)
        game.activate()
        XCTAssertTrue(game.wait(for: .runningForeground, timeout: 5))
        ready(game)
        XCTAssertFalse(game.staticTexts["challengeResult"].exists)
        action(game, points: [(5,3)]); action(game, points: [(5,4)])
        finished(4, mana: 0, title: "守住補給線", finalReply: "8. 白：落子 E4")
        next("突破後守住戰果")

        action(game, skill: true, points: [(4,2)], direction: "Down")
        action(game, points: [(4,2)]); ready(game)
        XCTAssertFalse(game.staticTexts["challengeResult"].exists)
        action(game, skill: true, points: [(3,2)], direction: "Left")
        action(game, points: [(3,2)]); ready(game)
        XCTAssertFalse(game.staticTexts["challengeResult"].exists)
        action(game, points: [(5,4)])
        action(game, skill: true, points: [(2,3)], direction: "Up")
        finished(6, mana: 6, title: "突破後守住戰果", finalReply: "12. 白：落子 C1")
        next("出手後的退路")

        action(game, points: [(4,2)]); action(game, points: [(4,4)]); ready(game)
        XCTAssertFalse(game.staticTexts["challengeResult"].exists)
        action(game, points: [(6,2)]); action(game, points: [(6,4)]); ready(game)
        XCTAssertFalse(game.staticTexts["challengeResult"].exists)
        action(game, points: [(2,1)]); action(game, points: [(2,2)])
        finished(6, mana: 0, title: "出手後的退路", finalReply: "11. 白：落子 F2")
        XCTAssertFalse(game.buttons["challengeNext"].exists)
        XCTAssertEqual(game.staticTexts["challengeProgress"].label, "3／3 已完成")

        let export = game.buttons["challengeExportObservation"]
        reveal(game, export)
        XCTAssertGreaterThanOrEqual(export.frame.height, 44)
        export.tap()
        // The system share sheet exposes actions as cells on iOS 27.
        let copy = game.cells.matching(NSPredicate(format: "label IN %@", ["拷貝", "複製", "Copy"])).firstMatch
        XCTAssertTrue(copy.waitForExistence(timeout: 10), game.debugDescription)
        shot(game, "TG12-observation-share-sheet")
        copy.tap()
        XCTAssertTrue(export.waitForExistence(timeout: 5))
    }

    /// Enter from the shipping home, not the debug chapter shortcut. The first
    /// chapter selected and later chapter changes must reach the intended catalog.
    func testHomeDirectChallengeEntryAndChapterSwitching() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString]
        game.launch()
        XCTAssertTrue(game.buttons["lobbyChallenges"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.buttons["lobbyChallenges"].isHittable)
        shot(game, "RELEASE-R1-home")
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "英雄技能入門")
        game.buttons["challengeChapter-advanced"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        for id in ["c03-1-commander-rescue", "c03-2-feint-counterattack", "c03-3-skill-timing"] {
            let button = game.buttons["challenge-" + id]
            reveal(game, button); button.tap()
            XCTAssertTrue(game.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
            XCTAssertTrue(game.otherElements["challengeArena"].exists)
            XCTAssertTrue(game.staticTexts["challengeResources"].label.contains("已用 0"))
            shot(game, "CHALLENGE-1018-advanced-" + id)
            reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
            XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        }
        reveal(game, game.buttons["challengeChapter-introduction"])
        game.buttons["challengeChapter-introduction"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "英雄技能入門")
        for id in ["warrior-rescue", "warrior-counterattack", "mage-split", "mage-rescue", "rogue-shape", "rogue-finish"] {
            let button = game.buttons["challenge-" + id]
            reveal(game, button); button.tap()
            XCTAssertTrue(game.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
            shot(game, "CHALLENGE-1018-intro-" + id)
            reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
        }
        game.buttons["challengeChapter-advanced"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        XCTAssertEqual(game.staticTexts["challengeProgress"].label, "0／3 已完成")
    }

    /// Opening practice must not mutate the live match, its preview or resources.
    func testMatchChallengeEntryReturnsToUnchangedMatch() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString]
        game.launch()
        game.buttons["lobbyNewGame"].tap()
        game.buttons["setupLocal"].tap()
        game.buttons["startMatch"].tap(); game.buttons["startMatch"].tap()
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 5))
        let turn = game.staticTexts["currentTurn"].label
        let resources = game.staticTexts["1 AP"].firstMatch.label
        game.buttons["對戰選單"].tap()
        XCTAssertTrue(game.buttons["戰術挑戰"].waitForExistence(timeout: 5))
        game.buttons["戰術挑戰"].tap()
        game.buttons["邊境攻防 · 三關候選"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        game.buttons["challenge-c03-3-skill-timing"].tap()
        action(game, skill: true, points: [(4,3)])
        let challengeResources = game.staticTexts["challengeResources"].label
        reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
        game.buttons["challengeChapter-introduction"].tap()
        game.buttons["challenge-warrior-rescue"].tap()
        reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
        game.buttons["challengeChapter-advanced"].tap()
        game.buttons["challenge-c03-3-skill-timing"].tap()
        XCTAssertEqual(game.staticTexts["challengeResources"].label, challengeResources)
        reveal(game, game.buttons["challengeBack"]); game.buttons["challengeBack"].tap()
        game.buttons["challengeBack"].tap()
        XCTAssertTrue(game.otherElements["playArena"].waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, turn)
        XCTAssertEqual(game.staticTexts["1 AP"].firstMatch.label, resources)
        shot(game, "CHALLENGE-1018-original-match-retained")
    }
    func testTabletLandscapeSharedBoardAndChapterSelection() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
        let game = XCUIApplication()
        game.launchArguments = ["--record-isolation", UUID().uuidString]
        game.launch()
        XCTAssertTrue(game.buttons["lobbyChallenges"].waitForExistence(timeout: 10))
        XCTAssertTrue(game.buttons["lobbyChallenges"].isHittable)
        shot(game, "RELEASE-R1-ipad-landscape-home")
        game.buttons["lobbyChallenges"].tap()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        game.buttons["challenge-mage-split"].tap()
        XCTAssertTrue(game.otherElements["challengeArena"].waitForExistence(timeout: 5))
        let window = game.windows.firstMatch.frame
        let board = game.otherElements["challengeArena"].frame
        XCTAssertGreaterThan(window.width, window.height)
        XCTAssertTrue(window.contains(board))
        XCTAssertEqual(board.height / board.width, 1.125, accuracy: 0.01)
        XCTAssertTrue(game.buttons["challengeSkill"].isHittable)
        shot(game, "CHALLENGE-1018-ipad-landscape-intro")
        game.buttons["challengeBack"].tap()
        game.buttons["challengeChapter-advanced"].tap()
        game.buttons["challenge-c03-1-commander-rescue"].tap()
        XCTAssertTrue(game.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(game.buttons["challengeSkill"].isHittable)
        shot(game, "CHALLENGE-1018-ipad-landscape-advanced")
    }
    func testChallengesInvalidateLateBotWithoutChangingTheSavedTurn() {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let game = XCUIApplication()
        game.launchArguments = ["--play-bot", "--bot-late-result", "--bot-step-review", "--record-isolation", UUID().uuidString]
        game.launch()
        let board = game.otherElements["playArena"]
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        // D5 from the published seven-line projection, inside the fitted arena.
        board.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18 + 0.65 * 4 / 6)).tap()
        game.buttons["playConfirm"].tap()
        XCTAssertTrue(game.staticTexts["電腦思考中"].waitForExistence(timeout: 5))
        let oldDecisionReturnsAfter = Date().addingTimeInterval(32)
        game.buttons["對戰選單"].tap(); game.buttons["戰術挑戰"].tap()
        game.buttons["邊境攻防 · 三關候選"].tap()
        XCTAssertEqual(game.staticTexts["challengeCatalog"].label, "邊境攻防")
        XCUIDevice.shared.press(.home); game.activate()
        XCTAssertTrue(game.staticTexts["challengeCatalog"].waitForExistence(timeout: 5))
        // Let the non-cooperative old decision actually return while this cover
        // is visible. Merely canceling a mock task would not test stale delivery.
        let returned = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in Date() >= oldDecisionReturnsAfter }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [returned], timeout: 40), .completed)
        game.buttons["challengeBack"].tap()
        XCTAssertTrue(board.waitForExistence(timeout: 5))
        XCTAssertEqual(game.staticTexts["currentTurn"].label, "輪到白方法師")
        XCTAssertTrue(game.staticTexts["2 AP"].exists)
        XCTAssertEqual(game.staticTexts["botDebugStatus"].label, "完成0／作廢1")
        shot(game, "CHALLENGE-1018-late-bot-discarded-original-turn-retained")
    }
    private func app(_ isolation: String = UUID().uuidString, intro: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [intro ? "--intro-challenges" : "--advanced-challenges", "--record-isolation", isolation, "--challenge-trace"]
        app.launch()
        XCTAssertTrue(app.staticTexts["challengeCatalog"].waitForExistence(timeout: 10))
        return app
    }
    private func reveal(_ app: XCUIApplication, _ element: XCUIElement) {
        for _ in 0..<7 {
            // iOS 27 can throw while querying isHittable for an offscreen button
            // ("Activation point invalid"). Scroll it into view before asking.
            if element.exists {
                let frame = element.frame
                let visible = app.windows.firstMatch.frame.intersection(frame)
                if !visible.isNull && visible.height >= min(44, frame.height)
                    && visible.width > 0 && element.isHittable { return }
            }
            // A partly clipped control above the viewport must scroll downward.
            // Scrolling only up made a valid 44-pt label remain clipped on iPad.
            if element.exists && element.frame.midY < app.windows.firstMatch.frame.midY {
                app.swipeDown()
            } else { app.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
    }
    private func ready(_ app: XCUIApplication) {
        let predicate = NSPredicate(format: "enabled == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: app.buttons["challengeSoldier"])], timeout: 12), .completed)
    }
    private func point(_ app: XCUIApplication, _ x: Int, _ y: Int) {
        reveal(app, app.buttons["challengePoints"]); app.buttons["challengePoints"].tap()
        let target = app.buttons["challengePoint-\(x)-\(y)"]
        XCTAssertTrue(target.waitForExistence(timeout: 5)); reveal(app, target); target.tap()
    }
    private func action(_ app: XCUIApplication, skill: Bool = false, points: [(Int, Int)], direction: String? = nil) {
        ready(app)
        let mode = app.buttons[skill ? "challengeSkill" : "challengeSoldier"]
        reveal(app, mode); mode.tap()
        for (x, y) in points { point(app, x, y) }
        if let direction {
            let button = app.buttons["challengeDirection-" + direction]
            reveal(app, button); button.tap()
        }
        reveal(app, app.buttons["challengeConfirm"])
        XCTAssertTrue(app.buttons["challengeConfirm"].isEnabled)
        app.buttons["challengeConfirm"].tap()
    }
    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func boardPoint(_ app: XCUIApplication, _ x: Int, _ y: Int) {
        let arena = app.otherElements["challengeArena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 5))
        // Published 8:9 board-fit and trapezoid anchors, independent of the renderer.
        // In particular, account for the fit margins inside the challenge arena.
        for _ in 0..<7 {
            let frame = arena.frame, width = min(frame.width, frame.height * 8 / 9)
            let height = width * 9 / 8, row = Double(y) / 6
            let inset = 0.13 - 0.06 * row
            let px = inset + (1 - 2 * inset) * Double(x) / 6
            let py = 0.18 + 0.65 * row
            let dx = (frame.width - width) / 2 + width * px
            let dy = (frame.height - height) / 2 + height * py
            let target = CGPoint(x: frame.minX + dx, y: frame.minY + dy)
            let viewport = app.windows.firstMatch.frame.insetBy(dx: 12, dy: 44)
            if viewport.contains(target) {
                arena.coordinate(withNormalizedOffset: CGVector(dx: dx / frame.width, dy: dy / frame.height)).tap()
                let label = "\(String(UnicodeScalar(65 + x)!))\(y + 1)"
                XCTAssertTrue((arena.value as? String)?.contains(label) == true)
                return
            }
            // Recompute after scrolling; a previous mode/confirm reveal can
            // leave the next board point under the top system gesture region.
            if target.y < viewport.minY { app.swipeDown() } else { app.swipeUp() }
        }
        XCTFail("Board point could not be brought into the viewport")
    }
    private func boardCommit(_ app: XCUIApplication, points: [(Int, Int)], skill: Bool = false) {
        ready(app)
        let mode = app.buttons[skill ? "challengeSkill" : "challengeSoldier"]
        reveal(app, mode); mode.tap()
        for (x,y) in points { boardPoint(app, x, y) }
        reveal(app, app.buttons["challengeConfirm"])
        XCTAssertTrue(app.buttons["challengeConfirm"].isEnabled)
        app.buttons["challengeConfirm"].tap()
    }
    func testNativeWarriorPlansAndActualCounterplayRecording() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        app.buttons["challenge-c03-1-commander-rescue"].tap()
        ready(app); shot(app, "CONTENT03-warrior-source")
        boardCommit(app, points: [(4,5),(3,6)], skill: true)
        boardCommit(app, points: [(5,5)])
        ready(app); shot(app, "CONTENT03-warrior-skill-real-counter")
        boardCommit(app, points: [(5,3)]); boardCommit(app, points: [(5,4)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 4"))
        shot(app, "CONTENT03-warrior-skill-complete")
        reveal(app, app.buttons["challengeRetry"]); app.buttons["challengeRetry"].tap()
        boardCommit(app, points: [(4,5)]); boardCommit(app, points: [(5,5)])
        ready(app); shot(app, "CONTENT03-warrior-ordinary-real-counter")
        boardCommit(app, points: [(5,3)]); boardCommit(app, points: [(5,4)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        shot(app, "CONTENT03-warrior-ordinary-complete")
    }
    func testNativeRogueResourceTradeoffRecording() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        app.buttons["challenge-c03-3-skill-timing"].tap()
        ready(app); shot(app, "CONTENT03-rogue-source")
        boardCommit(app, points: [(4,3)], skill: true)
        boardCommit(app, points: [(6,3)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 2"))
        shot(app, "CONTENT03-rogue-efficient-complete")
        reveal(app, app.buttons["challengeRetry"]); app.buttons["challengeRetry"].tap()
        boardCommit(app, points: [(4,2)]); boardCommit(app, points: [(4,4)])
        ready(app); shot(app, "CONTENT03-rogue-ordinary-real-counter")
        boardCommit(app, points: [(6,2)]); boardCommit(app, points: [(6,4)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 4"))
        shot(app, "CONTENT03-rogue-ordinary-complete")
    }
    func testHintProgressSurvivesCommittedCounterplayAndRelaunch() {
        XCUIDevice.shared.orientation = .portrait
        let isolation = UUID().uuidString
        let app = app(isolation)
        app.buttons["challenge-c03-2-feint-counterattack"].tap()
        let hint = "敵方不會站著等你提子。先想它可能補哪一口氣。"
        reveal(app, app.buttons["challengeHint"]); app.buttons["challengeHint"].tap()
        XCTAssertTrue(app.staticTexts[hint].exists)
        action(app, skill: true, points: [(4,2)], direction: "Down")
        // While a receipt is presented or its immutable controller is pending,
        // hint progress must not race with that controller's publication.
        if !app.buttons["challengeSoldier"].isEnabled {
            XCTAssertFalse(app.buttons["challengeHint"].isEnabled)
        }
        action(app, points: [(4,2)]); ready(app)
        reveal(app, app.buttons["challengeHint"])
        XCTAssertTrue(app.staticTexts[hint].exists)
        XCTAssertTrue(app.buttons["challengeHint"].isEnabled)
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["challengeTitle"].waitForExistence(timeout: 10))
        ready(app); reveal(app, app.buttons["challengeHint"])
        XCTAssertTrue(app.staticTexts[hint].exists)
        shot(app, "CONTENT03-hint-preserved-after-counter-and-relaunch")
    }
    func testAdjacentBoardPointsAndLargePickerSelectTheSameCoordinates() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        app.buttons["challenge-c03-1-commander-rescue"].tap()
        let before = app.staticTexts["challengeResources"].label
        for (x, y, label) in [(4,5,"已選 E6"), (5,5,"已選 F6"), (5,4,"已選 F5")] {
            boardPoint(app, x, y)
            XCTAssertEqual(app.otherElements["challengeArena"].value as? String, label)
            XCTAssertEqual(app.staticTexts["challengeResources"].label, before)
            XCTAssertTrue(app.buttons["challengeConfirm"].isEnabled)
        }
        point(app, 4, 5)
        XCTAssertEqual(app.otherElements["challengeArena"].value as? String, "已選 E6")
        XCTAssertEqual(app.staticTexts["challengeResources"].label, before)
        app.buttons["challengeCancel"].tap()
        XCTAssertEqual(app.otherElements["challengeArena"].value as? String, "未選取")
        XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled)
        shot(app, "CONTENT03-board-hit-and-picker-agree")
    }
    func testMageTwoTurnsCounterplayUndoAndCompletion() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        app.buttons["challenge-c03-2-feint-counterattack"].tap()
        XCTAssertTrue(app.staticTexts["challengeTitle"].waitForExistence(timeout: 5))
        shot(app, "CONTENT03-mage-start")
        action(app, skill: true, points: [(4,2)], direction: "Down")
        action(app, points: [(4,2)])
        ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("黑方"))
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("2 AP"))
        shot(app, "CONTENT03-mage-after-counter")
        // Undo removes both accepted enemy receipts and the human decision that handed over.
        reveal(app, app.buttons["challengeUndo"]); app.buttons["challengeUndo"].tap()
        ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("1 AP"))
        action(app, points: [(4,2)])
        ready(app)
        action(app, points: [(6,1)])
        action(app, points: [(6,3)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        XCTAssertFalse(app.buttons["challengeConfirm"].exists)
        shot(app, "CONTENT03-mage-completed")
        reveal(app, app.buttons["challengeRetry"]); app.buttons["challengeRetry"].tap()
        ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("已用 0"))
    }
    /// Normal-speed full-board demonstration. Every point is an actual board hit
    /// and every counter is a queued Core receipt, with no edited result frame.
    func testNativeMageCounterplayRecordingWithBoardHits() {
        XCUIDevice.shared.orientation = .portrait
        let app = app()
        app.buttons["challenge-c03-2-feint-counterattack"].tap()
        ready(app); shot(app, "CONTENT03-recording-source")
        func commit(_ x: Int, _ y: Int, skill: Bool = false, direction: String? = nil) {
            ready(app)
            reveal(app, app.buttons[skill ? "challengeSkill" : "challengeSoldier"])
            app.buttons[skill ? "challengeSkill" : "challengeSoldier"].tap()
            boardPoint(app, x, y)
            if let direction {
                reveal(app, app.buttons["challengeDirection-" + direction])
                app.buttons["challengeDirection-" + direction].tap()
            }
            reveal(app, app.buttons["challengeConfirm"])
            XCTAssertTrue(app.buttons["challengeConfirm"].isEnabled)
            app.buttons["challengeConfirm"].tap()
        }
        commit(4, 2, skill: true, direction: "Down")
        commit(4, 2)
        ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("2 AP"))
        shot(app, "CONTENT03-recording-real-counter")
        commit(6, 1); commit(6, 3)
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        shot(app, "CONTENT03-recording-complete")
        reveal(app, app.buttons["challengeUndo"]); app.buttons["challengeUndo"].tap()
        ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("1 AP"))
        XCTAssertFalse(app.staticTexts["challengeResult"].exists)
        commit(6, 3)
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
    }
    func testPreviewCancelIllegalAndBackgroundCounterResume() {
        XCUIDevice.shared.orientation = .portrait
        let isolation = UUID().uuidString
        let app = app(isolation)
        app.buttons["challenge-c03-1-commander-rescue"].tap()
        let before = app.staticTexts["challengeResources"].label
        point(app,3,5) // Commander occupies this point.
        XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["challengeResources"].label, before)
        point(app,4,5)
        app.buttons["challengeCancel"].tap()
        XCTAssertEqual(app.staticTexts["challengeResources"].label, before)
        XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled)
        action(app, skill: true, points: [(4,5),(3,6)])
        action(app, points: [(5,5)])
        // Pause immediately, then restore a journal which may contain zero, one or two
        // enemy receipts. All three positions have the same verified remaining reply.
        XCUIDevice.shared.press(.home)
        app.activate(); ready(app)
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("黑方"))
        XCTAssertTrue(app.staticTexts["challengeResources"].label.contains("2 AP"))
        action(app, points: [(5,3)])
        action(app, points: [(5,4)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        shot(app, "CONTENT03-rescue-after-background")
    }
    func testRogueCompletionRestartsAndKeepsChapterSeparate() {
        let isolation = UUID().uuidString
        let app = app(isolation)
        app.buttons["challenge-c03-3-skill-timing"].tap()
        action(app, skill: true, points: [(4,3)])
        action(app, points: [(6,3)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 12))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        shot(app, "CONTENT03-rogue-efficient-plan")
        reveal(app, app.buttons["challengeBack"]); app.buttons["challengeBack"].tap()
        XCTAssertTrue(app.staticTexts["challengeProgress"].label.contains("1／3"))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "challenge-c03-")).count, 3)
        let intro = self.app(isolation, intro: true)
        XCTAssertTrue(intro.staticTexts["challengeProgress"].label.contains("0／6"))
        XCTAssertEqual(intro.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "challenge-")).count, 6)
        shot(intro, "CONTENT03-original-six-retained")
    }
    func testIPadPortraitLandscapeAndRestoredSelectedRun() {
        XCUIDevice.shared.orientation = .portrait
        let isolation = UUID().uuidString
        let app = app(isolation)
        app.buttons["challenge-c03-2-feint-counterattack"].tap()
        let originalResources = app.staticTexts["challengeResources"].label
        XCTAssertTrue(app.otherElements["challengeArena"].waitForExistence(timeout: 5))
        shot(app, "CONTENT03-ipad-portrait")
        XCUIDevice.shared.orientation = .landscapeLeft
        let transition = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in false }, object: nil)
        _ = XCTWaiter.wait(for: [transition], timeout: 1.0)
        // Accessibility frames are transformed during the orientation animation;
        // assess hit areas only after the real landscape layout has settled.
        let landscape = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.windows.firstMatch.frame.width > app.windows.firstMatch.frame.height &&
            ["challengeSoldier", "challengeSkill"].allSatisfy { app.buttons[$0].frame.height >= 44 }
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscape], timeout: 5), .completed)
        XCTAssertEqual(app.staticTexts["challengeResources"].label, originalResources)
        for (x, label) in [(4, "已選 E3"), (5, "已選 F3")] {
            boardPoint(app, x, 2)
            XCTAssertEqual(app.otherElements["challengeArena"].value as? String, label)
            XCTAssertEqual(app.staticTexts["challengeResources"].label, originalResources)
            XCTAssertFalse(app.buttons["challengeConfirm"].isEnabled, "Occupied targets must remain a read-only invalid preview")
        }
        for id in ["challengeSoldier", "challengeSkill", "challengeConfirm", "challengePoints"] {
            reveal(app, app.buttons[id])
            XCTAssertGreaterThanOrEqual(app.buttons[id].frame.height, 44)
            XCTAssertGreaterThanOrEqual(app.buttons[id].frame.width, 44)
        }
        shot(app, "CONTENT03-ipad-landscape")
        action(app, skill: true, points: [(4,2)], direction: "Down")
        ready(app)
        let savedResources = app.staticTexts["challengeResources"].label
        app.terminate(); app.launch()
        XCTAssertTrue(app.staticTexts["challengeTitle"].waitForExistence(timeout: 10))
        ready(app)
        XCTAssertEqual(app.staticTexts["challengeResources"].label, savedResources)
        action(app, points: [(4,2)]); ready(app)
        action(app, points: [(6,1)]); action(app, points: [(6,3)])
        XCTAssertTrue(app.staticTexts["challengeResult"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["challengeResult"].label.contains("完成"))
        shot(app, "CONTENT03-ipad-restored-completion")
        XCUIDevice.shared.orientation = .portrait
    }
    func testExitDuringReplyNeverCommitsIntoNextChallenge() {
        let app = app()
        app.buttons["challenge-c03-2-feint-counterattack"].tap()
        action(app, skill: true, points: [(4,2)], direction: "Down")
        action(app, points: [(4,2)])
        // Retry while the reply task is live, then leave and select another fixture.
        reveal(app, app.buttons["challengeRetry"]); app.buttons["challengeRetry"].tap()
        reveal(app, app.buttons["challengeBack"]); app.buttons["challengeBack"].tap()
        app.buttons["challenge-c03-1-commander-rescue"].tap()
        ready(app)
        let expected = app.staticTexts["challengeResources"].label
        let unchanged = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            app.staticTexts["challengeResources"].label != expected
        }, object: nil)
        unchanged.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [unchanged], timeout: 3), .completed)
        XCTAssertTrue(expected.contains("已用 0"))
        shot(app, "CONTENT03-reply-invalidated")
    }
}
