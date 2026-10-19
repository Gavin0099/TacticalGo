#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoMotion

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
    /// Ambient motion (pulses, glints, banners). Off while UI tests drive the app (`--sound-preferences-reset` is only
    /// passed by the tests): XCUITest waits for the app to go idle before every action, and endless animations make each
    /// wait run into its timeout (a full run took 67 minutes instead of about 25). Always on in Beta and Release.
    static var ambient: Bool {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        return !args.contains("--sound-preferences-reset") && !args.contains("--art-no-ambient")
        #else
        return true
        #endif
    }
    /// The v30 sound set (Audio/V30) is only used when it is actually in the app. The App Store build strips it until the
    /// Owner has listened and approved; without it the original cues play exactly as before.
    static let sfx: Bool = enabled && Bundle.main.url(forResource: "confirm", withExtension: "wav", subdirectory: "Audio/V30") != nil
    static let brass = Color(red: 0.88, green: 0.72, blue: 0.42)
    /// Dashed preview lines and rings (pushes, swaps): brass instead of the old purple.
    static let preview = Color(red: 1, green: 0.86, blue: 0.46)
    static let brassDark = Color(red: 0.42, green: 0.28, blue: 0.12)

    /// Star points for the two board sizes, drawn as small brass studs (like the dots on a go board).
    static func studs(_ size: Int) -> [Point] {
        size >= 9 ? [Point(2,2),Point(6,2),Point(4,4),Point(2,6),Point(6,6)]
                  : [Point(2,2),Point(4,2),Point(3,3),Point(2,4),Point(4,4)]
    }
}

/// Engraved brass grid, brass studs and a soft light pass, clipped to the silhouette of the board image.
/// Line thickness follows the perspective: thicker on the near rows, thinner on the far rows.
struct ArtBoardInlay: View, Equatable {
    let boardSize: Int
    let boardImage: UIImage
    let pitch: CGFloat
    /// The board is re-evaluated every frame during animations; these layers only depend on these three values, so the
    /// call site uses `.equatable()` and the result is rasterised once with `drawingGroup`.
    nonisolated static func == (a: ArtBoardInlay, b: ArtBoardInlay) -> Bool {
        MainActor.assumeIsolated { a.boardSize == b.boardSize && a.pitch == b.pitch && a.boardImage === b.boardImage }
    }
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
            // wood grain: long faint streaks along the board's width, clipped to the board silhouette
            Canvas { ctx, size in
                var seed: UInt64 = 0x9E3779B97F4A7C15
                func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat((seed >> 33) % 10_000) / 10_000 }
                for _ in 0..<170 {
                    let y = size.height * (0.06 + 0.9 * rnd()), x = size.width * (rnd() * 0.9 - 0.1), len = size.width * (0.25 + 0.6 * rnd())
                    let wob = pitch * 0.05 * (rnd() - 0.5)
                    let path = Path { p in p.move(to: CGPoint(x:x,y:y)); p.addQuadCurve(to: CGPoint(x:x+len,y:y+wob),control: CGPoint(x:x+len/2,y:y-wob*2)) }
                    let dark = rnd() < 0.7
                    ctx.stroke(path,with:.color((dark ? Color(red:0.35,green:0.20,blue:0.06) : Color.white).opacity(dark ? 0.05 + 0.05 * rnd() : 0.05)),lineWidth:0.5 + 1.1 * rnd())
                }
            }.mask(Image(uiImage:boardImage).resizable())
            // Light: warm from the upper left, falling off toward the near edge; plus an inner vignette.
            LinearGradient(colors:[.white.opacity(0.13),.clear,.black.opacity(0.16)],startPoint:.topLeading,endPoint:.bottomTrailing)
                .mask(Image(uiImage:boardImage).resizable())
            RadialGradient(colors:[.clear,.black.opacity(0.22)],center:.center,startRadius:pitch*2.6,endRadius:pitch*7.2)
                .mask(Image(uiImage:boardImage).resizable())
        }.drawingGroup().allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Legal target: a small gem with a slow pulse so it reads against the brass grid. One shared timeline for all markers.
