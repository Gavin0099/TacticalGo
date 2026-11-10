import XCTest
import TacticalGoCore
import TacticalGoMotion

/// Behavior source: A/B-T1 event list and the published intensity table in `HapticVocabulary`.
/// Times must match the receipt fields the sound cues already use. Expected patterns are literals,
/// not recomputed from the production switch.
final class HapticVocabularyTests: XCTestCase {
    private let rarityOrder: [GameHapticEvent] = [.placement, .contactHit, .kill, .chain, .defeat, .victory]
    private let publishedPeaks: [Float] = [0.32, 0.48, 0.64, 0.78, 0.90, 1.00]

    func test_hapticToggle_off_suppressesAllSixEvents() {
        let gate = HapticGate(enabled: false, reduceMotion: false)
        for event in GameHapticEvent.allCases {
            XCTAssertNil(gate.pattern(for: event), event.rawValue)
        }
    }

    func test_hapticToggle_on_returnsAPatternForAllSixEvents() {
        let gate = HapticGate(enabled: true, reduceMotion: false)
        for event in GameHapticEvent.allCases {
            XCTAssertNotNil(gate.pattern(for: event), event.rawValue)
        }
    }

    func test_hapticToggle_missingStoredFlag_defaultsOn() {
        XCTAssertTrue(HapticPreference(storedFlag: nil).enabled)
    }

    func test_hapticToggle_storedFalse_staysOff() {
        XCTAssertFalse(HapticPreference(storedFlag: false).enabled)
        XCTAssertTrue(HapticPreference(storedFlag: true).enabled)
    }

    func test_hapticToggle_reduceMotion_stillPlaysShortPattern() {
        let gate = HapticGate(enabled: true, reduceMotion: true)
        let victory = gate.pattern(for: .victory)
        XCTAssertEqual(victory, HapticPattern(transients: [.init(time: 0, intensity: 1.00, sharpness: 0.90)]))
    }

