import XCTest
import TacticalGoCore
import TacticalGoContent
import TacticalGoMotion

final class HapticVocabularyTests: XCTestCase {
    func testHapticPreferenceMissingValueDefaultsOn() {
        XCTAssertTrue(HapticPreference(stored: nil).enabled)
        XCTAssertEqual(HapticPreference.storageKey, "combatHaptics.enabled")
    }

    func testHapticPreferenceStoredFalseStaysOff() {
        XCTAssertFalse(HapticPreference(stored: false).enabled)
    }

    func testHapticPreferenceStoredTrueStaysOn() {
        XCTAssertTrue(HapticPreference(stored: true).enabled)
    }

    func testHapticPreferenceNonBoolFallsBackOn() {
        XCTAssertTrue(HapticPreference(stored: "off").enabled)
        XCTAssertTrue(HapticPreference(stored: 0).enabled)
    }

    func testHapticPreferenceRoundTripUsesIsolatedDefaults() {
        let name = "HapticPreferenceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        XCTAssertNil(defaults.object(forKey: HapticPreference.storageKey))
        XCTAssertTrue(HapticPreference(stored: defaults.object(forKey: HapticPreference.storageKey)).enabled)
        defaults.set(false, forKey: HapticPreference.storageKey)
        XCTAssertFalse(HapticPreference(stored: defaults.object(forKey: HapticPreference.storageKey)).enabled)
        defaults.set(true, forKey: HapticPreference.storageKey)
        XCTAssertTrue(HapticPreference(stored: defaults.object(forKey: HapticPreference.storageKey)).enabled)
        defaults.set("no", forKey: HapticPreference.storageKey)
        XCTAssertTrue(HapticPreference(stored: defaults.object(forKey: HapticPreference.storageKey)).enabled)
        defaults.removePersistentDomain(forName: name)
    }

    func testHapticGateDisabledEmitsNoCues() {
        let gate = HapticGate(enabled: false, hardwareSupported: true, systemHapticsEnabled: true)
        XCTAssertFalse(gate.allowsPlayback)
        XCTAssertTrue(HapticPlayback.audible([tap(.placement, 0.5, at: 0.15)], gate: gate).isEmpty)
    }

    func testHapticGateUnsupportedHardwareEmitsNoCues() {
        let gate = HapticGate(enabled: true, hardwareSupported: false, systemHapticsEnabled: true)
        XCTAssertTrue(HapticPlayback.audible([tap(.kill, 0.75, at: 0.22)], gate: gate).isEmpty)
    }

    func testHapticGateSystemHapticsOffEmitsNoCues() {
        let gate = HapticGate(enabled: true, hardwareSupported: true, systemHapticsEnabled: false)
        XCTAssertTrue(HapticPlayback.audible([tap(.victory, 1, at: 0.4)], gate: gate).isEmpty)
    }

    func testHapticPlaybackDropsNonFiniteAndOutOfRangeIntensity() {
        let gate = HapticGate(enabled: true, hardwareSupported: true, systemHapticsEnabled: true)
        let kept = HapticPlayback.audible([
            tap(.placement, .nan, at: 0.1),
            tap(.contactHit, 0, at: 0.2),
            tap(.kill, 1.01, at: 0.3),
            tap(.chain, 0.875, at: -0.01),
            tap(.victory, 1, at: .infinity),
            tap(.defeat, 1, at: 0.4)
        ], gate: gate)
        XCTAssertEqual(kept, [tap(.defeat, 1, at: 0.4)])
    }

    func testHapticPlaybackSameTimeKeepsTheStrongerImpulse() {
        let gate = HapticGate(enabled: true, hardwareSupported: true, systemHapticsEnabled: true)
        let kept = HapticPlayback.audible([
            tap(.placement, 0.5, at: 0.58),
            tap(.contactHit, 0.625, at: 0.58)
        ], gate: gate)
        XCTAssertEqual(kept, [tap(.contactHit, 0.625, at: 0.58)])
    }

