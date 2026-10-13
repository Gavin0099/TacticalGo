#if DEBUG || TACTICALGO_V11
import SwiftUI
import CryptoKit
import TacticalGoMotion

@MainActor struct MageBodyAssets {
    let cleanPlate: UIImage
    enum Invalid: Error { case manifest }
    static func loadOriginal(bundle: Bundle = .main) throws -> UIImage {
        guard let url = bundle.url(forResource: "mage-original", withExtension: "png", subdirectory: "PresentationLab"),
              SHA256.hash(data: try Data(contentsOf: url)).map({ String(format: "%02x", $0) }).joined() == "6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33",
              let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage,
              cg.width == 512, cg.height == 512 else { throw Invalid.manifest }
        return image
    }
    static func load(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "clean-plate", withExtension: "png", subdirectory: "PresentationLab"),
              SHA256.hash(data: try Data(contentsOf: url)).map({ String(format: "%02x", $0) }).joined() == "9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d",
              let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage,
              cg.width == 1254, cg.height == 1254,
              [.first,.last,.premultipliedFirst,.premultipliedLast].contains(cg.alphaInfo) else { throw Invalid.manifest }
        return Self(cleanPlate: image)
    }
}
/// The head/hat/hair, staff and gripping hand use the unchanged original B-v02.
/// Only masked disoccluded garment/small hat backing comes from the generated clean plate.
/// All coordinates, pivots and masks are in the same immutable 512px canvas.
struct MageBodyView: View {
    let original: UIImage
    let plate: UIImage
    let pose: MageBodyPose
    let width: CGFloat
    @ViewBuilder var body: some View {
        if pose == .rest { source(original).allowsHitTesting(false) }
        else { ZStack {
            ZStack {
                source(plate).mask(MageMask.patch)
                source(plate).mask(MageMask.cape)
                source(original).mask(MageMask.body.fill(style: FillStyle(eoFill: true)))
                source(original).mask(MageMask.cape)
                    .rotationEffect(.degrees(pose.cape), anchor: UnitPoint(x: 300/512.0,y: 348/512.0))
                source(plate).mask(MageMask.headPatch)
                source(original).mask(MageMask.head.fill(style: FillStyle(eoFill: true)))
                    .rotationEffect(.degrees(pose.head),anchor: UnitPoint(x: 269/512.0,y: 329/512.0))
                ZStack {
                    source(plate).mask(MageMask.sleeve)
                    ZStack {
                        source(original).mask(MageMask.staff)
                        source(original).mask(MageMask.hand)
                    }.offset(x: width * pose.heldX / 512)
                        .rotationEffect(.degrees(pose.elbow),anchor: UnitPoint(x: 174/512.0,y: 436/512.0))
                }.rotationEffect(.degrees(pose.shoulder),anchor: UnitPoint(x: 205/512.0,y: 370/512.0))

            }.rotationEffect(.degrees(pose.torso),anchor: UnitPoint(x: 263/512.0,y: 445/512.0))
                .offset(x: width * pose.torsoX / 512, y: width * pose.torsoY / 512)
        }.frame(width: width,height: width)
            .offset(y: width * pose.lift / 512).opacity(pose.opacity)
            .allowsHitTesting(false)
        }
    }
    /// Visual prop point transformed through the same held/shoulder/body pivots.
    /// Does not query or modify any rule or board coordinate.
    static func tipOffset(pose: MageBodyPose, width: CGFloat) -> CGPoint {
        func rotate(_ p: CGPoint,_ a: CGPoint,_ degrees: Double) -> CGPoint {
            let t = degrees * .pi / 180, x = p.x-a.x, y = p.y-a.y
            return CGPoint(x:a.x+x*cos(t)-y*sin(t),y:a.y+x*sin(t)+y*cos(t))
        }
        var p = CGPoint(x:64+pose.heldX,y:180)
        p = rotate(p,CGPoint(x:174,y:436),pose.elbow)
        p = rotate(p,CGPoint(x:205,y:370),pose.shoulder)
        p = rotate(p,CGPoint(x:263,y:445),pose.torso)
        return CGPoint(x:(p.x+pose.torsoX-256)*width/512,y:(p.y+pose.torsoY+pose.lift-448)*width/512)
    }
    private func source(_ image: UIImage) -> some View {
        Image(uiImage: image).resizable().interpolation(.high).frame(width: width,height: width)
    }
}

private struct MageMask: Shape {
    let points: [(Double,Double)]
    var subtract: [[(Double,Double)]] = []
    var minY = 0.0
    var maxY = 512.0
    func path(in r: CGRect) -> Path {
        var p = Path()
        for input in [points] + subtract {
            let polygon = clipped(clipped(input,at:minY,keepAbove:true),at:maxY,keepAbove:false)
            guard let first = polygon.first else { continue }
            p.move(to: CGPoint(x: r.minX+r.width*first.0/512,y:r.minY+r.height*first.1/512))
            for v in polygon.dropFirst() { p.addLine(to: CGPoint(x:r.minX+r.width*v.0/512,y:r.minY+r.height*v.1/512)) }
            p.closeSubpath()
        }
        return p
    }
    // Clip holes before even-odd fill; holes extending outside a head/body
    // region would otherwise draw source pixels there (including a prop ghost).
    private func clipped(_ input: [(Double,Double)],at y: Double,keepAbove: Bool) -> [(Double,Double)] {
        guard var previous = input.last else { return [] }
        var result: [(Double,Double)] = []
        func inside(_ p: (Double,Double)) -> Bool { keepAbove ? p.1 >= y : p.1 <= y }
        for current in input {
            if inside(previous) != inside(current) {
                let t = (y-previous.1)/(current.1-previous.1)
                result.append((previous.0+(current.0-previous.0)*t,y))
            }
            if inside(current) { result.append(current) }
            previous = current
        }
        return result
    }
    private static let held: [(Double,Double)] = [(64,150),(108,180),(138,207),(151,236),(156,270),(149,314),(153,350),(172,371),(184,408),(199,439),(195,470),(166,484),(137,468),(111,449),(100,426),(101,386),(81,351),(60,320),(37,303),(22,286),(16,260),(16,232),(30,192),(45,162)]
    static let staff = Self(points: [(64,156),(105,183),(132,204),(148,232),(149,249),(140,275),(137,311),(132,335),(147,371),(165,424),(187,473),(159,480),(142,460),(126,421),(105,388),(96,349),(81,328),(64,306),(51,290),(45,280),(32,268),(27,236),(31,211),(40,193)])
    static let hand = Self(points: [(136,373),(153,374),(162,384),(164,410),(170,426),(163,442),(145,443),(124,435),(113,424),(111,412),(110,391),(120,380)])
    static let headPatch = Self(points: [(105,142),(134,164),(157,202),(157,331),(108,331),(97,291),(101,250),(91,206)])
    static let cape = Self(points: [(297,333),(329,332),(363,345),(385,366),(412,400),(424,418),(412,443),(396,463),(368,470),(329,460),(311,425),(319,388)])
    static let sleeve = Self(points: [(151,350),(191,352),(205,381),(196,411),(175,423),(168,442),(155,457),(127,450),(111,420),(111,389)])
    static let patch = Self(points: [(104,349),(184,345),(212,375),(210,460),(190,477),(127,475),(105,446),(99,409)])
    static let head = Self(points: [(0,0),(512,0),(512,333),(0,333)],subtract: [held],maxY: 333)
    static let body = Self(points: [(0,333),(512,333),(512,512),(0,512)],subtract: [held,cape.points],minY:333)
}
#endif

