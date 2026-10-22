import XCTest
@testable import TacticalGoCore
import TacticalGoContent

/// Test-only counterfactual: production setup deliberately rejects cost 3.
/// These handcrafted positions have no opening history; results are affordability/geometry evidence only.
final class PriestCostExperimentTests: XCTestCase {
    private func fixture(_ p: PriestSanctumPractice, cost: Int, mana: Int) throws -> GameState {
        let base = try p.state()
        var config = base.config;config.expansionSkillManaCost = cost
        var s = GameState(config:config,board:base.board,classes:base.classes,
                          mana:[mana,base.mana(of:.two)],summoned:base.heroSummoned)
        s.current=base.current;s.ply=base.ply;s.apRemaining=base.apRemaining
        s.history=base.history;s.seals=base.seals
        return s
    }
    func testCostThreeChangesAffordabilityNotGeometryAndNeverShippingDefault() throws {
        for p in PriestSanctumPractice.allCases {
            let a = try fixture(p,cost:3,mana:3), b = try fixture(p,cost:4,mana:3)
            let lower = GameEngine.apply(a,p.action), normal = GameEngine.apply(b,p.action)
            XCTAssertTrue(lower.success,"\(p)")
            XCTAssertFalse(normal.success);XCTAssertEqual(normal.reason,.notEnoughMana)
            XCTAssertEqual(normal.state,b);XCTAssertTrue(normal.events.isEmpty)
            XCTAssertEqual(lower.state.mana(of:.one),0)
            let funded = GameEngine.apply(try fixture(p,cost:4,mana:4),p.action)
            XCTAssertTrue(funded.success)
            XCTAssertEqual(lower.state.board,funded.state.board)
            XCTAssertEqual(lower.state.status,funded.state.status)
            XCTAssertEqual(lower.state.apRemaining,funded.state.apRemaining)
            print("PRIEST-COST \(p): mana3 cost3=legal cost4=notEnoughMana; funded geometry equal; not balance evidence")
        }
        var candidate=TacticalHints.updatedConfig(size:7);candidate.expansionSkillManaCost=3
        XCTAssertThrowsError(try GameSetup.newGame(config:candidate,classOne:.priest,classTwo:.warrior))
        XCTAssertEqual(TacticalHints.updatedConfig(size:7).expansionSkillManaCost,4)
    }
    func testLowerCostDoesNotMakeTheBadGeometrySafe() throws {
        // These fixtures contain no White hero: the changed shared expansion cost
        // cannot affect the reply action set. Search all ordinary White two-action replies.
        for p in PriestSanctumPractice.allCases {
            let start = try fixture(p,cost:3,mana:3)
            let result = GameEngine.apply(start,p.action)
            XCTAssertTrue(result.success)
            XCTAssertNil(result.state.board.find(.two,.hero))
            var frontier = [result.state]
            var captured = false
            for _ in 0..<2 {
                var next:[GameState] = []
                for state in frontier where state.current == .two && state.status == .ongoing {
                    for action in GameEngine.legalActions(state) {
                        let reply=GameEngine.apply(state,action)
                        if reply.state.winner == .two { captured=true }
                        if reply.state.current == .two && reply.state.status == .ongoing { next.append(reply.state) }
                    }
                }
                frontier=next
            }
            switch p.kind {
            case .onlySanctum, .placementEnough: XCTAssertFalse(captured,"\(p)")
            case .offeringEnough, .nothingSaves: XCTAssertTrue(captured,"\(p)")
            }
        }
    }

}
