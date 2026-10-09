import SwiftUI
import TacticalGoCore
import TacticalGoRecords

struct RecordLibraryView: View {
    @Bindable var store: GameStore
    let resume: (MatchRecord) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                if let error = store.recordErrorMessage { Text(error).foregroundStyle(.orange) }
                if store.savedRecords.isEmpty { Text("完成一個行動後，棋譜會自動保存在這裡。") }
                ForEach(store.savedRecords) { record in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(record.one.title) vs \(record.two.title) · \(record.size)×\(record.size)").bold()
                        Text(record.rules == .original ? "原版規則" : record.rules == .redeployment ? "候選技能" : "R2 " + record.rules.variant).font(.caption).foregroundStyle(.secondary)
                        Text(record.updated, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                        Text("\(record.computer == nil ? "本機雙人" : "單人・你執\(record.computer == .one ? "白" : "黑")") · \(record.difficulty == "easy" ? "簡單" : "標準") · \(record.steps.count) 步")
                            .font(.caption)
                        HStack {
                            NavigationLink("觀看棋譜") { RecordReplayView(record: record, export: { store.recordExport(record) }) }
                                .accessibilityIdentifier("replay-" + record.id.uuidString)
                            Spacer()
                            if record.steps.last?.after.status == .ongoing || record.steps.isEmpty {
                                Button("續玩") { resume(record); dismiss() }.buttonStyle(.bordered)
                            } else { Text(record.steps.last?.after.winner.map { $0 == .one ? "黑方獲勝" : "白方獲勝" } ?? "和局").font(.caption) }
                        }
                    }.padding(.vertical, 6)
                }
            }.navigationTitle("存局與棋譜")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() }.accessibilityIdentifier("recordsDone") } }
        }
    }
}

private struct RecordReplayView: View {
    let record: MatchRecord
    let export: () -> URL?
    private let frames: [ReplayFrame]
    @State private var index = 0
    @State private var exportURL: URL?
    init(record: MatchRecord, export: @escaping () -> URL?) {
        self.record = record; self.export = export; frames = (try? record.rebuild().1) ?? []
    }
    var body: some View {
        GeometryReader { geo in
            if frames.indices.contains(index) {
                let frame = frames[index], state = frame.state
                let width = min(geo.size.width - 24, 760)
                let height = min(width * 0.9, max(200, geo.size.height - 270))
                ScrollView {
                    VStack(spacing: 12) {
                        Text("第 \(index)／\(frames.count - 1) 步 · \(frame.step.map { ($0.actor == .one ? "黑方 " : "白方 ") + $0.action.label } ?? "開局")")
                            .font(.headline).accessibilityIdentifier("replayStep")
                        Text("輪到\(state.current == .one ? "黑方" : "白方") · \(state.apRemaining) AP · 黑方能量 \(state.mana(of:.one))／白方能量 \(state.mana(of:.two))")
                            .font(.subheadline).accessibilityIdentifier("replayResources")
                        SwiftBoard(presentation: BoardPresentation(state:state, selected:[],legal:[],preview:nil), select: { _ in })
                            .allowsHitTesting(false).frame(width:min(width,height/0.9),height:height)
                            .accessibilityLabel("棋譜唯讀棋盤").accessibilityIdentifier("replayBoard")
                        HStack {
                            Button("開局") { index = 0 }.disabled(index == 0).accessibilityIdentifier("replayStart")
                            Button("上一步") { index -= 1 }.disabled(index == 0).accessibilityIdentifier("replayPrevious")
                            Button("下一步") { index += 1 }.disabled(index + 1 >= frames.count).accessibilityIdentifier("replayNext")
                            Button("最後") { index = frames.count - 1 }.disabled(index + 1 >= frames.count).accessibilityIdentifier("replayLast")
                        }.buttonStyle(.bordered)
                        if !frame.events.isEmpty {
                            Text(frame.events.map(eventLabel).joined(separator:" · ")).font(.subheadline)
                        }
                        if let reason = frame.step?.decision {
                            DisclosureGroup("電腦決策紀錄") { Text(reason).font(.caption).textSelection(.enabled) }
                        }
                        if let exportURL { ShareLink("分享棋譜 JSON", item: exportURL).accessibilityIdentifier("shareReplay") }
                        else { Button("準備匯出棋譜") { exportURL = export() }.accessibilityIdentifier("exportReplay") }
                        Text("棋譜為唯讀；觀看不會改變正在玩的棋局。").font(.caption).foregroundStyle(.secondary)
                    }.padding(12).frame(maxWidth:784).frame(maxWidth:.infinity)
                }
            } else { Text("這份棋譜無法驗證，原檔已保留。") }
        }.navigationTitle("對局重播").navigationBarTitleDisplayMode(.inline)
    }
    private func eventLabel(_ event: ActionEvent) -> String {
        switch event {
        case .resourcesSpent(_,let ap,let mana): return "消耗 \(ap) AP、\(mana) 能量"
        case .piecesCaptured(_,let pieces): return "提子 \(pieces.count) 枚"
        case .piecePlaced(_,_,let kind): return kind == .hero ? "英雄召喚" : "落子"
        case .piecePushed: return "士兵推動"
        case .piecesSwapped: return "棋子交換"
        case .turnEnded: return "結束回合"
        case .turnStarted: return "換手"
        case .gameWon(let player): return player == .one ? "黑方獲勝" : "白方獲勝"
        case .gameDrawn: return "和局"
        case .sealPlaced: return "封印"
        case .sealExpired: return "封印結束"
        }
    }
}