#if DEBUG || TACTICALGO_V11
import SwiftUI
import CryptoKit
import TacticalGoCore
import TacticalGoMotion

/// Fixed Mage reference extracted from frozen signed phone build1023.
@MainActor struct P02CozyAssets {
    struct Sprite: Decodable {
        let file: String
        let pixelWidth: Int
        let pixelHeight: Int
        let anchorX: Double
        let anchorY: Double
        let widthInLocalD: Double?
        let widthInRadii: Double?
        let clipY: Double?
        let clipHeight: Double?
    }
    struct Manifest: Decodable { let soldiers: [String:Sprite] }
    struct Anim { let manifest: Manifest; let images:[String:UIImage]; func image(_ name:String)->UIImage { images[name]! } }
    let anim: Anim
    let mageBody: MageBodyAssets
    let heroes: [HeroClass:UIImage]
    let board: UIImage
    let shadow: UIImage
    enum Invalid: Error { case source }
    static func load() throws -> Self {
        let dir = "PresentationLab/P02"
        guard let pinURL=Bundle.main.url(forResource:"pins",withExtension:"json",subdirectory:dir) else { throw Invalid.source }
        let pins=try JSONDecoder().decode([String:String].self,from:Data(contentsOf:pinURL))
        var images:[String:UIImage]=[:]
        for (name,hash) in pins {
            guard let url=Bundle.main.url(forResource:name,withExtension:nil,subdirectory:dir) else {throw Invalid.source}
            let bytes=try Data(contentsOf:url)
            guard SHA256.hash(data:bytes).map({String(format:"%02x",$0)}).joined()==hash else {throw Invalid.source}
            if name.hasSuffix(".png") {guard let img=UIImage(data:bytes) else {throw Invalid.source};images[name]=img}
        }
        guard let url=Bundle.main.url(forResource:"anim01-manifest",withExtension:"json",subdirectory:dir) else {throw Invalid.source}
        let m=try JSONDecoder().decode(Manifest.self,from:Data(contentsOf:url))
        return try Self(anim:Anim(manifest:m,images:images),mageBody:MageBodyAssets.load(),heroes:[.mage:images["mage.png"]!,.warrior:images["warrior.png"]!,.rogue:images["rogue.png"]!],board:images["board.png"]!,shadow:images["shadow.png"]!)
    }
}
enum P02Cozy {
    static let bg = color(0xCCDCCE), card = color(0xF4EAD8), ink = color(0x243F43)
    static let gold = color(0xD9B46C), confirm = color(0xF1D394), sage = color(0x6C9276)
    static let selected = color(0xDCE7D5), disabled = color(0xDFE7DB), muted = color(0x496454)
    static let mage = color(0x9277B6), deepMage = color(0x59446F), danger = color(0x6E302B)
    static let coordinate = color(0x183438)
    static func color(_ value: UInt) -> Color {
        Color(red: Double((value >> 16) & 255)/255, green: Double((value >> 8)&255)/255, blue: Double(value&255)/255)
    }
}

enum P02HeroMarkerStyle { case legacy, thinRing }

