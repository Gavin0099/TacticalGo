import SwiftUI
import Observation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

/// Dedicated journals only. Immutable controller copies are committed off the main actor;
/// a generation guard prevents an old reply from publishing after undo, exit or background.
@MainActor @Observable final class ChallengesStore {
    private(set) var controller: ChallengeController
    private(set) var busy = false
    private(set) var playback: BoardPlayback?
    var skill = false
    var selected: [Point] = []
    var direction: PushDirection = .down
    var feedback = ""
    var saveError: String?
    private(set) var observation = PlaytestObservation()
    private var now: Double { ProcessInfo.processInfo.systemUptime }
    var observationReport: String { (try? observation.report()) ?? "[]" }
    private func observeOutcome() {
        if controller.locked, let assessment = controller.assessment {
            observation.finish(assessment.label, at: now)
        }
    }
    let repository: ChallengeRepository
    private var work: Task<Void, Never>?
    private var generation = 0
    private var active = true
    init(campaign: ChallengeCampaign = .introduction) {
        var directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/Challenges", isDirectory: true)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--record-isolation"), args.indices.contains(i + 1), let id = UUID(uuidString: args[i + 1]) {
            directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/TestChallenges/" + id.uuidString, isDirectory: true)
        }
        #endif
        repository = ChallengeRepository(directory: directory, campaign: campaign)
        do { controller = try repository.load() }
        catch { controller = try! ChallengeController(campaign: campaign); saveError = "挑戰進度無法驗證，原檔已保留。重設本章進度後才能儲存。" }
        if let id = controller.scenario?.id {
            observation.begin(id, at: now)
            observation.record("restored-run", at: now)
            observeOutcome()
        }
    }
    var humanCanAct: Bool { active && !busy && !controller.locked && controller.session?.state.current == .one }
    var action: GameAction? {
        guard humanCanAct, let scenario = controller.scenario, let first = selected.first else { return nil }
        if !skill { return .placeSoldier(first) }
        switch scenario.heroClass {
        case .warrior: return selected.count == 2 ? .castBastion(first, selected[1]) : nil
        case .mage: return .castMagicHand(first, direction)
        case .rogue: return .castSwap(first)
        // The 1.0 challenge campaigns only use the three original classes; the priest's skill belongs to the
        // expansion shell and has no action in this screen.
        case .priest, .none: return nil
        }
    }
    var preview: ActionOutcome? { action.flatMap(controller.preview) }
    var legal: Set<Point> {
        guard humanCanAct, let state = controller.session?.state else { return [] }
        return Set(GameEngine.legalActions(state).flatMap { action -> [Point] in
            switch action {
            case .placeSoldier(let p) where !skill: return [p]
            case .castBastion(let a, let b) where skill:
                if let first = selected.first { return a == first ? [b] : b == first ? [a] : [] }
                return [a,b]
            case .castMagicHand(let p, _) where skill: return [p]
            case .castSwap(let p) where skill: return [p]
            default: return []
            }
        })
    }
    var resultText: String {
        switch controller.assessment {
        case .completed: return "挑戰完成：達成局面目標。"
        case .failed(let reason): return "挑戰失敗：" + reason + " 可復原或重試。"
        default: return ""
        }
    }
    var previewText: String {
        if busy { return controller.session?.state.current == .two ? "白方正在反擊；看完回應，再決定下一步。" : "呈現行動結果…" }
        guard let preview else { return feedback.isEmpty ? (skill && controller.scenario?.heroClass == .warrior ? "選兩個不同的合法空點，再確認築壘。" : "選目標並預覽，再確認；預覽不扣資源。") : feedback }
        guard preview.success else { return GameStore.reason(preview.reason) }
        var ap = 0, mana = 0, captured: [CapturedPiece] = []
        for event in preview.events {
            switch event {
            case .resourcesSpent(_, let a, let m): ap += a; mana += m
            case .piecesCaptured(_, let pieces): captured += pieces
            default: break
            }
        }
        let commander = captured.contains { $0.piece.kind == .commander }
        return "預覽：\(ap) AP · \(mana) 能量；\(captured.isEmpty ? "不提子" : "提走 \(captured.count) 顆\(commander ? "（含主將）" : "")")"
    }
    func select(_ point: Point) {
        guard humanCanAct else { return }
        if skill && controller.scenario?.heroClass == .warrior {
            if selected.contains(point) { selected.removeAll { $0 == point } }
            else if selected.count < 2 { selected.append(point) }
            else { selected = [point] }
        } else { selected = [point] }
        feedback = ""
    }
    func mode(_ skill: Bool) { guard humanCanAct else { return }; clear(); self.skill = skill }
    func clear() { selected = []; feedback = "" }
    private func stop() { generation += 1; work?.cancel(); work = nil; busy = false; playback = nil; clear() }
    func choose(_ id: String, reduced: Bool) {
        stop()
        do { try controller.choose(id); observation.begin(id, at: now); skill = false; persist(); resume(reduced: reduced) }
        catch { feedback = "無法載入挑戰。" }
    }
    func confirm(reduced: Bool) { guard let action, preview?.success == true else { return }; submit(action, reduced: reduced) }
    func endTurn(reduced: Bool) { guard humanCanAct else { return }; submit(.endTurn, reduced: reduced) }
    private func submit(_ action: GameAction, reduced: Bool) {
        guard humanCanAct, let before = controller.session?.state else { return }
        let base = controller, token = generation
        busy = true; clear()
        work = Task { @MainActor in
            let result = await Task.detached(priority: .userInitiated) { () -> (ChallengeController, ActionOutcome)? in
                var next = base
                guard let outcome = try? next.commit(action) else { return nil }
                return (next, outcome)
            }.value
            guard !Task.isCancelled, active, generation == token else { return }
            guard let (next, outcome) = result else { busy = false; feedback = "進度無法驗證；可復原或重試。"; return }
            guard outcome.success else { busy = false; feedback = GameStore.reason(outcome.reason); return }
            controller = next; observation.record("action", at: now, detail: RecordedAction(action).label); observeOutcome(); persist()
            playback = reduced || action == .endTurn ? nil : BoardPlayback(before: before, action: action, outcome: outcome)
            if let playback {
                traceSuccessfulPlayback(playback, reduced: reduced)
                do { try await Task.sleep(for: .seconds(playback.visualDuration + 0.08)) } catch { return }
            }
            guard !Task.isCancelled, active, generation == token else { return }
            playback = nil; busy = false; work = nil
            feedback = controller.session?.state.current == .one ? "行動已完成；選擇下一步。" : "白方回應中。"
            resume(reduced: reduced)
        }
    }
    func resume(reduced: Bool = false) {
        active = true
        observation.resume(at: now)
        guard !busy, controller.opponentAction != nil else { return }
        let token = generation
        busy = true
        work = Task { @MainActor in
            while let action = controller.opponentAction {
                do { try await Task.sleep(for: .milliseconds(reduced ? 160 : 350)) } catch { return }
                guard !Task.isCancelled, active, generation == token, let before = controller.session?.state else { return }
                do {
                    let outcome = try controller.commit(action)
                    guard outcome.success else { feedback = "對手行動驗證失敗；可復原或重試。"; break }
                    observeOutcome(); persist()
                    playback = reduced || action == .endTurn ? nil : BoardPlayback(before: before, action: action, outcome: outcome)
                    if let playback {
                        traceSuccessfulPlayback(playback, reduced: reduced)
                        try await Task.sleep(for: .seconds(playback.visualDuration + 0.12))
                    }
                    guard !Task.isCancelled, active, generation == token else { return }
                    playback = nil
                } catch { if !Task.isCancelled { feedback = "反擊已中止；進度保留。" }; break }
            }
            guard active, generation == token else { return }
            busy = false; work = nil; playback = nil
            if !controller.locked { feedback = "輪到黑方。根據剛才的反擊，重新決定計畫。" }
        }
    }
    func undo(reduced: Bool) { stop(); do { if try controller.undo() { observation.undo(at: now); persist(); resume(reduced: reduced) } } catch { feedback = "無法復原，進度已保留。" } }
    func retry() { stop(); do { try controller.retry(); if let id = controller.scenario?.id { observation.begin(id, at: now, retry: true) }; skill = false; persist() } catch { feedback = "無法重試。" } }
    func leave() { observation.leave(at: now, reason: "back-to-catalog"); stop(); controller.leave(); persist() }
    func pause() { observation.pause(at: now); active = false; stop(); persist() }
    func hint() {
        // A human commit publishes an immutable controller copy. Do not mutate
        // hint progress while that copy or an opponent reply is in flight.
        guard !busy else { return }
        if controller.revealHint() { observation.record("hint", at: now) }; persist()
    }
    func displayHint(_ text: String) -> String {
        guard let state = controller.session?.state else { return text }
        return state.board.points.reduce(text) { result, p in
            result.replacingOccurrences(of: "(\(p.x),\(p.y))", with: "\(String(UnicodeScalar(65 + p.x)!))\(p.y + 1)")
        }
    }
    func reset() { stop(); controller = try! ChallengeController(campaign: repository.campaign); saveError = nil; persist() }
    private func persist() {
        guard saveError == nil else { return }
        do { try repository.save(controller.progress) }
        catch { saveError = "挑戰儲存失敗；正式存局未變動。" }
    }
    private func traceSuccessfulPlayback(_ receipt: BoardPlayback, reduced: Bool) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--challenge-trace") {
            // Record the instance actually presented by this store, after a
            // successful controller commit. The audit never calls Core.apply.
            GameFeelReceiptAudit.record(receipt, reduced: reduced)
        }
        #endif
    }
}