struct ArtLegalMarkers: View {
    let points: [CGPoint]
    let pitch: CGFloat
    let reduced: Bool
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/24, paused: reduced || !ArtV2.ambient)) { context in
            let t = (reduced || !ArtV2.ambient) ? 0.0 : context.date.timeIntervalSinceReferenceDate
            let pulse = (reduced || !ArtV2.ambient) ? 0.5 : 0.5 + 0.5 * sin(t * 2.6)
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
    var active = false
    var reduced = false
    var body: some View {
        // Only the side to move animates (aura pulse and a crown glint every few seconds); the other king is still.
        TimelineView(.animation(minimumInterval: 1.0/20, paused: reduced || !active || !ArtV2.ambient)) { context in
            king(t: (reduced || !active || !ArtV2.ambient) ? 0 : context.date.timeIntervalSinceReferenceDate)
        }
    }
    private func king(t: Double) -> some View {
        let w = pitch * 0.62
        let body1 = black ? Color(red:0.10,green:0.17,blue:0.23) : Color(red:0.78,green:0.70,blue:0.52)
        let body2 = black ? Color(red:0.40,green:0.55,blue:0.66) : Color(red:1.0,green:0.97,blue:0.88)
        let body3 = black ? Color(red:0.06,green:0.10,blue:0.15) : Color(red:0.58,green:0.50,blue:0.35)
        let goldColors = [Color(red:1,green:0.93,blue:0.66),Color(red:0.86,green:0.66,blue:0.30),Color(red:0.52,green:0.34,blue:0.12)]
        return Canvas { ctx, size in
            let cx = size.width / 2, by = size.height / 2
            func gold(_ rect: CGRect) -> GraphicsContext.Shading {
                .linearGradient(Gradient(colors:goldColors),startPoint:CGPoint(x:rect.midX,y:rect.minY),endPoint:CGPoint(x:rect.midX,y:rect.maxY))
            }
            func cyl(_ rect: CGRect) -> GraphicsContext.Shading {
                .linearGradient(Gradient(colors:[body3,body2,body1]),startPoint:CGPoint(x:rect.minX,y:rect.midY),endPoint:CGPoint(x:rect.maxX,y:rect.midY))
            }
            // turn aura: a soft gold ring under the king whose turn it is
            if active {
                let pulse = reduced ? 0.6 : 0.5 + 0.5 * sin(t * 2.4)
                var glow = ctx; glow.addFilter(.blur(radius:max(2,w*0.12)))
                glow.fill(Path(ellipseIn:CGRect(x:cx-w*0.78,y:by-w*0.34+w*0.04,width:w*1.56,height:w*0.68)),with:.color(Color(red:1,green:0.82,blue:0.38).opacity(0.28 + 0.28 * pulse)))
                ctx.stroke(Path(ellipseIn:CGRect(x:cx-w*0.62,y:by-w*0.27+w*0.03,width:w*1.24,height:w*0.54)),with:.color(Color(red:1,green:0.88,blue:0.50).opacity(0.55 + 0.35 * pulse)),lineWidth:max(1,w*0.05))
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
            if active && !reduced && ArtV2.ambient {
                // glint: a short bright sweep across the crown once every ~4.5 s
                let phase = (t.truncatingRemainder(dividingBy: 4.5)) / 0.55
                if phase < 1 {
                    let gx = cx - half + (half * 2) * phase
                    var g = ctx; g.clip(to: crown)
                    g.fill(Path(CGRect(x:gx-w*0.05,y:y-h*0.6,width:w*0.10,height:h*1.6)),with:.color(.white.opacity(0.85)))
                }
            }
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

/// Player panel: a hero crest, the mana as a row of crystals (full ones lit), liberties and AP pips. The panel is one
/// accessibility element at the call site, so everything here is decorative and the spoken value is unchanged.
struct ArtPlayerStrip: View {
    let portrait: UIImage?
    let accent: Color
    let name: String
    let black: Bool
    let active: Bool
    let status: String
    let role: String?
    let mana: Int
    let cap: Int
    let liberties: Int
    let ap: Int
    let apMax: Int
    var loot: String?
    var reduced = false
    @State private var pulse = false
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.black.opacity(0.55)).frame(width: 40, height: 40)
                if let portrait {
                    Image(uiImage: portrait).resizable().scaledToFill().frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
                Circle().stroke(LinearGradient(colors:[accent.opacity(0.95),accent.opacity(0.45)],startPoint:.top,endPoint:.bottom),lineWidth: 2.2).frame(width: 38, height: 38)
                Circle().stroke(ArtV2.brass.opacity(0.9),lineWidth: 1).frame(width: 42, height: 42)
                // faction, shape-coded: filled circle for Black, diamond for White
                Group {
                    if black { Circle().fill(Color(red:0.98,green:0.93,blue:0.78)).overlay(Circle().stroke(Color.black.opacity(0.5),lineWidth:0.6)) }
                    else { Rectangle().fill(Color(red:0.12,green:0.20,blue:0.25)).overlay(Rectangle().stroke(Color(red:0.98,green:0.93,blue:0.78),lineWidth:0.8)).rotationEffect(.degrees(45)) }
                }.frame(width: 9, height: 9).offset(x: -15, y: 15)
            }
            .shadow(color: active ? Color(red:1,green:0.80,blue:0.36).opacity(0.75) : .clear, radius: active ? (reduced ? 5 : (pulse ? 8 : 3)) : 0)
            .onAppear {
                guard !reduced, ArtV2.ambient else { return }
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { pulse = true }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(name).font(.system(size: 13, weight: .bold, design: .serif)).foregroundStyle(GameChrome.cream)
                        .accessibilityLabel((black ? "● " : "○ ") + name)
                    if let role { Text(role).font(.system(size: 9, weight: .bold)).foregroundStyle(GameChrome.gold) }
                    Spacer(minLength: 0)
                    Text(status).font(.system(size: 10, weight: .bold)).foregroundStyle(active ? GameChrome.gold : GameChrome.muted)
                }
                // Narrow phones: drop the "N AP" label first (the pips and the spoken value still carry it).
                ViewThatFits(in: .horizontal) {
                    resourceRow(showApLabel: true)
                    resourceRow(showApLabel: false)
                }
                if let loot { Text(loot).font(.system(size: 10)).foregroundStyle(GameChrome.gold) }
            }
        }.padding(.horizontal, 6).padding(.vertical, 5)
    }
}

