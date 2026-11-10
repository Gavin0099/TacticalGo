import SwiftUI
import TacticalGoVisuals

extension DynamicTypeSize {
    /// UIKit content-size names. These match `GameTypeScale.categoryNames`.
    var gameCategoryName: String {
        switch self {
        case .xSmall: "xSmall"
        case .small: "small"
        case .medium: "medium"
        case .large: "large"
        case .xLarge: "xLarge"
        case .xxLarge: "xxLarge"
        case .xxxLarge: "xxxLarge"
        case .accessibility1: "accessibilityMedium"
        case .accessibility2: "accessibilityLarge"
        case .accessibility3: "accessibilityExtraLarge"
        case .accessibility4: "accessibilityExtraExtraLarge"
        case .accessibility5: "accessibilityExtraExtraExtraLarge"
        @unknown default: "large"
        }
    }
}

struct GameTypeEnvironment {
    let name: String
    let stacksVertically: Bool
    let needsReflow: Bool

    init(_ size: DynamicTypeSize) {
        name = size.gameCategoryName
        stacksVertically = GameTypeScale.stacksVertically(named: name) ?? false
        needsReflow = GameTypeScale.needsReflow(named: name) ?? false
    }
}

extension GameTextStyleName {
    var fontStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption: .caption
        case .caption2: .caption2
        }
    }
}

extension GameTextWeightName {
    var fontWeight: Font.Weight {
        switch self {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        }
    }
}

extension GameTextDesignName {
    var fontDesign: Font.Design {
        switch self {
        case .standard: .default
        case .rounded: .rounded
        case .serif: .serif
        }
    }
}

extension Font {
    /// System text style for a scale role. Optical size and tracking stay with San Francisco.
    static func game(_ role: GameTextRole, emphasis: GameTextEmphasis = .regular, design: GameTextDesignName? = nil) -> Font {
        let spec = GameTypeScale.spec(role, emphasis: emphasis)
        var font = Font.system(spec.style.fontStyle, design: (design ?? spec.design).fontDesign, weight: spec.weight.fontWeight)
        if spec.monospacedDigits { font = font.monospacedDigit() }
        return font
    }
}

extension View {
    func gameFont(_ role: GameTextRole, emphasis: GameTextEmphasis = .regular, design: GameTextDesignName? = nil) -> some View {
        font(.game(role, emphasis: emphasis, design: design))
    }
}

/// Accessibility sizes flip the row to a column so text gets the full line (WWDC24 10074).
@ViewBuilder func gameRow<Content: View>(vertical: Bool, spacing: CGFloat = 8, @ViewBuilder content: () -> Content) -> some View {
    let layout = vertical
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
        : AnyLayout(HStackLayout(alignment: .center, spacing: spacing))
    layout { content() }
}
