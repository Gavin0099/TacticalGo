import SwiftUI
import CryptoKit

/// Debug review only; decode every declared actor/frame before accepting a pack.
@MainActor struct Anim01Assets {
    struct Sprite: Decodable {
        let file: String
        let pixelWidth: Int
        let pixelHeight: Int
        let anchorX: Double
        let anchorY: Double
        let widthInLocalD: Double?
        let widthInRadii: Double?
        let sha256: String?
        let clipY: Double?
        let clipHeight: Double?
    }
    struct Clip: Decodable {
        let files: [String]
        let frameMs: Int
        let pixelWidth: Int
        let pixelHeight: Int
        let anchorX: Double
        let anchorY: Double
        let widthInLocalD: Double
    }
    struct Manifest: Decodable {
        let schemaVersion: Int
        let id: String
        let approval: String
        let productionApproved: Bool
        let soldiers: [String: Sprite]
        let tokenMage: Sprite
        let portraitMage: Sprite?
        let fx: [String: Clip]
    }
    enum Invalid: Error { case manifest, missing(String), size(String), hash(String), alpha(String) }
    let manifest: Manifest
    private let images: [String: UIImage]
    static func load(bundle: Bundle = .main) throws -> Self {
        guard let manifestURL = bundle.url(forResource: "anim01-manifest", withExtension: "json", subdirectory: "Anim01") else { throw Invalid.manifest }
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: manifestURL))
        guard manifest.schemaVersion == 1, manifest.approval == "candidate", !manifest.productionApproved,
              Set(manifest.soldiers.keys) == ["black", "white"], Set(manifest.fx.keys) == ["cast", "push", "landing", "capture"] else { throw Invalid.manifest }
        var images: [String: UIImage] = [:]
        func load(_ name: String, width: Int, height: Int, hash: String? = nil) throws {
            guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Anim01") else { throw Invalid.missing(name) }
            let bytes = try Data(contentsOf: url)
            if let hash, SHA256.hash(data: bytes).map({ String(format: "%02x", $0) }).joined() != hash { throw Invalid.hash(name) }
            guard let image = UIImage(data: bytes), let cg = image.cgImage, cg.width == width, cg.height == height else { throw Invalid.size(name) }
            guard [.first, .last, .premultipliedFirst, .premultipliedLast].contains(cg.alphaInfo) else { throw Invalid.alpha(name) }
            images[name] = image
        }
        for sprite in Array(manifest.soldiers.values) + [manifest.tokenMage] + (manifest.portraitMage.map { [$0] } ?? []) {
            try load(sprite.file, width: sprite.pixelWidth, height: sprite.pixelHeight, hash: sprite.sha256)
        }
        for clip in manifest.fx.values {
            guard clip.frameMs == 20 else { throw Invalid.manifest }
            for name in clip.files { try load(name, width: clip.pixelWidth, height: clip.pixelHeight) }
        }
        return Self(manifest: manifest, images: images)
    }
    func image(_ name: String) -> UIImage { images[name]! }
    /// Frame selection is normalized to the receipt's phase, not a second independent clock.
    func fx(_ name: String, progress: Double) -> UIImage? {
        guard let clip = manifest.fx[name], progress >= 0, progress < 1, !clip.files.isEmpty else { return nil }
        let index = min(clip.files.count-1,Int(progress*Double(clip.files.count)))
        return images[clip.files[index]]
    }
    func fx(_ name: String, elapsed: Double) -> UIImage? {
        guard let clip = manifest.fx[name], elapsed >= 0 else { return nil }
        let index = Int((elapsed * 1000) / Double(clip.frameMs))
        return clip.files.indices.contains(index) ? images[clip.files[index]] : nil
    }
}

struct Anim01Sprite: View {
    let asset: Anim01Assets.Sprite
    let assets: Anim01Assets
    let pitch: CGFloat
    var body: some View {
        let width = pitch * CGFloat(asset.widthInLocalD ?? ((asset.widthInRadii ?? 2.45) * 0.31))
        let height = width * CGFloat(asset.pixelHeight) / CGFloat(asset.pixelWidth)
        Image(uiImage: assets.image(asset.file)).resizable().interpolation(.high)
            .frame(width: width, height: height)
            .mask {
                if let top = asset.clipY, let clipHeight = asset.clipHeight {
                    Rectangle().frame(width: width, height: height * clipHeight)
                        .offset(y: height * (top + clipHeight / 2 - 0.5))
                } else { Rectangle() }
            }
            .offset(x: (0.5 - asset.anchorX) * width, y: (0.5 - asset.anchorY) * height)
    }
}
