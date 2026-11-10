import SwiftUI
import TacticalGoVisuals

/// Applies `GameTypeScale` with `@ScaledMetric` so custom sizes follow Dynamic Type
/// through accessibility XXXL. Numeric copy uses monospaced digits.
struct GameFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design
    private let digits: Bool

    init(role: GameTextRole, weight: Font.Weight?, design: Font.Design) {
        let spec = GameTypeScale.spec(for: role)
        _size = ScaledMetric(wrappedValue: CGFloat(spec.basePointSize), relativeTo: Self.textStyle(spec.relativeTo))
        self.weight = weight ?? Self.fontWeight(spec.weight)
        self.design = design
        self.digits = role == .numeric
    }

    func body(content: Content) -> some View {
        let font = Font.system(size: size, weight: weight, design: design)
        content.font(digits ? font.monospacedDigit() : font)
    }

    private static func textStyle(_ token: GameTextStyleToken) -> Font.TextStyle {
        switch token {
        case .title3: .title3
        case .body: .body
        case .caption: .caption
        case .caption2: .caption2
        }
    }

    private static func fontWeight(_ token: GameFontWeightToken) -> Font.Weight {
        switch token {
        case .regular: .regular
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        }
    }
}

extension View {
    func gameFont(_ role: GameTextRole, weight: Font.Weight? = nil, design: Font.Design = .default) -> some View {
        modifier(GameFontModifier(role: role, weight: weight, design: design))
    }
}
