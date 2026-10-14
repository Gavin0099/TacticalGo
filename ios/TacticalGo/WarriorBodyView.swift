#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Original B-v02 pixels form every visible identity/prop layer. The clean plate
/// is consumed only through garment holes, inside the original alpha silhouette.
/// Coordinates and pivots remain editable in the immutable 512px art canvas.
/// Movement between board points belongs to the receipt renderer, not this view.
struct WarriorBodyView: View {
    let original: UIImage
    let plate: UIImage
    let pose: WarriorBodyPose
    let width: CGFloat

    @ViewBuilder var body: some View {
        if pose == .rest {
            source(original).allowsHitTesting(false)
        } else {
            let rig = HeroCutoutRig.warrior
            ZStack {
                ZStack {
                    // Disoccluded cloth is behind all original-pixel layers.
                    backing(rig.backing)
                    originalLayer(.canvas, removing: rig.removedFromBody)
                    // A small original garment overlap closes a moving collar/
                    // cape joint without introducing any generated skin pixels.
                    ForEach(rig.seamUnderlap.indices, id: \.self) { i in
                        originalLayer(rig.seamUnderlap[i], removing: [rig.held] + (rig.shield.map { [$0] } ?? []))
                    }
                    originalLayer(rig.cloth)
                        .rotationEffect(.degrees(pose.cloth), anchor: unit(rig.clothPivot))
                    originalLayer(rig.head, removing: [rig.held])
                        .rotationEffect(.degrees(pose.head), anchor: unit(rig.headPivot))
                    // The grip, handle, guard and blade share exactly one transform.
                    originalLayer(rig.held)
                        .rotationEffect(.degrees(pose.held), anchor: unit(rig.heldPivot))
                        .offset(x: scaled(pose.heldX), y: scaled(pose.heldY))
                    if let shield = rig.shield {
                        // The whole shield, including the identity-pinned fork emblem,
                        // moves as a rigid original-pixel layer; it is never warped.
                        originalLayer(shield)
                            .rotationEffect(.degrees(pose.shield), anchor: unit(rig.shieldPivot))
                            .offset(x: scaled(pose.shieldX), y: scaled(pose.shieldY))
                    }
                }
                .rotationEffect(.degrees(pose.body), anchor: unit(rig.bodyPivot))
                .offset(x: scaled(pose.bodyX), y: scaled(pose.bodyY))
            }
            .frame(width: width, height: width)
            .offset(y: scaled(pose.lift))
            .opacity(pose.opacity)
            .allowsHitTesting(false)
        }
    }

    private func scaled(_ value: Double) -> CGFloat { width * value / 512 }
    private func unit(_ p: CGPoint) -> UnitPoint { UnitPoint(x: p.x / 512, y: p.y / 512) }
    private func source(_ image: UIImage) -> some View {
        Image(uiImage: image).resizable().interpolation(.high).frame(width: width, height: width)
    }
    private func originalLayer(_ region: HeroCutoutPolygon, removing holes: [HeroCutoutPolygon] = []) -> some View {
        source(original).mask(region).mask {
            // Destination-out forms a union of holes. Even-odd overlapping holes
            // could restore a duplicate hand/prop at their intersection.
            ZStack {
                Rectangle().fill(.white)
                ForEach(holes.indices, id: \.self) { i in
                    holes[i].fill(.white).blendMode(.destinationOut)
                }
            }.compositingGroup()
        }
    }
    private func backing(_ regions: [HeroCutoutPolygon]) -> some View {
        source(plate).mask {
            ZStack { ForEach(regions.indices, id: \.self) { regions[$0].fill(.white) } }
        }
        // No newly generated anatomy or background beyond the source silhouette.
        .mask(source(original))
    }
}

/// Spell echoes reuse the same original shield pixels and crest; no new art.
struct WarriorShieldProjection:View {
    let original:UIImage
    let width:CGFloat
    var body:some View {
        let canvas=width*512/250
        ZStack {
            Image(uiImage:original).resizable().interpolation(.high)
                .frame(width:canvas,height:canvas).mask(HeroCutoutRig.warrior.shield!)
                .offset(x:canvas*(0.5-366/512),y:canvas*(0.5-390.5/512))
        }.frame(width:width,height:width).clipped().allowsHitTesting(false)
    }
}

