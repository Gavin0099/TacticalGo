import SwiftUI
import TacticalGoCore

extension View {
    /// Shared support-screen surface; native accessibility and control semantics remain intact.
    func gameSheetSurface() -> some View {
        self.scrollContentBackground(.hidden).background(GameBackdrop())
            .foregroundStyle(GameChrome.cream).tint(GameChrome.gold).preferredColorScheme(.dark)
            .toolbarBackground(GameChrome.ink, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

/// Shared game chrome. Rules and action availability remain owned by GameStore/Core.
enum GameChrome {
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.15)
    static let cream = Color(red: 0.98, green: 0.91, blue: 0.75)
    static let muted = Color(red: 0.77, green: 0.73, blue: 0.62)
    static let gold = Color(red: 0.86, green: 0.65, blue: 0.32)
    static let bronze = Color(red: 0.36, green: 0.24, blue: 0.13)
    static let teal = Color(red: 0.23, green: 0.67, blue: 0.68)
    static func accent(_ hero: HeroClass) -> Color {
        switch hero {
        case .warrior: gold
        case .mage: Color(red: 0.37, green: 0.77, blue: 0.91)
        case .rogue: Color(red: 0.53, green: 0.73, blue: 0.53)
        case .priest: Color(red: 0.96, green: 0.80, blue: 0.46)
        case .none: teal
        }
    }
}

struct GameBackdrop: View {
    var body: some View {
        GeometryReader { geo in
            LinearGradient(colors: [Color(red: 0.17, green: 0.24, blue: 0.23), GameChrome.ink], startPoint: .topLeading, endPoint: .bottomTrailing)
                .overlay {
                    Image("game-table-material").resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height).clipped().opacity(0.08)
                }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

struct GameCutCorner: Shape {
    var cut: CGFloat = 7
    func path(in rect: CGRect) -> Path {
        let c = min(cut, min(rect.width, rect.height) / 3)
        return Path { p in
            p.move(to: CGPoint(x: c, y: 0)); p.addLine(to: CGPoint(x: rect.width-c, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: c)); p.addLine(to: CGPoint(x: rect.width, y: rect.height-c))
            p.addLine(to: CGPoint(x: rect.width-c, y: rect.height)); p.addLine(to: CGPoint(x: c, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height-c)); p.addLine(to: CGPoint(x: 0, y: c)); p.closeSubpath()
        }
    }
}

struct GamePanel: View {
    enum Kind: Equatable { case field, hero, tray }
    var active = false
    var kind: Kind = .field
    var body: some View {
        ZStack {
            GameCutCorner().fill(LinearGradient(colors: [Color(red: 0.18, green: 0.25, blue: 0.26), GameChrome.ink], startPoint: .top, endPoint: .bottom))
            if kind == .hero {
                GeometryReader { geo in
                    Image("game-table-material").resizable().scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height).clipped().opacity(0.16)
                }.clipShape(GameCutCorner())
            }
            if kind == .tray {
                Image("game-tray-frame-v20").resizable()
            } else {
                GameCutCorner().stroke(GameChrome.bronze.opacity(0.70), lineWidth: 3)
                GameCutCorner().stroke(LinearGradient(colors: [active ? GameChrome.gold : GameChrome.muted.opacity(0.40), GameChrome.bronze.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            }
        }
        .shadow(color: .black.opacity(0.45), radius: kind == .tray ? 5 : 2, y: 3)
        .allowsHitTesting(false).accessibilityHidden(true)
    }
}

enum GameIcon: Int {
    case soldier, summon, bastion, reformation, magicHand, doublePull, swap, chainSwap, offering, slime, shadow, crystal
    static func hero(_ hero: HeroClass, advanced: Bool = false) -> Self {
        switch hero {
        case .warrior: advanced ? .reformation : .bastion
        case .mage: advanced ? .doublePull : .magicHand
        case .rogue: advanced ? .chainSwap : .swap
        case .priest: .offering
        case .none: .soldier
        }
    }
}

/// Atlas is sampled at render time; the generated source pixels stay untouched.
struct GameIconView: View {
    let icon: GameIcon
    var size: CGFloat = 36
    var body: some View {
        Image("game-ability-atlas-v20").resizable()
            .frame(width: size * 4, height: size * 3)
            .offset(x: -CGFloat(icon.rawValue % 4) * size, y: -CGFloat(icon.rawValue / 4) * size)
            .frame(width: size, height: size, alignment: .topLeading).clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

struct GameManaGem: View {
    let value: Int
    var compact = false
    var body: some View {
        ZStack {
            GameCutCorner(cut: 6).fill(LinearGradient(colors: [Color(red: 0.27, green: 0.74, blue: 0.92), Color(red: 0.06, green: 0.22, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing))
            GameCutCorner(cut: 6).stroke(Color(red: 0.62, green: 0.87, blue: 0.98), lineWidth: 1)
            GeometryReader { geo in
                Path { p in
                    p.move(to: CGPoint(x: 6, y: 0)); p.addLine(to: CGPoint(x: geo.size.width * 0.55, y: geo.size.height * 0.55))
                    p.addLine(to: CGPoint(x: 0, y: geo.size.height - 6)); p.addLine(to: CGPoint(x: 0, y: 6)); p.closeSubpath()
                }.fill(Color.white.opacity(0.20))
            }.clipShape(GameCutCorner(cut: 6))
            if !compact { Text("\(value)").font(.system(size: 12, weight: .heavy, design: .serif)).foregroundStyle(.white).shadow(color: .black, radius: 1, y: 1) }
        }.frame(width: compact ? 16 : 22, height: compact ? 16 : 24).accessibilityLabel("\(value) 能量")
    }
}

struct GameAbilityLabel: View {
    let title: String
    let icon: GameIcon
    let mana: Int
    var advanced = false
    var restriction: String?
    var body: some View {
        VStack(spacing: 1) {
            ZStack(alignment: .topLeading) {
                GameIconView(icon: icon, size: 44).saturation(restriction == nil ? 1 : 0.32)
                    .opacity(restriction == nil ? 1 : 0.68).frame(maxWidth: .infinity)
                if mana > 0 { GameManaGem(value: mana).scaleEffect(0.82, anchor: .topLeading) }
                if advanced { Text("II").font(.system(size: 12, weight: .black, design: .serif)).foregroundStyle(GameChrome.gold).frame(maxWidth: .infinity, alignment: .trailing) }
                if restriction != nil {
                    Image(systemName:"lock.fill").font(.system(size:10,weight:.bold)).foregroundStyle(GameChrome.cream)
                        .frame(width:16,height:16).background(Circle().fill(GameChrome.ink))
                        .frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.bottomTrailing).accessibilityHidden(true)
                }
            }
            Text(title).font(.system(size: 12, weight: .bold)).lineLimit(1).minimumScaleFactor(0.85)
        }.padding(.horizontal, 5).padding(.bottom, 3).frame(maxWidth: .infinity).frame(height: 64)
        .accessibilityElement(children: .ignore).accessibilityLabel(title + "，1 AP，\(mana) 能量")
        .accessibilityValue(restriction ?? "可選目標，仍須合法預覽")
    }
}

struct GameButtonStyle: ButtonStyle {
    enum Kind: Equatable { case quiet, ability, primary, turn }
    var kind: Kind = .quiet
    var selected = false
    var padded = false
    var restricted = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var top: Color {
        guard enabled else { return Color(red: 0.24, green: 0.26, blue: 0.25) }
        switch kind {
        case .primary: return Color(red: 0.91, green: 0.70, blue: 0.34)
        case .turn: return Color(red: 0.43, green: 0.27, blue: 0.15)
        case .ability: return selected ? Color(red: 0.22, green: 0.36, blue: 0.37) : restricted ? Color(red:0.18,green:0.21,blue:0.22) : Color(red: 0.21, green: 0.29, blue: 0.30)
        case .quiet: return Color(red: 0.24, green: 0.20, blue: 0.16)
        }
    }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(padded ? 10 : 0)
            .frame(minHeight: padded ? 44 : nil)
            .foregroundStyle(enabled && kind == .primary ? GameChrome.ink : enabled ? GameChrome.cream : GameChrome.muted)
            .background(LinearGradient(colors: enabled && kind == .primary ? [GameChrome.cream, top, GameChrome.gold] : [top, GameChrome.ink], startPoint: .top, endPoint: .bottom))
            .clipShape(GameCutCorner(cut: kind == .turn ? 12 : 6))
            .contentShape(GameCutCorner(cut: kind == .turn ? 12 : 6))
            .overlay(GameCutCorner(cut: kind == .turn ? 12 : 6).stroke(selected && enabled ? GameChrome.teal : GameChrome.gold.opacity(enabled ? (kind == .ability ? 0.40 : 0.70) : 0.25), lineWidth: selected ? 2 : 1))
            .overlay(GameCutCorner(cut: kind == .turn ? 12 : 6).stroke(LinearGradient(colors: [.white.opacity(enabled ? 0.16 : 0.05), .clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom), lineWidth: 2).padding(2))
            .overlay(alignment: .bottom) {
                if selected { Capsule().fill(enabled ? GameChrome.teal : GameChrome.muted).frame(width: 22, height: 2) }
            }
            .shadow(color: selected && enabled ? GameChrome.teal.opacity(0.25) : .black.opacity(0.45), radius: selected ? 5 : 1, y: 2)
            .offset(y: configuration.isPressed && !reduceMotion ? 1 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
