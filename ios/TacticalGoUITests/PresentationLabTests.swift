import XCTest

@MainActor final class PresentationLabTests: XCTestCase {
    private func launch(_ args:[String] = []) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--presentation-lab"] + args; app.launch()
        XCTAssertTrue(app.buttons["present-play"].waitForExistence(timeout:15))
        return app
    }
    private func tap(_ app:XCUIApplication,_ id:String) {
        let b = app.buttons[id]
        for _ in 0..<4 { if b.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(b.isHittable,id); b.tap()
    }
    private func settled(_ app:XCUIApplication) {
        let predicate = NSPredicate(format:"label CONTAINS %@", "active=false")
        XCTAssertTrue(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:app.staticTexts["present-audit"])],timeout:4) == .completed)
    }
    private func shot(_ app:XCUIApplication,_ name:String) {
        let a = XCTAttachment(screenshot:app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    func testPhoneADSameResultPreviewUndoAndReplay() {
        let app = launch()
        // D uses the phone board; compare its Domain outcome to
        // the restored phone A, rather than accidentally testing one variant twice.
        tap(app,"present-D")
        let before = app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0]
        tap(app,"present-preview")
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],before)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("cues=0"))
        tap(app,"present-cancel"); tap(app,"present-play"); settled(app)
        let b = app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0]
        XCTAssertTrue(b.contains("ap=1|mana=2"))
        shot(app,"present-D-final")
        tap(app,"present-undo")
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],before)
        tap(app,"present-A"); tap(app,"present-play"); settled(app)
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],b)
        tap(app,"present-play"); settled(app)
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],b)
        shot(app,"present-A-final")
    }
    func testWhiteDenseNineAndCaptureAreRealEngineResults() {
        let app = launch(["--presentation-9","--presentation-white","--presentation-dense"])
        tap(app,"present-play"); settled(app)
        XCTAssertTrue(app.staticTexts["present-status"].label.contains("施法成功"))
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=1|mana=2"))
        shot(app,"present-white-dense-nine")
        tap(app,"present-capture"); tap(app,"present-play"); settled(app)
        // D uses conjure/push/contact plus receipt-only capture/victory.
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("cues=5"))
        shot(app,"present-white-capture-nine")
        tap(app,"present-undo")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=2|mana=4"),app.staticTexts["present-audit"].label)
    }
    func testReducedMotionMuteAndBackgroundCancel() {
        let app = launch()
        for id in ["present-reduced","present-muted"] {
            let toggle = app.switches[id]
            for _ in 0..<3 { if toggle.isHittable { break }; app.swipeUp() }
            toggle.switches.firstMatch.exists ? toggle.switches.firstMatch.tap() : toggle.tap()
        }
        app.swipeDown(); tap(app,"present-play"); settled(app)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("players=0"))
        shot(app,"present-reduced-muted")
        let foregroundFrame = app.windows.firstMatch.frame
        XCUIDevice.shared.press(.home)
        app.activate()
        // activate() can return during the iOS zoom transition. The failed
        // event targeted a 355x773 window instead of the foreground window;
        // wait for its actual geometry before asking XCTest to tap Undo.
        let restoredWindow = NSPredicate { _, _ in app.windows.firstMatch.frame == foregroundFrame }
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:restoredWindow,object:nil)],timeout:4), .completed)

        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("active=false"))
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("players=0"))
        tap(app,"present-undo")
        shot(app,"present-resume-undo")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=2|mana=4"),app.staticTexts["present-audit"].label)
    }
    func testNativeEarlyCancellationStopsScheduledSoundAndUndo() {
        let app = launch(["--presentation-lifecycle-audit"])
        let predicate = NSPredicate(format:"label CONTAINS %@", "中途取消檢查通過")
        XCTAssertTrue(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:predicate,object:app.staticTexts["present-status"])],timeout:8) == .completed, app.staticTexts["present-status"].label)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("players=0"))
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=2|mana=4"))
    }
    func testNativeSmallPoseReviewAndOptionalAirLayer() {
        let app=launch(["--presentation-C"])
        let toggle=app.switches["present-air"]
        for _ in 0..<4 { if toggle.isHittable { break }; app.swipeUp() }
        let control=toggle.switches.firstMatch.exists ? toggle.switches.firstMatch : toggle
        XCTAssertEqual(control.value as? String,"1")
        control.tap()
        XCTAssertEqual(control.value as? String,"0")
        tap(app,"present-play"); settled(app)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=1|mana=2"))
        tap(app,"present-undo")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=2|mana=4"))
        for _ in 0..<5 { if app.staticTexts["64 pt"].isHittable { break }; app.swipeUp() }
        for label in ["32 pt","48 pt","64 pt"] { XCTAssertTrue(app.staticTexts[label].isHittable,label) }
        shot(app,"present-C-native-32-48-64")
    }
    func testNativeDHandAndSmallPoseReview() {
        let app=launch(["--presentation-D"])
        for _ in 0..<6 { if app.staticTexts["推開"].isHittable { break }; app.swipeUp() }
        for label in ["32 pt","48 pt","64 pt","伸出","抓穩","推開"] { XCTAssertTrue(app.staticTexts[label].isHittable,label) }
        shot(app,"present-D-native-hand-and-32-48-64")
    }
    func testAudioProfileToggleKeepsSameResultAndUndo() {
        let app=launch(["--presentation-D"])
        tap(app,"present-play");settled(app)
        let result=app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0]
        tap(app,"present-undo")
        let toggle=app.switches["present-weighty-audio"]
        for _ in 0..<5 { if toggle.isHittable { break };app.swipeUp() }
        let control=toggle.switches.firstMatch.exists ? toggle.switches.firstMatch:toggle
        XCTAssertEqual(control.value as? String,"1");control.tap();XCTAssertEqual(control.value as? String,"0")
        tap(app,"present-play");settled(app)
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],result)
        tap(app,"present-undo");XCTAssertTrue(app.staticTexts["present-audit"].label.contains("ap=2|mana=4"))
    }
    func testEnglishCastingVoiceTakesMuteAndPreview() {
        let app=launch(["--presentation-D"])
        tap(app,"present-preview")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=0"))
        tap(app,"present-play");settled(app)
        let result=app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0]
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=1|take=B"))
        tap(app,"present-undo")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("players=0"))
        let voice=app.switches["present-cast-voice"]
        for _ in 0..<5 { if voice.isHittable { break };app.swipeUp() }
        let control=voice.switches.firstMatch.exists ? voice.switches.firstMatch:voice
        XCTAssertEqual(control.value as? String,"1");control.tap()
        tap(app,"present-play");settled(app)
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],result)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=0"))
        tap(app,"present-undo")
        for _ in 0..<5 { if control.isHittable { break };app.swipeUp() };control.tap()
        let take=app.buttons["A · 自信指令"]
        for _ in 0..<5 { if take.isHittable { break };app.swipeUp() };take.tap()
        tap(app,"present-play");settled(app)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=1|take=A"))
        XCTAssertEqual(app.staticTexts["present-audit"].label.components(separatedBy:"|active=")[0],result)
        tap(app,"present-undo")
        let mute=app.switches["present-muted"]
        for _ in 0..<5 { if mute.isHittable { break };app.swipeDown() }
        (mute.switches.firstMatch.exists ? mute.switches.firstMatch:mute).tap()
        tap(app,"present-play");settled(app)
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=0"))
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("players=0"))
    }
}

