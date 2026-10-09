import XCTest

@MainActor final class BoardInteractionTests: XCTestCase {
    func testBothRenderersPreviewConfirmRejectAndUndo() {
        for swiftUI in [false, true] {
            let app = XCUIApplication()
            app.launchArguments = swiftUI ? ["--swiftui"] : ["--spritekit"]
            app.launchArguments.append("--review-controls"); app.launch()
            let arena = app.otherElements["arena"]
            XCTAssertTrue(arena.waitForExistence(timeout: 10))
            let confirm = app.buttons["confirm"]
            XCTAssertFalse(confirm.isEnabled)
            // (4,3) on 7×7: manually calculated from the published normalized projection.
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.633333, dy: 0.505)).tap()
            XCTAssertTrue(confirm.isEnabled)
            XCTAssertTrue(app.staticTexts["2 次"].exists) // preview has not spent AP
            confirm.tap()
            XCTAssertTrue(app.staticTexts["1 次"].exists)
            app.buttons["復原"].tap()
            XCTAssertTrue(app.staticTexts["2 次"].exists)
            // Occupied hero cell must report a reason and forbid confirmation.
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.505)).tap()
            XCTAssertFalse(confirm.isEnabled)
            XCTAssertEqual(app.staticTexts["message"].label, "這裡已有棋子。")
            app.terminate()
        }
    }
    func testWarriorAndMageSummonArtReview() {
        let app = XCUIApplication()
        app.launchArguments = ["--spritekit"]
        app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.buttons["新對戰"].waitForExistence(timeout: 10))
        app.buttons["新對戰"].tap()
        app.segmentedControls["mode"].buttons["召喚英雄"].tap()
        let arena = app.otherElements["arena"]
        // Fresh 7×7 Warrior: (3,4), adjacent to blue commander (3,5).
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.613333)).tap()
        XCTAssertTrue(app.buttons["confirm"].isEnabled)
        app.buttons["confirm"].tap()
        XCTAssertTrue(app.staticTexts["紅方行動"].exists)
        // Mage: (3,2), adjacent to red commander (3,1).
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.396667)).tap()
        XCTAssertTrue(app.buttons["confirm"].isEnabled)
        app.buttons["confirm"].tap()
        XCTAssertTrue(app.staticTexts["1 / 6"].exists)
        for renderer in ["SpriteKit", "SwiftUI"] {
            app.segmentedControls["renderer"].buttons[renderer].tap()
            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "warrior-mage-" + renderer; shot.lifetime = .keepAlways; add(shot)
        }
    }
    func testReviewScreensAndNineBoard() {
        let app = XCUIApplication()
        app.launchArguments = ["--nine", "--skill", "--spritekit"]
        app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.buttons["confirm"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["confirm"].isEnabled)
        XCTAssertEqual(app.otherElements["arena"].label, "9乘9棋盤")
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "9x9-skill"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.segmentedControls["review"].buttons["危險"].tap()
        XCTAssertTrue(app.staticTexts["1 氣"].exists)
        XCTAssertFalse(app.buttons["confirm"].isEnabled)
        let danger = XCTAttachment(screenshot: app.screenshot()); danger.name = "9x9-danger"; danger.lifetime = .keepAlways; add(danger)
    }
    func testThreeDimensionalBoardAndModelInspection() {
        let app = XCUIApplication()
        app.launchArguments.append("--review-controls"); app.launch()
        let arena = app.otherElements["arena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 20))
        XCTAssertTrue(app.segmentedControls["renderer"].buttons["3D"].isSelected)
        // Independently selected from the native camera review: empty (4,3),
        // followed by occupied (3,3). These exercise the actual 3D projection.
        // Hand-derived from the camera contract: one world unit at depth 12.77,
        // vertical FOV 38°, horizontal normalized pitch = 0.114 × height/width.
        let right = 0.5 + 0.114 * arena.frame.height / arena.frame.width
        arena.coordinate(withNormalizedOffset: CGVector(dx: right, dy: 0.518)).tap()
        XCTAssertTrue(app.buttons["confirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        app.buttons["confirm"].tap()
        XCTAssertTrue(app.staticTexts["1 次"].exists)
        app.buttons["復原"].tap()
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.518)).tap()
        XCTAssertFalse(app.buttons["confirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["message"].label, "這裡已有棋子。")
        app.buttons["旋轉視角"].tap()
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.518)).tap()
        XCTAssertFalse(app.buttons["confirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["message"].label, "這裡已有棋子。")
        renderedFrame()
        let rotated = XCTAttachment(screenshot: app.screenshot()); rotated.name = "board-3d-rotated"; rotated.lifetime = .keepAlways; add(rotated)
        app.buttons["英雄模型"].tap()
        XCTAssertTrue(app.segmentedControls["modelClass"].waitForExistence(timeout: 15))
        // Inspect the first frame even before selecting another class.
        renderedFrame()
        let entry = XCTAttachment(screenshot: app.screenshot()); entry.name = "model-first-entry-warrior"; entry.lifetime = .keepAlways; add(entry)
        for hero in ["戰士", "法師", "盜賊"] {
            app.segmentedControls["modelClass"].buttons[hero].tap()
            XCTAssertTrue(app.segmentedControls["modelClass"].buttons[hero].isSelected)
            renderedFrame()
            let front = XCTAttachment(screenshot: app.screenshot()); front.name = "model-" + hero + "-front"; front.lifetime = .keepAlways; add(front)
            app.buttons["modelMotion"].tap()
            let pose = XCTAttachment(screenshot: app.screenshot()); pose.name = "model-" + hero + "-pose"; pose.lifetime = .keepAlways; add(pose)
            renderedFrame()
        }
        app.buttons["rotateModel"].tap()
        renderedFrame()
        let back = XCTAttachment(screenshot: app.screenshot()); back.name = "model-rogue-back"; back.lifetime = .keepAlways; add(back)
        app.buttons["完成"].tap()
        app.segmentedControls["boardSize"].buttons["9 × 9"].tap()
        app.segmentedControls["review"].buttons["危險"].tap()
        XCTAssertEqual(arena.label, "9乘9棋盤")
        XCTAssertTrue(app.staticTexts["1 氣"].exists)
        renderedFrame()
        let nine = XCTAttachment(screenshot: app.screenshot()); nine.name = "board-3d-9x9-danger"; nine.lifetime = .keepAlways; add(nine)
    }
    func testIdleStopAttackHeroChangeReducedAndReturn() {
        let app = XCUIApplication(); app.launchArguments = ["--models", "--review-controls"]; app.launch()
        XCTAssertTrue(app.buttons["modelIdle"].waitForExistence(timeout: 20))
        let idle = app.buttons["modelIdle"]
        XCTAssertGreaterThanOrEqual(idle.frame.height, 44)
        XCTAssertEqual(idle.value as? String, "停止")
        for hero in ["戰士", "法師", "盜賊"] {
            app.segmentedControls["modelClass"].buttons[hero].tap()
            XCTAssertEqual(idle.value as? String, "停止")
            idle.tap(); XCTAssertEqual(idle.value as? String, "播放中")
            renderedFrame()
            let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "idle-" + hero; shot.lifetime = .keepAlways; add(shot)
            idle.tap(); XCTAssertEqual(idle.value as? String, "停止")
            idle.tap(); app.buttons["modelMotion"].tap(); XCTAssertEqual(idle.value as? String, "停止")
            renderedFrame()
        }
        idle.tap(); app.segmentedControls["modelClass"].buttons["戰士"].tap()
        XCTAssertEqual(idle.value as? String, "停止")
        idle.tap(); app.switches["modelReduceMotion"].tap()
        XCTAssertEqual(idle.value as? String, "停止"); XCTAssertFalse(idle.isEnabled)
        app.switches["modelReduceMotion"].tap(); XCTAssertTrue(idle.isEnabled)
        idle.tap(); app.buttons["完成"].tap()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        app.buttons["英雄模型"].tap()
        XCTAssertTrue(idle.waitForExistence(timeout: 10)); XCTAssertEqual(idle.value as? String, "停止")
        app.buttons["完成"].tap(); XCTAssertTrue(app.staticTexts["2 次"].exists)
    }
    private func renderedFrame() {
        // XCTest UI-idle does not await RealityKit's asynchronous Metal frame.
        // Attachments are subsequently inspected for actual silhouette/class/angle.
        let frame = expectation(description: "RealityKit render settling")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { frame.fulfill() }
        wait(for: [frame], timeout: 4)
    }
    func testAnimationExamplesUseRealResultsSkipAndReducedMotion() {
        let app = XCUIApplication(); app.launchArguments = ["--motion-review"]; app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.buttons["playMotion"].waitForExistence(timeout: 20))
        for name in ["落子", "召喚", "提子", "築壘", "封印", "換位", "勝負", "封印到期"] {
            app.buttons["motion-" + name].tap()
            app.buttons["playMotion"].tap()
            if name == "勝負" { XCTAssertTrue(app.staticTexts["藍方獲勝"].exists) }
            else if name == "封印到期" {
                XCTAssertTrue(app.staticTexts["2 次 · 5 能量"].exists)
                XCTAssertTrue(app.staticTexts["紅方結束回合，封印到期；藍方開始行動。"].exists)
            }
            else { XCTAssertTrue(app.staticTexts["1 次 · \(name == "落子" || name == "提子" ? 6 : 4) 能量"].exists) }
            app.buttons["skipMotion"].tap()
            renderedFrame()
            let result = XCTAttachment(screenshot: app.screenshot()); result.name = "motion-result-" + name; result.lifetime = .keepAlways; add(result)
        }
        app.switches["reduceMotion"].tap()
        app.buttons["motion-換位"].tap()
        app.buttons["playMotion"].tap()
        XCTAssertTrue(app.staticTexts["1 次 · 4 能量"].exists)
        app.buttons["重設"].tap()
        XCTAssertTrue(app.staticTexts["2 次 · 6 能量"].exists)
        app.buttons["完成"].tap()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2 次"].exists) // Review did not mutate the player's match.
    }
    func testSkipDelayedBastionAndLeaveRunningMotion() {
        let app = XCUIApplication(); app.launchArguments = ["--motion-review"]; app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.buttons["playMotion"].waitForExistence(timeout: 20))
        app.switches["slowMotion"].tap()
        app.buttons["playMotion"].tap() // Default: bastion, with delayed soldiers.
        app.buttons["skipMotion"].tap()
        XCTAssertTrue(app.staticTexts["1 次 · 4 能量"].exists)
        renderedFrame()
        let skipped = XCTAttachment(screenshot: app.screenshot()); skipped.name = "bastion-skipped-final"; skipped.lifetime = .keepAlways; add(skipped)
        app.buttons["重設"].tap()
        app.buttons["playMotion"].tap()
        app.buttons["完成"].tap()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        renderedFrame()
        let returned = XCTAttachment(screenshot: app.screenshot()); returned.name = "main-after-interrupted-bastion"; returned.lifetime = .keepAlways; add(returned)
        app.buttons["英雄模型"].tap()
        XCTAssertTrue(app.segmentedControls["modelClass"].waitForExistence(timeout: 10))
        renderedFrame()
        let model = XCTAttachment(screenshot: app.screenshot()); model.name = "model-after-interrupted-bastion"; model.lifetime = .keepAlways; add(model)
    }
    func testOriginalIdentityCandidatesLoadPlaySwitchAndReturn() {
        let app = XCUIApplication()
        app.launchArguments = ["--identity-models", "--review-controls"]
        app.launch()
        XCTAssertTrue(app.segmentedControls["modelClass"].waitForExistence(timeout: 25))
        for title in ["戰士", "法師", "盜賊"] {
            app.segmentedControls["modelClass"].buttons[title].tap()
            let loaded = NSPredicate(format: "label == %@", "原圖" + title + "候選 · 技能片段已載入")
            expectation(for: loaded, evaluatedWith: app.staticTexts["resourceModelStatus"])
            waitForExpectations(timeout: 20)
            XCTAssertTrue(app.buttons["modelMotion"].isHittable)
            let rest = XCTAttachment(screenshot: app.screenshot())
            rest.name = "original-identity-" + title; rest.lifetime = .keepAlways; add(rest)
            app.buttons["modelMotion"].tap()
            // Next class interrupts the current imported clip; latest class must load.
        }
        app.switches["identityModelToggle"].tap()
        app.switches["identityModelToggle"].tap()
        let reloaded = NSPredicate(format: "label == %@", "原圖盜賊候選 · 技能片段已載入")
        expectation(for: reloaded, evaluatedWith: app.staticTexts["resourceModelStatus"])
        waitForExpectations(timeout: 20)
        app.buttons["modelMotion"].tap()
        app.buttons["完成"].tap()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["2 次"].exists)
    }
    func testImportedSkeletonModelsPlayAndReturnToMatch() {
        // Fixture setup copies the three validated candidate USDZ packages to
        // this simulator's Documents directory before running this focused test.
        let app = XCUIApplication(); app.launchArguments = ["--rig-models"]; app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.segmentedControls["modelClass"].waitForExistence(timeout: 20))
        for hero in ["戰士", "法師", "盜賊"] {
            app.segmentedControls["modelClass"].buttons[hero].tap()
            let loaded = NSPredicate(format: "label == %@", "建模資源 · 2 段動作")
            expectation(for: loaded, evaluatedWith: app.staticTexts["resourceModelStatus"])
            waitForExpectations(timeout: 15)
            renderedFrame()
            let rest = XCTAttachment(screenshot: app.screenshot()); rest.name = "imported-rig-" + hero + "-rest"; rest.lifetime = .keepAlways; add(rest)
            app.buttons["modelMotion"].tap()
            let pose = XCTAttachment(screenshot: app.screenshot()); pose.name = "imported-rig-" + hero + "-pose"; pose.lifetime = .keepAlways; add(pose)
            renderedFrame()
        }
        app.buttons["modelMotion"].tap()
        app.buttons["完成"].tap() // Stop imported playback while leaving the gallery.
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        renderedFrame()
        let game = XCTAttachment(screenshot: app.screenshot()); game.name = "match-after-imported-playback"; game.lifetime = .keepAlways; add(game)
    }
    func testDrawEndsMatchAndUndoRestoresPlay() {
        let app = XCUIApplication(); app.launchArguments = ["--last-turn"]; app.launchArguments.append("--review-controls"); app.launch()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["1 次"].exists)
        app.buttons["換手"].tap()
        XCTAssertTrue(app.staticTexts["和局"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["message"].label, "已達 100 回合上限，對戰以和局結束。")
        XCTAssertFalse(app.buttons["換手"].isEnabled); XCTAssertFalse(app.buttons["confirm"].isEnabled)
        renderedFrame()
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "draw-result"; shot.lifetime = .keepAlways; add(shot)
        app.buttons["復原"].tap()
        XCTAssertFalse(app.staticTexts["和局"].exists); XCTAssertTrue(app.buttons["換手"].isEnabled)
        XCTAssertTrue(app.staticTexts["1 次"].exists)
        app.buttons["換手"].tap()
        XCTAssertTrue(app.staticTexts["和局"].exists)
        app.buttons["新對戰"].tap()
        XCTAssertFalse(app.staticTexts["和局"].exists); XCTAssertTrue(app.buttons["換手"].isEnabled)
        XCTAssertTrue(app.staticTexts["藍方行動"].exists)
    }

    func testPhonePlayLayoutZoomUsesRealNineBoardCoordinates() {
        let app = XCUIApplication()
        // A tappable accessibility overlay previously vanished from raw9×9
        // frames. The control now occupies a separate visible44pt row on both sizes.
        for flags in [[], ["--nine"]] as [[String]] {
            app.launchArguments = flags; app.launch()
            let board = app.otherElements["arena"]
            XCTAssertTrue(board.waitForExistence(timeout: 20)); renderedFrame()
            let zoom = app.buttons["boardZoom"]
            XCTAssertTrue(zoom.isHittable)
            XCTAssertGreaterThanOrEqual(zoom.frame.height, 44)
            XCTAssertLessThanOrEqual(zoom.frame.maxY, board.frame.minY)
            XCTAssertTrue(app.frame.contains(zoom.frame))
            let visible = XCTAttachment(screenshot: app.screenshot())
            visible.name = flags.isEmpty ? "phone-play-7x7-visible-zoom" : "phone-play-9x9-visible-zoom"
            visible.lifetime = .keepAlways; add(visible)
            app.terminate()
        }
        app.launchArguments = ["--nine"]; app.launch()
        let arena = app.otherElements["arena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 20))
        XCTAssertFalse(app.segmentedControls["review"].exists)
        XCTAssertTrue(app.staticTexts["法師 · 封印"].exists)
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        XCTAssertTrue(app.buttons["confirm"].isHittable)
        let zoom = app.buttons["boardZoom"]
        XCTAssertTrue(zoom.isHittable)
        renderedFrame()
        let full = XCTAttachment(screenshot: app.screenshot()); full.name = "phone-play-9x9-full"; full.lifetime = .keepAlways; add(full)
        zoom.tap(); renderedFrame()
        // The independent fixture's empty central intersection is (4,4); zoom
        // changes only the camera, and its native projected center stays central.
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "5,5")
        XCTAssertTrue(app.staticTexts["2 次"].exists); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        let detail = XCTAttachment(screenshot: app.screenshot()); detail.name = "phone-play-9x9-zoom-preview"; detail.lifetime = .keepAlways; add(detail)
        app.buttons["confirm"].tap(); XCTAssertTrue(app.staticTexts["1 次"].exists)
        zoom.tap(); renderedFrame()
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertFalse(app.buttons["confirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["message"].label, "這裡已有棋子。")
        app.buttons["對戰設定"].tap(); app.buttons["復原"].tap()
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        // On iOS 18 the menu's closing animation can outlive the state update.
        // Check the settled screen, while still failing if it remains covered.
        let uncovered = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.buttons["confirm"])
        wait(for: [uncovered], timeout: 5)
    }

    func testZoomedBoardDragAndLocatePreservePreview() {
        let app = XCUIApplication()
        for flags in [[], ["--nine"]] as [[String]] {
            app.launchArguments = flags + ["--pan-receipt"]; app.launch()
            let arena = app.otherElements["arena"]
            XCTAssertTrue(arena.waitForExistence(timeout: 20)); renderedFrame()
            app.buttons["boardZoom"].tap(); renderedFrame()
            let locate = app.buttons["boardLocate"]
            XCTAssertTrue(locate.isHittable); XCTAssertGreaterThanOrEqual(locate.frame.height, 44)
            XCTAssertEqual(locate.value as? String, "已置中")
            let before = XCTAttachment(screenshot: app.screenshot()); before.name = flags.isEmpty ? "pan-7-before" : "pan-9-before"; before.lifetime = .keepAlways; add(before)
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5)))
            renderedFrame()
            XCTAssertEqual(locate.value as? String, "棋盤已移動")
            XCTAssertEqual(arena.value as? String, ""); XCTAssertFalse(app.buttons["confirm"].isEnabled)
            XCTAssertTrue(app.staticTexts["2 次"].exists)
            let horizontal = XCTAttachment(screenshot: app.screenshot()); horizontal.name = flags.isEmpty ? "pan-7-horizontal" : "pan-9-horizontal"; horizontal.lifetime = .keepAlways; add(horizontal)
            let originalFrame = arena.frame
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
            renderedFrame()
            XCTAssertEqual(arena.frame, originalFrame) // board moves, page does not
            XCTAssertEqual(arena.value as? String, ""); XCTAssertTrue(app.staticTexts["2 次"].exists)
            let vertical = XCTAttachment(screenshot: app.screenshot()); vertical.name = flags.isEmpty ? "pan-7-vertical" : "pan-9-vertical"; vertical.lifetime = .keepAlways; add(vertical)
            locate.tap(); renderedFrame(); XCTAssertEqual(locate.value as? String, "已置中")
            let restored = XCTAttachment(screenshot: app.screenshot()); restored.name = flags.isEmpty ? "pan-7-located" : "pan-9-located"; restored.lifetime = .keepAlways; add(restored)
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
            XCTAssertEqual(arena.value as? String, flags.isEmpty ? "4,4" : "5,5")
            XCTAssertEqual(app.buttons["confirm"].isEnabled, !flags.isEmpty) // known 7 hero / 9 empty center
            XCTAssertTrue(app.staticTexts["2 次"].exists)
            app.buttons["boardZoom"].tap(); XCTAssertFalse(locate.exists)
            app.terminate()
        }
    }

    func testZoomedNineBoardRepeatedEdgeDragsRemainOperable() {
        let app = XCUIApplication(); app.launchArguments = ["--nine", "--pan-receipt"]; app.launch()
        let arena = app.otherElements["arena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 20)); renderedFrame()
        app.buttons["boardZoom"].tap(); renderedFrame()
        for _ in 0..<4 {
            arena.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.7)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3)))
            renderedFrame()
        }
        XCTAssertEqual(arena.value as? String, ""); XCTAssertTrue(app.staticTexts["2 次"].exists)
        let edge = XCTAttachment(screenshot: app.screenshot()); edge.name = "pan-9-clamped-edge"; edge.lifetime = .keepAlways; add(edge)
        app.buttons["boardLocate"].tap(); renderedFrame()
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        app.buttons["confirm"].tap(); XCTAssertTrue(app.staticTexts["1 次"].exists)
    }

    func testZoomedPanPreservesSelectedPreviewAndNewMatchResetsCamera() {
        let app = XCUIApplication(); app.launchArguments = ["--nine"]; app.launch()
        let arena = app.otherElements["arena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 20)); renderedFrame()
        app.buttons["boardZoom"].tap(); renderedFrame()
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)))
        renderedFrame()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["2 次"].exists); XCTAssertTrue(app.staticTexts["4 / 6"].exists)
        app.buttons["boardLocate"].tap(); renderedFrame()
        XCTAssertEqual(arena.value as? String, "5,5")
        app.buttons["對戰設定"].tap(); app.buttons["新對戰"].tap(); renderedFrame()
        XCTAssertFalse(app.buttons["boardLocate"].exists); XCTAssertEqual(arena.value as? String, "")
        XCTAssertFalse(app.buttons["confirm"].isEnabled); XCTAssertTrue(app.staticTexts["1 次"].exists)
        XCTAssertTrue(app.staticTexts["戰士 · 築壘"].exists)
        app.buttons["boardZoom"].tap(); renderedFrame()
        app.buttons["對戰設定"].tap(); app.buttons["旋轉視角"].tap(); renderedFrame()
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7)).press(forDuration: 0.1, thenDragTo: arena.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)))
        renderedFrame()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.staticTexts["1 次"].exists)
        app.buttons["boardLocate"].tap(); renderedFrame()
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "pan-selected-rotated-new-match-located"; shot.lifetime = .keepAlways; add(shot)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "5,5"); XCTAssertTrue(app.buttons["confirm"].isEnabled)
        app.buttons["confirm"].tap(); XCTAssertTrue(app.staticTexts["紅方行動"].exists)
    }

    func testPhoneCommanderCaptureEndsMatchAndUndoRestoresIt() {
        let app = XCUIApplication(); app.launchArguments = ["--winning-turn"]; app.launch()
        let arena = app.otherElements["arena"]
        XCTAssertTrue(arena.waitForExistence(timeout: 20)); renderedFrame()
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        XCTAssertEqual(arena.value as? String, "4,4")
        XCTAssertTrue(app.buttons["confirm"].isEnabled)
        app.buttons["confirm"].tap()
        XCTAssertTrue(app.staticTexts["藍方獲勝"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["對戰結束"].exists)
        XCTAssertEqual(app.staticTexts["message"].label, "藍方獲勝！主將已被包圍。")
        XCTAssertFalse(app.buttons["換手"].isEnabled); XCTAssertFalse(app.buttons["confirm"].isEnabled)
        renderedFrame()
        let result = XCTAttachment(screenshot: app.screenshot()); result.name = "phone-commander-captured-result"; result.lifetime = .keepAlways; add(result)
        XCTAssertTrue(app.staticTexts["藍方獲勝"].isHittable)
        app.buttons["對戰設定"].tap(); app.buttons["復原"].tap()
        XCTAssertTrue(app.staticTexts["2 次"].exists); XCTAssertFalse(app.staticTexts["藍方獲勝"].exists)
        let uncovered = expectation(for: NSPredicate(format: "hittable == true"), evaluatedWith: app.buttons["confirm"])
        wait(for: [uncovered], timeout: 5)
        XCTAssertTrue(app.buttons["換手"].isEnabled)
        arena.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.510)).tap()
        app.buttons["confirm"].tap(); XCTAssertTrue(app.staticTexts["藍方獲勝"].exists)
        app.buttons["對戰設定"].tap(); app.buttons["新對戰"].tap()
        XCTAssertTrue(app.staticTexts["藍方行動"].exists); XCTAssertFalse(app.staticTexts["藍方獲勝"].exists)
        XCTAssertTrue(app.buttons["換手"].isEnabled)
    }

    func testContinuousMatchesSkipUndoReducedMotionAndOppositeWinners() {
        let app = XCUIApplication(); app.launchArguments = ["--match-review"]; app.launch()
        XCTAssertTrue(app.otherElements["matchReplayArena"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts["0 / 16 步 · 1 回合"].exists)
        app.buttons["nextMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["1 / 16 步 · 2 回合"].exists)
        app.buttons["skipMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["1 / 16 步 · 2 回合"].exists)
        app.buttons["undoMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["0 / 16 步 · 1 回合"].exists)
        app.buttons["autoMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["藍方獲勝"].waitForExistence(timeout: 45))
        XCTAssertTrue(app.staticTexts["16 / 16 步 · 9 回合"].exists)
        XCTAssertFalse(app.buttons["nextMatchReplay"].isEnabled)
        renderedFrame()
        let blue = XCTAttachment(screenshot: app.screenshot()); blue.name = "continuous-blue-win"; blue.lifetime = .keepAlways; add(blue)
        app.buttons["undoMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["15 / 16 步 · 9 回合"].exists)
        XCTAssertFalse(app.staticTexts["藍方獲勝"].exists)
        app.switches["matchReplayReduce"].tap()
        app.buttons["nextMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["藍方獲勝"].exists)
        app.segmentedControls["matchExample"].buttons["盜賊／戰士"].tap()
        XCTAssertTrue(app.staticTexts["0 / 11 步 · 1 回合"].exists)
        app.buttons["autoMatchReplay"].tap()
        XCTAssertTrue(app.staticTexts["紅方獲勝"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["11 / 11 步 · 6 回合"].exists)
        XCTAssertFalse(app.buttons["nextMatchReplay"].isEnabled)
        renderedFrame()
        let red = XCTAttachment(screenshot: app.screenshot()); red.name = "continuous-red-win"; red.lifetime = .keepAlways; add(red)
        app.buttons["resetMatchReplay"].tap()
        XCTAssertFalse(app.staticTexts["紅方獲勝"].exists)
        XCTAssertTrue(app.staticTexts["0 / 11 步 · 1 回合"].exists)
        app.buttons["nextMatchReplay"].tap(); app.buttons["完成"].tap()
        XCTAssertTrue(app.otherElements["arena"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2 次"].exists)
        XCTAssertTrue(app.staticTexts["法師 · 封印"].exists)
    }
}
