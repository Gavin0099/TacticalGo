import SwiftUI
import CryptoKit
import TacticalGoMotion

@MainActor struct MageBodyAssets {
    let cleanPlate: UIImage
    static func load(bundle: Bundle = .main) throws -> Self {
        guard let url = bundle.url(forResource: "clean-plate", withExtension: "png", subdirectory: "MageBody"),
              SHA256.hash(data: try Data(contentsOf: url)).map({ String(format: "%02x", $0) }).joined() == "9a633d497e0ce5baaa1f726312d87b49507df65b1c997c84374fa2f612be294d",
              let image = UIImage(contentsOfFile: url.path), let cg = image.cgImage,
              cg.width == 1254, cg.height == 1254,
              [.first,.last,.premultipliedFirst,.premultipliedLast].contains(cg.alphaInfo) else { throw Anim01Assets.Invalid.manifest }
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
