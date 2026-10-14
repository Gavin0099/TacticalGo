import SwiftUI
import TacticalGoCore

/// Match-only surfaces. No rules, event scheduling or control state live here.
enum SellTheme {
    static let paper = Cozy.color(0xF7EBD3)
    static let ink = Cozy.color(0x213B40)
    static let muted = Cozy.color(0x52615A)
    static let lightMuted = Cozy.color(0xD6D8CB)
    static let bronze = Cozy.color(0xA77D46)
    static let teal = Cozy.color(0x193D46)
}

struct SellPlaque: Shape {
    func path(in rect: CGRect) -> Path {
        let c = min(7, rect.height * 0.15)
        return Path { p in
            p.move(to: CGPoint(x: c, y: 0)); p.addLine(to: CGPoint(x: rect.width-c, y: 0))
            p.addLine(to: CGPoint(x: rect.width, y: c)); p.addLine(to: CGPoint(x: rect.width, y: rect.height-c))
            p.addLine(to: CGPoint(x: rect.width-c, y: rect.height)); p.addLine(to: CGPoint(x: c, y: rect.height))
            p.addLine(to: CGPoint(x: 0, y: rect.height-c)); p.addLine(to: CGPoint(x: 0, y: c)); p.closeSubpath()
        }
    }
}

struct SellButton: ButtonStyle {
    var selected = false
    var confirm = false
    @Environment(\.isEnabled) private var enabled
    @Environment(\.accessibilityReduceMotion) private var reduced
    func makeBody(configuration: Configuration) -> some View {
        let top = confirm && enabled ? Cozy.color(0xFCE7AE) : selected ? Cozy.color(0xD6E8DE) : SellTheme.paper
        let bottom = confirm && enabled ? Cozy.color(0xE4B763) : selected ? Cozy.color(0xB9D5C8) : Cozy.color(0xE1D3B8)
        configuration.label
            .foregroundStyle(enabled ? SellTheme.ink : SellTheme.muted)
            .padding(.horizontal, 6)
            .background {
                SellPlaque().fill(LinearGradient(colors: [top,bottom], startPoint: .top, endPoint: .bottom))
                    .overlay(Image("sell-paper-r1").resizable().opacity(0.32).blendMode(.multiply).clipShape(SellPlaque()))
                    .shadow(color: Color.black.opacity(0.18),radius: 1,y: configuration.isPressed ? 0 : 2)
            }
            .overlay(SellPlaque().stroke(selected ? SellTheme.teal : SellTheme.bronze.opacity(confirm ? 0.95 : 0.65),lineWidth: selected || confirm ? 1.7 : 0.8))
            .overlay(SellPlaque().stroke(Color.white.opacity(0.45),lineWidth: 0.7).padding(3))
            .overlay(alignment: .topTrailing) {
                if selected { Image(systemName: "checkmark").font(.system(size: 10,weight: .black)).padding(5).accessibilityHidden(true) }
            }
            .offset(y: configuration.isPressed ? 1.5 : 0)
            .animation(reduced ? nil : .easeOut(duration: 0.12),value: enabled)
    }
}

extension View {
    @ViewBuilder func matchButtonStyle(commercial:Bool,selected:Bool = false,confirm:Bool = false) -> some View {
        if commercial { buttonStyle(SellButton(selected:selected,confirm:confirm)) }
        else { buttonStyle(CozyButton(selected:selected,confirm:confirm)) }
    }
}

struct SellOperationSurface: View {
    var body: some View {
        SellPlaque().fill(LinearGradient(colors: [SellTheme.paper,Cozy.color(0xE8D6B3)],startPoint: .topLeading,endPoint: .bottomTrailing))
            .overlay(Image("sell-paper-r1").resizable().opacity(0.65).blendMode(.multiply).clipShape(SellPlaque()))
            .overlay(SellPlaque().stroke(SellTheme.bronze.opacity(0.5),lineWidth: 0.8))
            .overlay(SellPlaque().stroke(Color.white.opacity(0.45),lineWidth: 0.7).padding(4))
            .shadow(color: Color.black.opacity(0.16),radius: 2,y: 2)
    }
}

/// A small tabletop seal, without invented scores, rewards or progression.
struct SellResultEmblem: View {
    let drawn: Bool
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(LinearGradient(colors: [Cozy.color(0xF7DC99), Cozy.color(0xC5964D)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(Circle().stroke(SellTheme.bronze, lineWidth: 1))
                    .overlay(Circle().stroke(SellTheme.paper.opacity(0.75), lineWidth: 1).padding(4))
                    .shadow(color: SellTheme.bronze.opacity(0.2), radius: 1, y: 1)
                Image(systemName: drawn ? "equal" : "crown.fill")
                    .font(.system(size: geo.size.width * 0.45, weight: .bold))
                    .foregroundStyle(SellTheme.teal)
            }
        }.allowsHitTesting(false)
    }
}

