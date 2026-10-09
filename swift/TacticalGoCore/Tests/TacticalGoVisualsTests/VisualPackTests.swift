import XCTest
@testable import TacticalGoVisuals

final class VisualPackTests: XCTestCase {
    private func heroes(_ token: SpriteAsset? = nil) -> [String: HeroAssets] {
        Dictionary(uniqueKeysWithValues: ["warrior", "mage", "rogue"].map {
            ($0, HeroAssets(portrait: SpriteAsset(name: $0, pixelWidth: 512, pixelHeight: 512),
                token: token ?? SpriteAsset(name: "token-" + $0, pixelWidth: 512, pixelHeight: 512)))
        })
    }
    func testManifestRoundTripWithBoardAndSeparateFactionSprites() throws {
        let pack = VisualPack(id: "v2-test", boardSurface: SpriteAsset(name: "board-v2", pixelWidth: 1024, pixelHeight: 1152),
            blackSoldier: SpriteAsset(name: "soldier-black-v2", pixelWidth: 256, pixelHeight: 256),
            whiteSoldier: SpriteAsset(name: "soldier-white-v2", pixelWidth: 256, pixelHeight: 256), heroes: heroes())
        let decoded = try JSONDecoder().decode(VisualPack.self, from: JSONEncoder().encode(pack))
        try decoded.validate(); XCTAssertEqual(decoded, pack); XCTAssertEqual(decoded.assets.count, 9)
    }
    func testUnknownSchemaProjectionAndIncompleteClassesAreRejected() {
        XCTAssertThrowsError(try VisualPack(schemaVersion: 2, id: "test", heroes: heroes()).validate())
        XCTAssertThrowsError(try VisualPack(id: "test", projection: "top-down", heroes: heroes()).validate())
        var missing = heroes(); missing.removeValue(forKey: "mage")
        XCTAssertThrowsError(try VisualPack(id: "test", heroes: missing).validate())
    }
    func testInvalidSizesAnchorsAndPathNamesAreRejected() {
        let cases = [SpriteAsset(name: "../image", pixelWidth: 512, pixelHeight: 512),
            SpriteAsset(name: "zero", pixelWidth: 0, pixelHeight: 512),
            SpriteAsset(name: "large", pixelWidth: 4097, pixelHeight: 512),
            SpriteAsset(name: "anchor", pixelWidth: 512, pixelHeight: 512, anchorY: 1.01),
            SpriteAsset(name: "nan", pixelWidth: 512, pixelHeight: 512, anchorX: .nan),
            SpriteAsset(name: "scale", pixelWidth: 512, pixelHeight: 512, widthInRadii: 5)]
        for asset in cases { XCTAssertThrowsError(try VisualPack(id: "test", heroes: heroes(asset)).validate(), asset.name) }
    }
    func testConflictingMetadataForSameResourceIsRejected() {
        var h = heroes(); h["mage"] = HeroAssets(portrait: h["mage"]!.portrait,
            token: SpriteAsset(name: "token-warrior", pixelWidth: 256, pixelHeight: 512))
        XCTAssertThrowsError(try VisualPack(id: "test", heroes: h).validate())
    }
    func testRectangularCanvasAnchorUsesHeightAndPreservesAspectRatio() {
        // Reviewed contract example: a 100x200 canvas at 2 radii, anchored at (25%,75%).
        let p = SpriteAsset(name: "example", pixelWidth: 100, pixelHeight: 200, anchorX: 0.25, anchorY: 0.75, widthInRadii: 2).placement(radius: 10)
        XCTAssertEqual(p.width, 20); XCTAssertEqual(p.height, 40)
        XCTAssertEqual(p.dx, 5); XCTAssertEqual(p.dy, -10)
    }
    func testOriginalTokenAnchorRetainsExistingOffset() {
        let p = SpriteAsset(name: "token", pixelWidth: 512, pixelHeight: 512, anchorY: 0.663265306122449).placement(radius: 20)
        XCTAssertEqual(p.width, 49); XCTAssertEqual(p.dx, 0)
        XCTAssertEqual(p.dy, -8, accuracy: 0.000001) // Existing A0 offset is -0.4r.
    }
}
