import XCTest
import TacticalGoCore
import TacticalGoContent

/// Review items 4–5 (PRIEST-S2-P0): the sacrifice preview must state the whole trade (what is given up and placed,
/// captures, which group) and its hints must not mislead at boundaries (split, merge, edge eye, false eye).
final class PriestSacrificeInsightTests: XCTestCase {
    private func board(_ rows: [String], size: Int = 9, ap: Int = 2, mana: Int = 6) throws -> GameState {
        try GameSetup.fromDiagram(config: TacticalHints.updatedConfig(size: size), diagram: rows.joined(separator: "\n"),
                                  classOne: .priest, classTwo: .mage, current: .one, manaOne: mana, manaTwo: 3, ap: ap, ply: 9)
    }

    func testLessonPreviewNamesTheTradeAndTheCommanderGroup() throws {
        let start = try PriestSanctumPractice.seven.state()
        let sanctum = try XCTUnwrap(PriestSacrificeInsight(start, PriestSanctumPractice.seven.action))
        XCTAssertEqual(sanctum.summary, "犧牲 B6→補 D7 · 主將氣 1→3")
        XCTAssertEqual(sanctum.group, .commander); XCTAssertEqual(sanctum.captured, 0)
        let offering = try XCTUnwrap(PriestSacrificeInsight(start, .castOffering(PriestSanctumPractice.seven.sacrifice)))
        XCTAssertEqual(offering.summary, "犧牲 B6 · 主將氣 1→2", "touches two white stones: no eye claimed")
        XCTAssertNil(PriestSacrificeInsight(start, .placeSoldier(Point(5,5))))
    }

    func testCapturesFromTheReinforcementAreShown() throws {
        // White F7 has only E7 left; Sanctum's stone on E7 (next to the commander E8) captures it.
        // Row 7 (y=6): E7 empty, F7 White, G7 Black; F6 and F8 Black around F7.
        let s = try board([".........", "....O....", ".........", ".........", ".........",
                           ".....x...", ".....ox..", "...HXx...", "...x....."])
        XCTAssertEqual(s.board.liberties(at: Point(5,6)), Set([Point(4,6)]))
        let insight = try XCTUnwrap(PriestSacrificeInsight(s, .castSanctum(sacrifice: Point(3,8), destination: Point(4,6))))
        XCTAssertEqual(insight.captured, 1)
        XCTAssertTrue(insight.summary.contains("提 1"), insight.summary)
        XCTAssertTrue(insight.summary.hasPrefix("犧牲 D9→補 E7 · 主將氣"), insight.summary)
    }

    func testCuttingAGroupSaysSoAndReportsTheCommanderPart() throws {
        // Priest D5 – soldier E5 – commander F5 in a bare line: giving up E5 leaves two groups.
        let s = try board([".........", "....O....", ".........", ".........", "...HxX...",
                           ".........", ".........", ".........", "........."])
        let insight = try XCTUnwrap(PriestSacrificeInsight(s, .castOffering(Point(4,4))))
        XCTAssertTrue(insight.split)
        XCTAssertEqual(insight.group, .commander)
        XCTAssertEqual(insight.libertiesBefore, 8, "the whole line before")
        XCTAssertEqual(insight.libertiesAfter, 4, "the commander alone after")
        XCTAssertEqual(insight.summary, "犧牲 E5 · 主將氣 8→4・棋群分開")
    }

    func testJoiningGroupsSaysSoAndCountsTheJoinedGroup() throws {
        // Commander E8 and the priest's group (D6, E6, C6) are apart; Sanctum's stone on E7 joins them.
        let s = try board([".........", "....O....", ".........", ".........", ".........",
                           "..xHx....", ".........", "....X....", "........."])
        let insight = try XCTUnwrap(PriestSacrificeInsight(s, .castSanctum(sacrifice: Point(2,5), destination: Point(4,6))))
        XCTAssertTrue(insight.merged)
        XCTAssertFalse(insight.split)
        XCTAssertEqual(insight.group, .commander)
        XCTAssertEqual(insight.libertiesBefore, 4, "the commander's own group before")
        XCTAssertTrue(insight.summary.hasSuffix("・連成一群"), insight.summary)
    }

    func testEdgeEyeAndInteriorFalseEyeAreDistinguished() throws {
        // Bottom edge: C7 vacated, sides and both diagonals own → an eye.
        let edge = try board([".......", "...O...", ".......", ".......", "ooooo..", "xxHxo..", ".Xxxo.."], size: 7, ap: 1, mana: 4)
        let real = try XCTUnwrap(PriestSacrificeInsight(edge, .castOffering(Point(2,6))))
        XCTAssertEqual(real.eye, .likely); XCTAssertTrue(real.summary.contains("・成眼"), real.summary)
        // Interior: E5 vacated, four own sides, but two diagonals are White → possibly a false eye, never "成眼".
        let inner = try board([".........", "....O....", ".........", "...oHo...", "...xxx...",
                               "...xXx...", ".........", ".........", "........."])
        let fake = try XCTUnwrap(PriestSacrificeInsight(inner, .castOffering(Point(4,4))))
        XCTAssertEqual(fake.eye, .possiblyFalse)
        XCTAssertTrue(fake.summary.contains("・可能假眼"), fake.summary)
        XCTAssertFalse(fake.summary.contains("成眼"))
    }
}