struct P02CozyToken: View {
    let piece: Piece
    let assets: P02CozyAssets
    let pitch: CGFloat
    var squash = 1.0
    var magePose: MageBodyPose = .rest
    var markers: P02HeroMarkerStyle = .thinRing
    var commercialStyle = false
    let heroClass: HeroClass
    private var black: Bool { piece.owner == .one }
    private var diameter: CGFloat { pitch * (piece.kind == .commander ? 0.73 : piece.kind == .hero ? 0.74 : 0.62) }
    private var classColor: Color { heroClass == .mage ? P02Cozy.mage : heroClass == .warrior ? P02Cozy.sage : P02Cozy.coordinate }
    private var symbol: String { heroClass == .warrior ? "shield.fill" : heroClass == .mage ? "sparkle" : "bolt.fill" }
    @ViewBuilder var body: some View {
        if commercialStyle && piece.kind != .hero { commercialUnit }
        else if markers == .thinRing && piece.kind == .hero { readableHero }
        else { legacyToken }
    }
    private var legacyToken: some View {
        ZStack {
            Ellipse().fill(P02Cozy.ink.opacity(0.18)).frame(width: diameter * 1.05, height: diameter * 0.60).offset(y: pitch * 0.05)
            Ellipse().fill(black ? P02Cozy.coordinate : P02Cozy.muted).frame(width: diameter, height: diameter * 0.70).offset(y: pitch * 0.035)
            Ellipse().fill(black ? P02Cozy.color(0x263C50) : P02Cozy.color(0xF1E7D3)).frame(width: diameter, height: diameter * 0.70)
                .overlay(Ellipse().stroke(black ? P02Cozy.color(0xD5DBD9) : P02Cozy.color(0x786E59), lineWidth: 1))
            if piece.kind == .soldier {
                P02Anim01Sprite(asset: assets.anim.manifest.soldiers[black ? "black" : "white"]!, assets: assets.anim, pitch: pitch)
                    .scaleEffect(x: 1, y: squash, anchor: .bottom)
            } else if piece.kind == .hero, let image = assets.heroes[heroClass] {
                Ellipse().stroke(classColor, lineWidth: 2).frame(width: diameter * 0.90, height: diameter * 0.63)
                let width = pitch * 0.70
                Group {
                    if heroClass == .mage { MageBodyView(original: image, plate: assets.mageBody.cleanPlate, pose: magePose, width: width) }
                    else { Image(uiImage: image).resizable().frame(width: width, height: width) }
                }
                    .mask { Rectangle().frame(width: width, height: width * 390/512).offset(y: width * (225.0/512 - 0.5)) }
                    .offset(y: width * (0.5 - 420.0/512))
                Group {
                    if heroClass == .rogue { P02CozyDagger().fill(P02Cozy.card).frame(width: max(8, pitch * 0.17), height: max(8, pitch * 0.17)) }
                    else { Image(systemName: symbol).font(.system(size: max(8, pitch * 0.17), weight: .black)).foregroundStyle(P02Cozy.card) }
                }.padding(2).background(classColor, in: Circle()).offset(x: diameter * 0.40, y: diameter * 0.08)
            } else if piece.kind == .commander {
                Image(systemName: "crown.fill").font(.system(size: pitch * 0.26, weight: .black)).foregroundStyle(black ? P02Cozy.confirm : P02Cozy.coordinate)
            }
            if piece.kind != .soldier {
                Text(black ? "黑" : "白").font(.system(size: max(7, pitch * 0.14), weight: .black))
                    .foregroundStyle(black ? P02Cozy.card : P02Cozy.coordinate)
                    .padding(1).background(black ? P02Cozy.coordinate : P02Cozy.card, in: RoundedRectangle(cornerRadius: 2))
                    .offset(x: -diameter * 0.35, y: diameter * 0.17)
            }
        }.allowsHitTesting(false)
    }
    private var commercialUnit: some View {
        ZStack {
            P02SellUnitBase(black:black,commander:piece.kind == .commander,width:diameter)
            if piece.kind == .soldier {
                P02Anim01Sprite(asset:assets.anim.manifest.soldiers[black ? "black" : "white"]!,assets:assets.anim,pitch:pitch)
                    .scaleEffect(x:1,y:squash,anchor:.bottom)
            } else {
                Image(systemName:"crown.fill").font(.system(size:pitch*0.30,weight:.black))
                    .foregroundStyle(black ? P02Cozy.confirm : P02Cozy.coordinate)
                    .shadow(color:black ? Color.black.opacity(0.4) : Color.white.opacity(0.6),radius:0,y:1)
                    .offset(y:-pitch*0.04)
                Text(black ? "黑" : "白").font(.system(size:max(7,pitch*0.13),weight:.bold))
                    .foregroundStyle(black ? P02Cozy.card : P02Cozy.coordinate)
                    .offset(x:-diameter*0.31,y:diameter*0.12)
            }
        }.allowsHitTesting(false)
    }
    private var readableHero: some View {
        let canvas = pitch * (heroClass == .mage ? 0.92 : 0.88)
        let ground = 448.0
        return ZStack {
            // All base layers are behind the character. The intersection is unchanged.
            if commercialStyle { P02SellUnitBase(black:black,commander:false,width:pitch*0.74).offset(y:pitch*0.03) }
            else {
            Ellipse().fill(P02Cozy.ink.opacity(0.17)).frame(width: pitch * 0.81,height: pitch * 0.37).offset(y: pitch * 0.06)
            Ellipse().fill(black ? P02Cozy.color(0x263C50) : P02Cozy.color(0xF1E7D3))
                .frame(width: pitch * 0.74,height: pitch * 0.36).offset(y: pitch * 0.03)
            Ellipse().stroke(black ? P02Cozy.color(0x263C50) : P02Cozy.color(0xB59D66),lineWidth: max(1,pitch * 0.025))
                .frame(width: pitch * 0.76,height: pitch * 0.38).offset(y: pitch * 0.03)
            Ellipse().stroke(black ? P02Cozy.card : P02Cozy.ink,lineWidth: max(0.65,pitch * 0.012))
                .frame(width: pitch * 0.70,height: pitch * 0.32).offset(y: pitch * 0.03)
            }
            if let image = assets.heroes[heroClass] {
                Group {
                    if heroClass == .mage { MageBodyView(original: image,plate:assets.mageBody.cleanPlate,pose:magePose,width:canvas) }
                    else { Image(uiImage:image).resizable().frame(width:canvas,height:canvas) }
                }
                .offset(y:canvas * (0.5-ground/512))
            }
            // Solid disc vs hollow diamond is readable without faction color.
            Group {
                if black { Circle().fill(P02Cozy.card).overlay(Circle().fill(P02Cozy.coordinate).padding(0.7)) }
                else { P02CozyFactionDiamond().fill(P02Cozy.ink).overlay(P02CozyFactionDiamond().fill(P02Cozy.card).padding(1)) }
            }.frame(width:max(3.5,pitch * 0.10),height:max(3.5,pitch * 0.10))
                .offset(x:-pitch * 0.20,y:pitch * 0.225)
            if pitch >= 32 {
                Group {
                    if heroClass == .rogue { P02CozyDagger().fill(black ? P02Cozy.card : P02Cozy.coordinate) }
                    else { Image(systemName:symbol).font(.system(size:max(4.5,pitch * 0.105),weight:.bold)).foregroundStyle(black ? P02Cozy.card : P02Cozy.coordinate) }
                }.frame(width:pitch * 0.12,height:pitch * 0.12)
                    .offset(x:pitch * 0.23,y:pitch * 0.215)
            }
        }.allowsHitTesting(false)
    }

}

private struct P02CozyDagger: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.midX, y: 0)); p.addLine(to: CGPoint(x: r.width * 0.68, y: r.height * 0.58))
            p.addLine(to: CGPoint(x: r.width * 0.32, y: r.height * 0.58)); p.closeSubpath()
            p.addRect(CGRect(x: r.width * 0.16, y: r.height * 0.58, width: r.width * 0.68, height: r.height * 0.12))
            p.addRect(CGRect(x: r.width * 0.42, y: r.height * 0.69, width: r.width * 0.16, height: r.height * 0.31))
        }
    }
}

private struct P02CozyFactionDiamond: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to:CGPoint(x:r.midX,y:r.minY));p.addLine(to:CGPoint(x:r.maxX,y:r.midY));p.addLine(to:CGPoint(x:r.midX,y:r.maxY));p.addLine(to:CGPoint(x:r.minX,y:r.midY));p.closeSubpath()
        }
    }
}

struct P02SellUnitBase: View {
    let black: Bool
    let commander: Bool
    let width: CGFloat
    var body: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.30)).frame(width:width*1.10,height:width*0.48).blur(radius: 1).offset(y:width*0.12)
            Ellipse().fill(black ? P02Cozy.color(0x102B38) : P02Cozy.color(0xAF9C78)).frame(width:width,height:width*0.51).offset(y:width*0.09)
            Ellipse().fill(LinearGradient(colors:black ? [P02Cozy.color(0x355665),P02Cozy.color(0x152E3B)] : [P02Cozy.color(0xFFF6E1),P02Cozy.color(0xD4C6A4)],startPoint:.topLeading,endPoint:.bottomTrailing))
                .frame(width:width,height:width*0.48)
                .overlay(Ellipse().stroke(commander ? P02Cozy.color(0xD7AD63) : black ? P02Cozy.color(0xCBDAD5) : P02Cozy.color(0x786B51),lineWidth:commander ? 1.6 : 0.85))
            if commander { Ellipse().stroke(black ? P02Cozy.card.opacity(0.50) : P02Cozy.coordinate.opacity(0.35),lineWidth:0.6).frame(width:width*0.84,height:width*0.33) }
        }.allowsHitTesting(false)
    }
}