extension ArtPlayerStrip {
    func resourceRow(showApLabel: Bool) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<cap, id: \.self) { i in ArtCrystal(lit: i < mana) }
            Text("\(liberties) 氣").font(.system(size: 10, weight: .semibold)).foregroundStyle(liberties <= 1 ? Color.redTeam : GameChrome.muted)
                .padding(.leading, 3).fixedSize()
            Spacer(minLength: 0)
            if active {
                HStack(spacing: 3) {
                    ForEach(0..<max(apMax, ap), id: \.self) { i in
                        Circle().fill(i < ap ? GameChrome.gold : Color.clear)
                            .overlay(Circle().stroke(GameChrome.gold.opacity(0.8), lineWidth: 1))
                            .frame(width: 7, height: 7)
                            .shadow(color: i < ap ? GameChrome.gold.opacity(0.8) : .clear, radius: 2)
                            .scaleEffect(i < ap ? 1 : 0.8)
                            .animation(reduced ? nil : .spring(response: 0.3, dampingFraction: 0.45), value: i < ap)
                    }
                    if showApLabel { Text("\(ap) AP").font(.system(size: 10, weight: .bold)).foregroundStyle(GameChrome.cream).fixedSize() }
                }
            }
        }
    }
}

/// One mana crystal: a small hexagon, lit blue or an empty dark socket.
struct ArtCrystal: View {
    let lit: Bool
    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width/2, y: size.height/2), r = min(size.width, size.height)/2
            let hex = Path { p in
                for k in 0..<6 {
                    let a = Double(k) * .pi / 3 - .pi / 2
                    let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
                    if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
            }
            if lit {
                ctx.fill(hex, with: .linearGradient(Gradient(colors:[Color(red:0.70,green:0.93,blue:1),Color(red:0.20,green:0.60,blue:0.90),Color(red:0.05,green:0.20,blue:0.45)]),
                                                    startPoint: CGPoint(x: c.x - r, y: c.y - r), endPoint: CGPoint(x: c.x + r, y: c.y + r)))
                ctx.stroke(hex, with: .color(Color(red:0.75,green:0.92,blue:1).opacity(0.9)), lineWidth: 0.7)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r*0.45, y: c.y - r*0.65, width: r*0.5, height: r*0.35)), with: .color(.white.opacity(0.55)))
            } else {
                ctx.fill(hex, with: .color(Color.black.opacity(0.45)))
                ctx.stroke(hex, with: .color(Color(red:0.45,green:0.60,blue:0.70).opacity(0.45)), lineWidth: 0.7)
            }
        }.frame(width: 10, height: 11).shadow(color: lit ? Color(red:0.3,green:0.7,blue:1).opacity(0.5) : .clear, radius: 1.5)
            .scaleEffect(lit ? 1 : 0.85).animation(.spring(response: 0.32, dampingFraction: 0.45), value: lit)
    }
}

