import SwiftUI
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import TacticalGoContent
import TacticalGoVisuals

extension HeroClass {
    var title: String { switch self { case .warrior: "戰士"; case .mage: "法師"; case .rogue: "盜賊"; case .priest: "牧師"; case .none: "無職業" } }
    var art: String { rawValue.lowercased() }
    var skillTitle: String { switch self { case .warrior: "築壘"; case .mage: "魔法之手"; case .rogue: "換位"; case .priest: "奉獻"; case .none: "技能" } }
    var skillHelp: String {
        switch self {
        case .warrior: "英雄相鄰的兩個空點，同時放士兵。"
        case .mage: "距離 2 內的任一士兵，推往相鄰空點。"
        case .rogue: "與相鄰敵方士兵交換位置。"
        case .priest: "犧牲兩格內己兵，打開氣或眼；不補子、不位移。"
        case .none: "請先選擇職業。"
        }
    }
    var summonCost: Int { self == .mage || self == .priest ? 3 : 2 }
}
extension PushDirection {
    var title: String { switch self { case .up: "上"; case .right: "右"; case .down: "下"; case .left: "左"; case .invalid: "？" } }
    var symbol: String { switch self { case .up: "arrow.up"; case .right: "arrow.right"; case .down: "arrow.down"; case .left: "arrow.left"; case .invalid: "questionmark" } }
}

enum PracticeLesson: String, CaseIterable, Identifiable {
    case capture = "包圍與提子", warrior = "戰士築壘", mage = "法師魔法之手", rogue = "盜賊換位"
    var id: String { rawValue }
    var instruction: String {
        switch self {
        case .capture: "在 D4 落子，封住敵兵最後一氣，再按確認。"
        case .warrior: "選 C4 與 E4，預覽兩顆士兵，再按確認。"
        case .mage: "選 E4 的敵兵，再選「上」並確認。"
        case .rogue: "選 E4 的敵兵，預覽換位，再按確認。"
        }
    }
    var initialState: GameState {
        var rows = [".......", "...O...", ".......", "...H...", ".......", "...X...", "......."]
        let hero: HeroClass
        switch self {
        case .capture:
            rows = ["...O...", "...x...", "..xox..", ".......", ".......", "...X...", "......."]; hero = .warrior
        case .warrior: hero = .warrior
        case .mage: rows[3] = "...Ho.."; hero = .mage
        case .rogue: rows[3] = "...Ho.."; hero = .rogue
        }
        return try! GameSetup.fromDiagram(config: .board(size: 7), diagram: rows.joined(separator: "\n"),
            classOne: hero, classTwo: .warrior, manaOne: 6, manaTwo: 6, ap: 2)
    }
    func isComplete(_ state: GameState) -> Bool {
        switch self {
        case .capture: state.board[Point(3, 2)] == nil && state.board[Point(3, 3)] == Piece(.one, .soldier)
        case .warrior: state.board[Point(2, 3)] == Piece(.one, .soldier) && state.board[Point(4, 3)] == Piece(.one, .soldier)
        case .mage: state.board[Point(4, 3)] == nil && state.board[Point(4, 2)] == Piece(.two, .soldier)
        case .rogue: state.board[Point(4, 3)] == Piece(.one, .hero) && state.board[Point(3, 3)] == Piece(.two, .soldier)
        }
    }
}

/// A0 playable product entry. Original cards/tokens; no 3D resource loading.
struct PlayableGameView: View {
    @State private var store = GameStore()
    @State private var visuals = GameVisualAssets.original
    @State private var visualFixture = false
    @State private var inMatch = false
    @State private var one: HeroClass = .warrior
    @State private var two: HeroClass = .mage
    @State private var choosing: Player = .one
    @State private var boardSize = 7
    @State private var singlePlayer = false
    @State private var humanSide: Player = .one
    @State private var showBotLog = false
    @State private var showSoundSettings = false
    @State private var showTacticalHelp = false
    @State private var showRecords = false
    @State private var showOnboarding = false
    @State private var showR2 = false
    @State private var selectedRules: RecordRules = .original
    #if DEBUG || TACTICALGO_V11
    @State private var audioAuditStatus = "RUNNING"
    @State private var useExpansion = true
    @State private var monsters: ExpansionLabStore.Monsters = .none
    #else
    private let useExpansion = false
    #endif
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lesson: PracticeLesson?
    @State private var showRules = false
    @State private var showGrid = false
    @State private var confirmExit = false
    