struct P02Anim01Sprite: View {
    let asset: P02CozyAssets.Sprite
    let assets: P02CozyAssets.Anim
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

public struct P02SkillBurstSample: Equatable, Sendable {
    public let x: Double, y: Double, tailX: Double, tailY: Double, alpha: Double, scale: Double
    public static func samples(at age: Double, lifetime: Double = 0.26, count: Int = 18, flatten: Double = 0.48) -> [Self] {
        guard age.isFinite, lifetime.isFinite, age >= 0, lifetime > 0, age < lifetime else { return [] }
        let t = age / lifetime, n = min(28, max(0, count)), f = min(1, max(0.15, flatten))
        return (0..<n).map { i in
            let angle = Double(i) * 2.399963229728653
            let speed = 0.32 + Double((i * 7) % 11) / 30
            // Fast launch followed by damping; small gravity arc never reaches the next anchor.
            func p(_ time: Double) -> (Double, Double) {
                let r = speed * (1 - exp(-4 * time))
                return (cos(angle) * r, sin(angle) * r * f - 0.12 * sin(.pi * time))
            }
            let head = p(t), tail = p(max(0, t - 0.12))
            return Self(x: head.0, y: head.1, tailX: tail.0, tailY: tail.1,
                        alpha: pow(1-t, 1.3), scale: (0.028 + Double(i % 3) * 0.012) * (1-0.6*t))
        }
    }
}

/// Describes real successful first-skill receipts. No rule resolution or state writes.
public struct P02SkillVFX: Equatable, Sendable {
    public enum Kind: String, Sendable { case bastion, magicHand, swap }
    public let kind: Kind
    public let caster: Player
    public let hero: Point
    public let sources: [Point]
    public let destinations: [Point]
    public let captures: [CapturedPiece]
    public let release: Double, moveStart: Double, arrival: Double, captureStart: Double, end: Double
    public static let reducedHintDuration = 0.24
    public func isActive(at time: Double) -> Bool { time >= 0 && time < end }
    init(_ receipt:MagePresentationPlan) {
        let clip=receipt.clip
        kind = .magicHand;caster=clip.caster;hero=clip.hero;sources=[clip.from];destinations=[clip.to];captures=clip.captures
        release=clip.timing.release;moveStart=clip.timing.moveStart;arrival=clip.timing.arrival;captureStart=clip.timing.captureStart;end=clip.duration
    }
}

import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Finite charge / ribbon / impact effects; successful receipt only. Tactical overlays stay above it.
struct P02SkillVFXLayer: View {
    let receipt: MagePresentationPlan
    let id: Int
    let plan: P02SkillVFX
    let elapsed: Double
    let pitch: CGFloat
    let size: CGSize
    let reduced: Bool
    let foreground: Bool
    let center: (Point) -> CGPoint
    @State private var reducedVisible = true

