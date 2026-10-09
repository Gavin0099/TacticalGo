import SwiftUI
import TacticalGoCore
import TacticalGoMotion

#if DEBUG
/// Recording-only timing receipts identify actual native playback in a video.
/// They never provide or change game outcomes and are absent without a UUID flag.
@MainActor enum MotionReviewTrace {
    private static var rows: [[String: Any]] = []
    static var enabled: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.firstIndex(of: "--record-tour-token").map { $0 + 1 < args.count && UUID(uuidString: args[$0 + 1]) != nil } ?? false
    }
    static func record(_ phase: String, values: [String: Any] = [:]) {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "--record-tour-token"), index + 1 < args.count,
              UUID(uuidString: args[index + 1]) != nil else { return }
        var row = values; row["phase"] = phase; row["wallTimeUnix"] = Date().timeIntervalSince1970
        rows.append(row)
        do {
            let folder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let trace: [String: Any] = ["token": args[index + 1], "complete": phase == "tour-complete", "rows": rows,
                "claim": "native presentation timing and actual accepted-action cues; rendered pixels require separate review"]
            try JSONSerialization.data(withJSONObject: trace, options: [.prettyPrinted, .sortedKeys])
                .write(to: folder.appendingPathComponent("motion-tour-" + args[index + 1] + ".json"), options: .atomic)
        } catch { print("Motion trace failed:", error) }
    }
}
#endif

/// Recording-only pixel timecode provides an independent clock in the movie.
/// Host launch time is not the video's first-frame presentation timestamp.
struct ReviewTimecode: ViewModifier {
    @ViewBuilder func body(content: Content) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--record-timecode") {
            content.overlay(alignment: .topLeading) {
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { context in
                    let stamp = UInt64((context.date.timeIntervalSince1970 * 1000).rounded()) & 0xffff_ffff
                    let check = (stamp ^ (stamp >> 8) ^ (stamp >> 16) ^ (stamp >> 24)) & 0xff
                    let payload = (stamp << 8) | check
                    Canvas { canvas, _ in
                        func cell(_ index: Int, _ color: Color) {
                            canvas.fill(Path(CGRect(x: CGFloat(index * 4), y: 0, width: 4, height: 8)), with: .color(color))
                        }
                        cell(0, Color(red: 0, green: 1, blue: 1))
                        for index in 0..<40 {
                            cell(index + 1, payload & (UInt64(1) << (39 - index)) == 0 ? .black : .white)
                        }
                        cell(41, Color(red: 1, green: 0, blue: 1))
                    }.frame(width: 168, height: 8)
                }.padding(8).allowsHitTesting(false).accessibilityHidden(true)
            }
        } else { content }
        #else
        content
        #endif
    }
}

/// Native review controls play real accepted actions using the game's same model renderer.
struct AnimationGallery: View {
    let view: TabletopView
    let done: () -> Void
    @State private var example: MotionExample = .bastion
    @State private var state = try! MotionExample.bastion.initialState()
    @State private var playback: BoardPlayback?
    @State private var slow = false
    @State private var reduce = false
    @State private var message = "準備好後播放動作。"
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion
    private var recordingCloseup: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--motion-closeup")
        #else
        false
        #endif
    }
    var body: some View {
        GeometryReader { geo in
            let compact = geo.size.height < 650
            ScrollView {
            VStack(spacing: compact ? 8 : 14) {
                HStack { Text("對戰動作").font(.title2.bold()); Spacer(); Button("完成", action: done) }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(MotionExample.allCases, id: \.self) { e in
                        Button(e.rawValue) { load(e) }.font(.subheadline.bold()).frame(maxWidth: .infinity, minHeight: compact ? 36 : 40)
                            .background(example == e ? Color.gold : Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(example == e ? Color.ink : .white).accessibilityIdentifier("motion-" + e.rawValue)
                    }
                }
                ModelBoard(view: view, presentation: BoardPresentation(state: state, selected: [], legal: [], preview: nil),
                           playback: playback, reducedMotion: reduce || systemReducedMotion, speed: slow ? 0.35 : 1, yaw: 0,
                           zoom: recordingCloseup ? 2.4 : 1, focusPoint: recordingCloseup ? Point(3, 3) : nil, select: { _ in })
                    .frame(height: min(geo.size.width * 0.95, geo.size.height * (compact ? 0.30 : 0.53)))
                    .clipShape(RoundedRectangle(cornerRadius: 20)).accessibilityIdentifier("motionArena")
                HStack {
                    Text("\(state.apRemaining) 次 · \(state.mana(of: .one)) 能量").font(.headline)
                    Spacer()
                    Text(state.status == .won ? "藍方獲勝" : "\(example.rawValue)").foregroundStyle(Color.gold)
                }.accessibilityIdentifier("motionResult")
                Text(message).font(.subheadline).lineLimit(2).frame(maxWidth: .infinity, minHeight: compact ? 32 : 40, alignment: .leading)
                HStack {
                    Toggle("慢動作", isOn: $slow).accessibilityIdentifier("slowMotion")
                    Toggle("減少動態", isOn: $reduce).accessibilityIdentifier("reduceMotion")
                }.font(.caption)
                HStack {
                    Button("重設") { load(example) }
                    Spacer()
                    Button("播放動作", systemImage: "play.fill") { play() }.font(.headline).accessibilityIdentifier("playMotion")
                    Spacer()
                    Button("跳過") { playback = nil; message = "已顯示確認後的結果。" }.accessibilityIdentifier("skipMotion")
                }.padding(12).background(Color.gold, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Color.ink)
                Spacer(minLength: 0)
            }.padding(compact ? 12 : 16)
            }.scrollIndicators(.hidden)
        }.foregroundStyle(.white).background(Color.ink).preferredColorScheme(.dark)
        .modifier(ReviewTimecode())
        .task {
            if ProcessInfo.processInfo.arguments.contains("--seal-tour") {
                slow = true; load(.seal)
                try? await Task.sleep(for: .seconds(3))
                guard !Task.isCancelled else { return }; play()
                #if DEBUG
                try? await Task.sleep(for: .seconds(5))
                MotionReviewTrace.record("tour-complete")
                #endif
            }
            // Local recording-only tour: no fabricated outcomes or hidden rule changes.
            if ProcessInfo.processInfo.arguments.contains("--motion-tour") {
                slow = true
                try? await Task.sleep(for: .seconds(6))
                for e in MotionExample.allCases {
                    guard !Task.isCancelled else { return }
                    load(e); try? await Task.sleep(for: .seconds(1))
                    play(); try? await Task.sleep(for: .seconds(4))
                }
                #if DEBUG
                MotionReviewTrace.record("tour-complete")
                #endif
            }
        }
    }
    func load(_ e: MotionExample) {
        example = e; state = try! e.initialState(); playback = nil; message = "\(e.rawValue)：按播放查看動作。"
    }
    func play() {
        let before = try! example.initialState(), outcome = GameEngine.apply(before, example.action)
        guard outcome.success else { message = GameStore.reason(outcome.reason); playback = nil; return }
        state = outcome.state; playback = BoardPlayback(before: before, action: example.action, outcome: outcome)
        #if DEBUG
        MotionReviewTrace.record("requested", values: ["example": example.rawValue, "receipt": playback!.id.uuidString])
        #endif
        if example == .victory { message = "主將被包圍並提走，藍方獲勝。" }
        else if example == .expire { message = "紅方結束回合，封印到期；藍方開始行動。" }
        else { message = "\(example.rawValue)完成；可重播或切換其他動作。" }
    }
}
