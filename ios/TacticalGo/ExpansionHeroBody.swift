#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// Original pixels define identity, hand/prop and silhouette. Generated cloth is
/// visible only behind removed layers and inside the original alpha boundary.
struct ExpansionHeroBody: View {
    let original: UIImage, plate: UIImage
    let hero: HeroClass
    let pose: ExpansionHeroPose
    let width: CGFloat
    var body: some View {
        let r = hero == .priest ? ExpansionCutoutRig.priest : .rogue
        Group {
            if pose == .rest { source(original) }
            else {
                ZStack {
                    source(plate).mask { ZStack { ForEach(r.backing.indices,id:\.self) { r.backing[$0].fill(.white) } } }.mask(source(original))
                    layer(.canvas,holes:[r.head,r.hand,r.book,r.cloth])
                    ForEach(r.seams.indices,id:\.self) { layer(r.seams[$0],holes:[r.hand,r.book]) }
                    layer(r.cloth).rotationEffect(.degrees(pose.cloth),anchor:unit(r.clothPivot))
                    layer(r.head,holes:[r.hand,r.book]).rotationEffect(.degrees(pose.head),anchor:unit(r.headPivot))
                    layer(r.hand).rotationEffect(.degrees(pose.hand),anchor:unit(r.handPivot)).offset(x:px(pose.handX),y:px(pose.handY))
                    layer(r.book).rotationEffect(.degrees(pose.book),anchor:unit(r.bookPivot)).offset(y:px(pose.bookY))
                }.rotationEffect(.degrees(pose.body),anchor:unit(r.bodyPivot)).offset(x:px(pose.bodyX),y:px(pose.bodyY))
            }
        }.frame(width:width,height:width).allowsHitTesting(false)
    }
    private func source(_ image: UIImage) -> some View { Image(uiImage:image).resizable().interpolation(.high).frame(width:width,height:width) }
    private func layer(_ region: ExpansionCutoutPolygon,holes: [ExpansionCutoutPolygon] = []) -> some View {
        source(original).mask(region).mask {
            ZStack { Rectangle().fill(.white); ForEach(holes.indices,id:\.self) { holes[$0].fill(.white).blendMode(.destinationOut) } }.compositingGroup()
        }
    }
    private func px(_ v: Double) -> CGFloat { width*v/512 }
    private func unit(_ p: CGPoint) -> UnitPoint { UnitPoint(x:p.x/512,y:p.y/512) }
}
private struct ExpansionCutoutPolygon: Shape {
    let points: [(Double,Double)]
    init(_ points: [(Double,Double)]) { self.points = points }
    func path(in rect: CGRect) -> Path { Path { p in
        guard let first = points.first else { return }
        func q(_ v: (Double,Double)) -> CGPoint { CGPoint(x:rect.minX+rect.width*v.0/512,y:rect.minY+rect.height*v.1/512) }
        p.move(to:q(first)); for v in points.dropFirst() { p.addLine(to:q(v)) }; p.closeSubpath()
    } }
    static let canvas = Self([(0,0),(512,0),(512,512),(0,512)])
}
private struct ExpansionCutoutRig {
    let head: ExpansionCutoutPolygon, hand: ExpansionCutoutPolygon, book: ExpansionCutoutPolygon, cloth: ExpansionCutoutPolygon
    let backing: [ExpansionCutoutPolygon], seams: [ExpansionCutoutPolygon]
    let headPivot: CGPoint,handPivot: CGPoint,bookPivot: CGPoint,clothPivot: CGPoint,bodyPivot: CGPoint
    static let rogue = Self(
        head:.init([(111,0),(512,0),(512,330),(457,322),(423,281),(397,257),(372,245),(346,264),(321,276),(286,281),(254,270),(230,251),(199,239),(171,245),(146,220),(125,193),(111,153)]),
        hand:.init([(93,201),(123,217),(149,243),(177,282),(196,283),(206,292),(205,312),(221,326),(233,356),(243,376),(238,394),(233,400),(236,412),(221,420),(199,411),(175,430),(145,440),(125,429),(110,409),(109,381),(113,359),(127,342),(135,333),(127,316),(120,293),(99,258)]),
        book:.init([]),cloth:.init([(443,368),(455,378),(471,390),(460,407),(434,418),(410,414),(396,401),(414,389),(430,386)]),
        backing:[.init([(126,248),(173,251),(183,282),(208,300),(211,322),(180,336),(139,318),(120,282)]),.init([(132,318),(182,320),(224,343),(239,383),(218,416),(170,433),(126,420),(115,384)]),.init([(403,386),(447,378),(471,393),(453,414),(415,419)])],
        seams:[.init([(174,250),(244,250),(260,264),(272,284),(253,304),(193,294),(167,275)]),.init([(379,284),(415,286),(444,310),(455,332),(421,342),(390,321)])],
        headPivot:CGPoint(x:287,y:274),handPivot:CGPoint(x:146,y:393),bookPivot:.zero,clothPivot:CGPoint(x:405,y:379),bodyPivot:CGPoint(x:277,y:419))
    static let priest = Self(
        head:.init([(120,0),(410,0),(410,199),(388,208),(361,207),(337,203),(324,209),(313,222),(295,230),(278,229),(260,223),(247,213),(233,218),(210,211),(183,216),(156,211),(137,198),(120,179)]),
        hand:.init([(88,190),(158,187),(164,214),(182,219),(208,228),(222,246),(219,285),(203,327),(178,345),(149,345),(115,334),(102,306),(100,278),(108,254),(120,247),(87,243)]),
        book:.init([(312,220),(420,240),(418,301),(411,337),(416,374),(409,390),(382,394),(360,381),(347,357),(326,355),(291,346),(294,311),(309,273)]),
        cloth:.init([(148,342),(170,351),(166,376),(143,418),(134,433),(124,427),(105,411),(99,385),(109,367)]),
        backing:[.init([(200,198),(321,199),(329,238),(293,258),(218,246),(182,221)]),.init([(118,234),(190,218),(225,236),(227,296),(199,344),(144,354),(109,318)]),.init([(304,227),(394,236),(421,290),(421,386),(376,395),(336,363),(285,350)]),.init([(104,362),(164,340),(174,370),(137,436),(106,414),(98,382)])],
        seams:[.init([(187,209),(232,220),(274,234),(301,222),(330,218),(342,243),(301,265),(228,254),(185,235)])],
        headPivot:CGPoint(x:281,y:218),handPivot:CGPoint(x:206,y:244),bookPivot:CGPoint(x:346,y:316),clothPivot:CGPoint(x:159,y:355),bodyPivot:CGPoint(x:256,y:478))
}
#endif