    func testHapticIntensityRisesFromPlacementToMatchEnd() {
        XCTAssertEqual(HapticVocabulary.peak(for: .placement, reduceMotion: false), 0.5)
        XCTAssertEqual(HapticVocabulary.peak(for: .contactHit, reduceMotion: false), 0.625)
        XCTAssertEqual(HapticVocabulary.peak(for: .kill, reduceMotion: false), 0.75)
        XCTAssertEqual(HapticVocabulary.peak(for: .chain, reduceMotion: false), 0.875)
        XCTAssertEqual(HapticVocabulary.peak(for: .victory, reduceMotion: false), 1)
        XCTAssertEqual(HapticVocabulary.peak(for: .defeat, reduceMotion: false), 1)
        XCTAssertEqual(HapticVocabulary.feel(for: .placement), .soft)
        XCTAssertEqual(HapticVocabulary.feel(for: .contactHit), .light)
        XCTAssertEqual(HapticVocabulary.feel(for: .kill), .medium)
        XCTAssertEqual(HapticVocabulary.feel(for: .chain), .heavy)
        XCTAssertEqual(HapticVocabulary.feel(for: .victory), .success)
        XCTAssertEqual(HapticVocabulary.feel(for: .defeat), .error)
        let order: [HapticEvent] = [.placement, .contactHit, .kill, .chain, .victory]
        var previous = 0.0
        for event in order {
            let peak = HapticVocabulary.peak(for: event, reduceMotion: false)
            XCTAssertGreaterThan(peak, previous)
            previous = peak
        }
    }

    func testReduceMotionSoftensMotionTapsAndKeepsOutcomePeaks() {
        XCTAssertEqual(HapticVocabulary.peak(for: .placement, reduceMotion: true), 0.375)
        XCTAssertEqual(HapticVocabulary.peak(for: .contactHit, reduceMotion: true), 0.5)
        XCTAssertEqual(HapticVocabulary.peak(for: .kill, reduceMotion: true), 0.75)
        XCTAssertEqual(HapticVocabulary.peak(for: .chain, reduceMotion: true), 0.875)
        XCTAssertEqual(HapticVocabulary.peak(for: .victory, reduceMotion: true), 1)
        XCTAssertEqual(HapticVocabulary.peak(for: .defeat, reduceMotion: true), 1)
        var previous = 0.0
        for event in [HapticEvent.placement, .contactHit, .kill, .chain, .victory] {
            let peak = HapticVocabulary.peak(for: event, reduceMotion: true)
            XCTAssertGreaterThan(peak, previous)
            previous = peak
        }
    }

    func testChainPatternUsesLeadThenPeakAndCollapsesUnderReduceMotion() {
        let full = HapticVocabulary.chainImpulses(at: [0.36, 0.26, 0.26], reduceMotion: false)
        XCTAssertEqual(full.map(\.event), [.chain, .chain])
        XCTAssertEqual(full.map(\.at), [0.26, 0.36])
        XCTAssertEqual(full.map(\.intensity), [0.75, 0.875])
        XCTAssertGreaterThan(full[0].intensity, HapticVocabulary.peak(for: .kill, reduceMotion: false) - 0.0001)
        let reduced = HapticVocabulary.chainImpulses(at: [0.26, 0.36], reduceMotion: true)
        XCTAssertEqual(reduced, [HapticVocabulary.impulse(.chain, at: 0.36, reduceMotion: true)])
        XCTAssertEqual(HapticVocabulary.chainImpulses(at: [0.36], reduceMotion: false).map(\.intensity), [0.875])
        XCTAssertTrue(HapticVocabulary.chainImpulses(at: [], reduceMotion: false).isEmpty)
    }

