import XCTest
import TacticalGoVisuals

final class Anim01GeometryTests: XCTestCase {
    func testFittedBoardAspectPitchAndBoundsAtBothReviewSizes() {
        for (width, height, count) in [(390.0, 440.0, 7), (320.0, 220.0, 9)] {
            let fit = Anim01Geometry(width: width, height: height, boardSize: count)
            XCTAssertEqual(fit.width / fit.height, 1024.0 / 1152.0, accuracy: 1e-8)
            XCTAssertGreaterThanOrEqual(fit.x, 0); XCTAssertGreaterThanOrEqual(fit.y, 0)
            XCTAssertLessThanOrEqual(fit.width, width); XCTAssertLessThanOrEqual(fit.height, height)
            XCTAssertEqual(fit.pitch, min(fit.width * 0.74, fit.height * 0.65) / Double(count - 1))
            XCTAssertTrue(fit.contains(x: fit.x + fit.width / 2, y: fit.y + fit.height / 2))
            XCTAssertFalse(fit.contains(x: fit.x - 0.1, y: fit.y + fit.height / 2))
        }
    }
}