    var body: some View {
        Canvas { context, _ in
            if reduced {
                if reducedVisible { drawReduced(&context) }
            } else if plan.isActive(at:elapsed) {
                if foreground { drawForeground(&context) } else { drawGround(&context) }
            }
        }
        .frame(width:size.width,height:size.height)
        .allowsHitTesting(false).accessibilityHidden(true)
        .task(id:id) {
            reducedVisible = true
            guard reduced else {return}
            do {try await Task.sleep(for:.seconds(P02SkillVFX.reducedHintDuration))} catch {return}
            reducedVisible = false
        }
    }
    private var accent: Color {
        switch plan.kind {
        case .bastion: Color(red:0.76,green:0.46,blue:0.10)
        case .magicHand: Color(red:0.32,green:0.29,blue:0.76)
        case .swap: Color(red:0.51,green:0.35,blue:0.67)
        }
    }
    private let light = Color(red:1,green:0.95,blue:0.78)
    private func u(_ start:Double,_ finish:Double) -> Double { MotionCurves.clamp((elapsed-start)/max(0.001,finish-start)) }
    private func offset(_ p:CGPoint,_ x:CGFloat=0,_ y:CGFloat=0) -> CGPoint {CGPoint(x:p.x+x,y:p.y+y)}
    private func ring(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double,_ color:Color?=nil,_ ellipse:Bool=false,_ width:CGFloat=1.6) {
        let rect=CGRect(x:p.x-radius,y:p.y-radius*(ellipse ? 0.36:1),width:2*radius,height:2*radius*(ellipse ? 0.36:1))
        let path=Path(ellipseIn:rect)
        context.stroke(path,with:.color((color ?? accent).opacity(alpha)),lineWidth:width)
    }
    private func aura(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double) {
        let path=Path(ellipseIn:CGRect(x:p.x-radius,y:p.y-radius*0.35,width:radius*2,height:radius*0.7))
        context.fill(path,with:.radialGradient(Gradient(colors:[accent.opacity(alpha),accent.opacity(0)]),center:p,startRadius:0,endRadius:radius))
    }
    private func stars(_ context:inout GraphicsContext,_ p:CGPoint,_ progress:Double,_ count:Int=5) {
        guard progress>=0,progress<1 else{return}
        for i in 0..<count {
            let angle=Double(i)*2*Double.pi/Double(count)+0.3
            let radius=pitch*CGFloat(0.22+0.16*progress)
            let q=offset(p,CGFloat(cos(angle))*radius,CGFloat(sin(angle))*radius*0.40-pitch*CGFloat(0.08*progress))
            let s=max(1,pitch*0.035)*CGFloat(1-progress)
            let path=Path { v in v.move(to:offset(q,0,-s));v.addLine(to:offset(q,s,0));v.addLine(to:offset(q,0,s));v.addLine(to:offset(q,-s,0));v.closeSubpath() }
            context.fill(path,with:.color(light.opacity(0.85*(1-progress))))
        }
    }
    private func cornerMarks(_ context:inout GraphicsContext,_ p:CGPoint,_ alpha:Double) {
        let r=pitch*0.39,l=pitch*0.11
        for sx in [CGFloat(-1),CGFloat(1)] {for sy in [CGFloat(-1),CGFloat(1)] {
            let path=Path {v in
                v.move(to:offset(p,sx*(r-l),sy*r*0.48));v.addLine(to:offset(p,sx*r,sy*r*0.48));v.addLine(to:offset(p,sx*r,sy*(r*0.48-l)))
            }
            context.stroke(path,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:1.7,lineCap:.round,lineJoin:.round))
        }}
    }
    /// A colored envelope supplies contrast on wood; the warm core is deliberately smaller.
    private func glow(_ context:inout GraphicsContext,_ p:CGPoint,_ radius:CGFloat,_ alpha:Double,_ color:Color?=nil,_ flat:CGFloat=1) {
        guard alpha>0 else{return}
        let c=color ?? accent
        let path=Path(ellipseIn:CGRect(x:p.x-radius,y:p.y-radius*flat,width:radius*2,height:radius*2*flat))
        context.fill(path,with:.radialGradient(Gradient(stops:[.init(color:light.opacity(alpha),location:0),.init(color:c.opacity(alpha*0.86),location:0.23),.init(color:c.opacity(alpha*0.38),location:0.55),.init(color:c.opacity(0),location:1)]),center:p,startRadius:0,endRadius:radius))
    }
    private func ribbon(_ context:inout GraphicsContext,_ points:[CGPoint],_ width:CGFloat,_ alpha:Double) {
        guard points.count>1,alpha>0 else{return}
        var path=Path();path.move(to:points[0]);for q in points.dropFirst(){path.addLine(to:q)}
        // Distinct saturated silhouette, soft halo, then a small luminous center.
        var halo=context;halo.addFilter(.blur(radius:max(1,pitch*0.055)))
        halo.stroke(path,with:.color(accent.opacity(alpha*0.60)),style:StrokeStyle(lineWidth:width*2.4,lineCap:.round,lineJoin:.round))
        context.stroke(path,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:width,lineCap:.round,lineJoin:.round))
        context.stroke(path,with:.color(light.opacity(alpha*0.88)),style:StrokeStyle(lineWidth:max(1,width*0.24),lineCap:.round,lineJoin:.round))
    }
    private func burst(_ context:inout GraphicsContext,_ p:CGPoint,_ age:Double,_ count:Int=18,_ flat:Double=0.48,_ lifetime:Double=0.26) {
        for sample in P02SkillBurstSample.samples(at:age,lifetime:lifetime,count:count,flatten:flat) {
            let q=offset(p,pitch*sample.x,pitch*sample.y),tail=offset(p,pitch*sample.tailX,pitch*sample.tailY)
            var line=Path();line.move(to:tail);line.addLine(to:q)
            context.stroke(line,with:.color(accent.opacity(sample.alpha)),style:StrokeStyle(lineWidth:max(1.4,pitch*sample.scale*1.8),lineCap:.round))
            context.stroke(line,with:.color(light.opacity(sample.alpha)),style:StrokeStyle(lineWidth:max(0.8,pitch*sample.scale*0.65),lineCap:.round))
            glow(&context,q,max(1.8,pitch*sample.scale*1.5),sample.alpha*0.75)
        }
    }
    private func impact(_ context:inout GraphicsContext,_ p:CGPoint,_ start:Double,_ lifetime:Double=0.26,_ count:Int=18) {
        guard elapsed>=start,elapsed<start+lifetime else{return}
        let t=u(start,start+lifetime),launch=1-pow(1-t,3)
        glow(&context,p,pitch*CGFloat(0.28+0.35*launch),0.88*pow(1-t,2),nil,0.43)
        ring(&context,p,pitch*CGFloat(0.15+0.50*launch),0.95*(1-t),nil,true,pitch*CGFloat(0.035*(1-t))+1)
        ring(&context,p,pitch*CGFloat(0.11+0.43*launch),0.8*(1-t),light,true,1.3)
        burst(&context,p,elapsed-start,count,0.38,lifetime)
    }
    private func chargeSeal(_ context:inout GraphicsContext,_ hero:CGPoint) {
        guard elapsed<plan.release else{return}
        let charge=u(0,plan.release),radius=pitch*CGFloat(0.72-0.05*charge)
        glow(&context,hero,radius*1.2,0.42+0.30*charge,nil,0.4)
        // Broken sweeping arcs and inward motes create visible gathering, not a static UI ring.
        for i in 0..<3 {
            let angle=Double(i)*2*Double.pi/3+elapsed*5
            var points:[CGPoint]=[]
            for j in 0...18 {
                let a=angle+Double(j)/18*1.30
                points.append(offset(hero,CGFloat(cos(a))*radius,CGFloat(sin(a))*radius*0.36))
            }
            ribbon(&context,points,max(2.2,pitch*0.06),0.80+0.20*charge)
        }
        if plan.kind != .swap {
            // Discrete runic teeth make a magical seal, rather than a selection highlight.
            for i in 0..<6 {
                let a=Double(i)*Double.pi/3,q=offset(hero,CGFloat(cos(a))*radius*0.82,CGFloat(sin(a))*radius*0.29)
                let r=pitch*0.07
                let rune=Path {v in v.move(to:offset(q,-r,0));v.addLine(to:offset(q,0,-r));v.addLine(to:offset(q,r,0));v.addLine(to:offset(q,0,r));v.closeSubpath()}
                context.fill(rune,with:.color(accent.opacity(0.75+0.25*charge)))
                context.stroke(rune,with:.color(light.opacity(0.8*charge)),lineWidth:1)
            }
        }
        for i in 0..<8 {
            let age=(charge+Double(i)/8).truncatingRemainder(dividingBy:1)
            let a=Double(i)*2.39996+charge*1.3,r=pitch*CGFloat(0.78-0.38*age)
            glow(&context,offset(hero,CGFloat(cos(a))*r,CGFloat(sin(a))*r*0.36),max(1.8,pitch*0.045),sin(.pi*age)*0.9)
        }
    }
    private func drawGround(_ context:inout GraphicsContext) {
        let hero=offset(center(plan.hero),0,pitch*0.27)
        chargeSeal(&context,hero)
        switch plan.kind {
        case .bastion:
            // Two matching summoning shafts establish both new anchors before the body drops.
            if elapsed>=plan.release,elapsed<plan.arrival+0.14 {
                let rise=u(plan.release,plan.arrival),fade=1-u(plan.arrival,plan.arrival+0.14)
                for p in plan.destinations {
                    let q=offset(center(p),0,pitch*0.16),height=pitch*CGFloat(0.62+0.16*rise)
                    let shaft=Path(roundedRect:CGRect(x:q.x-pitch*0.25,y:q.y-height,width:pitch*0.50,height:height),cornerRadius:pitch*0.12)
                    context.fill(shaft,with:.linearGradient(Gradient(colors:[accent.opacity(0),accent.opacity(0.42*fade),light.opacity(0.80*fade)]),startPoint:offset(q,0,-height),endPoint:q))
                    ring(&context,q,pitch*0.34,fade,nil,true,2.6)
                    for i in 0..<5 {
                        let t=(rise+Double(i)*0.21).truncatingRemainder(dividingBy:1)
                        glow(&context,offset(q,pitch*CGFloat(Double(i-2)*0.08),-height*CGFloat(t)),max(1.5,pitch*0.045),sin(.pi*t)*fade)
                    }
                }
            }
            // Shield contact, then the same-clock paired landings: one defensive impact.
            impact(&context,hero,plan.arrival,0.28,24)
            for p in plan.destinations {impact(&context,offset(center(p),0,pitch*0.17),plan.arrival,0.26,18)}
        case .magicHand:
            let source=offset(center(plan.sources[0]),0,pitch*0.16),target=offset(center(plan.destinations[0]),0,pitch*0.17)
            if elapsed>=plan.release,elapsed<plan.arrival {
                let t=u(plan.moveStart,plan.arrival)
                let q=CGPoint(x:source.x+(target.x-source.x)*t,y:source.y+(target.y-source.y)*t)
                glow(&context,q,pitch*0.43,0.6,nil,0.45)
                ring(&context,q,pitch*0.35,0.85,nil,true,2.2)
                burst(&context,source,elapsed-plan.moveStart,12,0.38,0.20)
            }
            impact(&context,target,plan.arrival,0.28,22)
        case .swap:
            for p in plan.sources {impact(&context,offset(center(p),0,pitch*0.17),plan.moveStart,0.18,12)}
            for p in plan.destinations {impact(&context,offset(center(p),0,pitch*0.17),plan.arrival,0.22,14)}
        }
        // A captured unit's departure remains subordinate to its exact event payload.
        if elapsed>=plan.captureStart,elapsed<plan.captureStart+0.18 {
            for p in plan.captures {burst(&context,center(p.at),elapsed-plan.captureStart,10,0.6,0.18)}
        }
    }
    private func arrow(_ context:inout GraphicsContext,_ from:CGPoint,_ to:CGPoint,_ alpha:Double,_ dashed:Bool=false) {
        let dx=to.x-from.x,dy=to.y-from.y,d=max(1,hypot(dx,dy)),ux=dx/d,uy=dy/d
        let trim=min(pitch*0.22,d*0.24),a=offset(from,ux*trim,uy*trim),b=offset(to,-ux*trim,-uy*trim)
        let p=Path {v in v.move(to:a);v.addLine(to:b);v.move(to:offset(b,-ux*4-uy*2,-uy*4+ux*2));v.addLine(to:b);v.addLine(to:offset(b,-ux*4+uy*2,-uy*4-ux*2))}
        context.stroke(p,with:.color(accent.opacity(alpha)),style:StrokeStyle(lineWidth:1.8,lineCap:.round,lineJoin:.round,dash:dashed ? [3,2]:[]))
    }
    private func drawForeground(_ context:inout GraphicsContext) {
        let hero=center(plan.hero)
        // This local staff core deliberately sits above the staff, not across the face.
        if plan.kind == .magicHand,elapsed<plan.moveStart {
            let tip=MageBodyView.tipOffset(pose:receipt.pose(at:elapsed),width:pitch*0.92)
            let orb=offset(hero,tip.x,tip.y),charge=u(0,plan.release)
            glow(&context,orb,pitch*CGFloat(0.17+0.12*charge),0.75+0.2*charge)
            for i in 0..<5 {
                let a=Double(i)*2*Double.pi/5+elapsed*12,r=pitch*CGFloat(0.20-0.12*charge)
                glow(&context,offset(orb,CGFloat(cos(a))*r,CGFloat(sin(a))*r),max(1.5,pitch*0.04),0.85)
            }
        }
        // A board-sized sibling layer avoids per-token clipping (Pow's particle-layer lesson).
        // Only directional strokes are masked; ground bursts are behind the real actors.
        var ink=context,mask=Path(CGRect(origin:.zero,size:size))
        for p in receipt.before.board.points where receipt.before.board[p] != nil || plan.destinations.contains(p) {
            let q=center(p);mask.addRect(CGRect(x:q.x-pitch*0.32,y:q.y-pitch*0.63,width:pitch*0.64,height:pitch*0.70))
        }
        ink.clip(to:mask,style:FillStyle(eoFill:true))
        // Visible impact fragments occupy the free floor band, never a face or grip.
        // The behind-actor field gives depth; this front field prevents the landing disappearing
        // entirely beneath a cutout's opaque skirt / shield / token base.
        if plan.kind == .bastion {
            impact(&ink,offset(hero,0,pitch*0.27),plan.arrival,0.28,20)
            for p in plan.destinations {impact(&ink,offset(center(p),0,pitch*0.27),plan.arrival,0.26,20)}
        } else if plan.kind == .magicHand {
            impact(&ink,offset(center(plan.destinations[0]),0,pitch*0.27),plan.arrival,0.28,22)
        } else {
            for p in plan.destinations {impact(&ink,offset(center(p),0,pitch*0.27),plan.arrival,0.22,14)}
        }
        if plan.kind == .magicHand,elapsed>=plan.release,elapsed<plan.arrival {
            let source=offset(center(plan.sources[0]),0,pitch*0.17),target=offset(center(plan.destinations[0]),0,pitch*0.17)
            let tip=MageBodyView.tipOffset(pose:receipt.pose(at:elapsed),width:pitch*0.92)
            let orb=offset(hero,tip.x,tip.y),control=offset(hero,(source.x-hero.x)*0.58,pitch*0.45)
            func point(_ f:Double) -> CGPoint {
                let t=CGFloat(MotionCurves.clamp(f)),a=1-t
                return CGPoint(x:a*a*orb.x+2*a*t*control.x+t*t*source.x,y:a*a*orb.y+2*a*t*control.y+t*t*source.y)
            }
            // A rapidly advancing comet strikes at the movement cue; finite trailing sparks.
            let flight=u(plan.release,plan.moveStart),head=point(flight)
            var points:[CGPoint]=[]
            for i in 0...16 {points.append(point(max(0,flight-0.48)+Double(i)/16*min(0.48,flight)))}
            let alpha=elapsed<plan.moveStart ? 1.0:0.65*(1-u(plan.moveStart,plan.arrival))
            ribbon(&ink,points,max(3,pitch*0.12),alpha)
            glow(&ink,head,max(5,pitch*0.23),alpha)
            for i in 0..<7 {
                let f=max(0,flight-Double(i)*0.075),q=point(f),a=Double(i)*2.39996
                glow(&ink,offset(q,CGFloat(sin(a))*pitch*0.08,CGFloat(cos(a))*pitch*0.06),max(1.5,pitch*0.045),alpha*(1-Double(i)/8))
            }
            // The impulse trail follows the same real pushed unit's one-cell trajectory.
            let travel=u(plan.moveStart,plan.arrival)
            if elapsed>=plan.moveStart {
                let body=CGPoint(x:source.x+(target.x-source.x)*travel,y:source.y+(target.y-source.y)*travel)
                ribbon(&ink,[source,body],max(2.4,pitch*0.10),0.85*(1-travel*0.65))
                burst(&ink,source,elapsed-plan.moveStart,16,0.5,0.22)
            }
        }
        if plan.kind == .swap,elapsed>=plan.release,elapsed<plan.arrival {
            let f=u(plan.moveStart,plan.arrival)
            for i in 0..<2 {
                let a=center(plan.sources[i]),b=center(plan.destinations[i]),vertical=plan.sources[i].x==plan.destinations[i].x
                func position(_ fraction:Double) -> CGPoint {
                    let t=MotionCurves.clamp(fraction),p=MotionCurves.swapProgress(t),lane=pitch*(i==0 ? -0.16:0.08)*CGFloat(sin(.pi*t))
                    return CGPoint(x:a.x+(b.x-a.x)*p+(vertical ? lane:0),y:a.y+(b.y-a.y)*p+(vertical ? 0:lane)+pitch*0.17)
                }
                // Two curved speed ribbons retain the actual opposing trajectories and identity.
                for lane in 0..<3 {
                    let shift=CGFloat(lane-1)*pitch*0.06,alpha=Double(lane==1 ? 0.90:0.45)
                    let points=(0...14).map {j in offset(position(max(0,f-0.50)+Double(j)/14*min(0.50,f)),0,shift)}
                    ribbon(&ink,points,max(2,pitch*(lane==1 ? 0.10:0.035)),alpha)
                }
                let q=position(f)
                glow(&ink,q,pitch*0.27,0.7,nil,0.6)
                if elapsed<plan.moveStart {arrow(&ink,offset(a,0,pitch*0.2),offset(b,0,pitch*0.2),0.75,true)}
            }
        }
    }
    private func drawReduced(_ context:inout GraphicsContext) {
        if !foreground {
            for p in plan.destinations {cornerMarks(&context,offset(center(p),0,pitch*0.16),0.9)}
        } else if plan.kind != .bastion {
            for (a,b) in zip(plan.sources,plan.destinations) {arrow(&context,offset(center(a),0,pitch*0.22),offset(center(b),0,pitch*0.22),0.8,true)}
        }
    }
}

