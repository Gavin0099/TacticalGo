import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Original B-v02 pixels form every visible identity/prop layer. The clean plate
/// is consumed only through garment holes, inside the original alpha silhouette.
/// Coordinates and pivots remain editable in the immutable 512px art canvas.
/// Movement between board points belongs to the receipt renderer, not this view.
struct HeroBodyView: View {
    let original: UIImage
    let plate: UIImage
    let heroClass: HeroClass
    let pose: HeroBodyPose
    let width: CGFloat

    @ViewBuilder var body: some View {
        if pose == .rest || heroClass == .mage {
            source(original).allowsHitTesting(false)
        } else {
            let rig = heroClass == .warrior ? HeroCutoutRig.warrior : .rogue
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
        let held = HeroCutoutPolygon([(172,333),(194,340),(209,358),(212,378),(237,392),(246,434),(231,448),(274,447),(306,483),(268,512),(215,495),(203,474),(171,467),(150,446),(150,416),(162,388),(171,371),(161,354)])
        let shield = HeroCutoutPolygon([(247,332),(253,323),(414,279),(435,275),(475,312),(485,330),(472,405),(449,447),(411,472),(368,488),(325,478),(288,447),(266,408),(252,368)])
        let cloth = HeroCutoutPolygon([(63,371),(89,379),(105,391),(80,409),(91,432),(79,442),(42,427),(30,413),(42,389)])
        return Self(head: head, held: held, shield: shield, cloth: cloth,
            backing: [
                // Only the sleeve/chest originally hidden by the gripping hand.
                HeroCutoutPolygon([(157,361),(200,361),(234,399),(240,452),(207,477),(151,465),(146,416)]),
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

    static let rogue: Self = {
        let head = HeroCutoutPolygon([(111,0),(512,0),(512,330),(457,322),(423,281),(397,257),(372,245),(346,264),(321,276),(286,281),(254,270),(230,251),(199,239),(171,245),(146,220),(125,193),(111,153)])
        let held = HeroCutoutPolygon([(93,201),(123,217),(149,243),(177,282),(196,283),(206,292),(205,312),(221,326),(233,356),(243,376),(238,394),(233,400),(236,412),(221,420),(199,411),(175,430),(145,440),(125,429),(110,409),(109,381),(113,359),(127,342),(135,333),(127,316),(120,293),(99,258)])
        let cloth = HeroCutoutPolygon([(443,368),(455,378),(471,390),(460,407),(434,418),(410,414),(396,401),(414,389),(430,386)])
        return Self(head: head, held: held, shield: nil, cloth: cloth,
            backing: [
                // No generated face/main hood is sampled. A small cloth patch
                // behind the blade and the sleeve under its gripping hand are
                // needed when the weapon leaves its original occlusion.
                HeroCutoutPolygon([(126,248),(173,251),(183,282),(208,300),(211,322),(180,336),(139,318),(120,282)]),
                HeroCutoutPolygon([(132,318),(182,320),(224,343),(239,383),(218,416),(170,433),(126,420),(115,384)]),
                HeroCutoutPolygon([(403,386),(447,378),(471,393),(453,414),(415,419)])
            ],
            seamUnderlap: [
                // Original blue cloth, below the left cheek, bridges the head/
                // torso split. The right patch is garment below the hood tail.
                HeroCutoutPolygon([(174,250),(244,250),(260,264),(272,284),(253,304),(193,294),(167,275)]),
                HeroCutoutPolygon([(379,284),(415,286),(444,310),(455,332),(421,342),(390,321)])
            ],
            headPivot: CGPoint(x:287,y:274), heldPivot: CGPoint(x:146,y:393),
            shieldPivot: CGPoint(x:0,y:0), clothPivot: CGPoint(x:405,y:379),
            bodyPivot: CGPoint(x:277,y:419))
    }()
}
