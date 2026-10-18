import SwiftUI
import TacticalGoCore
import TacticalGoBot
import TacticalGoRecords
import TacticalGoContent
import TacticalGoVisuals

/// The 1.1 expansion shell (priest, second skills, monsters, solo expansion, practice). The 1.0 shell keeps its own
/// look and is the product entry; this view is opened from the 1.0 lobby through an explicit entry and shares the
/// 1.0 PlayAccess gate so expansion matches are metered like any other full match.
/// Challenge campaigns offered by the product-mode lobby (same content as the original shell's challenge entry).
private enum ProductChallengeRoute: String, Identifiable {
    case introduction, advanced
    var id: String { rawValue }
    var campaign: ChallengeCampaign { self == .advanced ? .advanced : .introduction }
}

struct ExpansionGameView: View {
    /// Shared with the 1.0 shell. `nil` only in previews and the DEBUG expansion lab, where nothing is metered.
    var access: PlayAccess? = nil
    var onClose: (() -> Void)? = nil
    @State private var showPrivacy = false
    /// Why the unlock sheet is open. The lobby bar's entry only manages purchases; it must not start a match.
    /// Carried by `sheet(item:)`: a flag read only inside the sheet closure reached the first presentation stale.
    @State private var unlockRequest: UnlockRequest?
    @State private var challengeRoute: ProductChallengeRoute?
    @State private var adIsPresented = false
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
    @State private var showLootAbilities = false
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
    #if DEBUG
    @State private var polishReviewUsed = false
    /// Which step the autoplay review reached, or why it stopped; UI tests read it instead of only timing out.
    @State private var polishStatus = "polish: idle"
    #endif
    