#if DEBUG || TACTICALGO_V11
/// Native 32/48/64 point pose sheet. This is an engineering sample, not a played action.
struct ExpansionArtReview: View {
    private var hero: HeroClass { ProcessInfo.processInfo.arguments.contains("--exp-art-rogue") ? .rogue:.priest }
    private var original: UIImage? {
        if hero == .rogue { return try? P02CozyAssets.load().heroes[.rogue] }
        return png("priest-v02")
    }
    private var plate: UIImage? { png(hero == .rogue ? "rogue-clean-plate":"priest-clean-plate-v02") }
    private func png(_ name: String) -> UIImage? {
        guard let p = Bundle.main.url(forResource:name,withExtension:"png",subdirectory:"PresentationLab/P08") else { return nil }
        return UIImage(contentsOfFile:p.path)
    }
    var body: some View {
        ScrollView {
            VStack(spacing:8) {
                Text(hero == .rogue ? "盜賊原畫分層檢查":"牧師v02原畫分層檢查").font(.headline)
                Text("原生32／48／64 pt；定格樣本，不是對局錄影").font(.caption)
                if let original,let plate {
                    ForEach([false,true],id:\.self) { dark in
                        ForEach([32,48,64],id:\.self) { edge in
                            HStack(spacing:20) {
                                ForEach(0..<3,id:\.self) { phase in
                                    let t = phase == 0 ? 0:hero == .priest ? phase == 1 ? 0.20:0.32:phase == 1 ? 0.12:0.16
                                    VStack(spacing:4) {
                                        ExpansionHeroBody(original:original,plate:plate,hero:hero,pose:hero == .priest ? .priest(at:t):.rogue(at:t),width:CGFloat(edge)).frame(width:70,height:70)
                                        Text("\(edge) · \(phase == 0 ? "站立":phase == 1 ? "蓄勢":"出手")").font(.caption2)
                                    }
                                }
                            }.padding(6).foregroundStyle(dark ? Color.white:P02Cozy.ink).background(dark ? Color(red:0.15,green:0.20,blue:0.24):P02Cozy.card,in:RoundedRectangle(cornerRadius:10))
                        }
                    }
                } else { Text("素材未載入") }
                Text("頭、手與道具保持原像素。衣料補圖只顯示在遮罩缺口；美術與演技待Owner驗收。").font(.caption)
            }.padding(10)
        }.background(P02Cozy.bg).preferredColorScheme(.light)
    }
}
#endif
