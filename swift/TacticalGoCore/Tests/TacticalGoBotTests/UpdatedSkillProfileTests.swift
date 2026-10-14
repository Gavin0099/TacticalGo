import XCTest
import TacticalGoCore
import TacticalGoBot

final class UpdatedSkillProfileTests: XCTestCase {
    func testUpdatedMagePlanMatchesPlayableSkillsAndCompletesLegalTurn() throws {
        var c = RuleConfig.board(size:7);c.expansionSkills = true;c.bastionScope = .connectedGroup;c.experimentalFriendlyRedeploy = true
        let s = try GameSetup.fromDiagram(config:c,diagram:".......\n...O...\n.......\n..xHx..\n.......\n...X...\n.......",classOne:.mage,classTwo:.warrior,manaOne:2,manaTwo:2,ap:2)
        let p = try XCTUnwrap(BotPlanner.planTurn(s,limits:.easy,difficulty:.easy))
        var current = s
        for a in p.actions {
            if case .castMagicHand = a { XCTFail("New Mage's ordinary card is Redeploy") }
            let o = GameEngine.apply(current,a);XCTAssertTrue(o.success);current = o.state
        }
        XCTAssertTrue(current.current != s.current || current.status != .ongoing)
        XCTAssertEqual(s.config,c)
    }
}