    private var heroes: [HeroClass] {
        useExpansion ? HeroClass.allCases.filter { $0 != .none } : HeroClass.originalClasses
    }
    private func portrait(_ h: HeroClass) -> UIImage {
        #if DEBUG || TACTICALGO_V11
        // The other three are upper-body portraits; the priest's is a redrawn upper-body portrait of the same P08
        // character (assets/candidates/priest-portrait-redraw-v01, 512px here). The full figure stays on the board.
        if h == .priest, let bust = UIImage(named:"priest-portrait-v03") { return bust }
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
    /// Launch settlement shared by both shells (idempotent): interrupted starts are only settled once the entitlement
    /// check is done; completions of finished matches (original records and the expansion slot) are reconciled.
    private func settleProductLaunch() {
        guard let access else { return }
        var terminalIDs: [UUID] = []
        if productMode {
            terminalIDs = store.savedRecords.compactMap { record -> UUID? in
                guard let status = record.steps.last?.after.status, status != .ongoing else { return nil }
                return record.id
            }
        }
        if !access.purchase.isChecking {
            if productMode { store.recoverInterruptedStarts(isUnlocked: access.purchase.isUnlocked, isRegistered: { access.registration(of: $0) }) }
            #if DEBUG || TACTICALGO_V11
            GameStore.recoverExpansionStart(isUnlocked: access.purchase.isUnlocked, isRegistered: { access.registration(of: $0) })
            #endif
        }
        #if DEBUG || TACTICALGO_V11
        if let saved = ExpansionLabStore.savedTerminalIdentity() { terminalIDs.append(saved) }
        #endif
        if !terminalIDs.isEmpty { access.reconcileCompletedMatches(ids: terminalIDs) }
    }
    /// Product mode (Owner decision 2026-10-15, "use 1.1 for everything"): this shell is the app's root, carries the
    /// 1.0 commercial layer (allowance, purchase, privacy/support, challenges) and offers the original rules as an option.
    private var productMode: Bool { access != nil && onClose == nil }
    private var uiInk: Color { GameChrome.cream }
    private var uiSecondary: Color { GameChrome.muted }
    private var uiAccent: Color { GameChrome.gold }
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
        .background(GameBackdrop())
        .foregroundStyle(uiInk).tint(uiAccent).preferredColorScheme(.dark)
        .buttonStyle(GameButtonStyle(padded: true))
        .sheet(isPresented: $showRules) { rules }
        .sheet(isPresented: $showTacticalHelp) { tacticalHelp }
        .sheet(item: $unlockRequest, onDismiss: { RewardedAdService.shared.cancelPendingRequest() }) { request in
            if let access {
                let fromBar = request == .store
                UnlockView(access: access, continueGame: { if !fromBar { startMatch() } }, continueTitle: fromBar ? "返回遊戲" : "開始下一局", storeEntry: fromBar, presentationChanged: { presented in
                    store.setSceneAudioActive(!presented && scenePhase == .active)
                })
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) { OnboardingView { showOnboarding = false } }
        .sheet(isPresented: $showPrivacy) {
            if let access {
                ReleaseInformationView(access: access, presentationChanged: { presented in
                    adIsPresented = presented
                    store.setSceneAudioActive(!presented && scenePhase == .active)
                })
            }
        }
        .fullScreenCover(item: $challengeRoute, onDismiss: {
            store.setMatchAudioActive(inMatch)
            if inMatch { store.scheduleComputerTurn() }
        }) { route in
            ChallengesView(campaign: route.campaign) { challengeRoute = nil }.id(route.id)
        }
        // Recovery discards unadmitted, unplayed starts, so it must know whether the player owns the unlock.
        .onChange(of: access?.purchase.isChecking) { _, _ in settleProductLaunch() }
        .sheet(isPresented: $showGrid) { accessibleGrid }
        .alert("離開目前對戰？", isPresented: $confirmExit) {
            Button("返回選角", role: .destructive) { store.leaveMatch(); inMatch = false; lesson = nil }.accessibilityIdentifier("exitMatchConfirmed")
            Button("留在對戰", role: .cancel) {}
        }
        .onDisappear { store.cancelBotWork(); store.setMatchAudioActive(false) }
        .onChange(of: inMatch) { _, playing in if !playing { returnToLatestRules() } }
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
            if let match = store.expansion { IntegratedExpansionSoundSettings(store:match,background:store.audio,close: { showSoundSettings = false }) }
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
            if ProcessInfo.processInfo.arguments.contains("--polish-autoplay") { Text(polishStatus).font(.system(size:8)).accessibilityIdentifier("polishReviewStatus") }
            if ProcessInfo.processInfo.arguments.contains("--integrated-audio-audit") || ProcessInfo.processInfo.arguments.contains("--integrated-volume-audit") || ProcessInfo.processInfo.arguments.contains("--integrated-cadence-audit") {
                Text(audioAuditStatus).accessibilityIdentifier("integratedAudioAudit").padding().background(Color.ink)
            }
            #endif
        }
        #if DEBUG
        .task(id:scenePhase) { await runPolishReview() }
        #endif
        .onAppear {
            if let access {
                store.onMatchCompleted = { id in access.completedMatch(id: id) }
                if productMode {
                    selectedRules = GameStore.defaultMatchRules
                    store.authorizeContinuation = { copy, parent in
                        // A verified owner is never metered, and an unrelated damaged trial file must not block a copy.
                        if access.purchase.isUnlocked { return }
                        try access.continueMatch(copy: copy, of: parent)
                    }
                }
                settleProductLaunch()
            }
            store.setSceneAudioActive(scenePhase == .active)
            store.setMatchAudioActive(inMatch)
            #if DEBUG
            let args = ProcessInfo.processInfo.arguments
            if args.contains("--original-rules") { useExpansion = false }
            if let i = args.firstIndex(of:"--integrated-practice"),args.indices.contains(i+1),let value = ExpansionPractice(rawValue:args[i+1]) {
                store.expansionPractice(value); boardSize = store.size; one = store.state.heroClass(of:.one); two = store.state.heroClass(of:.two)
                // Review item 6: a recordable match (legal opening) where Black can afford the priest's Sanctum (4).
                if args.contains("--integrated-sanctum-ready") { store.expansion?.passTurnsForTest(untilBlackMana: 4) }
                inMatch = true; store.setMatchAudioActive(true)
            }
            if let i = args.firstIndex(of:"--polish-monster"),args.indices.contains(i+1),let value = MonsterPresentationPractice(rawValue:args[i+1]) {
                store.startExpansion(one:.warrior,two:.mage,size:9,monsters:value.kind == .slime ? .slime:.wolf)
                store.expansion?.monsterReview(value);boardSize = 9;one = .warrior;two = .mage
                inMatch = true;store.setMatchAudioActive(true)
            }
            if args.contains("--solo-warrior-review") {
                useExpansion = true;singlePlayer = true
                store.startExpansion(one:.warrior,two:.mage,size:9,monsters:.none,computer:.one)
                store.expansion?.warriorBotReview();store.expansion?.muted = false;boardSize = 9
                inMatch = true;store.setMatchAudioActive(true);store.scheduleComputerTurn()
            }
            if args.contains("--quality-warrior-fixture"),let match = store.expansion {
                let qualitySize = args.contains("--quality-seven") ? 7:9
                let owner:Player = args.contains("--quality-white") ? .two:.one
                do {
                    try match.qualityWarriorReview(owner:owner,size:qualitySize,dense:!args.contains("--quality-sparse"))
                    boardSize = qualitySize;one = match.state.heroClass(of:.one);two = match.state.heroClass(of:.two)
                } catch { match.message = "工程棋形載入失敗：\(error)" }
            }
            if args.contains("--onboard") { showOnboarding = true }
            if args.contains("--integrated-audio-audit") { Task { audioAuditStatus = await IntegratedAudioAudit.run() } }
            if args.contains("--integrated-volume-audit") { Task { audioAuditStatus = await IntegratedAudioAudit.runVolumes() } }
            if args.contains("--integrated-cadence-audit") { Task { audioAuditStatus = await IntegratedAudioAudit.runVoiceCadence() } }
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
    #if DEBUG
    /// Recording-only input follows the same preview/confirm path as a human.
    private func runPolishReview() async {
        let args = ProcessInfo.processInfo.arguments
        guard scenePhase == .active,!polishReviewUsed,args.contains("--polish-autoplay") else { return }
        func value(after flag:String) -> String? {
            guard let i = args.firstIndex(of:flag),args.indices.contains(i+1) else { return nil }
            return args[i+1]
        }
        let fixture = value(after:"--integrated-practice").flatMap(ExpansionPractice.init(rawValue:))
        let monsterFixture = value(after:"--polish-monster").flatMap(MonsterPresentationPractice.init(rawValue:))
        guard fixture != nil || monsterFixture != nil else { polishStatus = "polish: stopped - no --integrated-practice or --polish-monster fixture"; return }
        polishReviewUsed = true
        // The 3 s preparation and 0.8 s preview are authored windows (testPolishAutoplayBackgroundNeverCommitsOnReturn
        // backgrounds the app inside them); each step reports where it stopped instead of failing silently.
        polishStatus = "polish: preparing (3 s window)"
        do { try await Task.sleep(for:.seconds(3)) } catch { polishStatus = "polish: stopped - preparation cancelled (scene changed)"; return }
        guard inMatch else { polishStatus = "polish: stopped - no match on screen after preparation"; return }
        guard scenePhase == .active else { polishStatus = "polish: stopped - scene not active after preparation"; return }
        guard let match = store.expansion else { polishStatus = "polish: stopped - no expansion match"; return }
        // Fixed review conditions only; never write the owner's persisted sound preferences.
        match.configureReviewSound(voiceEnabled:!args.contains("--polish-voice-off"))
        if args.contains("--polish-body-only") { match.effects = false }
        if args.contains("--polish-reduced") { match.reduced = true }
        let basic = args.contains("--polish-basic") || fixture == .priest
        let points: [Point]
        let action: GameAction
        if args.contains("--quality-warrior-fixture") {
            points = [Point(2,3),Point(4,3)];action = .castBastion(points[0],points[1])
        } else if let monsterFixture {
            points = monsterFixture.points;action = monsterFixture.action
            match.ability = monsterFixture.kind == .slime ? .stickyBounce:.shadowStep
            store.changeMode(monsterFixture.isHunt ? .soldier:.loot)
        } else if let fixture,basic {
            switch fixture {
            case .warrior: points = [Point(5,5),Point(6,6)];action = .castBastion(points[0],points[1])
            case .mage: points = [Point(4,5),Point(5,5)];action = .castFriendlyRedeploy(points[0],points[1])
            case .rogue: points = [Point(5,4)];action = .castSwap(points[0])
            case .priest: points = [Point(4,5)];action = .castOffering(points[0])
            }
        } else if let fixture {
            action = fixture.action
            switch action {
            case .castReformation(let a,let b),.castDoublePull(let a,let b): points = [a.from,a.to,b.from,b.to]
            case .castChainSwap(let a,let b): points = [a,b]
            default: return
            }
        } else { return }
        let before = match.state,generation = match.generation
        let expected = GameEngine.apply(before,action)
        guard expected.success else { polishStatus = "polish: stopped - fixture action illegal: \(expected.reason) (\(action))"; return }
        if monsterFixture == nil { store.changeMode(basic ? .skill:.advanced) }
        for p in points { store.select(p) }
        guard match.state == before else { polishStatus = "polish: stopped - board changed while selecting"; return }
        guard let preview = match.preview else { polishStatus = "polish: stopped - no preview after selecting \(points) in mode \(match.mode)"; return }
        guard preview.success else { polishStatus = "polish: stopped - preview illegal: \(preview.reason)"; return }
        polishStatus = "polish: preview legal, showing (0.8 s window)"
        do { try await Task.sleep(for:.milliseconds(800)) } catch { polishStatus = "polish: stopped - preview window cancelled"; return }
        guard inMatch,scenePhase == .active,store.expansion === match else { polishStatus = "polish: stopped - match left or scene inactive before confirm"; return }
        guard match.state == before,match.generation == generation else { polishStatus = "polish: stopped - state changed before confirm"; return }
        let committedAt = ProcessInfo.processInfo.systemUptime
        store.confirm()
        polishStatus = match.state == expected.state ? "polish: committed" : "polish: stopped - confirm did not apply the action"
        let p = match.frameReceipt
        var report: [String:Any] = ["fixture":args.contains("--quality-warrior-fixture") ? "hand-placed-WarriorPresentationFixture":monsterFixture == nil ? "legal-opening-ExpansionPractice":"legal-opening-MonsterPresentationPractice","hero":before.heroClass(of:before.current).rawValue,
            "scene":monsterFixture?.rawValue ?? fixture?.rawValue ?? "unknown",
            "basic":basic,"action":String(describing:action),"success":match.state == expected.state,
            "before":before.board.diagram,"after":match.state.board.diagram,
            "beforeAP":before.apRemaining,"afterAP":match.state.apRemaining,
            "beforeMana":before.mana(of:before.current),"afterMana":match.state.mana(of:before.current),
            "commitUptime":committedAt,"release":p?.release ?? -1,"moveStart":p?.moveStart ?? -1,
            "arrival":p?.arrival ?? -1,"duration":p?.duration ?? -1,"soundKeys":match.lastSoundKeys]
        report["voiceEnabled"] = match.voice
        report["acceptedCues"] = match.cues
        report["soundSchedule"] = match.lastSoundSchedule.map { ["key":$0.key,"delay":$0.delay,"gain":$0.gain,"actualPlayerGain":$0.playerGain] as [String:Any] }
        if let i = args.firstIndex(of:"--polish-frame"),args.indices.contains(i+1),let time = Double(args[i+1]) {
            report["frameTime"] = time;report["frameFrozen"] = match.freezeConfirmedFrame(time)
            polishStatus = report["frameFrozen"] as? Bool == true ? "polish: frozen at \(time)" : "polish: stopped - freeze failed (no receipt or time outside the presentation)"
        }
        let url = FileManager.default.urls(for:.documentDirectory,in:.userDomainMask).first!.appendingPathComponent("polish-native-review.json")
        if let bytes = try? JSONSerialization.data(withJSONObject:report,options:[.prettyPrinted,.sortedKeys]) { try? bytes.write(to:url,options:.atomic) }
        print("POLISH_COMMIT uptime=\(committedAt) success=\(match.state == expected.state)")
    }
    #endif
    private func lobby(size: CGSize) -> some View {
        let tablet = size.width >= 600
        let wide = size.width >= 900 && size.width > size.height
        return ScrollView {
            VStack(spacing: tablet ? 22 : 18) {
                lobbyTitle
                if productMode { productBar }
                #if DEBUG || TACTICALGO_V11
                if FileManager.default.fileExists(atPath: ExpansionLabStore.savedURL.path) {
                    Button {
                        if store.resumeExpansion() {
                            useExpansion = true; singlePlayer = store.computer != nil; humanSide = store.humanPlayer; one = store.state.heroClass(of:.one); two = store.state.heroClass(of:.two); boardSize = store.size
                            inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn()
                        }
                    } label: { Label("續玩擴充玩法上局", systemImage: "play.circle").frame(maxWidth: .infinity, minHeight: 44) }
                        .buttonStyle(GameButtonStyle()).accessibilityIdentifier("resumeExpansion")
                }
                #endif
                if let record = store.resumableRecord {
                    Button { resumeRecord(record) } label: { Label(productMode ? "續玩原版規則上局" : "續玩上局", systemImage: "play.circle").frame(maxWidth:.infinity,minHeight:44) }
                        .buttonStyle(GameButtonStyle()).accessibilityIdentifier("resumeMatch")
                }
                Button { store.refreshRecords(); showRecords = true } label: {
                    Label("存局與棋譜", systemImage: "book.closed").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(GameButtonStyle()).accessibilityIdentifier("recordLibrary")
                if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
                if wide {
                    HStack(alignment: .top, spacing: 30) {
                        VStack(spacing: 18) { lobbySettings; boardSizePicker }
                            .padding(20).frame(width: 320)
                            .background(GamePanel())
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
    /// Allowance and the 1.0 commercial/compliance entries (all of them go through the shared `PlayAccess`).
    @ViewBuilder private var productBar: some View {
        if let access {
            VStack(spacing: 8) {
                Text(access.purchase.isUnlocked ? "已永久解鎖" : "免費完整對局剩餘 \(access.remainingTrialMatches)／3")
                    .font(.caption).foregroundStyle(uiSecondary).accessibilityIdentifier("accessStatus")
                HStack(spacing: 8) {
                    Menu {
                        Button("英雄技能入門 · 六關") { openProductChallenges(.introduction) }
                        Button("邊境攻防 · 三關") { openProductChallenges(.advanced) }
                    } label: { Label("戰術挑戰", systemImage: "flag.checkered").frame(maxWidth: .infinity, minHeight: 44) }
                        .accessibilityIdentifier("lobbyChallenges")
                    Button { unlockRequest = .store } label: {
                        Label("購買與恢復", systemImage: "cart").frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityIdentifier("purchaseSettings")
                    Button { showPrivacy = true } label: {
                        Label("隱私與支援", systemImage: "hand.raised").frame(maxWidth: .infinity, minHeight: 44)
                    }.accessibilityIdentifier("privacySupport")
                }.font(.system(size: 13, weight: .semibold)).buttonStyle(GameButtonStyle())
            }
        }
    }
    private func openProductChallenges(_ route: ProductChallengeRoute) {
        // Stop pending bot/presentation work without changing the current match or its journal.
        store.cancelBotWork()
        store.setMatchAudioActive(false)
        challengeRoute = route
    }
    private var lobbyTitle: some View {
                VStack(spacing: 5) {
                    if let onClose {
                        HStack {
                            Button { onClose() } label: { Label("返回主選單", systemImage: "chevron.left") }.accessibilityIdentifier("closeExpansion")
                            Spacer()
                        }
                    }
                    Text(productMode ? "皇冠戰略" : "TACTICAL GO").font(.system(size: 29, weight: .black, design: .serif)).tracking(2).foregroundStyle(uiAccent)
                    if productMode { Text("CROWN TACTICS").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(uiSecondary) }
                    Text("選擇英雄 · 包圍主將 · 一局決勝").font(.system(size: 14)).foregroundStyle(uiSecondary)
                }.padding(.top, 14)
    }
    private var lobbySettings: some View {
        VStack(spacing: 18) {
                Picker("對戰模式", selection: $singlePlayer) {
                    Text("本機雙人").tag(false); Text("電腦對戰").tag(true)
                }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("matchMode")
                    .onChange(of: singlePlayer) { _, solo in if solo { choosing = humanSide } }
                #if DEBUG || TACTICALGO_V11
                // Owner decision 2026-10-17 (TestFlight 1114): no play-style choice; every new match uses the latest rules.
                // Old original-rules saves can still be resumed (and restarted) from the lobby.
                if useExpansion {
                    Picker("魔物戰場",selection:$monsters) { ForEach(ExpansionLabStore.Monsters.allCases,id:\.self) { Text($0.rawValue).tag($0) } }
                        .accessibilityIdentifier("matchMonsters")
                        .onChange(of:monsters) { _, value in if value != .none { boardSize = 9 } }
                    if monsters != .none {
                        Text(SkillGuide.lobbyMonsters(monsters == .slime ? [.slime] : monsters == .wolf ? [.shadowWolf] : [.slime, .shadowWolf]))
                            .font(.system(size: 12)).foregroundStyle(uiSecondary).multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("monsterGuide")
                    }
                }
                #endif
                if singlePlayer {
                    Picker("你執哪方", selection: $humanSide) {
                        Text("黑方先手").tag(Player.one); Text("白方後手").tag(Player.two)
                    }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("humanSide")
                        .onChange(of: humanSide) { _, side in choosing = side }
                    Picker("電腦難度", selection: Binding(get: { store.botDifficulty }, set: { store.setBotDifficulty($0) })) {
                        Text("簡單").tag(BotDifficulty.easy)
                        Text("標準").tag(BotDifficulty.standard)
                    }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("botDifficulty")
                    Text(store.botDifficulty == .easy ? "適合先熟悉\(heroes.count == 4 ? "四" : "三")職技能與主將攻守。" : "會預判你的反擊，適合挑戰。")
                        .font(.system(size: 12)).foregroundStyle(uiSecondary)
                }
                if !useExpansion {
                Picker("技能規則", selection: $selectedRules) {
                    Text("原版").tag(RecordRules.original)
                    Text("新版技能").tag(RecordRules.redeployment)
                }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("matchRules")
                Text(selectedRules == .redeployment ? "戰士沿棋群築壘；法師可調度己兵。費用與每回合限制相同。" : "原版技能；對局中可從選單複製此局，改用新版技能續玩。")
                    .font(.caption).foregroundStyle(uiSecondary)
                }
                Picker("選擇哪一方", selection: $choosing) {
                    Text(singlePlayer ? (humanSide == .one ? "你 · 黑方 ●" : "電腦 · 黑方 ●") : "黑方 ●").tag(Player.one)
                    Text(singlePlayer ? (humanSide == .two ? "你 · 白方 ○" : "電腦 · 白方 ○") : "白方 ○").tag(Player.two)
                }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("choosingTeam")
        }
    }
    private func heroChoices(portraitHeight: CGFloat) -> some View {
                HStack(spacing: 8) {
                    ForEach(heroes, id: \.self) { h in
                        let selected = (choosing == .one ? one : two) == h
                        Button {
                            if choosing == .one { one = h } else { two = h }
                        } label: {
                            heroChoiceFace(h,selected:selected,portraitHeight:portraitHeight)
                        }.buttonStyle(.plain).accessibilityIdentifier("choose-" + h.art)
                            .accessibilityLabel(lobbyHeroLabel(h))
                            .accessibilityAddTraits(selected ? [.isSelected] : [])
                    }
                }
    }
    private func lobbyHeroLabel(_ h:HeroClass) -> String {
        let basic = h.title + "，" + lobbySkillTitle(h)
        return useExpansion ? basic + "，" + advancedSkillTitle(h) : basic
    }
    private func heroChoiceFace(_ h:HeroClass,selected:Bool,portraitHeight:CGFloat) -> some View {
        VStack(spacing:7) {
            Image(uiImage:portrait(h)).resizable().scaledToFit().frame(height:portraitHeight)
            Text(h.title).font(.system(size:17,weight:.bold))
            Text(lobbySkillTitle(h)).font(.system(size:12,weight:.semibold)).lineLimit(1)
            if useExpansion {
                // Every hero shows its second skill, so the four cards keep the same height.
                Text(advancedSkillTitle(h)).font(.system(size:11,weight:.semibold)).foregroundStyle(uiSecondary).lineLimit(1)
            }
        }.frame(maxWidth:.infinity).padding(.vertical,12)
            .background(GamePanel(active:selected,kind:.hero))
            .overlay(GameCutCorner().stroke(selected ? GameChrome.accent(h) : .clear,lineWidth:2))
            .overlay(alignment:.topTrailing) {
                if selected {
                    Image(systemName:"checkmark.seal.fill").font(.system(size:16,weight:.bold))
                        .foregroundStyle(GameChrome.cream).padding(5).accessibilityHidden(true)
                }
            }
    }
    private var updatedLobbySkills: Bool { useExpansion || selectedRules == .redeployment }
    private func lobbySkillTitle(_ hero: HeroClass) -> String {
        guard updatedLobbySkills else { return hero.skillTitle }
        return hero == .mage ? "調度己兵" : hero == .warrior ? "沿棋群築壘" : hero.skillTitle
    }
    @ViewBuilder private var chosenSkill: some View {
                let choice = choosing == .one ? one : two
                VStack(spacing: 6) {
                    Text(useExpansion ? SkillGuide.basic(choice) : updatedLobbySkills && choice == .warrior ? "在英雄相連棋群旁放兩兵；先選兩個不同空點。" : updatedLobbySkills && choice == .mage ? "調度法師2格內的相連己兵，移到原棋群旁空點。" : choice.skillHelp).font(.system(size: 14))
                        .accessibilityIdentifier("lobbySkillHelp")
                    Text("召喚 \(choice.summonCost) 能量 · 技能 1 AP＋2 能量 · 每回合一次").font(.system(size: 11)).foregroundStyle(uiAccent)
                    if useExpansion {
                        Text("第二技能 · \(advancedSkillTitle(choice))（1 AP＋\(TacticalHints.updatedConfig(size:boardSize).expansionSkillManaCost) 能量，與技能共用每回合一次）：" + SkillGuide.second(choice))
                            .font(.system(size:12)).foregroundStyle(uiSecondary).accessibilityIdentifier("lobbyAdvancedSkill")
                    }
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
                Picker("棋盤", selection: $boardSize) { Text("7 × 7").tag(7); Text("9 × 9").tag(9) }.pickerStyle(.segmented).padding(4).background(GamePanel()).accessibilityIdentifier("playBoardSize")
    }
    private var startControls: some View {
        VStack(spacing: 18) {
                Button(action: startMatch) { Label(singlePlayer ? "開始電腦對戰" : "開始本機雙人對戰", systemImage: "play.fill").frame(maxWidth: .infinity).frame(minHeight: 46) }
                    .buttonStyle(GameButtonStyle(kind: .primary)).tint(Color.gold).foregroundStyle(Color.ink).font(.system(size: 16, weight: .bold)).accessibilityIdentifier("startMatch")
                Button { showOnboarding = true } label: {
                    Label("新手教學 · 不需要懂圍棋", systemImage: "hand.tap")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(GameButtonStyle()).accessibilityIdentifier("startOnboarding")
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
                        ForEach(PriestSanctumPractice.allCases, id: \.self) { practice in
                            Button(practice.title) {
                                store.sanctumPractice(practice); boardSize = store.size; one = .priest; two = .mage
                                lesson = nil; inMatch = true; store.setMatchAudioActive(true)
                            }.accessibilityIdentifier("sanctumPractice-" + practice.rawValue)
                        }
                        Button("牧師：奉獻救援挑戰") {
                            store.expansionChallenge(); boardSize = store.size; one = .priest; two = .mage
                            lesson = nil; inMatch = true; store.setMatchAudioActive(true)
                        }.accessibilityIdentifier("priestChallenge")
                        #endif
                    } label: { Label("玩法練習", systemImage: "graduationcap") }
                    Spacer()
                    // The skill lab is an engineering tool; the product lobby (Owner request 2026-10-16) does not offer it.
                    if !productMode { Button("技能試驗") { showR2 = true }.accessibilityIdentifier("r2Lab") }
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
                            gameActionDock
                        }.padding(18)
                    }.frame(width: 320)
                        .background(GamePanel())

                }
            } else if phoneInterface {
                HStack(spacing:8) { playerStrip(.one);playerStrip(.two) }.frame(height:48)
                phoneStateBar.frame(height:20)
                board.frame(width:phoneLayout.width,height:phoneLayout.boardHeight)
                    .frame(maxWidth:.infinity)
                gameActionDock.frame(height:200,alignment:.top)
            } else {
                HStack(spacing:8) { playerStrip(.one);playerStrip(.two) }
                botStatus;matchBanners
                board.frame(width:tablet ? min(width,height/0.90):width,height:height).frame(maxWidth:.infinity)
                gameActionDock
            }
        }.font(.system(size: tablet ? 16 : 14))
            .padding(.horizontal,tablet ? 24:phoneInterface ? 6:12).padding(.vertical,phoneInterface ? 4:tablet ? 16:6)
            .frame(maxWidth: wide ? 1268 : tablet ? 784 : 650)

    }
    private var matchHeader: some View {
            HStack {
                Button { confirmExit = true } label: { Image(systemName: "chevron.left").font(.system(size: 20, weight: .bold)).frame(width: 38, height: 36) }.accessibilityLabel("返回選角")
                VStack(alignment: .leading, spacing: 2) {
                    Text(turnTitle).font(.system(size: 20, weight: .heavy, design: .serif))
                        .foregroundStyle(displayedPlayer == .one ? uiAccent:uiInk)
                        .lineLimit(1).minimumScaleFactor(0.80).accessibilityIdentifier("currentTurn")
                    Text(lesson?.rawValue ?? "第 \(store.state.ply) 回合 · \(store.computer == nil ? "本機雙人" : "單人・你執\(store.humanPlayer == .one ? "黑" : "白")")")
                        .font(.system(size: 11)).foregroundStyle(uiSecondary)
                }
                Spacer()
                Menu {
                    if !store.state.config.expansionSkills {
                        Button("複製此局改用新版技能") {
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
            }.buttonStyle(GameButtonStyle())
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
        if legacySkillWarning && !store.isBotActing {
            Text("舊技能存局 · 新開對局使用新版設定").font(.system(size:11)).foregroundStyle(uiAccent)
        } else if presentedResult != nil {
            HStack { Image(systemName:"crown.fill");Text("本局結算").bold();Spacer() }
                .font(.system(size:12))
        } else if complete {
            Text("挑戰達成").font(.system(size:12)).frame(maxWidth:.infinity,alignment:.leading)
        } else if store.computer != nil { botStatus }
        else {
            Text(store.recordErrorMessage ?? localActionStatus)
                .font(.system(size:12)).foregroundStyle(uiSecondary)
                .frame(maxWidth:.infinity,alignment:.leading)
                .accessibilityIdentifier("localActionStatus")
        }
    }
    // The skill tray owns instructions; this bar reports the actual action phase.
    private var localActionStatus: String {
        if store.inputLocked { return "行動演出中 · 請稍候" }
        if let preview = store.preview {
            return preview.success ? "合法預覽 · 等待確認" : "目標未成立 · 查看下方原因"
        }
        if !store.selected.isEmpty { return "目標選取中 · 尚未施放" }
        return "本機雙人 · \(side)行動"
    }
    @ViewBuilder private var matchBanners: some View {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--integrated-review-audit"),let match = store.expansion {
                Text(match.audit).font(.system(size:8)).accessibilityIdentifier("integratedExpansionAudit")
            }
            #endif
            if store.recordRules == .redeployment {
                Text("新版技能 · 戰士沿棋群築壘／法師調度己兵")
                    .font(.caption).foregroundStyle(uiAccent).accessibilityIdentifier("candidateRulesBanner")
            }
            if store.r2Fixture != nil { Text("R2 \(store.r2Rules.variant) 試驗 · \(store.r2Rules.labDescription)").font(.caption).foregroundStyle(uiAccent).accessibilityIdentifier("r2Banner") }
            if let error = store.recordErrorMessage { Text(error).font(.caption).foregroundStyle(.orange) }
    }
    // The same 200pt dock is used on phones and tablets; state never changes its height.
    private var gameActionDock: some View {
        VStack(spacing: 4) {
            if presentedResult != nil || complete {
                gameResultDock
            } else {
                dockHeading.frame(height: 44)
                gameAbilityRail.frame(height: 64)
                Text(tacticalMessage.replacingOccurrences(of: "確認前不扣資源、不播聲音。", with: ""))
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(uiSecondary)
                    .lineLimit(1).truncationMode(.tail)
                    .frame(maxWidth: .infinity, minHeight: 16, maxHeight: 16, alignment: .leading)
                    .accessibilityIdentifier("playMessage")
                    .accessibilityValue(store.isBotActing ? "\(store.botActionIndex)/\(store.botActionCount) \(store.botMotionStartedAt == nil ? "準備" : "落定")" : "")
                gameCommandRow.frame(height: 44)
            }
        }.padding(10).frame(height: 200, alignment: .top)
            .background(GamePanel(active: true, kind: .tray))
            .accessibilityElement(children: .contain).accessibilityIdentifier("gameActionDock")
    }
    private var dockHeading: some View {
        HStack(spacing: 8) {
            Image(uiImage: dockPortrait).resizable().scaledToFit().padding(2).frame(width: 44, height: 44)
                .background(Circle().fill(GameChrome.ink))
                .overlay(Circle().stroke(LinearGradient(colors: [GameChrome.cream, GameChrome.gold, GameChrome.bronze], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2))
                .shadow(color: .black.opacity(0.50), radius: 2, y: 2)
            VStack(alignment: .leading, spacing: 1) {
                Text(dockTitle).font(.system(size: 14, weight: .heavy, design: .serif)).foregroundStyle(GameChrome.accent(hero)).accessibilityIdentifier("tacticalActionTitle")
                Text(stepPrompt).font(.system(size: 11,weight:.semibold)).lineLimit(2).foregroundStyle(uiSecondary)
                    .accessibilityIdentifier("skillStepPrompt")
            }
            Spacer(minLength: 0)
            if !store.state.board.monsters.isEmpty {
                Menu {
                    ForEach(store.state.board.points.filter { store.state.board.monsters.contains($0) }, id: \.self) { point in
                        let hunt = TacticalHuntPreview(store.state,at:point)
                        Button("\(hunt.name) \(coordinate(point)) · \(hunt.reason == .none ? "可討伐" : "查看條件")") {
                            store.select(point)
                        }.accessibilityIdentifier("hunt-\(point.x)-\(point.y)")
                    }
                } label: {
                    Text("討伐").font(.system(size:11,weight:.bold)).frame(width:44,height:44)
                }.foregroundStyle(uiAccent).accessibilityLabel("討伐魔物").accessibilityIdentifier("huntMenu")
                    .disabled(store.inputLocked || store.state.status != .ongoing)
            }
            if !store.state.lootInventory(of: store.state.current).isEmpty {
                Button { showLootAbilities.toggle() } label: {
                    Label("戰利", systemImage: "shippingbox.fill").font(.system(size: 11, weight: .bold)).frame(minWidth: 52, minHeight: 44)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(uiAccent)
                    .accessibilityLabel(showLootAbilities ? "查看職業技能" : "查看戰利能力").accessibilityIdentifier("showLootAbilities")
            }
            if store.mode == .skill && hero == .mage && store.state.config.experimentalFriendlyRedeploy && !store.state.config.expansionSkills {
                Picker("魔法之手方式", selection: Binding(get: { store.mageOperation }, set: { store.changeMageOperation($0) })) {
                    ForEach(GameStore.MageOperation.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.menu).accessibilityIdentifier("mageOperation")
            }
            #if DEBUG || TACTICALGO_V11
            if store.expansion?.challenge == true {
                Button("提示") { store.expansion?.showHint = true; showTacticalHelp = true }
                    .font(.caption).frame(minWidth: 44, minHeight: 32).accessibilityIdentifier("priestHint")
            }
            #endif
            Button { showTacticalHelp = true } label: {
                Image(systemName: "book.closed.fill").font(.system(size: 15)).frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(uiAccent)
                .accessibilityLabel("技能說明").accessibilityIdentifier("tacticalHelp")
        }
    }
    private var dockTitle: String {
        #if DEBUG || TACTICALGO_V11
        if let title = store.expansion?.presentedHuntTitle { return title }
        #endif
        return hero.title
    }
    private var dockPortrait: UIImage {
        #if DEBUG || TACTICALGO_V11
        if let match = store.expansion,let kind = match.presentedHuntKind,let image = match.monsterArt[kind] { return image }
        #endif
        return portrait(hero)
    }
    private func modeCost(_ mode: GameStore.Mode) -> Int {
        switch mode {
        case .soldier, .loot: 0
        case .summon: store.state.config.summonCost(hero)
        case .skill: store.state.config.skillManaCost
        case .advanced: store.state.config.expansionSkillManaCost
        }
    }
    private func modeTitle(_ mode: GameStore.Mode) -> String {
        switch mode { case .soldier: "放士兵"; case .summon: "召喚英雄"; case .skill: hero == .mage && store.mageOperation == .redeploy ? "調度己兵" : hero == .warrior && store.state.config.bastionScope == .connectedGroup ? "沿棋群築壘" : hero.skillTitle; case .advanced: advancedTitle; case .loot: "戰利能力" }
    }
    private var stepPrompt: String {
        #if DEBUG || TACTICALGO_V11
        if let match = store.expansion { return match.stepPrompt }
        #endif
        return store.isBotActing ? "對手行動中" : "選擇戰術 · 每次 1 AP"
    }
    private var legacySkillWarning: Bool {
        #if DEBUG || TACTICALGO_V11
        return store.expansion?.legacySkillsOnResume == true
        #else
        return false
        #endif
    }
    private var tacticalMessage: String {
        #if DEBUG || TACTICALGO_V11
        if let match = store.expansion { return match.tacticalMessage }
        #endif
        return store.message
    }
    private func modeIcon(_ mode: GameStore.Mode) -> GameIcon {
        switch mode { case .soldier: .soldier; case .summon: .summon; case .skill: .hero(hero); case .advanced: .hero(hero, advanced: true); case .loot: .slime }
    }
    private func modeRestriction(_ mode: GameStore.Mode, ability: MonsterAbility = .stickyBounce) -> String? {
        let kind: TacticalHintMode = switch mode {
        case .soldier: .soldier; case .summon: .summon; case .skill: .skill; case .advanced: .advanced; case .loot: .loot
        }
        return TacticalReadiness.restriction(store.state,mode:kind,ability:ability)?.message
    }
    private var gameAbilityRail: some View {
        GeometryReader { geo in
            let count = availableModes.filter { $0 != .loot }.count
            let width = max(64, (geo.size.width - 2 - CGFloat(max(0, count-1)) * 6) / CGFloat(max(1, count)))
            if store.mode == .skill && hero == .mage && store.selected.first != nil && store.mageOperation == .push {
                HStack(spacing: 6) {
                    ForEach(PushDirection.allCases, id: \.self) { direction in
                        Button { store.chooseDirection(direction) } label: {
                            VStack(spacing: 5) {
                                Image(systemName: direction.symbol).font(.system(size: 22, weight: .heavy))
                                Text(direction.title).font(.system(size: 12, weight: .bold))
                            }.frame(maxWidth: .infinity).frame(height: 64)
                        }.buttonStyle(GameButtonStyle(kind: .ability, selected: store.pushDirection == direction))
                            .disabled(store.inputLocked || !store.availableDirections.contains(direction))
                            .accessibilityIdentifier("push-" + direction.rawValue)
                    }
                }
            } else {
                ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(availableModes.filter { $0 != .loot }, id: \.self) { mode in
                            Button { store.changeMode(mode) } label: {
                                GameAbilityLabel(title: modeTitle(mode), icon: modeIcon(mode), mana: modeCost(mode), advanced: mode == .advanced, restriction: modeRestriction(mode))
                                    .frame(width: width)
                            }.buttonStyle(GameButtonStyle(kind: .ability, selected: store.mode == mode, restricted: modeRestriction(mode) != nil))
                                .disabled(store.inputLocked || store.state.status != .ongoing)
                                .accessibilityIdentifier("mode-" + String(describing: mode))
                                .accessibilityValue(modeRestriction(mode) ?? "可選目標，仍須合法預覽")
                                .accessibilityAddTraits(store.mode == mode ? [.isSelected] : [])
                                .id("mode-" + String(describing: mode))
                        }
                        #if DEBUG || TACTICALGO_V11
                        if let match = store.expansion {
                            ForEach(store.state.lootInventory(of: store.state.current), id: \.ability) { loot in
                                Button { store.changeMode(.loot); match.ability = loot.ability } label: {
                                    GameAbilityLabel(title: loot.ability == .stickyBounce ? "黏彈" : "影步", icon: loot.ability == .stickyBounce ? .slime : .shadow, mana: 0, restriction: modeRestriction(.loot,ability:loot.ability))
                                        .frame(width: width)
                                }.buttonStyle(GameButtonStyle(kind: .ability, selected: store.mode == .loot && match.ability == loot.ability, restricted: modeRestriction(.loot,ability:loot.ability) != nil))
                                    .disabled(store.inputLocked || store.state.ply < loot.unlockPly || store.state.status != .ongoing)
                                    .accessibilityIdentifier("loot-" + loot.ability.rawValue)
                                    .accessibilityValue(modeRestriction(.loot,ability:loot.ability) ?? "可選目標，仍須合法預覽")
                                    .id("loot-" + loot.ability.rawValue)
                            }
                        }
                        #endif
                    }.padding(.horizontal, 1)
                }.accessibilityHint("左右滑動查看技能與戰利能力")
                    .onChange(of: showLootAbilities) { _, show in
                        let firstLoot = store.state.lootInventory(of: store.state.current).first
                        let target = show ? firstLoot.map { "loot-" + $0.ability.rawValue } : "mode-soldier"
                        if let target { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { proxy.scrollTo(target, anchor: .leading) } }
                    }
                }
            }
        }
    }
    private var gameCommandRow: some View {
        HStack(spacing: 8) {
            Button { if store.selected.isEmpty { store.undo() } else { store.cancelSelection() } } label: {
                VStack(spacing: 1) {
                    Image(systemName: store.selected.isEmpty ? "arrow.uturn.backward" : "xmark").font(.system(size: 12, weight: .bold))
                    Text(store.selected.isEmpty ? "復原" : "取消").font(.system(size: 10, weight: .semibold))
                }.frame(width: 48, height: 44)
            }.buttonStyle(GameButtonStyle()).disabled(store.selected.isEmpty && !store.canUndoHumanDecision)
                .accessibilityIdentifier("undoOrCancel")
            Button(action: store.confirm) {
                Label("確認", systemImage: "checkmark.seal.fill").font(.system(size: 15, weight: .heavy))
                    .frame(maxWidth: .infinity).frame(height: 44)
            }.buttonStyle(GameButtonStyle(kind: .primary))
                .disabled(store.inputLocked || store.preview?.success != true).accessibilityIdentifier("playConfirm")
            Button(action: store.endTurn) {
                HStack(spacing: 4) { Text("結束回合"); Image(systemName: "chevron.right.2") }
                    .font(.system(size: 12, weight: .bold)).frame(width: 105, height: 44)
            }.buttonStyle(GameButtonStyle(kind: .turn))
                .disabled(store.inputLocked || store.state.status != .ongoing || lesson != nil).accessibilityIdentifier("playEndTurn")
        }
    }
    private var gameResultDock: some View {
        VStack(spacing: 8) {
            Image(systemName: complete ? "checkmark.seal.fill" : "crown.fill")
                .font(.system(size: 28, weight: .bold)).foregroundStyle(uiAccent)
            Text(complete ? "練習完成" : (presentedResult ?? "對戰結束"))
                .font(.system(size: 23, weight: .heavy, design: .serif)).foregroundStyle(GameChrome.cream)
                .accessibilityIdentifier(complete ? "practiceComplete" : "matchResult")
            Text(store.message).font(.system(size: 11)).foregroundStyle(uiSecondary).lineLimit(2)
                .accessibilityIdentifier("playMessage")
            HStack(spacing: 8) {
                Button { store.undo() } label: { Text("復原重試").frame(maxWidth: .infinity, minHeight: 44) }
                    .buttonStyle(GameButtonStyle()).disabled(!store.canUndoHumanDecision).accessibilityIdentifier("undoOrCancel")
                Button { if complete { store.leaveMatch(); inMatch = false; lesson = nil } else { returnToLatestRules(); startMatch() } } label: {
                    Text(complete ? "返回選角" : "再玩一局").bold().frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(GameButtonStyle(kind: .primary)).accessibilityIdentifier("resultReplay")
            }
        }.frame(maxWidth: .infinity).frame(height: 180)
    }
    private var tacticalHelp: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Text(store.message).font(.headline)
                    Text(modeHelp)
                    #if DEBUG || TACTICALGO_V11
                    if let match = store.expansion {
                        if let instruction = match.instruction { Text(instruction) }
                        if match.challenge && match.showHint { Text(PriestSanctuaryChallenge.hint) }
                    }
                    #endif
                    Text("先選擇棋盤上的目標，查看合法預覽，再按確認。取消不扣資源，復原可以還原上一個行動。")
                }.padding()
            }.background(GameBackdrop()).foregroundStyle(GameChrome.cream).navigationTitle("技能說明")
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("完成") { showTacticalHelp = false }.accessibilityIdentifier("tacticalHelpDone") } }
        }
    }
    private var availableModes: [GameStore.Mode] {
        store.state.config.expansionSkills ? [.soldier,.summon,.skill,.advanced] + (store.state.lootInventory(of:store.state.current).isEmpty ? []:[.loot]) : [.soldier,.summon,.skill]
    }
    private var advancedTitle: String {
        advancedSkillTitle(hero)
    }
    private func advancedSkillTitle(_ hero:HeroClass) -> String {
        switch hero { case .warrior: "戰線重整"; case .mage: "雙重牽引"; case .rogue: "連鎖換位"; case .priest: "聖所"; case .none: "第二技能" }
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
                GameManaGem(value: state.mana(of: player), compact: true).accessibilityHidden(true)
                Text("\(state.mana(of: player))/\(state.config.manaCap) · \(liberties) 氣")
                    .font(.system(size: 11)).foregroundStyle(liberties <= 1 ? Color.redTeam:uiSecondary)
                Spacer(minLength: 0)
                if active {
                    let ap = store.isBotActing && state.current != player ? 0 : state.apRemaining
                    HStack(spacing: 3) {
                        ForEach(0..<min(2, max(0, ap)), id: \.self) { _ in Circle().fill(GameChrome.gold).frame(width: 4, height: 4).accessibilityHidden(true) }
                        Text("\(ap) AP").font(.system(size: 11, weight: .bold))
                    }
                }
            }
            if !phoneInterface && !state.lootInventory(of:player).isEmpty {
                Text(state.lootInventory(of:player).map { ($0.ability == .stickyBounce ? "黏彈":"影步") + (state.ply < $0.unlockPly ? "待解鎖":"×1") }.joined(separator:" · ")).font(.system(size:10)).foregroundStyle(uiAccent)
            }
        }.font(.system(size:12)).padding(phoneInterface ? 6:8)
            .frame(maxWidth:.infinity)
            .background(GamePanel(active: active))
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
                        ExpansionBoard(store:match,assets:assets,time:match.reviewTime ?? (match.playing ? ProcessInfo.processInfo.systemUptime-match.started : 2),reduced:reduceMotion || match.reduced,identityPrefix:"play-cell",focusedNine:store.size == 9 && UIDevice.current.userInterfaceIdiom == .phone,focusedPhone:phoneInterface)
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
                .buttonStyle(GameButtonStyle()).accessibilityLabel("以格點清單操作棋盤")
        }
    }
    private var modeHelp: String {
        if store.isBotActing { return store.botActionLabel }
        if let lesson { return lesson.instruction }
        #if DEBUG || TACTICALGO_V11
        if let match = store.expansion,match.huntPreview != nil { return match.help }
        #endif
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
            }.gameSheetSurface().navigationTitle("選擇棋盤格點")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showGrid = false } } }
        }
    }
    private var rules: some View {
        NavigationStack {
            List {
                Section("勝利") { Text("包圍敵方主將所在的棋串，使它沒有相鄰空點（氣），提走主將即可獲勝。斜角不算相鄰。") }
                Section("回合與資源") { Text("首回合 1 AP，其後 2 AP。每次行動 1 AP；耗盡 AP 自動換手。每回合增加 1 能量，上限 6。也可提早結束回合。100 回合未分勝負則和局。") }
                Section("英雄") { Text("召喚在任一己方棋子相鄰空點。戰士與盜賊需 2 能量，\(heroes.contains(.priest) ? "法師與牧師需 3" : "法師需 3")。英雄被提走後，本局不能再召喚。") }
                ForEach(heroes, id: \.self) { h in Section(h.title + " · " + ruleSkillTitle(h)) { Text((rulesConfig.expansionSkills ? SkillGuide.basic(h) + "\n" + SkillGuide.basicSteps(h) : h.skillHelp(config: rulesConfig)) + "\n技能需 1 AP＋2 能量，每回合只能使用一次。") } }
                if rulesConfig.expansionSkills {
                    Section("第二技能 · 1 AP＋4 能量") {
                        ForEach(heroes, id: \.self) { h in
                            Text(h.title + " · " + advancedSkillTitle(h) + "：" + SkillGuide.second(h) + "\n" + SkillGuide.secondSteps(h))
                        }
                        Text("技能、第二技能和戰利能力，每回合合計只能用一次。")
                    }
                    Section("魔物與戰利能力") {
                        Text(SkillGuide.monsters)
                        Text(SkillGuide.loot)
                        Text(SkillGuide.stickyBounce)
                        Text(SkillGuide.shadowStep)
                    }
                }
                Section("合法行動") { Text("先處理敵方提子，再檢查己方是否無氣。禁止自殺與重複任何先前盤面。預覽不扣資源；復原會還原完整盤面、回合、資源與歷史。") }
            }.gameSheetSurface().navigationTitle("遊戲規則").toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { showRules = false } } }
        }
    }
    /// In a match the sheet describes that match's rules; in the lobby, the rules the next match would use.
    private var rulesConfig: RuleConfig {
        if inMatch { return store.state.config }
        return useExpansion ? TacticalHints.updatedConfig(size: boardSize) : selectedRules.config(size: boardSize)
    }
    private func ruleSkillTitle(_ hero: HeroClass) -> String {
        let config = rulesConfig
        if hero == .warrior, config.bastionScope == .connectedGroup { return "沿棋群築壘" }
        if hero == .mage, config.experimentalFriendlyRedeploy { return "調度己兵" }
        return hero.skillTitle
    }
    private func coordinate(_ p: Point) -> String { String(UnicodeScalar(65 + p.x)!) + String(p.y + 1) }
    private func cellDescription(_ p: Point) -> String {
        if store.state.board.monsters.contains(p) { return store.state.config.monsterBattlefield?.kind(at:p) == .slime ? "史萊姆，點選討伐" : "暗影狼，點選討伐" }
        guard let piece = store.state.board[p] else { return "空點" }
        return (piece.owner == .one ? "黑方 " : "白方 ") + (piece.kind == .hero ? store.state.heroClass(of: piece.owner).title : piece.kind == .commander ? "主將" : "士兵")
    }
    private func returnToLatestRules() {
        guard productMode else { return }
        #if DEBUG || TACTICALGO_V11
        useExpansion = true
        #endif
        selectedRules = GameStore.defaultMatchRules
    }
    private func resumeRecord(_ record: MatchRecord) {
        if store.resume(record) {
            #if DEBUG || TACTICALGO_V11
            // A resumed original-rules record keeps its mode: "重新開始" must restart it with the same rules, not switch
            // the player into an expansion match (and spend a new admission on it).
            useExpansion = false; monsters = .none
            #endif
            one = record.one; two = record.two; boardSize = record.size; selectedRules = record.rules
            singlePlayer = record.computer != nil; humanSide = record.computer?.opponent ?? .one
            lesson = nil; inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn()
        }
    }
    private func startMatch() {
        // Same gate as the 1.0 shell: the UI check only decides what to show, the ledger write is the permission.
        if let access, !access.canStartMatch { unlockRequest = .startGate; return }
        let authorize: ((UUID) throws -> Void)? = access.map { gate in { id in try gate.authorizeNewMatch(id: id) } }
        #if DEBUG || TACTICALGO_V11
        if useExpansion {
            guard store.startExpansion(one:one,two:two,size:boardSize,monsters:monsters,computer:singlePlayer ? humanSide.opponent:nil,
                                       authorize:authorize) else { return }
            boardSize = store.size; lesson = nil; inMatch = true; store.setMatchAudioActive(true); store.scheduleComputerTurn(); return
        }
        #endif
        store.size = singlePlayer ? 7 : boardSize
        guard store.newMatch(classOne: one, classTwo: two, computer: singlePlayer ? humanSide.opponent : nil, rules: selectedRules,
                             authorize: authorize) else { return }
        lesson = nil; inMatch = true; store.setMatchAudioActive(true)
        store.scheduleComputerTurn()
    }
    private func startPractice(_ value: PracticeLesson) { lesson = value; store.startPractice(value); inMatch = true; store.setMatchAudioActive(true) }
}

