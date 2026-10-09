import SwiftUI
import TacticalGoVisuals

/// Only explicitly selected packs enter the game. A manifest is not Owner approval.
@MainActor struct GameVisualAssets {
    let pack: VisualPack
    private let images: [String: UIImage]
    let diagnostic: String?
    enum LoadError: Error { case missing(String), dimensions(String), alpha(String) }

    static var originalPack: VisualPack {
        VisualPack(id: "original-a0", heroes: Dictionary(uniqueKeysWithValues: ["warrior", "mage", "rogue"].map {
            ($0, HeroAssets(portrait: SpriteAsset(name: $0, pixelWidth: 512, pixelHeight: 512),
                token: SpriteAsset(name: "token-" + $0, pixelWidth: 512, pixelHeight: 512, anchorY: 0.663265306122449)))
        }))
    }
    static let original: Self = try! load(originalPack)
    static func load(_ pack: VisualPack) throws -> Self {
        try pack.validate()
        var images: [String: UIImage] = [:]
        // Resolve the entire pack first: no half-new/half-old art after an import failure.
        for asset in pack.assets {
            guard let image = UIImage(named: asset.name), let cg = image.cgImage else { throw LoadError.missing(asset.name) }
            guard cg.width == asset.pixelWidth, cg.height == asset.pixelHeight else { throw LoadError.dimensions(asset.name) }
            if asset.requiresAlpha {
                guard [.first, .last, .premultipliedFirst, .premultipliedLast].contains(cg.alphaInfo) else { throw LoadError.alpha(asset.name) }
            }
            images[asset.name] = image
        }
        return Self(pack: pack, images: images, diagnostic: nil)
    }
    static func selecting(_ pack: VisualPack) -> Self {
        do { return try load(pack) }
        catch {
            let old = original
            return Self(pack: old.pack, images: old.images, diagnostic: "素材包拒絕：\(error)")
        }
    }
    func image(_ asset: SpriteAsset) -> UIImage { images[asset.name]! }
    func portrait(_ hero: String) -> UIImage { image(pack.heroes[hero]!.portrait) }

    #if DEBUG
    static func connectionFixture(invalid: Bool) -> Self {
        let source = originalPack
        var heroes = source.heroes
        if invalid {
            heroes["warrior"] = HeroAssets(portrait: source.heroes["warrior"]!.portrait,
                token: SpriteAsset(name: "missing-visual-fixture", pixelWidth: 512, pixelHeight: 512))
        }
        return selecting(VisualPack(id: "a0-interface-fixture", heroes: heroes))
    }
    #endif
}

struct AnchoredSprite: View {
    let asset: SpriteAsset
    let visuals: GameVisualAssets
    let radius: CGFloat
    var body: some View {
        let frame = asset.placement(radius: Double(radius))
        Image(uiImage: visuals.image(asset)).resizable().interpolation(.high)
            .frame(width: frame.width, height: frame.height)
            .offset(x: frame.dx, y: frame.dy)
    }
}
