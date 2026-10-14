import SwiftUI
import TacticalGoCore
import TacticalGoMotion
import TacticalGoBot
import TacticalGoRecords
import TacticalGoContent

extension HeroClass {
    var title: String { switch self { case .warrior: "戰士"; case .mage: "法師"; case .rogue: "盜賊"; case .none: "無職業" } }
    var art: String { rawValue.lowercased() }
    var skillTitle: String { switch self { case .warrior: "築壘"; case .mage: "魔法之手"; case .rogue: "換位"; case .none: "技能" } }
    var skillHelp: String {
        switch self {
        case .warrior: "英雄相鄰的兩個空點，同時放士兵。"
        case .mage: "距離 2 內的任一士兵，推往相鄰空點。"
        case .rogue: "與相鄰敵方士兵交換位置。"
        case .none: "請先選擇職業。"
        }
    }
    func skillHelp(config: RuleConfig) -> String {
        if self == .warrior, config.bastionScope == .connectedGroup {
            return "在施放前與戰士相連的己方棋群旁，選兩個不同空點，同時放士兵；第一顆新兵不會擴大第二個落點的範圍。"
        }
        if self == .mage, config.experimentalFriendlyRedeploy {
            return "可將距離 2 內的普通士兵推往相鄰空點；也可將英雄兩格內、相連棋群中的己兵調度至原棋群外緣空點。不能調度主將或英雄。"
        }
        if self == .mage, config.magicHandDestination == .opposingSoldierExchange {
            return "將距離 2 內的普通士兵推往相鄰空點，或與異色普通士兵交換；主將和英雄不能作為交換目標。"
        }
        return skillHelp
    }
    var summonCost: Int { self == .mage ? 3 : 2 }
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

/// Measures the real HUD and controls first; the board uses the remaining space.
/// Its renderer and input still receive the same 8:9 display rectangle.
private struct MatchViewportLayout: Layout {
    private let gap: CGFloat = 6
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 390
        let hud = subviews[0].sizeThatFits(.init(width: width, height: nil))
        let controls = subviews[2].sizeThatFits(.init(width: width, height: nil))
        return CGSize(width: width, height: proposal.height ?? hud.height + controls.height + width * 1.125 + gap * 2)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let hud = subviews[0].sizeThatFits(.init(width: bounds.width, height: nil))
        let controls = subviews[2].sizeThatFits(.init(width: bounds.width, height: nil))
        let available = max(0, bounds.height - hud.height - controls.height - gap * 2)
        let boardWidth = min(bounds.width, available / 1.125)
        let boardHeight = boardWidth * 1.125
        subviews[0].place(at: CGPoint(x: bounds.midX, y: bounds.minY), anchor: .top,
                          proposal: .init(width: bounds.width, height: hud.height))
        subviews[1].place(at: CGPoint(x: bounds.midX, y: bounds.minY + hud.height + gap + (available - boardHeight) / 2), anchor: .top,
                          proposal: .init(width: boardWidth, height: boardHeight))
        subviews[2].place(at: CGPoint(x: bounds.midX, y: bounds.maxY), anchor: .bottom,
                          proposal: .init(width: bounds.width, height: controls.height))
    }
}

/// The sheet payload is the chapter selection, so its first presentation cannot
/// capture a separate, stale campaign state. Keep routing outside the rules core.
private enum ChallengeRoute: String, Identifiable {
    case introduction, advanced
    var id: String { rawValue }
    var campaign: ChallengeCampaign { self == .advanced ? .advanced : .introduction }
}

/// A0 playable product entry. Original cards/tokens; no 3D resource loading.
struct PlayableGameView: View {
    @State private var skillVFXAuditStatus = "waiting"
    @State private var skillVFXAuditStarted = false

