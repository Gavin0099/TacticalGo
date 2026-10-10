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
    var effectsEnabled = true
    var mageRevision: MageArtRevision = .m3
    var markerStyle: HeroMarkerStyle = .thinRing
    let select: (Point) -> Void
    private var receipt: BoardPlayback? {
        guard let playback, playback.outcome.success, playback.outcome.state == presentation.state else { return nil }
        switch playback.action {
        case .summonHero, .placeSoldier, .castBastion, .castSwap: return playback
        default: return Anim01MagicHand.make(before: playback.before, action: playback.action, outcome: playback.outcome) != nil ? playback : nil
        }
    }
    var body: some View {
        GeometryReader { geometry in
            let fit = Anim01Geometry(width: geometry.size.width, height: geometry.size.height, boardSize: presentation.state.board.size)
            TimelineView(.animation(minimumInterval: 1 / 60, paused: !animating || (receipt == nil && botPlayback == nil) || checkpoint != nil || reducedMotion)) { context in
                let elapsed = checkpoint ?? (receipt.map { item in
                    let duration = item.visualDuration
                    return animating && !reducedMotion ? max(0, context.date.timeIntervalSince(item.startedAt)) : duration
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
            "heroRepresentation": "B-v02 original head/hand/staff pixels + masked garment clean plate; articulated mage",
            "effectsEnabled": effectsEnabled, "mageRevision":mageRevision.rawValue, "markerStyle":markerStyle == .legacy ? "legacy" : "thinRing",
            "mageCanvas":fit.pitch * (mageRevision == .m2 ? 0.70 : 0.92), "mageGroundSource":mageRevision == .m2 ? 420 : 448, "reducedMotion": reducedMotion, "checkpointMs": checkpoint.map { $0 * 1000 } ?? -1]
        if let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
           let data = try? JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys]) {
            try? data.write(to: directory.appendingPathComponent("cozy-render-geometry.json"), options: .atomic)
        }
        #endif
    }
    private func point(_ p: Point, size: CGSize) -> CGPoint { presentation.center(p, size) }
    @ViewBuilder private func layers(size: CGSize, pitch: CGFloat, receipt: BoardPlayback?, elapsed: Double, now: Date) -> some View {
        let clip = receipt?.magicHand
        let timing = receipt?.mageTempo.timing ?? MageTempo.full.timing
        let summonPoint = receipt?.mageSummon
        let heroPerformance = receipt?.heroPerformance
        let mageSummoning = summonPoint != nil && elapsed < timing.summonEnd && !reducedMotion
        let generic: BotBoardFrame = {
            if let receipt, clip == nil { return BotBoardFrame.committed(receipt, elapsed: elapsed, pitch: Double(pitch), reducedMotion: reducedMotion) }
            return receipt == nil ? BotBoardFrame.make(botPlayback, startedAt: botStartedAt, now: now, reducedMotion: reducedMotion) : BotBoardFrame()
        }()
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
                let captureOpacity = elapsed < timing.captureStart ? 1.0 : max(0, 1 - (elapsed - timing.captureStart) / (timing.captureEnd - timing.captureStart))
                ZStack {
                    if presentation.legal.contains(p) { Circle().fill(Color.white.opacity(0.40)).frame(width: pitch * 0.15) }
                    if !hideMovedSource, !(mageSummoning && p == summonPoint), !generic.hidden.contains(p), let piece = displayed[p] {
                        token(piece, pitch: pitch, magePose: showingAnimation && p == clip?.hero ? MageBodyPose.cast(at: elapsed, timing: timing, revision: mageRevision) : .rest,
                              heroPose: p == heroPerformance?.hero ? bodyPose(piece,receipt:receipt,elapsed:elapsed) : .rest).opacity(showingAnimation && captured != nil ? captureOpacity : 1)
                    }
                }.position(point(p, size: size)).zIndex(Double(p.y) * 10 + 10)
            }
            ForEach(generic.sprites.filter { !(summonPoint != nil && $0.piece.kind == .hero && $0.to == summonPoint && $0.piece.owner == receipt?.before.current) }) { sprite in
                let a = point(sprite.from, size: size), b = point(sprite.to, size: size)
                let bodySummon = heroPerformance?.isSummon == true && sprite.piece.kind == .hero && sprite.piece.owner == receipt?.before.current
                token(sprite.piece, pitch: pitch,heroPose:bodyPose(sprite.piece,receipt:receipt,elapsed:elapsed))
                    .scaleEffect(bodySummon ? 1 : sprite.scale).opacity(sprite.opacity)
                    .position(x: a.x + (b.x - a.x) * sprite.progress + sprite.lateral,
                              y: a.y + (b.y - a.y) * sprite.progress + (bodySummon ? 0 : sprite.lift))
                    .zIndex(180 + Double(sprite.to.y))
            }
            if mageSummoning, let summonPoint, let piece = presentation.state.board[summonPoint] {
                token(piece, pitch: pitch, magePose: MageBodyPose.summon(at: elapsed, timing: timing, revision: mageRevision))
                    .position(point(summonPoint,size: size)).zIndex(Double(summonPoint.y)*10+10)
            }
            if let receipt, case .summonHero = receipt.action, !reducedMotion, effectsEnabled {
                let plan = receipt.plan
                if elapsed < (receipt.mageSummon != nil ? timing.summonEnd : plan.duration) {
                    ForEach(plan.cues.indices, id: \.self) { i in
                        if case .drop(.hero) = plan.cues[i].kind, let at = plan.cues[i].points.first {
                            let t = min(1, max(0, elapsed / (receipt.mageSummon != nil ? timing.summonEnd : 0.46)))
                            Circle().stroke(Cozy.gold.opacity(1 - t), lineWidth: 2)
                                .frame(width: pitch * 0.82, height: pitch * 0.82)
                                .scaleEffect(0.6 + 0.4 * t).position(point(at, size: size)).zIndex(185)
                            Circle().stroke(Cozy.card.opacity(1 - t), style: StrokeStyle(lineWidth: 1, dash: [3,2]))
                                .frame(width: pitch * 0.63, height: pitch * 0.63)
                                .rotationEffect(.degrees(t * 50)).position(point(at, size: size)).zIndex(185)
                        }
                    }
                }
            }
            if let receipt, !reducedMotion, effectsEnabled {
                let plan = receipt.plan
                ForEach(plan.cues.indices, id: \.self) { i in
                    let cue = plan.cues[i]
                    let t = min(1, max(0, (elapsed - cue.start) / cue.duration))
                    if elapsed >= cue.start, elapsed < cue.start + cue.duration {
                        if case .bastion = cue.kind, let hero = cue.points.first {
                            Image(systemName: "shield.fill").font(.system(size: pitch * 0.33, weight: .bold))
                                .foregroundStyle(Cozy.gold.opacity(1 - t)).offset(y: -pitch * 0.14 * t)
                                .position(point(hero, size: size)).zIndex(190)
                        }
                        if case .swap = cue.kind {
                            ForEach(cue.points, id: \.self) { p in
                                Circle().stroke(Cozy.deepMage.opacity(1-t), style: StrokeStyle(lineWidth: 2,dash: [3,3]))
                                    .frame(width: pitch * 0.76, height: pitch * 0.76).position(point(p,size: size)).zIndex(185)
                            }
                        }
                        if case .capture(let piece) = cue.kind, piece.kind == .commander {
                            ForEach(cue.points, id: \.self) { p in
                                Circle().stroke(Color(red: 0.81, green: 0.40, blue: 0.35).opacity(1-t),lineWidth: 2.5)
                                    .frame(width: pitch * 0.82,height: pitch * 0.82).position(point(p,size: size)).zIndex(191)
                            }
                        }
                    }
                }
            }
            if let clip, showingAnimation {
                let a = point(clip.from, size: size), b = point(clip.to, size: size)
                let position = CGPoint(x: a.x + (b.x - a.x) * progress, y: a.y + (b.y - a.y) * progress)
                let squash = elapsed >= timing.arrival && elapsed < timing.captureStart ? 0.94 + 0.06 * (elapsed - timing.arrival) / (timing.captureStart - timing.arrival) : 1
                token(clip.piece, pitch: pitch, squash: squash).position(position).zIndex(Double(clip.from.y) * 10 + Double(clip.to.y - clip.from.y) * 10 * progress + 11)
                if effectsEnabled, mageRevision == .m3, elapsed >= timing.release, elapsed < timing.arrival {
                    let hero = point(clip.hero,size:size)
                    let pose = MageBodyPose.cast(at:elapsed,timing:timing)
                    let tip = MageBodyView.tipOffset(pose:pose,width:pitch * 0.92)
                    let opacity = sin(.pi * min(1,max(0,(elapsed-timing.release)/(timing.arrival-timing.release))))
                    Circle().fill(Cozy.card.opacity(opacity)).frame(width:3,height:3)
                        .position(x:hero.x+tip.x,y:hero.y+tip.y).zIndex(190)
                    // Short directional cue occupies the gap, not faces or source/target bodies.
                    let dx = a.x-hero.x, dy = a.y-hero.y, distance = max(1,hypot(dx,dy))
                    let unit = CGPoint(x:dx/distance,y:dy/distance)
                    let start = CGPoint(x:hero.x+unit.x*pitch*0.50,y:hero.y+unit.y*pitch*0.50)
                    let end = CGPoint(x:hero.x+unit.x*pitch*0.62,y:hero.y+unit.y*pitch*0.62)
                    Path { p in
                        p.move(to:start);p.addLine(to:end)
                        p.move(to:CGPoint(x:end.x-unit.x*3-unit.y*2,y:end.y-unit.y*3+unit.x*2));p.addLine(to:end)
                        p.addLine(to:CGPoint(x:end.x-unit.x*3+unit.y*2,y:end.y-unit.y*3-unit.x*2))
                    }.stroke(Cozy.deepMage.opacity(opacity),style:StrokeStyle(lineWidth:1.3,lineCap:.round)).zIndex(190)
                }
                if effectsEnabled, mageRevision == .m2, elapsed < timing.moveStart { effect("cast", progress: elapsed / timing.moveStart, pitch: pitch).position(point(clip.hero, size: size)).zIndex(190) }
                else if effectsEnabled, elapsed >= timing.moveStart, elapsed < timing.arrival { effect("push", progress: (elapsed - timing.moveStart) / (timing.arrival - timing.moveStart), pitch: pitch).position(position).zIndex(190) }
                else if effectsEnabled, elapsed < timing.captureStart { effect("landing", progress: (elapsed - timing.arrival) / (timing.captureStart - timing.arrival), pitch: pitch).position(b).zIndex(190) }
                if effectsEnabled, elapsed >= timing.captureStart {
                    ForEach(clip.captures, id: \.at) { captured in
                        effect("capture", progress: (elapsed - timing.captureStart) / (timing.captureEnd - timing.captureStart), pitch: pitch).position(point(captured.at, size: size)).zIndex(190)
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
            let beforeLanding = !reducedMotion && receipt != nil && elapsed < (heroPerformance?.timing.arrival ?? timing.arrival)
            let informationBoard = (showingAnimation || heroPerformance != nil) && beforeLanding ? receipt!.before.board : presentation.state.board
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
    @ViewBuilder private func effect(_ key: String, progress: Double, pitch: CGFloat) -> some View {
        if let image = assets.anim.fx(key, progress: progress), let clip = assets.anim.manifest.fx[key] {
            let width = pitch * clip.widthInLocalD
            Image(uiImage: image).resizable().frame(width: width, height: width)
                .offset(x: (0.5 - clip.anchorX) * width, y: (0.5 - clip.anchorY) * width)
        }
    }
    private func bodyPose(_ piece: Piece,receipt: BoardPlayback?,elapsed: Double) -> HeroBodyPose {
        guard !reducedMotion,let receipt,let p = receipt.heroPerformance,piece.kind == .hero,piece.owner == receipt.before.current,elapsed < receipt.visualDuration else { return .rest }
        if p.isSummon { return HeroBodyPose.summon(p.heroClass,at:elapsed) }
        let target = p.plan.cues.first { if case .swap = $0.kind { return true }; return false }?.points.last
        let direction = target.map { $0.x < p.hero.x ? -1.0 : 1.0 } ?? 1
        return HeroBodyPose.skill(p.heroClass,at:elapsed,direction:direction)
    }
    private func token(_ piece: Piece, pitch: CGFloat, squash: Double = 1, magePose: MageBodyPose = .rest,heroPose: HeroBodyPose = .rest) -> some View {
        CozyToken(piece: piece, assets: assets, pitch: pitch, squash: squash, magePose: magePose, heroPose:heroPose,markers: markerStyle, heroClass: presentation.state.heroClass(of: piece.owner))
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
