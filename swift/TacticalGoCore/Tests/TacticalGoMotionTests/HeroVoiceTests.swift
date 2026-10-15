import XCTest
import TacticalGoCore
import TacticalGoMotion

final class HeroVoiceTests: XCTestCase {
    func testEachSummonUsesActualPrecommitClassAndNotOpponent() throws {
        for (hero, expected) in [(HeroClass.warrior, "voice-warrior-summon"), (.mage, "voice-mage-summon"), (.rogue, "voice-rogue-summon")] {
            for owner in Player.allCases {
                let before = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...O...\n.......\n.......\n.......\n.......\n...X...\n.......", classOne: hero, classTwo: hero, current: owner, manaOne: 4, manaTwo: 4, ap: 1)
                let at = owner == .one ? Point(3, 4) : Point(3, 1)
                let action = GameAction.summonHero(at), outcome = GameEngine.apply(before, action)
                XCTAssertTrue(outcome.success)
                XCTAssertNotEqual(outcome.state.current, owner)
                XCTAssertEqual(HeroVoiceCue.make(before: before, action: action, outcome: outcome)?.key, expected)
                XCTAssertEqual(outcome.state.apRemaining, 2)
            }
        }
    }
    func testMagePushesEitherTeamWithOneAPSelectMageAfterTurnChanges() throws {
        for caster in Player.allCases {
            for pushed in Player.allCases {
                let before = try Anim01Fixture.state(caster: caster, pushedOwner: pushed, capture: false, ap: 1)
                let outcome = GameEngine.apply(before, Anim01Fixture.action)
                XCTAssertTrue(outcome.success)
                XCTAssertNotEqual(outcome.state.current, caster)
                XCTAssertEqual(HeroVoiceCue.make(before: before, action: Anim01Fixture.action, outcome: outcome)?.key, "voice-mage-skill")
            }
        }
    }
    func testWarriorAndRogueSuccessfulSkillsHaveOwnLines() throws {
        let warrior = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...O...\n.......\n.......\n...H...\n.......\n...X...\n.......", classOne: .warrior, manaOne: 4, ap: 2)
        let bastion = GameAction.castBastion(Point(2,3),Point(4,3)), w = GameEngine.apply(warrior,bastion)
        XCTAssertTrue(w.success); XCTAssertEqual(HeroVoiceCue.make(before: warrior, action: bastion, outcome: w)?.key,"voice-warrior-skill")
        let rogue = try GameSetup.fromDiagram(config: .board(size: 7), diagram: "...O...\n.......\n.......\n...Ho..\n.......\n...X...\n.......", classOne: .rogue, manaOne: 4, ap: 2)
        let swap = GameAction.castSwap(Point(4,3)), r = GameEngine.apply(rogue,swap)
        XCTAssertTrue(r.success); XCTAssertEqual(HeroVoiceCue.make(before: rogue, action: swap, outcome: r)?.key,"voice-rogue-skill")
    }
    func testIllegalAndOrdinaryActionsNeverSpeak() throws {
        let before = try Anim01Fixture.state(capture: false)
        for action in [GameAction.castMagicHand(Point(3,3),.up), .castMagicHand(Point(4,3),.invalid), .summonHero(Point(0,0)), .placeSoldier(Point(0,0)), .endTurn] {
            let outcome = GameEngine.apply(before,action)
            XCTAssertNil(HeroVoiceCue.make(before: before, action: action, outcome: outcome))
        }
    }
}
