import SwiftUI
import Observation
import TacticalGoCore
import TacticalGoOnboarding

@MainActor @Observable final class OnboardingStore {
    private(set) var session: OnboardingSession
    var selected: Point?
    var inspecting: Point?
    var feedback = ""
    var saveError: String?
    let repository: OnboardingRepository
    init() {
        var directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/Onboarding", isDirectory: true)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--record-isolation"), args.indices.contains(i + 1), let id = UUID(uuidString: args[i + 1]) {
            directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/TestOnboarding/" + id.uuidString, isDirectory: true)
        }
        #endif
        repository = OnboardingRepository(directory: directory)
        do { session = try repository.load() }
        catch {
            session = try! OnboardingSession()
            saveError = "教學進度無法驗證，原檔已保留。請選「重新開始」才會覆寫教學進度。"
        }
    }
    var state: GameState { session.state }
    var preview: ActionOutcome? { selected.flatMap { session.preview($0) } }
    var inspection: GroupInspection? { inspecting.flatMap { GroupInspection.read(state, at: $0) } }
    var canConfirm: Bool {
        preview?.success == true && state.current == .one && !session.completed &&
        (session.lesson?.id != "breathing" || session.progress.observed[session.progress.lessonIndex] != nil)
    }
    var warning: String? {
        guard state.status == .ongoing else { return nil }
        let threatened = Player.allCases.compactMap { owner -> String? in
            guard let p = state.board.find(owner, .commander), state.board.liberties(at: p).count == 1 else { return nil }
            return "\(owner == .one ? "黑" : "白")方主將只剩 1 氣：最後空點被封住就會被提。"
        }
        return threatened.isEmpty ? nil : threatened.joined(separator: "\n")
    }
    var previewText: String {
        guard let preview else { return feedback.isEmpty ? "先選位置；預覽不扣資源。" : feedback }
        guard preview.success else { return GameStore.reason(preview.reason) }
        var ap = 0, mana = 0, captures: [CapturedPiece] = []
        for event in preview.events {
            switch event {
            case .resourcesSpent(_, let a, let m): ap += a; mana += m
            case .piecesCaptured(_, let pieces): captures += pieces
            default: break
            }
        }
        var text = "預覽：\(ap) AP · \(mana) 能量"
        if !captures.isEmpty {
            let owner = captures[0].piece.owner == .one ? "黑" : "白"
            text += "；將提\(owner)方 \(captures.count) 顆"
            if captures.contains(where: { $0.piece.kind == .commander }) { text += "（主將）" }
        } else { text += "；不提子" }
        if preview.state.status == .won { text += "，\(preview.state.winner == .one ? "黑" : "白")方獲勝" }
        return text
    }
    func select(_ point: Point) {
        guard !session.finished, !session.completed, state.board.contains(point) else { return }
        if state.board[point] != nil {
            inspecting = point; selected = nil; session.observe(point); persist()
            feedback = "已顯示這串棋的气。點空的交叉點可預覽落子。"
        } else { selected = point; feedback = "" }
    }
    func confirm() {
        guard let selected, canConfirm else { return }
        do {
            let result = try session.commit(selected)
            guard result.success else { feedback = GameStore.reason(result.reason); return }
            self.selected = nil
            if session.completed { feedback = session.lesson!.explanation }
            else { feedback = "已合法落子；看看棋群的氣。也可復原再試。" }
            persist()
        } catch { feedback = "先觀察棋群；若回合已結束，可復原再試。" }
    }
    func cancel() { selected = nil; feedback = "選擇已取消，沒有扣資源。" }
    func undo() {
        if session.undo() { selected = nil; feedback = "已復原；盤面與資源一併恢復。"; persist() }
    }
    func next() {
        do { try session.advance(); selected = nil; inspecting = nil; feedback = ""; persist() }
        catch { feedback = "先完成這個小目標。" }
    }
    func restart() {
        session = try! OnboardingSession(); selected = nil; inspecting = nil; feedback = ""; saveError = nil; persist()
    }
    func pause() { selected = nil; inspecting = nil; feedback = ""; persist() }
    private func persist() {
        // A corrupt existing journal remains untouched until explicit restart.
        guard saveError == nil else { return }
        do { try repository.save(session.progress) }
        catch { saveError = "教學進度儲存失敗；正式存局沒有變動。" }
    }
}

