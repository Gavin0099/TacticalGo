import SwiftUI
import CryptoKit
import TacticalGoCore

enum Cozy {
    static let bg = color(0xCCDCCE), card = color(0xF4EAD8), ink = color(0x243F43)
    static let gold = color(0xD9B46C), confirm = color(0xF1D394), sage = color(0x6C9276)
    static let selected = color(0xDCE7D5), disabled = color(0xDFE7DB), muted = color(0x496454)
    static let mage = color(0x9277B6), deepMage = color(0x59446F), danger = color(0x6E302B)
    static let coordinate = color(0x183438)
    static func color(_ value: UInt) -> Color {
        Color(red: Double((value >> 16) & 255)/255, green: Double((value >> 8)&255)/255, blue: Double(value&255)/255)
    }
}

struct CozyButton: ButtonStyle {
    var selected = false
    var confirm = false
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(enabled ? Cozy.ink : Cozy.muted)
            .padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(enabled ? (confirm ? Cozy.confirm : selected ? Cozy.selected : Cozy.card) : Cozy.disabled)
                    .shadow(color: Cozy.muted.opacity(enabled ? 0.35 : 0.1), radius: 0, y: configuration.isPressed ? 0 : confirm ? 3 : 2)
            }
            .overlay(alignment: .topTrailing) {
                if selected { Image(systemName: "checkmark").font(.system(size: 10, weight: .black)).padding(5).foregroundStyle(Cozy.ink) }
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? Cozy.ink : Cozy.muted.opacity(0.25), lineWidth: selected ? 1.5 : 0.6))
            .offset(y: configuration.isPressed ? 2 : 0)
    }
}

@MainActor struct CozyAssets {
    let anim: Anim01Assets
    let heroes: [HeroClass: UIImage]
    let board: UIImage
    let shadow: UIImage
    static func load(bundle: Bundle = .main) throws -> Self {
        struct Pins: Decodable { let files: [String: String] }
        guard let pinsURL = bundle.url(forResource: "source-pins", withExtension: "json", subdirectory: "Cozy") else { throw Anim01Assets.Invalid.manifest }
        let pins = try JSONDecoder().decode(Pins.self, from: Data(contentsOf: pinsURL))
        for (name, expected) in pins.files {
            let subdir = name.hasPrefix("Anim01/") ? "Anim01" : "Cozy"
            guard let url = bundle.url(forResource: String(name.split(separator: "/").last!), withExtension: nil, subdirectory: subdir) else { throw Anim01Assets.Invalid.missing(name) }
            let hash = SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
            guard hash == expected else { throw Anim01Assets.Invalid.hash(name) }
        }
        func image(_ name: String, width: Int, height: Int) throws -> UIImage {
            guard let url = bundle.url(forResource: name, withExtension: "png", subdirectory: "Cozy"),
                  let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage,
                  cg.width == width, cg.height == height else { throw Anim01Assets.Invalid.size(name) }
            return image
        }
        var heroes: [HeroClass: UIImage] = [:]
        for hero in [HeroClass.warrior, .mage, .rogue] { heroes[hero] = try image("B-" + hero.rawValue.lowercased() + "-v02", width: 512, height: 512) }
        return try Self(anim: Anim01Assets.load(bundle: bundle), heroes: heroes,
                        board: image("v3-b-board-surface", width: 1024, height: 1152),
                        shadow: image("v3-b-board-shadow", width: 1024, height: 1152))
    }
}

struct CozyToken: View {
    let piece: Piece
    let assets: CozyAssets
    let pitch: CGFloat
    var squash = 1.0
    let heroClass: HeroClass
    private var black: Bool { piece.owner == .one }
    private var diameter: CGFloat { pitch * (piece.kind == .commander ? 0.73 : piece.kind == .hero ? 0.74 : 0.62) }
    private var classColor: Color { heroClass == .mage ? Cozy.mage : heroClass == .warrior ? Cozy.sage : Cozy.coordinate }
    private var symbol: String { heroClass == .warrior ? "shield.fill" : heroClass == .mage ? "sparkle" : "bolt.fill" }
    var body: some View {
        ZStack {
            Ellipse().fill(Cozy.ink.opacity(0.18)).frame(width: diameter * 1.05, height: diameter * 0.60).offset(y: pitch * 0.05)
            Ellipse().fill(black ? Cozy.coordinate : Cozy.muted).frame(width: diameter, height: diameter * 0.70).offset(y: pitch * 0.035)
            Ellipse().fill(black ? Cozy.color(0x263C50) : Cozy.color(0xF1E7D3)).frame(width: diameter, height: diameter * 0.70)
                .overlay(Ellipse().stroke(black ? Cozy.color(0xD5DBD9) : Cozy.color(0x786E59), lineWidth: 1))
            if piece.kind == .soldier {
                Anim01Sprite(asset: assets.anim.manifest.soldiers[black ? "black" : "white"]!, assets: assets.anim, pitch: pitch)
                    .scaleEffect(x: 1, y: squash, anchor: .bottom)
            } else if piece.kind == .hero, let image = assets.heroes[heroClass] {
                Ellipse().stroke(classColor, lineWidth: 2).frame(width: diameter * 0.90, height: diameter * 0.63)
                let width = pitch * 0.70
                Image(uiImage: image).resizable().frame(width: width, height: width)
                    .mask { Rectangle().frame(width: width, height: width * 390/512).offset(y: width * (225.0/512 - 0.5)) }
                    .offset(y: width * (0.5 - 420.0/512))
                Group {
                    if heroClass == .rogue { CozyDagger().fill(Cozy.card).frame(width: max(8, pitch * 0.17), height: max(8, pitch * 0.17)) }
                    else { Image(systemName: symbol).font(.system(size: max(8, pitch * 0.17), weight: .black)).foregroundStyle(Cozy.card) }
                }.padding(2).background(classColor, in: Circle()).offset(x: diameter * 0.40, y: diameter * 0.08)
            } else if piece.kind == .commander {
                Image(systemName: "crown.fill").font(.system(size: pitch * 0.26, weight: .black)).foregroundStyle(black ? Cozy.confirm : Cozy.coordinate)
            }
            if piece.kind != .soldier {
                Text(black ? "黑" : "白").font(.system(size: max(7, pitch * 0.14), weight: .black))
                    .foregroundStyle(black ? Cozy.card : Cozy.coordinate)
                    .padding(1).background(black ? Cozy.coordinate : Cozy.card, in: RoundedRectangle(cornerRadius: 2))
                    .offset(x: -diameter * 0.35, y: diameter * 0.17)
            }
        }.allowsHitTesting(false)
    }
}

private struct CozyDagger: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: 0)); p.addLine(to: CGPoint(x: r.width * 0.68, y: r.height * 0.58))
            p.addLine(to: CGPoint(x: r.width * 0.32, y: r.height * 0.58)); p.closeSubpath()
            p.addRect(CGRect(x: r.width * 0.16, y: r.height * 0.58, width: r.width * 0.68, height: r.height * 0.12))
            p.addRect(CGRect(x: r.width * 0.42, y: r.height * 0.69, width: r.width * 0.16, height: r.height * 0.31))
        }
    }
}