    private var heroes: [HeroClass] {
        useExpansion ? HeroClass.allCases.filter { $0 != .none } : HeroClass.originalClasses
    }
    private func portrait(_ h: HeroClass) -> UIImage {
        #if DEBUG || TACTICALGO_V11
        if h == .priest, let url = Bundle.main.url(forResource:"priest-v02",withExtension:"png",subdirectory:"PresentationLab/P08"),let image = UIImage(contentsOfFile:url.path) { return image }
        #endif
        return visuals.portrait(h.art)
    }
    private var warmInterface: Bool {
        #if DEBUG || TACTICALGO_V11
        useExpansion
        #else
        false
        #endif
    }
    private var uiInk: Color { warmInterface ? Color(red:0.14,green:0.25,blue:0.26):.white }
    private var uiSecondary: Color { uiInk.opacity(0.70) }
    private var uiAccent: Color { warmInterface ? Color(red:0.27,green:0.39,blue:0.29):.gold }
    private var uiCard: Color { warmInterface ? Color(red:0.96,green:0.92,blue:0.85):.white.opacity(0.05) }
    private var uiBorder: Color { warmInterface ? Color(red:0.68,green:0.57,blue:0.37):.white.opacity(0.15) }
    private var phoneInterface: Bool { warmInterface && UIDevice.current.userInterfaceIdiom == .phone }
    private var displayedPlayer: Player { store.isBotActing ? (store.computer ?? store.state.current) : store.state.current }
    private var side: String { displayedPlayer == .one ? "黑方" : "白方" }
    private var turnTitle: String { store.state.status == .ongoing || store.isBotActing ? "輪到" + side + hero.title : "對戰結束" }
    private var presentedResult: String? { store.isBotActing ? nil : store.resultTitle }
    private var hero: HeroClass { store.state.heroClass(of: displayedPlayer) }
    private var complete: Bool { lesson?.isComplete(store.state) == true }
    var body: some View {
        GeometryReader { geo in
            Group { if inMatch { match(size: geo.size) } else { lobby(size: geo.size) } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(LinearGradient(colors: warmInterface ? [Color(red:0.82,green:0.88,blue:0.82),Color(red:0.96,green:0.92,blue:0.85)] : [Color(red:0.12,green:0.18,blue:0.21),Color(red:0.20,green:0.28,blue:0.28)],startPoint:.top,endPoint:.bottom).ignoresSafeArea())
        .foregroundStyle(uiInk).tint(uiAccent).preferredColorScheme(warmInterface ? .light:.dark)
        .sheet(isPresented: $showRules) { rules }
        .sheet(isPresented: $showTacticalHelp) { tacticalHelp }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingView { showOnboarding = false } }
        .sheet(isPresented: $showGrid) { accessibleGrid }
        .alert("離開目前對戰？", isPresented: $confirmExit) {
            Button("返回選角", role: .destructive) { store.leaveMatch(); inMatch = false; lesson = nil }.accessibilityIdentifier("exitMatchConfirmed")
            Button("留在對戰", role: .cancel) {}
        }
        .onDisappear { store.cancelBotWork(); store.setMatchAudioActive(false) }
        .onChange(of: inMatch) { _, active in store.setMatchAudioActive(active) }
        .onChange(of: scenePhase) { _, phase in
            store.setSceneAudioActive(phase == .active)
            if phase == .active && inMatch { store.scheduleComputerTurn() }
            else { store.cancelBotWork() }
        }
        .onChange(of:reduceMotion) {
            #if DEBUG || TACTICALGO_V11
            store.expansion?.stop()
            #endif
        }
        .sheet(isPresented: $showR2) {
            R2LabView { fixture, rules in
                if store.startR2(fixture,rules:rules) { lesson = nil; inMatch = true; store.setMatchAudioActive(true) }
            }
        }
        .sheet(isPresented: $showRecords, onDismiss: { if inMatch { store.scheduleComputerTurn() } }) {
            RecordLibraryView(store: store, resume: resumeRecord)
        }
        .sheet(isPresented: $showSoundSettings) {
            #if DEBUG || TACTICALGO_V11
            if let match = store.expansion { IntegratedExpansionSoundSettings(store:match,background:store.audio) }
            else { CombatSoundSettings(audio: store.audio) }
            #else
            CombatSoundSettings(audio: store.audio)
            #endif
        }
        .sheet(isPresented: $showBotLog) {
            NavigationStack {
                ScrollView { Text(store.botLastDecision.isEmpty ? "尚未完成電腦回合。" : store.botLastDecision).padding().accessibilityIdentifier("botDecisionLog") }
                    .navigationTitle("電腦決策紀錄")
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showBotLog = false } } }
            }
        }
        .onChange(of: store.state.current) { _, _ in
            if !store.isBotActing { UIAccessibility.post(notification: .announcement, argument: turnTitle) }
        }
        .overlay(alignment: .top) {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--integrated-review-audit"),let match = store.expansion { Text(match.audit).font(.system(size:8)).accessibilityIdentifier("integratedExpansionAudit") }
            if ProcessInfo.processInfo.arguments.contains("--integrated-audio-audit") {
                Text(audioAuditStatus).accessibilityIdentifier("integratedAudioAudit").padding().background(Color.ink)
            }
            #endif
        }
        .onAppear {
            store.setSceneAudioActive(scenePhase == .active)
            store.setMatchAudioActive(inMatch)
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--original-rules") { useExpansion = false }
            if let i = args.firstIndex(of:"--integrated-practice"),args.indices.contains(i+1),let value = ExpansionPractice(rawValue:args[i+1]) {
                store.expansionPractice(value); boardSize = store.size; one = store.state.heroClass(of:.one); two = store.state.heroClass(of:.two)
                inMatch = true; store.setMatchAudioActive(true)
            }
            if args.contains("--solo-warrior-review") {
                useExpansion = true;singlePlayer = true
                store.startExpansion(one:.warrior,two:.mage,size:9,monsters:.none,computer:.one)
                store.expansion?.warriorBotReview();store.expansion?.muted = false;boardSize = 9
                inMatch = true;store.setMatchAudioActive(true);store.scheduleComputerTurn()
            }
            if args.contains("--onboard") { showOnboarding = true }
            if args.contains("--integrated-audio-audit") { Task { audioAuditStatus = await IntegratedAudioAudit.run() } }
            if args.contains("--bot-delayed") { store.botDelayNanoseconds = 2_500_000_000 }
            // Leave enough time to open the native menu on a small/loaded simulator.
            if args.contains("--bot-late-result") {
                store.deliverCancelledBotResult = true
                store.botDelayNanoseconds = 30_000_000_000
            }
            if args.contains("--bot-step-review") { store.botReviewPhases = true }
            if args.contains("--play-bot") { singlePlayer = true; startMatch() }
            if args.contains("--bot-mage-motion-review") { singlePlayer = true; startMatch(); store.loadBotMageMotionReview() }
            if args.contains("--visual-pack-fixture") || args.contains("--visual-pack-invalid-fixture") {
                visualFixture = true
                visuals = .connectionFixture(invalid: args.contains("--visual-pack-invalid-fixture"))
            }
            if let i = args.firstIndex(of: "--practice"), args.indices.contains(i + 1), let value = PracticeLesson.allCases.first(where: { $0.rawValue == args[i + 1] }) { startPractice(value) }
            if args.contains("--play-nine") { boardSize = 9; startMatch() }
            if args.contains("--play-win") { startMatch(); store.loadWinningTurn() }
            if args.contains("--play-draw") { startMatch(); store.loadLastTurn() }
            if args.contains("--skill-screenshot") {
                store.loadSkillScreenshot(candidate: args.contains("--candidate-skills"), mage: args.contains("--mage-redeploy"))
                lesson = nil; inMatch = true
            }
            #endif
        }
    }
    private func lobby(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let wide = size.width >= 900 && size.width > size.height
        return ScrollView {
            VStack(spacing: tablet ? 22 : 18) {
                lobbyTitle
                #if DEBUG || TACTICALGO_V11
                if FileManager.default.fileExists(atPath: ExpansionLabStore.savedURL.path) {
                    Button("續玩 1.1 上局") {
                        if store.resumeExpansion() {
                            useExpansion = true; singlePlayer = store.computer != nil; humanSide = store.humanPlayer; one = store.state.heroClass(of:.one); two = store.state.heroClass(of:.two); boardSize = store.size
                            inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn()
                        }
                    }.accessibilityIdentifier("resumeExpansion")
                }
                #endif
                if let record = store.resumableRecord {
                    Button { resumeRecord(record) } label: { Label("續玩上局", systemImage: "play.circle").frame(maxWidth:.infinity,minHeight:40) }
                        .buttonStyle(.bordered).accessibilityIdentifier("resumeMatch")
                }
                Button("存局與棋譜") { store.refreshRecords(); showRecords = true }.accessibilityIdentifier("recordLibrary")
                if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
                if wide {
                    HStack(alignment: .top, spacing: 30) {
                        VStack(spacing: 18) { lobbySettings; boardSizePicker }
                            .padding(20).frame(width: 320)
                            .background(uiCard, in: RoundedRectangle(cornerRadius: 22))
                        VStack(spacing: 18) { heroChoices(portraitHeight: 180); chosenSkill; matchClasses }
                    }
                } else {
                    lobbySettings
                    heroChoices(portraitHeight: tablet ? 195 : 125)
                    chosenSkill; matchClasses; boardSizePicker
                }
                startControls.frame(maxWidth: wide ? 560 : .infinity)
                lobbyFooter
            }.padding(tablet ? 28 : 18)
                .frame(maxWidth: wide ? 1180 : tablet ? 760 : 650)
                .frame(maxWidth: .infinity)
        }
    }
    private var lobbyTitle: some View {
                VStack(spacing: 5) {
                    Text("TACTICAL GO").font(.system(size: 29, weight: .black, design: .rounded)).foregroundStyle(uiAccent)
                    Text("選擇英雄 · 包圍主將 · 一局決勝").font(.system(size: 14)).foregroundStyle(uiSecondary)
                }.padding(.top, 14)
    }
    private var lobbySettings: some View {
        VStack(spacing: 18) {
                Picker("對戰模式", selection: $singlePlayer) {
                    Text("本機雙人").tag(false); Text("電腦對戰").tag(true)
                }.pickerStyle(.segmented).accessibilityIdentifier("matchMode")
                    .onChange(of: singlePlayer) { _, solo in if solo { choosing = humanSide } }
                #if DEBUG || TACTICALGO_V11
                if useExpansion {
                    Picker("魔物戰場",selection:$monsters) { ForEach(ExpansionLabStore.Monsters.allCases,id:\.self) { Text($0.rawValue).tag($0) } }
                        .accessibilityIdentifier("matchMonsters")
                        .onChange(of:monsters) { _, value in if value != .none { boardSize = 9 } }
                }
                #endif
                if singlePlayer {
                    Picker("你執哪方", selection: $humanSide) {
                        Text("黑方先手").tag(Player.one); Text("白方後手").tag(Player.two)
                    }.pickerStyle(.segmented).accessibilityIdentifier("humanSide")
                        .onChange(of: humanSide) { _, side in choosing = side }
                    Picker("電腦難度", selection: Binding(get: { store.botDifficulty }, set: { store.setBotDifficulty($0) })) {
                        Text("簡單").tag(BotDifficulty.easy)
                        Text("標準").tag(BotDifficulty.standard)
                    }.pickerStyle(.segmented).accessibilityIdentifier("botDifficulty")
                    Text(store.botDifficulty == .easy ? "適合先熟悉四職技能與主將攻守。" : "會預判你的反擊，適合挑戰。")
                        .font(.system(size: 12)).foregroundStyle(uiSecondary)
                }
                if !useExpansion {
                Picker("技能規則", selection: $selectedRules) {
                    Text("原版").tag(RecordRules.original)
                    Text("候選技能").tag(RecordRules.redeployment)
                }.pickerStyle(.segmented).accessibilityIdentifier("matchRules")
                Text(selectedRules == .redeployment ? "戰士沿棋群築壘；法師可調度己兵。費用與每回合限制相同。" : "原版技能；你也可以保留原局，建立候選續玩副本。")
                    .font(.caption).foregroundStyle(uiSecondary)
                }
                Picker("選擇哪一方", selection: $choosing) {
                    Text(singlePlayer ? (humanSide == .one ? "你 · 黑方 ●" : "電腦 · 黑方 ●") : "黑方 ●").tag(Player.one)
                    Text(singlePlayer ? (humanSide == .two ? "你 · 白方 ○" : "電腦 · 白方 ○") : "白方 ○").tag(Player.two)
                }.pickerStyle(.segmented).accessibilityIdentifier("choosingTeam")
        }
    }
    private func heroChoices(portraitHeight: CGFloat) -> some View {
                HStack(spacing: 8) {
                    ForEach(heroes, id: \.self) { h in
                        let selected = (choosing == .one ? one : two) == h
                        Button {
                            if choosing == .one { one = h } else { two = h }
                        } label: {
                            VStack(spacing: 7) {
                                Image(uiImage: portrait(h)).resizable().scaledToFit().frame(height: portraitHeight)
                                Text(h.title).font(.system(size: 17, weight: .bold))
                                Text(h.skillTitle).font(.system(size: 12, weight: .semibold)).lineLimit(1)
                            }.frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(selected ? uiAccent.opacity(0.15) : uiCard, in: RoundedRectangle(cornerRadius: 18))
                                .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? uiAccent : uiBorder, lineWidth: selected ? 2 : 1))
                        }.buttonStyle(.plain).accessibilityIdentifier("choose-" + h.art)
                            .accessibilityLabel(h.title + "，" + h.skillTitle).accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }
    }
    @ViewBuilder private var chosenSkill: some View {
                let choice = choosing == .one ? one : two
                VStack(spacing: 6) {
                    Text(choice.skillHelp).font(.system(size: 14))
                    Text("召喚 \(choice.summonCost) 能量 · 技能 1 AP＋2 能量 · 每回合一次").font(.system(size: 11)).foregroundStyle(uiAccent)
                }.frame(minHeight: 45)
    }
    private var matchClasses: some View {
                HStack {
                    Text("黑方 · \(one.title)").foregroundStyle(uiAccent)
                    Spacer(); Text("VS").font(.caption.bold()).foregroundStyle(.secondary); Spacer()
                    Text("白方 · \(two.title)").foregroundStyle(uiInk)
                }.font(.system(size: 14, weight: .bold)).accessibilityIdentifier("matchClasses")
    }
    private var boardSizePicker: some View {
                Picker("棋盤", selection: $boardSize) { Text("7 × 7").tag(7); Text("9 × 9").tag(9) }.pickerStyle(.segmented).accessibilityIdentifier("playBoardSize")
    }
    private var startControls: some View {
        VStack(spacing: 18) {
                Button { showOnboarding = true } label: {
                    Label("新手教學 · 不需要懂圍棋", systemImage: "hand.tap")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(.bordered).accessibilityIdentifier("startOnboarding")
                Button(action: startMatch) { Label(singlePlayer ? "開始電腦對戰" : "開始本機雙人對戰", systemImage: "play.fill").frame(maxWidth: .infinity).frame(minHeight: 46) }
                    .buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink).font(.system(size: 16, weight: .bold)).accessibilityIdentifier("startMatch")
                HStack {
                    Menu {
                        ForEach(PracticeLesson.allCases) { value in Button(value.rawValue) { startPractice(value) } }
                        #if DEBUG || TACTICALGO_V11
                        ForEach(ExpansionPractice.allCases,id:\.self) { value in
                            Button(value.hero.title + " · 擴充技能") {
                                store.expansionPractice(value); boardSize = store.size; one = store.state.heroClass(of:.one); two = store.state.heroClass(of:.two)
                                lesson = nil; inMatch = true; store.setMatchAudioActive(true)
                            }
                        }
                        Button("牧師：奉獻救援挑戰") {
                            store.expansionChallenge(); boardSize = store.size; one = .priest; two = .mage
                            lesson = nil; inMatch = true; store.setMatchAudioActive(true)
                        }.accessibilityIdentifier("priestChallenge")
                        #endif
                    } label: { Label("玩法練習", systemImage: "graduationcap") }
                    Spacer(); Button("技能試驗") { showR2 = true }.accessibilityIdentifier("r2Lab")
                    Button("遊戲規則") { showRules = true }
                }.font(.system(size: 14)).frame(minHeight: 44)
        }
    }
    private var lobbyFooter: some View {
                Text(singlePlayer ? "單人 \(boardSize)×\(boardSize)：你執\(humanSide == .one ? "黑" : "白")方，電腦執\(humanSide == .one ? "白" : "黑")方。\n黑方首回合 1 AP，之後每回合 2 AP。" : "兩人共用這台裝置，黑方先手。\n首回合 1 AP，之後每回合 2 AP。")
                    .multilineTextAlignment(.center).font(.system(size:12)).foregroundStyle(uiSecondary)
    }
    private func match(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let wide = size.width >= 900 && size.width > size.height
        let phoneNine = UIDevice.current.userInterfaceIdiom == .phone && store.size == 9 && store.state.config.expansionSkills
        let width = min(size.width - (tablet ? 48 : phoneNine ? 12 : 24), wide ? 1220 : tablet ? 736 : 626)
        let phoneLayout = PhoneMatchLayout(width:Double(size.width),height:Double(size.height))
        let height = min(tablet ? width*0.90:size.width*0.92,max(170,size.height-(tablet ? 518:410)))
        return VStack(spacing: phoneInterface ? 4:tablet ? 14:6) {
            matchHeader.frame(height:phoneInterface ? 40:nil)
            if wide {
                HStack(alignment: .center, spacing: 24) {
                    let boardWidth = min(width - 344, max(240, (size.height - 110) / 0.90))
                    board.frame(width: boardWidth, height: boardWidth * 0.90)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ScrollView {
                        VStack(spacing: 16) {
                            playerStrip(.one); playerStrip(.two)
                            botStatus; matchBanners
                            actionPanel(tablet: true, sidebar: true)
                        }.padding(18)
                    }.frame(width: 320)
                        .background(uiCard, in: RoundedRectangle(cornerRadius:22))

                }
            } else if phoneInterface {
                HStack(spacing:8) { playerStrip(.one);playerStrip(.two) }.frame(height:48)
                phoneStateBar.frame(height:20)
                board.frame(width:phoneLayout.width,height:phoneLayout.boardHeight)
                    .frame(maxWidth:.infinity)
                phoneNineActionPanel.frame(height:200,alignment:.top)
            } else {
                HStack(spacing:8) { playerStrip(.one);playerStrip(.two) }
                botStatus;matchBanners
                board.frame(width:tablet ? min(width,height/0.90):width,height:height).frame(maxWidth:.infinity)
                actionPanel(tablet:tablet,sidebar:false)
            }
        }.font(.system(size: tablet ? 16 : 14))
            .padding(.horizontal,tablet ? 24:phoneInterface ? 6:12).padding(.vertical,phoneInterface ? 4:tablet ? 16:6)
            .frame(maxWidth: wide ? 1268 : tablet ? 784 : 650)

    }
    private var matchHeader: some View {
            HStack {
                Button { confirmExit = true } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).frame(width: 38, height: 36) }.accessibilityLabel("返回選角")
                VStack(alignment: .leading, spacing: 2) {
                    Text(turnTitle).font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(displayedPlayer == .one ? uiAccent:uiInk)
                        .lineLimit(1).minimumScaleFactor(0.80).accessibilityIdentifier("currentTurn")
                    Text(lesson?.rawValue ?? "第 \(store.state.ply) 回合 · \(store.computer == nil ? "本機雙人" : "單人・你執\(store.humanPlayer == .one ? "黑" : "白")")")
                        .font(.system(size: 11)).foregroundStyle(uiSecondary)
                }
                Spacer()
                Menu {
                    if !store.state.config.expansionSkills {
                        Button("複製此局測候選技能") {
                            if store.createCandidateCopy() { selectedRules = .redeployment }
                        }.disabled(!store.canCreateCandidateCopy).accessibilityIdentifier("candidateCopy")
                    }
                    Button("復原", action: store.undo).disabled(!store.canUndoHumanDecision)
                    Button("格點清單") { showGrid = true }
                    Button("遊戲規則") { showRules = true }
                    Button("重新開始") {
                        if let fixture = store.r2Fixture { _ = store.startR2(fixture,rules:store.r2Rules) }
                        else if let lesson { startPractice(lesson) } else { startMatch() }
                    }
                    #if DEBUG || TACTICALGO_V11
                    if let match = store.expansion {
                        Button("保存對局") { match.saveCandidate() }.accessibilityIdentifier("saveExpansion")
                    } else {
                        Button("存局與棋譜") { store.cancelBotWork(); store.refreshRecords(); showRecords = true }.accessibilityIdentifier("matchRecords")
                    }
                    #else
                    Button("存局與棋譜") { store.cancelBotWork(); store.refreshRecords(); showRecords = true }.accessibilityIdentifier("matchRecords")
                    #endif
                    Button("聲音設定") { showSoundSettings = true }.accessibilityIdentifier("audioSettings")
                    if store.computer != nil {
                        Button(store.botDifficulty == .easy ? "難度：簡單 ✓" : "改為簡單") { store.setBotDifficulty(.easy) }
                            .accessibilityIdentifier("difficulty-easy")
                        Button(store.botDifficulty == .standard ? "難度：標準 ✓" : "改為標準") { store.setBotDifficulty(.standard) }
                            .accessibilityIdentifier("difficulty-standard")
                    }
                    #if DEBUG || TACTICALGO_V11
                    if store.computer != nil { Button("電腦決策紀錄") { showBotLog = true } }
                    #endif
                } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)).frame(width: 38, height: 36) }.accessibilityLabel("對戰選單")
            }
    }
    @ViewBuilder private var botStatus: some View {
            if store.computer != nil {
                HStack(spacing: 6) {
                    if store.isBotThinking { ProgressView().controlSize(.small) }
                    Text(store.isBotThinking ? "電腦思考中" : store.isBotActing ? "電腦下棋中 · \(store.botActionIndex)/\(store.botActionCount)" : store.state.status == .ongoing ? "你的回合 · \(store.humanPlayer == .one ? "黑方" : "白方")" : "對戰完成")
                        .font(.system(size: 12, weight: .semibold))
                    if store.isBotActing {
                        Text(store.botMotionStartedAt == nil ? "準備" : "落定")
                            .font(.system(size: 11)).foregroundStyle(uiAccent)
                            .accessibilityIdentifier("botActionStatus")
                            .accessibilityValue("\(store.botActionIndex)/\(store.botActionCount) \(store.botActionLabel)")
                    }
                    Spacer()
                    Text(store.botDifficulty == .easy ? "簡單" : "標準").font(.system(size: 11)).foregroundStyle(uiAccent)
                }.frame(height: 22).accessibilityElement(children: .combine).accessibilityIdentifier("botStatus")
                    .accessibilityValue("已完成\(store.botTurnsCompleted)電腦回合")
            }
    }
    @ViewBuilder private var phoneStateBar: some View {
        if let title = presentedResult {
            HStack { Image(systemName:"crown.fill");Text(title).bold();Spacer();Button("再玩一局",action:startMatch) }
                .font(.system(size:12)).accessibilityIdentifier("matchResult")
        } else if complete {
            HStack { Text("練習完成").bold();Spacer();Button("回到選角") { inMatch = false;lesson = nil } }
                .font(.system(size:12)).accessibilityIdentifier("practiceComplete")
        } else if store.computer != nil { botStatus }
        else { Text(store.recordErrorMessage ?? "點選目標 · 預覽後確認").font(.system(size:12)).foregroundStyle(uiSecondary).frame(maxWidth:.infinity,alignment:.leading) }
    }
    @ViewBuilder private var matchBanners: some View {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--integrated-review-audit"),let match = store.expansion {
                Text(match.audit).font(.system(size:8)).accessibilityIdentifier("integratedExpansionAudit")
            }
            #endif
            if store.recordRules == .redeployment {
                Text("候選技能 · 沿棋群築壘／法師調度己兵")
                    .font(.caption).foregroundStyle(uiAccent).accessibilityIdentifier("candidateRulesBanner")
            }
            if store.r2Fixture != nil { Text("R2 \(store.r2Rules.variant) 試驗 · \(store.r2Rules.labDescription)").font(.caption).foregroundStyle(uiAccent).accessibilityIdentifier("r2Banner") }
            if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
            if let title = presentedResult {
                HStack { Image(systemName: "crown.fill"); Text(title).font(.system(size: 16, weight: .bold)); Spacer(); Button("再玩一局", action: startMatch) }
                    .padding(9).background(Color.gold.opacity(0.18), in: RoundedRectangle(cornerRadius: 10)).accessibilityIdentifier("matchResult")
            }
            if complete {
                HStack { Image(systemName: "checkmark.circle.fill"); Text("練習完成").bold(); Spacer(); Button("回到選角") { inMatch = false; lesson = nil } }
                    .font(.system(size: 14)).padding(8).background(Color.green.opacity(0.25), in: RoundedRectangle(cornerRadius: 10)).accessibilityIdentifier("practiceComplete")
            }
    }
    private func actionPanel(tablet: Bool, sidebar: Bool) -> some View {
        VStack(spacing: tablet ? 12 : 6) {
            Group {
                HStack(spacing: 9) {
                    Image(uiImage: portrait(hero)).resizable().scaledToFit().frame(width: tablet ? 72 : 48, height: tablet ? 72 : 48)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(hero.title + " · " + (store.mode == .advanced ? advancedTitle : hero.skillTitle)).font(.system(size: tablet ? 18 : 14, weight: .bold)).lineLimit(1)
                        Text(modeHelp).font(.system(size: tablet ? 15 : 12)).foregroundStyle(uiSecondary).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }.frame(minHeight: 50)
            }
            Text(complete ? "已完成目標；可以復原重試或回到選角。" : store.message)
                .font(.system(size: tablet ? 15 : 12)).foregroundStyle(uiAccent).frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                .accessibilityIdentifier("playMessage")
                .accessibilityValue(store.isBotActing ? "\(store.botActionIndex)/\(store.botActionCount) \(store.botMotionStartedAt == nil ? "準備" : "落定")" : "")
            if store.mode == .skill && hero == .mage && store.state.config.experimentalFriendlyRedeploy {
                Picker("魔法之手方式", selection: Binding(get: { store.mageOperation }, set: { store.changeMageOperation($0) })) {
                    ForEach(GameStore.MageOperation.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).accessibilityIdentifier("mageOperation")
            }
            if store.mode == .skill && hero == .mage && store.mageOperation == .push && store.selected.first != nil {
                HStack(spacing: 6) {
                    ForEach(PushDirection.allCases, id: \.self) { direction in
                        Button { store.chooseDirection(direction) } label: {
                            Label(direction.title, systemImage: direction.symbol).frame(maxWidth: .infinity).frame(minHeight: tablet ? 48 : 38)
                        }.buttonStyle(.bordered).tint(store.pushDirection == direction ? uiAccent:uiSecondary)
                            .disabled(store.inputLocked || !store.availableDirections.contains(direction)).accessibilityIdentifier("push-" + direction.rawValue)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    ForEach(availableModes.filter { $0 != .advanced && $0 != .loot }, id: \.self) { mode in
                        Button { store.changeMode(mode) } label: {
                            Text(mode == .skill ? hero.skillTitle : mode.rawValue).font(.system(size: tablet ? 16 : 13, weight: .bold)).frame(maxWidth: .infinity).frame(minHeight: tablet ? 48 : 38)
                        }.buttonStyle(.bordered).tint(store.mode == mode ? uiAccent:uiSecondary)
                            .disabled(store.state.status != .ongoing || store.inputLocked).accessibilityIdentifier("mode-" + String(describing: mode))
                    }
                }
            }
            #if DEBUG || TACTICALGO_V11
            if let match = store.expansion {
                HStack(spacing:8) {
                    if hero != .priest {
                        Button { store.changeMode(.advanced) } label: { Text(advancedTitle).frame(maxWidth:.infinity,minHeight:38) }
                            .buttonStyle(.bordered).tint(store.mode == .advanced ? uiAccent:uiSecondary).disabled(store.inputLocked || store.state.status != .ongoing).accessibilityIdentifier("mode-advanced")
                    }
                    ForEach(store.state.lootInventory(of:store.state.current),id:\.ability) { loot in
                        Button {
                            store.changeMode(.loot); match.ability = loot.ability
                        } label: { Text(loot.ability == .stickyBounce ? "黏彈":"影步").frame(minHeight:38) }
                            .buttonStyle(.bordered).tint(store.mode == .loot && match.ability == loot.ability ? uiAccent:uiSecondary)
                            .disabled(store.inputLocked || store.state.ply < loot.unlockPly || store.state.status != .ongoing)
                            .accessibilityIdentifier("loot-"+loot.ability.rawValue)
                    }
                }
                if let instruction = match.instruction { Text(instruction).font(.caption).foregroundStyle(uiAccent) }
                if match.challenge {
                    Button(match.showHint ? "隱藏提示":"查看提示") { match.showHint.toggle() }.accessibilityIdentifier("priestHint")
                    if match.showHint { Text(PriestSanctuaryChallenge.hint).font(.caption) }
                }
            }
            #endif
            if sidebar {
                Button(action: store.confirm) { Text("確認行動").bold().frame(maxWidth: .infinity, minHeight: 48) }
                    .buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink)
                    .disabled(store.inputLocked || store.preview?.success != true).accessibilityIdentifier("playConfirm")
                HStack(spacing: 10) {
                    Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                        Text(store.selected.isEmpty ? "復原" : "取消").frame(maxWidth: .infinity, minHeight: 46)
                    }.buttonStyle(.bordered).disabled(store.selected.isEmpty && !store.canUndoHumanDecision).accessibilityIdentifier("undoOrCancel")
                    Button(action: store.endTurn) { Text("結束回合").frame(maxWidth: .infinity, minHeight: 46) }
                        .buttonStyle(.bordered).disabled(store.state.status != .ongoing || store.inputLocked || lesson != nil).accessibilityIdentifier("playEndTurn")
                }
            } else {
            HStack(spacing: 8) {
                Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                    Text(store.selected.isEmpty ? "復原" : "取消").frame(minWidth: 48, minHeight: tablet ? 48 : 40)
                }.buttonStyle(.bordered).disabled(store.selected.isEmpty && !store.canUndoHumanDecision).accessibilityIdentifier("undoOrCancel")
                Button(action: store.confirm) { Text("確認").bold().frame(maxWidth: .infinity, minHeight: tablet ? 48 : 40) }
                    .buttonStyle(.borderedProminent).tint(Color.gold).foregroundStyle(Color.ink)
                    .disabled(store.inputLocked || store.preview?.success != true).accessibilityIdentifier("playConfirm")
                Button(action: store.endTurn) { Text("結束回合").frame(minHeight: tablet ? 48 : 40) }.buttonStyle(.bordered)
                    .disabled(store.state.status != .ongoing || store.inputLocked || lesson != nil).accessibilityIdentifier("playEndTurn")
            }
            }
        }
    }
    private func phoneAction(_ title: String,id:String,selected:Bool=false,disabled:Bool=false,action:@escaping ()->Void)->some View {
        Button(action:action) { Text(title).font(.system(size:13,weight:.bold)).lineLimit(1).minimumScaleFactor(0.8).frame(maxWidth:.infinity,minHeight:44) }
            .buttonStyle(.plain).foregroundStyle(selected ? Color.white:uiInk)
            .background(selected ? uiAccent:uiCard,in:RoundedRectangle(cornerRadius:10))
            .overlay(RoundedRectangle(cornerRadius:10).stroke(selected ? uiAccent:uiBorder.opacity(0.50),lineWidth:1))
            .opacity(disabled ? 0.55:1).disabled(disabled).accessibilityIdentifier(id)
    }
    private var phoneNineActionPanel: some View {
        VStack(spacing:4) {
            HStack(spacing:8) {
                Image(uiImage:portrait(hero)).resizable().scaledToFit().frame(width:24,height:24)
                Text(hero.title + " · " + (store.mode == .advanced ? advancedTitle:hero.skillTitle)).font(.system(size:14,weight:.bold))
                Spacer(minLength:0)
                #if DEBUG || TACTICALGO_V11
                if store.expansion?.challenge == true { Button("提示") { store.expansion?.showHint = true;showTacticalHelp = true }.font(.caption).accessibilityIdentifier("priestHint") }
                #endif
                Button { showTacticalHelp = true } label: { Image(systemName:"info.circle").frame(width:28,height:24) }
                    .accessibilityLabel("技能說明").accessibilityIdentifier("tacticalHelp")
            }.frame(height:24)
            Text(store.message).font(.system(size:12)).foregroundStyle(uiAccent).lineLimit(1)
                .frame(maxWidth:.infinity,minHeight:16,maxHeight:16,alignment:.leading).accessibilityIdentifier("playMessage")
                .accessibilityValue(store.isBotActing ? "\(store.botActionIndex)/\(store.botActionCount) \(store.botMotionStartedAt == nil ? "準備" : "落定")":"")
            HStack(spacing:6) {
                if store.mode == .skill && hero == .mage && store.selected.first != nil {
                    ForEach(PushDirection.allCases,id:\.self) { direction in
                        phoneAction(direction.title,id:"push-"+direction.rawValue,disabled:store.inputLocked || !store.availableDirections.contains(direction)) { store.chooseDirection(direction) }
                    }
                } else {
                    ForEach(availableModes.filter { $0 != .advanced && $0 != .loot },id:\.self) { mode in
                        phoneAction(mode == .skill ? hero.skillTitle:mode.rawValue,id:"mode-"+String(describing:mode),selected:store.mode == mode,disabled:store.inputLocked || store.state.status != .ongoing) { store.changeMode(mode) }
                    }
                }
            }
            Group {
            #if DEBUG || TACTICALGO_V11
            if let match = store.expansion {
                if hero != .priest || !store.state.lootInventory(of:store.state.current).isEmpty {
                    HStack(spacing:6) {
                        if hero != .priest {
                            phoneAction(advancedTitle,id:"mode-advanced",selected:store.mode == .advanced,disabled:store.inputLocked || store.state.status != .ongoing) { store.changeMode(.advanced) }
                        }
                        ForEach(store.state.lootInventory(of:store.state.current),id:\.ability) { loot in
                            phoneAction(loot.ability == .stickyBounce ? "黏彈":"影步",id:"loot-"+loot.ability.rawValue,selected:store.mode == .loot && match.ability == loot.ability,disabled:store.inputLocked || store.state.ply < loot.unlockPly || store.state.status != .ongoing) { store.changeMode(.loot);match.ability = loot.ability }
                        }
                    }
                }
                else { Text("奉獻 · 打開氣與眼").font(.system(size:12)).foregroundStyle(uiSecondary) }
            }
            #endif
            }.frame(height:44)
            HStack(spacing:6) {
                phoneAction(store.selected.isEmpty ? "復原":"取消",id:"undoOrCancel",disabled:store.selected.isEmpty && !store.canUndoHumanDecision) { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } }
                phoneAction("確認",id:"playConfirm",selected:store.preview?.success == true,disabled:store.inputLocked || store.preview?.success != true) { store.confirm() }
                phoneAction("結束回合",id:"playEndTurn",disabled:store.inputLocked || store.state.status != .ongoing || lesson != nil) { store.endTurn() }
            }
        }.padding(.horizontal,6).padding(.vertical,6)
            .background(uiCard.opacity(0.80),in:RoundedRectangle(cornerRadius:14))
    }
    private var tacticalHelp: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Text(modeHelp)
                    #if DEBUG || TACTICALGO_V11
                    if let match = store.expansion {
                        if let instruction = match.instruction { Text(instruction) }
                        if match.challenge && match.showHint { Text(PriestSanctuaryChallenge.hint) }
                    }
                    #endif
                    Text("先選擇棋盤上的目標，查看合法預覽，再按確認。取消不扣資源，復原可以還原上一個行動。")
                }.padding()
            }.navigationTitle("技能說明")
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("完成") { showTacticalHelp = false }.accessibilityIdentifier("tacticalHelpDone") } }
        }
    }
    private var availableModes: [GameStore.Mode] {
        store.state.config.expansionSkills ? [.soldier,.summon,.skill] + (hero == .priest ? []:[.advanced]) + (store.state.lootInventory(of:store.state.current).isEmpty ? []:[.loot]) : [.soldier,.summon,.skill]
    }
    private var advancedTitle: String {
        switch hero { case .warrior: "戰線重整"; case .mage: "雙重牽引"; case .rogue: "連鎖換位"; case .priest,.none: "第二技能" }
    }
    private func playerStrip(_ player: Player) -> some View {
        let state = store.state, active = displayedPlayer == player
        let commander = state.board.find(player, .commander)
        let liberties = commander.map { state.board.liberties(at: $0).count } ?? 0
        return VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text((player == .one ? "● 黑方 " : "○ 白方 ") + state.heroClass(of: player).title).fontWeight(.bold)
                Spacer(minLength: 0)
                Text(state.status == .ongoing || store.isBotActing ? (active ? "行動中" : "等待") : "已結束")
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(active ? uiAccent:uiSecondary)
            }
            HStack(spacing: 4) {
                if store.computer != nil {
                    Text(player == store.computer ? "電腦" : "你")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(uiAccent)
                }
                Text("能量 \(state.mana(of: player))/\(state.config.manaCap) · \(liberties) 氣")
                    .font(.system(size: 11)).foregroundStyle(liberties <= 1 ? Color.redTeam:uiSecondary)
                Spacer(minLength: 0)
                if active { Text("\(store.isBotActing && state.current != player ? 0 : state.apRemaining) AP").font(.system(size: 11, weight: .bold)) }
            }
            if !phoneInterface && !state.lootInventory(of:player).isEmpty {
                Text(state.lootInventory(of:player).map { ($0.ability == .stickyBounce ? "黏彈":"影步") + (state.ply < $0.unlockPly ? "待解鎖":"×1") }.joined(separator:" · ")).font(.system(size:10)).foregroundStyle(uiAccent)
            }
        }.font(.system(size:12)).padding(phoneInterface ? 6:8)
            .frame(maxWidth:.infinity)
            .background(warmInterface ? (active ? uiCard:uiCard.opacity(0.55)) : (active ? Color.white.opacity(0.10):.white.opacity(0.04)),in:RoundedRectangle(cornerRadius:10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? uiAccent:uiBorder.opacity(0.35), lineWidth: 1))
            .accessibilityElement(children:.combine)
            .accessibilityValue("能量 \(state.mana(of:player))/\(state.config.manaCap) · \(active ? state.apRemaining : 0) AP · \(liberties) 氣")
            .accessibilityIdentifier(player == .one ? "blueResources" : "redResources")
    }
    private var board: some View {
        let data = BoardPresentation(state: store.state, selected: store.selected, legal: store.legalTargets, preview: store.preview)
        return ZStack(alignment: .topTrailing) {
            Group {
                #if DEBUG || TACTICALGO_V11
                if let match = store.expansion,let assets = match.assets {
                    TimelineView(.animation(minimumInterval:1.0/60,paused:!match.playing)) { _ in
                        ExpansionBoard(store:match,assets:assets,time:ProcessInfo.processInfo.systemUptime-match.started,reduced:reduceMotion || match.reduced,identityPrefix:"play-cell",focusedNine:store.size == 9 && UIDevice.current.userInterfaceIdiom == .phone,focusedPhone:phoneInterface)
                    }.clipped().accessibilityElement(children:.contain).accessibilityIdentifier("playArena")
                } else {
                SwiftBoard(visuals: visuals, presentation: data, computerAction: store.botAction,
                    motion: store.isBotActing && store.botMotionStartedAt != nil ? store.playback : nil,
                    motionStartedAt: store.botMotionStartedAt, reducedMotion: reduceMotion, select: store.select)
                    .accessibilityElement(children: .ignore).accessibilityIdentifier("playArena")
                    .accessibilityLabel("\(store.size)乘\(store.size)棋盤")
                    .accessibilityValue(store.selected.map(coordinate).joined(separator: ","))
                }
                #else
            SwiftBoard(visuals: visuals, presentation: data, computerAction: store.botAction,
                motion: store.isBotActing && store.botMotionStartedAt != nil ? store.playback : nil,
                motionStartedAt: store.botMotionStartedAt, reducedMotion: reduceMotion, select: store.select)
                .accessibilityElement(children: .ignore).accessibilityIdentifier("playArena")
                .accessibilityLabel("\(store.size)乘\(store.size)棋盤")
                .accessibilityValue(store.selected.map(coordinate).joined(separator: ","))
                #endif
            }
            #if DEBUG || TACTICALGO_V11
            if store.botReviewPhases && store.isBotActing {
                Button("下一演出階段") { store.advanceBotReviewPhase() }
                    .font(.system(size: 10)).padding(5).background(Color.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .accessibilityIdentifier("botReviewAdvance")
            }
            if store.deliverCancelledBotResult {
                Text("完成\(store.botTurnsCompleted)／作廢\(store.botDiscardedDecisions)")
                    .font(.system(size: 10)).padding(5).background(Color.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .accessibilityIdentifier("botDebugStatus").allowsHitTesting(false)
            }
            #endif
            if visualFixture {
                Text(visuals.diagnostic == nil ? "素材接線：" + visuals.pack.id : "素材拒絕，保留原圖")
                    .font(.system(size: 10)).padding(5).background(Color.ink)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .accessibilityIdentifier("visualPackStatus").allowsHitTesting(false)
            }
            Button { showGrid = true } label: { Image(systemName: "square.grid.3x3").font(.system(size: 16)).padding(10) }
                .accessibilityLabel("以格點清單操作棋盤")
        }
    }
    private var modeHelp: String {
        if store.isBotActing { return store.botActionLabel }
        if let lesson { return lesson.instruction }
        switch store.mode {
        case .soldier: return "點空格放士兵 · 1 AP · 先預覽再確認"
        case .summon: return "選己方棋子旁的空點 · 1 AP＋\(hero.summonCost) 能量"
        case .skill:
            if hero == .warrior, store.state.config.bastionScope == .connectedGroup { return "施放前原棋串旁兩個不同空點。1 AP＋2 能量" }
            if hero == .mage, store.state.config.experimentalFriendlyRedeploy, store.mageOperation == .redeploy { return "先選英雄兩格內的相連己兵，再選原棋群旁空點。1 AP＋2 能量" }
            if hero == .mage, store.state.config.magicHandDestination == .opposingSoldierExchange { return "推入相鄰空點，或交換異色普通士兵。1 AP＋2 能量" }
            return hero.skillHelp + " 1 AP＋2 能量"
        case .advanced, .loot:
            #if DEBUG || TACTICALGO_V11
            if let match = store.expansion { return match.help + (store.mode == .advanced ? " 1 AP＋\(match.advancedCost) 能量":" 1 AP／0 能量") }
            return "選擇目標後確認。"
            #else
            return "選擇目標後確認。"
            #endif
        }
    }
    private var accessibleGrid: some View {
        NavigationStack {
            List(store.state.board.points, id: \.self) { point in
                Button {
                    store.select(point); showGrid = false
                } label: {
                    HStack { Text(coordinate(point)); Text(cellDescription(point)); Spacer(); if store.legalTargets.contains(point) { Text("可選").foregroundStyle(.green) } }
                }.accessibilityIdentifier("cell-\(point.x)-\(point.y)")
            }.navigationTitle("選擇棋盤格點")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showGrid = false } } }
        }
    }
    private var rules: some View {
        NavigationStack {
            List {
                Section("勝利") { Text("包圍敵方主將所在的棋串，使它沒有相鄰空點（氣），提走主將即可獲勝。斜角不算相鄰。") }
                Section("回合與資源") { Text("首回合 1 AP，其後 2 AP。每次行動 1 AP；耗盡 AP 自動換手。每回合增加 1 能量，上限 6。也可提早結束回合。100 回合未分勝負則和局。") }
                Section("英雄") { Text("召喚在任一己方棋子相鄰空點。戰士與盜賊需 2 能量，法師需 3。英雄被提走後，本局不能再召喚。") }
                ForEach(heroes, id: \.self) { h in Section(h.title + " · " + h.skillTitle) { Text(h.skillHelp + "\n技能需 1 AP＋2 能量，每回合只能使用一次。") } }
                if useExpansion {
                    Section("第二技能與魔物") { Text("三職第二技能需要1 AP＋4能量。原技能、第二技能和戰利能力每回合共用一次；魔物能力要到下一個己方回合才解鎖。魔物占據交叉點、阻擋氣；正鄰己子至少兩格且多於對手，可花1 AP討伐。暗影狼還需要正鄰己方英雄。") }
                }
                Section("合法行動") { Text("先處理敵方提子，再檢查己方是否無氣。禁止自殺與重複任何先前盤面。預覽不扣資源；復原會還原完整盤面、回合、資源與歷史。") }
            }.navigationTitle("遊戲規則").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showRules = false } } }
        }
    }
    private func coordinate(_ p: Point) -> String { String(UnicodeScalar(65 + p.x)!) + String(p.y + 1) }
    private func cellDescription(_ p: Point) -> String {
        if store.state.board.monsters.contains(p) { return store.state.config.monsterBattlefield?.kind(at:p) == .slime ? "史萊姆，點選討伐" : "暗影狼，點選討伐" }
        guard let piece = store.state.board[p] else { return "空點" }
        return (piece.owner == .one ? "黑方 " : "白方 ") + (piece.kind == .hero ? store.state.heroClass(of: piece.owner).title : piece.kind == .commander ? "主將" : "士兵")
    }
    private func resumeRecord(_ record: MatchRecord) {
        if store.resume(record) {
            one = record.one; two = record.two; boardSize = record.size; selectedRules = record.rules
            singlePlayer = record.computer != nil; humanSide = record.computer?.opponent ?? .one
            lesson = nil; inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn()
        }
    }
    private func startMatch() {
        #if DEBUG || TACTICALGO_V11
        if useExpansion {
            store.startExpansion(one:one,two:two,size:boardSize,monsters:monsters,computer:singlePlayer ? humanSide.opponent:nil)
            boardSize = store.size; lesson = nil; inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn(); return
        }
        #endif
        store.size = singlePlayer ? 7 : boardSize; store.newMatch(classOne: one, classTwo: two, computer: singlePlayer ? humanSide.opponent : nil, rules: selectedRules)
        lesson = nil; inMatch = true; store.setMatchAudioActive(true)
        store.scheduleComputerTurn()
    }
    private func startPractice(_ value: PracticeLesson) { lesson = value; store.startPractice(value); inMatch = true; store.setMatchAudioActive(true) }
}