struct SellTabletop: View {
    var body: some View {
        GeometryReader { geo in
            Image(geo.size.width > geo.size.height ? "sell-tabletop-wide-r1" : "sell-tabletop").resizable().scaledToFill()
                .frame(width: geo.size.width,height: geo.size.height).clipped()
                .overlay(Color.black.opacity(0.16))
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Every unit shares this grounded base; kind is distinguished without enlarging art.
struct SellUnitBase: View {
    let black: Bool
    let commander: Bool
    let width: CGFloat
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.30)).frame(width:width*1.10,height:width*0.48).blur(radius: 1).offset(y:width*0.12)
            Ellipse().fill(black ? Cozy.color(0x102B38) : Cozy.color(0xAF9C78)).frame(width:width,height:width*0.51).offset(y:width*0.09)
            Ellipse().fill(LinearGradient(colors:black ? [Cozy.color(0x355665),Cozy.color(0x152E3B)] : [Cozy.color(0xFFF6E1),Cozy.color(0xD4C6A4)],startPoint:.topLeading,endPoint:.bottomTrailing))
                .frame(width:width,height:width*0.48)
                .overlay(Ellipse().stroke(commander ? Cozy.color(0xD7AD63) : black ? Cozy.color(0xCBDAD5) : Cozy.color(0x786B51),lineWidth:commander ? 1.6 : 0.85))
            if commander { Ellipse().stroke(black ? Cozy.card.opacity(0.50) : Cozy.coordinate.opacity(0.35),lineWidth:0.6).frame(width:width*0.84,height:width*0.33) }
        }.allowsHitTesting(false)
    }
}


/// Text comes from the read-only preview receipt, including costs before any automatic turn refill.
/// No UI legality, resource arithmetic or capture rules are duplicated here.
struct SellActionSummary {
    let effect: String
    let cost: String
    let consequence: String?
    init?(outcome: ActionOutcome, action: GameAction?) {
        guard outcome.success else { return nil }
        var ap = 0, mana = 0, placed: [(Point, PieceKind)] = [], details: String?, captured = 0, wins = false
        func coordinate(_ p: Point) -> String { "\(UnicodeScalar(65 + p.x).map(String.init) ?? "?")\(p.y + 1)" }
        for event in outcome.events {
            switch event {
            case .resourcesSpent(_, let a, let m): ap += a; mana += m
            case .piecePlaced(_, let p, let kind): placed.append((p, kind))
            case .piecePushed(_, let from, let to, _):
                if case .castFriendlyRedeploy = action {
                    details = "調度 \(coordinate(from)) 己兵至 \(coordinate(to))"
                } else { details = "將 \(coordinate(from)) 士兵推至 \(coordinate(to))" }
            case .piecesSwapped(_, let from, let to): details = "\(coordinate(from)) 與 \(coordinate(to)) 交換位置"
            case .sealPlaced(_, _, let p): details = "於 \(coordinate(p)) 設置封印"
            case .piecesCaptured(_, let pieces): captured += pieces.count
            case .gameWon: wins = true
            default: break
            }
        }
        guard ap > 0 || mana > 0 else { return nil }
        if details == nil, !placed.isEmpty {
            let locations = placed.map { coordinate($0.0) }.joined(separator: "、")
            if placed.contains(where: { $0.1 == .hero }) { details = "於 \(locations) 召喚英雄" }
            else if placed.count > 1 { details = "於 \(locations) 部署 \(placed.count) 名士兵" }
            else { details = "於 \(locations) 放置士兵" }
        }
        effect = details ?? "執行所選行動"
        cost = "消耗 \(ap) AP" + (mana > 0 ? " · \(mana) 能量" : "")
        consequence = wins ? "預計提子 \(captured) 顆 · 對局結束" : captured > 0 ? "預計提子 \(captured) 顆" : nil
    }
}

