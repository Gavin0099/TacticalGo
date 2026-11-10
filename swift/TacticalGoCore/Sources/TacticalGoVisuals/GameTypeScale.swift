import Foundation

/// Reading-text roles for in-game HUD, settings, and result copy.
/// Point sizes are the Large content-size design sizes. They grow with the
/// named Dynamic Type style: scaled = base × (current style size / Large style size).
/// Large style sizes are the Apple Human Interface Guidelines Dynamic Type table.
public enum GameTextRole: String, CaseIterable, Sendable, Equatable {
    case title
    case body
    case caption
    case numeric
}

public enum GameFontWeightToken: String, Sendable, Equatable {
    case regular, medium, semibold, bold, heavy, black
}

public enum GameTextStyleToken: String, Sendable, Equatable {
    case title3, body, caption, caption2
}

public struct GameTextSpec: Equatable, Sendable {
    public let role: GameTextRole
    public let basePointSize: Double
    public let weight: GameFontWeightToken
    public let relativeTo: GameTextStyleToken
    /// Point size of `relativeTo` at the system Large content-size category.
    public let largeStylePointSize: Double

    public init(role: GameTextRole, basePointSize: Double, weight: GameFontWeightToken, relativeTo: GameTextStyleToken, largeStylePointSize: Double) {
        self.role = role
        self.basePointSize = basePointSize
        self.weight = weight
        self.relativeTo = relativeTo
        self.largeStylePointSize = largeStylePointSize
    }
}

public enum GameTypeScale {
    public static func spec(for role: GameTextRole) -> GameTextSpec {
        switch role {
        case .title:
            return GameTextSpec(role: .title, basePointSize: 20, weight: .heavy, relativeTo: .title3, largeStylePointSize: 20)
        case .body:
            return GameTextSpec(role: .body, basePointSize: 14, weight: .regular, relativeTo: .body, largeStylePointSize: 17)
        case .caption:
            return GameTextSpec(role: .caption, basePointSize: 11, weight: .medium, relativeTo: .caption2, largeStylePointSize: 11)
        case .numeric:
            return GameTextSpec(role: .numeric, basePointSize: 12, weight: .bold, relativeTo: .caption, largeStylePointSize: 12)
        }
    }

    /// Invalid or non-positive style sizes keep the base size. A non-finite base returns 0.
    public static func scaledPointSize(basePointSize: Double, largeStylePointSize: Double, currentStylePointSize: Double) -> Double {
        guard basePointSize.isFinite else { return 0 }
        guard largeStylePointSize.isFinite, largeStylePointSize > 0,
              currentStylePointSize.isFinite, currentStylePointSize > 0 else {
            return basePointSize
        }
        return basePointSize * currentStylePointSize / largeStylePointSize
    }

    public static func scaledPointSize(role: GameTextRole, currentStylePointSize: Double) -> Double {
        let spec = spec(for: role)
        return scaledPointSize(basePointSize: spec.basePointSize, largeStylePointSize: spec.largeStylePointSize, currentStylePointSize: currentStylePointSize)
    }
}
