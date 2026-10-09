import SwiftUI
import TacticalGoCore

struct ContentView: View {
    @State private var store = GameStore()
    @State private var showAccessibleBoard = false
    @State private var showModels = false
    @State private var showAnimations = false
    @State private var showMatchReplay = false
    @State private var showReviewTools = ProcessInfo.processInfo.arguments.contains("--review-controls")
    @State private var boardZoom: Float = 1
    @State private var zoomFocus: Point?
    @State private var boardPan = SIMD2<Float>.zero
    @State private var boardYaw: Float = 0
    @State private var tabletop = TabletopView()
    @State private var startupApplied = false
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    var body: some View {
        Group {
            if showMatchReplay { MatchGallery(view: tabletop, done: { showMatchReplay = false }) }
            else if showAnimations { AnimationGallery(view: tabletop, done: { showAnimations = false }) }
            else if showModels { ModelGallery(view: tabletop, done: { showModels = false }) }
            else { game }
        }
    }
    var game: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: showReviewTools ? (geo.size.height < 650 ? 5 : 10) : (geo.size.height < 650 ? 3 : 8)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text("TACTICAL GO").font(.system(size: 22, weight: .black, design: .rounded)).tracking(1)
                            if showReviewTools && geo.size.height > 650 { Text("英雄包圍戰 · 斜俯視棋盤").font(.caption).foregroundStyle(.white.opacity(0.65)) }
                        }
                        Spacer()
                        gameMenu
                        Text("\(store.state.ply) 回合").font(.caption.bold()).padding(8).background(.white.opacity(0.08), in: Capsule())
                    }.foregroundStyle(.white)
                    if showReviewTools {
                    HStack {
                        Picker("棋盤尺寸", selection: Binding(get: { store.size }, set: { store.load(size: $0) })) {
                            Text("7 × 7").tag(7); Text("9 × 9").tag(9)
                        }.pickerStyle(.segmented).accessibilityIdentifier("boardSize")
                        Picker("渲染方式", selection: $store.renderer) {
                            ForEach(GameStore.Renderer.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.segmented).accessibilityIdentifier("renderer")
                    }
                    Picker("驗收畫面", selection: Binding(get: { store.review }, set: { store.load($0) })) {
                        ForEach(GameStore.Review.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("review")
                    }
                    HStack(spacing: 8) {
                        Circle().fill(store.state.current == .one ? Color.blueTeam : Color.redTeam).frame(width: 10, height: 10)
                        Text(store.state.status == .ongoing ? (store.state.current == .one ? "藍方行動" : "紅方行動") : "對戰結束").font(.subheadline.bold())
                        Spacer()
                        Label("\(store.state.apRemaining) 次", systemImage: "bolt.fill").foregroundStyle(Color.gold)
                        Label("\(store.state.mana(of: store.state.current)) / 6", systemImage: "drop.fill").foregroundStyle(.cyan)
                    }.font(.subheadline.bold()).foregroundStyle(.white).padding(.horizontal, 12).padding(.vertical, showReviewTools ? 10 : 7)
                        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14)).accessibilityIdentifier("resources")
                    if let result = store.resultTitle {
                        Label(result, systemImage: store.state.status == .won ? "crown.fill" : "equal.circle.fill")
                            .font(.headline).foregroundStyle(Color.gold).frame(maxWidth: .infinity, minHeight: 40)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityIdentifier("matchResult")
                    }
                    if !showReviewTools && store.renderer == .models {
                        HStack {
                            Text(boardZoom > 1 ? "拖曳棋盤 · 點選預覽" : "\(store.size) × \(store.size) · 點選棋盤預覽")
                                .font(.caption).foregroundStyle(.white.opacity(0.7))
                            Spacer()
                            if boardZoom > 1 {
                                Button {
                                    boardPan = .zero; zoomFocus = store.selected.first
                                } label: {
                                    Label("置中", systemImage: "scope").font(.caption.bold())
                                        .padding(.horizontal, 10).frame(minHeight: 44)
                                }
                                .foregroundStyle(.white).background(.white.opacity(0.10), in: Capsule())
                                .accessibilityIdentifier("boardLocate")
                                .accessibilityValue(boardPan == .zero ? "已置中" : "棋盤已移動")
                            }
                            Button {
                                boardPan = .zero
                                if boardZoom == 1 { zoomFocus = store.selected.first; boardZoom = 1.6 }
                                else { boardZoom = 1; zoomFocus = nil; boardPan = .zero }
                            } label: {
                                Label(boardZoom == 1 ? "放大" : "全盤", systemImage: boardZoom == 1 ? "plus.magnifyingglass" : "arrow.down.right.and.arrow.up.left")
                                    .font(.caption.bold()).padding(.horizontal, 12).frame(minHeight: 44)
                            }
                            .foregroundStyle(.white).background(.white.opacity(0.10), in: Capsule())
                            .accessibilityIdentifier("boardZoom")
                        }.frame(height: 44)
                    }
                    let data = BoardPresentation(state: store.state, selected: store.selected, legal: store.legalTargets, preview: store.preview)
                    Group {
                        if store.renderer == .models { ModelBoard(view: tabletop, presentation: data, playback: store.playback, reducedMotion: reducedMotion, yaw: boardYaw, zoom: boardZoom, focusPoint: zoomFocus, panOffset: boardPan, panChanged: { boardPan = $0 }, select: { store.select($0) }) }
                        else if store.renderer == .spriteKit { SpriteBoard(presentation: data, select: { store.select($0) }) }
                        else { SwiftBoard(presentation: data, select: { store.select($0) }) }
                    }.frame(height: boardHeight(geo.size))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .accessibilityElement(children: .ignore).accessibilityLabel("\(store.size)乘\(store.size)棋盤")
                        .accessibilityIdentifier("arena")
                        .accessibilityValue(store.selected.map { "\($0.x + 1),\($0.y + 1)" }.joined(separator: "; "))
                    if showReviewTools && store.renderer == .models {
                        HStack {
                            Button("英雄模型", systemImage: "cube") { showModels = true }
                            Spacer()
                            Button("對戰動作", systemImage: "play.circle") { showAnimations = true }
                            Spacer()
                            Button("旋轉視角", systemImage: "rotate.3d") { boardYaw = boardYaw == 0 ? 0.30 : 0 }
                        }.font(.caption.bold()).foregroundStyle(Color.gold)
                    }
                    HStack(spacing: 10) {
                        Image(heroImage).resizable().scaledToFit().frame(width: 58, height: showReviewTools && geo.size.height >= 650 ? 65 : 48)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(heroTitle).font(.headline)
                            Text(showReviewTools ? heroDescription : compactHeroDescription).font(.caption).foregroundStyle(Color.ink.opacity(0.7))
                        }
                        Spacer(minLength: 0)
                        VStack(spacing: 2) {
                            Text("主將棋串").font(.caption2)
                            let commander = store.state.board.find(store.state.current, .commander)
                            let count = commander.map { store.state.board.liberties(at: $0).count } ?? 0
                            Text("\(count) 氣").font(.headline).foregroundStyle(count <= 1 ? Color.redTeam : Color.ink)
                        }
                    }.foregroundStyle(Color.ink).padding(.horizontal, 10).padding(.vertical, 6).background(Color(red: 0.95, green: 0.92, blue: 0.82), in: RoundedRectangle(cornerRadius: 16))
                    Text(store.message).font(.system(size: 13, weight: .medium)).foregroundStyle(Color.gold)
                        .frame(maxWidth: .infinity, minHeight: showReviewTools ? 34 : 26, alignment: .leading).accessibilityIdentifier("message")
                    Picker("行動", selection: Binding(get: { store.mode }, set: { store.changeMode($0) })) {
                        ForEach(GameStore.Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("mode")
                    HStack(spacing: 8) {
                        Button { store.selected = [] } label: { Image(systemName: "xmark").frame(width: 38, height: 44) }
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white).accessibilityLabel("取消預覽")
                        Button { store.confirm() } label: {
                            Label(store.mode == .skill ? "確認技能" : "確認放這裡", systemImage: "checkmark.circle.fill").font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                        }.background(Color.gold, in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(Color.ink)
                            .disabled(store.preview?.success != true).opacity(store.preview?.success == true ? 1 : 0.45).accessibilityIdentifier("confirm")
                        Button("換手") { store.endTurn() }.font(.subheadline.bold()).frame(width: 56, height: 44)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)).foregroundStyle(.white).disabled(store.state.status != .ongoing)
                    }
                    if showReviewTools {
                    HStack {
                        Button("復原", systemImage: "arrow.uturn.backward", action: { store.undo() }).disabled(!store.session.canUndo)
                        Spacer()
                        Button("格點清單") { showAccessibleBoard.toggle() }
                        Spacer()
                        Button("新對戰", action: startNewMatch)
                    }.font(.caption.bold()).foregroundStyle(.white.opacity(0.75)).frame(minHeight: 32)
                    }
                    if showAccessibleBoard {
                        // Native accessible targets for both renderers, including dense 9×9 boards.
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
                            ForEach(store.state.board.points, id: \.self) { p in
                                Button("\(p.x + 1),\(p.y + 1) · \(String(Board.symbol(store.state.board[p])))") { store.select(p) }
                                    .frame(minHeight: 44).foregroundStyle(.white).accessibilityIdentifier("cell-\(p.x)-\(p.y)")
                            }
                        }
                    }
                }.padding(.horizontal, 16).padding(.vertical, 8)
            }.scrollIndicators(.hidden)
        }.background(LinearGradient(colors: [Color(red: 0.12, green: 0.26, blue: 0.30), Color(red: 0.055, green: 0.12, blue: 0.18)], startPoint: .top, endPoint: .bottom))
            .preferredColorScheme(.dark)
            .onChange(of: store.size) { boardZoom = 1; zoomFocus = nil; boardPan = .zero }
            .onChange(of: store.review) { boardZoom = 1; zoomFocus = nil; boardPan = .zero }
            .onAppear {
                guard !startupApplied else { return }; startupApplied = true
                let args = ProcessInfo.processInfo.arguments
                #if DEBUG
                if args.contains("--export-units") {
                    do { print("Unit candidates exported:", try ModelResourceExport.writeCandidates(unitsOnly: true).path) }
                    catch { print("Unit candidate export failed:", error) }
                }
                if args.contains("--export-arena") {
                    do { print("Arena candidates exported:", try ModelResourceExport.writeCandidates(arenaOnly: true).path) }
                    catch { print("Arena candidate export failed:", error) }
                }
                if args.contains("--verify-sockets") {
                    do { print("Model sockets checked:", try ModelResourceExport.verifySockets().path) }
                    catch { print("Model socket check failed:", error) }
                }
                if args.contains("--verify-playback-restoration") {
                    do { print("Native playback restoration checked:", try ModelResourceExport.verifyPlaybackRestoration(on: tabletop).path) }
                    catch { print("Native playback restoration failed:", error) }
                }
                if args.contains("--verify-idle") {
                    do { print("Native idle poses checked:", try ModelResourceExport.verifyIdlePoses(on: tabletop).path) }
                    catch { print("Native idle pose check failed:", error) }
                }
                if args.contains("--export-idle") {
                    do { print("Idle candidates exported:", try ModelResourceExport.writeCandidates(idle: true).path) }
                    catch { print("Idle candidate export failed:", error) }
                }
                if args.contains("--export-models") {
                    do { print("Model candidates exported:", try ModelResourceExport.writeCandidates().path) }
                    catch { print("Model candidate export failed:", error) }
                }
                if args.contains("--verify-models"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Model packages checked:", try await ModelResourceExport.verifyPackages().path) }
                        catch { print("Model package check failed:", error) }
                    }
                }
                if args.contains("--verify-arena"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Arena packages checked:", try await ModelResourceExport.verifyArenas().path) }
                        catch { print("Arena package check failed:", error) }
                    }
                }
                if args.contains("--verify-units"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Unit packages checked:", try await ModelResourceExport.verifyUnits(compacted: args.contains("--compact-units")).path) }
                        catch { print("Unit package check failed:", error) }
                    }
                }
                if args.contains("--audit-imported-clips"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Imported clip bindings audited:", try await ModelResourceExport.auditImportedClips(in: tabletop).path) }
                        catch { print("Imported clip binding audit failed:", error) }
                    }
                }
                if args.contains("--verify-rigs"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Model rigs checked:", try await ModelResourceExport.verifyRigs().path) }
                        catch { print("Model rig check failed:", error) }
                    }
                }
                if args.contains("--verify-cape-poses"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Native cape poses checked:", try await ModelResourceExport.verifyCapePoses().path) }
                        catch { print("Native cape pose check failed:", error) }
                    }
                }
                if args.contains("--verify-leg-poses"), #available(iOS 18.0, *) {
                    Task { @MainActor in
                        do { print("Model leg poses checked:", try await ModelResourceExport.verifyLegPoses().path) }
                        catch { print("Model leg pose check failed:", error) }
                    }
                }
                #endif
                if args.contains("--nine") { store.load(size: 9) }
                if args.contains("--swiftui") { store.renderer = .swiftUI }
                if args.contains("--spritekit") { store.renderer = .spriteKit }
                if args.contains("--identity-models") || args.contains("--models") || args.contains("--idle-tour") || args.contains("--model-tour") || args.contains("--rig-models") || args.contains("--package-models") { showModels = true }
                if args.contains("--motion-review") || args.contains("--motion-tour") || args.contains("--seal-tour") { showAnimations = true }
                if args.contains("--match-review") || args.contains("--match-tour") { showMatchReplay = true }
                if args.contains("--skill") { store.load(.skill) }
                if args.contains("--danger") { store.load(.danger) }
                #if DEBUG
                if args.contains("--last-turn") { store.loadLastTurn() }
                if args.contains("--winning-turn") { store.loadWinningTurn() }
                #endif
            }
    }
    func boardHeight(_ size: CGSize) -> CGFloat {
        if !showReviewTools {
            return max(180, min(size.width * 1.10, size.height * 0.56) - (store.resultTitle == nil ? 0 : 44) - (store.renderer == .models ? 44 + (size.height < 650 ? 3 : 8) : 0))
        }
        return min(size.width * 0.86, size.height * (size.height < 650 ? (store.renderer == .models ? 0.30 : 0.34) : (store.renderer == .models ? 0.39 : 0.44)))
    }
    func startNewMatch() {
        boardZoom = 1; zoomFocus = nil; boardPan = .zero
        store.newMatch()
    }
    var gameMenu: some View {
        Menu {
            Button("英雄模型", systemImage: "cube") { showModels = true }
            Button("對戰動作", systemImage: "play.circle") { showAnimations = true }
            Button("連續對戰回放", systemImage: "play.rectangle") { showMatchReplay = true }
            Button("復原", systemImage: "arrow.uturn.backward", action: store.undo).disabled(!store.session.canUndo)
            Button("格點清單") { showAccessibleBoard.toggle() }
            Button("新對戰", action: startNewMatch)
            Button("旋轉視角") { boardYaw = boardYaw == 0 ? 0.30 : 0 }
            Button(showReviewTools ? "試玩畫面" : "驗收設定") { showReviewTools.toggle(); boardZoom = 1; zoomFocus = nil; boardPan = .zero }
        } label: { Image(systemName: "slider.horizontal.3").frame(width: 36, height: 36) }
            .accessibilityLabel("對戰設定").foregroundStyle(Color.gold)
    }
    var compactHeroDescription: String {
        switch store.state.heroClass(of: store.state.current) {
        case .warrior: "築壘 · 相鄰雙落子 · 2 能量"
        case .rogue: "換位 · 相鄰敵兵 · 2 能量"
        default: "封印 · 距離 2 · 2 能量"
        }
    }
    var heroImage: String {
        let name: String
        switch store.state.heroClass(of: store.state.current) {
        case .warrior: name = "warrior"
        case .rogue: name = "rogue"
        default: name = "mage"
        }
        return store.renderer == .models ? name + "-3d" : name
    }
    var heroTitle: String {
        switch store.state.heroClass(of: store.state.current) {
        case .warrior: "戰士 · 築壘"; case .rogue: "盜賊 · 換位"; default: "法師 · 封印"
        }
    }
    var heroDescription: String {
        switch store.state.heroClass(of: store.state.current) {
        case .warrior: "相鄰兩個空點放士兵 · 1 次行動＋2 能量"
        case .rogue: "交換相鄰敵方士兵 · 1 次行動＋2 能量"
        default: "封住距離 2 內空點 · 1 次行動＋2 能量"
        }
    }
}
