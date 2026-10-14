import XCTest
import TacticalGoCore
@testable import TacticalGoContent

final class TacticalHintsTests: XCTestCase {
    func testNewProfileAndOriginalDefaultsRemainSeparate() {
        let c = TacticalHints.updatedConfig(size:7)
        XCTAssertEqual(c.bastionScope,.connectedGroup);XCTAssertTrue(c.experimentalFriendlyRedeploy)
        XCTAssertEqual(c.skillManaCost,2);XCTAssertEqual(c.expansionSkillManaCost,4)
        XCTAssertEqual(RuleConfig.board(size:7).bastionScope,.heroAdjacent)
        XCTAssertFalse(RuleConfig.board(size:7).experimentalFriendlyRedeploy)
    }
    func testOpeningHintsAreAll47EmptyPointsAndReadOnly() throws {
        let s = try GameSetup.newGame(config:TacticalHints.updatedConfig(size:7),classOne:.warrior,classTwo:.mage)
        let before = s
        let targets = TacticalHints.targets(s,mode:.soldier,selected:[])
        XCTAssertEqual(targets.count,47)
        XCTAssertTrue(targets.contains(Point(0,0)));XCTAssertTrue(targets.contains(Point(6,6)))
        XCTAssertFalse(targets.contains(Point(3,5)));XCTAssertFalse(targets.contains(Point(3,1)))
        XCTAssertEqual(s,before)
        XCTAssertTrue(TacticalHints.targets(s,mode:.skill,selected:[]).isEmpty)
    }
    func testRedeployGuidesConnectedOwnSourceThenFrontierAndQuota() throws {
        var session = try ExpansionPractice.mage.session(updatedBaseSkills:true)
        let s = session.state
        let first = TacticalHints.targets(s,mode:.skill,selected:[])
        XCTAssertTrue(first.contains(Point(4,5)))
        XCTAssertFalse(first.contains(Point(4,3)),"Enemy soldier cannot be redeployed")
        let second = TacticalHints.targets(s,mode:.skill,selected:[Point(4,5)])
        XCTAssertTrue(second.contains(Point(5,5)))
        XCTAssertFalse(second.contains(Point(8,8)))
        XCTAssertTrue(session.apply(.castFriendlyRedeploy(Point(4,5),Point(5,5))).success)
        XCTAssertEqual(session.state.board[Point(5,5)],Piece(.one,.soldier))
        XCTAssertNil(session.state.board[Point(4,5)])
        XCTAssertTrue(TacticalHints.targets(session.state,mode:.skill,selected:[]).isEmpty)
        XCTAssertTrue(session.undo());XCTAssertEqual(session.state,s)
    }
    func testBastionSecondPointAndReverseOrderAreValidated() throws {
        let s = try ExpansionPractice.warrior.session(updatedBaseSkills:true).state
        let a = Point(5,5),b = Point(6,6)
        XCTAssertEqual(GameEngine.validate(s,.castBastion(a,b)),.none)
        XCTAssertTrue(TacticalHints.targets(s,mode:.skill,selected:[a]).contains(b))
        XCTAssertTrue(TacticalHints.targets(s,mode:.skill,selected:[b]).contains(a))
        XCTAssertFalse(TacticalHints.targets(s,mode:.skill,selected:[a]).contains(a))
        XCTAssertFalse(TacticalHints.targets(s,mode:.skill,selected:[a]).contains(Point(8,0)))
    }
    func testAdvancedOrderAndIllegalPrefix() throws {
        let s = try ExpansionPractice.mage.session(updatedBaseSkills:true).state
        XCTAssertTrue(TacticalHints.targets(s,mode:.advanced,selected:[Point(4,5)]).contains(Point(5,5)))
        XCTAssertTrue(TacticalHints.targets(s,mode:.advanced,selected:[Point(4,3),Point(3,3)]).contains(Point(4,5)))
        XCTAssertTrue(TacticalHints.targets(s,mode:.advanced,selected:[Point(8,8)]).isEmpty)
    }
}