private struct HeroCutoutPolygon: Shape {
    let points: [CGPoint]
    init(_ points: [(Double, Double)]) { self.points = points.map { CGPoint(x: $0.0, y: $0.1) } }
    func path(in rect: CGRect) -> Path {
        Path { path in
            guard let first = points.first else { return }
            func point(_ p: CGPoint) -> CGPoint {
                CGPoint(x: rect.minX + rect.width * p.x / 512, y: rect.minY + rect.height * p.y / 512)
            }
            path.move(to: point(first))
            for p in points.dropFirst() { path.addLine(to: point(p)) }
            path.closeSubpath()
        }
    }
    static let canvas = Self([(0,0),(512,0),(512,512),(0,512)])
}

private struct HeroCutoutRig {
    let head: HeroCutoutPolygon
    let held: HeroCutoutPolygon
    let shield: HeroCutoutPolygon?
    let cloth: HeroCutoutPolygon
    let backing: [HeroCutoutPolygon]
    let seamUnderlap: [HeroCutoutPolygon]
    let headPivot: CGPoint
    let heldPivot: CGPoint
    let shieldPivot: CGPoint
    let clothPivot: CGPoint
    let bodyPivot: CGPoint
    var removedFromBody: [HeroCutoutPolygon] { [head, held, cloth] + (shield.map { [$0] } ?? []) }

    static let warrior: Self = {
        // Follow hair/skin/neck, not the silver shoulder: rotating a broad
        // horizontal chest cut would carry armour with the head and open a seam.
        let head = HeroCutoutPolygon([(90,0),(400,0),(400,190),(359,230),(327,253),(305,271),(286,279),(266,296),(234,288),(214,276),(192,258),(174,245),(147,226),(114,216),(90,193)])
        // Move the complete gauntlet and gold guard with the gripping hand.
        // Cutting through those outlines left angular stationary fragments.
        let held = HeroCutoutPolygon([(171,343),(194,343),(207,356),(216,388),(236,397),(241,430),(255,435),(268,440),(279,458),(285,492),(267,512),(170,512),(106,492),(77,470),(68,444),(81,421),(108,409),(149,409),(159,391),(166,369),(161,354)])
        // Include the original black/gold rim, not only its blue interior.
        // The old diagonal cut left a second gold edge on the chest when raised.
        let shield = HeroCutoutPolygon([(241,334),(246,317),(412,271),(438,269),(480,308),(491,329),(479,408),(457,449),(417,491),(369,512),(307,512),(289,483),(273,452),(256,414),(244,374)])
        let cloth = HeroCutoutPolygon([(63,371),(89,379),(105,391),(80,409),(91,432),(79,442),(42,427),(30,413),(42,389)])
        return Self(head: head, held: held, shield: shield, cloth: cloth,
            backing: [
                // Only the sleeve/chest originally hidden by the gripping hand.
                held,
                // Only the old shield occlusion is eligible for this backing.
                // The shifted shield exposes its top strip during release;
                // filling only the left strip would leave a transparent wedge.
                // The face and emblem still come exclusively from original.
                shield,
                HeroCutoutPolygon([(39,385),(86,381),(100,407),(78,439),(44,425)])
            ],
            seamUnderlap: [
                HeroCutoutPolygon([(128,269),(170,274),(203,283),(218,300),(199,322),(148,318),(127,297)]),
                HeroCutoutPolygon([(224,296),(275,298),(302,293),(317,310),(282,329),(230,326)])
            ],
            headPivot: CGPoint(x:257,y:289), heldPivot: CGPoint(x:146,y:414),
            shieldPivot: CGPoint(x:354,y:278), clothPivot: CGPoint(x:93,y:378),
            bodyPivot: CGPoint(x:259,y:460))
    }()

}

#endif
