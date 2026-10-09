import SwiftUI
import TacticalGoCore
import TacticalGoMotion

/// A continuous native presentation review; the player's match stays separate.
struct MatchGallery: View {
    let view: TabletopView
    let done: () -> Void
    @State private var example: MatchExample = .warriorMage
    @State private var session = GameSession(try! MatchExample.warriorMage.initialState())
    @State private var index = 0
    @State private var playback: BoardPlayback?
    @State private var runID: UUID?
    @State private var slow = false
    @State private var reduce = false
    @State private var message = "從標準開局檢查跨回合動作銜接。"
    @State private var trace: [[String: Any]] = []
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion

    private var state: GameState { session.state }
    private var result: String {
        state.status == .won ? "\(state.winner == .one ? "藍方" : "紅方")獲勝" : "\(state.current == .one ? "藍方" : "紅方")行動"
    }
    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 650
            ScrollView {
                VStack(spacing: compact ? 8 : 12) {
                    HStack { Text("連續對戰回放").font(.title2.bold()); Spacer(); Button("完成") { stop(); done() } }
                    Picker("回放對戰", selection: $example) {
                        ForEach(MatchExample.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("matchExample")
                    ModelBoard(view: view, presentation: BoardPresentation(state: state, selected: [], legal: [], preview: nil),
                        playback: playback, reducedMotion: reduce || systemReducedMotion,
                        speed: slow ? 0.35 : 1, yaw: 0, select: { _ in })
                        .frame(height: min(geo.size.width * 1.02, geo.size.height * (compact ? 0.38 : 0.55)))
                        .clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityIdentifier("matchReplayArena")
                    HStack {
                        Text("\(index) / \(example.actions.count) 步 · \(state.ply) 回合")
                        Spacer(); Text(result).foregroundStyle(Color.gold)
                    }.font(.headline).accessibilityIdentifier("matchReplayResult")
                    HStack {
                        Text("藍 \(state.mana(of: .one)) 能量")
                        Spacer(); Text("\(state.apRemaining) 次行動")
                        Spacer(); Text("紅 \(state.mana(of: .two)) 能量")
                    }.font(.caption.bold()).accessibilityIdentifier("matchReplayResources")
                    Text(message).font(.subheadline).lineLimit(2).frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    HStack {
                        Toggle("慢動作", isOn: $slow)
                        Toggle("減少動態", isOn: $reduce).accessibilityIdentifier("matchReplayReduce")
                    }.font(.caption)
                    HStack {
                        Button("重設") { reset() }.accessibilityIdentifier("resetMatchReplay")
                        Spacer()
                        Button(runID == nil ? "連續播放" : "暫停", systemImage: runID == nil ? "play.fill" : "pause.fill") {
                            if runID == nil { runID = UUID() } else { runID = nil }
                        }.disabled(index >= example.actions.count).accessibilityIdentifier("autoMatchReplay")
                        Spacer()
                        Button("下一步") { runID = nil; advance() }.disabled(index >= example.actions.count)
                            .accessibilityIdentifier("nextMatchReplay")
                    }.font(.subheadline.bold()).padding(12).foregroundStyle(Color.ink)
                        .background(Color.gold, in: RoundedRectangle(cornerRadius: 12))
                    HStack {
                        Button("復原一步") {
                            stop()
                            if session.undo() { index -= 1; trace.removeLast(); message = "已復原完整狀態，可重播這一步。"; writeTrace() }
                        }.disabled(!session.canUndo).accessibilityIdentifier("undoMatchReplay")
                        Spacer()
                        Button("跳過動作") { stop(); message = "保留已確認結果，停止這一步的動畫。" }
                            .accessibilityIdentifier("skipMatchReplay")
                    }.font(.subheadline)
                    Text("配合走法供動畫檢查；玩法與平衡仍需真人驗收。")
                        .font(.caption).foregroundStyle(.white.opacity(0.60))
                }.padding(compact ? 12 : 16)
            }.scrollIndicators(.hidden)
        }.foregroundStyle(.white).background(Color.ink).preferredColorScheme(.dark)
        .onChange(of: example) { reset() }
        .task(id: runID) {
            guard runID != nil else { return }
            while !Task.isCancelled && index < example.actions.count {
                advance()
                let duration = (playback?.plan.duration ?? 0) / (slow ? 0.35 : 1)
                do { try await Task.sleep(for: .seconds(max(1.4, duration + 0.65))) }
                catch { return }
            }
            if !Task.isCancelled { runID = nil }
        }
        .task {
            let args = ProcessInfo.processInfo.arguments
            guard args.contains("--match-tour") else { return }
            if args.contains("--rogue-match") { example = .rogueWarrior; reset() }
            if args.contains("--slow-match") { slow = true }
            do { try await Task.sleep(for: .seconds(4)) } catch { return }
            runID = UUID()
        }
        .onDisappear { stop() }
    }
    private func stop() { runID = nil; playback = nil }
    private func reset() {
        stop(); session = GameSession(try! example.initialState()); index = 0; trace = []
        message = "標準開局：藍方首回合 1 次行動。"; writeTrace()
    }
    private func advance() {
        guard index < example.actions.count else { return }
        let before = state, action = example.actions[index], result = session.apply(action)
        guard result.success else { stop(); message = GameStore.reason(result.reason); return }
        playback = BoardPlayback(before: before, action: action, outcome: result)
        index += 1
        let verb: String
        switch action {
        case .summonHero: verb = "召喚英雄"
        case .castBastion: verb = "築壘"
        case .castSeal: verb = "封印"
        case .castMagicHand: verb = "魔法之手"
        case .castFriendlyRedeploy: verb = "調度己兵"
        case .castSwap: verb = "換位"
        case .placeSoldier: verb = "落子"
        case .endTurn: verb = "換手"
        }
        message = "\(before.current == .one ? "藍方" : "紅方")\(verb)；\(self.result)。"
        trace.append(["step": index, "actor": before.current.name, "action": String(describing: action),
            "events": result.events.map(\.name), "diagram": state.board.diagram,
            "ply": state.ply, "ap": state.apRemaining, "manaOne": state.mana(of: .one),
            "manaTwo": state.mana(of: .two), "status": state.status.rawValue,
            "winner": state.winner?.name ?? "", "motionDuration": playback!.plan.duration])
        writeTrace()
    }
    private func writeTrace() {
        #if DEBUG
        do {
            let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let file = folder.appendingPathComponent(example == .warriorMage ? "warrior-mage-match-review.json" : "rogue-warrior-match-review.json")
            try JSONSerialization.data(withJSONObject: ["kind": "native continuous actual GameSession actions from newGame",
                "example": example.rawValue, "completedActions": index, "expectedActions": example.actions.count,
                "steps": trace, "claim": "cooperative motion continuity review; not balance or human playtest"], options: [.prettyPrinted, .sortedKeys])
                .write(to: file, options: .atomic)
        } catch { message = "回放記錄寫入失敗：\(error.localizedDescription)" }
        #endif
    }
}