    func testLegacyPlaceCueMapsToPlacementAndSkillLandingMapsToContact() {
        let placed = HapticCuePlan.impulses(legacyCues: [.init("place", at: 0.21)], action: .placeSoldier(Point(3, 3)), defeat: false, reduceMotion: false)
        XCTAssertEqual(placed, [HapticVocabulary.impulse(.placement, at: 0.21, reduceMotion: false)])
        let summoned = HapticCuePlan.impulses(legacyCues: [.init("summon", at: 0)], action: .summonHero(Point(4, 4)), defeat: false, reduceMotion: false)
        XCTAssertEqual(summoned.map(\.event), [.placement])
        let contact = HapticCuePlan.impulses(
            legacyCues: [.init("mage", at: 0), .init("place", at: 0.56), .init("capture", at: 0.62), .init("victory", at: 0.96), .init("danger", at: 0.7)],
            action: .castMagicHand(Point(4, 3), .up), defeat: false, reduceMotion: false)
        XCTAssertEqual(contact.map(\.event), [.contactHit, .kill, .victory])
        XCTAssertEqual(contact.map(\.intensity), [0.625, 0.75, 1])
        let loss = HapticCuePlan.impulses(legacyCues: [.init("victory", at: 0.96)], action: .placeSoldier(Point(3, 3)), defeat: true, reduceMotion: false)
        XCTAssertEqual(loss.map(\.event), [.defeat])
        XCTAssertTrue(HapticCuePlan.impulses(legacyCues: [.init("draw", at: 0)], action: .endTurn, defeat: false, reduceMotion: false).isEmpty)
        XCTAssertTrue(HapticCuePlan.impulses(legacyCues: [], action: .placeSoldier(Point(0, 0)), defeat: false, reduceMotion: false).isEmpty)
    }

    func testNilPresentationAndRejectedActionScheduleNothing() throws {
        XCTAssertTrue(HapticCuePlan.impulses(presentation: nil, computer: nil, reduceMotion: false).isEmpty)
        let before = try endingBoard(winner: .one)
        let invalid = GameAction.placeSoldier(Point(3, 2))
        let rejected = GameEngine.apply(before, invalid)
        XCTAssertFalse(rejected.success)
        let presentation = ExpansionPresentation.make(before: before, action: invalid, outcome: rejected, current: before)
        XCTAssertNil(presentation)
        XCTAssertTrue(HapticCuePlan.impulses(presentation: presentation, computer: .two, reduceMotion: true).isEmpty)
    }

