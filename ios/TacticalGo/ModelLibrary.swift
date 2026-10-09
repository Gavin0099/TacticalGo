import Foundation
import Combine
import RealityKit
import TacticalGoCore

/// The native prototype presentation loads the same editable skeleton packages reviewed
/// in Blender. Rule state and actions have no dependency on these resources.
@MainActor enum ModelLibrary {
    private static var models: [HeroClass: Entity] = [:]
    private static var halo: Entity?
    private static var units: [String: Entity] = [:]
    static func load() async throws {
        guard models.count != 3 || halo == nil || units.count != 4 else { return }
        var loaded: [HeroClass: Entity] = [:]
        for hero in [HeroClass.warrior, .mage, .rogue] {
            guard let url = Bundle.main.url(forResource: hero.rawValue.lowercased(), withExtension: "usdz", subdirectory: "Models") else {
                throw CocoaError(.fileNoSuchFile)
            }
            loaded[hero] = try await loadResource(url)
        }
        guard let haloURL = Bundle.main.url(forResource: "magic-halo", withExtension: "usdz", subdirectory: "Models") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let loadedHalo = try await loadResource(haloURL)
        var loadedUnits: [String: Entity] = [:]
        for name in ["bluesoldier", "bluecommander", "redsoldier", "redcommander"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "usdz", subdirectory: "Models") else {
                throw CocoaError(.fileNoSuchFile)
            }
            loadedUnits[name] = try await loadResource(url)
        }
        models = loaded; halo = loadedHalo; units = loadedUnits
    }
    private static func loadResource(_ url: URL) async throws -> Entity {
        if #available(iOS 18.0, *) { return try await Entity(contentsOf: url) }
        // iOS 17 uses the existing asynchronous publisher rather than blocking
        // the main actor with the synchronous compatibility loader.
        for try await model in Entity.loadAsync(contentsOf: url).values { return model }
        throw CocoaError(.fileReadUnknown)
    }
    static func hero(_ hero: HeroClass) -> Entity? {
        guard let prototype = models[hero] else { return nil }
        // Keep USD's authored coordinate conversion below the gameplay pose.
        // Motion can safely reset this identity wrapper without flattening the
        // imported Y/Z-axis transform or changing its skeletal bind space.
        let wrapper = Entity(); wrapper.name = "hero-" + hero.rawValue
        wrapper.addChild(prototype.clone(recursive: true))
        return wrapper
    }
    static func magicHalo() -> Entity? { halo?.clone(recursive: true) }
    static func unit(_ piece: Piece) -> Entity? {
        guard piece.kind != .hero else { return nil }
        let name = (piece.owner == .one ? "blue" : "red") + (piece.kind == .commander ? "commander" : "soldier")
        guard let prototype = units[name] else { return nil }
        let wrapper = Entity(); wrapper.name = name
        wrapper.addChild(prototype.clone(recursive: true))
        return wrapper
    }
}

extension MiniatureModels {
    static func renderedHero(_ hero: HeroClass) -> Entity {
        ModelLibrary.hero(hero) ?? self.hero(hero)
    }
}
