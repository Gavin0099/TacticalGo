import XCTest
import TacticalGoCore
import TacticalGoMotion
import TacticalGoContent

final class ExpansionFeedbackTests: XCTestCase {
    func testConfirmedClassFixturesRestOutsideClipAndNeverDeformUnrelatedCells() throws {
        for fixture in ExpansionPractice.allCases {
            let before = try fixture.session().state, result = GameEngine.apply(before,fixture.action)
            let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:result,current:result.state))
            let targets = p.transfers.map(\.to) + p.placements + p.sacrifices
            XCTAssertFalse(targets.isEmpty)
            for target in targets {
                for t in [-0.01, p.duration, Double.nan, Double.infinity] {
                    XCTAssertEqual(p.tokenFrame(at:target,time:t,moving:true),.rest)
                }
                XCTAssertEqual(p.tokenFrame(at:target,time:p.arrival-0.01,moving:true,reduced:true),.rest)
            }
            XCTAssertEqual(p.tokenFrame(at:Point(8,8),time:p.arrival),.rest)
            if fixture == .rogue {
                let first = try XCTUnwrap(p.transfers.first { $0.from == Point(5,4) && $0.piece.kind == .soldier })
                XCTAssertEqual(p.tokenFrame(at:first.to,time:(p.moveStart+p.arrival)/2,moving:true).tilt,0,accuracy:0.0001,"First pawn rests after the first exchange")
            }
            XCTAssertEqual(p.after,result.state,"Presentation never changes the immutable outcome")
        }
    }
    func testWarriorImpactHoldsThenSettlesMageBracesAndOfferingDoesNotReturn() throws {
        for fixture in [ExpansionPractice.warrior,.mage,.priest] {
            let before = try fixture.session().state, result = GameEngine.apply(before,fixture.action)
            let p = try XCTUnwrap(ExpansionPresentation.make(before:before,action:fixture.action,outcome:result,current:result.state))
            let target = try XCTUnwrap((p.transfers.map(\.to)+p.sacrifices).first)
            if fixture == .warrior {
                let hit = p.tokenFrame(at:target,time:p.arrival)
                XCTAssertGreaterThan(hit.scaleX,1); XCTAssertLessThan(hit.scaleY,1)
                XCTAssertEqual(hit,p.tokenFrame(at:target,time:p.arrival+0.03))
                XCTAssertEqual(p.tokenFrame(at:target,time:p.arrival+0.18),.rest)
            } else if fixture == .mage {
                XCTAssertLessThan(p.tokenFrame(at:target,time:0.44,moving:true).scaleY,1)
                XCTAssertLessThan(p.tokenFrame(at:target,time:p.arrival).scaleY,1)
            } else {
                let beforeFade = p.tokenFrame(at:target,time:p.release)
                let halfway = p.tokenFrame(at:target,time:(p.release+p.arrival)/2)
                XCTAssertEqual(beforeFade.opacity,1); XCTAssertLessThan(halfway.opacity,1)
                XCTAssertLessThan(halfway.lift,0); XCTAssertEqual(p.tokenFrame(at:target,time:p.arrival).opacity,0)
                XCTAssertNil(p.after.board[target]); XCTAssertTrue(p.placements.isEmpty)
            }
        }
    }
    func testCaptureTailHasExactBoundaryAndReducedMotionCannotRecreateCapturedPiece() {
        XCTAssertEqual(CaptureDissolveFrame.sample(at:0.5,start:0.5).opacity,1)
        XCTAssertEqual(CaptureDissolveFrame.sample(at:0.68,start:0.5).opacity,0)
        XCTAssertEqual(CaptureDissolveFrame.sample(at:.nan,start:0.5).opacity,0)
        XCTAssertEqual(CaptureDissolveFrame.sample(at:0.5,start:0.5,reduced:true).opacity,0)
        let pawn = CaptureDissolveFrame.sample(at:0.6,start:0.5), commander = CaptureDissolveFrame.sample(at:0.6,start:0.5,commander:true)
        XCTAssertGreaterThan(commander.scale,pawn.scale); XCTAssertLessThan(commander.lift,pawn.lift)
    }
    // Independently authored one-liberty commander diagrams; D4 closes the final liberty.
    private func state(winner: Player, lastTurn: Bool = false) throws -> GameState {
        var config = RuleConfig.board(size: 7); config.expansionSkills = true
        if lastTurn { config.maxPlies = 1 }
        let diagram = winner == .one
            ? ".......\n...x...\n..xOx..\n.......\n.......\n...X...\n......."
            : ".......\n...o...\n..oXo..\n.......\n.......\n...O...\n......."
        return try GameSetup.fromDiagram(config: config, diagram: diagram, classOne: .warrior,
                                         classTwo: .mage, current: winner, ap: 2)
    }
    func testEitherWinnerUsesHumanPerspectiveAndLocalMatchKeepsNeutralVictory() throws {
        for winner in [Player.one, .two] {
            let before = try state(winner: winner), action = GameAction.placeSoldier(Point(3, 3))
            let result = GameEngine.apply(before, action)
            XCTAssertEqual(result.state.status, .won); XCTAssertEqual(result.state.winner, winner)
            let receipt = try XCTUnwrap(ExpansionPresentation.make(before: before, action: action, outcome: result, current: result.state))
            XCTAssertEqual(receipt.terminalCue(computer: winner), "defeat")
            XCTAssertEqual(receipt.terminalCue(computer: winner.opponent), "victory")
            XCTAssertEqual(receipt.terminalCue(computer: nil), "victory")
        }
    }
    func testLastTurnDrawAndOrdinaryOrRejectedActionsDoNotInventVictory() throws {
        let finalTurn = try state(winner: .one, lastTurn: true)
        let draw = GameEngine.apply(finalTurn, .endTurn)
        XCTAssertEqual(draw.state.status, .drawn)
        let ending = try XCTUnwrap(ExpansionPresentation.make(before: finalTurn, action: .endTurn, outcome: draw, current: draw.state))
        for computer in [Player.one, .two] { XCTAssertEqual(ending.terminalCue(computer: computer), "draw") }
        XCTAssertEqual(ending.terminalCue(computer: nil), "draw")
        let before = try state(winner: .one), ordinary = GameAction.placeSoldier(Point(0, 0))
        let result = GameEngine.apply(before, ordinary)
        XCTAssertEqual(result.state.status, .ongoing)
        let receipt = try XCTUnwrap(ExpansionPresentation.make(before: before, action: ordinary, outcome: result, current: result.state))
        XCTAssertNil(receipt.terminalCue(computer: .two))
        let invalid = GameAction.placeSoldier(Point(3, 2)), rejected = GameEngine.apply(before, invalid)
        XCTAssertFalse(rejected.success)
        XCTAssertNil(ExpansionPresentation.make(before: before, action: invalid, outcome: rejected, current: before))
    }
    func testOfferingHasOnlyUpwardMotionAndFiniteShortTail() {
        let release = 0.20, arrival = 0.58
        XCTAssertEqual(OfferingDissolveFrame.sample(at: release - 0.01, release: release, arrival: arrival).opacity, 0)
        let active = [0.30, 0.45, 0.60, 0.75].map { OfferingDissolveFrame.sample(at: $0, release: release, arrival: arrival) }
        XCTAssertTrue(active.allSatisfy { $0.opacity > 0 && $0.opacity <= 0.9 && $0.spread >= 0 && $0.lift > 0 && $0.lift < 0.55 })
        XCTAssertEqual(active.map(\.lift), active.map(\.lift).sorted())
        XCTAssertEqual(OfferingDissolveFrame.sample(at: arrival + 0.24, release: release, arrival: arrival).opacity, 0)
        XCTAssertEqual(OfferingDissolveFrame.sample(at: .nan, release: release, arrival: arrival).opacity, 0)
        XCTAssertEqual(OfferingDissolveFrame.sample(at: 0.4, release: arrival, arrival: release).opacity, 0)
    }
    func testSwapArcKeepsEndpointsAndSeparatesBothUnitsAtMidpoint() {
        for (dx,dy) in [(40.0,0.0),(0.0,40.0),(28.0,28.0)] {
            for t in [0.0,1.0] {
                let end = RogueSwapArc.offset(dx: dx, dy: dy, progress: t, pitch: 40)
                XCTAssertEqual(end.x,0); XCTAssertEqual(end.y,0)
            }
            let first = RogueSwapArc.offset(dx: dx, dy: dy, progress: 0.5, pitch: 40)
            let second = RogueSwapArc.offset(dx: -dx, dy: -dy, progress: 0.5, pitch: 40)
            XCTAssertEqual(first.x,-second.x,accuracy:0.001); XCTAssertEqual(first.y,-second.y,accuracy:0.001)
            XCTAssertGreaterThan(hypot(first.x-second.x,first.y-second.y),24,"Midpoint separation exceeds 0.6 cell pitch")
        }
        let invalid = RogueSwapArc.offset(dx: 0, dy: 0, progress: .nan, pitch: 40)
        XCTAssertEqual(invalid.x,0); XCTAssertEqual(invalid.y,0)
    }
    func testChainMakesTwoExchangesAndKeepsTheSecondPawnWaiting() {
        let hero=(x:0.0,y:0.0), first=(x:40.0,y:0.0),second=(x:40.0,y:-40.0)
        let wait = RogueChainPath.position(from:second,to:first,via:first,progress:0.25,pitch:40,hero:false,firstEnemy:false)
        XCTAssertEqual(wait.x,second.x); XCTAssertEqual(wait.y,second.y)
        let halfwayHero = RogueChainPath.position(from:hero,to:second,via:first,progress:0.5,pitch:40,hero:true,firstEnemy:false)
        let clearedFirst = RogueChainPath.position(from:first,to:hero,via:first,progress:0.5,pitch:40,hero:false,firstEnemy:true)
        XCTAssertEqual(halfwayHero.x,first.x); XCTAssertEqual(halfwayHero.y,first.y)
        XCTAssertEqual(clearedFirst.x,hero.x); XCTAssertEqual(clearedFirst.y,hero.y)
        for t in [0.25,0.75] {
            let h = RogueChainPath.position(from:hero,to:second,via:first,progress:t,pitch:40,hero:true,firstEnemy:false)
            let pawn = t < 0.5
                ? RogueChainPath.position(from:first,to:hero,via:first,progress:t,pitch:40,hero:false,firstEnemy:true)
                : RogueChainPath.position(from:second,to:first,via:first,progress:t,pitch:40,hero:false,firstEnemy:false)
            XCTAssertGreaterThan(hypot(h.x-pawn.x,h.y-pawn.y),24)
        }
    }
}