#if DEBUG || TACTICALGO_V11
private struct IntegratedExpansionSoundSettings: View {
    @Bindable var store: ExpansionLabStore
    @Bindable var background: CombatAudio
    let close: () -> Void
    var body: some View {
        NavigationStack {
            Form {
                Toggle("靜音",isOn:$store.muted).accessibilityIdentifier("audioMute").onChange(of:store.muted) { background.muted = store.muted; store.stop() }
                Section("音效") {
                    HStack {
                        Slider(value:$store.sfxVolume,in:0...1).accessibilityLabel("音效音量").accessibilityIdentifier("sfxVolume")
                        Text("\(Int(store.sfxVolume * 100))%").monospacedDigit().frame(minWidth:48,alignment:.trailing).accessibilityIdentifier("sfxVolumeValue")
                    }
                }
                Section("英文施法語音") {
                    Toggle("播放角色台詞",isOn:$store.voice).accessibilityIdentifier("castVoice")
                    HStack {
                        Slider(value:$store.voiceVolume,in:0...1).accessibilityLabel("施法語音音量").accessibilityIdentifier("voiceVolume")
                        Text(store.voice ? "\(Int(store.voiceVolume * 100))%" : "語音已關閉").font(.caption).monospacedDigit().frame(minWidth:48,alignment:.trailing).accessibilityIdentifier("voiceVolumeValue")
                    }
                }
                Toggle("減少動態",isOn:$store.reduced).accessibilityIdentifier("reduceCombatMotion").onChange(of:store.reduced) { store.stop() }
                Section("背景音樂") {
                    HStack {
                        Slider(value:$background.musicVolume,in:0...1).accessibilityLabel("配樂音量").accessibilityIdentifier("musicVolume")
                        Text("\(Int(background.musicVolume * 100))%").monospacedDigit().frame(minWidth:48,alignment:.trailing)
                    }
                }
                Section { Text("設定會保留。音效、英文台詞與配樂可分別調整；靜音會關閉全部聲音。").font(.footnote) }
            }.gameSheetSurface().navigationTitle("聲音與動畫").navigationBarTitleDisplayMode(.inline).toolbar {
                ToolbarItem(placement:.principal) {
                    Text("聲音與動畫").font(.headline).foregroundStyle(GameChrome.cream).accessibilityIdentifier("soundSettingsTitle")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: close) { Text("完成").frame(minWidth: 44, minHeight: 44).contentShape(Rectangle()) }
                        .foregroundStyle(GameChrome.cream)
                        .accessibilityIdentifier("audioSettingsDone")
                }
            }
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
            }.gameSheetSurface().navigationTitle("聲音設定")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() }.accessibilityIdentifier("audioSettingsDone") } }
        }
    }
}

