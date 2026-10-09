import SwiftUI
import TacticalGoCore
import TacticalGoMotion
import TacticalGoVisuals

/// Local candidate renderer. The bitmap/VFX only decorate typed successful events.
struct CozyBoard: View {
    let presentation: BoardPresentation
    let assets: CozyAssets
    let playback: BoardPlayback?
    let botPlayback: BoardPlayback?
    let botStartedAt: Date?
    let animating: Bool
    let reducedMotion: Bool
    let checkpoint: Double?
    let select: (Point) -> Void
    private var receipt: BoardPlayback? {
        guard let playback, playback.outcome.state == presentation.state,
              Anim01MagicHand.make(before: playback.before, action: playback.action, outcome: playback.outcome) != nil else { return nil }
        return playback
    }
    var body: some View {
        GeometryReader { geometry in
            let fit = Anim01Geometry(width: geometry.size.width, height: geometry.size.height, boardSize: presentation.state.board.size)
            TimelineView(.animation(minimumInterval: 1 / 60, paused: !animating || (receipt == nil && botPlayback == nil) || checkpoint != nil || reducedMotion)) { context in
                let elapsed = checkpoint ?? (receipt.map { item in
                    let clip = Anim01MagicHand.make(before: item.before, action: item.action, outcome: item.outcome)!
                    return clip.displayTime(elapsed: context.date.timeIntervalSince(item.startedAt), animating: animating, reducedMotion: reducedMotion)
                } ?? 0)
                #if DEBUG
                let _ = CozyTrace.record(receipt: receipt, elapsed: elapsed, reduced: reducedMotion)
                #endif
                layers(size: CGSize(width: fit.width, height: fit.height), pitch: fit.pitch, receipt: receipt, elapsed: elapsed, now: context.date)
                    .frame(width: fit.width, height: fit.height)
                    .offset(x: fit.x, y: fit.y)
            }
            // Tap coordinates use the entire available arena, including fit margins.
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .contentShape(Rectangle())
            .gesture(SpatialTapGesture().onEnded { tap in
                guard fit.width > 0, fit.height > 0, fit.contains(x: tap.location.x, y: tap.location.y) else { return }
                if let point = BoardProjection(size: presentation.state.board.size).hit(
                    x: (tap.location.x - fit.x) / fit.width, y: (tap.location.y - fit.y) / fit.height) { select(point) }
            })
            .onAppear { recordGeometry(fit, available: geometry.size) }
            .onChange(of: geometry.size) { _, size in
                recordGeometry(Anim01Geometry(width: size.width, height: size.height, boardSize: presentation.state.board.size), available: size)
            }
        }

    }
    private func recordGeometry(_ fit: Anim01Geometry, available: CGSize) {
        #if DEBUG
        let board = receipt?.before.board ?? presentation.state.board
        let units = board.points.compactMap { p -> [String: Any]? in
            guard let piece = board[p] else { return nil }
            let center = BoardProjection(size: board.size).center(p)
            return ["point": [p.x, p.y], "owner": piece.owner == .one ? "black" : "white", "kind": String(describing: piece.kind),
                    "center": [fit.x + center.x * fit.width, fit.y + center.y * fit.height]]
        }
        let report: [String: Any] = ["renderer": "native SwiftUI CozyBoard", "pack": assets.anim.manifest.id,
            "available": [available.width, available.height], "fitted": [fit.x, fit.y, fit.width, fit.height],
            "pitch": fit.pitch, "boardSize": board.size, "units": units,
            "heroRepresentation": "original B-v02 runtime half-body clip",
            "reducedMotion": reducedMotion, "checkpointMs": checkpoint.map { $0 * 1000 } ?? -1]
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: directory.appendingPathComponent("cozy-render-geometry.json"), options: .atomic)
        }
        #endif
    }
    private func point(_ p: Point, size: CGSize) -> CGPoint { presentation.center(p, size) }
    @ViewBuilder private func layers(size: CGSize, pitch: CGFloat, receipt: BoardPlayback?, elapsed: Double, now: Date) -> some View {
        let clip = receipt.flatMap { Anim01MagicHand.make(before: $0.before, action: $0.action, outcome: $0.outcome) }
        let generic = receipt == nil ? BotBoardFrame.make(botPlayback, startedAt: botStartedAt, now: now, reducedMotion: reducedMotion) : BotBoardFrame()
        let preview = presentation.preview.flatMap { result -> (from: Point, to: Point)? in
            guard result.success else { return nil }
            for event in result.events { if case .piecePushed(_, let from, let to, _) = event { return (from, to) } }
            return nil
        }
        let showingAnimation = clip != nil && elapsed < (clip?.duration ?? 0) && !reducedMotion
        let displayed = showingAnimation ? receipt!.before.board : presentation.state.board
        let progress = clip?.progress(at: elapsed, reducedMotion: reducedMotion) ?? 1
        ZStack {
            Image(uiImage: assets.shadow).resizable().frame(width: size.width, height: size.height)
            Image(uiImage: assets.board).resizable().frame(width: size.width, height: size.height)
            ArenaGrid(boardSize: presentation.state.board.size).stroke(Color.ink.opacity(0.30), lineWidth: 1)
            ForEach(presentation.state.board.points, id: \.self) { p in
                let hideMovedSource = showingAnimation && p == clip?.from
                let captured = clip?.captures.first { $0.at == p }
                let captureOpacity = elapsed < 0.4 ? 1.0 : max(0, 1 - (elapsed - 0.4) / 0.18)
                ZStack {
                    if presentation.legal.contains(p) { Circle().fill(Color.white.opacity(0.40)).frame(width: pitch * 0.15) }
                    if !hideMovedSource, !generic.hidden.contains(p), let piece = displayed[p] {
                        token(piece, pitch: pitch).opacity(showingAnimation && captured != nil ? captureOpacity : 1)
                    }
                }.position(point(p, size: size)).zIndex(Double(p.y) * 10 + 10)
            }
            ForEach(generic.sprites) { sprite in
                let a = point(sprite.from, size: size), b = point(sprite.to, size: size)
                token(sprite.piece, pitch: pitch).scaleEffect(sprite.scale).opacity(sprite.opacity)
                    .position(x: a.x + (b.x - a.x) * sprite.progress,
                              y: a.y + (b.y - a.y) * sprite.progress + sprite.lift)
                    .zIndex(180 + Double(sprite.to.y))
            }
            if let clip, showingAnimation {
                let a = point(clip.from, size: size), b = point(clip.to, size: size)
                let position = CGPoint(x: a.x + (b.x - a.x) * progress, y: a.y + (b.y - a.y) * progress)
                let squash = elapsed >= 0.30 && elapsed < 0.40 ? 0.94 + 0.06 * (elapsed - 0.30) / 0.10 : 1
                token(clip.piece, pitch: pitch, squash: squash).position(position).zIndex(Double(clip.from.y) * 10 + Double(clip.to.y - clip.from.y) * 10 * progress + 11)
                if elapsed < 0.08 { effect("cast", elapsed: elapsed, pitch: pitch).position(point(clip.hero, size: size)).zIndex(190) }
                else if elapsed < 0.30 { effect("push", elapsed: elapsed - 0.08, pitch: pitch).position(position).zIndex(190) }
                else if elapsed < 0.40 { effect("landing", elapsed: elapsed - 0.30, pitch: pitch).position(b).zIndex(190) }
                if elapsed >= 0.40 {
                    ForEach(clip.captures, id: \.at) { captured in
                        effect("capture", elapsed: elapsed - 0.40, pitch: pitch).position(point(captured.at, size: size)).zIndex(190)
                    }
                }
            }
            if let clip, reducedMotion {
                Circle().stroke(Color(red: 146 / 255.0, green: 119 / 255.0, blue: 182 / 255.0), lineWidth: 2)
                    .frame(width: pitch * 0.78).position(point(clip.to, size: size)).zIndex(190)
            }
            if let preview, !showingAnimation {
                Anim01Arrow(from: point(preview.from, size: size), to: point(preview.to, size: size), pitch: pitch)
                    .stroke(Cozy.card, lineWidth: 5).zIndex(199)
                Anim01Arrow(from: point(preview.from, size: size), to: point(preview.to, size: size), pitch: pitch)
                    .stroke(Cozy.deepMage, style: StrokeStyle(lineWidth: 2, dash: [3, 3])).zIndex(200)
                Circle().stroke(Cozy.deepMage, lineWidth: 2).frame(width: pitch * 0.78)
                    .position(point(preview.to, size: size)).zIndex(200)
            }
            ForEach(presentation.state.board.points, id: \.self) { p in
                ZStack {
                    if presentation.danger.contains(p) || presentation.captures.contains(p) {
                        Circle().stroke(Color(red: 0.81, green: 0.40, blue: 0.35), style: StrokeStyle(lineWidth: 2, dash: [3, 3])).frame(width: pitch * 0.80)
                    }
                    if presentation.selected.contains(p) { Circle().stroke(Color(red: 0.37, green: 0.53, blue: 0.40), lineWidth: 2).frame(width: pitch * 0.82) }
                }.position(point(p, size: size)).zIndex(210)
            }
            // Liberties are real empty points of the commander group, never HP.
            // Movement shows source-board information; settling uses the committed result.
            let informationBoard = showingAnimation && elapsed < 0.30 ? receipt!.before.board : presentation.state.board
            ForEach(Player.allCases, id: \.self) { owner in
                if let commander = informationBoard.find(owner, .commander) {
                    let liberties = informationBoard.liberties(at: commander)
                    ForEach(Array(liberties), id: \.self) { p in
                        Circle().stroke(liberties.count == 1 ? Color(red: 0.81, green: 0.40, blue: 0.35) : owner == .one ? Color(red: 0.37, green: 0.53, blue: 0.40) : Color(red: 217 / 255.0, green: 180 / 255.0, blue: 108 / 255.0), lineWidth: 1.2)
                            .frame(width: pitch * 0.25).position(point(p, size: size)).zIndex(215)
                    }
                }
            }
            ForEach(0..<presentation.state.board.size, id: \.self) { n in
                let x = point(Point(n, presentation.state.board.size - 1), size: size), y = point(Point(0, n), size: size)
                CozyCoordinate(value: String(UnicodeScalar(65 + n)!)).position(x: x.x, y: size.height * 0.885)
                CozyCoordinate(value: String(n + 1)).position(x: y.x - 10, y: y.y)
            }.zIndex(220)
        }
    }
    @ViewBuilder private func effect(_ key: String, elapsed: Double, pitch: CGFloat) -> some View {
        if let image = assets.anim.fx(key, elapsed: elapsed), let clip = assets.anim.manifest.fx[key] {
            let width = pitch * clip.widthInLocalD
            Image(uiImage: image).resizable().frame(width: width, height: width)
                .offset(x: (0.5 - clip.anchorX) * width, y: (0.5 - clip.anchorY) * width)
        }
    }
    private func token(_ piece: Piece, pitch: CGFloat, squash: Double = 1) -> some View {
        CozyToken(piece: piece, assets: assets, pitch: pitch, squash: squash, heroClass: presentation.state.heroClass(of: piece.owner))
    }
}