    @State private var store = GameStore()
    @State private var access = PlayAccess()
    @State private var showUnlock = false
    @State private var pendingMatchRules: RecordRules?
    @State private var adIsPresented = false
    @State private var showPrivacy = false
    @State private var visuals = GameVisualAssets.original
    @State private var heroBodyAuditStatus = "RUNNING"
    @State private var heroBodyAuditStarted = false
    @State private var mageBodyAuditStatus = "RUNNING"
    @State private var mageBodyAuditStarted = false
    @State private var cozyAuditStatus = "RUNNING"
    @State private var cozyAuditStarted = false
    @State private var voiceAuditStarted = false
    @State private var voiceAuditStatus = "RUNNING"
    @State private var requestedWidth: CGFloat?
    @State private var cozyReduced = false
    @State private var mageEffectsEnabled = true
    @State private var mageRevision: MageArtRevision = .r1
    @State private var mageMarkers: HeroMarkerStyle = .thinRing
    @State private var gameFeelAuditStarted = false
    @State private var gameFeelAuditStatus = "準備測試"
    @State private var cozyAssets = try? CozyAssets.load()
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
    @State private var showMatchOptions = false
    @State private var showLobbySetup = false
    @State private var lobbyShowsHeroes = false
    @State private var showRecords = false
    @State private var showOnboarding = false
    @State private var showR2 = false
    @State private var challengeRoute: ChallengeRoute?
    #if DEBUG
    @State private var audioAuditStatus = "RUNNING"
    #endif
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var lesson: PracticeLesson?
    @State private var showActionHelp = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .subheadline) private var compactSummaryHeight: CGFloat = 38
    @ScaledMetric(relativeTo: .subheadline) private var compactActionHeight: CGFloat = 44
    @State private var showRules = false
    @State private var showGrid = false
    @State private var confirmExit = false
    
    private let heroes: [HeroClass] = [.warrior, .mage, .rogue]
    private var displayedPlayer: Player { store.isBotActing ? (store.computer ?? store.state.current) : store.state.current }
    private var side: String { displayedPlayer == .one ? "黑方" : "白方" }
    // Core has already committed the result. Keep the result UI behind the same
    // successful playback boundary as the moving and captured pieces.
    private var isResolvingTerminalPlayback: Bool {
        store.state.status != .ongoing && store.isPresenting && store.playback?.outcome.success == true
    }
    private var turnTitle: String {
        if isResolvingTerminalPlayback { return side + hero.title + " · 行動演出中" }
        return store.state.status == .ongoing || store.isBotActing ? "輪到" + side + hero.title : "對戰結束"
    }
    private var presentedResult: String? { store.isBotActing || isResolvingTerminalPlayback ? nil : store.resultTitle }
    private var presentedMessage: String { isResolvingTerminalPlayback ? "行動演出中 · 等待落定與提子" : store.message }
    private var hero: HeroClass { store.state.heroClass(of: displayedPlayer) }
    private var complete: Bool { !store.isPresenting && lesson?.isComplete(store.state) == true }
    var body: some View {
        GeometryReader { geo in
            Group { if inMatch { match(size: CGSize(width: requestedWidth ?? geo.size.width, height: geo.size.height)) } else { lobby(size: geo.size) } }
                .frame(width: requestedWidth).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .background(LinearGradient(colors: [Cozy.bg, Cozy.selected], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        .foregroundStyle(Cozy.ink).preferredColorScheme(sellLook ? .dark : .light)
        .overlay(alignment:.topLeading) {
            #if DEBUG
            // Encoded-frame registration only in recordings. Resource transition comes from
            // real Core state; it locates the shot without assuming host/simulator clock equality.
            if ProcessInfo.processInfo.arguments.contains("--vfx-record-marker") {
                Rectangle().fill(store.state.apRemaining == 1 ? Color(red:1,green:0,blue:1) : Color(red:0,green:1,blue:1))
                    .frame(width:8,height:8).padding(4).allowsHitTesting(false).accessibilityHidden(true)
            }
            #endif
        }
         .task { await access.purchase.start() }
        .sheet(isPresented: $showUnlock, onDismiss: { RewardedAdService.shared.cancelPendingRequest(); pendingMatchRules = nil }) {
            UnlockView(access: access, continueGame: {
                if let rules = pendingMatchRules { startMatch(rules: rules) }
            }, continueTitle: pendingMatchRules == nil ? "返回遊戲" : "開始下一局", presentationChanged: { presented in
                adIsPresented = presented
                store.setSceneAudioActive(!presented && scenePhase == .active)
            })
        }
        .sheet(isPresented: $showPrivacy) {
            ReleaseInformationView(access: access, presentationChanged: { presented in
                adIsPresented = presented
                store.setSceneAudioActive(!presented && scenePhase == .active)
            })
        }
        .sheet(isPresented: $showRules) { rules }
        .fullScreenCover(item: $challengeRoute, onDismiss: {
            store.setMatchAudioActive(inMatch)
            if inMatch { store.scheduleComputerTurn() }
        }) { route in
            ChallengesView(campaign: route.campaign) { challengeRoute = nil }.id(route.id)
        }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingView { showOnboarding = false } }
        .sheet(isPresented: $showGrid) { accessibleGrid }
        .alert("離開目前對戰？", isPresented: $confirmExit) {
            Button("返回選角", role: .destructive) { store.leaveMatch(); inMatch = false; showLobbySetup = true; lobbyShowsHeroes = true; lesson = nil }.accessibilityIdentifier("exitMatchConfirmed")
            Button("留在對戰", role: .cancel) {}
        }
        .onDisappear { store.cancelBotWork(); store.setMatchAudioActive(false) }
        .onChange(of: reduceMotion) { _, value in store.cancelPresentation(); store.presentationReducedMotion = value || cozyReduced }
        .onChange(of: inMatch) { _, active in store.setMatchAudioActive(active) }
        .onChange(of: scenePhase) { _, phase in
            store.setSceneAudioActive(phase == .active && !adIsPresented)
            if phase == .active { startCozyAuditIfActive() }
            if phase == .active && inMatch && challengeRoute == nil { store.scheduleComputerTurn() }
            else { store.cancelBotWork() }
        }
        .sheet(isPresented: $showR2) {
            R2LabView { fixture, rules in
                if store.startR2(fixture,rules:rules) { lesson = nil; inMatch = true; store.setMatchAudioActive(true) }
            }
        }
        .sheet(isPresented: $showRecords, onDismiss: { if inMatch { store.scheduleComputerTurn() } }) {
            RecordLibraryView(store: store, resume: resumeRecord)
        }
        .sheet(isPresented: $showSoundSettings) { CombatSoundSettings(audio: store.audio) }
        .sheet(isPresented: $showMatchOptions) { lobbySettingsSheet }
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
        .onChange(of: presentedResult) { _, result in
            if let result { UIAccessibility.post(notification: .announcement, argument: result) }
        }
        .overlay(alignment: .top) {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--hero-body-audit") { Text(heroBodyAuditStatus).accessibilityIdentifier("heroBodyAudit").font(.caption).background(Cozy.card) }
            if ProcessInfo.processInfo.arguments.contains("--mage-body-audit") { Text(mageBodyAuditStatus).accessibilityIdentifier("mageBodyAudit").font(.caption).background(Cozy.card) }
            if ProcessInfo.processInfo.arguments.contains("--game-feel-audit") {
                Text(gameFeelAuditStatus).accessibilityIdentifier("gameFeelAudit").font(.caption2).background(Cozy.card)
            }
            if ProcessInfo.processInfo.arguments.contains("--voice-review") {
                Text(store.audio.voiceObservations.last?["key"] ?? "尚未觸發語音").font(.system(size: 9)).accessibilityIdentifier("heroStage").padding(2).background(Cozy.card.opacity(0.85)).allowsHitTesting(false)
            }
            if ProcessInfo.processInfo.arguments.contains("--vfx-audit") {
                Text(skillVFXAuditStatus).accessibilityIdentifier("skillVFXAudit").padding(4).background(Cozy.card)
            }
            if ProcessInfo.processInfo.arguments.contains("--voice-audit") {
                Text(voiceAuditStatus).accessibilityIdentifier("voiceAudit").padding(4).background(Cozy.card)
            }
            if ProcessInfo.processInfo.arguments.contains("--cozy-audit") {
                Text(cozyAuditStatus).accessibilityIdentifier("cozyAudit").padding(4).background(Cozy.card)
            }
            if ProcessInfo.processInfo.arguments.contains("--integrated-audio-audit") {
                Text(audioAuditStatus).accessibilityIdentifier("integratedAudioAudit").padding().background(Color.ink)
            }
            #endif
        }
        .onAppear {
            store.onMatchCompleted = { id in access.completedMatch(id: id) }
            access.reconcileCompletedMatches(ids: store.savedRecords.compactMap {
                guard let status = $0.steps.last?.after.status, status != .ongoing else { return nil }
                return $0.id
            })
            store.presentationReducedMotion = reduceMotion || cozyReduced
            store.setSceneAudioActive(scenePhase == .active)
            store.setMatchAudioActive(inMatch)
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--demo-audio-defaults") {
                store.audio.muted = false; store.audio.voiceEnabled = true; store.audio.voiceVolume = 0.75; store.audio.sfxVolume = 0.65
            }
            if args.contains("--mage-body-review") || args.contains("--hero-body-review") { store.audio.voiceEnabled = false }
            // One-time recovery for the owner's build; ordinary launches preserve preferences.
            if args.contains("--restore-play-audio") {
                store.audio.muted = false; store.audio.sfxVolume = 0.65
                store.audio.musicEnabled = true; store.audio.musicVolume = 0.30
                store.audio.voiceEnabled = false
            }
            mageEffectsEnabled = !args.contains("--mage-no-effects")
            if args.contains("--mage-m3-reference") { mageRevision = .m3 }
            if args.contains("--mage-m2-reference") { mageRevision = .m2; mageMarkers = .legacy }
            if args.contains("--mage-compact") { store.mageTempo = .compact }
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
            if args.contains("--bot-material-witness") {
                singlePlayer = true; startMatch()
                store.loadBotMaterialWitness(policy: args.contains("--bot-material-candidate") ? .materialThreatContinuation : .baseline)
            }
            if args.contains("--bot-mage-motion-review") { singlePlayer = true; startMatch(); store.loadBotMageMotionReview() }
            if args.contains("--visual-pack-fixture") || args.contains("--visual-pack-invalid-fixture") {
                visualFixture = true
                visuals = .connectionFixture(invalid: args.contains("--visual-pack-invalid-fixture"))
            }
            if let i = args.firstIndex(of: "--practice"), args.indices.contains(i + 1), let value = PracticeLesson.allCases.first(where: { $0.rawValue == args[i + 1] }) { startPractice(value) }
            requestedWidth = args.contains("--cozy-320") ? 320 : args.contains("--cozy-390") ? 390 : nil
            cozyReduced = args.contains("--cozy-reduced")
            store.presentationReducedMotion = reduceMotion || cozyReduced
            if args.contains("--summon-demo") {
                let selectedHero = args.firstIndex(of: "--hero").flatMap { index in
                    args.indices.contains(index + 1) ? ["warrior": HeroClass.warrior, "mage": .mage, "rogue": .rogue][args[index+1]] : nil
                } ?? .mage
                let owner: Player = args.contains("--white-caster") ? .two : .one
                let size = args.contains("--cozy-nine") ? 9 : 7
                var diagram = Array(repeating: String(repeating: ".", count: size), count: size)
                diagram[0] = "...O" + String(repeating: ".", count: size - 4)
                diagram[5] = "...X" + String(repeating: ".", count: size - 4)
                store.leaveMatch(); store.size = size
                store.session = GameSession(try! GameSetup.fromDiagram(config: .board(size: size), diagram: diagram.joined(separator: "\n"), classOne: selectedHero, classTwo: selectedHero, current: owner, manaOne: 4, manaTwo: 4, ap: 2))
                store.mode = .summon; inMatch = true; store.setMatchAudioActive(true)
            }
            if args.contains("--hero-skill-demo") {
                let hero: HeroClass = args.contains("rogue") ? .rogue : .warrior
                let owner: Player = args.contains("--white-caster") ? .two : .one
                let symbol = owner == .one ? "H" : "Q", enemy = owner == .one ? "o" : "x"
                let diagram = "...O...\n.......\n.......\n..." + symbol + (hero == .rogue ? enemy : ".") + "..\n.......\n...X...\n......."
                store.leaveMatch(); store.size = 7
                store.session = GameSession(try! GameSetup.fromDiagram(config: .board(size: 7), diagram: diagram,classOne: hero,classTwo: hero,current: owner,manaOne: 4,manaTwo: 4,ap: 2))
                store.mode = .skill; inMatch = true; store.setMatchAudioActive(true)
            }
            if args.contains("--hero-body-demo") {
                let hero:HeroClass = args.contains("rogue") ? .rogue : .warrior
                let owner:Player = args.contains("--white-caster") ? .two : .one
                store.leaveMatch();store.size = args.contains("--cozy-nine") ? 9 : 7
                store.session = GameSession(try! HeroBodyFixture.state(hero,owner:owner,size:store.size,capture:args.contains("--hero-body-capture"),dense:args.contains("--hero-body-dense"),summon:args.contains("--hero-body-summon")))
                store.mode = args.contains("--hero-body-summon") ? .summon : .skill;inMatch = true;store.setMatchAudioActive(true)
            }
            if args.contains("--cozy-demo") {
                store.leaveMatch(); store.size = args.contains("--cozy-nine") ? 9 : 7
                let caster: Player = args.contains("--white-caster") ? .two : .one
                let pushedOwner = args.contains("--enemy-target") ? caster.opponent : caster
                store.session = GameSession(try! TacticalGoMotion.Anim01Fixture.state(size: store.size, caster: caster, pushedOwner: pushedOwner, capture: !args.contains("--cozy-no-capture") && pushedOwner == caster))
                one = .mage; two = .warrior; store.mode = .skill; inMatch = true
                store.setMatchAudioActive(true)
            }
            if args.contains("--mage-dense") {
                store.size = 9; store.session = GameSession(try! Anim01Fixture.denseState(caster: args.contains("--white-caster") ? .two : .one))
            }
            if args.contains("--cozy-dense") {
                let url = Bundle.main.url(forResource: "scenes", withExtension: "json", subdirectory: "Cozy")!
                let scenes = try! JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [[String: Any]]
                let scene = scenes.first { ($0["size"] as? Int) == store.size && ($0["phase"] as? String) == "dense" }!
                func hero(_ key: String) -> HeroClass { ["mage": .mage, "warrior": .warrior, "rogue": .rogue][scene[key] as! String]! }
                store.session = GameSession(try! GameSetup.fromDiagram(config: .board(size: store.size), diagram: scene["diagram"] as! String,
                    classOne: hero("hero"), classTwo: hero("enemyHero"), manaOne: scene["mana"] as! Int, manaTwo: scene["enemyMana"] as! Int,
                    ap: scene["ap"] as! Int, ply: scene["ply"] as! Int))
            }
            if args.contains("--vfx-demo") {
                let hero:HeroClass = args.contains("warrior") ? .warrior : args.contains("rogue") ? .rogue : .mage
                let owner:Player = args.contains("--white-caster") ? .two : .one
                store.leaveMatch();store.size = args.contains("--cozy-nine") ? 9 : 7
                store.session = GameSession(try! SkillVFXFixture.state(hero,owner:owner,size:store.size,capture:args.contains("--vfx-capture"),dense:args.contains("--vfx-dense"),enemyTarget:args.contains("--vfx-enemy")))
                store.mode = .skill;inMatch = true;store.setMatchAudioActive(true)
            }
            if args.contains("--play-nine") { boardSize = 9; startMatch() }
            if args.contains("--play-win") { startMatch(); store.loadWinningTurn() }
            if args.contains("--play-draw") { startMatch(); store.loadLastTurn() }
            if args.contains("--skill-screenshot") {
                store.loadSkillScreenshot(candidate: args.contains("--candidate-skills"), mage: args.contains("--mage-redeploy"))
                lesson = nil; inMatch = true
            }
            #endif
            startCozyAuditIfActive()
        }
    }
    private func startCozyAuditIfActive() {
        #if DEBUG
        guard scenePhase == .active else { return }
        if !skillVFXAuditStarted, ProcessInfo.processInfo.arguments.contains("--vfx-audit"), let cozyAssets {
            skillVFXAuditStarted = true; Task {skillVFXAuditStatus = await SkillVFXAudit.run(store:store,assets:cozyAssets)}
        }
        if !heroBodyAuditStarted, ProcessInfo.processInfo.arguments.contains("--hero-body-audit"), let cozyAssets {
            heroBodyAuditStarted = true; Task { heroBodyAuditStatus = await HeroBodyAudit.run(store:store,assets:cozyAssets) }
        }
        if !mageBodyAuditStarted, ProcessInfo.processInfo.arguments.contains("--mage-body-audit"), let cozyAssets {
            mageBodyAuditStarted = true; Task { mageBodyAuditStatus = await MageBodyAudit.run(store:store,assets:cozyAssets) }
        }
        if !gameFeelAuditStarted, ProcessInfo.processInfo.arguments.contains("--game-feel-audit") {
            gameFeelAuditStarted = true; Task { gameFeelAuditStatus = await GameFeelFrameAudit.run(store: store) }
        }
        if !voiceAuditStarted, ProcessInfo.processInfo.arguments.contains("--voice-audit") {
            voiceAuditStarted = true; Task { voiceAuditStatus = await HeroVoiceAudit.run(store: store) }
        }
        if !cozyAuditStarted, ProcessInfo.processInfo.arguments.contains("--cozy-audit") {
            cozyAuditStarted = true; Task { cozyAuditStatus = await CozyAudit.run(store: store) }
        }
        #endif
    }
    @ViewBuilder private func lobby(size: CGSize) -> some View {
        if showLobbySetup { lobbySetup(size: size) }
        else { lobbyHome(size: size) }
    }
    private func lobbyHome(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let compact = size.height < 720 && !tablet
        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: compact ? 12 : 20) {
                    HStack { Spacer(); lobbyTools }
                    VStack(spacing: 6) {
                        Image(systemName: "crown.fill").font(.system(size: compact ? 34 : 44, weight: .bold))
                            .foregroundStyle(Cozy.confirm).accessibilityHidden(true)
                        Text("皇冠戰略").font(.system(size: compact ? 32 : 36, weight: .black, design: .rounded))
                        Text("CROWN TACTICS").font(.system(size: 12, weight: .bold)).tracking(2)
                    }.foregroundStyle(SellTheme.paper).shadow(color: .black.opacity(0.55), radius: 3, y: 2)
                    lobbyHeroEnsemble(height: tablet ? 235 : compact ? 135 : 185)
                    Text("選擇你的英雄，贏下這一盤。")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(SellTheme.paper)
                        .multilineTextAlignment(.center)
                    if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
                }.padding(.horizontal, tablet ? 32 : 22).padding(.top, 6).padding(.bottom, 18)
                    .frame(maxWidth: tablet ? 660 : 500).frame(maxWidth: .infinity)
            }
            VStack(spacing: 10) {
                Text(access.purchase.isUnlocked ? "已永久解鎖" : "免費完整對局剩餘 \(access.remainingTrialMatches)／3")
                    .font(.caption).foregroundStyle(SellTheme.paper.opacity(0.8)).accessibilityIdentifier("accessStatus")
                if let record = store.resumableRecord {
                    Button { resumeRecord(record) } label: {
                        Label("續玩上局", systemImage: "play.circle.fill").font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }.buttonStyle(SellButton(confirm: true)).accessibilityIdentifier("resumeMatch")
                }
                Button { lobbyShowsHeroes = false; choosing = singlePlayer ? humanSide : .one; showLobbySetup = true } label: {
                    Label("開始對戰", systemImage: "play.fill").font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                }.buttonStyle(SellButton(confirm: store.resumableRecord == nil)).accessibilityIdentifier("lobbyNewGame")
                let links = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 16))
                links {
                    Button { showOnboarding = true } label: {
                        Label("新手入門", systemImage: "hand.tap").frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityIdentifier("startOnboarding")
                    Button { openChallenges(.introduction) } label: {
                        Label("戰術挑戰", systemImage: "flag.checkered").frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityIdentifier("lobbyChallenges")
                }.font(.subheadline.weight(.semibold)).foregroundStyle(SellTheme.paper)
            }.padding(.horizontal, tablet ? 32 : 22).padding(.vertical, 14)
                .frame(maxWidth: tablet ? 560 : 500).frame(maxWidth: .infinity)
                .background(SellTheme.teal)
        }.background { SellTabletop() }.foregroundStyle(SellTheme.ink)
    }
    private func lobbyHeroEnsemble(height: CGFloat) -> some View {
        // Original approved pixels, decorative only; selection stays on the next page.
        ZStack(alignment: .bottom) {
            Ellipse().fill(Color.black.opacity(0.35)).frame(width: height * 1.55, height: 22).blur(radius: 8)
            Image(uiImage: visuals.portrait("mage")).resizable().scaledToFit()
                .frame(width: height * 0.78, height: height * 0.83).offset(x: -height * 0.53, y: -8)
            Image(uiImage: visuals.portrait("rogue")).resizable().scaledToFit()
                .frame(width: height * 0.78, height: height * 0.83).offset(x: height * 0.53, y: -8)
            Image(uiImage: visuals.portrait("warrior")).resizable().scaledToFit()
                .frame(width: height, height: height)
        }.frame(height: height + 12).frame(maxWidth: .infinity)
            .shadow(color: .black.opacity(0.45), radius: 5, y: 5).accessibilityHidden(true)
    }
    private var lobbyTools: some View {
        Menu {
            Button("聲音", systemImage: "speaker.wave.2") { showSoundSettings = true }
            Button("遊戲規則", systemImage: "book") { showRules = true }
            Button("存局與棋譜", systemImage: "book.closed") {
                store.refreshRecords(); showRecords = true
            }.accessibilityIdentifier("recordLibrary")
            Menu("玩法練習", systemImage: "graduationcap") {
                ForEach(PracticeLesson.allCases) { value in Button(value.rawValue) { startPractice(value) } }
            }
            Button("購買與恢復", systemImage: "cart") { pendingMatchRules = nil; showUnlock = true }.accessibilityIdentifier("purchaseSettings")
            Button("隱私與支援", systemImage: "hand.raised") { showPrivacy = true }.accessibilityIdentifier("privacySupport")
            #if DEBUG
            Button("技能試驗", systemImage: "flask") { showR2 = true }
            #endif
        } label: {
            Image(systemName: "gearshape").font(.system(size: 20)).frame(width: 44, height: 44)
                .foregroundStyle(SellTheme.paper).background(SellTheme.teal.opacity(0.7), in: Circle())
        }.accessibilityLabel("設定與工具").accessibilityIdentifier("lobbyTools")
    }
    private var challengeEntry: some View {
        Menu("戰術挑戰", systemImage: "flag.checkered") {
            Button("英雄技能入門 · 六關") { openChallenges(.introduction) }
            Button("邊境攻防 · 三關候選") { openChallenges(.advanced) }
        }
    }
    private func openChallenges(_ route: ChallengeRoute) {
        // Stop pending bot/presentation work without changing the current match
        // or its journal. The existing turn resumes only after challenges close.
        store.cancelBotWork()
        store.setMatchAudioActive(false)
        challengeRoute = route
    }
    private func lobbySetup(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let compact = size.height < 720 && !tablet
        return VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: compact ? 16 : 24) {
                    HStack {
                        Button { showLobbySetup = false } label: {
                            Label("主畫面", systemImage: "chevron.left").frame(minHeight: 44)
                        }.accessibilityIdentifier("lobbyHomeBack")
                        Spacer()
                        Button { showMatchOptions = true } label: {
                            Image(systemName: "gearshape").frame(width: 44, height: 44)
                        }.accessibilityLabel("對戰設定").accessibilityIdentifier("lobbyMatchOptions")
                            .accessibilityValue("已收起")
                        Button { showSoundSettings = true } label: {
                            Image(systemName: "speaker.wave.2").frame(width: 44, height: 44)
                        }.accessibilityLabel("聲音").accessibilityIdentifier("lobbySoundSettings")
                    }.foregroundStyle(SellTheme.paper)
                    if lobbyShowsHeroes {
                        let first = singlePlayer ? humanSide : Player.one
                        Text(singlePlayer ? (choosing == humanSide ? "選擇你的英雄" : "選擇電腦英雄") : (choosing == .one ? "黑方選擇英雄" : "白方選擇英雄"))
                            .font(.title2.bold()).foregroundStyle(SellTheme.paper)
                        lobbyHeroPanel(portraitHeight: tablet ? 180 : compact ? 105 : 145)
                        Button {
                            if choosing != first { choosing = first }
                            else { lobbyShowsHeroes = false }
                        } label: { Label("上一步", systemImage: "arrow.left").frame(minHeight: 44) }
                            .foregroundStyle(SellTheme.paper).accessibilityIdentifier("lobbyPreviousStep")
                    } else {
                        Text("想和誰下這一盤？").font(.title2.bold()).foregroundStyle(SellTheme.paper)
                        lobbyHeroEnsemble(height: tablet ? 210 : compact ? 130 : 170)
                        Button { singlePlayer = true; boardSize = 7; choosing = humanSide; lobbyShowsHeroes = true } label: {
                            Label("電腦對戰", systemImage: "cpu").font(.headline).frame(maxWidth: .infinity, minHeight: 68)
                        }.buttonStyle(SellButton()).accessibilityIdentifier("setupComputer")
                        Button { singlePlayer = false; choosing = .one; lobbyShowsHeroes = true } label: {
                            Label("本機雙人", systemImage: "person.2.fill").font(.headline).frame(maxWidth: .infinity, minHeight: 68)
                        }.buttonStyle(SellButton()).accessibilityIdentifier("setupLocal")
                    }
                }.padding(.horizontal, tablet ? 32 : 22).padding(.top, 10).padding(.bottom, 24)
                    .frame(maxWidth: tablet ? 650 : 500).frame(maxWidth: .infinity)
            }
            if lobbyShowsHeroes {
                lobbyStartButton.frame(maxWidth: tablet ? 560 : 500).padding(.horizontal, tablet ? 32 : 22)
                    .padding(.vertical, 14).frame(maxWidth: .infinity).background(SellTheme.teal)
            }
        }.background { SellTabletop() }.foregroundStyle(SellTheme.ink)
    }
    private func lobbyHeroPanel(portraitHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            heroChoices(portraitHeight: portraitHeight)
            DisclosureGroup("技能說明") { chosenSkill.padding(.top, 8) }
                .font(.subheadline).tint(SellTheme.ink).accessibilityIdentifier("lobbySkillDetails")
        }.padding(14).background { SellOperationSurface() }.environment(\.colorScheme, .light)
    }
    private var lobbySettingsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    lobbySettings
                    boardSizePicker
                    Picker("選角陣營", selection: $choosing) {
                        Text(singlePlayer ? (humanSide == .one ? "你 · 黑方 ●" : "電腦 · 黑方 ●") : "黑方 ●").tag(Player.one)
                        Text(singlePlayer ? (humanSide == .two ? "你 · 白方 ○" : "電腦 · 白方 ○") : "白方 ○").tag(Player.two)
                    }.pickerStyle(.segmented).accessibilityIdentifier("choosingTeam")
                    matchClasses
                }.padding(20)
            }.navigationTitle("對戰設定")
                .toolbar { ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { showMatchOptions = false }.accessibilityIdentifier("lobbyOptionsDone")
                } }
        }.preferredColorScheme(.light)
    }
    private var lobbySettings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("對戰模式").font(.caption.bold())
            Picker("對戰模式", selection: $singlePlayer) {
                Text("本機雙人").tag(false); Text("電腦對戰").tag(true)
            }.pickerStyle(.segmented).accessibilityIdentifier("matchMode")
                .onChange(of: singlePlayer) { _, solo in if solo { boardSize = 7; choosing = humanSide } }
            if singlePlayer {
                Picker("你執哪方", selection: $humanSide) {
                    Text("黑方先手").tag(Player.one); Text("白方後手").tag(Player.two)
                }.pickerStyle(.segmented).accessibilityIdentifier("humanSide")
                    .onChange(of: humanSide) { _, side in choosing = side }
                Picker("電腦難度", selection: Binding(get: { store.botDifficulty }, set: { store.setBotDifficulty($0) })) {
                    Text("簡單").tag(BotDifficulty.easy); Text("標準").tag(BotDifficulty.standard)
                }.pickerStyle(.segmented).accessibilityIdentifier("botDifficulty")
                Text(store.botDifficulty == .easy ? "適合先熟悉三職技能與主將攻守。" : "會預判你的反擊，適合挑戰。")
                    .font(.caption).foregroundStyle(SellTheme.muted)
            }
        }
    }
    private func heroChoices(portraitHeight: CGFloat) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(heroes, id: \.self) { h in
                let selected = (choosing == .one ? one : two) == h
                Button {
                    if choosing == .one { one = h } else { two = h }
                } label: {
                    VStack(spacing: 6) {
                        Image(uiImage: visuals.portrait(h.art)).resizable().scaledToFit().frame(height: portraitHeight)
                        Text(h.title).font(.subheadline.bold())
                        Text(h.skillTitle).font(.caption.weight(.semibold))
                    }.frame(maxWidth: .infinity).padding(.vertical, 10)
                }.buttonStyle(SellButton(selected: selected)).accessibilityIdentifier("choose-" + h.art)
                    .accessibilityLabel(h.title + "，" + h.skillTitle).accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }
    @ViewBuilder private var chosenSkill: some View {
        let choice = choosing == .one ? one : two
        let description = choice.skillHelp(config: GameStore.defaultMatchRules.config(size: boardSize))
        VStack(alignment: .leading, spacing: 5) {
            Text(description).font(.subheadline).accessibilityIdentifier("lobbySkillDescription")
            Text("召喚 \(choice.summonCost) 能量 · 技能 1 AP＋2 能量 · 每回合一次")
                .font(.caption).foregroundStyle(SellTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var matchClasses: some View {
        HStack {
            Label("黑方 · \(one.title)", systemImage: "circle.fill")
            Spacer(); Text("VS").font(.caption.bold()).foregroundStyle(SellTheme.muted); Spacer()
            Label("白方 · \(two.title)", systemImage: "circle")
        }.font(.caption.bold()).foregroundStyle(SellTheme.ink).accessibilityIdentifier("matchClasses")
    }
    private var boardSizePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("棋盤").font(.caption.bold())
            Picker("棋盤", selection: $boardSize) { Text("7 × 7").tag(7); Text("9 × 9").tag(9) }
                .pickerStyle(.segmented).disabled(singlePlayer).accessibilityIdentifier("playBoardSize")
        }
    }
    private var lobbyStartButton: some View {
        let first = singlePlayer ? humanSide : Player.one
        let final = singlePlayer || choosing != first
        return Button {
            if final { startMatch() }
            else { choosing = first.opponent }
        } label: {
            Label(final ? "開始對局" : (singlePlayer ? "下一步：電腦英雄" : "下一步：白方英雄"), systemImage: final ? "play.fill" : "arrow.right")
                .font(.headline).frame(maxWidth: .infinity, minHeight: 54)
        }.buttonStyle(SellButton(confirm: true)).accessibilityIdentifier("startMatch")
    }
    private var lobbyFooter: some View {
        Text(singlePlayer ? "單人 7×7：你執\(humanSide == .one ? "黑" : "白")方，電腦執\(humanSide == .one ? "白" : "黑")方。\n黑方首回合 1 AP，之後每回合 2 AP。" : "兩人共用這台裝置，黑方先手。\n首回合 1 AP，之後每回合 2 AP。")
            .multilineTextAlignment(.center).font(.caption).foregroundStyle(SellTheme.paper.opacity(0.8))
    }
    @ViewBuilder private func match(size: CGSize) -> some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--sell-legacy") {
            legacyMatch(size: size)
        } else {
            tabletopMatch(size: size)
        }
        #else
        tabletopMatch(size: size)
        #endif
    }

    private var sellLook: Bool {
        #if DEBUG
        !ProcessInfo.processInfo.arguments.contains("--sell01a") && !ProcessInfo.processInfo.arguments.contains("--sell-legacy")
        #else
        true
        #endif
    }

    /// Presentation only: all input continues through the existing GameStore and CozyBoard.
    private func tabletopMatch(size: CGSize) -> some View {
        let wide = size.width >= 900 && size.width > size.height && !dynamicTypeSize.isAccessibilitySize
        let tablet = size.width >= 600
        let margin: CGFloat = tablet ? 24 : 8
        let compact = sellLook && !tablet && size.height < 720 && !dynamicTypeSize.isAccessibilitySize
        let reserved: CGFloat = dynamicTypeSize.isAccessibilitySize ? 440 : tablet ? 360 : compact ? 330 : 310
        let boardWidth = dynamicTypeSize.isAccessibilitySize
            ? min(size.width - margin * 2, tablet ? 700 : 420)
            : min(size.width - margin * 2, max(200, (size.height - reserved) / 1.125))
        return Group {
        if sellLook && !tablet && !dynamicTypeSize.isAccessibilitySize {
            phoneTabletopMatch
        } else { ScrollView {
            VStack(spacing: 10) {
                matchHeader(compact:compact)
                if wide {
                    HStack(alignment: .center, spacing: 24) {
                        board.frame(width: min(size.width - 364, (size.height - 100) / 1.125),
                                    height: min(size.width - 364, (size.height - 100) / 1.125) * 1.125)
                            .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 18) {
                            tabletopPlayer(.one); tabletopPlayer(.two)
                            botStatus; matchBanners
                            tabletopControls()
                        }.frame(width: 300)
                    }
                } else {
                    let layout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                        : AnyLayout(HStackLayout(alignment: .top, spacing: 14))
                    layout { tabletopPlayer(.one); tabletopPlayer(.two) }
                    botStatus; matchBanners
                    board.frame(width: boardWidth, height: boardWidth * 1.125)
                        .frame(maxWidth: .infinity)
                    tabletopControls(compact:compact)
                }
            }
            .padding(.horizontal, margin).padding(.top, 8).padding(.bottom, sellLook ? 16 : 8)
            .frame(maxWidth: wide ? 1268 : tablet ? 800 : 650)
            .frame(maxWidth: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if sellLook { Color.clear.frame(height: 12).allowsHitTesting(false).accessibilityHidden(true) }
        }
        } }
        .background {
            // The environment extends; important controls remain in the root safe area.
            if sellLook { SellTabletop() }
            else { LinearGradient(colors: [Cozy.bg, Cozy.selected, Cozy.card.opacity(0.7)], startPoint: .top, endPoint: .bottom).ignoresSafeArea() }
        }
        .foregroundStyle(sellLook ? SellTheme.paper : Cozy.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tabletopMatch")
        // Completion remains observable after the transient thinking banner goes away.
        .accessibilityValue("已完成\(store.botTurnsCompleted)電腦回合")
    }

    private var phoneTabletopMatch: some View {
        MatchViewportLayout {
            VStack(spacing: 4) {
                matchHeader(compact: true, battleFocus: true)
                HStack(alignment: .top, spacing: 10) {
                    tabletopPlayer(.one, compact: true); tabletopPlayer(.two, compact: true)
                }
                matchBanners
            }.padding(.horizontal, 8).fixedSize(horizontal: false, vertical: true)
            board
            tabletopControls(compact: true).padding(.horizontal, 8).fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 4).padding(.bottom, 12)
        .sheet(isPresented: $showActionHelp) {
            NavigationStack {
                ScrollView { Text(modeHelp).font(.body).padding().accessibilityIdentifier("actionHelpText") }
                    .navigationTitle("操作說明")
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { showActionHelp = false }.accessibilityIdentifier("actionHelpDone")
                    } }
            }
        }
    }

    private func tabletopPlayer(_ player: Player, compact: Bool = false) -> some View {
        let state = store.state, active = presentedResult == nil && displayedPlayer == player
        let commander = state.board.find(player, .commander)
        let liberties = commander.map { state.board.liberties(at: $0).count } ?? 0
        return VStack(alignment: .leading, spacing: compact ? 3 : 5) {
            HStack(spacing: 4) {
                if sellLook {
                    Text(player == .one ? "● 黑方" : "○ 白方").font(.subheadline.weight(.heavy))
                    Text(state.heroClass(of:player).title).font(.caption.weight(.semibold))
                } else {
                    Text((player == .one ? "● 黑方 " : "○ 白方 ") + state.heroClass(of:player).title).font(.subheadline.weight(.bold))
                }
                Spacer(minLength: 0)
                if active {
                    Text("\(store.isBotActing && state.current != player ? 0 : state.apRemaining) AP")
                        .font(.subheadline.weight(.heavy)).monospacedDigit()
                        .padding(.horizontal,sellLook ? 7 : 0).padding(.vertical,sellLook ? 3 : 0)
                        .foregroundStyle(sellLook ? SellTheme.ink : Cozy.ink)
                        .background { if sellLook { SellPlaque().fill(Cozy.confirm) } }
                }
            }
            HStack(spacing: 3) {
                if sellLook { Image(systemName:"diamond.fill").font(.system(size:10)).foregroundStyle(Cozy.color(0x9ADADD)).accessibilityHidden(true) }
                Text("能量 \(state.mana(of:player))/\(state.config.manaCap) · " + (presentedResult != nil && commander == nil ? "主將已被提" : "\(liberties) 氣"))
                    .font(.caption).foregroundStyle(liberties <= 1 && presentedResult == nil ? (sellLook ? Cozy.color(0xFFBEA0) : Cozy.danger) : sellLook ? SellTheme.lightMuted : Cozy.muted)
                Spacer(minLength:0)
                if store.computer != nil { Text(player == store.computer ? "電腦" : "你").font(.caption.weight(.bold)) }
            }
            Rectangle().fill(active ? (sellLook ? Cozy.gold : Cozy.ink) : (sellLook ? SellTheme.paper.opacity(0.2) : Cozy.ink.opacity(0.12)))
                .frame(height:active ? 3 : 1).accessibilityHidden(true)
        }.padding(.vertical, compact ? 2 : 4)
            .opacity(sellLook && presentedResult == nil && !active && liberties > 1 ? 0.82 : 1)
            .frame(maxWidth:.infinity,alignment:.leading)
            .accessibilityIdentifier(player == .one ? "blueResources" : "redResources")
    }

    private var tabletopPhase: String {
        if store.isBotThinking { return "等待電腦思考" }
        if store.isPresenting || store.isBotActing { return "行動演出中" }
        if store.state.status != .ongoing { return "本局已結束" }
        if let preview = store.preview { return preview.success ? "行動預覽" : "請調整目標" }
        if sellLook && store.playback != nil { return "結果已落定 · 可進行下一步" }
        return store.selected.isEmpty ? (sellLook ? store.mode == .skill ? "已選技能 · 等待目標" : "選擇行動 · 點棋盤預覽" : "選擇棋盤目標") : "選擇方向或下一個目標"
    }

    private var tabletopActionLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
    }

    @ViewBuilder private func tabletopControls(compact: Bool = false) -> some View {
        // The committed terminal state can arrive before the final capture has
        // been shown. Use the same presentation boundary as the result title.
        if sellLook && presentedResult != nil { matchResultPanel(compact: compact) }
        else { tabletopActions(compact: compact) }
    }

    private func matchResultPanel(compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(spacing: 12) {
                SellResultEmblem(drawn: store.state.status == .drawn)
                    .frame(width: compact ? 42 : 52, height: compact ? 42 : 52)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(presentedResult ?? "對戰結束")
                        .font(.system(.title2, design: .rounded, weight: .heavy))
                        .accessibilityIdentifier("resultTitle")
                    Text(resultExplanation).font(.subheadline)
                        .foregroundStyle(SellTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("resultReason")
                }
                Spacer(minLength: 0)
                if let winner = store.state.winner {
                    Image(uiImage: visuals.portrait(store.state.heroClass(of: winner).art))
                        .resizable().scaledToFit().frame(width: compact ? 48 : 60, height: compact ? 48 : 60)
                        .accessibilityHidden(true)
                }
            }
            Button(action: startMatch) {
                Label("再玩一局", systemImage: "arrow.clockwise")
                    .font(.headline).frame(maxWidth: .infinity, minHeight: 48)
            }.buttonStyle(SellButton(confirm: true)).accessibilityIdentifier("resultRematch")
            tabletopActionLayout {
                Button {
                    store.cancelBotWork(); store.refreshRecords(); showRecords = true
                } label: {
                    Label("查看棋譜", systemImage: "book.closed")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("resultRecords")
                Button(action: store.undo) {
                    Label("復原", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(!store.canUndoHumanDecision)
                    .accessibilityIdentifier("undoOrCancel")
            }
        }
        .foregroundStyle(SellTheme.ink).padding(compact ? 12 : 16)
        .background { SellOperationSurface() }
        .accessibilityElement(children: .contain).accessibilityIdentifier("matchResult")
    }

    private var resultExplanation: String {
        if let winner = store.state.winner {
            return (winner == .one ? "白方" : "黑方") + "主將已被包圍提走。"
        }
        return store.terminalMessage ?? "對戰已結束。"
    }

    private func tabletopActions(compact:Bool = false) -> some View {
        // Disabled computer-turn controls remain the human's own action bar.
        // Switching the active opponent must not add a mage picker to this bar.
        let hero = compact && sellLook && store.computer != nil ? store.state.heroClass(of: store.humanPlayer) : self.hero
        let summary = sellLook ? store.preview.flatMap { SellActionSummary(outcome: $0, action: store.selectedAction) } : nil
        // Both the two-line action buttons and one-line direction buttons need
        // the same budget when the preferred text size increases.
        let actionHeight: CGFloat = compact && sellLook ? max(44, compactActionHeight) : compact ? 44 : 58
        return VStack(alignment: .leading, spacing: compact ? 4 : 8) {
            if compact && sellLook {
                compactActionSummary(summary)
            } else {
            HStack(spacing: 10) {
                if !compact { Image(uiImage: visuals.portrait(hero.art)).resizable().scaledToFit().frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    if let summary {
                        Text(summary.effect).font(.subheadline.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("sellPreviewEffect")
                        Text(summary.cost).font(.caption.weight(.semibold)).foregroundStyle(Cozy.deepMage)
                            .accessibilityIdentifier("sellPreviewCost")
                        if let consequence = summary.consequence {
                            Text(consequence).font(.caption).foregroundStyle(Cozy.muted).accessibilityIdentifier("sellPreviewConsequence")
                        }
                    } else {
                        Text(sellLook ? (store.mode == .skill ? hero.skillTitle : store.mode.rawValue) : hero.title + " · " + (store.mode == .skill ? hero.skillTitle : store.mode.rawValue))
                            .font(.headline)
                        Text(tabletopPhase).font(.caption.weight(sellLook ? .bold : .regular)).foregroundStyle(Cozy.muted).accessibilityIdentifier("sellPhase")
                    }
                }
                Spacer(minLength: 0)
                if !compact { Button { showActionHelp.toggle() } label: {
                    Image(systemName: showActionHelp ? "chevron.up.circle" : "info.circle")
                        .font(.body).foregroundStyle(Cozy.muted).frame(width: 44, height: 44).contentShape(Rectangle())
                }.accessibilityLabel(showActionHelp ? "收起操作說明" : "展開操作說明")
                    .accessibilityIdentifier("actionHelp")
                }
            }
            }
            if showActionHelp && !compact {
                Text(modeHelp).font(.body).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("actionHelpText")
            }
            if !(compact && sellLook) && ((!sellLook && (!compact || !store.selected.isEmpty)) || complete || store.isBotActing || store.state.status != .ongoing || store.preview?.success == false) {
                Text(complete ? "已完成目標；可以復原重試或回到選角。" : presentedMessage)
                    .font(.footnote).foregroundStyle(Cozy.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("playMessage")
                    .accessibilityValue(store.isBotActing ? "\(store.botActionIndex)/\(store.botActionCount) \(store.botMotionStartedAt == nil ? "準備" : "落定")" : "")
            }
            if hero == .mage && store.state.config.experimentalFriendlyRedeploy && (store.mode == .skill || (compact && sellLook)) {
                Picker("魔法之手方式", selection: Binding(get: { store.mageOperation }, set: { store.changeMageOperation($0) })) {
                    ForEach(GameStore.MageOperation.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).accessibilityIdentifier("mageOperation")
                    .opacity(store.mode == .skill ? 1 : 0)
                    .allowsHitTesting(store.mode == .skill)
                    .accessibilityHidden(store.mode != .skill)
            }
            if store.mode == .skill && hero == .mage && store.mageOperation == .push && store.selected.first != nil {
                tabletopActionLayout {
                    ForEach(PushDirection.allCases, id: \.self) { direction in
                        Button { store.chooseDirection(direction) } label: {
                            Label(direction.title, systemImage: direction.symbol)
                                .font(.subheadline.weight(.bold)).frame(maxWidth: .infinity, minHeight: sellLook ? actionHeight : 44)
                        }.matchButtonStyle(commercial:sellLook,selected:store.pushDirection == direction)
                            .disabled(store.isComputerTurn || !store.availableDirections.contains(direction))
                            .accessibilityIdentifier("push-" + direction.rawValue)
                    }
                }
            } else {
                tabletopActionLayout {
                    ForEach(GameStore.Mode.allCases, id: \.self) { mode in
                        Button { store.changeMode(mode) } label: {
                            Group {
                            if compact && sellLook {
                            VStack(spacing: 2) {
                                HStack(spacing: 4) {
                                    if sellLook { SellActionGlyph(mode: mode, hero: hero).frame(width: compact ? 16 : 24, height: compact ? 16 : 19).accessibilityHidden(true) }
                                    Text(mode == .skill ? hero.skillTitle : mode.rawValue).font(.subheadline.weight(.bold))
                                        .lineLimit(1).minimumScaleFactor(0.85)
                                }
                                Text(mode == .soldier ? "1 AP" : "1 AP · \(mode == .summon ? hero.summonCost : 2) 能量").font(.caption2)
                                    .lineLimit(1).minimumScaleFactor(0.85)
                            }
                            } else {
                                HStack(spacing: 6) {
                                    if sellLook { SellActionGlyph(mode: mode, hero: hero).frame(width: 24, height: 19).accessibilityHidden(true) }
                                    VStack(spacing: 2) {
                                        Text(mode == .skill ? hero.skillTitle : mode.rawValue).font(.subheadline.weight(.bold))
                                        Text(mode == .soldier ? "1 AP" : "1 AP · \(mode == .summon ? hero.summonCost : 2) 能量").font(.caption2)
                                    }
                                }
                            }
                            }.frame(maxWidth: .infinity, minHeight:sellLook ? actionHeight : compact ? 44 : 48)
                        }.matchButtonStyle(commercial:sellLook,selected:store.mode == mode)
                            .disabled(store.state.status != .ongoing || store.isComputerTurn || store.isPresenting)
                            .accessibilityIdentifier("mode-" + String(describing: mode))
                            .accessibilityValue(store.mode == mode ? tabletopPhase : "")
                    }
                }
            }
            tabletopActionLayout {
                Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                    Text(store.selected.isEmpty ? "復原" : "取消").font(.subheadline).frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).disabled(store.selected.isEmpty && !store.canUndoHumanDecision)
                    .accessibilityIdentifier("undoOrCancel")
                Button(action: store.confirm) {
                    VStack(spacing:1) {
                        Label(sellLook && store.preview?.success == true ? store.mode == .skill ? "確認施法" : store.mode == .summon ? "確認召喚" : "確認落子" : "確認",systemImage:store.isPresenting ? "hourglass" : store.preview?.success == true ? "checkmark.seal.fill" : "checkmark").font(.headline)
                        if sellLook && !compact && store.preview?.success != true { Text(store.isPresenting ? "結果演出中" : "先選合法目標").font(.caption2) }
                    }.frame(maxWidth:.infinity,minHeight:compact ? 44 : sellLook ? 52 : 44)
                }.matchButtonStyle(commercial:sellLook,confirm:true)
                    .disabled(store.isPresenting || store.isComputerTurn || store.preview?.success != true)
                    .accessibilityIdentifier("playConfirm").accessibilityValue(store.preview?.success == true ? "可確認" : "等待合法預覽")
                Button(action: store.endTurn) {
                    Text("結束回合").font(.subheadline).frame(minWidth: 72, minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain)
                    .disabled(store.isPresenting || store.state.status != .ongoing || store.isComputerTurn || lesson != nil)
                    .accessibilityIdentifier("playEndTurn")
            }
        }
        .foregroundStyle(Cozy.ink)
        .padding(sellLook ? compact ? 8 : 10 : 0).padding(.top,sellLook ? 0 : 10)
        .background { if sellLook { SellOperationSurface() } }
        .overlay(alignment:.top) { if !sellLook { Rectangle().fill(Cozy.ink.opacity(0.14)).frame(height:1).accessibilityHidden(true) } }
    }

    /// The same two-line space serves idle, partial, illegal and valid preview.
    /// Changing selection must never move the board or the confirmation target.
    private func compactActionSummary(_ summary: SellActionSummary?) -> some View {
        Group {
            if let summary {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.effect).font(.subheadline.weight(.bold))
                        .lineLimit(1).minimumScaleFactor(0.9).accessibilityIdentifier("sellPreviewEffect")
                    HStack(spacing: 4) {
                        Text(summary.cost).font(.caption.weight(.semibold)).foregroundStyle(Cozy.deepMage)
                            .lineLimit(1).minimumScaleFactor(0.85).accessibilityIdentifier("sellPreviewCost")
                        Spacer(minLength: 0)
                        if let consequence = summary.consequence {
                            Text(consequence).font(.caption2).foregroundStyle(Cozy.muted)
                                .lineLimit(1).minimumScaleFactor(0.85).accessibilityIdentifier("sellPreviewConsequence")
                        }
                    }
                }
            } else if complete || store.isBotActing || store.state.status != .ongoing || store.preview?.success == false {
                Text(complete ? "已完成目標；可以復原重試或回到選角。" : presentedMessage)
                    .font(.caption).foregroundStyle(Cozy.muted).lineLimit(2)
                    .accessibilityIdentifier("playMessage")
                    .accessibilityValue(store.isBotActing ? "\(store.botActionIndex)/\(store.botActionCount) \(store.botMotionStartedAt == nil ? "準備" : "落定")" : "")
            } else if !store.selected.isEmpty {
                Text(tabletopPhase).font(.caption).foregroundStyle(Cozy.muted)
                    .lineLimit(2).accessibilityIdentifier("sellPhase")
            } else {
                Color.clear.accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: compactSummaryHeight, alignment: .center)
    }

    private func legacyMatch(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let wide = size.width >= 900 && size.width > size.height
        let width = min(size.width - (tablet ? 48 : 8), wide ? 1220 : tablet ? 736 : 626)
        let compactTablet = tablet && !wide && size.height < 1200
        let extra = (store.state.status == .ongoing ? 0.0 : 52.0)
            + (store.mode == .skill && hero == .mage && store.state.config.experimentalFriendlyRedeploy ? 38.0 : 0.0)
        let portraitWidth = tablet && !wide ? min(width,max(320,(size.height - (compactTablet ? 470 : 550) - extra) / 1.125)) : width
        return ScrollView {
        return VStack(spacing: tablet ? 14 : 6) {
            matchHeader()
            if wide {
                HStack(alignment: .center, spacing: 24) {
                    let boardWidth = min(width - 344, max(240, (size.height - 110) / 1.125))
                    board.frame(width: boardWidth, height: boardWidth * 1.125)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    ScrollView {
                        VStack(spacing: 16) {
                            playerStrip(.one); playerStrip(.two)
                            botStatus; matchBanners
                            actionPanel(tablet: true, sidebar: true)
                        }.padding(18)
                    }.frame(width: 320)
                        .background(Cozy.ink.opacity(0.045), in: RoundedRectangle(cornerRadius: 22))

                }
            } else {
                HStack(spacing: 8) { playerStrip(.one); playerStrip(.two) }
                botStatus; matchBanners
                board.frame(width: portraitWidth, height: portraitWidth * 1.125)
                    .frame(maxWidth: .infinity)
                actionPanel(tablet: tablet && !compactTablet, sidebar: false)
            }
        }.font(.system(size: tablet ? 16 : 14))
            .padding(.horizontal, tablet ? 24 : 4).padding(.vertical, tablet ? 16 : 6)
            .frame(maxWidth: wide ? 1268 : tablet ? 784 : 650)
        }.defaultScrollAnchor(.top)
    }
    private func matchHeader(compact:Bool = false, battleFocus:Bool = false) -> some View {
            HStack {
                Button { confirmExit = true } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).frame(width: 44, height: 44) }.accessibilityLabel("返回選角")
                VStack(alignment: .leading, spacing: 2) {
                    Text(battleFocus && store.state.status == .ongoing ? "\(side)回合 · \(store.state.ply)" : sellLook && store.state.status == .ongoing ? "輪到" + side : turnTitle).font(compact ? .headline.weight(.heavy) : .title2.weight(.heavy))
                        .foregroundStyle(sellLook ? SellTheme.paper : Cozy.ink)
                        .accessibilityLabel(turnTitle)
                        .accessibilityValue(store.recordRules == .redeployment ? "新版技能" : "舊版規則")
                        .accessibilityIdentifier("currentTurn")
                    if !battleFocus || lesson != nil { Text(lesson?.rawValue ?? "第 \(store.state.ply) 回合 · \(store.computer == nil ? "本機雙人" : "單人・你執\(store.humanPlayer == .one ? "黑" : "白")")")
                        .font(.system(size:11)).foregroundStyle(sellLook ? SellTheme.lightMuted : Cozy.ink.opacity(0.65))
                    }
                    if battleFocus && (store.isBotThinking || store.isBotActing) {
                        HStack(spacing: 3) {
                            Text(store.isBotThinking ? "電腦思考中" : "電腦下棋中 · \(store.botActionIndex)/\(store.botActionCount)")
                            if store.isBotActing {
                                Text(store.botMotionStartedAt == nil ? "準備" : "落定")
                                    .accessibilityIdentifier("botActionStatus")
                                    .accessibilityValue("\(store.botActionIndex)/\(store.botActionCount) \(store.botActionLabel)")
                            }
                        }.font(.system(size: 11)).foregroundStyle(SellTheme.lightMuted)
                            .accessibilityElement(children: .combine).accessibilityIdentifier("botStatus")
                            .accessibilityValue("已完成\(store.botTurnsCompleted)電腦回合")
                    }
                }
                Spacer()
                if battleFocus && presentedResult == nil {
                    Button { showActionHelp = true } label: {
                        Image(systemName: "info.circle").font(.system(size: 20)).frame(width: 44, height: 44)
                    }.accessibilityLabel("操作與技能說明").accessibilityIdentifier("actionHelp")
                }
                Menu {
                    challengeEntry
                    if store.canCreateCandidateCopy {
                        Button("建立新版技能續玩副本") { store.createCandidateCopy() }
                            .accessibilityIdentifier("candidateCopy")
                    }
                    Button("復原", action: store.undo).disabled(!store.canUndoHumanDecision)
                    Button("格點清單") { showGrid = true }
                    Button("遊戲規則") { showRules = true }
                    Button("重新開始") {
                        if let fixture = store.r2Fixture { _ = store.startR2(fixture,rules:store.r2Rules) }
                        else if let lesson { startPractice(lesson) } else { startMatch(rules: store.recordRules) }
                    }
                    Button("存局與棋譜") { store.cancelBotWork(); store.refreshRecords(); showRecords = true }.accessibilityIdentifier("matchRecords")
                    Button("聲音設定") { showSoundSettings = true }.accessibilityIdentifier("audioSettings")
                    if store.computer != nil {
                        Button(store.botDifficulty == .easy ? "難度：簡單 ✓" : "改為簡單") { store.setBotDifficulty(.easy) }
                            .accessibilityIdentifier("difficulty-easy")
                        Button(store.botDifficulty == .standard ? "難度：標準 ✓" : "改為標準") { store.setBotDifficulty(.standard) }
                            .accessibilityIdentifier("difficulty-standard")
                        #if DEBUG
                        Menu("AI 研究") {
                            Button(store.botPolicy == .baseline ? "原版 AI ✓" : "原版 AI") { store.setBotPolicy(.baseline) }
                                .accessibilityIdentifier("ai-original")
                            Button(store.botPolicy == .materialThreatContinuation ? "安全續攻候選 ✓" : "安全續攻候選（標準）") { store.setBotPolicy(.materialThreatContinuation) }
                                .disabled(store.botDifficulty != .standard).accessibilityIdentifier("ai-material-threat")
                        }.accessibilityIdentifier("aiPolicyMenu")
                        #endif
                    }
                    #if DEBUG
                    if store.computer != nil { Button("電腦決策紀錄") { showBotLog = true } }
                    #endif
                } label: { Image(systemName: "ellipsis.circle").font(.system(size: 20)).frame(width: 44, height: 44) }.accessibilityLabel("對戰選單")
            }
    }
    @ViewBuilder private var botStatus: some View {
            if store.computer != nil && presentedResult == nil {
                HStack(spacing: 6) {
                    if store.isBotThinking { ProgressView().controlSize(.small) }
                    Text(store.isBotThinking ? "電腦思考中" : store.isBotActing ? "電腦下棋中 · \(store.botActionIndex)/\(store.botActionCount)" : isResolvingTerminalPlayback ? "行動演出中" : store.state.status == .ongoing ? "你的回合 · \(store.humanPlayer == .one ? "黑方" : "白方")" : "對戰完成")
                        .font(.system(size: 12, weight: .semibold))
                    if store.isBotActing {
                        Text(store.botMotionStartedAt == nil ? "準備" : "落定")
                            .font(.system(size: 11)).foregroundStyle(sellLook ? SellTheme.lightMuted : Cozy.muted)
                            .accessibilityIdentifier("botActionStatus")
                            .accessibilityValue("\(store.botActionIndex)/\(store.botActionCount) \(store.botActionLabel)")
                    }
                    Spacer()
                    Text(store.botDifficulty == .easy ? "簡單" : store.botPolicy == .materialThreatContinuation ? "標準 · 續攻候選" : "標準").font(.system(size: 11)).foregroundStyle(sellLook ? SellTheme.lightMuted : Cozy.muted)
                }.frame(height: 22).accessibilityElement(children: .combine).accessibilityIdentifier("botStatus")
                    .accessibilityValue("已完成\(store.botTurnsCompleted)電腦回合")
            }
    }
    @ViewBuilder private var matchBanners: some View {
            if !sellLook && store.recordRules == .redeployment && presentedResult == nil {
                Text("新版技能 · 沿棋群築壘／法師調度己兵")
                    .font(.caption).foregroundStyle(sellLook ? SellTheme.lightMuted : Cozy.muted).accessibilityIdentifier("matchRulesSummary")
            }
            if store.r2Fixture != nil { Text("R2 \(store.r2Rules.variant) 試驗 · \(store.r2Rules.labDescription)").font(.caption).foregroundStyle(sellLook ? SellTheme.lightMuted : Cozy.muted).accessibilityIdentifier("r2Banner") }
            if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
            if !sellLook, let title = presentedResult {
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
                    Image(uiImage: visuals.portrait(hero.art)).resizable().scaledToFit().frame(width: tablet ? 72 : 48, height: tablet ? 72 : 48)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(hero.title + " · " + (store.mode == .skill ? hero.skillTitle : store.mode.rawValue)).font(.system(size: tablet ? 18 : 14, weight: .bold)).lineLimit(1)
                        Text(modeHelp).font(.system(size: tablet ? 15 : 12)).foregroundStyle(Cozy.ink.opacity(0.75)).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }.frame(minHeight: 50).padding(8).background(Cozy.card, in: RoundedRectangle(cornerRadius: 12)).shadow(color: Cozy.ink.opacity(0.10), radius: 1, y: 2)
            }
            Text(complete ? "已完成目標；可以復原重試或回到選角。" : presentedMessage)
                .font(.system(size: tablet ? 15 : 12)).foregroundStyle(Cozy.muted).frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
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
                        }.buttonStyle(CozyButton(selected: store.pushDirection == direction))
                            .disabled(store.isComputerTurn || !store.availableDirections.contains(direction)).accessibilityIdentifier("push-" + direction.rawValue)
                    }
                }
            } else {
                HStack(spacing: 6) {
                    ForEach(GameStore.Mode.allCases, id: \.self) { mode in
                        Button { store.changeMode(mode) } label: {
                            Text(mode == .skill ? hero.skillTitle : mode.rawValue).font(.system(size: tablet ? 16 : 13, weight: .bold)).frame(maxWidth: .infinity).frame(minHeight: tablet ? 48 : 38)
                        }.buttonStyle(CozyButton(selected: store.mode == mode))
                            .disabled(store.state.status != .ongoing || store.isComputerTurn).accessibilityIdentifier("mode-" + String(describing: mode))
                    }
                }
            }
            if sidebar {
                Button(action: store.confirm) { Text("確認行動").bold().frame(maxWidth: .infinity, minHeight: 48) }
                    .buttonStyle(CozyButton(confirm: true))
                    .disabled(store.isPresenting || store.isComputerTurn || store.preview?.success != true).accessibilityIdentifier("playConfirm")
                HStack(spacing: 10) {
                    Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                        Text(store.selected.isEmpty ? "復原" : "取消").frame(maxWidth: .infinity, minHeight: 46)
                    }.buttonStyle(CozyButton()).disabled(store.selected.isEmpty && !store.canUndoHumanDecision).accessibilityIdentifier("undoOrCancel")
                    Button(action: store.endTurn) { Text("結束回合").frame(maxWidth: .infinity, minHeight: 46) }
                        .buttonStyle(CozyButton()).disabled(store.isPresenting || store.state.status != .ongoing || store.isComputerTurn || lesson != nil).accessibilityIdentifier("playEndTurn")
                }
            } else {
            HStack(spacing: 8) {
                Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                    Text(store.selected.isEmpty ? "復原" : "取消").frame(minWidth: 48, minHeight: tablet ? 48 : 40)
                }.buttonStyle(CozyButton()).disabled(store.selected.isEmpty && !store.canUndoHumanDecision).accessibilityIdentifier("undoOrCancel")
                Button(action: store.confirm) { Text("確認").bold().frame(maxWidth: .infinity, minHeight: tablet ? 48 : 40) }
                    .buttonStyle(CozyButton(confirm: true))
                    .disabled(store.isPresenting || store.isComputerTurn || store.preview?.success != true).accessibilityIdentifier("playConfirm")
                Button(action: store.endTurn) { Text("結束回合").frame(minHeight: tablet ? 48 : 40) }.buttonStyle(CozyButton())
                    .disabled(store.isPresenting || store.state.status != .ongoing || store.isComputerTurn || lesson != nil).accessibilityIdentifier("playEndTurn")
            }
            }
        }
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
                    .font(.system(size: 10, weight: .bold)).foregroundStyle(active ? Cozy.ink : Cozy.muted)
            }
            HStack(spacing: 4) {
                if store.computer != nil {
                    Text(player == store.computer ? "電腦" : "你")
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(Cozy.muted)
                }
                Text("能量 \(state.mana(of: player))/\(state.config.manaCap) · \(liberties) 氣")
                    .font(.system(size: 11)).foregroundStyle(liberties <= 1 ? Color.redTeam : Cozy.ink.opacity(0.65))
                Spacer(minLength: 0)
                if active { Text("\(store.isBotActing && state.current != player ? 0 : state.apRemaining) AP").font(.system(size: 11, weight: .bold)) }
            }
        }.font(.system(size: 12)).padding(8)
            .background(active ? Cozy.ink.opacity(0.10) : Cozy.ink.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(active ? Cozy.ink : Cozy.muted.opacity(0.2), lineWidth: active ? 1.5 : 0.5))
            .accessibilityIdentifier(player == .one ? "blueResources" : "redResources")
    }
    private var board: some View {
        let canSelect = store.state.status == .ongoing
        let data = BoardPresentation(state: store.state, selected: canSelect ? store.selected : [],
                                     legal: canSelect ? store.legalTargets : [], preview: canSelect ? store.preview : nil)
        return ZStack(alignment: .topTrailing) {
            Group {
                if let cozyAssets {
                    CozyBoard(presentation: data, assets: cozyAssets, playback: store.playback,
                              botPlayback: store.isBotActing ? store.playback : nil, botStartedAt: store.botMotionStartedAt,
                              animating: store.isPresenting || (store.isBotActing && store.botMotionStartedAt != nil), reducedMotion: reduceMotion || cozyReduced, checkpoint: nil, effectsEnabled: mageEffectsEnabled, mageRevision: mageRevision, markerStyle: mageMarkers, commercialStyle:sellLook, select: { point in
                                  if canSelect { store.select(point) }
                              })
                } else { Text("Cozy 素材校驗失敗；請重新安裝候選。").foregroundStyle(Cozy.danger) }
            }
                .accessibilityElement(children: .ignore).accessibilityIdentifier("playArena")
                .accessibilityLabel("\(store.size)乘\(store.size)棋盤")
                .accessibilityValue(canSelect ? store.selected.map(coordinate).joined(separator: ",") : "終局棋盤")
            #if DEBUG
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
        }
    }
    private var accessibleGrid: some View {
        NavigationStack {
            List(store.state.board.points, id: \.self) { point in
                Button {
                    guard store.state.status == .ongoing else { return }
                    store.select(point); showGrid = false
                } label: {
                    HStack { Text(coordinate(point)); Text(cellDescription(point)); Spacer(); if store.state.status == .ongoing && store.legalTargets.contains(point) { Text("可選").foregroundStyle(.green) } }
                }.disabled(store.state.status != .ongoing).accessibilityIdentifier("cell-\(point.x)-\(point.y)")
            }.navigationTitle(store.state.status == .ongoing ? "選擇棋盤格點" : "終局棋盤")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showGrid = false } } }
        }
    }
    private var rules: some View {
        NavigationStack {
            List {
                Section("勝利") { Text("包圍敵方主將所在的棋串，使它沒有相鄰空點（氣），提走主將即可獲勝。斜角不算相鄰。") }
                Section("回合與資源") { Text("首回合 1 AP，其後 2 AP。每次行動 1 AP；耗盡 AP 自動換手。每回合增加 1 能量，上限 6。也可提早結束回合。100 回合未分勝負則和局。") }
                Section("英雄") { Text("召喚在任一己方棋子相鄰空點。戰士與盜賊需 2 能量，法師需 3。英雄被提走後，本局不能再召喚。") }
                ForEach(heroes, id: \.self) { h in
                    Section(h.title + " · " + h.skillTitle) {
                        Text(h.skillHelp(config: inMatch ? store.state.config : GameStore.defaultMatchRules.config(size: boardSize)) + "\n技能需 1 AP＋2 能量，每回合只能使用一次。")
                    }
                }
                Section("合法行動") { Text("先處理敵方提子，再檢查己方是否無氣。禁止自殺與重複任何先前盤面。預覽不扣資源；復原會還原完整盤面、回合、資源與歷史。") }
            }.navigationTitle("遊戲規則").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showRules = false } } }
        }
    }
    private func coordinate(_ p: Point) -> String { String(UnicodeScalar(65 + p.x)!) + String(p.y + 1) }
    private func cellDescription(_ p: Point) -> String {
        guard let piece = store.state.board[p] else { return "空點" }
        return (piece.owner == .one ? "黑方 " : "白方 ") + (piece.kind == .hero ? store.state.heroClass(of: piece.owner).title : piece.kind == .commander ? "主將" : "士兵")
    }
    private func resumeRecord(_ record: MatchRecord) {
        if store.resume(record) {
            one = record.one; two = record.two; boardSize = record.size
            singlePlayer = record.computer != nil; humanSide = record.computer?.opponent ?? .one
            lesson = nil; inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn()
        }
    }
    private func startMatch() {
        #if DEBUG
        // Historical-save regression only; no old-rule selector exists in Release.
        if ProcessInfo.processInfo.arguments.contains("--original-rules") { startMatch(rules: .original); return }
        #endif
        startMatch(rules: GameStore.defaultMatchRules)
    }
    private func startMatch(rules: RecordRules) {
        guard access.canStartMatch else { pendingMatchRules = rules; showUnlock = true; return }
        guard store.newMatch(classOne: one, classTwo: two, computer: singlePlayer ? humanSide.opponent : nil, rules: rules,
                             requestedSize: singlePlayer ? 7 : boardSize, authorize: { id in try access.authorizeNewMatch(id: id) }) else { return }
        lesson = nil; inMatch = true; store.setMatchAudioActive(true)
        store.scheduleComputerTurn()
    }
    private func startPractice(_ value: PracticeLesson) { lesson = value; store.startPractice(value); inMatch = true; store.setMatchAudioActive(true) }
}

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
                #if DEBUG
                Section("英雄語音") {
                    Toggle("英文英雄語音", isOn: $audio.voiceEnabled).accessibilityIdentifier("voiceEnabled")
                    Slider(value: $audio.voiceVolume, in: 0...1).accessibilityIdentifier("voiceVolume")
                    Text("\(Int(audio.voiceVolume * 100))% · VO-01 原型，正式聲線待驗收")
                }
                #endif
                Section("音樂音量") {
                    Toggle("背景音樂", isOn: $audio.musicEnabled).disabled(!audio.musicIntegrationAllowed).accessibilityIdentifier("musicEnabled")
                    if !audio.musicIntegrationAllowed { Text("目前為靜音動作檢視；一般對戰可播放背景音樂。").font(.caption) }
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