    func testPlaceSoldierMapsToPlacementOnly() throws {
        var session = try ExpansionPractice.rogue.session()
        let before = session.state
        let result = session.apply(.placeSoldier(Point(8, 8)))
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: before, action: .placeSoldier(Point(8, 8)), outcome: result, current: result.state))
        let impulses = HapticCuePlan.impulses(presentation: presentation, computer: nil, reduceMotion: false)
        XCTAssertEqual(impulses.map(\.event), [.placement])
        XCTAssertEqual(impulses.map(\.intensity), [0.5])
        XCTAssertEqual(impulses[0].at, 0.15, accuracy: 0.0001)
    }

    func testPracticeSkillsMapContactAndChainWithoutInventingMatchEnd() throws {
        let mage = try presentation(.mage)
        XCTAssertEqual(HapticCuePlan.impulses(presentation: mage, computer: nil, reduceMotion: false).map(\.event), [.contactHit])
        XCTAssertEqual(mage.arrival, 0.68, accuracy: 0.0001)
        let priest = try presentation(.priest)
        XCTAssertTrue(HapticCuePlan.impulses(presentation: priest, computer: nil, reduceMotion: false).contains { $0.event == .contactHit })
        let rogue = try presentation(.rogue)
        let chain = HapticCuePlan.impulses(presentation: rogue, computer: nil, reduceMotion: false).filter { $0.event == .chain }
        XCTAssertEqual(chain.count, 2)
        XCTAssertEqual(chain[0].at, 0.26, accuracy: 0.0001)
        XCTAssertEqual(chain[1].at, 0.36, accuracy: 0.0001)
        XCTAssertEqual(chain.map(\.intensity), [0.75, 0.875])
        XCTAssertFalse(HapticCuePlan.impulses(presentation: rogue, computer: nil, reduceMotion: false).contains { $0.event == .contactHit })
        let reduced = HapticCuePlan.impulses(presentation: rogue, computer: nil, reduceMotion: true).filter { $0.event == .chain }
        XCTAssertEqual(reduced.count, 1)
        XCTAssertEqual(reduced[0].at, 0.36, accuracy: 0.0001)
        XCTAssertEqual(reduced.map(\.intensity), [0.875])
        for fixture in [ExpansionPractice.warrior, .mage, .rogue, .priest] {
            let cues = HapticCuePlan.impulses(presentation: try presentation(fixture), computer: nil, reduceMotion: false)
            XCTAssertFalse(cues.contains { $0.event == .victory || $0.event == .defeat })
        }
    }

    func testCaptureWinMapsVictoryOrDefeatFromTheHumanPerspective() throws {
        for winner in [Player.one, .two] {
            let before = try endingBoard(winner: winner)
            let action = GameAction.placeSoldier(Point(3, 3))
            let result = GameEngine.apply(before, action)
            XCTAssertEqual(result.state.status, .won)
            let presentation = try XCTUnwrap(ExpansionPresentation.make(before: before, action: action, outcome: result, current: result.state))
            XCTAssertFalse(presentation.captures.isEmpty)
            let loss = HapticCuePlan.impulses(presentation: presentation, computer: winner, reduceMotion: false).map(\.event)
            let win = HapticCuePlan.impulses(presentation: presentation, computer: winner.opponent, reduceMotion: false).map(\.event)
            XCTAssertEqual(loss, [.placement, .kill, .defeat])
            XCTAssertEqual(win, [.placement, .kill, .victory])
            XCTAssertEqual(HapticCuePlan.impulses(presentation: presentation, computer: nil, reduceMotion: false).map(\.event), [.placement, .kill, .victory])
        }
    }

    func testDrawMapsToNeitherVictoryNorDefeat() throws {
        var config = RuleConfig.board(size: 7)
        config.expansionSkills = true
        config.maxPlies = 1
        let before = try GameSetup.fromDiagram(config: config, diagram: ".......\n...x...\n..xOx..\n.......\n.......\n...X...\n.......",
                                                classOne: .warrior, classTwo: .mage, current: .one, ap: 2)
        let draw = GameEngine.apply(before, .endTurn)
        XCTAssertEqual(draw.state.status, .drawn)
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: before, action: .endTurn, outcome: draw, current: draw.state))
        let events = HapticCuePlan.impulses(presentation: presentation, computer: .two, reduceMotion: false).map(\.event)
        XCTAssertFalse(events.contains(.victory))
        XCTAssertFalse(events.contains(.defeat))
        XCTAssertFalse(events.contains(.kill))
    }

    private func presentation(_ fixture: ExpansionPractice) throws -> ExpansionPresentation {
        let session = try fixture.session()
        let before = session.state
        let result = GameEngine.apply(before, fixture.action)
        return try XCTUnwrap(ExpansionPresentation.make(before: before, action: fixture.action, outcome: result, current: result.state))
    }

    private func endingBoard(winner: Player) throws -> GameState {
        var config = RuleConfig.board(size: 7)
        config.expansionSkills = true
        let diagram = winner == .one
            ? ".......\n...x...\n..xOx..\n.......\n.......\n...X...\n......."
            : ".......\n...o...\n..oXo..\n.......\n.......\n...O...\n......."
        return try GameSetup.fromDiagram(config: config, diagram: diagram, classOne: .warrior, classTwo: .mage, current: winner, ap: 2)
    }

    private func tap(_ event: HapticEvent, _ intensity: Double, at time: Double) -> HapticImpulse {
        .init(event: event, feel: HapticVocabulary.feel(for: event), intensity: intensity, at: time)
    }
}