/// Small painted-looking tabletop emblems, drawn natively; all button labels remain real text.
struct SellActionGlyph: View {
    let mode: GameStore.Mode
    let hero: HeroClass
    var body: some View {
        Canvas { context, size in
            let scale = size.width / 24
            context.scaleBy(x: scale, y: size.height / 20)
            let gold = Cozy.color(0xBE893D), pale = Cozy.color(0xF9E2A5), blue = Cozy.color(0x326373)
            func line(_ a: CGPoint, _ b: CGPoint, _ color: Color, _ width: CGFloat) {
                var p = Path(); p.move(to: a); p.addLine(to: b)
                context.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }
            if mode == .soldier {
                let base = CGRect(x: 3, y: 13, width: 18, height: 5)
                context.fill(Path(ellipseIn: base), with: .color(gold))
                context.fill(Path(ellipseIn: CGRect(x: 4, y: 11, width: 16, height: 5)), with: .color(blue))
                let helmet = Path { p in
                    p.move(to: CGPoint(x: 7, y: 12)); p.addLine(to: CGPoint(x: 7, y: 8))
                    p.addQuadCurve(to: CGPoint(x: 17, y: 8), control: CGPoint(x: 12, y: -1))
                    p.addLine(to: CGPoint(x: 17, y: 12)); p.closeSubpath()
                }
                context.fill(helmet, with: .color(pale)); context.stroke(helmet, with: .color(gold), lineWidth: 1)
                line(CGPoint(x: 12,y: 5),CGPoint(x: 12,y: 12),blue,1)
                line(CGPoint(x: 8,y: 10),CGPoint(x: 16,y: 10),blue,1)
            } else if mode == .summon {
                context.stroke(Path(ellipseIn: CGRect(x: 5,y: 3,width: 14,height: 14)), with: .color(gold), lineWidth: 2)
                context.stroke(Path(ellipseIn: CGRect(x: 2,y: 14,width: 20,height: 4)), with: .color(blue), lineWidth: 1)
                let star = Path { p in
                    for (i, xy) in [(12.0,2.0),(14,7),(19,9),(14,11),(12,16),(10,11),(5,9),(10,7)].enumerated() {
                        let pt = CGPoint(x: xy.0,y: xy.1); if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }; p.closeSubpath()
                }
                context.fill(star, with: .color(pale)); context.stroke(star, with: .color(gold), lineWidth: 0.8)
            } else if hero == .warrior {
                let shield = Path { p in
                    p.move(to: CGPoint(x: 4,y: 3)); p.addLine(to: CGPoint(x: 20,y: 3)); p.addLine(to: CGPoint(x: 19,y: 11))
                    p.addQuadCurve(to: CGPoint(x: 12,y: 18), control: CGPoint(x: 17,y: 16))
                    p.addQuadCurve(to: CGPoint(x: 5,y: 11), control: CGPoint(x: 7,y: 16)); p.closeSubpath()
                }
                context.fill(shield, with: .color(blue)); context.stroke(shield, with: .color(gold), lineWidth: 2)
                line(CGPoint(x: 12,y: 7),CGPoint(x: 12,y: 14),pale,2)
                line(CGPoint(x: 8,y: 7),CGPoint(x: 12,y: 10),pale,2)
                line(CGPoint(x: 16,y: 7),CGPoint(x: 12,y: 10),pale,2)
            } else if hero == .mage {
                line(CGPoint(x: 7,y: 18),CGPoint(x: 15,y: 5),gold,3)
                line(CGPoint(x: 7,y: 18),CGPoint(x: 15,y: 5),pale,1)
                let gem = Path { p in
                    p.move(to: CGPoint(x: 15,y: 1)); p.addLine(to: CGPoint(x: 19,y: 5)); p.addLine(to: CGPoint(x: 15,y: 9)); p.addLine(to: CGPoint(x: 11,y: 5)); p.closeSubpath()
                }
                context.fill(gem, with: .color(Cozy.color(0x7099AD))); context.stroke(gem, with: .color(blue), lineWidth: 1)
                line(CGPoint(x: 5,y: 3),CGPoint(x: 5,y: 7),gold,1)
                line(CGPoint(x: 3,y: 5),CGPoint(x: 7,y: 5),gold,1)
            } else {
                for x in [7.0,16.0] {
                    let blade = Path { p in
                        p.move(to: CGPoint(x: x,y: 1)); p.addLine(to: CGPoint(x: x+3,y: 10)); p.addLine(to: CGPoint(x: x,y: 12)); p.addLine(to: CGPoint(x: x-2,y: 10)); p.closeSubpath()
                    }
                    context.fill(blade, with: .color(pale)); context.stroke(blade, with: .color(blue), lineWidth: 1)
                    line(CGPoint(x:x-3,y:12),CGPoint(x:x+3,y:12),gold,2)
                    line(CGPoint(x:x,y:13),CGPoint(x:x,y:18),blue,2)
                }
            }
        }.allowsHitTesting(false)
    }
}
