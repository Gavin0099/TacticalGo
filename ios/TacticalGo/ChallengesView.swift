import SwiftUI
import Observation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords

/// This screen never owns a GameStore, a Bot task, or a normal match save.
@MainActor @Observable final class ChallengesStore {
    private(set) var controller: ChallengeController
    var skill = false
    var selected: [Point] = []
    var direction: PushDirection = .down
    var feedback = ""
    var saveError: String?
    let repository: ChallengeRepository
    init() {
        var directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/Challenges", isDirectory: true)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--record-isolation"), args.indices.contains(i + 1), let id = UUID(uuidString: args[i + 1]) {
            directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/TestChallenges/" + id.uuidString, isDirectory: true)
        }
        #endif
        repository = ChallengeRepository(directory: directory)
        do { controller = try repository.load() }
        catch { controller = try! ChallengeController(); saveError = "挑戰進度無法驗證，原檔已保留。重設挑戰進度後才能儲存。" }
    }
    var action: GameAction? {
        guard let scenario = controller.scenario, let first = selected.first else { return nil }
        if !skill { return .placeSoldier(first) }
        switch scenario.heroClass {
        case .warrior: return selected.count == 2 ? .castBastion(first, selected[1]) : nil
        case .mage: return .castMagicHand(first, direction)
        case .rogue: return .castSwap(first)
        case .none: return nil
        }
    }
    var preview: ActionOutcome? { action.flatMap(controller.preview) }
    var legal: Set<Point> {
        guard !controller.locked, let state = controller.session?.state else { return [] }
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
        case .completed: return "挑戰完成：達成局面目標，輸入已鎖定。"
        case .failed(let reason): return "挑戰失敗：" + reason + "。可復原或重試。"
        default: return ""
        }
    }
    var previewText: String {
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
        let count = captured.count
        let commander = captured.contains { $0.piece.kind == .commander }
        return "預覽：\(ap) AP · \(mana) 能量；\(count == 0 ? "不提子" : "提走 \(count) 顆\(commander ? "（含主將）" : "")")"
    }
    func select(_ point: Point) {
        guard !controller.locked else { return }
        if skill && controller.scenario?.heroClass == .warrior {
            if selected.contains(point) { selected.removeAll { $0 == point } }
            else if selected.count < 2 { selected.append(point) }
            else { selected = [point] }
        } else { selected = [point] }
        feedback = ""
    }
    func mode(_ skill: Bool) { clear(); self.skill = skill }
    func clear() { selected = []; feedback = "" }
    func choose(_ id: String) { do { try controller.choose(id); mode(false); persist() } catch { feedback = "無法載入挑戰。" } }
    func confirm() {
        guard let action, preview?.success == true else { return }
        do {
            let outcome = try controller.commit(action)
            if outcome.success { clear(); feedback = "已完成一次合法行動；請思考第二步。"; persist() }
            else { feedback = GameStore.reason(outcome.reason) }
        } catch { feedback = "結果已鎖定；可復原或重試。" }
    }
    func undo() { do { if try controller.undo() { clear(); persist() } } catch { feedback = "無法復原，進度已保留。" } }
    func retry() { do { try controller.retry(); mode(false); persist() } catch { feedback = "無法重試。" } }
    func leave() { controller.leave(); clear(); persist() }
    func pause() { clear(); persist() }
    func hint() { _ = controller.revealHint(); persist() }
    func displayHint(_ text: String) -> String {
        guard let state = controller.session?.state else { return text }
        return state.board.points.reduce(text) { result, p in
            result.replacingOccurrences(of: "(\(p.x),\(p.y))", with: "\(String(UnicodeScalar(65 + p.x)!))\(p.y + 1)")
        }
    }
    func reset() { controller = try! ChallengeController(); clear(); saveError = nil; persist() }
    private func persist() {
        guard saveError == nil else { return }
        do { try repository.save(controller.progress) }
        catch { saveError = "挑戰儲存失敗；正式存局未變動。" }
    }
}