struct ChallengesView: View {
    @State private var model: ChallengesStore
    private let assets = try? CozyAssets.load()
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    init(campaign: ChallengeCampaign = .introduction, close: @escaping () -> Void) {
        _model = State(initialValue: ChallengesStore(campaign: campaign)); self.close = close
    }
    @State private var points = false
    @State private var reset = false
    @Environment(\.scenePhase) private var scenePhase
    let close: () -> Void
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Button {
                            if model.controller.scenario == nil { model.pause(); close() } else { model.leave() }
                        } label: { Text(model.controller.scenario == nil ? "退出挑戰" : "返回選關").frame(minHeight: 44) }.accessibilityIdentifier("challengeBack")
                        Spacer()
                        Text("\(model.controller.completedIDs.count)／\(model.controller.catalog.count) 已完成").accessibilityIdentifier("challengeProgress")
                    }.font(.system(size: 14)).frame(minHeight: 44)
                    if let scenario = model.controller.scenario, let session = model.controller.session {
                        challenge(scenario, session, geo.size)
                    } else { catalog }
                    if model.controller.campaign == .expedition {
                        ShareLink("匯出本次試玩觀察", item: model.observationReport)
                            .accessibilityIdentifier("challengeExportObservation")
                        Text("僅本次開啟的紀錄，最多 500 筆；背景時間不計入。離開章節後清除，不會自動上傳。")
                            .font(.caption2)
                    }
                    if let error = model.saveError {
                        Text(error).font(.caption).foregroundStyle(.orange)
                        Button("重設挑戰進度") { reset = true }
                    }
                }.padding(.horizontal, 12).padding(.bottom, 20).frame(maxWidth: geo.size.width > geo.size.height ? 1080 : 720).frame(maxWidth: .infinity)
            }
        }.background { SellTabletop() }.foregroundStyle(SellTheme.paper).preferredColorScheme(.dark)
            .sheet(isPresented: $points) { pointPicker }
            .alert("只重設本章挑戰進度，其他挑戰、正式存局與基礎教學不變。", isPresented: $reset) {
                Button("重設挑戰進度", role: .destructive) { model.reset() }
                Button("保留進度", role: .cancel) {}
            }
            .onAppear { model.resume(reduced: reducedMotion) }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { model.resume(reduced: reducedMotion) } else { model.pause(); points = false }
            }
            .onChange(of: reducedMotion) { _, _ in model.pause(); model.resume(reduced: reducedMotion) }
            .onDisappear { model.pause() }
    }
    private var catalog: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                chapterButton(.introduction, title: "技能入門 · 六關", id: "introduction")
                chapterButton(.advanced, title: "邊境攻防 · 三關", id: "advanced")
            }
            HStack {
                chapterButton(.expedition, title: "戰術遠征 · 短篇攻防", id: "expedition")
            }
            Text(model.controller.campaign == .expedition ? "戰術遠征 · 試玩版" : model.controller.campaign == .advanced ? "邊境攻防" : "英雄技能入門").font(.title2.bold()).accessibilityIdentifier("challengeCatalog")
            Text(model.controller.campaign == .expedition ? "最後反擊後結算 · 每場獨立 · 原版技能" : model.controller.campaign == .advanced ? "兩個回合 · 原版技能 · 對手會反擊" : "兩次行動練習 · 原版技能 · 無電腦回合").font(.caption).foregroundStyle(Color.gold)
            Text("先讀目標、自己選擇；需要時再打開提示。自由對戰中，技能不一定比普通落子更好。")
                .font(.subheadline).multilineTextAlignment(.center)
            ForEach(Array(model.controller.catalog.enumerated()), id: \.element.id) { index, scenario in
                Button { model.choose(scenario.id, reduced: reducedMotion) } label: {
                    HStack(spacing: 12) {
                        Image(uiImage: GameVisualAssets.original.portrait(scenario.heroClass.art)).resizable().scaledToFit().frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text("\(index + 1). \(scenario.title)").font(.headline)
                            Text(scenario.heroClass.title + " · 原版 " + scenario.heroClass.skillTitle).font(.caption)
                        }
                        Spacer()
                        Image(systemName: model.controller.completedIDs.contains(scenario.id) ? "checkmark.circle.fill" : "chevron.right")
                    }.frame(minHeight: 64).padding(8)
                }.buttonStyle(SellButton()).accessibilityIdentifier("challenge-" + scenario.id)
            }
        }
    }
    private func chapterButton(_ campaign: ChallengeCampaign, title: String, id: String) -> some View {
        Button {
            guard model.controller.campaign != campaign else { return }
            model.pause()
            // Each chapter loads its existing, separately validated repository.
            // Switching never resets either progress file or the saved match.
            model = ChallengesStore(campaign: campaign)
            model.resume(reduced: reducedMotion)
        } label: {
            Text(title).font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
        }.buttonStyle(SellButton(selected: model.controller.campaign == campaign))
            .accessibilityIdentifier("challengeChapter-" + id)
            .accessibilityAddTraits(model.controller.campaign == campaign ? [.isSelected] : [])
    }
    private func challenge(_ scenario: TutorialScenario, _ session: TutorialSession, _ size: CGSize) -> some View {
        VStack(spacing: 8) {
            Text(scenario.title).font(.title2.bold()).accessibilityIdentifier("challengeTitle")
            Text(scenario.instructions.joined(separator: "\n").replacingOccurrences(of: "由 Core 判定己方獲勝", with: "獲勝"))
                .font(.system(size: 14)).multilineTextAlignment(.center)
            Text("\(session.state.current == .one ? "黑方" : "白方") · \(session.state.apRemaining) AP · \(session.state.mana(of: session.state.current)) 能量 · 你已用 \(session.playerActionCount) 次行動")
                .font(.system(size: 12)).foregroundStyle(Color.gold).accessibilityIdentifier("challengeResources")
            if size.width > size.height && size.width >= 700 {
                // Keep the board and controls together on the actual landscape viewport.
                // This only changes presentation; both variants share the same projection.
                HStack(alignment: .top, spacing: 20) {
                    challengeBoard(session, width: min(max(200, size.height - 210) / 1.125, (size.width - 48) * 0.56))
                    challengeControls(scenario, session).frame(maxWidth: 360)
                }.frame(maxWidth: .infinity)
            } else {
                challengeBoard(session, width: min(size.width - 24, 680))
                challengeControls(scenario, session)
            }
        }
    }
    private func challengeBoard(_ session: TutorialSession, width: CGFloat) -> some View {
        let height = width * 1.125
        let presentation = BoardPresentation(state: session.state, selected: model.selected, legal: model.legal, preview: model.preview)
        return Group {
                if let assets {
                    CozyBoard(presentation: presentation, assets: assets, playback: model.playback, botPlayback: nil,
                        botStartedAt: nil, animating: model.playback != nil, reducedMotion: reducedMotion, checkpoint: nil,
                        commercialStyle: true, select: model.select)
                } else { Text("棋盤素材驗證失敗，請重新安裝候選。").foregroundStyle(.orange) }
            }.frame(width: width, height: height).accessibilityElement(children: .ignore)
                .accessibilityLabel("挑戰棋盤，可使用大按鍵選點。")
                .accessibilityValue(model.selected.isEmpty ? "未選取" : "已選 " + model.selected.map {
                    "\(String(UnicodeScalar(65 + $0.x)!))\($0.y + 1)"
                }.joined(separator: "、"))
                .accessibilityIdentifier("challengeArena")
    }
    private func challengeControls(_ scenario: TutorialScenario, _ session: TutorialSession) -> some View {
        VStack(spacing: 8) {
            if model.controller.locked {
                if let review = try? ChallengeReview(session: session) {
                    Text(review.summary).font(.caption).accessibilityIdentifier("challengeReviewSummary")
                    DisclosureGroup("回顧本次攻防") {
                        ForEach(Array(review.timeline.enumerated()), id: \.offset) { _, line in
                            Text(line).font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }.accessibilityIdentifier("challengeReviewTimeline")
                }
                Text(model.resultText).font(.system(size: 15, weight: .bold)).foregroundStyle(model.controller.assessment == .completed ? .mint : .orange)
                    .multilineTextAlignment(.center).accessibilityIdentifier("challengeResult")
                if model.controller.assessment == .completed, let i = model.controller.catalog.firstIndex(where: { $0.id == scenario.id }), i + 1 < model.controller.catalog.count {
                    Button("下一關") { model.choose(model.controller.catalog[i + 1].id, reduced: reducedMotion) }.accessibilityIdentifier("challengeNext")
                }
            } else {
                HStack {
                    Button { model.mode(false) } label: { Text("放士兵").frame(minWidth: 88, minHeight: 44) }.tint(model.skill ? .gray : Color.gold).disabled(!model.humanCanAct).accessibilityIdentifier("challengeSoldier")
                    Button { model.mode(true) } label: { Text(scenario.heroClass.skillTitle).frame(minWidth: 88, minHeight: 44) }.tint(model.skill ? Color.gold : .gray).disabled(!model.humanCanAct).accessibilityIdentifier("challengeSkill")
                }.buttonStyle(.bordered).frame(minHeight: 44)
                if model.skill && scenario.heroClass == .mage {
                    HStack { ForEach([PushDirection.up, .right, .down, .left], id: \.rawValue) { d in
                        Button { model.direction = d } label: { Text(d.title).frame(minWidth: 44, minHeight: 44) }.tint(model.direction == d ? Color.gold : .gray)
                            .accessibilityIdentifier("challengeDirection-" + d.rawValue).frame(minWidth: 44, minHeight: 44)
                    } }.buttonStyle(.bordered)
                }
                Text(model.previewText).font(.system(size: 14)).frame(minHeight: 32).multilineTextAlignment(.center).accessibilityIdentifier("challengeFeedback")
                HStack {
                    Button { model.clear() } label: { Text("取消").frame(minWidth: 44, minHeight: 44) }.accessibilityIdentifier("challengeCancel")
                    Button { model.confirm(reduced: reducedMotion) } label: { Text("確認").frame(minWidth: 72, minHeight: 44) }.buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink)
                        .disabled(!model.humanCanAct || model.preview?.success != true).accessibilityIdentifier("challengeConfirm")
                    Button { points = true } label: { Text("大按鍵選點").frame(minHeight: 44) }.accessibilityIdentifier("challengePoints")
                }.font(.system(size: 14)).frame(minHeight: 44)
            }
            if model.controller.campaign != .introduction && !model.controller.locked {
                Button { model.endTurn(reduced: reducedMotion) } label: { Text("結束回合，讓白方回應").frame(minHeight: 44) }
                    .disabled(!model.humanCanAct).frame(minHeight: 44).accessibilityIdentifier("challengeEndTurn")
            }
            HStack {
                Button { model.undo(reduced: reducedMotion) } label: { Text("復原上一步").frame(minHeight: 44) }.disabled(session.actions.isEmpty).accessibilityIdentifier("challengeUndo")
                Spacer()
                Button { model.retry() } label: { Text(model.controller.locked ? "換個計畫再試一次" : "重試本關").frame(minHeight: 44) }.accessibilityIdentifier("challengeRetry")
            }.frame(minHeight: 44)
            ForEach(model.controller.visibleHints, id: \.self) { hint in
                Text(model.displayHint(hint).replacingOccurrences(of: "由 Core 判定捕獲主將與勝利", with: "捕獲主將並獲勝"))
                    .font(.system(size: 13)).foregroundStyle(.mint).multilineTextAlignment(.center)
            }
            Button { model.hint() } label: { Text("顯示一則提示").frame(minHeight: 44) }.disabled(model.busy || model.controller.visibleHints.count == scenario.optionalHints.count)
                .frame(minHeight: 44).accessibilityIdentifier("challengeHint")
        }
    }
    private var pointPicker: some View {
        NavigationStack {
            ScrollView {
                if let state = model.controller.session?.state {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
                        ForEach(state.board.points, id: \.self) { p in
                            Button { model.select(p); points = false } label: {
                                VStack {
                                    Text("\(String(UnicodeScalar(65 + p.x)!))\(p.y + 1)")
                                    Text(state.board[p].map { "\($0.owner == .one ? "黑" : "白")\($0.kind == .hero ? "英雄" : $0.kind == .commander ? "主將" : "兵")" } ?? "空點").font(.system(size: 10))
                                }.frame(maxWidth: .infinity, minHeight: 48)
                            }.buttonStyle(.bordered).accessibilityIdentifier("challengePoint-\(p.x)-\(p.y)")
                        }
                    }.padding(12)
                }
            }.navigationTitle("交叉點大按鍵").toolbar { ToolbarItem(placement: .confirmationAction) { Button("取消") { points = false } } }
        }
    }
}
