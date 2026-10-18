import XCTest

@MainActor final class ExpansionLabTests: XCTestCase {
    private func ready(_ app: XCUIApplication) {
        let enabled = XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:app.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for:[enabled],timeout:8),.completed)
    }
    private func integrated(_ hero: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        #if DEBUG
        app.expansionShellArguments = hero.map { ["--integrated-practice",$0] } ?? []
        app.launch()
        #else
        app.expansionShellArguments = []
        app.launch()
        if let hero {
            let title = (hero == "mage" ? "法師":hero == "warrior" ? "戰士":hero == "rogue" ? "盜賊":"牧師") + " · 擴充技能"
            XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
            app.buttons["玩法練習"].tap();app.buttons[title].tap()
        }
        #endif
        XCTAssertFalse(app.buttons["openExpansion"].exists); return app
    }
    private func normalPoints(_ app: XCUIApplication,_ points: [(Int,Int)]) {
        for (x,y) in points { tap(app,"play-cell-\(x)-\(y)") }
    }
    func testQualitySequenceFromNormalLobbyToMageCastCaptureResultAndUndo() {
        for size in [7, 9] {
            let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
            app.swipeUp();tap(app,"choose-mage");XCTAssertTrue(app.buttons["choose-mage"].isSelected)
            tap(app,"\(size) × \(size)")
            XCTAssertTrue(app.segmentedControls["playBoardSize"].buttons["\(size) × \(size)"].isSelected)
            shot(app,"quality35-\(size)-lobby")
            tap(app,"startMatch");ready(app);let frames = boardFrames(app),c = size / 2
            func place(_ x:Int,_ y:Int) { tap(app,"mode-soldier");normalPoints(app,[(x,y)]);tap(app,"playConfirm");ready(app) }
            normalPoints(app,[(c+1,size-2)]);let before = resources(app)
            XCTAssertEqual(app.staticTexts["skillStepPrompt"].label,"目標已選好，按確認放兵")
            XCTAssertTrue(app.buttons["playConfirm"].isEnabled);shot(app,"quality35-\(size)-preview")
            tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
            XCTAssertTrue(app.buttons["play-cell-\(c+1)-\(size-2)"].label.contains("空點"));fixedBoard(app,frames)
            place(c+1,size-2);place(0,0);tap(app,"playEndTurn");ready(app)
            tap(app,"mode-summon");normalPoints(app,[(c+1,size-3)])
            XCTAssertEqual(app.staticTexts["skillStepPrompt"].label,"目標已選好，按確認召喚英雄")
            tap(app,"playConfirm");ready(app)
            place(c-1,1);place(size-1,size-1);tap(app,"playEndTurn");ready(app)
            let castBefore = resources(app);tap(app,"mode-skill");normalPoints(app,[(c+1,size-2),(c,size-3)])
            XCTAssertTrue(app.buttons["playConfirm"].isEnabled);XCTAssertEqual(resources(app),castBefore)
            XCTAssertEqual(app.staticTexts["skillStepPrompt"].label,"目標已選好，按確認調度己兵")
            shot(app,"quality35-\(size)-mage-preview");tap(app,"playConfirm");ready(app)
            XCTAssertTrue(app.buttons["play-cell-\(c+1)-\(size-2)"].label.contains("空點"))
            XCTAssertTrue(app.buttons["play-cell-\(c)-\(size-3)"].label.contains("士兵"));fixedBoard(app,frames)
            shot(app,"quality35-\(size)-mage-settled")
            place(c,0);place(0,1);tap(app,"playEndTurn");ready(app);place(c+1,1)
            let winningBefore = resources(app)
            normalPoints(app,[(c,2)]);tap(app,"playConfirm")
            let result = app.descendants(matching:.any)["matchResult"].firstMatch
            XCTAssertTrue(result.waitForExistence(timeout:10));XCTAssertTrue(result.label.contains("黑方"))
            XCTAssertEqual(app.staticTexts["playMessage"].label,"白方主將已被提，黑方獲勝。")
            XCTAssertTrue(app.buttons["play-cell-\(c)-1"].label.contains("空點"));fixedBoard(app,frames)
            XCTAssertFalse(app.buttons["mode-skill"].exists);shot(app,"quality35-\(size)-victory")
            tap(app,"undoOrCancel");ready(app)
            XCTAssertFalse(result.exists);XCTAssertEqual(resources(app),winningBefore)
            XCTAssertFalse(app.staticTexts["playMessage"].label.contains("主將已被提"))
            XCTAssertTrue(app.buttons["play-cell-\(c)-1"].label.contains("主將"));fixedBoard(app,frames)
            shot(app,"quality35-\(size)-result-undo")
            app.terminate()
        }
    }
    func testRogueLobbyListsBothSkillsAndNewMatchKeepsLockedAdvancedVisible() {
        let app = integrated();XCTAssertTrue(app.buttons["choose-rogue"].waitForExistence(timeout:15))
        XCTAssertTrue(app.buttons["choose-rogue"].label.contains("換位"))
        XCTAssertTrue(app.buttons["choose-rogue"].label.contains("連鎖換位"))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        tap(app,"choose-rogue")
        XCTAssertTrue(app.staticTexts["lobbyAdvancedSkill"].label.contains("連鎖換位"))
        shot(app,"feedback34-rogue-two-skills-lobby")
        tap(app,"startMatch");ready(app);let frames = boardFrames(app)
        XCTAssertTrue(app.buttons["mode-skill"].label.contains("換位"))
        XCTAssertTrue(app.buttons["mode-advanced"].isHittable)
        XCTAssertTrue(app.buttons["mode-advanced"].label.contains("連鎖換位"))
        tap(app,"mode-advanced")
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("先召喚英雄"))
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled);fixedBoard(app,frames)
        shot(app,"feedback34-rogue-advanced-visible-before-summon")
    }
    func testRogueWhiteStandardDualNewMatchKeepsBothSkillsAfterComputerOpening() {
        let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        app.segmentedControls["botDifficulty"].buttons["標準"].tap()
        tap(app,"matchMonsters");app.buttons["雙怪"].tap()
        tap(app,"電腦 · 黑方 ●")
        XCTAssertTrue(app.segmentedControls["choosingTeam"].buttons["電腦 · 黑方 ●"].isSelected)
        app.swipeUp()
        tap(app,"choose-priest");XCTAssertTrue(app.buttons["choose-priest"].isSelected)
        XCTAssertTrue(app.staticTexts["黑方 · 牧師"].exists)
        tap(app,"你 · 白方 ○")
        XCTAssertTrue(app.segmentedControls["choosingTeam"].buttons["你 · 白方 ○"].isSelected)
        app.swipeUp()
        tap(app,"choose-rogue");XCTAssertTrue(app.buttons["choose-rogue"].isSelected)
        XCTAssertTrue(app.staticTexts["黑方 · 牧師"].exists)
        XCTAssertTrue(app.staticTexts["白方 · 盜賊"].exists)
        XCTAssertTrue(app.staticTexts["lobbyAdvancedSkill"].label.contains("連鎖換位"))
        app.swipeUp();shot(app,"feedback34-rogue-white-standard-lobby-scrolled")
        tap(app,"startMatch")
        let enabled = XCTNSPredicateExpectation(predicate:NSPredicate(format:"enabled == true"),object:app.buttons["mode-soldier"])
        XCTAssertEqual(XCTWaiter.wait(for:[enabled],timeout:25),.completed)
        XCTAssertTrue(app.buttons["play-cell-8-8"].exists)
        XCTAssertTrue(app.staticTexts["● 黑方 牧師"].exists)
        XCTAssertTrue(app.staticTexts["輪到白方盜賊"].exists)
        XCTAssertTrue(app.buttons["mode-skill"].isHittable)
        XCTAssertTrue(app.buttons["mode-skill"].label.contains("換位"))
        XCTAssertTrue(app.buttons["mode-advanced"].isHittable)
        XCTAssertTrue(app.buttons["mode-advanced"].label.contains("連鎖換位"))
        let frames = boardFrames(app);tap(app,"mode-advanced")
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("先召喚英雄"));fixedBoard(app,frames)
        shot(app,"feedback34-rogue-white-standard-dual-after-computer")
    }
    func testWolfHuntMenuRejectsNoAdjacentHeroThenHuntsAndUndoPreservesResources() {
        let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        tap(app,"matchMonsters");app.buttons["暗影狼"].tap();tap(app,"choose-warrior");tap(app,"startMatch");ready(app)
        let frames = boardFrames(app)
        normalPoints(app,[(3,4)]);tap(app,"playConfirm");ready(app)
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        normalPoints(app,[(5,4)]);tap(app,"playConfirm");ready(app)
        let blocked = resources(app)
        tap(app,"huntMenu");tap(app,"hunt-4-4")
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("上下左右一格"))
        XCTAssertEqual(resources(app),blocked);fixedBoard(app,frames)
        shot(app,"feedback34-wolf-needs-adjacent-hero")
        tap(app,"undoOrCancel");normalPoints(app,[(4,6)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        tap(app,"mode-summon");normalPoints(app,[(4,5)]);tap(app,"playConfirm");ready(app)
        let before = resources(app)
        tap(app,"huntMenu");tap(app,"hunt-4-4")
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("影步"))
        XCTAssertEqual(resources(app),before);fixedBoard(app,frames)
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
        tap(app,"undoOrCancel");ready(app)
        XCTAssertEqual(resources(app),before)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("暗影狼"));fixedBoard(app,frames)
    }
    func testDualMonsterHuntMenuAndLootRemainVisibleAtFixedDock() {
        let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        tap(app,"matchMonsters");app.buttons["雙怪"].tap();tap(app,"choose-warrior");tap(app,"startMatch");ready(app)
        let frames = boardFrames(app)
        normalPoints(app,[(2,5)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        normalPoints(app,[(1,4)]);tap(app,"playConfirm");ready(app)
        tap(app,"huntMenu");tap(app,"hunt-2-4");tap(app,"playConfirm");ready(app);tap(app,"playEndTurn");ready(app)
        XCTAssertTrue(app.buttons["loot-stickyBounce"].exists)
        for id in ["huntMenu","showLootAbilities","tacticalHelp"] {
            XCTAssertTrue(app.buttons[id].isHittable,id)
            XCTAssertGreaterThanOrEqual(app.buttons[id].frame.width,44,id)
            XCTAssertGreaterThanOrEqual(app.buttons[id].frame.height,44,id)
        }
        XCTAssertFalse(app.buttons["huntMenu"].frame.intersects(app.buttons["showLootAbilities"].frame))
        XCTAssertFalse(app.buttons["showLootAbilities"].frame.intersects(app.buttons["tacticalHelp"].frame))
        XCTAssertEqual(app.otherElements["gameActionDock"].frame.height,200,accuracy:0.5);fixedBoard(app,frames)
        shot(app,"feedback34-dual-hunt-and-loot-controls")
        let before = resources(app)
        tap(app,"huntMenu");tap(app,"hunt-6-4")
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertEqual(resources(app),before)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("我0：敵0"))
        shot(app,"feedback34-wolf-preview-with-loot")
        tap(app,"undoOrCancel");fixedBoard(app,frames)
    }
    private func resources(_ app: XCUIApplication) -> String {
        let element = app.descendants(matching:.any)["blueResources"].firstMatch
        XCTAssertTrue(element.exists); let value = element.value as? String
        XCTAssertNotNil(value); return value ?? "MISSING"
    }
    private func boardFrames(_ app: XCUIApplication) -> [CGRect] {
        [app.descendants(matching:.any)["playArena"].firstMatch.frame,
         app.buttons["play-cell-0-0"].frame,app.buttons["play-cell-\(app.buttons["play-cell-8-8"].exists ? 8:6)-\(app.buttons["play-cell-8-8"].exists ? 8:6)"].frame]
    }
    func testUpdatedMageHintsStepsMoveQuotaAndResume() {
        let app = integrated("mage");ready(app)
        let frames = boardFrames(app),before = resources(app)
        tap(app,"mode-soldier")
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"本機雙人 · 黑方行動")
        XCTAssertEqual(app.buttons["play-cell-8-8"].value as? String,"可選下一點")
        XCTAssertNotEqual(app.buttons["play-cell-4-7"].value as? String,"可選下一點")
        shot(app,"ux26-soldier-legal-dots")
        tap(app,"mode-skill")
        XCTAssertTrue(app.buttons["mode-skill"].label.contains("調度己兵"))
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("①"))
        XCTAssertEqual(app.buttons["play-cell-4-5"].value as? String,"可選下一點")
        XCTAssertNotEqual(app.buttons["play-cell-4-3"].value as? String,"可選下一點")
        // Enemy source remains clickable for a precise rejection; it never charges or casts.
        normalPoints(app,[(4,3),(3,3)])
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("己方普通士兵"))
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"目標未成立 · 查看下方原因")
        XCTAssertEqual(resources(app),before);fixedBoard(app,frames)
        tap(app,"undoOrCancel")
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("①"))
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"本機雙人 · 黑方行動")
        normalPoints(app,[(4,5)])
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("②"))
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"目標選取中 · 尚未施放")
        XCTAssertEqual(app.buttons["play-cell-5-5"].value as? String,"可選下一點")
        shot(app,"ux26-mage-frontier-hints")
        normalPoints(app,[(5,5)])
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("合法預覽"))
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"合法預覽 · 等待確認")
        XCTAssertEqual(resources(app),before);fixedBoard(app,frames)
        shot(app,"ux26-mage-two-point-preview")
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.buttons["play-cell-5-5"].label.contains("士兵"))
        XCTAssertTrue(app.buttons["play-cell-4-5"].label.contains("空點"))
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("本回合已施法"))
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
        XCTAssertEqual(app.staticTexts["localActionStatus"].label,"本機雙人 · 黑方行動")
        app.terminate();app.expansionShellArguments = [];app.launch();tap(app,"resumeExpansion");ready(app)
        tap(app,"mode-skill");XCTAssertTrue(app.buttons["mode-skill"].label.contains("調度己兵"))
        XCTAssertEqual(app.buttons["play-cell-4-5"].value as? String,"可選下一點")
    }
    func testUpdatedWarriorCanBuildBeyondHeroAdjacent() {
        let app = integrated("warrior");ready(app);tap(app,"mode-skill")
        let before = resources(app),frames = boardFrames(app)
        XCTAssertTrue(app.buttons["mode-skill"].label.contains("沿棋群築壘"))
        normalPoints(app,[(5,5)])
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("②"))
        XCTAssertEqual(app.buttons["play-cell-6-6"].value as? String,"可選下一點")
        normalPoints(app,[(6,6)])
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled);XCTAssertEqual(resources(app),before)
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.buttons["play-cell-6-6"].label.contains("士兵"))
        fixedBoard(app,frames);shot(app,"ux26-warrior-connected-frontier")
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
    }
    func testNewGameExplainsMissingHeroAndShowsSoldierHints() {
        let app = integrated();tap(app,"startMatch");ready(app)
        let frames = boardFrames(app)
        XCTAssertEqual(app.buttons["play-cell-0-0"].value as? String,"可選下一點")
        tap(app,"mode-skill")
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("請先召喚英雄"))
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("請先召喚英雄"))
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        fixedBoard(app,frames);shot(app,"ux26-missing-hero-explained")
    }
    func testSkillCardsExplainRestrictionsBeforeAndAfterCasting() {
        let app = integrated("mage");ready(app)
        let frames = boardFrames(app),before = resources(app)
        XCTAssertEqual(app.buttons["mode-skill"].value as? String,"可選目標，仍須合法預覽")
        XCTAssertTrue((app.buttons["mode-summon"].value as? String ?? "").contains("本局已召喚"))
        tap(app,"mode-summon");XCTAssertEqual(resources(app),before)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("本局已召喚"))
        fixedBoard(app,frames);shot(app,"p27-summon-restricted-card")
        tap(app,"mode-skill");normalPoints(app,[(4,5),(5,5)])
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue((app.buttons["mode-skill"].value as? String ?? "").contains("本回合已施法"))
        XCTAssertTrue((app.buttons["mode-advanced"].value as? String ?? "").contains("本回合已施法"))
        XCTAssertEqual(app.buttons["mode-soldier"].value as? String,"可選目標，仍須合法預覽")
        fixedBoard(app,frames);shot(app,"p27-used-skill-card")
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
        XCTAssertEqual(app.buttons["mode-skill"].value as? String,"可選目標，仍須合法預覽")
    }
    func testPolishAutoplayBackgroundNeverCommitsOnReturn() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--integrated-practice","warrior","--polish-autoplay","--polish-basic"]
        app.launch();XCTAssertTrue(app.buttons["play-cell-6-6"].waitForExistence(timeout:10))
        XCUIDevice.shared.press(.home)
        // Exceeds the authored 3s preparation + .8s preview window.
        let timer = XCTestExpectation(description:"recording input cancelled while backgrounded")
        DispatchQueue.main.asyncAfter(deadline:.now()+4) { timer.fulfill() }
        XCTAssertEqual(XCTWaiter.wait(for:[timer],timeout:6),.completed)
        app.activate();ready(app)
        XCTAssertTrue(app.buttons["play-cell-6-6"].label.contains("空點"))
        let noReplay = XCTestExpectation(description:"foreground must not restart recording action")
        DispatchQueue.main.asyncAfter(deadline:.now()+4) { noReplay.fulfill() }
        XCTAssertEqual(XCTWaiter.wait(for:[noReplay],timeout:6),.completed)
        XCTAssertTrue(app.buttons["play-cell-6-6"].label.contains("空點"))
        XCTAssertTrue(resources(app).contains("4/6"));shot(app,"p28-autoplay-background-cancelled")
        #else
        throw XCTSkip("The recording input is DEBUG-only")
        #endif
    }
    func testConfirmedChainFrameUsesExactPhaseAndUndoDiscardsIt() throws {
        #if DEBUG
        let app = XCUIApplication()
        app.expansionShellArguments = ["--integrated-practice","rogue","--polish-autoplay","--polish-frame","0.275","--integrated-review-audit"]
        app.launch()
        let audit = app.staticTexts["integratedExpansionAudit"]
        XCTAssertTrue(audit.waitForExistence(timeout:10))
        let frozen = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","frozen=true"),object:audit)
        // On a timeout, say which autoplay step stopped (polishReviewStatus) instead of only "timed out".
        XCTAssertEqual(XCTWaiter.wait(for:[frozen],timeout:20),.completed, app.staticTexts["polishReviewStatus"].label)
        XCTAssertTrue(audit.label.contains("players=0|active=false"))
        shot(app,"p28b-chain-first-contact-exact-frame")
        tap(app,"undoOrCancel");ready(app)
        XCTAssertTrue(audit.label.contains("frozen=false"))
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("盜賊"))
        XCTAssertTrue(app.buttons["play-cell-5-3"].label.contains("士兵"))
        XCTAssertTrue(resources(app).contains("4/6"))
        #else
        throw XCTSkip("Exact-frame review is DEBUG-only")
        #endif
    }
    func testMonsterRewardFramesUndoAndReducedMotionUseRealCommit() throws {
        #if DEBUG
        for scene in ["slime-hunt","wolf-hunt"] {
            let app = XCUIApplication()
            app.expansionShellArguments = ["--polish-monster",scene,"--polish-autoplay","--polish-frame","0.50","--integrated-review-audit"]
            app.launch();let audit = app.staticTexts["integratedExpansionAudit"]
            XCTAssertTrue(audit.waitForExistence(timeout:10))
            let frozen = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","frozen=true"),object:audit)
            XCTAssertEqual(XCTWaiter.wait(for:[frozen],timeout:10),.completed)
            XCTAssertTrue(audit.label.contains("players=0|active=false"))
            XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
            XCTAssertTrue(app.staticTexts["tacticalActionTitle"].label.contains("黑方討伐"))
            XCTAssertTrue(app.staticTexts["playMessage"].label.contains(scene == "slime-hunt" ? "取得黏彈":"取得影步"))
            shot(app,"p28d-\(scene)-reward-exact")
            tap(app,"undoOrCancel");ready(app)
            XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains(scene == "slime-hunt" ? "史萊姆":"暗影狼"))
            XCTAssertTrue(audit.label.contains("frozen=false"));app.terminate()
        }
        let app = XCUIApplication()
        app.expansionShellArguments = ["--polish-monster","slime-hunt","--polish-autoplay","--polish-frame","0.50","--polish-reduced","--integrated-review-audit"]
        app.launch();let audit = app.staticTexts["integratedExpansionAudit"]
        XCTAssertTrue(audit.waitForExistence(timeout:10))
        let frozen = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","frozen=true"),object:audit)
        XCTAssertEqual(XCTWaiter.wait(for:[frozen],timeout:10),.completed)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("取得黏彈"))
        XCTAssertTrue(audit.label.contains("reduced=true"));shot(app,"p28d-reduced-reward-no-motion")
        #else
        throw XCTSkip("Recording fixture is DEBUG-only")
        #endif
    }
    private func fixedBoard(_ app: XCUIApplication,_ frames: [CGRect],file:StaticString = #filePath,line:UInt = #line) {
        let current = boardFrames(app)
        for (a,b) in zip(frames,current) {
            XCTAssertEqual(a.minX,b.minX,accuracy:0.5,file:file,line:line)
            XCTAssertEqual(a.minY,b.minY,accuracy:0.5,file:file,line:line)
            XCTAssertEqual(a.width,b.width,accuracy:0.5,file:file,line:line)
            XCTAssertEqual(a.height,b.height,accuracy:0.5,file:file,line:line)
        }
    }
    func testFixedPhoneBoardAcrossFourClassesModesPreviewHelpHandoffAndUndo() {
        for hero in ["warrior","mage","rogue","priest"] {
            let app = integrated(hero);ready(app)
            let frames = boardFrames(app)
            let dock = app.otherElements["gameActionDock"]
            XCTAssertEqual(dock.frame.height, 200, accuracy: 0.5, "The presentation contract reserves a fixed 200pt dock")
            for id in ["mode-soldier", "mode-summon", "mode-skill", "tacticalHelp", "playConfirm", "playEndTurn"] {
                let button = app.buttons[id]
                XCTAssertTrue(button.isHittable, "Visible action: \(id)")
                XCTAssertGreaterThanOrEqual(button.frame.width, 44)
                XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            }
            if hero != "priest" { XCTAssertTrue(app.buttons["mode-advanced"].isHittable) }
            tap(app,"mode-soldier");fixedBoard(app,frames)
            normalPoints(app,[(8,8)]);fixedBoard(app,frames)
            tap(app,"tacticalHelp");tap(app,"tacticalHelpDone");fixedBoard(app,frames)
            tap(app,"undoOrCancel");tap(app,"mode-summon");fixedBoard(app,frames)
            tap(app,"mode-skill");fixedBoard(app,frames)
            if hero == "mage" {
                normalPoints(app,[(4,5)]);fixedBoard(app,frames)
                normalPoints(app,[(5,5)]);fixedBoard(app,frames)
                tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
                tap(app,"undoOrCancel");fixedBoard(app,frames)
            }
            if hero != "priest" { tap(app,"mode-advanced");fixedBoard(app,frames) }
            tap(app,"playEndTurn");ready(app);fixedBoard(app,frames)
            tap(app,"undoOrCancel");fixedBoard(app,frames)
            shot(app,"fixed-warm-"+hero+"-nine");app.terminate()
        }
    }
    func testFixedSevenSoloPriestComputerMageEveryPrepareLandingAndUndo() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--bot-step-review"];app.launch()
        XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout:15))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap();tap(app,"choose-priest");tap(app,"startMatch");ready(app)
        let frames = boardFrames(app)
        normalPoints(app,[(0,0)]);fixedBoard(app,frames);tap(app,"playConfirm")
        XCTAssertTrue(app.buttons["botReviewAdvance"].waitForExistence(timeout:25));fixedBoard(app,frames)
        let value = app.staticTexts["playMessage"].value as? String ?? ""
        let count = Int(value.split(separator:"/").last?.split(separator:" ").first ?? "") ?? 0
        XCTAssertGreaterThan(count,0)
        for index in 1...max(1,count) {
            let prep = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","\(index)/\(count) 準備"),object:app.staticTexts["playMessage"])
            XCTAssertEqual(XCTWaiter.wait(for:[prep],timeout:20),.completed);fixedBoard(app,frames)
            tap(app,"botReviewAdvance")
            let hit = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","\(index)/\(count) 落定"),object:app.staticTexts["playMessage"])
            XCTAssertEqual(XCTWaiter.wait(for:[hit],timeout:20),.completed);fixedBoard(app,frames)
            tap(app,"botReviewAdvance")
        }
        botDone(app,1);fixedBoard(app,frames);shot(app,"fixed-warm-seven-priest-solo")
        tap(app,"undoOrCancel");fixedBoard(app,frames)
        #else
        throw XCTSkip("Manual phase stepping is DEBUG-only")
        #endif
    }
    func testFixedBoardTerminalBannerAfterComputerCapture() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--solo-warrior-review","--bot-step-review"];app.launch()
        XCTAssertTrue(app.buttons["botReviewAdvance"].waitForExistence(timeout:25));let frames = boardFrames(app)
        tap(app,"botReviewAdvance")
        let hit = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","1/1 落定"),object:app.staticTexts["playMessage"])
        XCTAssertEqual(XCTWaiter.wait(for:[hit],timeout:20),.completed);fixedBoard(app,frames)
        tap(app,"botReviewAdvance");XCTAssertTrue(app.descendants(matching:.any)["matchResult"].firstMatch.waitForExistence(timeout:10));fixedBoard(app,frames)
        XCTAssertFalse(app.buttons["mode-soldier"].exists)
        XCTAssertFalse(app.buttons["playConfirm"].exists)
        XCTAssertFalse(app.buttons["playEndTurn"].exists)
        XCTAssertTrue(app.buttons["resultReplay"].isHittable)
        XCTAssertEqual(app.otherElements["gameActionDock"].frame.height, 200, accuracy: 0.5)
        shot(app,"fixed-board-terminal-warm")
        XCTAssertFalse(app.buttons["undoOrCancel"].isEnabled, "This fixture has no earlier human decision to undo")
        tap(app,"resultReplay");ready(app);fixedBoard(app,frames)
        XCTAssertFalse(app.buttons["resultReplay"].exists)
        #else
        throw XCTSkip("Engineering capture fixture is DEBUG-only")
        #endif
    }
    private func botDone(_ app: XCUIApplication,_ turns: Int) {
        let status = app.descendants(matching:.any)["botStatus"].firstMatch
        XCTAssertTrue(status.waitForExistence(timeout:8))
        let wait = XCTNSPredicateExpectation(predicate:NSPredicate(format:"value == %@","已完成\(turns)電腦回合"),object:status)
        XCTAssertEqual(XCTWaiter.wait(for:[wait],timeout:40),.completed)
        ready(app)
    }
    func testComputerReformationUsesConfirmedWeightedBodyAndEnglishBReceipt() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--solo-warrior-review","--integrated-review-audit","--bot-step-review"]
        app.launch();XCTAssertTrue(app.buttons["botReviewAdvance"].waitForExistence(timeout:20))
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        app.buttons["play-cell-8-8"].tap();XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        app.buttons["botReviewAdvance"].tap()
        let audit = app.staticTexts["integratedExpansionAudit"]
        let voice = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","w7-voice-B"),object:audit)
        XCTAssertEqual(XCTWaiter.wait(for:[voice],timeout:10),.completed)
        XCTAssertTrue(audit.label.contains("defeat"), "A computer win must choose the human defeat ending")
        XCTAssertFalse(app.descendants(matching:.any)["matchResult"].exists,"Result waits until computer landing completes")
        XCTAssertFalse(app.buttons["play-cell-4-1"].label.contains("白方 主將"))
        shot(app,"computer-reformation-weight-confirmed-english-B")
        XCUIDevice.shared.press(.home);app.activate()
        XCTAssertTrue(audit.label.contains("players=0|active=false"))
        XCTAssertTrue(app.descendants(matching:.any)["matchResult"].exists)
        #else
        throw XCTSkip("Engineering receipt fixture only in DEBUG; Beta uses real lobby tests")
        #endif
    }
    func testExpandedThinkingUndoRejectsNonCooperativeLateDecision() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--play-bot","--bot-late-result"]
        app.launch();XCTAssertTrue(app.staticTexts["currentTurn"].waitForExistence(timeout:15));ready(app)
        normalPoints(app,[(0,0)]);tap(app,"playConfirm")
        XCTAssertFalse(app.buttons["mode-soldier"].isEnabled)
        tap(app,"undoOrCancel")
        let rejected = XCTNSPredicateExpectation(predicate:NSPredicate(format:"label == %@","完成0／作廢1"),object:app.staticTexts["botDebugStatus"])
        XCTAssertEqual(XCTWaiter.wait(for:[rejected],timeout:45),.completed)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士")
        XCTAssertTrue(app.buttons["play-cell-0-0"].label.contains("空點"))
        XCTAssertTrue(resources(app).contains("1 AP"))
        shot(app,"expanded-late-decision-rejected-after-undo")
        #else
        throw XCTSkip("Noncooperative test worker only in DEBUG")
        #endif
    }
    // Undo across a computer reply after a skill that captured: each undo must land on one consistent moment
    // (board, side to move, AP, mana and the once-per-turn skill gate together), and the computer must not move again.
    func testUndoAfterSkillCaptureCrossesComputerReplyAndRestoresManaAndSkillGate() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--undo-fixture","capture"];app.launch()
        XCTAssertTrue(app.staticTexts["currentTurn"].waitForExistence(timeout:15));ready(app)
        func cell(_ x:Int,_ y:Int) -> String { app.buttons["play-cell-\(x)-\(y)"].label }
        XCTAssertTrue(cell(6,4).contains("白方士兵"))
        let start = resources(app)
        XCTAssertTrue(start.contains("能量 6/6") && start.contains("2 AP"), start)
        tap(app,"mode-skill");normalPoints(app,[(6,3),(6,5)])
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("合法預覽"))
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(cell(6,4).contains("空點"),"Bastion captured White G5")
        XCTAssertTrue(cell(6,3).contains("黑方士兵") && cell(6,5).contains("黑方士兵"))
        let afterSkill = resources(app)
        XCTAssertTrue(afterSkill.contains("能量 4/6") && afterSkill.contains("1 AP"), afterSkill)
        XCTAssertTrue((app.buttons["mode-skill"].value as? String ?? "").contains("本回合已施法"))
        tap(app,"playEndTurn");botDone(app,1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士")
        // Undo 1: the computer's whole reply and Black's end turn go; the capture, spent mana and closed gate stay.
        tap(app,"undoOrCancel");ready(app)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士")
        XCTAssertTrue(cell(6,4).contains("空點"))
        let beforeEnd = resources(app)
        XCTAssertTrue(beforeEnd.contains("能量 4/6") && beforeEnd.contains("1 AP"), beforeEnd)
        XCTAssertTrue((app.buttons["mode-skill"].value as? String ?? "").contains("本回合已施法"))
        // Undo 2: the Bastion goes; the captured stone, mana, AP and the skill gate come back together.
        tap(app,"undoOrCancel");ready(app)
        XCTAssertTrue(cell(6,4).contains("白方士兵"),"captured stone restored")
        XCTAssertTrue(cell(6,3).contains("空點") && cell(6,5).contains("空點"))
        XCTAssertEqual(resources(app),start)
        XCTAssertFalse((app.buttons["mode-skill"].value as? String ?? "").contains("本回合已施法"))
        // Nothing late: the computer does not move again on its own after the undo.
        Thread.sleep(forTimeInterval:3)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士")
        XCTAssertEqual(resources(app),start)
        #else
        throw XCTSkip("Undo fixtures are DEBUG-only")
        #endif
    }
    // Undo from the result screen after a winning skill: the game is live again at the moment before the skill.
    func testUndoAfterWinningSkillRestoresTheLiveGame() throws {
        #if DEBUG
        let app = XCUIApplication();app.expansionShellArguments = ["--undo-fixture","win"];app.launch()
        XCTAssertTrue(app.staticTexts["currentTurn"].waitForExistence(timeout:15));ready(app)
        func cell(_ x:Int,_ y:Int) -> String { app.buttons["play-cell-\(x)-\(y)"].label }
        let start = resources(app)
        XCTAssertTrue(start.contains("能量 6/6") && start.contains("1 AP"), start)
        XCTAssertTrue(cell(4,1).contains("白方主將"))
        tap(app,"mode-advanced");normalPoints(app,[(4,3),(4,2),(5,3),(5,2)])
        tap(app,"playConfirm")
        XCTAssertTrue(app.descendants(matching:.any)["matchResult"].firstMatch.waitForExistence(timeout:15),"Reformation captures the commander")
        XCTAssertFalse(cell(4,1).contains("主將"))
        let undo = app.buttons["undoOrCancel"]
        XCTAssertTrue(undo.isEnabled,"the winning skill is a human decision that can be undone")
        undo.tap();ready(app)
        XCTAssertFalse(app.descendants(matching:.any)["matchResult"].firstMatch.exists)
        XCTAssertTrue(cell(4,1).contains("白方主將"))
        XCTAssertTrue(cell(4,3).contains("黑方士兵") && cell(5,3).contains("黑方士兵"))
        XCTAssertTrue(cell(4,2).contains("空點") && cell(5,2).contains("空點"))
        XCTAssertEqual(resources(app),start)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士")
        XCTAssertFalse((app.buttons["mode-advanced"].value as? String ?? "").contains("本回合已施法"))
        Thread.sleep(forTimeInterval:3)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方戰士","the computer does not move after the undo")
        XCTAssertTrue(cell(4,1).contains("白方主將"))
        #else
        throw XCTSkip("Undo fixtures are DEBUG-only")
        #endif
    }
    func testSoloDefaultsFourClassesNewBoardAndUndoCrossesComputerReply() {
        let app = integrated();XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout:15))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        XCTAssertFalse(app.segmentedControls["matchRules"].exists);XCTAssertFalse(app.switches["expansionRules"].exists)
        XCTAssertTrue(app.buttons["choose-priest"].exists)
        tap(app,"choose-mage");tap(app,"startMatch");ready(app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","play-cell-")).count,49)
        XCTAssertTrue(app.buttons["mode-advanced"].exists)
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");botDone(app,1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方法師")
        XCTAssertFalse(app.staticTexts["candidateRulesBanner"].exists)
        shot(app,"solo-new-art-human-black-after-computer")
        tap(app,"undoOrCancel")
        XCTAssertTrue(app.buttons["play-cell-0-0"].label.contains("空點"))
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方法師")
        XCTAssertTrue(resources(app).contains("1 AP"))
    }
    func testSoloHumanWhitePriestStandardResumeKeepsComputerControl() {
        let app = integrated();XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout:15))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        app.segmentedControls["humanSide"].buttons["白方後手"].tap()
        app.segmentedControls["botDifficulty"].buttons["標準"].tap()
        tap(app,"choose-priest");tap(app,"startMatch");botDone(app,1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到白方牧師")
        // PRIEST-S2-P0: the priest now has a second skill (聖所); before summoning it is shown but restricted.
        XCTAssertTrue(app.buttons["mode-advanced"].exists)
        XCTAssertFalse(app.buttons["undoOrCancel"].isEnabled)
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");ready(app)
        tap(app,"playEndTurn");botDone(app,2)
        shot(app,"solo-priest-human-white-new-board")
        app.terminate();app.launch();tap(app,"resumeExpansion");ready(app)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到白方牧師")
        XCTAssertTrue(app.descendants(matching:.any)["botStatus"].firstMatch.label.contains("白方"))
        tap(app,"undoOrCancel")
        XCTAssertTrue(app.buttons["play-cell-0-0"].label.contains("士兵"))
        tap(app,"playEndTurn");botDone(app,1)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到白方牧師")
    }
    func testSoloMonsterNineUsesNewBoardAndKeepsRulesOnResume() {
        let app = integrated();XCTAssertTrue(app.segmentedControls["matchMode"].waitForExistence(timeout:15))
        app.segmentedControls["matchMode"].buttons["電腦對戰"].tap()
        tap(app,"matchMonsters");app.buttons["雙怪"].tap();tap(app,"startMatch");ready(app)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","play-cell-")).count,81)
        XCTAssertTrue(app.buttons["play-cell-2-4"].label.contains("史萊姆"))
        XCTAssertTrue(app.buttons["play-cell-6-4"].label.contains("暗影狼"))
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");botDone(app,1)
        XCTAssertTrue(app.buttons["mode-advanced"].exists)
        shot(app,"solo-dual-monsters-new-nine-board")
        app.terminate();app.launch();tap(app,"resumeExpansion");ready(app)
        XCTAssertTrue(app.buttons["play-cell-2-4"].label.contains("史萊姆"))
        XCTAssertTrue(app.descendants(matching:.any)["botStatus"].exists)
    }
    func testUnifiedLobbyPriestSummonOfferingPreviewCancelAndUndoInSameMatch() {
        let app = integrated()
        XCTAssertTrue(app.buttons["choose-priest"].waitForExistence(timeout:15))
        tap(app,"choose-priest"); tap(app,"startMatch"); ready(app)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方牧師")
        XCTAssertFalse(app.staticTexts["exp-status"].exists)
        normalPoints(app,[(2,5)])
        tap(app,"playConfirm"); ready(app)
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到白方法師")
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        tap(app,"mode-summon");normalPoints(app,[(3,4)])
        tap(app,"playConfirm"); ready(app)
        let before = resources(app);XCTAssertTrue(before.contains("能量 2/6"));XCTAssertTrue(before.contains("1 AP"))
        tap(app,"mode-skill");normalPoints(app,[(2,5)])
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("合法預覽"))
        XCTAssertEqual(resources(app),before)
        tap(app,"undoOrCancel");XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        normalPoints(app,[(2,5)]);tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.buttons["play-cell-2-5"].label.contains("空點"))
        XCTAssertTrue(app.buttons["play-cell-3-4"].label.contains("牧師"))
        shot(app,"unified-priest-offering-no-relocation")
        tap(app,"undoOrCancel")
        XCTAssertTrue(app.buttons["play-cell-2-5"].label.contains("士兵"))
        XCTAssertEqual(app.staticTexts["currentTurn"].label,"輪到黑方牧師")
    }
    func testThreeAdvancedSkillsUseOriginalMatchControlsAndUndo() {
        for (hero,targets,source,destination) in [
            ("mage",[(4,5),(5,5),(4,3),(3,3)],(4,5),(5,5)),
            ("warrior",[(4,6),(5,5),(5,6),(6,6)],(4,6),(6,6)),
            ("rogue",[(5,4),(5,3)],(4,4),(5,3))
        ] {
            let app = integrated(hero)
            XCTAssertTrue(app.staticTexts["currentTurn"].waitForExistence(timeout:15));ready(app)
            XCTAssertFalse(app.staticTexts["exp-status"].exists)
            let before = resources(app);XCTAssertTrue(before.contains("2 AP"))
            tap(app,"mode-advanced");normalPoints(app,targets)
            let title = hero == "mage" ? "法師 · 雙重牽引":hero == "warrior" ? "戰士 · 戰線重整":"盜賊 · 連鎖換位"
            XCTAssertTrue(app.buttons["mode-advanced"].isSelected)
            XCTAssertTrue(app.buttons["mode-advanced"].label.contains(title.components(separatedBy: " · ").last!))
            XCTAssertTrue(app.staticTexts["playMessage"].label.contains("合法預覽"),hero)
            XCTAssertEqual(resources(app),before)
            tap(app,"playConfirm");ready(app)
            XCTAssertTrue(app.buttons["play-cell-\(destination.0)-\(destination.1)"].label.contains(hero == "rogue" ? "盜賊":"士兵"))
            if hero != "rogue" { XCTAssertTrue(app.buttons["play-cell-\(source.0)-\(source.1)"].label.contains("空點")) }
            shot(app,"unified-"+hero+"-advanced")
            tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
            app.terminate()
        }
    }
    func testIntegratedCastingMuteReducedMotionAndBackgroundCancelPlayers() {
        let app = XCUIApplication();app.expansionShellArguments = ["--integrated-practice","mage","--integrated-review-audit"];app.launch()
        XCTAssertTrue(app.staticTexts["currentTurn"].waitForExistence(timeout:15));ready(app)
        app.buttons["對戰選單"].tap();tap(app,"audioSettings")
        if app.switches["audioMute"].value as? String == "1" {
            app.switches["audioMute"].coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap()
        }
        XCTAssertEqual(app.switches["audioMute"].value as? String,"0");tap(app,"audioSettingsDone")
        tap(app,"mode-advanced");normalPoints(app,[(4,5),(5,5),(4,3),(3,3)])
        XCTAssertTrue(app.staticTexts["integratedExpansionAudit"].label.contains("cues=0|players=0|active=false"))
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.staticTexts["integratedExpansionAudit"].label.contains("mage-cast-B"))
        XCUIDevice.shared.press(.home);app.activate();ready(app)
        XCTAssertTrue(app.staticTexts["integratedExpansionAudit"].label.contains("players=0|active=false"))
        tap(app,"undoOrCancel")
        app.buttons["對戰選單"].tap();tap(app,"audioSettings")
        XCTAssertEqual(app.switches["castVoice"].value as? String,"1")
        app.switches["audioMute"].coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap()
        XCTAssertEqual(app.switches["audioMute"].value as? String,"1")
        app.switches["reduceCombatMotion"].coordinate(withNormalizedOffset:CGVector(dx:0.9,dy:0.5)).tap()
        XCTAssertEqual(app.switches["reduceCombatMotion"].value as? String,"1")
        shot(app,"unified-muted-reduced-settings");tap(app,"audioSettingsDone")
        XCTAssertTrue(app.staticTexts["integratedExpansionAudit"].label.contains("muted=true"))
        let before = app.staticTexts["integratedExpansionAudit"].label.components(separatedBy:"|")[0]
        tap(app,"mode-advanced");normalPoints(app,[(4,5),(5,5),(4,3),(3,3)]);tap(app,"playConfirm");ready(app)
        XCTAssertEqual(app.staticTexts["integratedExpansionAudit"].label.components(separatedBy:"|")[0],before)
        XCTAssertTrue(app.buttons["play-cell-5-5"].label.contains("士兵"))
        tap(app,"undoOrCancel");XCTAssertTrue(app.buttons["play-cell-4-5"].label.contains("士兵"))
    }
    func testMonsterHuntAndLootUseSameNineBoardAndResume() {
        let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        let picker = app.buttons["matchMonsters"]
        for _ in 0..<4 { if picker.isHittable { break };app.swipeDown() }
        XCTAssertTrue(picker.exists);picker.tap(); app.buttons["史萊姆"].tap()
        tap(app,"startMatch");ready(app);let frames = boardFrames(app)
        normalPoints(app,[(4,5)]);tap(app,"playConfirm");ready(app);fixedBoard(app,frames);tap(app,"playEndTurn")
        normalPoints(app,[(3,4)]);tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
        normalPoints(app,[(4,4)]);XCTAssertTrue(app.staticTexts["playMessage"].label.contains("合法預覽"))
        tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
        tap(app,"playEndTurn");normalPoints(app,[(4,4)]);tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
        tap(app,"showLootAbilities");fixedBoard(app,frames)
        tap(app,"loot-stickyBounce");fixedBoard(app,frames);normalPoints(app,[(3,4),(4,4)])
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled);tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
        XCTAssertTrue(app.buttons["play-cell-5-4"].label.contains("士兵"));XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
        shot(app,"unified-monster-loot-used")
        app.terminate();app.launch()
        tap(app,"resumeExpansion");ready(app);fixedBoard(app,frames)
        XCTAssertTrue(app.buttons["play-cell-5-4"].label.contains("士兵"))
        tap(app,"undoOrCancel");XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("士兵"))
    }
    func testHuntOverridesUsedHeroSkillPromptAndCancelRestoresIt() {
        let app = integrated();XCTAssertTrue(app.buttons["startMatch"].waitForExistence(timeout:15))
        let picker = app.buttons["matchMonsters"]
        for _ in 0..<4 { if picker.isHittable { break };app.swipeDown() }
        picker.tap();app.buttons["史萊姆"].tap()
        tap(app,"choose-warrior");tap(app,"startMatch");ready(app)
        let frames = boardFrames(app)
        normalPoints(app,[(4,6)]);tap(app,"playConfirm");ready(app)
        normalPoints(app,[(0,0)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        tap(app,"mode-summon");normalPoints(app,[(4,5)]);tap(app,"playConfirm");ready(app)
        tap(app,"mode-soldier");normalPoints(app,[(3,5)]);tap(app,"playConfirm");ready(app);tap(app,"playEndTurn")
        tap(app,"mode-skill");normalPoints(app,[(3,4),(5,5)]);tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("本回合已施法"))
        let before = resources(app)
        XCTAssertTrue(app.buttons["huntMenu"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["huntMenu"].frame.width,44)
        tap(app,"huntMenu");tap(app,"hunt-4-4")
        shot(app,"p28c-hunt-after-bastion")
        // The selected action is a hunt, although the skill rail remains correctly locked.
        XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        XCTAssertTrue(app.staticTexts["tacticalActionTitle"].label.contains("討伐"))
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("黏彈"))
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("1 AP／0 能量"))
        XCTAssertTrue(app.staticTexts["playMessage"].label.contains("我2：敵0"))
        XCTAssertTrue(app.buttons["mode-skill"].value as? String == "本回合已施法，下一回合才能再用")
        XCTAssertEqual(resources(app),before);fixedBoard(app,frames)
        tap(app,"tacticalHelp")
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format:"label CONTAINS %@","不占施法次數")).firstMatch.exists)
        shot(app,"p28c-hunt-explained");tap(app,"tacticalHelpDone")
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
        XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("本回合已施法"))
        XCTAssertFalse(app.buttons["playConfirm"].isEnabled)
        normalPoints(app,[(4,4)]);tap(app,"playConfirm");ready(app);fixedBoard(app,frames)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("空點"))
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before);fixedBoard(app,frames)
        XCTAssertTrue(app.buttons["play-cell-4-4"].label.contains("史萊姆"))
        tap(app,"mode-skill");XCTAssertTrue(app.staticTexts["skillStepPrompt"].label.contains("本回合已施法"))
    }
    func testPhoneNineLargerCellsAllCornersHelpAndUndo() {
        let app = integrated("mage");ready(app);tap(app,"mode-soldier")
        let cells = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","play-cell-"))
        XCTAssertEqual(cells.count,81)
        let screen = app.windows.firstMatch.frame
        let minimum: CGFloat = screen.width < 390 ? 27:34
        let cell = app.buttons["play-cell-4-4"].frame
        print("PHONE_GRID_METRIC width=\(screen.width) cell=\(cell.width) height=\(cell.height)")
        XCTAssertGreaterThanOrEqual(cell.width,minimum)
        XCTAssertGreaterThanOrEqual(cell.height,minimum)
        let before = resources(app)
        for point in [(0,0),(8,0),(0,8),(8,8)] {
            let b = app.buttons["play-cell-\(point.0)-\(point.1)"]
            XCTAssertTrue(b.isHittable)
            XCTAssertGreaterThanOrEqual(b.frame.minX,screen.minX)
            XCTAssertLessThanOrEqual(b.frame.maxX,screen.maxX)
            XCTAssertGreaterThanOrEqual(b.frame.minY,screen.minY)
            XCTAssertLessThanOrEqual(b.frame.maxY,screen.maxY)
            b.tap();XCTAssertEqual(resources(app),before);tap(app,"undoOrCancel")
        }
        normalPoints(app,[(8,8)])
        let message = app.staticTexts["playMessage"].label
        let confirm = app.buttons["playConfirm"]
        XCTAssertTrue(confirm.isHittable);XCTAssertTrue(confirm.isEnabled)
        XCTAssertTrue(app.buttons["playEndTurn"].isHittable)
        tap(app,"tacticalHelp");tap(app,"tacticalHelpDone")
        XCTAssertEqual(app.staticTexts["playMessage"].label,message)
        XCTAssertEqual(resources(app),before);XCTAssertTrue(confirm.isEnabled)
        shot(app,"phone-nine-large-preview")
        tap(app,"playConfirm");ready(app)
        XCTAssertTrue(app.buttons["play-cell-8-8"].label.contains("士兵"))
        tap(app,"undoOrCancel")
        XCTAssertTrue(app.buttons["play-cell-8-8"].label.contains("空點"));XCTAssertEqual(resources(app),before)
        tap(app,"mode-skill");normalPoints(app,[(4,5)])
        normalPoints(app,[(5,5)]);XCTAssertTrue(app.buttons["playConfirm"].isEnabled)
        tap(app,"playConfirm")
        XCTAssertTrue(app.buttons["play-cell-5-5"].label.contains("士兵"))
        XCTAssertTrue(app.buttons["play-cell-4-5"].label.contains("空點"))
        tap(app,"undoOrCancel");XCTAssertEqual(resources(app),before)
        XCTAssertTrue(app.buttons["play-cell-4-5"].label.contains("士兵"))
    }
    private func launch(_ args: [String] = ["--expansion-lab"]) -> XCUIApplication {
        let app = XCUIApplication(); app.expansionShellArguments = args; app.launch()
        XCTAssertTrue(app.staticTexts["exp-status"].waitForExistence(timeout:15)); return app
    }
    private func tap(_ app: XCUIApplication,_ id: String) {
        let b = app.buttons[id]
        for _ in 0..<8 {
            if b.isHittable { break }
            if b.frame.minY < app.windows.firstMatch.frame.minY+30 { app.swipeDown() } else { app.swipeUp() }
        }
        XCTAssertTrue(b.isHittable,id); if b.isHittable { b.tap() }
        if id.hasPrefix("mode-") { XCTAssertTrue(b.isSelected, "The tapped card must select its own mode: \(id)") }
    }
    private func toggle(_ app: XCUIApplication,_ id: String) {
        let s = app.switches[id]
        for _ in 0..<6 { if s.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(s.isHittable); if s.isHittable { s.tap() }
    }
    private func settled(_ app: XCUIApplication) {
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","active=false"),object:app.staticTexts["exp-audit"])],timeout:5),.completed)
    }
    private func shot(_ app: XCUIApplication,_ name: String) { let a = XCTAttachment(screenshot:app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a) }
    private func points(_ app: XCUIApplication,_ list: [(Int,Int)]) { for (x,y) in list { tap(app,"exp-cell-\(x)-\(y)") } }
    func testFourSkillsPreviewSameBoardConfirmActualOutcomeAndUndo() {
        let app = launch()
        for (hero,targets,empty,occupied) in [
            ("mage",[(4,5),(5,5),(4,3),(3,3)],(4,5),(5,5)),
            ("warrior",[(4,6),(5,5),(5,6),(6,6)],(4,6),(6,6)),
            ("rogue",[(5,4),(5,3)],(0,0),(5,3)),
            ("priest",[(4,5)],(4,5),(4,6))
        ] {
            tap(app,"exp-practice-"+hero)
            let before = app.staticTexts["exp-status"].label
            let beforeCell = app.buttons["exp-cell-\(occupied.0)-\(occupied.1)"].label
            points(app,targets)
            XCTAssertTrue(app.staticTexts["exp-preview"].label.contains("合法預覽"),hero)
            XCTAssertEqual(app.staticTexts["exp-status"].label,before)
            XCTAssertEqual(app.buttons["exp-cell-\(occupied.0)-\(occupied.1)"].label,beforeCell)
            shot(app,"exp-\(hero)-preview-source-retained")
            tap(app,"exp-confirm"); settled(app)
            XCTAssertTrue(app.staticTexts["exp-status"].label.contains("1 AP"),hero)
            XCTAssertTrue(app.buttons["exp-cell-\(occupied.0)-\(occupied.1)"].label.contains(hero == "priest" ? "空點" : hero == "rogue" ? "盜賊" : "士兵"))
            if hero != "rogue" { XCTAssertTrue(app.buttons["exp-cell-\(empty.0)-\(empty.1)"].label.contains("空點")) }
            shot(app,"exp-\(hero)-confirmed")
            tap(app,"exp-undo")
            XCTAssertEqual(app.staticTexts["exp-status"].label,before)
            XCTAssertEqual(app.buttons["exp-cell-\(occupied.0)-\(occupied.1)"].label,beforeCell)
            XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("players=0"))
        }
    }
    func testIllegalPreviewSilentCancellationMuteReducedAndBackground() {
        let app = launch(); tap(app,"exp-practice-mage")
        let before = app.staticTexts["exp-status"].label
        let audit = app.staticTexts["exp-audit"].label
        points(app,[(4,5),(4,4),(4,3),(3,3)])
        XCTAssertFalse(app.buttons["exp-confirm"].isEnabled)
        XCTAssertEqual(app.staticTexts["exp-status"].label,before)
        XCTAssertEqual(app.staticTexts["exp-audit"].label,audit)
        tap(app,"exp-cancel"); XCTAssertFalse(app.buttons["exp-confirm"].isEnabled)
        toggle(app,"exp-mute"); toggle(app,"exp-reduced")
        points(app,[(4,5),(5,5),(4,3),(3,3)]); tap(app,"exp-confirm"); settled(app)
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("cues=0|players=0|active=false"))
        shot(app,"exp-reduced-muted")
        XCUIDevice.shared.press(.home); app.activate()
        tap(app,"exp-undo"); XCTAssertEqual(app.staticTexts["exp-status"].label,before)
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("players=0|active=false"))
    }
    func testPriestChallengeHintAutoSaveResumeAndUndoRestoresOneEye() {
        let app = launch();tap(app,"exp-challenge")
        XCTAssertTrue(app.staticTexts["exp-instruction"].label.contains("只剩一口氣"))
        XCTAssertFalse(app.staticTexts["exp-hint-text"].exists)
        let before = app.staticTexts["exp-status"].label
        tap(app,"exp-hint");XCTAssertTrue(app.staticTexts["exp-hint-text"].label.contains("E4"))
        points(app,[(4,3)]);tap(app,"exp-confirm");settled(app)
        XCTAssertTrue(app.staticTexts["exp-message"].label.contains("挑戰完成"))
        XCTAssertTrue(app.buttons["exp-cell-4-3"].label.contains("空點"))
        XCTAssertTrue(app.buttons["exp-cell-4-6"].label.contains("空點"));shot(app,"priest-two-real-eyes-rescue")
        let after = app.staticTexts["exp-status"].label
        tap(app,"exp-restart");tap(app,"exp-resume")
        XCTAssertEqual(app.staticTexts["exp-status"].label,after)
        XCTAssertTrue(app.staticTexts["exp-message"].label.contains("重播並載入"))
        XCTAssertTrue(app.buttons["exp-cell-4-3"].label.contains("空點"))
        tap(app,"exp-undo");XCTAssertEqual(app.staticTexts["exp-status"].label,before)
        XCTAssertTrue(app.buttons["exp-cell-4-3"].label.contains("士兵"))
    }
    func testMageCounterUsesLastAPChangesEyeAndUndoRestoresReceipt() {
        let app = launch();tap(app,"exp-counter")
        let before = app.staticTexts["exp-status"].label
        XCTAssertTrue(before.contains("白方法師"));XCTAssertTrue(before.contains("1 AP"))
        points(app,[(5,3)]);tap(app,"exp-push-Left")
        XCTAssertTrue(app.staticTexts["exp-preview"].label.contains("合法預覽"))
        tap(app,"exp-confirm");settled(app)
        XCTAssertTrue(app.staticTexts["exp-status"].label.contains("黑方牧師"))
        XCTAssertTrue(app.buttons["exp-cell-5-3"].label.contains("空點"))
        XCTAssertTrue(app.buttons["exp-cell-4-3"].label.contains("士兵"));shot(app,"priest-rescue-mage-counter")
        tap(app,"exp-undo");XCTAssertEqual(app.staticTexts["exp-status"].label,before)
        XCTAssertTrue(app.buttons["exp-cell-5-3"].label.contains("士兵"))
    }
    func testSavedMatchResumesFromFrozenReviewAndRemainsPlayableAndSaveable() {
        let app = launch();tap(app,"exp-practice-priest")
        points(app,[(4,5)]);tap(app,"exp-confirm");settled(app)
        let saved = app.staticTexts["exp-status"].label
        app.terminate()
        app.expansionShellArguments = ["--expansion-lab","--exp-review","Rogue","--exp-review-time","0.12"]
        app.launch();XCTAssertTrue(app.staticTexts["exp-status"].waitForExistence(timeout:15))
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("frozen=true"))
        tap(app,"exp-resume");XCTAssertEqual(app.staticTexts["exp-status"].label,saved)
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("frozen=false"))
        XCTAssertTrue(app.buttons["exp-cell-0-1"].label.contains("空點"))
        points(app,[(0,1)]);XCTAssertTrue(app.staticTexts["exp-preview"].label.contains("合法預覽"))
        tap(app,"exp-confirm");settled(app)
        XCTAssertTrue(app.buttons["exp-cell-0-1"].label.contains("士兵"))
        let next = app.staticTexts["exp-status"].label
        tap(app,"exp-restart");tap(app,"exp-resume")
        XCTAssertEqual(app.staticTexts["exp-status"].label,next)
        XCTAssertTrue(app.buttons["exp-cell-0-1"].label.contains("士兵"))
        tap(app,"exp-undo");XCTAssertEqual(app.staticTexts["exp-status"].label,saved)
    }
    func testFrozenConfirmedReviewRetainsPhaseAcrossBackgroundWithoutAudio() {
        let app = launch(["--expansion-lab","--exp-review","Priest","--exp-review-time","0.20","--exp-review-body-only"])
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("frozen=true"))
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("cues=0|players=0|active=false"))
        let before = app.staticTexts["exp-status"].label
        shot(app,"priest-frozen-coil-before-background")
        XCUIDevice.shared.press(.home);app.activate()
        XCTAssertEqual(app.staticTexts["exp-status"].label,before)
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("frozen=true"))
        shot(app,"priest-frozen-coil-after-background")
        tap(app,"exp-practice-priest")
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("frozen=false"))
    }
    func testRoguePriestEnglishCandidatesAndVoiceOffStillPlayFoley() {
        let app = launch()
        for (hero,coords) in [("rogue",[(5,4),(5,3)]),("priest",[(4,5)])] {
            tap(app,"exp-practice-"+hero);let before = app.staticTexts["exp-status"].label
            points(app,coords);tap(app,"exp-confirm");settled(app)
            XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("p8-voice-"+hero+"-B"))
            tap(app,"exp-undo");XCTAssertEqual(app.staticTexts["exp-status"].label,before)
            XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("players=0|active=false"))
        }
        toggle(app,"exp-voice");points(app,[(4,5)]);tap(app,"exp-confirm");settled(app)
        XCTAssertFalse(app.staticTexts["exp-audit"].label.contains("p8-voice"))
        XCTAssertTrue(app.staticTexts["exp-audit"].label.contains("p8-priest-bless"))
        tap(app,"exp-undo")
    }
    func testHomeHasPlayableAndBothExistingLabsWithoutChangingOriginalEntry() {
        let app = XCUIApplication(); app.expansionShellArguments = ["--v11-home"]; app.launch()
        XCTAssertTrue(app.buttons["v11-play"].waitForExistence(timeout:15)); shot(app,"v11-unified-home")
        app.buttons["v11-play"].tap(); XCTAssertTrue(app.staticTexts["exp-status"].waitForExistence(timeout:5))
        tap(app,"exp-practice-priest"); shot(app,"v11-priest-board")
        app.navigationBars.buttons.element(boundBy:0).tap()
        tap(app,"v11-monsters"); XCTAssertTrue(app.staticTexts["mobTitle"].waitForExistence(timeout:5))
        XCTAssertEqual(app.buttons["mobCell_4_4"].value as? String,"候選圖樣已載入")
        app.navigationBars.buttons.element(boundBy:0).tap()
        tap(app,"v11-presentation"); XCTAssertTrue(app.buttons["present-play"].waitForExistence(timeout:5))
        app.buttons["lab-warrior"].tap(); XCTAssertTrue(app.buttons["warrior-play"].waitForExistence(timeout:5))
        app.terminate(); app.expansionShellArguments = []; app.launch()
        XCTAssertFalse(app.buttons["v11-play"].exists)
    }
}

/// In the integrated app the 1.1 shell is `ExpansionGameView`; these tests drive it directly (DEBUG-only routing in
/// `TacticalGoApp` for any `--integrated-*` argument). Arguments the original tests pass are kept as they are.
private extension XCUIApplication {
    var expansionShellArguments: [String] {
        get { launchArguments }
        // A fresh token per test resets sound settings once, so results do not depend on test order or on preferences
        // left in the simulator; relaunching the same app object keeps the token and therefore the test's own settings.
        set { launchArguments = ["--integrated-shell"] + newValue + ["--sound-preferences-reset", UUID().uuidString] }
    }
}