@MainActor final class WarriorPresentationLabTests:XCTestCase {
    private func launch(_ args:[String]=[])->XCUIApplication {
        let app=XCUIApplication();app.launchArguments=["--presentation-lab","--presentation-warrior"]+args;app.launch()
        XCTAssertTrue(app.buttons["warrior-play"].waitForExistence(timeout:15));return app
    }
    private func tap(_ app:XCUIApplication,_ id:String) {
        let button=app.buttons[id]
        for _ in 0..<6 {if button.isHittable {break};if button.frame.minY < app.windows.firstMatch.frame.midY {app.swipeDown()} else {app.swipeUp()}}
        XCTAssertTrue(button.isHittable,id);button.tap()
    }
    private func toggle(_ app:XCUIApplication,_ id:String) {
        let s=app.switches[id]
        for _ in 0..<5 {if s.isHittable {break};app.swipeUp()}
        XCTAssertTrue(s.isHittable,id);(s.switches.firstMatch.exists ? s.switches.firstMatch:s).tap()
    }
    private func settled(_ app:XCUIApplication) {
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","active=false"),object:app.staticTexts["warrior-audit"])],timeout:4),.completed)
    }
    private func shot(_ app:XCUIApplication,_ name:String) {let a=XCTAttachment(screenshot:app.screenshot());a.name=name;a.lifetime = .keepAlways;add(a)}
    func testPreviewBothVoicesSameOldNewResultAndUndo() {
        let app=launch();XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("take=B"));tap(app,"A · 堅定守護");tap(app,"warrior-preview")
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"));XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=0"))
        tap(app,"warrior-play");settled(app)
        let result=app.staticTexts["warrior-audit"].label.components(separatedBy:"|active=")[0]
        XCTAssertTrue(result.contains("ap=1|mana=2"));XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=1|take=A"))
        tap(app,"warrior-undo");XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("players=0"))
        toggle(app,"warrior-voice");tap(app,"warrior-play");settled(app)
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=0"));XCTAssertEqual(app.staticTexts["warrior-audit"].label.components(separatedBy:"|active=")[0],result)
        tap(app,"warrior-undo");toggle(app,"warrior-voice")
        let b=app.buttons["B · 戰線號令"];for _ in 0..<5 {if b.isHittable {break};app.swipeUp()};b.tap()
        tap(app,"warrior-play");settled(app);XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=1|take=B"))
        XCTAssertEqual(app.staticTexts["warrior-audit"].label.components(separatedBy:"|active=")[0],result)
        tap(app,"warrior-old");tap(app,"warrior-play");settled(app)
        XCTAssertEqual(app.staticTexts["warrior-audit"].label.components(separatedBy:"|active=")[0],result)
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=0"));tap(app,"warrior-undo")
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"))
    }
    func testWhiteDenseNineCaptureAndOriginalPixelSmallPoses() {
        let app=launch(["--warrior-white","--warrior-9","--warrior-dense"])
        tap(app,"warrior-play");settled(app);XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=1|mana=2"));shot(app,"warrior-white-dense-nine")
        tap(app,"warrior-capture");tap(app,"warrior-play");settled(app)
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("captures=1"));shot(app,"warrior-white-capture-nine")
        tap(app,"warrior-undo");XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"))
        for _ in 0..<6 {if app.staticTexts["擊地"].isHittable {break};app.swipeUp()}
        for text in ["站穩","蓄勢","擊地"] {XCTAssertTrue(app.staticTexts[text].isHittable)}
        shot(app,"warrior-native-32-48-64-rest-coil-impact")
    }
    func testEarlyCancellationAndInterruptionStopVoice() {
        let app=launch(["--warrior-lifecycle-audit","--warrior-voice-B"])
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate(format:"label CONTAINS %@","取消檢查通過"),object:app.staticTexts["warrior-status"])],timeout:9),.completed)
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("players=0"));XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"))
    }
    func testReducedMuteBackgroundAndReturnToAcceptedMage() {
        let app=launch();toggle(app,"warrior-reduced");toggle(app,"warrior-muted");tap(app,"warrior-play");settled(app)
        XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("voice=0"));XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("players=0"));shot(app,"warrior-reduced-muted")
        let frame=app.windows.firstMatch.frame;XCUIDevice.shared.press(.home);app.activate()
        XCTAssertEqual(XCTWaiter.wait(for:[XCTNSPredicateExpectation(predicate:NSPredicate {_,_ in app.windows.firstMatch.frame==frame},object:nil)],timeout:4),.completed)
        tap(app,"warrior-undo");XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"))
        app.buttons["lab-mage"].tap();XCTAssertTrue(app.buttons["present-play"].waitForExistence(timeout:5));tap(app,"present-play")
        XCTAssertTrue(app.staticTexts["present-audit"].label.contains("voice=1|take=B"))
        app.buttons["lab-warrior"].tap();XCTAssertTrue(app.buttons["warrior-play"].waitForExistence(timeout:5));XCTAssertTrue(app.staticTexts["warrior-audit"].label.contains("ap=2|mana=4"))
    }
}
