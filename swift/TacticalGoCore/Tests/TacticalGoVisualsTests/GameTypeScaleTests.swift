import XCTest
@testable import TacticalGoVisuals

final class GameTypeScaleTests: XCTestCase {
    func test_spec_for_each_role_matches_published_scale() {
        let title = GameTypeScale.spec(for: .title)
        XCTAssertEqual(title.basePointSize, 20)
        XCTAssertEqual(title.weight, .heavy)
        XCTAssertEqual(title.relativeTo, .title3)
        XCTAssertEqual(title.largeStylePointSize, 20)

        let body = GameTypeScale.spec(for: .body)
        XCTAssertEqual(body.basePointSize, 14)
        XCTAssertEqual(body.weight, .regular)
        XCTAssertEqual(body.relativeTo, .body)
        XCTAssertEqual(body.largeStylePointSize, 17)

        let caption = GameTypeScale.spec(for: .caption)
        XCTAssertEqual(caption.basePointSize, 11)
        XCTAssertEqual(caption.weight, .medium)
        XCTAssertEqual(caption.relativeTo, .caption2)
        XCTAssertEqual(caption.largeStylePointSize, 11)

        let numeric = GameTypeScale.spec(for: .numeric)
        XCTAssertEqual(numeric.basePointSize, 12)
        XCTAssertEqual(numeric.weight, .bold)
        XCTAssertEqual(numeric.relativeTo, .caption)
        XCTAssertEqual(numeric.largeStylePointSize, 12)

        XCTAssertEqual(Set(GameTextRole.allCases), Set([.title, .body, .caption, .numeric]))
    }

    func test_scaledPointSize_atLarge_returns_base_and_half_scale_is_linear() {
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 20, currentStylePointSize: 20), 10)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 20, currentStylePointSize: 50), 25)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .title, currentStylePointSize: 20), 20)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .body, currentStylePointSize: 17), 14)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .caption, currentStylePointSize: 11), 11)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .numeric, currentStylePointSize: 12), 12)
    }

    func test_scaledPointSize_atAccessibilityXXXL_uses_hig_style_sizes() {
        // HIG accessibility extra-extra-extra-large column, used as the current style size:
        // title3 55, body 53, caption 43, caption2 40.
        // Expected points are hand products of the published base and that column, not a second lookup table.
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .title, currentStylePointSize: 55), 55, accuracy: 1e-9)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .body, currentStylePointSize: 53), 43.64705882352941, accuracy: 1e-9)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .numeric, currentStylePointSize: 43), 43, accuracy: 1e-9)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .caption, currentStylePointSize: 40), 40, accuracy: 1e-9)
        let sizes = [
            GameTypeScale.scaledPointSize(role: .title, currentStylePointSize: 55),
            GameTypeScale.scaledPointSize(role: .body, currentStylePointSize: 53),
            GameTypeScale.scaledPointSize(role: .numeric, currentStylePointSize: 43),
            GameTypeScale.scaledPointSize(role: .caption, currentStylePointSize: 40)
        ]
        XCTAssertEqual(sizes, sizes.sorted(by: >))
        XCTAssertEqual(sizes.count, Set(sizes.map { ($0 * 1_000_000).rounded() }).count)
    }

    func test_scaledPointSize_invalid_style_size_returns_base_or_zero() {
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 20, currentStylePointSize: 0), 10)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 20, currentStylePointSize: -4), 10)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 0, currentStylePointSize: 40), 10)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: 10, largeStylePointSize: 20, currentStylePointSize: .nan), 10)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: .infinity, largeStylePointSize: 20, currentStylePointSize: 40), 0)
        XCTAssertEqual(GameTypeScale.scaledPointSize(basePointSize: .nan, largeStylePointSize: 20, currentStylePointSize: 40), 0)
        XCTAssertEqual(GameTypeScale.scaledPointSize(role: .caption, currentStylePointSize: 0), 11)
    }

    func test_role_order_is_title_body_numeric_caption() {
        let sizes = [GameTextRole.title, .body, .numeric, .caption].map { GameTypeScale.spec(for: $0).basePointSize }
        XCTAssertEqual(sizes, [20, 14, 12, 11])
        for pair in zip(sizes, sizes.dropFirst()) {
            XCTAssertGreaterThan(pair.0, pair.1)
        }
    }
}
