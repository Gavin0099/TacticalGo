import XCTest

@MainActor final class MonsterLabTests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--monster-lab"]; app.launch()
        XCTAssertTrue(app.staticTexts["mobTitle"].waitForExistence(timeout: 15))
        return app
    }
    private func loadComparison(_ app: XCUIApplication) {
        for _ in 0..<3 { if app.buttons["mobReachable"].isHittable { break }; app.swipeUp() }
        app.buttons["mobReachable"].tap()
        app.swipeDown()
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("黑方 · 第 3 回合 · 1 AP"))
    }
    private func confirm(_ app: XCUIApplication) {
        for _ in 0..<3 { if app.buttons["mobConfirm"].isHittable { break }; app.swipeUp() }
        app.buttons["mobConfirm"].tap()
    }
    private func tap(_ app: XCUIApplication, _ id: String) {
        let button = app.buttons[id]
        for _ in 0..<4 { if button.isHittable { break }; app.swipeDown() }
        for _ in 0..<4 { if button.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(button.isHittable, id); button.tap()
    }
    private func shot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name
        attachment.lifetime = .keepAlways; add(attachment)
    }
    func testPaidHuntPreviewCancelConfirmUndoAndOffset() {
        let app = launch()
        loadComparison(app)
        let status = app.staticTexts["mobStatus"].label
        tap(app, "mobCell_4_4")
        XCTAssertTrue(app.staticTexts["mobPreview"].label.contains("花 1 AP"))
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        XCTAssertTrue(app.buttons["mobCell_4_4"].label.contains("史萊姆"))
        shot(app, "mob-paid-hunt-preview")
        tap(app, "mobCancel")
        XCTAssertFalse(app.buttons["mobConfirm"].isEnabled)
        tap(app, "mobCell_4_4"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("白方 · 第 4 回合"))
        XCTAssertTrue(app.staticTexts["mobHunted"].exists)
        tap(app, "mobUndo")
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        XCTAssertTrue(app.buttons["mobCell_4_4"].label.contains("史萊姆"))
        app.swipeDown()
        app.segmentedControls["mobPosition"].buttons["偏中心"].tap()
        XCTAssertTrue(app.buttons["mobCell_3_4"].label.contains("史萊姆"))
        XCTAssertTrue(app.buttons["mobCell_4_4"].label.contains("空點"))
        shot(app, "mob-offset-new-game")
    }
    func testFreeHuntAtZeroAPThenUndoAndSkip() {
        let app = launch()
        app.segmentedControls["mobCost"].buttons["0 AP"].tap()
        loadComparison(app)
        tap(app, "mobCell_4_6"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobFreeWindow"].exists)
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("黑方 · 第 3 回合 · 0 AP"))
        tap(app, "mobCell_0_1")
        XCTAssertFalse(app.buttons["mobConfirm"].isEnabled)
        tap(app, "mobCell_4_4")
        XCTAssertTrue(app.buttons["mobConfirm"].isEnabled)
        shot(app, "mob-free-last-ap-window")
        confirm(app)
        XCTAssertTrue(app.staticTexts["mobHunted"].exists)
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("白方 · 第 4 回合"))
        tap(app, "mobUndo")
        XCTAssertTrue(app.staticTexts["mobFreeWindow"].exists)
        tap(app, "mobEndTurn")
        XCTAssertFalse(app.staticTexts["mobFreeWindow"].exists)
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("白方 · 第 4 回合"))
        XCTAssertTrue(app.buttons["mobCell_4_4"].label.contains("史萊姆"))
        shot(app, "mob-free-hunt-skipped")
    }
    func testUncontrolledMonsterRejectsWithoutChangingState() {
        let app = launch()
        let status = app.staticTexts["mobStatus"].label
        tap(app, "mobCell_4_4")
        XCTAssertTrue(app.staticTexts["mobPreview"].label.contains("至少 2 格"))
        XCTAssertFalse(app.buttons["mobConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
    }
    func testSlimeLootLegalReplayPreviewConsumptionUndo() {
        let app = launch()
        tap(app, "mobLootReachable")
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("黏彈 · 可用一次"))
        XCTAssertTrue(app.staticTexts["mobLootWhite"].label.contains("無可用"))
        let status = app.staticTexts["mobStatus"].label
        tap(app, "mobCell_4_4"); tap(app, "mobCell_5_4")
        XCTAssertTrue(app.staticTexts["mobPreview"].label.contains("1 AP／0 能量"))
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        shot(app, "mob-slime-loot-preview")
        confirm(app)
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("無可用"))
        XCTAssertTrue(app.buttons["mobCell_5_4"].label.contains("空點"))
        XCTAssertTrue(app.buttons["mobCell_6_4"].label.contains("黑方士兵"))
        tap(app, "mobUndo")
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("可用一次"))
        XCTAssertTrue(app.buttons["mobCell_5_4"].label.contains("黑方士兵"))
    }
    func testWolfLootLegalReplayMoveUndoAndBlockedTarget() {
        let app = launch()
        app.segmentedControls["mobKind"].buttons["暗影狼"].tap()
        tap(app, "mobLootReachable")
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("影步 · 可用一次"))
        let status = app.staticTexts["mobStatus"].label
        tap(app, "mobCell_4_3") // diagonal from hero at D5
        XCTAssertFalse(app.buttons["mobConfirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        tap(app, "mobCell_3_2"); shot(app, "mob-wolf-step-preview"); confirm(app)
        XCTAssertTrue(app.buttons["mobCell_3_2"].label.contains("黑方英雄"))
        XCTAssertTrue(app.buttons["mobCell_3_4"].label.contains("空點"))
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("無可用"))
        tap(app, "mobUndo")
        XCTAssertEqual(app.staticTexts["mobStatus"].label, status)
        XCTAssertTrue(app.buttons["mobCell_3_4"].label.contains("黑方英雄"))
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("可用一次"))
    }
    func testDualLootSwitchConsumesOnlyChosenAbilityAndUndoRestoresBoth() {
        let app = launch()
        app.switches["mobDual"].tap()
        XCTAssertTrue(app.buttons["mobCell_2_4"].label.contains("史萊姆"))
        XCTAssertTrue(app.buttons["mobCell_6_4"].label.contains("暗影狼"))
        tap(app,"mobLootReachable")
        let both = app.staticTexts["mobLootBlack"].label
        XCTAssertTrue(both.contains("黏彈 · 可用一次")); XCTAssertTrue(both.contains("影步 · 可用一次"))
        let status = app.staticTexts["mobStatus"].label
        tap(app,"mobCell_1_5"); tap(app,"mobCell_1_4")
        XCTAssertTrue(app.staticTexts["mobPreview"].label.contains("1 AP／0 能量"))
        shot(app,"mob-dual-bounce-preview"); confirm(app)
        XCTAssertFalse(app.staticTexts["mobLootBlack"].label.contains("黏彈"))
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("影步 · 可用一次"))
        app.segmentedControls["mobAbility"].buttons["影步"].tap()
        tap(app,"mobCell_5_2")
        XCTAssertFalse(app.buttons["mobConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["mobPreview"].label.contains("技能"))
        tap(app,"mobUndo")
        XCTAssertEqual(app.staticTexts["mobLootBlack"].label,both)
        XCTAssertEqual(app.staticTexts["mobStatus"].label,status)
        tap(app,"mobCell_5_2"); shot(app,"mob-dual-step-preview"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("黏彈 · 可用一次"))
        XCTAssertFalse(app.staticTexts["mobLootBlack"].label.contains("影步"))
        XCTAssertTrue(app.buttons["mobCell_5_2"].label.contains("黑方英雄"))
    }
    func testDualFreeWindowHuntOneSkipAndUndo() {
        let app = launch()
        app.switches["mobDual"].tap()
        XCTAssertEqual(app.buttons["mobCell_2_4"].value as? String,"候選圖樣已載入")
        XCTAssertEqual(app.buttons["mobCell_6_4"].value as? String,"候選圖樣已載入")
        shot(app,"mob-dual-monster-art-initial")
        app.segmentedControls["mobCost"].buttons["0 AP"].tap()
        tap(app,"mobReachable")
        tap(app,"mobCell_0_1"); confirm(app)
        tap(app,"mobCell_0_2"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobFreeWindow"].exists)
        tap(app,"mobCell_2_4"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobFreeWindow"].exists)
        XCTAssertTrue(app.buttons["mobCell_2_4"].label.contains("空點"))
        XCTAssertTrue(app.buttons["mobCell_6_4"].label.contains("暗影狼"))
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("第 9 回合解鎖"))
        shot(app,"mob-dual-free-one-left")
        tap(app,"mobEndTurn")
        XCTAssertFalse(app.staticTexts["mobFreeWindow"].exists)
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("白方 · 第 8 回合"))
        tap(app,"mobUndo")
        XCTAssertTrue(app.staticTexts["mobFreeWindow"].exists)
        tap(app,"mobCell_6_4"); confirm(app)
        XCTAssertTrue(app.staticTexts["mobHunted"].exists)
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("黏彈"))
        XCTAssertTrue(app.staticTexts["mobLootBlack"].label.contains("影步"))
        XCTAssertTrue(app.staticTexts["mobStatus"].label.contains("白方 · 第 8 回合"))
    }

}
