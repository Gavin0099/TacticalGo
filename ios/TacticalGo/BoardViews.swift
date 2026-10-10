import SwiftUI
import SpriteKit
import TacticalGoCore
import TacticalGoMotion
import TacticalGoVisuals

extension Color {
    static let ink = Color(red: 0.10, green: 0.20, blue: 0.25)
    static let blueTeam = Color(red: 0.23, green: 0.64, blue: 0.91)
    static let redTeam = Color(red: 0.90, green: 0.37, blue: 0.30)
    static let gold = Color(red: 1, green: 0.80, blue: 0.40)
}
struct BoardPresentation {
    let state: GameState
    let selected: [Point]
    let legal: Set<Point>
    let preview: ActionOutcome?
    var captures: Set<Point> {
        Set(preview?.events.flatMap { e -> [Point] in
            if case .piecesCaptured(_, let pieces) = e { return pieces.map(\.at) }
            return []
        } ?? [])
    }
    var danger: Set<Point> {
        guard let commander = state.board.find(state.current, .commander), state.board.liberties(at: commander).count <= 1 else { return [] }
        return Set(state.board.group(at: commander))
    }
    func center(_ p: Point, _ size: CGSize) -> CGPoint {
        let pos = BoardProjection(size: state.board.size).center(p)
        return CGPoint(x: pos.x * size.width, y: pos.y * size.height)
    }
    func artSize(_ size: CGSize) -> CGFloat {
        // Limit the upright silhouette by row pitch to preserve dense vertical neighbors.
        min(size.width / CGFloat(state.board.size + 1) * 1.02, size.height * 0.65 / CGFloat(state.board.size - 1) * 1.10)
    }
    func radius(_ p: Point, _ size: CGSize) -> CGFloat {
        size.width / CGFloat(state.board.size + 1) * 0.31
    }
}
struct ArenaGround: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: r.width * 0.09, y: r.height * 0.10))
            p.addLine(to: CGPoint(x: r.width * 0.91, y: r.height * 0.10))
            p.addLine(to: CGPoint(x: r.width * 0.99, y: r.height * 0.92))
            p.addLine(to: CGPoint(x: r.width * 0.01, y: r.height * 0.92)); p.closeSubpath()
        }
    }
}
struct ArenaGrid: Shape {
    let boardSize: Int
    func path(in r: CGRect) -> Path {
        let projection = BoardProjection(size: boardSize)
        func point(_ p: Point) -> CGPoint { let a = projection.center(p); return CGPoint(x: a.x * r.width, y: a.y * r.height) }
        return Path { path in
            for n in 0..<boardSize {
                path.move(to: point(Point(0, n))); path.addLine(to: point(Point(boardSize - 1, n)))
                path.move(to: point(Point(n, 0))); path.addLine(to: point(Point(n, boardSize - 1)))
            }
        }
    }
}
/// Immutable source art; faction, selection and warnings belong to separate layers.
@MainActor enum BoardArt {
    static let miniatures: [HeroClass: UIImage] = {
        var images: [HeroClass: UIImage] = [:]
        for hero in [HeroClass.warrior, .mage, .rogue] {
            if let image = UIImage(named: name(for: hero)) { images[hero] = image }
        }
        return images
    }()
    static func name(for hero: HeroClass) -> String { "miniature-" + hero.rawValue.lowercased() }
    // Candidate foot anchors on the unchanged source canvas, from visual inspection.
    static func anchor(for hero: HeroClass) -> CGPoint {
        switch hero {
        case .warrior: CGPoint(x: 0.54, y: 0.93)
        case .mage: CGPoint(x: 0.54, y: 0.94)
        case .rogue: CGPoint(x: 0.55, y: 0.93)
        case .none: CGPoint(x: 0.5, y: 0.93)
        }
    }
}
struct PieceToken: View {
    let piece: Piece
    let heroClass: HeroClass
    let radius: CGFloat
    let artSize: CGFloat
    var team: Color { piece.owner == .one ? .blueTeam : .redTeam }
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.27)).frame(width: radius * 2.5, height: radius * 0.9).offset(y: radius * 0.25)
            Ellipse().fill(team.gradient).frame(width: radius * 2.2, height: radius * 1.25)
                .overlay(Ellipse().stroke(.white.opacity(0.8), lineWidth: 1))
            if piece.kind == .hero, let art = BoardArt.miniatures[heroClass] {
                let anchor = BoardArt.anchor(for: heroClass)
                Image(uiImage: art).resizable().interpolation(.high).scaledToFit()
                    .frame(width: artSize, height: artSize)
                    .offset(x: (0.5 - anchor.x) * artSize, y: (0.5 - anchor.y) * artSize)
            } else {
                Ellipse().fill(piece.owner == .one ? Color(red: 0.13, green: 0.19, blue: 0.23) : Color(red: 0.98, green: 0.94, blue: 0.83))
                    .frame(width: radius * 1.8, height: radius * 1.4).offset(y: -radius * 0.3)
                    .overlay(Ellipse().stroke(piece.kind == .commander ? Color.gold : Color.white.opacity(0.4), lineWidth: piece.kind == .commander ? 2 : 1)
                        .frame(width: radius * 1.8, height: radius * 1.4).offset(y: -radius * 0.3))
                Ellipse().fill(.white.opacity(piece.owner == .one ? 0.18 : 0.7)).frame(width: radius * 0.6, height: radius * 0.3).offset(x: -radius * 0.3, y: -radius * 0.6)
                if piece.kind == .commander {
                    Image(systemName: "crown.fill").font(.system(size: radius * 1.15, weight: .black)).foregroundStyle(piece.owner == .one ? Color.gold : Color.ink).offset(y: -radius * 0.55)
                }
            }
            // Front marker remains visible without recoloring the character.
            if piece.owner == .one {
                Circle().fill(.white).frame(width: radius * 0.28).offset(y: radius * 0.44)
            } else {
                Image(systemName: "triangle.fill").font(.system(size: radius * 0.32)).foregroundStyle(.white).offset(y: radius * 0.44)
            }
        }
    }
}
/// A0 is the unchanged, reviewed symbol token, not an invented full-body character.
struct A0PieceToken: View {
    var visuals: GameVisualAssets = .original
    let piece: Piece
    let heroClass: HeroClass
    let radius: CGFloat
    private var black: Bool { piece.owner == .one }
    private var fill: Color { black ? Color(red: 0.045, green: 0.055, blue: 0.065) : Color(red: 1, green: 0.98, blue: 0.90) }
    private var edge: Color { black ? .white : Color(red: 0.10, green: 0.12, blue: 0.14) }
    private var factionSprite: SpriteAsset? {
        if piece.kind == .commander { return black ? visuals.pack.blackCommander : visuals.pack.whiteCommander }
        return black ? visuals.pack.blackSoldier : visuals.pack.whiteSoldier
    }
    var body: some View {
        ZStack {
            Ellipse().fill(.black.opacity(0.32)).frame(width: radius * 2.9, height: radius * 1.15).offset(y: radius * 0.4)
            Ellipse().fill(black ? Color.black : Color(red: 0.67, green: 0.63, blue: 0.51))
                .frame(width: radius * 2.65, height: radius * 1.8).offset(y: radius * 0.15)
            Ellipse().fill(fill.gradient).frame(width: radius * 2.65, height: radius * 1.7)
                .overlay(Ellipse().stroke(edge, lineWidth: 1.4))
            if piece.kind == .hero {
                // Preserve source pixels; ownership belongs to this separate base/badge.
                if let asset = visuals.pack.heroes[heroClass.rawValue.lowercased()]?.token {
                    AnchoredSprite(asset: asset, visuals: visuals, radius: radius)
                }
            } else if let asset = factionSprite {
                AnchoredSprite(asset: asset, visuals: visuals, radius: radius)
            } else if piece.kind == .commander {
                Image(systemName: "crown.fill").font(.system(size: radius * 0.92, weight: .black))
                    .foregroundStyle(black ? Color.gold : Color.ink).offset(y: -radius * 0.16)
            } else {
                Ellipse().fill(.white.opacity(black ? 0.20 : 0.85)).frame(width: radius * 0.7, height: radius * 0.3)
                    .offset(x: -radius * 0.43, y: -radius * 0.4)
            }
            if piece.kind != .soldier {
                Text(black ? "黑" : "白").font(.system(size: max(7, radius * 0.62), weight: .black))
                    .foregroundStyle(edge).frame(width: radius * 0.95, height: radius * 1.05)
                    .background(fill, in: RoundedRectangle(cornerRadius: 3))
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(edge, lineWidth: 1))
                    .offset(x: radius * 1.05, y: radius * 0.08)
            }
        }
    }
}
struct WoodGrain: Shape {
    func path(in r: CGRect) -> Path {
        Path { p in
            for i in 0..<14 {
                let x = r.width * CGFloat(i) / 13
                p.move(to: CGPoint(x: x, y: 0))
                p.addCurve(to: CGPoint(x: x + 5, y: r.height), control1: CGPoint(x: x - 10, y: r.height * 0.3), control2: CGPoint(x: x + 12, y: r.height * 0.65))
            }
        }
    }
}
struct SwiftBoard: View {
    var visuals: GameVisualAssets = .original
    let presentation: BoardPresentation
    var computerAction: GameAction? = nil
    var motion: BoardPlayback? = nil
    var motionStartedAt: Date? = nil
    var reducedMotion = false
    let select: (Point) -> Void
    var body: some View {
        TimelineView(.animation(paused: motionStartedAt == nil || reducedMotion)) { clock in
        GeometryReader { geo in
            let animation = BotBoardFrame.make(motion, startedAt: motionStartedAt, now: clock.date, reducedMotion: reducedMotion)
            ZStack {
                if let asset = visuals.pack.boardShadow {
                    Image(uiImage: visuals.image(asset)).resizable().frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ArenaGround().fill(Color(red: 0.26, green: 0.13, blue: 0.08)).offset(y: 10)
                }
                if let asset = visuals.pack.boardSurface {
                    Image(uiImage: visuals.image(asset)).resizable().frame(width: geo.size.width, height: geo.size.height)
                } else {
                    ArenaGround().fill(LinearGradient(colors: [Color(red: 0.80, green: 0.61, blue: 0.35), Color(red: 0.60, green: 0.39, blue: 0.20)], startPoint: .top, endPoint: .bottom))
                        .overlay(ArenaGround().stroke(Color.gold.opacity(0.65), lineWidth: 4))
                    WoodGrain().stroke(Color(red: 0.3, green: 0.15, blue: 0.06).opacity(0.13), lineWidth: 1).clipShape(ArenaGround())
                }
                ArenaGrid(boardSize: presentation.state.board.size).stroke(Color.ink.opacity(0.32), lineWidth: 1.2)
                ForEach(presentation.state.board.points, id: \.self) { p in
                    let center = presentation.center(p, geo.size)
                    let r = presentation.radius(p, geo.size)
                    ZStack {
                        if presentation.legal.contains(p) { Circle().fill(Color.white.opacity(0.28)).frame(width: r * 0.5) }
                        if presentation.state.seals.contains(where: { $0.at == p }) { Circle().stroke(.purple, lineWidth: 3).frame(width: r * 1.8) }
                        let visibleBoard = presentation.preview?.success == true ? presentation.preview!.state.board : presentation.state.board
                        if let piece = visibleBoard[p], !animation.hidden.contains(p) {
                            A0PieceToken(visuals: visuals, piece: piece, heroClass: presentation.state.heroClass(of: piece.owner), radius: r)
                                .opacity(presentation.preview?.success == true && piece != presentation.state.board[p] ? 0.68 : 1)
                        }
                        if presentation.captures.contains(p), let old = presentation.state.board[p] {
                            A0PieceToken(visuals: visuals, piece: old, heroClass: presentation.state.heroClass(of: old.owner), radius: r).opacity(0.3)
                        }
                    }.position(center).zIndex(Double(p.y) * 10 + 10).allowsHitTesting(false)
                }
                ForEach(animation.sprites) { sprite in
                    let from = presentation.center(sprite.from, geo.size)
                    let to = presentation.center(sprite.to, geo.size)
                    A0PieceToken(visuals: visuals, piece: sprite.piece,
                        heroClass: presentation.state.heroClass(of: sprite.piece.owner), radius: presentation.radius(sprite.to, geo.size))
                        .scaleEffect(sprite.scale).opacity(sprite.opacity)
                        .position(x: from.x + (to.x - from.x) * CGFloat(sprite.progress),
                                  y: from.y + (to.y - from.y) * CGFloat(sprite.progress) + CGFloat(sprite.lift))
                        .zIndex(180 + Double(sprite.to.y)).allowsHitTesting(false)
                }
                ForEach(0..<presentation.state.board.size, id: \.self) { n in
                    let x = presentation.center(Point(n, presentation.state.board.size - 1), geo.size)
                    let y = presentation.center(Point(0, n), geo.size)
                    Text(String(UnicodeScalar(65 + n)!)).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.ink).position(x: x.x, y: geo.size.height * 0.885)
                    Text(String(n + 1)).font(.system(size: 10, weight: .bold)).foregroundStyle(Color.ink).position(x: y.x - 16, y: y.y)
                }
                // Overlays use a separate top layer, independent of character row ordering.
                ForEach(presentation.state.board.points, id: \.self) { p in
                    let center = presentation.center(p, geo.size)
                    let r = presentation.radius(p, geo.size)
                    ZStack {
                        if presentation.danger.contains(p) || presentation.captures.contains(p) {
                            Circle().stroke(Color.redTeam, style: StrokeStyle(lineWidth: 3, dash: [3, 2])).frame(width: r * 2.5)
                        }
                        if presentation.selected.contains(p) { Circle().stroke(Color.gold, lineWidth: 3).frame(width: r * 2.7) }
                        if botFocus.contains(p) {
                            Ellipse().stroke(Color.gold, lineWidth: 3).frame(width: r * 3.3, height: r * 2.2)
                            Image(systemName: "hand.point.down.fill").foregroundStyle(Color.gold)
                                .font(.system(size: max(16, r))).offset(y: -r * 2.2)
                        }
                    }.position(center).zIndex(200).allowsHitTesting(false)
                }
                if let arrow = botArrow {
                    let a = presentation.center(arrow.0, geo.size), b = presentation.center(arrow.1, geo.size)
                    Path { p in p.move(to: a); p.addLine(to: b) }
                        .stroke(Color.gold, style: StrokeStyle(lineWidth: 3, dash: [5, 4])).zIndex(210).allowsHitTesting(false)
                    Image(systemName: "arrowtriangle.right.fill").foregroundStyle(Color.gold)
                        .rotationEffect(.radians(atan2(b.y - a.y, b.x - a.x)))
                        .position(b).zIndex(211).allowsHitTesting(false)
                }
            }.contentShape(Rectangle()).gesture(SpatialTapGesture().onEnded { tap in
                if let p = BoardProjection(size: presentation.state.board.size).hit(x: tap.location.x / geo.size.width, y: tap.location.y / geo.size.height) { select(p) }
            })
        }
        }
    }
    private var botFocus: Set<Point> {
        guard let action = computerAction else { return [] }
        switch action {
        case .placeSoldier(let p), .summonHero(let p), .castSeal(let p): return [p]
        case .castBastion(let a, let b), .castFriendlyRedeploy(let a, let b): return [a, b]
        case .castMagicHand(let p, let d): return [p, d.destination(from: p)]
        case .castSwap(let p): return Set([p] + (botArrow.map { [$0.0] } ?? []))
        case .endTurn: return []
        }
    }
    private var botArrow: (Point, Point)? {
        switch computerAction {
        case .castMagicHand(let p, let d): return (p, d.destination(from: p))
        case .castFriendlyRedeploy(let from, let to): return (from, to)
        case .castSwap(let p):
            let before = motion?.before ?? presentation.state
            return before.board.find(before.current, .hero).map { ($0, p) }
        default: return nil
        }
    }
}
/// Small A0 presentation adapter for committed Bot events; no game rules or new art.
struct BotBoardFrame {
    struct Sprite: Identifiable {
        let id: Int
        let piece: Piece
        let from: Point
        let to: Point
        let progress: Double
        let lift: Double
        let scale: Double
        let opacity: Double
        var lateral = 0.0
    }
    var hidden: Set<Point> = []
    var sprites: [Sprite] = []
    /// Reuses the existing sprite data and MotionPlan timing for committed native actions.
    static func committed(_ receipt: BoardPlayback, elapsed: Double, pitch: Double, reducedMotion: Bool) -> BotBoardFrame {
        let plan = receipt.plan
        guard !reducedMotion, receipt.outcome.success, elapsed < plan.duration else { return BotBoardFrame() }
        func fraction(_ start: Double, _ duration: Double) -> Double { min(1, max(0, (elapsed - start) / duration)) }
        var result = BotBoardFrame(), animated: Set<Point> = []
        let captures = plan.cues.filter { if case .capture = $0.kind { return true }; return false }
        func opacity(_ at: Point) -> Double {
            guard let cue = captures.first(where: { $0.points.contains(at) }) else { return 1 }
            return 1 - fraction(cue.start, cue.duration)
        }
        for cue in plan.cues {
            switch cue.kind {
            case .drop(let kind):
                for p in cue.points {
                    result.hidden.insert(p); animated.insert(p)
                    // The committed after-board already contains both soldiers.
                    // Keep their destinations hidden until the body's release cue.
                    guard elapsed >= cue.start else { continue }
                    let t = fraction(cue.start,cue.duration)
                    result.sprites.append(Sprite(id: result.sprites.count, piece: Piece(receipt.before.current,kind), from: p,to: p,progress: 1,
                        lift: -pitch * 0.18 * MotionCurves.dropHeight(t),scale: kind == .hero ? 0.62 + 0.38 * MotionCurves.ease(min(1,t / 0.70)) : 1,
                        opacity: (kind == .hero && receipt.heroPerformance?.isSummon != true ? min(1,t / 0.35) : 1) * opacity(p)))
                }
            case .swap:
                guard cue.points.count == 2 else { continue }
                for i in 0..<2 {
                    let from = cue.points[i], to = cue.points[1-i]
                    guard let piece = receipt.before.board[from] else { continue }
                    let t = fraction(cue.start,cue.duration)
                    result.hidden.insert(from); result.hidden.insert(to); animated.insert(to)
                    result.sprites.append(Sprite(id: result.sprites.count,piece: piece,from: from,to: to,
                        progress: MotionCurves.swapProgress(t),
                        lift: from.x == to.x ? 0 : (piece.kind == .hero ? -pitch * 0.16 : pitch * 0.08) * sin(t * .pi),
                        scale: 1,opacity: opacity(to),
                        lateral: from.x == to.x ? (piece.kind == .hero ? -pitch * 0.16 : pitch * 0.08) * sin(t * .pi) : 0))
                }
            case .capture(let piece):
                for p in cue.points where !animated.contains(p) {
                    let t = fraction(cue.start,cue.duration); result.hidden.insert(p)
                    result.sprites.append(Sprite(id: result.sprites.count,piece: piece,from: p,to: p,progress: 1,lift: -pitch * 0.12 * t,scale: 1 - 0.45 * t,opacity: 1 - t))
                }
            default: break
            }
        }
        return result
    }
    static func make(_ receipt: BoardPlayback?, startedAt: Date?, now: Date, reducedMotion: Bool) -> BotBoardFrame {
        guard !reducedMotion, let receipt, let startedAt else { return BotBoardFrame() }
        let elapsed = max(0, now.timeIntervalSince(startedAt))
        func fraction(_ start: Double, _ duration: Double) -> Double { min(1, max(0, (elapsed - start) / duration)) }
        let move = fraction(0, 0.42), fade = fraction(0.45, 0.25)
        var captured: [Point: Piece] = [:]
        for event in receipt.outcome.events {
            if case .piecesCaptured(_, let pieces) = event { for piece in pieces { captured[piece.at] = piece.piece } }
        }
        var result = BotBoardFrame(), animatedDestinations: Set<Point> = []
        func add(_ piece: Piece, _ from: Point, _ to: Point, drop: Bool = false) {
            result.hidden.insert(to); animatedDestinations.insert(to)
            let opacity = captured[to] == nil ? 1.0 : 1 - fade
            result.sprites.append(Sprite(id: result.sprites.count, piece: piece, from: from, to: to,
                progress: move * move * (3 - 2 * move), lift: drop ? -28 * (1 - move) * (1 - move) : -14 * sin(.pi * move),
                scale: drop ? 0.82 + 0.18 * move : 1, opacity: opacity))
        }
        for event in receipt.outcome.events {
            switch event {
            case .piecePlaced(let owner, let p, let kind): add(Piece(owner, kind), p, p, drop: true)
            case .piecePushed(_, let from, let to, let piece): add(piece, from, to)
            case .piecesSwapped(_, let a, let b):
                if let piece = receipt.before.board[a] { add(piece, a, b) }
                if let piece = receipt.before.board[b] { add(piece, b, a) }
            default: break
            }
        }
        for p in captured.keys.sorted(by: { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y }) where !animatedDestinations.contains(p) {
            result.hidden.insert(p)
            result.sprites.append(Sprite(id: result.sprites.count, piece: captured[p]!, from: p, to: p,
                progress: 1, lift: -12 * fade, scale: 1 - 0.45 * fade, opacity: 1 - fade))
        }
        return result
    }
}
@MainActor final class ArenaScene: SKScene {
    var select: ((Point) -> Void)?
    var presentation: BoardPresentation?
    func show(_ data: BoardPresentation, size: CGSize) {
        self.size = size; scaleMode = .resizeFill; backgroundColor = .clear; presentation = data
        removeAllChildren()
        let groundPath = ArenaGround().path(in: CGRect(origin: .zero, size: size)).cgPath
        // SwiftUI top-left coordinates become SpriteKit bottom-left exactly once here.
        var transform = CGAffineTransform(translationX: 0, y: size.height).scaledBy(x: 1, y: -1)
        let base = SKShapeNode(path: groundPath.copy(using: &transform)!)
        base.fillColor = UIColor(red: 0.49, green: 0.67, blue: 0.51, alpha: 1)
        base.strokeColor = UIColor(Color.gold); base.lineWidth = 4; addChild(base)
        let depth = base.copy() as! SKShapeNode; depth.position.y = -10; depth.fillColor = UIColor(Color.ink); depth.zPosition = -1; addChild(depth)
        let gridPath = ArenaGrid(boardSize: data.state.board.size).path(in: CGRect(origin: .zero, size: size)).cgPath
        let grid = SKShapeNode(path: gridPath.copy(using: &transform)!); grid.strokeColor = UIColor(Color.ink.opacity(0.32)); grid.lineWidth = 1.2; addChild(grid)
        for p in data.state.board.points {
            let pos = data.center(p, size), r = data.radius(p, size)
            let anchor = CGPoint(x: pos.x, y: size.height - pos.y)
            if data.legal.contains(p) {
                let dot = SKShapeNode(circleOfRadius: r * 0.25); dot.fillColor = .white.withAlphaComponent(0.3); dot.strokeColor = .clear; dot.position = anchor; dot.zPosition = 1; addChild(dot)
            }
            if data.state.seals.contains(where: { $0.at == p }) {
                let ring = SKShapeNode(circleOfRadius: r); ring.strokeColor = .systemPurple; ring.lineWidth = 3; ring.position = anchor; ring.zPosition = 2; addChild(ring)
            }
            if let piece = data.state.board[p] {
                let team = UIColor(piece.owner == .one ? Color.blueTeam : Color.redTeam)
                let group = SKNode(); group.position = anchor; group.zPosition = CGFloat(p.y) * 10 + 10
                let shadow = SKShapeNode(ellipseOf: CGSize(width: r * 2.4, height: r * 0.9)); shadow.fillColor = .black.withAlphaComponent(0.25); shadow.strokeColor = .clear; shadow.position.y = -r * 0.35; group.addChild(shadow)
                let base = SKShapeNode(ellipseOf: CGSize(width: r * 2, height: r * 1.25)); base.fillColor = team.withAlphaComponent(0.85); base.strokeColor = .white.withAlphaComponent(0.8); base.lineWidth = 1; group.addChild(base)
                let heroClass = data.state.heroClass(of: piece.owner)
                if piece.kind == .hero, let image = BoardArt.miniatures[heroClass] {
                    let figure = SKSpriteNode(texture: SKTexture(image: image))
                    let canvas = data.artSize(size), anchor = BoardArt.anchor(for: heroClass)
                    figure.size = CGSize(width: canvas, height: canvas)
                    figure.anchorPoint = CGPoint(x: anchor.x, y: 1 - anchor.y)
                    figure.texture?.filteringMode = .linear
                    group.addChild(figure)
                } else {
                    let stone = SKShapeNode(ellipseOf: CGSize(width: r * 1.8, height: r * 1.4))
                    stone.position.y = r * 0.3
                    stone.fillColor = piece.owner == .one ? UIColor(red: 0.13, green: 0.19, blue: 0.23, alpha: 1) : UIColor(red: 0.98, green: 0.94, blue: 0.83, alpha: 1)
                    stone.strokeColor = piece.kind == .commander ? UIColor(Color.gold) : .white.withAlphaComponent(0.4)
                    stone.lineWidth = piece.kind == .commander ? 2 : 1; group.addChild(stone)
                    let glint = SKShapeNode(ellipseOf: CGSize(width: r * 0.6, height: r * 0.3)); glint.fillColor = .white.withAlphaComponent(piece.owner == .one ? 0.18 : 0.7); glint.strokeColor = .clear; glint.position = CGPoint(x: -r * 0.3, y: r * 0.6); group.addChild(glint)
                    if piece.kind == .commander, let image = UIImage(systemName: "crown.fill")?.withTintColor(piece.owner == .one ? UIColor(Color.gold) : UIColor(Color.ink), renderingMode: .alwaysOriginal) {
                        let raster = UIGraphicsImageRenderer(size: CGSize(width: 48, height: 48)).image { _ in image.draw(in: CGRect(x: 0, y: 0, width: 48, height: 48)) }
                        let crown = SKSpriteNode(texture: SKTexture(image: raster)); crown.size = CGSize(width: r * 1.15, height: r * 1.15); crown.position.y = r * 0.55; group.addChild(crown)
                    }
                }
                let marker: SKShapeNode
                if piece.owner == .one { marker = SKShapeNode(circleOfRadius: r * 0.14) }
                else {
                    let path = CGMutablePath(); path.move(to: CGPoint(x: 0, y: r * 0.18)); path.addLine(to: CGPoint(x: -r * 0.17, y: -r * 0.14)); path.addLine(to: CGPoint(x: r * 0.17, y: -r * 0.14)); path.closeSubpath(); marker = SKShapeNode(path: path)
                }
                marker.fillColor = .white; marker.strokeColor = .clear; marker.position.y = -r * 0.44; group.addChild(marker)
                addChild(group)
            }
            if data.danger.contains(p) || data.captures.contains(p) {
                let danger = SKShapeNode(circleOfRadius: r * 1.25); danger.strokeColor = UIColor(Color.redTeam); danger.lineWidth = 3; danger.position = anchor; danger.zPosition = 190; addChild(danger)
            }
            if data.selected.contains(p) {
                let ring = SKShapeNode(circleOfRadius: r * 1.35); ring.strokeColor = UIColor(Color.gold); ring.lineWidth = 3
                ring.fillColor = data.preview?.success == true ? UIColor(Color.gold.opacity(0.25)) : .clear
                ring.position = anchor; ring.zPosition = 200; addChild(ring)
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in: self), let presentation else { return }
        if let cell = BoardProjection(size: presentation.state.board.size).hit(x: p.x / size.width, y: 1 - p.y / size.height) { select?(cell) }
    }
}
struct SpriteBoard: View {
    let presentation: BoardPresentation
    let select: (Point) -> Void
    @State private var scene = ArenaScene()
    var body: some View {
        GeometryReader { geo in
            SpriteView(scene: scene, options: [.allowsTransparency])
                .onAppear { scene.select = select; scene.show(presentation, size: geo.size) }
                .onChange(of: presentation.state) { scene.show(presentation, size: geo.size) }
                .onChange(of: presentation.selected) { scene.show(presentation, size: geo.size) }
                .onChange(of: presentation.legal) { scene.show(presentation, size: geo.size) }
                .onChange(of: geo.size) { scene.show(presentation, size: geo.size) }
        }
    }
}
