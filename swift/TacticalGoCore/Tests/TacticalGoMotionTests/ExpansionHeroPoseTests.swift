import XCTest
import TacticalGoMotion
final class ExpansionHeroPoseTests: XCTestCase {
    func testRogueAnticipationReleaseAndRecoveryShareReceiptLandTime() {
        let coil = ExpansionHeroPose.rogue(at:0.12),release = ExpansionHeroPose.rogue(at:0.16),contact = ExpansionHeroPose.rogue(at:0.36)
        XCTAssertLessThan(coil.body,0); XCTAssertGreaterThan(release.body,0)
        XCTAssertLessThan(coil.hand,0); XCTAssertGreaterThan(release.hand,0)
        XCTAssertGreaterThan(contact.bodyY,release.bodyY)
        XCTAssertEqual(ExpansionHeroPose.rogue(at:0.70),.rest)
    }
    func testPriestHandBookAndHeadMoveIndependentlyWithClothRecovery() {
        let prayer = ExpansionHeroPose.priest(at:0.20),reach = ExpansionHeroPose.priest(at:0.32)
        XCTAssertGreaterThan(prayer.head,0); XCTAssertLessThan(reach.head,0)
        XCTAssertLessThan(prayer.book,0); XCTAssertLessThan(prayer.bookY,0)
        XCTAssertGreaterThan(prayer.handX,0); XCTAssertLessThan(reach.handX,0)
        XCTAssertEqual(ExpansionHeroPose.priest(at:0.84).body,0)
        XCTAssertNotEqual(ExpansionHeroPose.priest(at:0.84).cloth,0)
        XCTAssertEqual(ExpansionHeroPose.priest(at:0.94),.rest)
    }
    func testReducedNonFiniteAndOutOfRangeAreExactOriginalRest() {
        for t in [-1.0,0,0.2,0.58,0.94,1.5,Double.nan,Double.infinity] {
            XCTAssertEqual(ExpansionHeroPose.rogue(at:t,reduced:true),.rest)
            XCTAssertEqual(ExpansionHeroPose.priest(at:t,reduced:true),.rest)
        }
        for t in [-1.0,1.5,Double.nan,Double.infinity] {
            XCTAssertEqual(ExpansionHeroPose.rogue(at:t),.rest); XCTAssertEqual(ExpansionHeroPose.priest(at:t),.rest)
        }
    }
}