struct ChallengesView: View {
    @State private var model = ChallengesStore()
    @State private var points = false
    @State private var reset = false
    @Environment(\.scenePhase) private var scenePhase
    let close: () -> Void
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        Button(model.controller.scenario == nil ? "退出挑戰" : "返回選關") {
                            if model.controller.scenario == nil { model.pause(); close() } else { model.leave() }
                        }.accessibilityIdentifier("challengeBack")
                        Spacer()
                        Text("\(model.controller.completedIDs.count)／6 已完成").accessibilityIdentifier("challengeProgress")
                    }.font(.system(size: 14)).frame(minHeight: 44)
                    if let scenario = model.controller.scenario, let session = model.controller.session {
                        challenge(scenario, session, geo.size)
                    } else { catalog }
                    if let error = model.saveError {
                        Text(error).font(.caption).foregroundStyle(.orange)
                        Button("重設挑戰進度") { reset = true }
                    }
                }.padding(.horizontal, 12).padding(.bottom, 20).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
        }.background(Color.ink.ignoresSafeArea()).foregroundStyle(.white).preferredColorScheme(.dark)
            .sheet(isPresented: $points) { pointPicker }
            .alert("只重設六關挑戰進度，正式存局與基礎教學不變。", isPresented: $reset) {
                Button("重設挑戰進度", role: .destructive) { model.reset() }
                Button("保留進度", role: .cancel) {}
            }
            .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause(); points = false } }
            .onDisappear { model.pause() }
    }
    private var catalog: some View {
        VStack(spacing: 12) {
            Text("英雄戰術挑戰").font(.title2.bold()).accessibilityIdentifier("challengeCatalog")
            Text("兩次行動戰術題 · 原版技能 · 無電腦回合").font(.caption).foregroundStyle(Color.gold)
            Text("先讀目標、自己選擇；需要時再打開提示。自由對戰中，技能不一定比普通落子更好。")
                .font(.subheadline).multilineTextAlignment(.center)
            ForEach(Array(model.controller.catalog.enumerated()), id: \.element.id) { index, scenario in
                Button { model.choose(scenario.id) } label: {
                    HStack(spacing: 12) {
                        Image(uiImage: GameVisualAssets.original.portrait(scenario.heroClass.art)).resizable().scaledToFit().frame(width: 54, height: 54)
                        VStack(alignment: .leading) {
                            Text("\(index + 1). \(scenario.title)").font(.headline)
                            Text(scenario.heroClass.title + " · 原版 " + scenario.heroClass.skillTitle).font(.caption)
                        }
                        Spacer()
                        Image(systemName: model.controller.completedIDs.contains(scenario.id) ? "checkmark.circle.fill" : "chevron.right")
                    }.frame(minHeight: 64).padding(8)
                }.buttonStyle(.bordered).accessibilityIdentifier("challenge-" + scenario.id)
            }
        }
    }
    private func challenge(_ scenario: TutorialScenario, _ session: TutorialSession, _ size: CGSize) -> some View {
        VStack(spacing: 8) {
            Text(scenario.title).font(.title2.bold()).accessibilityIdentifier("challengeTitle")
            Text(scenario.instructions.joined(separator: "\n").replacingOccurrences(of: "由 Core 判定己方獲勝", with: "獲勝"))
                .font(.system(size: 14)).multilineTextAlignment(.center)
            Text(model.controller.locked
                ? "本關已結束 · 黑方 \(session.state.mana(of: .one)) 能量 · 已用 \(session.playerActionCount)／2 行動"
                : "黑方 · \(session.state.apRemaining) AP · \(session.state.mana(of: .one)) 能量 · 已用 \(session.playerActionCount)／2 行動")
                .font(.system(size: 12)).foregroundStyle(Color.gold).accessibilityIdentifier("challengeResources")
            // Preserve row spacing when rotating. Compressing height alone overlaps dense stones.
            let landscapeWidth = max(200, size.height - 280) / 0.88
            let width = min(size.width - 24, 680, size.width > size.height ? landscapeWidth : 680)
            let height = width * 0.88
            SwiftBoard(presentation: BoardPresentation(state: session.state, selected: model.selected,
                legal: model.legal, preview: model.preview), select: model.select)
                .frame(width: width, height: height).accessibilityElement(children: .ignore)
                .accessibilityLabel("挑戰棋盤，可使用大按鍵選點。").accessibilityIdentifier("challengeArena")
            if model.controller.locked {
                Text(model.resultText).font(.system(size: 15, weight: .bold)).foregroundStyle(model.controller.assessment == .completed ? .mint : .orange)
                    .multilineTextAlignment(.center).accessibilityIdentifier("challengeResult")
                if model.controller.assessment == .completed, let i = model.controller.catalog.firstIndex(where: { $0.id == scenario.id }), i + 1 < model.controller.catalog.count {
                    Button("下一關") { model.choose(model.controller.catalog[i + 1].id) }.accessibilityIdentifier("challengeNext")
                }
            } else {
                HStack {
                    Button("放士兵") { model.mode(false) }.tint(model.skill ? .gray : Color.gold).accessibilityIdentifier("challengeSoldier")
                    Button(scenario.heroClass.skillTitle) { model.mode(true) }.tint(model.skill ? Color.gold : .gray).accessibilityIdentifier("challengeSkill")
                }.buttonStyle(.bordered).frame(minHeight: 44)
                if model.skill && scenario.heroClass == .mage {
                    HStack { ForEach([PushDirection.up, .right, .down, .left], id: \.rawValue) { d in
                        Button(d.title) { model.direction = d }.tint(model.direction == d ? Color.gold : .gray)
                            .accessibilityIdentifier("challengeDirection-" + d.rawValue).frame(minWidth: 44, minHeight: 44)
                    } }.buttonStyle(.bordered)
                }
                Text(model.previewText).font(.system(size: 14)).frame(minHeight: 32).multilineTextAlignment(.center).accessibilityIdentifier("challengeFeedback")
                HStack {
                    Button("取消") { model.clear() }.accessibilityIdentifier("challengeCancel")
                    Button("確認") { model.confirm() }.buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink)
                        .disabled(model.preview?.success != true).accessibilityIdentifier("challengeConfirm")
                    Button("大按鍵選點") { points = true }.accessibilityIdentifier("challengePoints")
                }.font(.system(size: 14)).frame(minHeight: 44)
            }
            HStack {
                Button("復原上一步") { model.undo() }.disabled(session.actions.isEmpty).accessibilityIdentifier("challengeUndo")
                Spacer()
                Button("重試本關") { model.retry() }.accessibilityIdentifier("challengeRetry")
            }.frame(minHeight: 44)
            ForEach(model.controller.visibleHints, id: \.self) { hint in
                Text(model.displayHint(hint).replacingOccurrences(of: "由 Core 判定捕獲主將與勝利", with: "捕獲主將並獲勝"))
                    .font(.system(size: 13)).foregroundStyle(.mint).multilineTextAlignment(.center)
            }
            Button("顯示一則提示") { model.hint() }.disabled(model.controller.visibleHints.count == scenario.optionalHints.count)
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