private enum UnlockRequest: String, Identifiable {
    case store, startGate
    var id: String { rawValue }
}

#if DEBUG || TACTICALGO_V11
/// Root of the Beta/TestFlight product: owns the shared access gate and presents the 1.1 shell as the whole game.
struct FullGameRoot: View {
    @State private var access = PlayAccess()
    var body: some View {
        ExpansionGameView(access: access)
            .task { await access.purchase.start() }
    }
}
#endif

/// Player-facing explanations for the expansion rules (`TacticalHints.updatedConfig`): what each skill does and
/// when it helps, before how to tap it. Owner TestFlight 1114 feedback: the old texts only listed tap steps.
enum SkillGuide {
    static func basic(_ hero: HeroClass) -> String {
        switch hero {
        case .warrior: "在戰士所在的己方棋群旁，一次加兩顆士兵。適合補牆、圍住敵兵或替棋群補氣。"
        case .mage: "把法師 2 格內、與法師棋群相連的一顆己兵，移到棋群外緣的空點。不增加棋子，適合補缺口或逃出包圍。"
        case .rogue: "盜賊和正鄰的一顆敵方士兵交換位置。適合突入敵陣，或拆開正在包圍你的敵兵。"
        case .priest: "移除牧師 2 格內的一顆己兵，空出位置替被困的棋群打開氣或眼。不會在別處補兵。"
        case .none: "請先選擇職業。"
        }
    }
    static func basicSteps(_ hero: HeroClass) -> String {
        switch hero {
        case .warrior: "依序點棋群旁兩個不同空點，再按確認。"
        case .mage: "先點要移動的己兵，再點棋群外緣空點，再按確認。"
        case .rogue: "點盜賊上下左右的一顆敵兵，再按確認。"
        case .priest: "點牧師 2 格內的一顆己兵，再按確認。"
        case .none: ""
        }
    }
    static func second(_ hero: HeroClass) -> String {
        switch hero {
        case .warrior: "把與戰士相連的兩顆己兵，各移到棋群外緣的空點（距戰士 4 格內）。適合重新排陣、堵住缺口。"
        case .mage: "移動法師 2 格內的兩顆士兵（敵我皆可），各推到上下左右相鄰的空點。適合一次拆開敵陣。"
        case .rogue: "盜賊穿過兩顆相連的敵兵：盜賊到第二顆敵兵的位置，兩顆敵兵各往後退一格。適合深入敵陣。"
        case .priest: "聖所：犧牲牧師 2 格內的一顆己兵，同時在牧師或主將旁的空點補一顆兵。一手同時替棋群開氣、又向外延伸，適合救援快被提的主將。"
        case .none: "請先選擇職業。"
        }
    }
    static func secondSteps(_ hero: HeroClass) -> String {
        switch hero {
        case .warrior, .mage: "依序點：士兵① → 空點① → 士兵② → 空點②，再按確認。"
        case .rogue: "先點盜賊旁的敵兵，再點那顆敵兵旁的另一顆敵兵，再按確認。"
        case .priest: "先點要犧牲的己兵，再點牧師或主將旁的空點，再按確認。"
        case .none: ""
        }
    }
    static let monsters = "魔物占住一個交叉點，也會擋住氣。用己子從上下左右圍住它（至少 2 格，且比敵方多；斜角不算），再點「討伐」並確認，花 1 AP。暗影狼還需要己方英雄站在牠的上下左右。"
    static let loot = "討伐後得到一次戰利能力，下個己方回合才能用：花 1 AP、0 能量，和職業技能共用每回合一次。按技能列的「戰利」切換使用。"
    static let stickyBounce = "史萊姆 → 黏彈：選一顆己子，把貼著它的一顆士兵往外彈開一格（後方要是空點）。"
    static let shadowStep = "暗影狼 → 影步：英雄沿直線移動 1～2 格到空點，路上不能有棋子或魔物。"
    static func lobbyMonsters(_ kinds: [MonsterKind]) -> String {
        let rewards = kinds.map { $0 == .slime ? stickyBounce : shadowStep }.joined(separator: "\n")
        return "討伐魔物：用己子從上下左右圍住（至少 2 格且比敵方多），點「討伐」花 1 AP。" + (kinds.contains(.shadowWolf) ? "暗影狼還要己方英雄貼在旁邊。" : "") + "\n" + rewards
    }
}