    func test_hapticPattern_publishedPeaks_increaseWithRarity() {
        let full: [HapticPattern] = [
            HapticPattern(transients: [.init(time: 0, intensity: 0.32, sharpness: 0.25)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.48, sharpness: 0.72)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.64, sharpness: 0.80)]),
            HapticPattern(transients: [
                .init(time: 0, intensity: 0.62, sharpness: 0.70),
                .init(time: 0.10, intensity: 0.78, sharpness: 0.84)
            ]),
            HapticPattern(
                transients: [.init(time: 0, intensity: 0.90, sharpness: 0.22)],
                continuous: [.init(time: 0.02, duration: 0.28, intensity: 0.40, sharpness: 0.12)]
            ),
            HapticPattern(
                transients: [
                    .init(time: 0, intensity: 0.55, sharpness: 0.45),
                    .init(time: 0.12, intensity: 0.78, sharpness: 0.62),
                    .init(time: 0.24, intensity: 1.00, sharpness: 0.90)
                ],
                continuous: [.init(time: 0.24, duration: 0.40, intensity: 0.70, sharpness: 0.40)]
            )
        ]
        for (event, expected) in zip(rarityOrder, full) {
            XCTAssertEqual(HapticVocabulary.pattern(for: event, reduceMotion: false), expected, event.rawValue)
        }
        let peaks = rarityOrder.map { HapticVocabulary.pattern(for: $0, reduceMotion: false).peakIntensity }
        XCTAssertEqual(peaks, publishedPeaks)
        for pair in zip(peaks, peaks.dropFirst()) {
            XCTAssertGreaterThan(pair.1, pair.0)
        }
    }

    func test_hapticPattern_reduceMotion_keepsPeakAndDropsChoreography() {
        let expected: [HapticPattern] = [
            HapticPattern(transients: [.init(time: 0, intensity: 0.32, sharpness: 0.25)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.48, sharpness: 0.72)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.64, sharpness: 0.80)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.78, sharpness: 0.84)]),
            HapticPattern(transients: [.init(time: 0, intensity: 0.90, sharpness: 0.22)]),
            HapticPattern(transients: [.init(time: 0, intensity: 1.00, sharpness: 0.90)])
        ]
        for (event, pattern) in zip(rarityOrder, expected) {
            let reduced = HapticVocabulary.pattern(for: event, reduceMotion: true)
            XCTAssertEqual(reduced, pattern, event.rawValue)
            XCTAssertEqual(reduced.peakIntensity, HapticVocabulary.pattern(for: event, reduceMotion: false).peakIntensity)
            XCTAssertTrue(reduced.continuous.isEmpty)
            XCTAssertEqual(reduced.transients.count, 1)
        }
    }

    func test_legacyHapticPlan_placeSoldier_mapsPlaceCueToPlacement() {
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "place", action: .placeSoldier(Point(2, 1))), .placement)
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "summon", action: .summonHero(Point(2, 1))), .placement)
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "capture", action: .placeSoldier(Point(2, 1))), .kill)
    }

    func test_legacyHapticPlan_skillLanding_mapsPlaceCueToContactNotPlacement() {
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "place", action: .castMagicHand(Point(4, 3), .up)), .contactHit)
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "place", action: .castSwap(Point(4, 3))), .contactHit)
        XCTAssertNil(LegacyHapticPlan.event(forCue: "place", action: .castChainSwap(first: Point(4, 4), second: Point(5, 4))))
    }

    func test_legacyHapticPlan_victoryCue_becomesDefeatOnlyWhenComputerWon() {
        XCTAssertEqual(LegacyHapticPlan.playbackKey("victory", winnerIsComputer: false), "victory")
        XCTAssertEqual(LegacyHapticPlan.playbackKey("victory", winnerIsComputer: true), "defeat")
        XCTAssertEqual(LegacyHapticPlan.playbackKey("place", winnerIsComputer: true), "place")
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "victory", action: .placeSoldier(Point(0, 0))), .victory)
        XCTAssertEqual(LegacyHapticPlan.event(forCue: "defeat", action: .placeSoldier(Point(0, 0))), .defeat)
    }

    func test_legacyHapticPlan_routineCues_staySilent() {
        let action = GameAction.placeSoldier(Point(2, 1))
        for key in ["selection", "confirm", "mage", "warrior", "rogue", "danger", "draw", "w7-strike", "w7-land"] {
            XCTAssertNil(LegacyHapticPlan.event(forCue: key, action: action), key)
        }
    }

    func test_expansionHapticPlan_placeSoldier_firesPlacementAtArrival() throws {
        let state = try GameSetup.fromDiagram(config: .board(size: 7),
            diagram: ".......\n...O...\n...x...\n.......\n.......\n...X...\n.......", classOne: .mage, manaOne: 4, ap: 2)
        let action = GameAction.placeSoldier(Point(2, 1))
        let outcome = GameEngine.apply(state, action)
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: state, action: action, outcome: outcome, current: outcome.state))
        XCTAssertEqual(ExpansionHapticPlan.moments(presentation, computer: nil),
                       [HapticMoment(.placement, at: presentation.arrival)])
    }

    func test_expansionHapticPlan_bastion_firesOneContactHit() throws {
        let state = try GameSetup.fromDiagram(config: .board(size: 7),
            diagram: "...O...\n.......\n.......\n...H...\n.......\n...X...\n.......", classOne: .warrior, manaOne: 4, ap: 2)
        let action = GameAction.castBastion(Point(2, 3), Point(4, 3))
        let outcome = GameEngine.apply(state, action)
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: state, action: action, outcome: outcome, current: outcome.state))
        let moments = ExpansionHapticPlan.moments(presentation, computer: nil)
        XCTAssertEqual(moments.filter { $0.event == .contactHit }.map(\.at), [presentation.arrival])
        XCTAssertEqual(moments.filter { $0.event == .contactHit }.count, 1)
        XCTAssertFalse(moments.contains { $0.event == .placement || $0.event == .chain })
    }

    func test_expansionHapticPlan_chainSwap_firesChainWithoutContact() throws {
        let state = try expansionState(.rogue, [(Point(3, 4), "H"), (Point(4, 4), "o"), (Point(5, 4), "o")])
        let action = GameAction.castChainSwap(first: Point(4, 4), second: Point(5, 4))
        let outcome = GameEngine.apply(state, action)
        XCTAssertTrue(outcome.success)
        XCTAssertFalse(outcome.events.contains { if case .piecesCaptured = $0 { return true }; return false })
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: state, action: action, outcome: outcome, current: outcome.state))
        let moments = ExpansionHapticPlan.moments(presentation, computer: nil)
        let firstContact = (presentation.moveStart + presentation.arrival) / 2
        XCTAssertEqual(moments, [HapticMoment(.chain, at: firstContact)])
    }

    func test_expansionHapticPlan_chainCapture_firesKillAndVictoryOrDefeat() throws {
        let wall: [(Point, Character)] = [(Point(3, 1), "x"), (Point(5, 1), "x"), (Point(4, 0), "x")]
        let stones: [(Point, Character)] = [(Point(3, 3), "H"), (Point(3, 2), "o"), (Point(4, 2), "o")]
        let state = try expansionState(.rogue, wall + stones, ap: 1)
        let action = GameAction.castChainSwap(first: Point(3, 2), second: Point(4, 2))
        let outcome = GameEngine.apply(state, action)
        XCTAssertEqual(outcome.state.winner, .one)
        let presentation = try XCTUnwrap(ExpansionPresentation.make(before: state, action: action, outcome: outcome, current: outcome.state))
        let firstContact = (presentation.moveStart + presentation.arrival) / 2
        let human = ExpansionHapticPlan.moments(presentation, computer: nil)
        XCTAssertEqual(human.map(\.event), [.chain, .kill, .victory])
        XCTAssertEqual(human.map(\.at), [firstContact, presentation.captureStart, presentation.duration])
        XCTAssertFalse(human.contains { $0.event == .contactHit })
        let lost = ExpansionHapticPlan.moments(presentation, computer: .one)
        XCTAssertEqual(lost.map(\.event), [.chain, .kill, .defeat])
        XCTAssertFalse(lost.contains { $0.event == .victory })
    }

    private func expansionState(_ hero: HeroClass, _ stones: [(Point, Character)], ap: Int = 2) throws -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: 9), count: 9)
        rows[7][4] = "X"
        rows[1][4] = "O"
        for (point, mark) in stones { rows[point.y][point.x] = mark }
        var config = RuleConfig.board(size: 9)
        config.expansionSkills = true
        config.expansionSkillManaCost = 4
        return try GameSetup.fromDiagram(config: config, diagram: rows.map { String($0) }.joined(separator: "\n"),
            classOne: hero, classTwo: .mage, manaOne: 6, manaTwo: 6, ap: ap)
    }
}