#endif

#if DEBUG || TACTICALGO_V11
/// Sparse, receipt-driven Mage effects. Native board/pawns remain primary;
/// no independent animation task or synthetic capture/winner inference.
struct P03MageEffects: View {
    let receipt: MagePresentationPlan
    let elapsed: Double
    let pitch: CGFloat
    let size: CGSize
    let reduced: Bool
    let foreground: Bool
    let center: (Point) -> CGPoint
    private let violet=Color(red:0.43,green:0.29,blue:0.76)
    private let crystal=Color(red:0.48,green:0.89,blue:0.96)
    func offset(_ p:CGPoint,_ x:CGFloat,_ y:CGFloat) -> CGPoint { CGPoint(x:p.x+x,y:p.y+y) }
    func unit(_ start:Double,_ end:Double) -> Double { min(1,max(0,(elapsed-start)/max(0.001,end-start))) }
    var body: some View {
        // Immutable receipt/clock snapshot only; drawing must not monopolize
        // the main actor that owns cancellation and sound scheduling.
        Canvas(rendersAsynchronously: true) { context,_ in
            guard !reduced, elapsed >= 0, elapsed < receipt.clip.duration else { return }
            let t=receipt.clip.timing,hero=center(receipt.clip.hero)
            let tip=MageBodyView.tipOffset(pose:receipt.pose(at:elapsed),width:pitch*0.92)
            let staff=offset(hero,tip.x,tip.y)
            let source=offset(center(receipt.clip.from),0,pitch*0.20)
            let target=offset(center(receipt.clip.to),0,pitch*0.20)
            if foreground {
                // Local crystal highlight stays on the existing prop; it does
                // not cover the face, change the hand, or mark a board point.
                if elapsed < t.moveStart {
                    let charge=unit(0,t.release),fade=1-unit(t.release,t.moveStart)
                    let radius=pitch*CGFloat(0.055+0.055*charge)
                    context.fill(Path(ellipseIn:CGRect(x:staff.x-radius,y:staff.y-radius,width:2*radius,height:2*radius)),with:.color(crystal.opacity(0.75*fade)))
                    context.stroke(Path(ellipseIn:CGRect(x:staff.x-radius*1.6,y:staff.y-radius*1.6,width:3.2*radius,height:3.2*radius)),with:.color(violet.opacity(0.55*fade)),lineWidth:1)
                }
                return
            }
            if elapsed >= t.release,elapsed < t.moveStart {
                let f=CGFloat(unit(t.release,t.moveStart)),a=1-f
                let bend=CGPoint(x:(staff.x+source.x)*0.5,y:max(staff.y,source.y)+pitch*0.20)
                func point(_ q:CGFloat) -> CGPoint {
                    let r=1-q
                    return CGPoint(x:r*r*staff.x+2*r*q*bend.x+q*q*source.x,y:r*r*staff.y+2*r*q*bend.y+q*q*source.y)
                }
                let head=CGPoint(x:a*a*staff.x+2*a*f*bend.x+f*f*source.x,y:a*a*staff.y+2*a*f*bend.y+f*f*source.y)
                var path=Path(); path.move(to:point(max(0,f-0.40)))
                for i in 1...12 { path.addLine(to:point(max(0,f-0.40)+CGFloat(i)/12*min(0.40,f))) }
                context.stroke(path,with:.color(violet.opacity(0.70)),style:StrokeStyle(lineWidth:max(1,pitch*0.035),lineCap:.round))
                let r=max(1.1,pitch*0.06)
                context.fill(Path(ellipseIn:CGRect(x:head.x-r,y:head.y-r,width:r*2,height:r*2)),with:.color(crystal))
            }
            if elapsed >= t.moveStart,elapsed < t.arrival {
                // This trail samples the same pawn progress as the real actor.
                let f=CGFloat(receipt.clip.progress(at:elapsed))
                let q=CGPoint(x:source.x+(target.x-source.x)*f,y:source.y+(target.y-source.y)*f)
                var trail=Path(); trail.move(to:source); trail.addLine(to:q)
                context.stroke(trail,with:.color(violet.opacity(0.65*(1-Double(f)*0.7))),style:StrokeStyle(lineWidth:max(1,pitch*0.045),lineCap:.round))
            }
            if elapsed >= t.arrival,elapsed < t.arrival+0.16 {
                let f=unit(t.arrival,t.arrival+0.16),r=pitch*CGFloat(0.30+0.13*f)
                context.stroke(Path(ellipseIn:CGRect(x:target.x-r,y:target.y-r*0.30,width:r*2,height:r*0.60)),with:.color(violet.opacity(0.8*(1-f))),lineWidth:max(1,pitch*0.035))
            }
            if elapsed >= t.captureStart,elapsed < t.captureEnd {
                let f=unit(t.captureStart,t.captureEnd)
                for captured in receipt.clip.captures {
                    let q=offset(center(captured.at),0,pitch*0.23)
                    for i in 0..<4 {
                        let a=Double(i)*Double.pi/2,r=pitch*CGFloat(0.18+0.20*f)
                        let p=offset(q,CGFloat(cos(a))*r,CGFloat(sin(a))*r*0.35)
                        context.fill(Path(ellipseIn:CGRect(x:p.x-1,y:p.y-1,width:2,height:2)),with:.color(violet.opacity(1-f)))
                    }
                }
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false)
    }
}

/// Runtime texture-atlas windows, decoded before a receipt starts. The
/// generated source file is retained unchanged; no art is redrawn or exported.
enum P04HandAssets {
    static func load() -> [UIImage] {
        guard let url=Bundle.main.url(forResource:"arcane-hand-atlas",withExtension:"png",subdirectory:"PresentationLab/P04"),
              let source=UIImage(contentsOfFile:url.path)?.cgImage, source.width == source.height*3 else { return [] }
        let edge=source.height
        return (0..<3).compactMap { index in
            guard let cell=source.cropping(to:CGRect(x:index*edge,y:0,width:edge,height:edge)) else { return nil }
            let image=UIImage(cgImage:cell)
            return image.preparingForDisplay() ?? image
        }
    }
}
struct P04HandSprite: View {
    let poses: [UIImage]
    let index: Int
    let width: CGFloat
    var body: some View {
        Image(uiImage:poses[index]).resizable().interpolation(.high)
            .frame(width:width,height:width)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A literal spell object supplies the story; the connecting beam and floor
/// pressure wave support it. No object/impact/capture is inferred from animation.
struct P04MageEffects: View {
    let receipt: MagePresentationPlan
    let poses: [UIImage]
    let elapsed: Double
    let pitch: CGFloat
    let size: CGSize
    let reduced: Bool
    let foreground: Bool
    let center: (Point) -> CGPoint
    private var frame: ArcaneHandFrame { .sample(at:elapsed,reduced:reduced) }
    private var source: CGPoint { let p=center(receipt.clip.from); return CGPoint(x:p.x,y:p.y-pitch*0.03) }
    private var target: CGPoint { let p=center(receipt.clip.to); return CGPoint(x:p.x,y:p.y-pitch*0.03) }
    private var unit: CGPoint {
        let a=center(receipt.clip.from),b=center(receipt.clip.to),d=max(0.001,hypot(b.x-a.x,b.y-a.y))
        return CGPoint(x:(b.x-a.x)/d,y:(b.y-a.y)/d)
    }
    private var staff: CGPoint {
        let p=center(receipt.clip.hero),q=MageBodyView.tipOffset(pose:receipt.pose(at:elapsed),width:pitch*0.92)
        return CGPoint(x:p.x+q.x,y:p.y+q.y)
    }
    private var pawn: CGPoint {
        let t=receipt.clip.progress(at:elapsed)
        return CGPoint(x:source.x+(target.x-source.x)*t,y:source.y+(target.y-source.y)*t)
    }
    private var hand: CGPoint {
        let u=unit,q=pawn,r=pitch*CGFloat(0.40+frame.recoil)
        let braced=CGPoint(x:q.x-u.x*r,y:q.y-u.y*r)
        let t=frame.reach
        return CGPoint(x:staff.x+(braced.x-staff.x)*t,y:staff.y+(braced.y-staff.y)*t-pitch*CGFloat(sin(t * .pi))*0.16)
    }
    private let violet=Color(red:0.39,green:0.24,blue:0.67)
    private let mint=Color(red:0.59,green:0.96,blue:0.88)
    var body: some View {
        ZStack {
            Canvas(rendersAsynchronously:true) { context,_ in
                guard !reduced, elapsed >= 0, elapsed < receipt.clip.duration else { return }
                if foreground {
                    // A growing, shaped crystal light at the prop, not a board marker.
                    if elapsed >= 0.08 && elapsed < 0.34 {
                        let t=min(1,max(0,(elapsed-0.08)/0.22)),alpha=1-min(1,max(0,(elapsed-0.30)/0.04))
                        let r=pitch*CGFloat(0.07+0.10*t),p=staff
                        let diamond=Path { v in
                            v.move(to:CGPoint(x:p.x,y:p.y-r*1.3));v.addLine(to:CGPoint(x:p.x+r*0.65,y:p.y));v.addLine(to:CGPoint(x:p.x,y:p.y+r));v.addLine(to:CGPoint(x:p.x-r*0.65,y:p.y));v.closeSubpath()
                        }
                        context.fill(diamond,with:.color(mint.opacity(alpha)))
                        context.stroke(diamond,with:.color(violet.opacity(alpha)),lineWidth:max(1,pitch*0.04))
                    }
                } else {
                    if elapsed >= 0.30 && elapsed < 0.88 {
                        let p=staff,q=hand,alpha=frame.alpha*(1-min(1,max(0,(elapsed-0.73)/0.15)))
                        var beam=Path();beam.move(to:p)
                        beam.addQuadCurve(to:q,control:CGPoint(x:(p.x+q.x)*0.5,y:max(p.y,q.y)+pitch*0.22))
                        context.stroke(beam,with:.color(violet.opacity(alpha*0.85)),style:StrokeStyle(lineWidth:pitch*0.10,lineCap:.round))
                        context.stroke(beam,with:.color(mint.opacity(alpha*0.8)),style:StrokeStyle(lineWidth:pitch*0.045,lineCap:.round))
                    }
                    // Contact emphasis is under the pawn. Its base and commander
                    // danger overlay stay readable above the spell.
                    if elapsed >= 0.68 && elapsed < 0.86 {
                        let t=(elapsed-0.68)/0.18,p=center(receipt.clip.to),r=pitch*CGFloat(0.31+0.19*t)
                        let wave=Path(ellipseIn:CGRect(x:p.x-r,y:p.y-r*0.32,width:r*2,height:r*0.64))
                        context.stroke(wave,with:.color(violet.opacity(0.95*(1-t))),lineWidth:pitch*CGFloat(0.07*(1-t)+0.02))
                        for sign in [-1.0,1.0] {
                            let q=CGPoint(x:p.x+sign*r,y:p.y-pitch*0.08),s=pitch*CGFloat(0.05*(1-t))
                            let star=Path {v in v.move(to:CGPoint(x:q.x,y:q.y-s*2));v.addLine(to:CGPoint(x:q.x+s,y:q.y));v.addLine(to:CGPoint(x:q.x,y:q.y+s*2));v.addLine(to:CGPoint(x:q.x-s,y:q.y));v.closeSubpath()}
                            context.fill(star,with:.color(mint.opacity(1-t)))
                        }
                    }
                }
            }.frame(width:size.width,height:size.height)
            if !foreground, frame.alpha > 0 {
                ZStack {
                    P04HandSprite(poses:poses,index:0,width:pitch*1.10).opacity(frame.open)
                    P04HandSprite(poses:poses,index:1,width:pitch*1.10).opacity(frame.cup)
                    P04HandSprite(poses:poses,index:2,width:pitch*1.10).opacity(frame.palm)
                }.scaleEffect(frame.scale)
                    .rotationEffect(.radians(atan2(unit.y,unit.x)))
                    .opacity(frame.alpha).position(hand)
            }
        }.frame(width:size.width,height:size.height).allowsHitTesting(false).accessibilityHidden(true)
    }
}

#endif
