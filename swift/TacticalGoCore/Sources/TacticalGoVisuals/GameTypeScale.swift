import Foundation

/// In-game type roles. Sizes come from system text styles, not frozen point sizes.
public enum GameTextRole: String, CaseIterable, Sendable {
    case title
    case body
    case caption
    case numeric
}

/// Weight step inside a role. Emphasis changes weight, not a new typeface.
public enum GameTextEmphasis: String, CaseIterable, Sendable {
    case regular
    case strong
    case display
}

public enum GameTextStyleName: String, CaseIterable, Sendable {
    case largeTitle
    case title
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption
    case caption2
}

public enum GameTextWeightName: String, Sendable, Equatable {
    case regular
    case medium
    case semibold
    case bold
    case heavy
    case black
}

public enum GameTextDesignName: String, Sendable, Equatable {
    /// SF Pro. Brand wordmarks may override this at the call site.
    case standard
    /// SF Pro Rounded, for numerals and friendly counts.
    case rounded
    case serif
}

public struct GameTextSpec: Equatable, Sendable {
    public let role: GameTextRole
    public let emphasis: GameTextEmphasis
    public let style: GameTextStyleName
    public let weight: GameTextWeightName
    public let design: GameTextDesignName
    public let monospacedDigits: Bool
    public let wraps: Bool
    /// 0 lets San Francisco's size-specific tracking stand. Nonzero tracking is not part of this scale.
    public let tracking: Double

    public init(role: GameTextRole, emphasis: GameTextEmphasis, style: GameTextStyleName, weight: GameTextWeightName, design: GameTextDesignName, monospacedDigits: Bool, wraps: Bool, tracking: Double) {
        self.role = role
        self.emphasis = emphasis
        self.style = style
        self.weight = weight
        self.design = design
        self.monospacedDigits = monospacedDigits
        self.wraps = wraps
        self.tracking = tracking
    }
}

public enum GameTypeScale {
    /// Apple's 12 Dynamic Type categories, default ladder then accessibility (AX1–AX5).
    /// The last name is accessibility XXXL (`accessibilityExtraExtraExtraLarge`).
    public static let categoryNames: [String] = [
        "xSmall", "small", "medium", "large", "xLarge", "xxLarge", "xxxLarge",
        "accessibilityMedium", "accessibilityLarge", "accessibilityExtraLarge",
        "accessibilityExtraExtraLarge", "accessibilityExtraExtraExtraLarge"
    ]

    /// Three text styles. Emphasis is weight. Numeric uses SF Pro Rounded and monospaced digits.
    public static func spec(_ role: GameTextRole, emphasis: GameTextEmphasis = .regular) -> GameTextSpec {
        switch (role, emphasis) {
        case (.title, .regular):
            return make(role, emphasis, style: .title2, weight: .semibold)
        case (.title, .strong):
            return make(role, emphasis, style: .title2, weight: .bold)
        case (.title, .display):
            return make(role, emphasis, style: .title2, weight: .black)
        case (.body, .regular):
            return make(role, emphasis, style: .body, weight: .regular)
        case (.body, .strong):
            return make(role, emphasis, style: .body, weight: .semibold)
        case (.body, .display):
            return make(role, emphasis, style: .body, weight: .bold)
        case (.caption, .regular):
            return make(role, emphasis, style: .caption, weight: .regular)
        case (.caption, .strong):
            return make(role, emphasis, style: .caption, weight: .semibold)
        case (.caption, .display):
            return make(role, emphasis, style: .caption, weight: .bold)
        case (.numeric, .regular):
            return make(role, emphasis, style: .body, weight: .regular, design: .rounded, monospacedDigits: true)
        case (.numeric, .strong):
            return make(role, emphasis, style: .body, weight: .bold, design: .rounded, monospacedDigits: true)
        case (.numeric, .display):
            return make(role, emphasis, style: .title2, weight: .bold, design: .rounded, monospacedDigits: true)
        }
    }

    /// nil when `name` is not one of the 12 categories.
    /// Reflow starts at xLarge, before accessibility sizes, because fixed HUD slots clip there.
    public static func needsReflow(named name: String) -> Bool? {
        guard let index = categoryNames.firstIndex(of: name) else { return nil }
        return index >= categoryNames.firstIndex(of: "xLarge")!
    }

    /// nil when `name` is not one of the 12 categories.
    /// Vertical stacking starts at the first accessibility size (AX1).
    public static func stacksVertically(named name: String) -> Bool? {
        guard let index = categoryNames.firstIndex(of: name) else { return nil }
        return index >= categoryNames.firstIndex(of: "accessibilityMedium")!
    }

    private static func make(_ role: GameTextRole, _ emphasis: GameTextEmphasis, style: GameTextStyleName, weight: GameTextWeightName, design: GameTextDesignName = .standard, monospacedDigits: Bool = false) -> GameTextSpec {
        GameTextSpec(role: role, emphasis: emphasis, style: style, weight: weight, design: design, monospacedDigits: monospacedDigits, wraps: true, tracking: 0)
    }
}