#if DEBUG || TACTICALGO_V11
private struct IntegratedExpansionSoundSettings: View {
    @Bindable var store: ExpansionLabStore
    @Bindable var background: CombatAudio
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Toggle("靜音",isOn:$store.muted).accessibilityIdentifier("audioMute").onChange(of:store.muted) { background.muted = store.muted; store.stop() }
                Toggle("英文施法語音",isOn:$store.voice).accessibilityIdentifier("castVoice").onChange(of:store.voice) { store.stop() }
                Toggle("減少動態",isOn:$store.reduced).accessibilityIdentifier("reduceCombatMotion").onChange(of:store.reduced) { store.stop() }
                Section("背景音樂") { Slider(value:$background.musicVolume,in:0...1).accessibilityIdentifier("musicVolume") }
            }.navigationTitle("聲音與動畫").toolbar { Button("完成") { dismiss() }.accessibilityIdentifier("audioSettingsDone") }
        }
    }
}
#endif

private struct CombatSoundSettings: View {
    @Bindable var audio: CombatAudio
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Toggle("靜音", isOn: $audio.muted).accessibilityIdentifier("audioMute")
                Section("音效音量") {
                    Slider(value: $audio.sfxVolume, in: 0...1).accessibilityIdentifier("sfxVolume")
                    Text("\(Int(audio.sfxVolume * 100))%")
                }
                Section("音樂音量") {
                    Text("對戰曲：Hearthside Council").font(.caption)
                    Slider(value: $audio.musicVolume, in: 0...1).accessibilityIdentifier("musicVolume")
                    Text("\(Int(audio.musicVolume * 100))%")
                }
                Section {
                    Text("聲音設定會保留。聲音尊重系統靜音模式；音樂與音效可分別調整。")
                }
            }.navigationTitle("聲音設定")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() }.accessibilityIdentifier("audioSettingsDone") } }
        }
    }
}