/// Landing dust and capture shards, as pure functions of time from the presentation receipt (so a frozen review frame
/// shows exactly what the live match shows). Skipped for reduced motion. Never touches rules, audio or hit testing.
struct ArtImpact: View {
    let receipt: ExpansionPresentation
    let time: Double
    let pitch: CGFloat
    let size: CGSize
    let center: (Point) -> CGPoint
    private func rnd(_ i: Int,_ k: Int) -> Double {
        var x = UInt64(i &* 7919 &+ k &* 104729 &+ 17) &* 6364136223846793005 &+ 1442695040888963407
        x ^= x >> 29; x = x &* 0xBF58476D1CE4E5B9
        return Double((x >> 40) % 10_000) / 10_000
    }
    var body: some View {
        Canvas { ctx, _ in
            // landing: a dust ring plus a few sparks where a piece arrives
            let a = time - receipt.arrival
            if a >= 0, a < 0.5 {
                let t = a / 0.5
                for at in receipt.placements {
                    let c = center(at)
                    let r = pitch * CGFloat(0.18 + 0.50 * (1 - pow(1 - t, 2)))
                    let ring = Path(ellipseIn: CGRect(x: c.x - r, y: c.y + pitch*0.06 - r*0.34, width: r*2, height: r*0.68))
                    ctx.stroke(ring, with: .color(Color(red:1,green:0.93,blue:0.74).opacity(0.70 * (1 - t))), lineWidth: max(1.2, pitch * 0.10 * CGFloat(1 - t)))
                    for k in 0..<7 {
                        let ang = (Double(k) / 7 + rnd(k, 1) * 0.1) * 2 * .pi, d = pitch * CGFloat(0.20 + 0.34 * t) * CGFloat(0.7 + 0.5 * rnd(k, 2))
                        let px = c.x + CGFloat(cos(ang)) * d, py = c.y + pitch*0.06 + CGFloat(sin(ang)) * d * 0.34 - pitch * CGFloat(0.18 * t * (0.5 + rnd(k, 3)))
                        let sz = max(1.2, pitch * 0.06) * CGFloat(1 - t)
                        ctx.fill(Path(ellipseIn: CGRect(x: px - sz/2, y: py - sz/2, width: sz, height: sz)), with: .color(Color(red:1,green:0.95,blue:0.80).opacity(0.85 * (1 - t))))
                    }
                }
            }
            // capture: flash, then shards flying out with a little gravity; the commander gets a bigger, golden version
            let b = time - receipt.captureStart
            if b >= 0, b < 0.62 {
                for (n, captured) in receipt.captures.enumerated() {
                    let commander = captured.piece.kind == .commander
                    let t = b / (commander ? 0.62 : 0.50)
                    guard t < 1 else { continue }
                    let c = center(captured.at)
                    let flash = max(0, 1 - b / 0.16)
                    if flash > 0 {
                        let r = pitch * CGFloat(commander ? 0.95 : 0.55) * CGFloat(0.55 + 0.45 * (1 - flash))
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r*0.9, width: r*2, height: r*1.8)),
                                 with: .radialGradient(Gradient(colors:[.white.opacity(0.80 * flash),Color(red:1,green:0.85,blue:0.45).opacity(0.32 * flash),.clear]),
                                                       center: c, startRadius: 0, endRadius: r))
                    }
                    if commander {
                        let rr = pitch * CGFloat(0.3 + 1.5 * (1 - pow(1 - t, 2)))
                        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr*0.5, width: rr*2, height: rr)),
                                   with: .color(Color(red:1,green:0.86,blue:0.45).opacity(0.75 * (1 - t))), lineWidth: max(1.5, pitch * 0.10 * CGFloat(1 - t)))
                    }
                    let count = commander ? 26 : 12
                    let black = captured.piece.owner == .one
                    for k in 0..<count {
                        let ang = (Double(k) / Double(count) + rnd(k + 40 * n, 4) * 0.08) * 2 * .pi
                        let speed = pitch * CGFloat(commander ? 1.35 : 0.95) * CGFloat(0.5 + rnd(k + 40 * n, 5))
                        let tt = CGFloat(t)
                        let x = c.x + CGFloat(cos(ang)) * speed * tt
                        let y = c.y - pitch * 0.25 + CGFloat(sin(ang)) * speed * tt * 0.55 - pitch * 0.45 * tt + pitch * 0.9 * tt * tt
                        let w = max(2, pitch * CGFloat(0.10 + 0.09 * rnd(k + 40 * n, 6))) * (1 - 0.45 * tt)
                        var piece = ctx; piece.translateBy(x: x, y: y); piece.rotate(by: .radians(ang * 2 + Double(tt) * 6 * (rnd(k, 7) - 0.5)))
                        let color: Color = commander && k % 3 == 0 ? Color(red:1,green:0.82,blue:0.36)
                            : black ? Color(red:0.30,green:0.45,blue:0.56) : Color(red:0.98,green:0.94,blue:0.82)
                        let shard = Path(CGRect(x: -w/2, y: -w*0.35, width: w, height: w*0.7))
                        piece.fill(shard, with: .color(color.opacity(1 - Double(tt) * 0.9)))
                        piece.stroke(shard, with: .color(Color(red:0.20,green:0.12,blue:0.05).opacity(0.55 * (1 - Double(tt)))), lineWidth: 0.7)
                    }
                }
            }
        }.frame(width: size.width, height: size.height).allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// A short ribbon over the board when the match ends (about 3 seconds, then it fades and the result dock remains).
