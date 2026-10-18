#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore

/// Beta-only material pass. It draws on top of the unchanged pinned board art and never touches rules, hit testing,
/// accessibility or the grid projection. `--art-v1` (DEBUG) switches back to the previous look for side-by-side captures.
enum ArtV2 {
    static var enabled: Bool {
        #if DEBUG
        return !ProcessInfo.processInfo.arguments.contains("--art-v1")
        #else
        return true
        #endif
    }
    static let brass = Color(red: 0.88, green: 0.72, blue: 0.42)
    static let brassDark = Color(red: 0.42, green: 0.28, blue: 0.12)

    /// Star points for the two board sizes, drawn as small brass studs (like the dots on a go board).
    static func studs(_ size: Int) -> [Point] {
        size >= 9 ? [Point(2,2),Point(6,2),Point(4,4),Point(2,6),Point(6,6)]
                  : [Point(2,2),Point(4,2),Point(3,3),Point(2,4),Point(4,4)]
    }
}

/// Engraved brass grid, brass studs and a soft light pass, clipped to the silhouette of the board image.
/// Line thickness follows the perspective: thicker on the near rows, thinner on the far rows.
struct ArtBoardInlay: View {
    let boardSize: Int
    let boardImage: UIImage
    let pitch: CGFloat
    var body: some View {
        ZStack {
            Canvas { ctx, size in
                let projection = BoardProjection(size: boardSize)
                func p(_ x: Int,_ y: Int) -> CGPoint { let c = projection.center(Point(x,y)); return CGPoint(x:c.x*size.width,y:c.y*size.height) }
                let last = boardSize - 1
                func quad(_ a: CGPoint,_ b: CGPoint,_ wa: CGFloat,_ wb: CGFloat,vertical: Bool,dy: CGFloat = 0) -> Path {
                    Path { path in
                        if vertical {
                            path.move(to: CGPoint(x:a.x-wa/2,y:a.y+dy)); path.addLine(to: CGPoint(x:a.x+wa/2,y:a.y+dy))
                            path.addLine(to: CGPoint(x:b.x+wb/2,y:b.y+dy)); path.addLine(to: CGPoint(x:b.x-wb/2,y:b.y+dy))
                        } else {
                            path.move(to: CGPoint(x:a.x,y:a.y-wa/2+dy)); path.addLine(to: CGPoint(x:b.x,y:b.y-wb/2+dy))
                            path.addLine(to: CGPoint(x:b.x,y:b.y+wb/2+dy)); path.addLine(to: CGPoint(x:a.x,y:a.y+wa/2+dy))
                        }
                        path.closeSubpath()
                    }
                }
                let base = pitch * 0.034
                func scale(_ row: Int) -> CGFloat { 0.75 + 0.5 * CGFloat(row) / CGFloat(last) }
                // groove (dark), brass line, thin highlight: three passes give the inlaid look.
                for pass in 0..<3 {
                    let color: Color = pass == 0 ? .black.opacity(0.30) : pass == 1 ? ArtV2.brass.opacity(0.50) : .white.opacity(0.26)
                    let mult: CGFloat = pass == 0 ? 2.0 : pass == 1 ? 1.0 : 0.34
                    let shift: CGFloat = pass == 0 ? base * 0.5 : pass == 1 ? 0 : -base * 0.35
                    for n in 0...last {
                        ctx.fill(quad(p(0,n),p(last,n),base*scale(n)*mult,base*scale(n)*mult,vertical:false,dy:shift),with:.color(color))
                        ctx.fill(quad(p(n,0),p(n,last),base*scale(0)*mult,base*scale(last)*mult,vertical:true,dy:shift),with:.color(color))
                    }
                }
                for stud in ArtV2.studs(boardSize) {
                    let c = p(stud.x,stud.y), r = pitch * 0.075 * scale(stud.y)
                    ctx.fill(Path(ellipseIn: CGRect(x:c.x-r*1.25,y:c.y-r*0.95+r*0.25,width:r*2.5,height:r*1.9)),with:.color(.black.opacity(0.30)))
                    ctx.fill(Path(ellipseIn: CGRect(x:c.x-r,y:c.y-r*0.78,width:r*2,height:r*1.56)),
                             with:.linearGradient(Gradient(colors:[Color(red:1,green:0.93,blue:0.72),ArtV2.brass,ArtV2.brassDark]),
                                                  startPoint:CGPoint(x:c.x-r,y:c.y-r),endPoint:CGPoint(x:c.x+r,y:c.y+r)))
                }
            }
            // Light: warm from the upper left, falling off toward the near edge; plus an inner vignette.
            LinearGradient(colors:[.white.opacity(0.13),.clear,.black.opacity(0.16)],startPoint:.topLeading,endPoint:.bottomTrailing)
                .mask(Image(uiImage:boardImage).resizable())
            RadialGradient(colors:[.clear,.black.opacity(0.22)],center:.center,startRadius:pitch*2.6,endRadius:pitch*7.2)
                .mask(Image(uiImage:boardImage).resizable())
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Legal target: a small gem with a slow pulse so it reads against the brass grid. One shared timeline for all markers.
struct ArtLegalMarkers: View {
    let points: [CGPoint]
    let pitch: CGFloat
    let reduced: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/24, paused: reduced)) { context in
            let t = reduced ? 0.0 : context.date.timeIntervalSinceReferenceDate
            let pulse = reduced ? 0.5 : 0.5 + 0.5 * sin(t * 2.6)
            ZStack {
                ForEach(points.indices, id: \.self) { i in
                    ZStack {
                        Circle().fill(Color(red:0.25,green:0.95,blue:0.70).opacity(0.04 + 0.10 * pulse)).frame(width: pitch*0.30)
                        Circle().fill(RadialGradient(colors:[Color(red:0.82,green:1,blue:0.92),Color(red:0.16,green:0.74,blue:0.55),Color(red:0.05,green:0.30,blue:0.24)],
                                                     center:.init(x:0.35,y:0.30),startRadius:0,endRadius:pitch*0.12))
                            .overlay(Circle().stroke(Color.white.opacity(0.55),lineWidth:0.5))
                            .frame(width: pitch*0.13).shadow(color:.black.opacity(0.55),radius:1,y:1)
                    }.position(points[i])
                }
            }
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The commander as a standing crowned piece instead of a flat coin: lathe-style body with cylindrical shading, a gold
/// collar and crown, and the team's marker (circle for Black, diamond for White) so identity never depends on color alone.
/// Drawn in one Canvas with the base centre at the view centre, so the token is placed like every other unit.
struct ArtKing: View {
    let black: Bool
    let pitch: CGFloat
    var body: some View {
        let w = pitch * 0.62
        let body1 = black ? Color(red:0.10,green:0.17,blue:0.23) : Color(red:0.78,green:0.70,blue:0.52)
        let body2 = black ? Color(red:0.40,green:0.55,blue:0.66) : Color(red:1.0,green:0.97,blue:0.88)
        let body3 = black ? Color(red:0.06,green:0.10,blue:0.15) : Color(red:0.58,green:0.50,blue:0.35)
        let goldColors = [Color(red:1,green:0.93,blue:0.66),Color(red:0.86,green:0.66,blue:0.30),Color(red:0.52,green:0.34,blue:0.12)]
        Canvas { ctx, size in
            let cx = size.width / 2, by = size.height / 2
            func gold(_ rect: CGRect) -> GraphicsContext.Shading {
                .linearGradient(Gradient(colors:goldColors),startPoint:CGPoint(x:rect.midX,y:rect.minY),endPoint:CGPoint(x:rect.midX,y:rect.maxY))
            }
            func cyl(_ rect: CGRect) -> GraphicsContext.Shading {
                .linearGradient(Gradient(colors:[body3,body2,body1]),startPoint:CGPoint(x:rect.minX,y:rect.midY),endPoint:CGPoint(x:rect.maxX,y:rect.midY))
            }
            // contact shadow
            var shadow = ctx; shadow.addFilter(.blur(radius:1.4))
            shadow.fill(Path(ellipseIn:CGRect(x:cx-w*0.58,y:by+w*0.16-w*0.23,width:w*1.16,height:w*0.46)),with:.color(.black.opacity(0.36)))
            // base disc: side, top, gold rim
            ctx.fill(Path(ellipseIn:CGRect(x:cx-w*0.5,y:by+w*0.10-w*0.22,width:w,height:w*0.44)),with:.color(body3))
            let top = CGRect(x:cx-w*0.5,y:by-w*0.22,width:w,height:w*0.44)
            ctx.fill(Path(ellipseIn:top),with:.linearGradient(Gradient(colors:[body2,body1]),startPoint:CGPoint(x:top.minX,y:top.minY),endPoint:CGPoint(x:top.maxX,y:top.maxY)))
            ctx.stroke(Path(ellipseIn:top),with:gold(top),lineWidth:max(0.8,pitch*0.03))
            // stem
            let stemRect = CGRect(x:cx-w*0.34,y:by-w*0.78,width:w*0.68,height:w*0.76)
            let stem = Path { p in
                p.move(to:CGPoint(x:cx-w*0.34,y:by-w*0.02))
                p.addQuadCurve(to:CGPoint(x:cx-w*0.15,y:by-w*0.78),control:CGPoint(x:cx-w*0.16,y:by-w*0.30))
                p.addLine(to:CGPoint(x:cx+w*0.15,y:by-w*0.78))
                p.addQuadCurve(to:CGPoint(x:cx+w*0.34,y:by-w*0.02),control:CGPoint(x:cx+w*0.16,y:by-w*0.30))
                p.closeSubpath()
            }
            ctx.fill(stem,with:cyl(stemRect))
            // collar
            let collar = CGRect(x:cx-w*0.25,y:by-w*0.78-w*0.085,width:w*0.5,height:w*0.17)
            ctx.fill(Path(ellipseIn:collar),with:gold(collar))
            ctx.fill(Path(ellipseIn:CGRect(x:cx-w*0.20,y:by-w*0.80-w*0.03,width:w*0.40,height:w*0.06)),with:.color(.white.opacity(0.35)))
            // head
            let head = CGRect(x:cx-w*0.26,y:by-w*1.02-w*0.26,width:w*0.52,height:w*0.52)
            ctx.fill(Path(ellipseIn:head),with:.radialGradient(Gradient(colors:[body2,body1,body3]),center:CGPoint(x:head.minX+head.width*0.34,y:head.minY+head.height*0.28),startRadius:0,endRadius:w*0.36))
            // crown
            let y = by - w*1.26, h = w*0.17, half = w*0.25
            let crown = Path { p in
                p.move(to:CGPoint(x:cx-half,y:y+h)); p.addLine(to:CGPoint(x:cx-half,y:y)); p.addLine(to:CGPoint(x:cx-half*0.5,y:y+h*0.45))
                p.addLine(to:CGPoint(x:cx,y:y-h*0.45)); p.addLine(to:CGPoint(x:cx+half*0.5,y:y+h*0.45)); p.addLine(to:CGPoint(x:cx+half,y:y))
                p.addLine(to:CGPoint(x:cx+half,y:y+h)); p.closeSubpath()
            }
            ctx.fill(crown,with:gold(CGRect(x:cx-half,y:y-h*0.45,width:half*2,height:h*1.45)))
            ctx.stroke(crown,with:.color(Color(red:0.35,green:0.22,blue:0.08).opacity(0.7)),lineWidth:0.6)
            ctx.fill(Path(ellipseIn:CGRect(x:cx-w*0.05,y:y+h*0.35-w*0.05,width:w*0.10,height:w*0.10)),with:.color(Color(red:0.95,green:0.25,blue:0.30)))
            // faction marker, shape-coded, on the front of the base
            let m = max(3.2,w*0.15), mc = CGPoint(x:cx,y:by+w*0.12)
            if black { ctx.fill(Path(ellipseIn:CGRect(x:mc.x-m/2,y:mc.y-m/2,width:m,height:m)),with:.color(Color(red:0.98,green:0.93,blue:0.78))) }
            else {
                let d = Path { p in p.move(to:CGPoint(x:mc.x,y:mc.y-m*0.6)); p.addLine(to:CGPoint(x:mc.x+m*0.6,y:mc.y)); p.addLine(to:CGPoint(x:mc.x,y:mc.y+m*0.6)); p.addLine(to:CGPoint(x:mc.x-m*0.6,y:mc.y)); p.closeSubpath() }
                ctx.fill(d,with:.color(Color(red:0.12,green:0.20,blue:0.25)))
            }
        }.frame(width:w*1.4,height:w*2.9).allowsHitTesting(false)
    }
}

/// The table around the board: a warm pool of light under the board and a dark vignette, over the existing backdrop.
struct ArtTable: View {
    var body: some View {
        ZStack {
            GameBackdrop()
            if ArtV2.enabled {
                RadialGradient(colors:[Color(red:0.62,green:0.43,blue:0.20).opacity(0.26),.clear],
                               center:UnitPoint(x:0.5,y:0.44),startRadius:20,endRadius:520).ignoresSafeArea().allowsHitTesting(false)
                RadialGradient(colors:[.clear,.black.opacity(0.55)],
                               center:UnitPoint(x:0.5,y:0.46),startRadius:260,endRadius:760).ignoresSafeArea().allowsHitTesting(false)
            }
        }.accessibilityHidden(true)
    }
}
#endif