private struct Anim01Arrow: Shape {
    let from: CGPoint
    let to: CGPoint
    let pitch: CGFloat
    func path(in rect: CGRect) -> Path {
        let dx = to.x - from.x, dy = to.y - from.y, distance = hypot(dx, dy)
        guard distance > 0 else { return Path() }
        let x = dx / distance, y = dy / distance, trim = min(pitch * 0.22, distance * 0.25)
        let a = CGPoint(x: from.x + x * trim, y: from.y + y * trim), b = CGPoint(x: to.x - x * trim, y: to.y - y * trim)
        return Path { path in
            path.move(to: a); path.addLine(to: b)
            path.move(to: CGPoint(x: b.x - x * 5 - y * 3, y: b.y - y * 5 + x * 3)); path.addLine(to: b)
            path.addLine(to: CGPoint(x: b.x - x * 5 + y * 3, y: b.y - y * 5 - x * 3))
        }
    }
}

private struct CozyCoordinate: View {
    let value: String
    private let offsets: [CGSize] = [CGSize(width: -1.3, height: 0), CGSize(width: 1.3, height: 0),
        CGSize(width: 0, height: -1.3), CGSize(width: 0, height: 1.3),
        CGSize(width: -0.9, height: -0.9), CGSize(width: 0.9, height: -0.9),
        CGSize(width: -0.9, height: 0.9), CGSize(width: 0.9, height: 0.9)]
    var body: some View {
        Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(Cozy.coordinate)
            .background {
                ZStack {
                    ForEach(offsets.indices, id: \.self) { i in
                        Text(value).font(.system(size: 10, weight: .bold)).foregroundStyle(Cozy.card)
                            .offset(offsets[i]).accessibilityHidden(true)
                    }
                }
            }
    }
}
