import XCTest
@testable import TacticalGoVisuals

/// Expected mapping is the type scale chosen for in-game text.
/// Point sizes are the published Large (default) Dynamic Type sizes, not values read back from production.
final class GameTypeScaleTests: XCTestCase {
    /// Human Interface Guidelines Dynamic Type sizes at the Large content size.
    private let largePointSize: [GameTextStyleName: Double] = [
        .title2: 22,
        .body: 17,
        .caption: 12
    ]

    func test_type_scale_maps_each_role_and_emphasis_to_the_chosen_spec() {
        let expected: [GameTextSpec] = [
            GameTextSpec(role: .title, emphasis: .regular, style: .title2, weight: .semibold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .title, emphasis: .strong, style: .title2, weight: .bold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .title, emphasis: .display, style: .title2, weight: .black, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .body, emphasis: .regular, style: .body, weight: .regular, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .body, emphasis: .strong, style: .body, weight: .semibold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .body, emphasis: .display, style: .body, weight: .bold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .caption, emphasis: .regular, style: .caption, weight: .regular, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .caption, emphasis: .strong, style: .caption, weight: .semibold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .caption, emphasis: .display, style: .caption, weight: .bold, design: .standard, monospacedDigits: false, wraps: true, tracking: 0),
            GameTextSpec(role: .numeric, emphasis: .regular, style: .body, weight: .regular, design: .rounded, monospacedDigits: true, wraps: true, tracking: 0),
            GameTextSpec(role: .numeric, emphasis: .strong, style: .body, weight: .bold, design: .rounded, monospacedDigits: true, wraps: true, tracking: 0),
            GameTextSpec(role: .numeric, emphasis: .display, style: .title2, weight: .bold, design: .rounded, monospacedDigits: true, wraps: true, tracking: 0)
        ]
        XCTAssertEqual(expected.count, GameTextRole.allCases.count * GameTextEmphasis.allCases.count)
        for spec in expected {
            XCTAssertEqual(GameTypeScale.spec(spec.role, emphasis: spec.emphasis), spec)
        }
        let styles = Set(expected.map(\.style))
        XCTAssertEqual(styles, Set([GameTextStyleName.title2, .body, .caption]))
    }

    func test_type_scale_hierarchy_at_published_large_sizes() {
        let title = pointSize(.title)
        let body = pointSize(.body)
        let caption = pointSize(.caption)
        XCTAssertGreaterThan(title, body)
        XCTAssertGreaterThan(body, caption)
        XCTAssertEqual(title, 22)
        XCTAssertEqual(body, 17)
        XCTAssertEqual(caption, 12)
        XCTAssertEqual(pointSize(.numeric), body)
        XCTAssertGreaterThan(pointSize(.numeric, emphasis: .display), pointSize(.numeric))
        XCTAssertEqual(GameTypeScale.spec(.numeric).design, .rounded)
        XCTAssertTrue(GameTypeScale.spec(.numeric).monospacedDigits)
        XCTAssertFalse(GameTypeScale.spec(.body).monospacedDigits)
        XCTAssertEqual(GameTypeScale.spec(.title, emphasis: .display).weight, .black)
        XCTAssertEqual(GameTypeScale.spec(.title, emphasis: .regular).weight, .semibold)
    }

    func test_body_role_uses_the_style_that_grows_from_17_to_53() {
        // WWDC24 session 10074: .body is 17pt at the default size and 53pt at accessibility XXXL (AX5).
        XCTAssertEqual(GameTypeScale.spec(.body).style, .body)
        XCTAssertEqual(largePointSize[.body], 17)
        XCTAssertEqual(accessibilityXXXLBodyPointSize, 53)
    }

    func test_dynamic_type_ladder_names_the_twelve_apple_categories() {
        XCTAssertEqual(GameTypeScale.categoryNames, [
            "xSmall", "small", "medium", "large", "xLarge", "xxLarge", "xxxLarge",
            "accessibilityMedium", "accessibilityLarge", "accessibilityExtraLarge",
            "accessibilityExtraExtraLarge", "accessibilityExtraExtraExtraLarge"
        ])
    }

    func test_reflow_starts_at_xlarge_and_vertical_stack_starts_at_accessibility() {
        XCTAssertEqual(GameTypeScale.needsReflow(named: "large"), false)
        XCTAssertEqual(GameTypeScale.stacksVertically(named: "large"), false)
        XCTAssertEqual(GameTypeScale.needsReflow(named: "xLarge"), true)
        XCTAssertEqual(GameTypeScale.stacksVertically(named: "xLarge"), false)
        XCTAssertEqual(GameTypeScale.needsReflow(named: "xxxLarge"), true)
        XCTAssertEqual(GameTypeScale.stacksVertically(named: "xxxLarge"), false)
        XCTAssertEqual(GameTypeScale.needsReflow(named: "accessibilityMedium"), true)
        XCTAssertEqual(GameTypeScale.stacksVertically(named: "accessibilityMedium"), true)
        XCTAssertEqual(GameTypeScale.needsReflow(named: "accessibilityExtraExtraExtraLarge"), true)
        XCTAssertEqual(GameTypeScale.stacksVertically(named: "accessibilityExtraExtraExtraLarge"), true)
    }

    func test_unknown_content_size_category_does_not_choose_a_layout() {
        XCTAssertNil(GameTypeScale.needsReflow(named: ""))
        XCTAssertNil(GameTypeScale.stacksVertically(named: ""))
        XCTAssertNil(GameTypeScale.needsReflow(named: "XXXL"))
        XCTAssertNil(GameTypeScale.stacksVertically(named: "accessibilityXXXL"))
        XCTAssertNil(GameTypeScale.needsReflow(named: "Large"))
        XCTAssertNil(GameTypeScale.stacksVertically(named: "x-large"))
    }

    func test_every_named_category_has_a_layout_decision() {
        let verticalFrom = "accessibilityMedium"
        var seenVertical = false
        for name in GameTypeScale.categoryNames {
            if name == verticalFrom { seenVertical = true }
            XCTAssertEqual(GameTypeScale.stacksVertically(named: name), seenVertical, name)
            XCTAssertNotNil(GameTypeScale.needsReflow(named: name), name)
        }
        XCTAssertTrue(seenVertical)
    }

    private func pointSize(_ role: GameTextRole, emphasis: GameTextEmphasis = .regular) -> Double {
        let style = GameTypeScale.spec(role, emphasis: emphasis).style
        guard let size = largePointSize[style] else {
            XCTFail("missing published Large size for \(style)")
            return -1
        }
        return size
    }

    /// Published .body size at accessibilityExtraExtraExtraLarge. Not produced by GameTypeScale.
    private let accessibilityXXXLBodyPointSize = 53.0
}