struct OnboardingView: View {
    @State private var model = OnboardingStore()
    @State private var showPoints = false
    @State private var confirmRestart = false
    @Environment(\.scenePhase) private var scenePhase
    let close: () -> Void
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 8) {
                    HStack {
                        Button("退出教學") { model.pause(); close() }.accessibilityIdentifier("onboardExit")
                        Spacer()
                        Text(model.session.finished ? "基礎 5／5" : "\(model.session.progress.lessonIndex + 1)／5")
                            .accessibilityIdentifier("onboardStep")
                        Spacer()
                        Button("重新開始") { confirmRestart = true }.accessibilityIdentifier("onboardRestart")
                    }.font(.system(size: 14)).frame(minHeight: 44)
                    if model.session.finished { finished }
                    else if let lesson = model.session.lesson {
                        Text(lesson.title).font(.system(size: 22, weight: .bold)).accessibilityIdentifier("onboardTitle")
                        Text(lesson.goal).font(.system(size: 15)).multilineTextAlignment(.center)
                        Text("\(model.state.current == .one ? "黑" : "白")方 · \(model.state.apRemaining) AP · \(model.state.mana(of: model.state.current)) 能量 · \(lesson.opening ? "原版開局" : "原版教學固定局面")")
                            .font(.system(size: 12)).foregroundStyle(Color.gold).accessibilityIdentifier("onboardResources")
                        let width = min(geometry.size.width - 24, 680)
                        let height = min(width * 0.88, max(205, geometry.size.height - 355))
                        arena(lesson).frame(width: width, height: height)
                        if let inspection = model.inspection {
                            Text("\(model.preview == nil ? "" : "目前（預覽前）")\(inspection.owner == .one ? "黑" : "白")方 · 棋群 \(inspection.group.count) 子 · \(inspection.liberties.count) 氣")
                                .font(.system(size: 15, weight: .bold)).foregroundStyle(.mint)
                                .accessibilityIdentifier("onboardInspection")
                        } else {
                            Text("點一顆棋子看共享氣，綠色菱形表示空點。")
                                .font(.system(size: 12)).foregroundStyle(.mint).accessibilityIdentifier("onboardInspection")
                        }
                        if let warning = model.warning {
                            Text(warning).font(.system(size: 13, weight: .bold)).foregroundStyle(.orange)
                                .accessibilityIdentifier("onboardDanger")
                        }
                        Text(model.session.completed ? lesson.explanation : model.previewText)
                            .font(.system(size: 14)).multilineTextAlignment(.center).frame(minHeight: 36)
                            .accessibilityIdentifier("onboardFeedback")
                        if model.session.completed {
                            Button(model.session.progress.lessonIndex == 4 ? "完成基礎教學" : "下一個小目標") { model.next() }
                                .buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink)
                                .frame(minHeight: 44).accessibilityIdentifier("onboardNext")
                        } else {
                            HStack(spacing: 8) {
                                Button("取消") { model.cancel() }.accessibilityIdentifier("onboardCancel")
                                Button("確認") { model.confirm() }.buttonStyle(.borderedProminent)
                                    .tint(Color.gold).foregroundStyle(Color.ink).disabled(!model.canConfirm)
                                    .accessibilityLabel("確認落子").accessibilityIdentifier("onboardConfirm")
                                Button("大按鍵選點") { showPoints = true }.accessibilityIdentifier("onboardPoints")
                            }.font(.system(size: 14)).frame(minHeight: 44)
                            Text(lesson.instruction).font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                        }
                        Button("復原上一步") { model.undo() }.disabled(model.session.progress.actions[model.session.progress.lessonIndex].isEmpty)
                            .frame(minHeight: 44).accessibilityIdentifier("onboardUndo")
                    }
                    if let error = model.saveError { Text(error).font(.caption).foregroundStyle(.orange) }
                }.padding(.horizontal, 12).padding(.bottom, 12).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
        }
        .background(Color.ink.ignoresSafeArea()).foregroundStyle(.white).preferredColorScheme(.dark)
        .sheet(isPresented: $showPoints) { points }
        .alert("重新開始會重設教學進度；正式對局不變。", isPresented: $confirmRestart) {
            Button("重設教學進度", role: .destructive) { model.restart() }.accessibilityIdentifier("onboardRestartConfirmed")
            Button("保留進度", role: .cancel) {}
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .onDisappear { model.pause() }
    }
    private func arena(_ lesson: OnboardingLesson) -> some View {
        let data = BoardPresentation(state: model.state, selected: model.selected.map { [$0] } ?? [],
            legal: [lesson.recommended], preview: model.preview)
        return SwiftBoard(presentation: data, select: model.select)
            .overlay {
                GeometryReader { geo in
                    ForEach(model.state.board.points, id: \.self) { point in
                        let center = data.center(point, geo.size)
                        if model.inspection?.group.contains(point) == true {
                            Circle().stroke(.mint, lineWidth: 2).frame(width: data.radius(point, geo.size) * 2.6)
                                .position(center)
                        }
                        if model.inspection?.liberties.contains(point) == true {
                            Rectangle().stroke(.mint, lineWidth: 2)
                                .background(Rectangle().fill(model.preview?.success == true && model.preview?.state.board[point] != nil ? Color.clear : Color.mint))
                                .frame(width: 10, height: 10).rotationEffect(.degrees(45)).position(center)
                        }
                        if point == lesson.recommended && !model.session.completed {
                            Circle().stroke(Color.gold, lineWidth: 3).frame(width: 27).position(center)
                        }
                    }
                }.allowsHitTesting(false)
            }
            .accessibilityElement(children: .ignore).accessibilityLabel("教學棋盤。亦可使用大按鍵選點。")
            .accessibilityIdentifier("onboardArena")
    }
    private var points: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 6) {
                    ForEach(model.state.board.points, id: \.self) { point in
                        Button {
                            model.select(point); showPoints = false
                        } label: {
                            VStack(spacing: 2) {
                                Text("\(String(UnicodeScalar(65 + point.x)!))\(point.y + 1)")
                                Text(model.state.board[point].map { "\($0.owner == .one ? "黑" : "白")\($0.kind == .commander ? "將" : "兵")" } ?? "空點").font(.system(size: 10))
                            }.frame(maxWidth: .infinity, minHeight: 48)
                        }.buttonStyle(.bordered).accessibilityIdentifier("onboardPoint-\(point.x)-\(point.y)")
                    }
                }.padding(12)
            }.navigationTitle("交叉點大按鍵")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("取消") { showPoints = false }.accessibilityIdentifier("onboardPointsCancel") } }
        }
    }
    private var finished: some View {
        VStack(spacing: 20) {
            Text("你已完成五個基礎操作").font(.title2.bold())
            Text("下一步試著自己思考：要增加己方的氣，還是封住對方的氣？\n英雄與技能可在現有玩法練習中體驗，完整技能新手課程尚未加入。")
                .multilineTextAlignment(.center)
            Button("前往自由對戰選角") { model.pause(); close() }.buttonStyle(.borderedProminent)
                .tint(Color.gold).foregroundStyle(Color.ink).accessibilityIdentifier("onboardFinish")
        }.padding(24)
    }
}
