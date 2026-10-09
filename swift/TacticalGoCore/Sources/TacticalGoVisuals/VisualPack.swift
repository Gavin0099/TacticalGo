import Foundation

/// Art metadata only. It cannot move intersections, change hit testing or resolve rules.
public struct SpriteAsset: Codable, Equatable, Sendable {
    public let name: String
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let anchorX: Double
    public let anchorY: Double
    public let widthInRadii: Double
    public let requiresAlpha: Bool
    public init(name: String, pixelWidth: Int, pixelHeight: Int, anchorX: Double = 0.5,
                anchorY: Double = 0.5, widthInRadii: Double = 2.45, requiresAlpha: Bool = true) {
        self.name = name; self.pixelWidth = pixelWidth; self.pixelHeight = pixelHeight
        self.anchorX = anchorX; self.anchorY = anchorY; self.widthInRadii = widthInRadii
        self.requiresAlpha = requiresAlpha
    }
    /// Top-left canvas origin; preserve aspect ratio, then align this anchor to the board point.
    public func placement(radius: Double) -> (width: Double, height: Double, dx: Double, dy: Double) {
        let width = radius * widthInRadii, height = width * Double(pixelHeight) / Double(pixelWidth)
        return (width, height, (0.5 - anchorX) * width, (0.5 - anchorY) * height)
    }
}

public struct HeroAssets: Codable, Equatable, Sendable {
    public let portrait: SpriteAsset
    public let token: SpriteAsset
    public init(portrait: SpriteAsset, token: SpriteAsset) { self.portrait = portrait; self.token = token }
}

public struct VisualPack: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let id: String
    public let projection: String
    /// Full normalized board canvas. Supply without grid, pieces, badges or highlights.
    public let boardShadow: SpriteAsset?
    public let boardSurface: SpriteAsset?
    public let blackSoldier: SpriteAsset?
    public let whiteSoldier: SpriteAsset?
    public let blackCommander: SpriteAsset?
    public let whiteCommander: SpriteAsset?
    public let heroes: [String: HeroAssets]
    public init(schemaVersion: Int = 1, id: String, projection: String = "v1-oblique",
                boardShadow: SpriteAsset? = nil, boardSurface: SpriteAsset? = nil,
                blackSoldier: SpriteAsset? = nil, whiteSoldier: SpriteAsset? = nil,
                blackCommander: SpriteAsset? = nil, whiteCommander: SpriteAsset? = nil,
                heroes: [String: HeroAssets]) {
        self.schemaVersion = schemaVersion; self.id = id; self.projection = projection
        self.boardShadow = boardShadow; self.boardSurface = boardSurface
        self.blackSoldier = blackSoldier; self.whiteSoldier = whiteSoldier
        self.blackCommander = blackCommander; self.whiteCommander = whiteCommander; self.heroes = heroes
    }
    public enum Invalid: Error, Equatable { case schema, identifier, projection, heroes, sprite(String), conflictingName(String) }
    public var assets: [SpriteAsset] {
        [boardShadow, boardSurface, blackSoldier, whiteSoldier, blackCommander, whiteCommander].compactMap { $0 }
        + heroes.keys.sorted().flatMap { [heroes[$0]!.portrait, heroes[$0]!.token] }
    }
    public func validate() throws {
        guard schemaVersion == 1 else { throw Invalid.schema }
        guard Self.validName(id) else { throw Invalid.identifier }
        guard projection == "v1-oblique" else { throw Invalid.projection }
        guard Set(heroes.keys) == ["warrior", "mage", "rogue"] else { throw Invalid.heroes }
        var names: [String: SpriteAsset] = [:]
        for asset in assets {
            guard Self.validName(asset.name), (1...4096).contains(asset.pixelWidth), (1...4096).contains(asset.pixelHeight),
                  asset.anchorX.isFinite, asset.anchorY.isFinite,
                  (0...1).contains(asset.anchorX), (0...1).contains(asset.anchorY),
                  asset.widthInRadii.isFinite, (1...4).contains(asset.widthInRadii) else { throw Invalid.sprite(asset.name) }
            if let previous = names[asset.name], previous != asset { throw Invalid.conflictingName(asset.name) }
            names[asset.name] = asset
        }
    }
    private static func validName(_ value: String) -> Bool {
        !value.isEmpty && value.count <= 80 && value.unicodeScalars.allSatisfy {
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_").contains($0)
        }
    }
}