/// Victory: gold ribbon with slowly turning rays. Defeat: dark and quiet. Draw: steel. Not shown for reduced motion;
/// it never intercepts touches and is hidden from accessibility (the dock already says the result).
struct ArtResultBanner: View {
    enum Tone { case victory, defeat, draw }
    let title: String
    let tone: Tone
    @State private var start = Date()
    private var colors: [Color] {
        switch tone {
        case .victory: [Color(red:0.30,green:0.22,blue:0.08),Color(red:0.14,green:0.12,blue:0.10)]
        case .defeat: [Color(red:0.26,green:0.10,blue:0.12),Color(red:0.10,green:0.07,blue:0.09)]
        case .draw: [Color(red:0.17,green:0.24,blue:0.30),Color(red:0.08,green:0.11,blue:0.15)]
        }
    }
    private var edge: Color { tone == .victory ? Color(red:1,green:0.84,blue:0.42) : tone == .defeat ? Color(red:0.75,green:0.45,blue:0.45) : Color(red:0.62,green:0.76,blue:0.86) }
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30)) { context in
            let t = context.date.timeIntervalSince(start)
            let appear = min(1, t / 0.45)
            let ease = 1 - pow(1 - appear, 3)
            let fade = t > 2.6 ? max(0, 1 - (t - 2.6) / 0.6) : 1
            ZStack {
                if tone == .victory {
                    Canvas { ctx, size in
                        let c = CGPoint(x: size.width/2, y: size.height/2)
                        let spin = t * 0.25
                        for k in 0..<14 {
                            let a0 = spin + Double(k) * 2 * .pi / 14, a1 = a0 + .pi / 28
                            var path = Path(); path.move(to: c)
                            path.addLine(to: CGPoint(x: c.x + CGFloat(cos(a0)) * size.width, y: c.y + CGFloat(sin(a0)) * size.width))
                            path.addLine(to: CGPoint(x: c.x + CGFloat(cos(a1)) * size.width, y: c.y + CGFloat(sin(a1)) * size.width)); path.closeSubpath()
                            ctx.fill(path, with: .radialGradient(Gradient(colors:[Color(red:1,green:0.88,blue:0.5).opacity(0.30),.clear]), center: c, startRadius: 0, endRadius: size.width * 0.7))
                        }
                    }.opacity(ease)
                }
                VStack(spacing: 0) {
                    Rectangle().fill(edge).frame(height: 2)
                    ZStack {
                        LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                        Text(title).font(.system(size: 34, weight: .heavy, design: .serif))
                            .foregroundStyle(LinearGradient(colors:[Color(red:1,green:0.96,blue:0.78),edge],startPoint:.top,endPoint:.bottom))
                            .shadow(color: .black.opacity(0.7), radius: 2, y: 2)
                            .kerning(4)
                    }.frame(height: 66)
                    Rectangle().fill(edge).frame(height: 2)
                }
                .shadow(color: edge.opacity(tone == .victory ? 0.5 : 0.2), radius: 10)
                .scaleEffect(x: 1, y: CGFloat(0.2 + 0.8 * ease))
            }
            .opacity(fade)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// "Your turn" / "Computer's turn" pill that slides in at the top of the board for under a second at each turn change.
/// Transient, no hit testing, hidden from accessibility (the turn label above the board already says it).
struct ArtTurnBanner: View {
    let text: String
    let black: Bool
    let start: Date
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/30)) { context in
            let t = context.date.timeIntervalSince(start)
            let inT = min(1, t / 0.22), out = t > 0.85 ? max(0, 1 - (t - 0.85) / 0.25) : 1
            let ease = 1 - pow(1 - inT, 3)
            HStack(spacing: 7) {
                Group {
                    if black { Circle().fill(Color(red:0.98,green:0.93,blue:0.78)) }
                    else { Rectangle().fill(Color(red:0.12,green:0.20,blue:0.25)).rotationEffect(.degrees(45)).overlay(Rectangle().stroke(Color(red:0.98,green:0.93,blue:0.78),lineWidth:1).rotationEffect(.degrees(45))) }
                }.frame(width: 9, height: 9)
                Text(text).font(.system(size: 15, weight: .heavy, design: .serif)).foregroundStyle(GameChrome.cream).kerning(1.5)
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
            .background(Capsule().fill(LinearGradient(colors:[Color(red:0.17,green:0.24,blue:0.27),Color(red:0.07,green:0.10,blue:0.13)],startPoint:.top,endPoint:.bottom)))
            .overlay(Capsule().stroke(ArtV2.brass.opacity(0.9), lineWidth: 1.2))
            .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            .offset(y: CGFloat(-16 * (1 - ease))).opacity(ease * out)
        }.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// Selected hero card: lifts a little and glows in the class color.
struct ArtCardLift: ViewModifier {
    let selected: Bool
    let accent: Color
    @ViewBuilder func body(content: Content) -> some View {
        if ArtV2.enabled {
            content.shadow(color: selected ? accent.opacity(0.55) : .clear, radius: selected ? 9 : 0)
                .offset(y: selected ? -3 : 0)   // no scaleEffect: the four cards must keep the same height
                .animation(.easeOut(duration: 0.18), value: selected)
        } else { content }
    }
}

/// A thin brass rule with a diamond at its centre, used under the lobby title.
struct ArtDivider: View {
    var body: some View {
        HStack(spacing: 6) {
            LinearGradient(colors:[.clear,ArtV2.brass.opacity(0.8)],startPoint:.leading,endPoint:.trailing).frame(height: 1)
            Rectangle().fill(ArtV2.brass).frame(width: 6, height: 6).rotationEffect(.degrees(45))
            LinearGradient(colors:[ArtV2.brass.opacity(0.8),.clear],startPoint:.leading,endPoint:.trailing).frame(height: 1)
        }.frame(width: 190).accessibilityHidden(true)
    }
}

/// The table around the board: a warm pool of light under the board and a dark vignette, over the existing backdrop.
struct ArtTable: View {
    var body: some View {
        ZStack {
            GameBackdrop()
            if ArtV2.enabled {
                Canvas { ctx, size in
                    var seed: UInt64 = 0xD1B54A32D192ED03
                    func rnd() -> CGFloat { seed = seed &* 6364136223846793005 &+ 1442695040888963407; return CGFloat((seed >> 33) % 10_000) / 10_000 }
                    for _ in 0..<1400 {
                        let x = size.width * rnd(), y = size.height * rnd(), r = 0.4 + 0.9 * rnd()
                        ctx.fill(Path(ellipseIn:CGRect(x:x,y:y,width:r,height:r)),with:.color((rnd() < 0.5 ? Color.black : Color.white).opacity(0.05)))
                    }
                }.ignoresSafeArea().allowsHitTesting(false)
                RadialGradient(colors:[Color(red:0.62,green:0.43,blue:0.20).opacity(0.26),.clear],
                               center:UnitPoint(x:0.5,y:0.44),startRadius:20,endRadius:520).ignoresSafeArea().allowsHitTesting(false)
                RadialGradient(colors:[.clear,.black.opacity(0.55)],
                               center:UnitPoint(x:0.5,y:0.46),startRadius:260,endRadius:760).ignoresSafeArea().allowsHitTesting(false)
            }
        }.accessibilityHidden(true)
    }
}
#else
import SwiftUI

/// Release (App Store 1.0) keeps the previous look: these stand-ins make the shared lobby code compile unchanged.
enum ArtV2 { static let enabled = false; static let ambient = false; static let sfx = false }
struct ArtTable: View { var body: some View { GameBackdrop() } }
struct ArtDivider: View { var body: some View { EmptyView() } }
struct ArtCardLift: ViewModifier {
    let selected: Bool
    let accent: Color
    func body(content: Content) -> some View { content }
}
#endif

extension ArtV2 {
    /// Versioned original SFX keep their existing keys. Release and --art-v1 resolve the immutable original files.
    static func audioURL(_ name: String, bundle: Bundle = .main, subdirectory: String) -> URL? {
        #if DEBUG || TACTICALGO_V11
        if enabled, let candidate = bundle.url(forResource: name, withExtension: "wav", subdirectory: "Audio/V30") {
            return candidate
        }
        #endif
        return bundle.url(forResource: name, withExtension: "wav", subdirectory: subdirectory)
            ?? bundle.url(forResource: name, withExtension: "wav", subdirectory: "Audio")
            ?? bundle.url(forResource: name, withExtension: "wav")
    }
}
