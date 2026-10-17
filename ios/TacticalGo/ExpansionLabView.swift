#if DEBUG || TACTICALGO_V11
import SwiftUI
import AVFoundation
import TacticalGoCore
import TacticalGoContent
import TacticalGoRecords
import TacticalGoMotion
import TacticalGoVisuals

/// Candidate match owner. Preview and playback never own rules or charge resources.
@MainActor @Observable final class ExpansionLabStore {
    enum Mode: String, CaseIterable { case soldier = "落子", summon = "召喚", skill = "技能", advanced = "第二技能", loot = "戰利能力" }
    enum Monsters: String, CaseIterable { case none = "無魔物", slime = "史萊姆", wolf = "暗影狼", dual = "雙怪" }
    var computer: Player?
    @ObservationIgnored var onTerminalCue: ((String) -> Void)?
    /// Stable identity of this match for the access ledger. Generated once per started match; resumed matches keep the
    /// identity they were saved with. `nil` after resuming a legacy file: such a match is deliberately not registered.
    private(set) var matchID: UUID? = UUID()
    /// Called once, after the save that records a terminal state (same ordering as the original match path).
    @ObservationIgnored var onTerminal: ((UUID) -> Void)?
    @ObservationIgnored private var terminalReported = false
    var difficulty = "easy"
    var controlsLocked: Bool { playing || (state.current == computer && state.status == .ongoing) }
    var presentationHold = 0.0
    var presentationAudioHold = 0.0
    var size = 9
    var one: HeroClass = .warrior
    var two: HeroClass = .mage
    var advancedCost = 4
    var huntCost = 1
    var monsters: Monsters = .none
    var mode: Mode = .soldier
    var ability: MonsterAbility = .stickyBounce
    var selected: [Point] = []
    @ObservationIgnored private var hintState: GameState?
    @ObservationIgnored private var hintMode: Mode?
    @ObservationIgnored private var hintSelection: [Point] = []
    @ObservationIgnored private var hintAbility: MonsterAbility?
    @ObservationIgnored private var hintPoints: Set<Point> = []
    var legalTargets: Set<Point> {
        guard !controlsLocked, reviewTime == nil else { return [] }
        if hintState != state || hintMode != mode || hintSelection != selected || hintAbility != ability {
            let kind: TacticalHintMode = switch mode {
            case .soldier: .soldier; case .summon: .summon; case .skill: .skill; case .advanced: .advanced; case .loot: .loot
            }
            hintPoints = TacticalHints.targets(state,mode:kind,selected:selected,ability:ability)
            hintState = state; hintMode = mode; hintSelection = selected; hintAbility = ability
        }
        return hintPoints
    }
    var pending: GameAction?
    var message = "選擇格點，再確認行動。"
    var instruction: String?
    var voice: Bool {
        didSet { if persistSoundPreferences { soundDefaults.set(voice,forKey:"combatAudio.castVoiceEnabled") }; updateSoundMix() }
    }
    var sfxVolume: Double {
        didSet {
            let value = Self.soundLevel(sfxVolume)
            if value != sfxVolume { sfxVolume = value; return }
            if persistSoundPreferences { soundDefaults.set(sfxVolume,forKey:"combatAudio.expansionSFXVolume") }; updateSoundMix()
        }
    }
    var voiceVolume: Double {
        didSet {
            let value = Self.soundLevel(voiceVolume)
            if value != voiceVolume { voiceVolume = value; return }
            if persistSoundPreferences { soundDefaults.set(voiceVolume,forKey:"combatAudio.castVoiceVolume") }; updateSoundMix()
        }
    }
    var muted = false
    var reduced = false
    var effects = true
    var castTake = "B"
    var challenge = false
    var showHint = false
    var savedCount = 0
    var legacySkillsOnResume = false
    var reviewTime: Double?
    var reviewWidth: CGFloat?
    var reviewFixture = false
    private(set) var session: GameSession?
    private(set) var receipt: ExpansionPresentation?
    private var reviewReceipt: ExpansionPresentation?
    var frameReceipt: ExpansionPresentation? { reviewTime != nil ? reviewReceipt:receipt }
    private(set) var started = 0.0
    private(set) var playing = false
    private(set) var generation = 0
    private(set) var cues = 0
    private(set) var lastSoundKeys: [String] = []
    #if DEBUG
    @ObservationIgnored private(set) var lastSoundSchedule: [(key:String,delay:Double,gain:Double,playerGain:Double)] = []
    #endif
    var state: GameState { session!.state }
    var preview: ActionOutcome? { pending.map { GameEngine.apply(state,$0) } }
    let assets = try? P02CozyAssets.load()
    let handPoses = P04HandAssets.load()
    let priest: UIImage? = {
        guard let url = Bundle.main.url(forResource:"priest-v02",withExtension:"png",subdirectory:"PresentationLab/P08") else { return nil }
        return UIImage(contentsOfFile:url.path)
    }()
    let priestPlate: UIImage? = {
        guard let url = Bundle.main.url(forResource:"priest-clean-plate-v02",withExtension:"png",subdirectory:"PresentationLab/P08") else { return nil }
        return UIImage(contentsOfFile:url.path)
    }()
    let roguePlate: UIImage? = {
        guard let url = Bundle.main.url(forResource:"rogue-clean-plate",withExtension:"png",subdirectory:"PresentationLab/P08") else { return nil }
        return UIImage(contentsOfFile:url.path)
    }()
    let warriorPlate: UIImage? = {
        guard let url = Bundle.main.url(forResource:"warrior-clean-plate",withExtension:"png",subdirectory:"PresentationLab/P07") else { return nil }
        return UIImage(contentsOfFile:url.path)
    }()
    let monsterArt: [MonsterKind:UIImage] = {
        var result: [MonsterKind:UIImage] = [:]
        for (kind,name) in [(MonsterKind.slime,"slime-token-v02"),(.shadowWolf,"shadow-wolf-preview-v02")] {
            if let url = Bundle.main.url(forResource:name,withExtension:"png"),let image = UIImage(contentsOfFile:url.path) { result[kind] = image }
        }; return result
    }()
    @ObservationIgnored private let samples = PresentationSamples()
    @ObservationIgnored private var voiceCadence = CharacterVoiceCadence(profile: .everyCast)
    #if DEBUG
    var voiceClockForAudit: Double?
    var voiceKeyForAudit: String?
    func setVoiceCadenceForAudit(_ profile: CharacterVoiceCadence.Profile) { voiceCadence = CharacterVoiceCadence(profile:profile) }
    #endif
    @ObservationIgnored private let soundDefaults: UserDefaults
    @ObservationIgnored private var persistSoundPreferences = true
    @ObservationIgnored private let audio = CombatAudio(defaults:UserDefaults(suiteName:"TacticalGo.expansionLab")!)
    @ObservationIgnored private var task: Task<Void,Never>?
    @ObservationIgnored private var active = false
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored nonisolated(unsafe) private var observer: (any NSObjectProtocol)?
    init(soundDefaults: UserDefaults = .standard) {
        self.soundDefaults = soundDefaults
        voice = soundDefaults.object(forKey:"combatAudio.castVoiceEnabled") as? Bool ?? true
        sfxVolume = Self.soundLevel(soundDefaults.object(forKey:"combatAudio.expansionSFXVolume") as? Double ?? 0.80)
        voiceVolume = Self.soundLevel(soundDefaults.object(forKey:"combatAudio.castVoiceVolume") as? Double ?? 0.85)
        updateSoundMix()
        restart(); loadReview()
        observer = NotificationCenter.default.addObserver(forName:AVAudioSession.interruptionNotification,object:nil,queue:.main) { [weak self] note in
            let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor [weak self] in
                guard let self,let raw,let type = AVAudioSession.InterruptionType(rawValue:raw) else { return }
                self.interrupted = type == .began || !AVAudioSession.InterruptionOptions(rawValue:options).contains(.shouldResume)
                if type == .began { self.stop() }
            }
        }
    }
    private static func soundLevel(_ value:Double) -> Double { value.isFinite ? min(1,max(0,value)) : 0 }
    private func updateSoundMix() {
        samples.setMix(effects:sfxVolume/0.80,voice:voice ? voiceVolume/0.85 : 0)
    }
    #if DEBUG
    func soundVolumeForAudit(_ key:String) -> Double { samples.volume(key) }
    func soundPlayingForAudit(_ key:String) -> Bool { samples.isPlaying(key) }
    func configureReviewSound(voiceEnabled:Bool) {
        persistSoundPreferences = false
        defer { persistSoundPreferences = true }
        muted = false; voice = voiceEnabled; sfxVolume = 0.80; voiceVolume = 0.85
    }
    #endif
    private func loadReview() {
        let args = ProcessInfo.processInfo.arguments
        func value(_ key: String) -> String? { guard let i = args.firstIndex(of:key),i+1 < args.count else { return nil }; return args[i+1] }
        guard let name = value("--exp-review"),let hero = HeroClass(rawValue:name),hero != .none else { return }
        do {
            let owner: Player = value("--exp-review-owner") == "White" ? .two:.one
            let n = Int(value("--exp-review-size") ?? "9") ?? 9
            session = GameSession(try ExpansionReviewFixture.state(hero:hero,owner:owner,size:n,dense:args.contains("--exp-review-dense")))
            size = n;one = state.heroClass(of:.one);two = state.heroClass(of:.two);mode = hero == .priest ? .skill:.advanced
            pending = ExpansionReviewFixture.action(hero:hero);reviewFixture = true
            reviewWidth = value("--exp-review-width").flatMap(Double.init).map { CGFloat($0) }
            reduced = args.contains("--exp-review-reduced");effects = !args.contains("--exp-review-body-only");muted = args.contains("--exp-review-muted")
            instruction = "工程圖層/聲畫檢查局面；不作可達挑戰或平衡證明。"
            if let t = value("--exp-review-time").flatMap(Double.init),t.isFinite {
                let before = state,action = pending!,outcome = session!.apply(action)
                reviewReceipt = ExpansionPresentation.make(before:before,action:action,outcome:outcome,current:state)
                reviewTime = t;pending = nil;message = "確認結果的定格檢查：\(t)秒（無音訊）。"
            }
        } catch { message = "工程棋形未載入：\(error)" }
    }
    deinit { task?.cancel(); if let observer { NotificationCenter.default.removeObserver(observer) } }
    func scene(_ isActive: Bool) {
        if isActive && !active { interrupted = false }
        active = isActive; if !isActive { stop() }
        audio.musicVolume = 0; audio.setMatchActive(isActive); audio.setSceneActive(isActive)
    }
    func stop(keepingCompletedVoice: Bool = false) {
        generation += 1; task?.cancel(); task = nil; samples.cancel(keepingVoice:keepingCompletedVoice); audio.cancelEffects()
        playing = false; receipt = nil
    }
    func cancelSelection() { selected = []; pending = nil }
    /// `keepIdentity` lets the caller restart the board of a match whose identity was already admitted.
    func restart(keepIdentity: Bool = false) {
        if !keepIdentity { matchID = UUID() }
        terminalReported = false
        stop(); cancelSelection(); reviewTime = nil; reviewWidth = nil; reviewFixture = false; challenge = false; showHint = false; instruction = nil; mode = .soldier; legacySkillsOnResume = false
        if monsters != .none { size = 9 }
        var c = TacticalHints.updatedConfig(size:size,advancedCost:advancedCost)
        switch monsters {
        case .none: break
        case .slime: c.monsterBattlefield = .init(huntAPCost:huntCost,kind:.slime,awardsLoot:true)
        case .wolf: c.monsterBattlefield = .init(huntAPCost:huntCost,kind:.shadowWolf,awardsLoot:true)
        case .dual: c.monsterBattlefield = .init(monsters:[.init(.slime,at:Point(2,4)),.init(.shadowWolf,at:Point(6,4))],huntAPCost:huntCost,awardsLoot:true)
        }
        do { session = GameSession(try GameSetup.newGame(config:c,classOne:one,classTwo:two)); voiceCadence.reset(); message = "新對局，輪流操作黑白兩方。" }
        catch { message = "開局失敗：\(error)" }
    }
    #if DEBUG
    func monsterReview(_ fixture: MonsterPresentationPractice) {
        stop();cancelSelection();reviewTime = nil;reviewWidth = nil;reviewFixture = false;challenge = false;showHint = false
        do {
            session = try fixture.session();size = 9;one = .warrior;two = .mage
            monsters = fixture.kind == .slime ? .slime:.wolf;computer = nil;legacySkillsOnResume = false
            mode = fixture.isHunt ? .soldier:.loot
            ability = fixture.kind == .slime ? .stickyBounce:.shadowStep
            instruction = "工程錄影局面：从合法開局重播，與正常對局共用preview／confirm。"
            message = "已重播\(session!.log.count)個合法行動；確認前不扣資源。"
        } catch { message = "魔物錄影局面未載入：\(error)" }
    }
    /// Hand-placed pose/occlusion QA; not evidence of competitive reachability.
    func qualityWarriorReview(owner:Player,size:Int,dense:Bool) throws {
        let fixture = try WarriorPresentationFixture.state(owner:owner,size:size,dense:dense)
        let rebuilt = try GameSetup.fromDiagram(config:TacticalHints.updatedConfig(size:size),diagram:fixture.board.diagram,
                                               classOne:fixture.heroClass(of:.one),classTwo:fixture.heroClass(of:.two),
                                               current:owner,manaOne:6,manaTwo:6,ap:2)
        stop();cancelSelection();voiceCadence.reset();reviewTime = nil;reviewReceipt = nil;reviewFixture = true
        session = GameSession(rebuilt);self.size = size;one = rebuilt.heroClass(of:.one);two = rebuilt.heroClass(of:.two)
        computer = nil;monsters = .none;mode = .skill;legacySkillsOnResume = false
        instruction = "工程密集棋形：僅驗本體姿勢與鄰兵，不作開局可達或玩法平衡證明。"
    }
    func voiceHandoffReview() throws {
        let rebuilt = try CombatVoiceHandoff.session()
        stop();cancelSelection();voiceCadence.reset();reviewTime = nil;reviewReceipt = nil
        session = rebuilt;size = 9;one = .rogue;two = .mage;computer = nil;mode = .skill
    }
    func warriorBotReview() {
        stop();cancelSelection();reviewFixture = true
        var c = RuleConfig.board(size:9);c.expansionSkills = true
        session = GameSession(try! GameSetup.fromDiagram(config:c,diagram:"....xx...\n...xOox..\n...x..x..\n...xxx...\n...H.....\n.........\n.........\n....X....\n.........",classOne:.warrior,classTwo:.mage,manaOne:6,manaTwo:6,ap:1))
        size = 9;one = .warrior;two = .mage
        instruction = "工程棋形：電腦以戰線重整提主將；不作可達開局或平衡證明。"
    }
    /// Exact-time renderer QA after a real successful commit; never an alternate rules path.
    @discardableResult func freezeConfirmedFrame(_ time: Double) -> Bool {
        guard let p = receipt,time.isFinite,time >= 0,time <= p.duration else { return false }
        stop();reviewReceipt = p;reviewTime = time
        return true
    }
    #endif
    func practice(_ fixture: ExpansionPractice) {
        stop(); cancelSelection(); reviewTime = nil; reviewWidth = nil; reviewFixture = false; challenge = false; showHint = false; legacySkillsOnResume = false
        do {
            session = try fixture.session(cost:advancedCost,updatedBaseSkills:true); voiceCadence.reset(); size = 9; monsters = .none; one = fixture.hero; two = .mage
            mode = fixture == .priest ? .skill : .advanced; instruction = fixture.instruction
            message = "已重播 \(session!.log.count) 個合法行動；可照說明試用，也可自由落子比較。"
        } catch { message = "試用局面載入失敗：\(error)" }
    }
    /// PRIEST-S2-P0 lesson: a hand-placed position (not a recordable match), so it is a review fixture and never saved.
    func sanctumPractice(_ practice: PriestSanctumPractice) {
        stop(); cancelSelection(); reviewTime = nil; reviewWidth = nil; reviewFixture = true; challenge = false; showHint = false
        do {
            session = GameSession(try practice.state()); voiceCadence.reset()
            size = practice.size; monsters = .none; one = .priest; two = .mage; computer = nil
            mode = .advanced; instruction = practice.instruction
            message = "練習局面：不會覆蓋你的存局。"
        } catch { message = "練習局面載入失敗：\(error)" }
    }
    func priestChallenge() {
        stop(); cancelSelection(); reviewTime = nil; reviewWidth = nil; reviewFixture = false; showHint = false
        do {
            session = try PriestSanctuaryChallenge.session(cost:advancedCost)
            voiceCadence.reset()
            size = 9; monsters = .none; one = .priest; two = .mage; challenge = true
            mode = .skill; instruction = PriestSanctuaryChallenge.brief
            message = "已從合法開局重播到單眼困境。可試普通落子，或用救援形成兩眼。"
        } catch { message = "挑戰載入失敗：\(error)" }
    }
    func priestCounter() {
        stop();cancelSelection();reviewTime = nil;reviewWidth = nil;reviewFixture = false;showHint = false;challenge = false
        do {
            session = try PriestSanctuaryChallenge.counterSession(cost:advancedCost)
            voiceCadence.reset()
            size = 9;monsters = .none;one = .priest;two = .mage;mode = .skill
            instruction = "法師反制：選 F4 的黑方士兵，再向左推到 E4。新空點 F4 與白方包圍圈相鄰，兩口氣不再都是安全的真眼。黑方仍能回應，並非強制獲勝。"
            message = "救援成功後的合法回應：白方法師剛召喚到 H4，剩1 AP。"
        } catch { message = "反制局面未載入：\(error)" }
    }
    func select(_ p: Point) {
        guard !controlsLocked,state.status == .ongoing else { return }
        defer { message = previewText }
        if state.board.monsters.contains(p) { selected = [p]; pending = .huntMonster(p); return }
        let hero = state.heroClass(of:state.current)
        let needed: Int
        switch mode {
        case .soldier: selected = [p]; pending = .placeSoldier(p); return
        case .summon: selected = [p]; pending = .summonHero(p); return
        case .skill: needed = hero == .warrior || (hero == .mage && state.config.experimentalFriendlyRedeploy) ? 2 : 1
        case .advanced: needed = hero == .warrior || hero == .mage ? 4 : hero == .rogue || hero == .priest ? 2 : 0
        case .loot: needed = ability == .stickyBounce ? 2 : 1
        }
        guard needed > 0 else { message = SkillGuide.second(.priest); return }
        if selected.count >= needed { selected = [] }
        selected.append(p); pending = nil
        guard selected.count == needed else { return }
        switch mode {
        case .skill:
            switch hero {
            case .warrior: pending = .castBastion(selected[0],selected[1])
            case .priest: pending = .castOffering(selected[0])
            case .rogue: pending = .castSwap(p)
            case .mage:
                if state.config.experimentalFriendlyRedeploy { pending = .castFriendlyRedeploy(selected[0],selected[1]) }
            case .none: break
            }
        case .advanced:
            if hero == .rogue { pending = .castChainSwap(first:selected[0],second:selected[1]) }
            else if hero == .priest { pending = .castSanctum(sacrifice:selected[0],destination:selected[1]) }
            else {
                let a = SoldierShift(selected[0],selected[1]), b = SoldierShift(selected[2],selected[3])
                pending = hero == .mage ? .castDoublePull(a,b) : .castReformation(a,b)
            }
        case .loot: pending = ability == .stickyBounce ? .useStickyBounce(anchor:selected[0],target:selected[1]) : .useShadowStep(p)
        default: break
        }
    }
    func push(_ direction: PushDirection) {
        guard !controlsLocked,mode == .skill,state.heroClass(of:state.current) == .mage,let p = selected.first else { return }
        pending = .castMagicHand(p,direction)
        message = previewText
    }
    func confirm(systemReduced: Bool) {
        guard active,!interrupted,!playing,let action = pending,preview?.success == true else { return }
        commit(action,systemReduced:systemReduced)
    }
    @discardableResult func commit(_ action: GameAction, systemReduced: Bool) -> Bool {
        guard active,!interrupted else { return false }
        let before = state, outcome = session!.apply(action)
        guard outcome.success else { message = GameStore.reason(outcome.reason); return false }
        let plan = ExpansionPresentation.make(before:before,action:action,outcome:outcome,current:state)
        // Once the visual unlocks, an ongoing confirmed line can finish across a
        // quick turn/quiet skill. Undo, background and terminal outcomes fully stop.
        // Cadence prevents another line from starting immediately over this tail.
        let previousVisualEnded = !playing && (receipt == nil || receipt?.duration == 0)
        let keepVoice = previousVisualEnded && state.status == .ongoing && !muted && voice && voiceVolume > 0
        stop(keepingCompletedVoice:keepVoice); cancelSelection()
        receipt = plan
        if before.current != state.current { mode = .soldier }
        started = ProcessInfo.processInfo.systemUptime; playing = (receipt?.duration ?? 0) > 0
        message = challenge && PriestSanctuaryChallenge.solved(state) ? "挑戰完成：犧牲一兵，牧師棋群形成兩個真眼。" : "已確認：\(before.current == .one ? "黑" : "白")方行動。"
        if state.status == .won, let winner = state.winner {
            // Explain the confirmed result; no animation or board inspection decides victory.
            let commander = outcome.events.compactMap { event -> CapturedPiece? in
                guard case .piecesCaptured(_,let pieces) = event else { return nil }
                return pieces.first { $0.piece.kind == .commander }
            }.first
            if let commander {
                message = "\(commander.piece.owner == .one ? "黑" : "白")方主將已被提，\(winner == .one ? "黑" : "白")方獲勝。"
            }
        }
        if ProcessInfo.processInfo.arguments.contains("--exp-autoplay") {
            FileHandle.standardOutput.write(Data(("EXPANSION_RECEIPT id=\(generation) class=\(before.heroClass(of:before.current).rawValue) ap=\(before.apRemaining)->\(state.apRemaining) mana=\(before.mana(of:before.current))->\(state.mana(of:before.current)) before=\(before.board.diagram.replacingOccurrences(of:"\n",with:"/")) after=\(state.board.diagram.replacingOccurrences(of:"\n",with:"/"))"+"\n").utf8))
        }
        saveCandidate(announce:false); schedule(systemReduced:systemReduced); return true
    }
    func endTurn() {
        guard !controlsLocked else { return }
        if commit(.endTurn,systemReduced:reduced) { message = "已結束回合。" }
    }
    var canUndoHuman: Bool {
        guard let session else { return false }
        guard computer != nil else { return session.canUndo }
        var copy = session
        while copy.undo() { if copy.state.current != computer { return true } }
        return false
    }
    func undo() {
        guard canUndoHuman else { return }
        stop(); cancelSelection()
        // A reviewed frame belongs to the discarded receipt, never the restored state.
        reviewTime = nil;reviewReceipt = nil
        repeat { guard session!.undo() else { break } } while computer == state.current
        message = "已復原盤面、資源、技能與魔物庫存。"; saveCandidate(announce:false)
    }
    static var savedURL: URL {
        var folder = "ExpansionCandidate08"
        #if DEBUG
        // UI tests must not read or overwrite the player's single saved expansion match (same isolation id as records).
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of:"--record-isolation"),args.indices.contains(i+1),UUID(uuidString:args[i+1]) != nil {
            folder = "ExpansionCandidate08-Test-" + args[i+1]
        }
        #endif
        return FileManager.default.urls(for:.documentDirectory,in:.userDomainMask)[0].appendingPathComponent(folder,isDirectory:true).appendingPathComponent("latest.json")
    }
    #if DEBUG
    /// Test hook: a finished expansion match as the single saved slot would hold it (real replay of a commander capture).
    static func seedTerminalRecord() -> ExpansionMatchRecord? {
        guard var s = try? GameSession(GameSetup.newGame(config:TacticalHints.updatedConfig(size:7,advancedCost:4),classOne:.warrior,classTwo:.mage)) else { return nil }
        for a: GameAction in [.placeSoldier(Point(3,2)),.endTurn,.placeSoldier(Point(2,1)),.placeSoldier(Point(4,1)),.endTurn,.placeSoldier(Point(3,0))] {
            guard s.apply(a).success else { return nil }
        }
        guard s.state.status != .ongoing else { return nil }
        return try? ExpansionMatchRecord(session:s,matchID:UUID())
    }
    #endif
    private var candidateURL: URL { Self.savedURL }
    /// Staging next to the single saved slot (INTEG-ACCESS-01 / P1): see `ExpansionStartJournal`.
    static var journal: ExpansionStartJournal { ExpansionStartJournal(slot: savedURL) }
    /// Identity of the saved match when it is already finished; `nil` for no file, an unfinished match, a legacy file
    /// without an identity, or anything that fails validation (the file is never modified here).
    static func savedTerminalIdentity() -> UUID? { journal.savedTerminalIdentity() }
    /// The complete zero-step record of the match as it starts (nothing is written here).
    func initialRecord() throws -> ExpansionMatchRecord {
        guard let session else { throw RecordError.invalidSetup }
        return try ExpansionMatchRecord(session:session,computer:computer,difficulty:computer == nil ? nil:difficulty,matchID:matchID)
    }
    #if DEBUG
    /// UI-test setup only: legal end-turn pairs applied straight to the session (the scene is not active yet at launch),
    /// then saved, so the match stays a recordable game from a real opening.
    func passTurnsForTest(untilBlackMana mana: Int) {
        guard var s = session else { return }
        while s.state.mana(of:.one) < mana, s.state.current == .one, s.state.ply < 30 {
            guard s.apply(.endTurn).success, s.apply(.endTurn).success else { break }
        }
        session = s; cancelSelection(); saveCandidate(announce:false)
    }
    #endif
    func saveCandidate(announce: Bool = true) {
        guard let session,!reviewFixture else { return }
        do {
            let bytes = try ExpansionMatchRecord(session:session,computer:computer,difficulty:computer == nil ? nil:difficulty,matchID:matchID).data()
            try FileManager.default.createDirectory(at:candidateURL.deletingLastPathComponent(),withIntermediateDirectories:true)
            try bytes.write(to:candidateURL,options:.atomic); savedCount = session.log.count
            if session.state.status != .ongoing, !terminalReported, let matchID {
                terminalReported = true; onTerminal?(matchID)
            }
            if announce { message = "已保存 \(savedCount) 個合法行動，包含魔物與技能庫存。" }
        } catch { message = "候選存局未保存：\(error)。目前對局仍保留，可繼續操作。" }
    }
    @discardableResult func resumeCandidate() -> Bool {
        stop(); cancelSelection()
        do {
            let values = try candidateURL.resourceValues(forKeys:[.fileSizeKey])
            guard let count = values.fileSize,count <= ExpansionMatchRecord.byteLimit else { throw RecordError.oversized }
            let record = try ExpansionMatchRecord.read(Data(contentsOf:candidateURL))
            let rebuilt = try record.rebuild()
            reviewTime = nil; reviewWidth = nil; reviewFixture = false
            matchID = record.matchID; terminalReported = rebuilt.state.status != .ongoing
            computer = record.computer; difficulty = record.difficulty ?? "easy"
            voiceCadence.reset()
            session = rebuilt; size = state.config.boardSize; one = state.heroClass(of:.one); two = state.heroClass(of:.two)
            advancedCost = state.config.expansionSkillManaCost; huntCost = state.config.monsterBattlefield?.huntAPCost ?? 1
            if let mode = state.config.monsterBattlefield { monsters = mode.monsters.count == 2 ? .dual : mode.monsters[0].kind == .slime ? .slime:.wolf } else { monsters = .none }
            savedCount = session!.log.count; challenge = false; instruction = nil; showHint = false; mode = .soldier
            legacySkillsOnResume = !state.config.experimentalFriendlyRedeploy
            message = "已重播並載入 \(savedCount) 個合法行動，復原也已恢復。"
            return true
        } catch { message = "候選存局未載入：\(error)。目前盤面沒有更動。"; return false }
    }
    private func schedule(systemReduced: Bool) {
        guard let p = receipt else { return }
        let marker = generation
        var sound: [(String,Double,Double)] = []
        let voiceCue: (String,Double)?
        switch p.action {
        case .castMagicHand,.castFriendlyRedeploy,.castDoublePull: voiceCue = ("mage-cast-B",0.08)
        case .castBastion,.castReformation: voiceCue = ("w7-voice-B",0.08)
        case .castSwap,.castChainSwap: voiceCue = ("p8-voice-rogue-"+castTake,0.06)
        case .castSanctuary,.castSanctum,.castOffering: voiceCue = ("p8-voice-priest-"+castTake,0.06)
        default: voiceCue = nil
        }
        let carriedVoiceTail = samples.remainingVoiceDuration
        var hasVoice = false
        var acceptedVoice: (String,Double,Double)?
        if let (key,delay) = voiceCue {
            var proposal = voiceCadence
            #if DEBUG
            let clock = voiceClockForAudit ?? ProcessInfo.processInfo.systemUptime
            let requestedKey = voiceKeyForAudit ?? key
            #else
            let clock = ProcessInfo.processInfo.systemUptime
            let requestedKey = key
            #endif
            let requested = proposal.shouldSpeak(player:p.before.current,hero:p.before.heroClass(of:p.before.current),at:clock,
                                                  eligible:!muted && voice && voiceVolume > 0)
            if requested {
                hasVoice = samples.schedule(requestedKey,after:delay,volume:0.85)
                if hasVoice { voiceCadence = proposal; acceptedVoice = (requestedKey,delay,0.85);cues += 1 }
            } else { voiceCadence = proposal }
        }
        let voiceEnd = max(carriedVoiceTail,acceptedVoice.map { $0.1+samples.duration($0.0) } ?? 0)
        // A carried sentence must not suppress a later contact after it has ended.
        func mix(at delay:Double) -> ExpansionCueMix { ExpansionCueMix(voiceEnabled:delay < voiceEnd) }
        if !muted {
            switch p.action {
            case .castMagicHand,.castFriendlyRedeploy,.castDoublePull:
                sound = [("p5-conjure",0.08,mix(at:0.08).preparation),("p5-push",p.moveStart,mix(at:p.moveStart).motion),("p5-contact",p.arrival,mix(at:p.arrival).impact)]
            case .castBastion,.castReformation:
                sound = [("w7-brace",0.20,mix(at:0.20).preparation),("w7-strike",p.arrival,mix(at:p.arrival).impact),("w7-land",p.arrival,mix(at:p.arrival).impact)]
            case .castSwap,.castChainSwap:
                sound = [("p8-rogue-coil",0.04,mix(at:0.04).preparation),("p8-rogue-dash",p.moveStart,mix(at:p.moveStart).motion),("p8-rogue-land",p.arrival,mix(at:p.arrival).impact)]
                if p.isChainSwap { let at = (p.moveStart+p.arrival)/2; sound.insert(("p8-rogue-land-first",at,mix(at:at).impact*0.60),at:2) }
            case .castSanctuary, .castSanctum, .castOffering:
                sound = [("p8-priest-prayer",0.06,mix(at:0.06).preparation),("p8-priest-bless",p.moveStart,mix(at:p.moveStart).motion),("p8-priest-land",p.arrival,mix(at:p.arrival).impact)]
            case .useStickyBounce:
                sound = [("p8-slime-coil",0.12,ExpansionCueMix.monsterPreparation),("p8-slime-bounce",p.moveStart,ExpansionCueMix.monsterMotion),("p8-slime-land",p.arrival,ExpansionCueMix.monsterImpact)]
            case .useShadowStep:
                sound = [("p8-wolf-growl",0.02,ExpansionCueMix.monsterPreparation),("p8-wolf-dash",p.moveStart,ExpansionCueMix.monsterMotion),("p8-wolf-land",p.arrival,ExpansionCueMix.monsterImpact)]
            case .huntMonster(let point):
                let slime = p.before.config.monsterBattlefield?.kind(at:point) == .slime
                sound = slime ? [("p8-slime-coil",0.02,ExpansionCueMix.monsterPreparation),("p8-slime-land",p.arrival,ExpansionCueMix.monsterImpact)] : [("p8-wolf-growl",0.02,ExpansionCueMix.monsterPreparation),("p8-wolf-land",p.arrival,ExpansionCueMix.monsterImpact)]
            case .placeSoldier,.summonHero: sound = [("place",p.arrival,0.55)]
            default: break
            }
            if !p.captures.isEmpty { sound.append(("capture",p.captureStart,p.captureStart < voiceEnd ? 0.30:0.60)) }
            if let ending = p.terminalCue(computer: computer), onTerminalCue == nil {
                sound.append((ending,p.duration,p.duration < voiceEnd ? 0.30:0.60))
            }
        }
        let ending = p.terminalCue(computer: computer)
        let routedEnding = ending != nil && onTerminalCue != nil
        for (key,delay,volume) in sound { if samples.schedule(key,after:delay,volume:volume) { cues += 1 } }
        // Voice was scheduled once before choosing the matching SFX mix.
        // Include it in the shared lifetime/audit timeline without playing it again.
        if let acceptedVoice { sound.append(acceptedVoice) }
        lastSoundKeys = sound.map { $0.0 } + (routedEnding ? ending.map { [$0] } ?? [] : [])
        #if DEBUG
        lastSoundSchedule = sound.map { (key:$0.0,delay:$0.1,gain:$0.2,playerGain:samples.volume($0.0)) }
        #endif
        let endingTail = routedEnding && !muted ? ending.map { samples.duration($0) } ?? 0 : 0
        let window = ExpansionPlaybackWindow.make(visualEnd:p.duration,lastSoundEnd:max(carriedVoiceTail,sound.map { $0.1 + samples.duration($0.0) }.max() ?? 0),
                                                  terminal:ending != nil,endingTail:endingTail)
        presentationHold = window.inputEnd
        presentationAudioHold = window.audioEnd
        playing = window.inputEnd > 0
        task = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for:.seconds(window.visualEnd))
                guard let self,self.generation == marker,self.active,!self.interrupted else { return }
                if routedEnding,let ending { self.onTerminalCue?(ending) }
                if ending == nil { self.playing = false; self.receipt = nil }
                try await Task.sleep(for:.seconds(max(0,window.inputEnd-window.visualEnd)))
                guard self.generation == marker,self.active,!self.interrupted else { return }
                self.playing = false; self.receipt = nil
                try await Task.sleep(for:.seconds(max(0,window.audioEnd-window.inputEnd)))
            } catch { return }
            guard let self,self.generation == marker else { return }
            self.task = nil
        }
    }
    var audit: String { "cues=\(cues)|players=\(samples.playing)|active=\(playing)|generation=\(generation)|keys=\(lastSoundKeys.joined(separator:","))|frozen=\(reviewTime != nil && frameReceipt != nil)|muted=\(muted)|voice=\(voice)|reduced=\(reduced)|voices=\(samples.playingVoices)" }
    var huntPreview: TacticalHuntPreview? {
        guard case .huntMonster(let point) = pending else { return nil }
        return TacticalHuntPreview(state,at:point)
    }
    var presentedHuntKind: MonsterKind? {
        if let hunt = huntPreview { return hunt.kind }
        guard let p = frameReceipt,let point = p.hunted.first else { return nil }
        return p.before.config.monsterBattlefield?.kind(at:point)
    }
    var presentedHuntTitle: String? {
        if let hunt = huntPreview { return hunt.title }
        guard let kind = presentedHuntKind,let p = frameReceipt else { return nil }
        return "\(p.caster == .one ? "黑方":"白方")討伐 · \(kind == .slime ? "史萊姆":"暗影狼")"
    }
    var blockedReason: String? {
        if controlsLocked { return playing ? "演出中，落定後可操作" : "對手回合，請等待" }
        if let hunt = huntPreview { return hunt.reason == .none ? nil : hunt.targetRestriction ?? GameStore.reason(hunt.reason) }
        let kind: TacticalHintMode = switch mode {
        case .soldier: .soldier; case .summon: .summon; case .skill: .skill; case .advanced: .advanced; case .loot: .loot
        }
        return TacticalReadiness.restriction(state,mode:kind,ability:ability)?.message
    }
    var stepPrompt: String {
        if let blockedReason { return blockedReason }
        if let hunt = huntPreview { return hunt.awardsLoot ? "確認取得\(hunt.reward) · 下個己方回合可用" : "確認討伐，移除魔物打開空點" }
        if let preview {
            guard preview.success else { return "目標不合法，重新選點或取消" }
            let action: String = switch pending {
            case .placeSoldier: "放兵"
            case .summonHero: "召喚英雄"
            case .castBastion: state.config.bastionScope == .connectedGroup ? "沿棋群築壘" : "築壘"
            case .castMagicHand: "施放魔法之手"
            case .castFriendlyRedeploy: "調度己兵"
            case .castSwap: "換位"
            case .castOffering: "奉獻己兵"
            case .castSanctum: "施放聖所"
            case .castDoublePull: "施放雙重牽引"
            case .castReformation: "戰線重整"
            case .castChainSwap: "連鎖換位"
            case .useStickyBounce: "使用黏彈"
            case .useShadowStep: "使用影步"
            default: "執行行動"
            }
            return "目標已選好，按確認\(action)"
        }
        let hero = state.heroClass(of:state.current),n = selected.count
        switch mode {
        case .soldier: return "① 點綠色空點 → ② 確認放兵"
        case .summon: return "① 選己方棋子旁綠點 → ② 確認"
        case .skill:
            switch hero {
            case .warrior: return n == 0 ? "① 選棋群旁第1個空點" : "② 選第2個不同空點"
            case .mage: return state.config.experimentalFriendlyRedeploy ? (n == 0 ? "① 選相連己兵（法師2格內）" : "② 選原棋群旁空點") : (n == 0 ? "① 選2格內普通兵" : "② 選推動方向")
            case .rogue: return "① 選正鄰敵兵 → ② 確認換位"
            case .priest: return "① 選2格內己兵 → ② 確認奉獻"
            case .none: return "先選擇職業"
            }
        case .advanced:
            if hero == .rogue { return n == 0 ? "① 選英雄正鄰敵兵" : "② 選第1敵兵旁另一敵兵" }
            if hero == .priest { return n == 0 ? "① 選牧師2格內要犧牲的己兵" : "② 選牧師或主將旁的空點補兵" }
            return ["① 選第1顆士兵","② 選第1個目的空點","③ 選第2顆不同士兵","④ 選第2個不同空點"][min(n,3)]
        case .loot: return ability == .shadowStep ? "① 選英雄直線2格內空點" : n == 0 ? "① 選己方接觸支點" : "② 選支點旁普通士兵"
        }
    }
    var tacticalMessage: String {
        if let p = frameReceipt,!p.hunted.isEmpty {
            if let grant = p.lootGrants.first {
                return "\(grant.owner == .one ? "黑方":"白方")取得\(grant.ability == .stickyBounce ? "黏彈":"影步")一次 · 下個己方回合可用"
            }
            return "討伐移除魔物，空點已打開 · 本局無戰利獎勵"
        }
        if let blockedReason { return blockedReason }
        if let hunt = huntPreview { return "合法預覽：\(hunt.summary)" }
        if preview != nil { return previewText }
        if mode == .soldier {
            return state.board.monsters.isEmpty ? "綠點可放士兵 · 1 AP · 先預覽再確認" : "包圍後點「討伐」→ 確認；不會自動觸發"
        }
        if mode == .summon { return "1 AP＋\(state.config.summonCost(state.heroClass(of:state.current))) 能量 · 己兵旁空點" }
        if legalTargets.isEmpty { return "沒有合法目標；先連接棋群或換一招" }
        let cost = mode == .loot ? 0 : mode == .advanced ? state.config.expansionSkillManaCost : state.config.skillManaCost
        return "1 AP＋\(cost) 能量 · 每回合限一次 · 綠圈提示下一點"
    }
    var help: String {
        if let hunt = huntPreview { return hunt.help }
        let hero = state.heroClass(of:state.current)
        return switch mode {
        case .soldier: state.board.monsters.isEmpty ? "選一個空點，確認後落子。" : "選一個空點，確認後落子。\n\n" + SkillGuide.monsters + "\n" + SkillGuide.loot
        case .summon: "選己方棋子正鄰空點。牧師和法師召喚3能量，其他2能量。"
        case .skill:
            // Only the expansion rules describe these skills; a legacy resume keeps the original wording.
            state.config.experimentalFriendlyRedeploy || hero == .priest || hero == .rogue
                ? SkillGuide.basic(hero) + "\n" + SkillGuide.basicSteps(hero)
                : hero == .warrior ? (state.config.bastionScope == .connectedGroup ? "依序選戰士相連棋群旁兩個不同空點。英雄可以透過相連士兵延伸築壘。" : "依序選戰士正鄰兩個空點。")
                : "選距法師2格內的普通士兵，再選推動方向。"
        case .advanced: SkillGuide.second(hero) + (SkillGuide.secondSteps(hero).isEmpty ? "" : "\n" + SkillGuide.secondSteps(hero))
        case .loot: ability == .stickyBounce ? SkillGuide.stickyBounce : SkillGuide.shadowStep
        }
    }
    /// Tap steps only, for the status line while targets are being picked (the full explanation is in 技能說明).
    private var stepHelp: String {
        let hero = state.heroClass(of:state.current)
        switch mode {
        case .skill where state.config.experimentalFriendlyRedeploy: return SkillGuide.basicSteps(hero)
        case .advanced: return SkillGuide.secondSteps(hero)
        default: return help
        }
    }
    var previewText: String {
        guard let preview else { return selected.isEmpty ? help : "已選 \(selected.count) 個位置。\(stepHelp)" }
        guard preview.success else {
            if case .castFriendlyRedeploy = pending {
                if preview.reason == .invalidTarget { return "只能調度己方普通士兵，不能移敵兵或英雄" }
                if preview.reason == .notAdjacentToFriend { return "此己兵未與法師棋群相連" }
                if preview.reason == .outOfRange { return "來源須在法師2格內，目的須在原棋群旁" }
            }
            return GameStore.reason(preview.reason)
        }
        let captures = preview.events.reduce(0) { n,e in if case .piecesCaptured(_,let p) = e { return n+p.count }; return n }
        let spent = preview.events.compactMap { e -> String? in if case .resourcesSpent(_,let ap,let mana) = e { return "\(ap) AP／\(mana) 能量" }; return nil }.first ?? ""
        // Priest sacrifices say what the sacrifice buys (review PRIEST-S2-P0: players could not see why to give a stone up).
        if let action = pending, let insight = PriestSacrificeInsight(state, action) {
            // Spend first, then the trade; the line may be cut on a phone, the 技能說明 sheet shows it whole.
            return "\(spent) · \(insight.summary)。確認前不扣資源、不播聲音。"
        }
        return "合法預覽：\(spent) · 提 \(captures) 顆。確認前不扣資源、不播聲音。"
    }
}

struct V11HomeView: View {
    var onClose: (() -> Void)? = nil
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:20) {
                    Text("TacticalGo 1.1").font(.largeTitle.bold())
                    Text("職業、魔物與聲畫候選").foregroundStyle(.secondary)
                    NavigationLink { ExpansionLabView() } label: { card("開始對戰","四職業、第二技能、魔物戰場","checkerboard.rectangle") }.accessibilityIdentifier("v11-play")
                    NavigationLink { ExpansionLabView(practice:.mage) } label: { card("技能試用","從合法開局重播，比較落子與新技能","wand.and.stars") }.accessibilityIdentifier("v11-practice")
                    NavigationLink { ExpansionLabView(loadChallenge:true) } label: { card("牧師救援挑戰","一眼困境：奉獻能否比普通落子更有用？","leaf.fill") }.accessibilityIdentifier("v11-challenge")
                    NavigationLink { MonsterLabView() } label: { card("魔物比較","0／1 AP討伐、單怪與雙怪、戰利技能","pawprint.fill") }.accessibilityIdentifier("v11-monsters")
                    NavigationLink { CombatPresentationLabView() } label: { card("動畫與配音","保留法師D、法師與戰士英文B，可看A/B","speaker.wave.2.fill") }.accessibilityIdentifier("v11-presentation")
                    NavigationLink { PlayableGameView() } label: { card("原規則對照","原三職與原有電腦對戰","arrow.triangle.branch") }.accessibilityIdentifier("v11-original")
                    Text("候選玩法與聲畫待試玩驗收。擴充對戰目前由兩人在本機輪流操作。").font(.caption).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth:650)
            }.background(P02Cozy.bg).foregroundStyle(P02Cozy.ink).preferredColorScheme(.light)
            .toolbar {
                if let onClose {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("返回首頁", action: onClose).accessibilityIdentifier("v11-close")
                    }
                }
            }
        }
    }
    private func card(_ title: String,_ subtitle: String,_ icon: String) -> some View {
        HStack(spacing:16) { Image(systemName:icon).font(.title).frame(width:40)
            VStack(alignment:.leading,spacing:6) { Text(title).font(.title3.bold()); Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            Spacer(); Image(systemName:"chevron.right")
        }.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(P02Cozy.card,in:RoundedRectangle(cornerRadius:18))
    }
}

struct ExpansionLabView: View {
    @State private var store = ExpansionLabStore()
    var practice: ExpansionPractice?
    var loadChallenge = false
    @State private var loadedPractice = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @State private var showSetup = false
    var body: some View {
        ScrollView {
            VStack(spacing:12) {
                Text(status).font(.headline).accessibilityIdentifier("exp-status")
                HStack {
                    Button("對局設定",systemImage:"slider.horizontal.3") { showSetup = true }.accessibilityIdentifier("exp-setup")
                    Spacer()
                    Button("復原",systemImage:"arrow.uturn.backward") { store.undo() }.disabled(store.session?.canUndo != true).accessibilityIdentifier("exp-undo")
                    Button("新局",systemImage:"arrow.clockwise") { store.restart() }.accessibilityIdentifier("exp-restart")
                }
                if let assets = store.assets {
                    TimelineView(.animation(paused:!store.playing)) { _ in
                        ExpansionBoard(store:store,assets:assets,time:store.reviewTime ?? (store.playing ? ProcessInfo.processInfo.systemUptime-store.started : 2),reduced:store.reduced || systemReduced)
                    }.aspectRatio(1024.0/1152,contentMode:.fit).frame(maxWidth:store.reviewWidth ?? 520)
                } else { Text("棋盤素材未載入").foregroundStyle(.red) }
                Picker("行動",selection:$store.mode) {
                    ForEach(ExpansionLabStore.Mode.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).onChange(of:store.mode) { store.cancelSelection() }.disabled(store.playing).accessibilityIdentifier("exp-mode")
                if store.mode == .skill && store.state.heroClass(of:store.state.current) == .mage {
                    HStack { ForEach(PushDirection.allCases,id:\.self) { d in Button(d.title,systemImage:d.symbol) { store.push(d) }.accessibilityIdentifier("exp-push-"+d.rawValue) } }
                }
                if store.mode == .loot {
                    Picker("戰利能力",selection:$store.ability) { Text("黏彈").tag(MonsterAbility.stickyBounce); Text("影步").tag(MonsterAbility.shadowStep) }
                        .pickerStyle(.segmented).onChange(of:store.ability) { store.cancelSelection() }
                }
                Text(store.previewText).font(.subheadline).frame(maxWidth:.infinity,alignment:.leading).accessibilityIdentifier("exp-preview")
                HStack {
                    Button("取消選擇") { store.cancelSelection() }.accessibilityIdentifier("exp-cancel")
                    Button("確認行動") { store.confirm(systemReduced:systemReduced) }.buttonStyle(.borderedProminent)
                        .disabled(store.preview?.success != true || store.playing).accessibilityIdentifier("exp-confirm")
                    Button(store.state.awaitingFreeHunt ? "略過討伐" : "結束回合") { store.endTurn() }.disabled(store.playing).accessibilityIdentifier("exp-end")
                }
                if let instruction = store.instruction { Text(instruction).font(.subheadline.bold()).accessibilityIdentifier("exp-instruction") }
                if store.challenge {
                    Button(store.showHint ? "隱藏提示" : "查看提示") { store.showHint.toggle() }.accessibilityIdentifier("exp-hint")
                    if store.showHint { Text(PriestSanctuaryChallenge.hint).font(.caption).accessibilityIdentifier("exp-hint-text") }
                }
                HStack {
                    Button("牧師救援挑戰") { store.priestChallenge() }.accessibilityIdentifier("exp-challenge")
                    Button("法師反制") { store.priestCounter() }.accessibilityIdentifier("exp-counter")
                }
                HStack { ForEach(ExpansionPractice.allCases,id:\.self) { f in Button(f.hero.title) { store.practice(f) }.buttonStyle(.bordered).accessibilityIdentifier("exp-practice-"+f.rawValue) } }
                Text("上方職業按鈕載入試用局面；可改用普通落子比較。第二技能 \(store.state.config.expansionSkillManaCost) 能量；所有英雄/魔物技能每回合共用一次。").font(.caption).foregroundStyle(.secondary)
                ForEach(Player.allCases,id:\.self) { player in
                    Text("\(player == .one ? "黑" : "白")方 \(store.state.heroClass(of:player).title) · \(store.state.mana(of:player)) 能量 · " + loot(player)).font(.caption).accessibilityIdentifier("exp-player-\(player.rawValue)")
                }
                HStack {
                    Button("保存候選",systemImage:"square.and.arrow.down") { store.saveCandidate() }.accessibilityIdentifier("exp-save")
                    Button("載入候選",systemImage:"arrow.clockwise") { store.resumeCandidate() }.accessibilityIdentifier("exp-resume")
                }
                Text("已確認的行動會自動保存；新局尚未落子前，可載入上次候選對局。").font(.caption).foregroundStyle(.secondary)
                Toggle("英文施法語音",isOn:$store.voice).onChange(of:store.voice) { store.stop() }.accessibilityIdentifier("exp-voice")
                Picker("盜賊／牧師英文語音",selection:$store.castTake) { Text("A").tag("A"); Text("B").tag("B") }.pickerStyle(.segmented).onChange(of:store.castTake) { store.stop() }.accessibilityIdentifier("exp-cast-take")
                Toggle("技能特效",isOn:$store.effects).accessibilityIdentifier("exp-effects")
                Toggle("靜音",isOn:$store.muted).onChange(of:store.muted) { store.stop() }.accessibilityIdentifier("exp-mute")
                Toggle("減少動態",isOn:$store.reduced).onChange(of:store.reduced) { store.stop() }.accessibilityIdentifier("exp-reduced")
                Text(store.message).font(.caption).accessibilityIdentifier("exp-message")
                Text(store.audit).font(.system(size:1)).foregroundStyle(.clear).frame(height:1).accessibilityIdentifier("exp-audit")
            }.padding(14).frame(maxWidth:650)
        }.background(P02Cozy.bg).foregroundStyle(P02Cozy.ink).preferredColorScheme(.light)
            .navigationTitle("1.1 對戰").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented:$showSetup) { setup }
            .onAppear { store.scene(scenePhase == .active); if !loadedPractice, let practice { store.practice(practice); loadedPractice = true }; if !loadedPractice,loadChallenge { store.priestChallenge(); loadedPractice = true } }
            .onDisappear { store.scene(false) }
            .onChange(of:scenePhase) { store.scene(scenePhase == .active) }
            .onChange(of:systemReduced) { store.stop() }
            .task { if ProcessInfo.processInfo.arguments.contains("--exp-autoplay") { do { try await Task.sleep(for:.seconds(3));store.confirm(systemReduced:systemReduced) } catch { store.stop() } } }
    }
    private var status: String {
        let s = store.state
        if let winner = s.winner { return "\(winner == .one ? "黑" : "白")方獲勝" }
        if s.status == .drawn { return "回合上限 · 和局" }
        return "\(s.current == .one ? "黑" : "白")方\(s.heroClass(of:s.current).title) · 第\(s.ply)回合 · \(s.apRemaining) AP · \(s.mana(of:s.current)) 能量"
    }
    private func loot(_ p: Player) -> String {
        let inventory = store.state.lootInventory(of:p)
        if inventory.isEmpty { return "無戰利能力" }
        return inventory.map { "\($0.ability == .stickyBounce ? "黏彈" : "影步")\(store.state.ply < $0.unlockPly ? "（下次己方回合解鎖）" : "×1")" }.joined(separator:"、")
    }
    private var setup: some View {
        NavigationStack {
            Form {
                Section("職業") {
                    Picker("黑方",selection:$store.one) { ForEach(HeroClass.allCases.filter { $0 != .none },id:\.self) { Text($0.title).tag($0) } }
                    Picker("白方",selection:$store.two) { ForEach(HeroClass.allCases.filter { $0 != .none },id:\.self) { Text($0.title).tag($0) } }
                }
                Section("玩法比較") {
                    Picker("棋盤",selection:$store.size) { Text("7×7").tag(7); Text("9×9").tag(9) }.disabled(store.monsters != .none)
                    Picker("第二技能",selection:$store.advancedCost) { Text("4 能量").tag(4); Text("5 能量").tag(5) }
                    Picker("魔物",selection:$store.monsters) { ForEach(ExpansionLabStore.Monsters.allCases,id:\.self) { Text($0.rawValue).tag($0) } }
                    Picker("討伐",selection:$store.huntCost) { Text("0 AP").tag(0); Text("1 AP").tag(1) }
                    Text("魔物占位會阻擋氣。正鄰己方至少2格且多於敵方可討伐；暗影狼還需要正鄰英雄。獎勵下次己方回合起可用一次，1 AP／0能量。").font(.caption)
                }
                Button("套用並開新局") { store.restart(); showSetup = false }.accessibilityIdentifier("exp-apply-setup")
            }.navigationTitle("對局設定").toolbar { Button("返回") { showSetup = false } }
        }.presentationDetents([.large])
    }
}

struct ExpansionBoard: View {
    private var weightedWarrior: Bool {
        #if DEBUG
        !ProcessInfo.processInfo.arguments.contains("--warrior-weight-before")
        #else
        true
        #endif
    }
    let store: ExpansionLabStore
    let assets: P02CozyAssets
    let time: Double
    let reduced: Bool
    var identityPrefix = "exp-cell"
    var focusedNine = false
    var focusedPhone = false
    var body: some View {
        GeometryReader { geo in
            let fit = Anim01Geometry(width:geo.size.width,height:geo.size.height,boardSize:store.state.board.size,focusedNine:focusedNine,focusedPhone:focusedPhone)
            let size = CGSize(width:fit.width,height:fit.height), pitch = CGFloat(fit.pitch)
            let p = store.frameReceipt
            let board = p?.board(at:time,reduced:reduced) ?? store.state.board
            let moving = p != nil && !reduced && time < p!.arrival
            let sources = Set(moving ? p!.transfers.map(\.from) : [])
            let targets = store.legalTargets
            let presentation = BoardPresentation(state:store.state,selected:store.selected,legal:targets,preview:store.preview)
            ZStack {
                Image(uiImage:assets.shadow).resizable().frame(width:size.width,height:size.height)
                Image(uiImage:assets.board).resizable().frame(width:size.width,height:size.height)
                ArenaGrid(boardSize:board.size).stroke(P02Cozy.ink.opacity(0.30),lineWidth:1)
                ForEach(targets.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y },id:\.self) { point in
                    if board.isEmpty(point) {
                        Circle().fill(Color(red:0.18,green:0.62,blue:0.46))
                            .overlay(Circle().stroke(Color(red:0.94,green:0.94,blue:0.76).opacity(0.65),lineWidth:0.5))
                            .frame(width:4.5,height:4.5)
                            .shadow(color:.black.opacity(0.55),radius:0.8).position(presentation.center(point,size)).zIndex(8)
                    } else {
                        Circle().stroke(Color(red:0.25,green:0.85,blue:0.63),lineWidth:2).frame(width:pitch*0.82,height:pitch*0.82)
                            .position(presentation.center(point,size)).zIndex(225)
                    }
                }.allowsHitTesting(false).accessibilityHidden(true)
                if let p,store.effects {
                    ExpansionContactEffects(receipt:p,time:time,pitch:pitch,size:size,reduced:reduced,
                                            center:{ presentation.center($0,size) }).zIndex(5)
                }
                if let p,store.effects {
                    ExpansionSpellEffects(receipt:p,assets:assets,hands:store.handPoses,time:time,pitch:pitch,size:size,reduced:reduced,
                                          plane:.ground,center:{ presentation.center($0,size) }).zIndex(6)
                    ExpansionSpellEffects(receipt:p,assets:assets,hands:store.handPoses,time:time,pitch:pitch,size:size,reduced:reduced,center:{ presentation.center($0,size) }).zIndex(160)
                }
                ForEach(board.points,id:\.self) { point in
                    if let piece = board[point],!sources.contains(point) {
                        posedToken(piece,pitch:pitch,plan:p,point:point).position(presentation.center(point,size)).zIndex(Double(point.y)*10+10)
                    }
                    if board.monsters.contains(point),let kind = store.state.config.monsterBattlefield?.kind(at:point),let image = store.monsterArt[kind] {
                        ZStack { Ellipse().fill(P02Cozy.card).overlay(Ellipse().stroke(P02Cozy.sage,lineWidth:1.5)).frame(width:pitch*0.76,height:pitch*0.40)
                            let pose = monsterPose(kind,point:point,plan:p)
                            Image(uiImage:image).resizable().scaledToFit().frame(width:pitch*0.70,height:pitch*0.70)
                                .scaleEffect(x:pose.x,y:pose.y,anchor:.bottom).rotationEffect(.degrees(pose.tilt),anchor:.bottom)
                                .offset(y:-pitch*0.20+pitch*pose.lift)
                        }.position(presentation.center(point,size)).zIndex(Double(point.y)*10+10)
                    }
                    Button { store.select(point) } label: { Color.clear.frame(width:pitch,height:pitch).contentShape(Rectangle()) }
                        .buttonStyle(.plain).position(presentation.center(point,size)).zIndex(300)
                        .accessibilityIdentifier("\(identityPrefix)-\(point.x)-\(point.y)")
                        .accessibilityLabel("\(String(UnicodeScalar(65+point.x)!))\(point.y+1)，\(cellName(point))")
                        .accessibilityValue(targets.contains(point) ? "可選下一點" : "")
                }
                if let p,moving {
                    ForEach(p.transfers.indices,id:\.self) { i in
                        let move = p.transfers[i],t = p.progress(at:time)
                        let point = transferCenter(move,receipt:p,progress:t,presentation:presentation,size:size,pitch:pitch)
                        posedToken(move.piece,pitch:pitch,plan:p,point:move.to,moving:true).position(point).zIndex(180)
                    }
                    ForEach(p.placements,id:\.self) { point in
                        if let piece = p.after.board[point] {
                            let c = presentation.center(point,size), t = p.progress(at:time)
                            token(piece,pitch:pitch,plan:p).opacity(min(1,t*4)).position(x:c.x,y:c.y-pitch*0.55*(1-t*t)).zIndex(170)
                        }
                    }
                }
                if let p,!reduced,time >= p.arrival,time < p.captureStart+0.18 {
                    ForEach(p.captures,id:\.at) { captured in
                        let f = CaptureDissolveFrame.sample(at:time,start:p.captureStart,commander:captured.piece.kind == .commander)
                        token(captured.piece,pitch:pitch,plan:nil).scaleEffect(f.scale,anchor:.bottom)
                            .opacity(f.opacity).offset(y:pitch*CGFloat(f.lift)).position(presentation.center(captured.at,size)).zIndex(190)
                    }
                }
                if let preview = store.preview,preview.success {
                    ForEach(preview.events.indices,id:\.self) { i in
                        if case .piecePushed(_,let from,let to,_) = preview.events[i] {
                            Path { path in path.move(to:presentation.center(from,size)); path.addLine(to:presentation.center(to,size)) }
                                .stroke(P02Cozy.deepMage,style:StrokeStyle(lineWidth:2,dash:[3,3])).zIndex(220)
                            Circle().stroke(P02Cozy.deepMage,style:StrokeStyle(lineWidth:2,dash:[3,3])).frame(width:pitch*0.66).position(presentation.center(to,size)).zIndex(220)
                        }
                    }
                }
                ForEach(store.selected.indices,id:\.self) { i in
                    let point = store.selected[i]
                    Circle().stroke(P02Cozy.deepMage,lineWidth:2.5).frame(width:pitch*0.80).position(presentation.center(point,size)).zIndex(230)
                    Text("\(i+1)").font(.system(size:10,weight:.bold)).foregroundStyle(.white).padding(2).background(P02Cozy.deepMage,in:Circle()).position(x:presentation.center(point,size).x+pitch*0.30,y:presentation.center(point,size).y+pitch*0.20).zIndex(230)
                }
                ForEach(Player.allCases,id:\.self) { player in
                    if let commander = board.find(player,.commander),board.liberties(at:commander).count <= 1 {
                        Circle().stroke(P02Cozy.danger,style:StrokeStyle(lineWidth:2,dash:[3,3])).frame(width:pitch*0.88).position(presentation.center(commander,size)).zIndex(240)
                    }
                }
            }.frame(width:size.width,height:size.height).offset(x:fit.x,y:fit.y)
                .allowsHitTesting(!store.playing && store.reviewTime == nil)
        }
    }
    private func posedToken(_ piece: Piece,pitch: CGFloat,plan: ExpansionPresentation?,point: Point,moving: Bool = false) -> some View {
        let f = plan?.tokenFrame(at:point,time:time,moving:moving,reduced:reduced) ?? .rest
        let focus = plan?.contextOpacity(at:point,time:time,reduced:reduced) ?? 1
        return token(piece,pitch:pitch,plan:plan).scaleEffect(x:f.scaleX,y:f.scaleY,anchor:.bottom)
            .rotationEffect(.degrees(f.tilt),anchor:.bottom).opacity(f.opacity*focus).offset(y:pitch*CGFloat(f.lift))
    }
    @ViewBuilder private func token(_ piece: Piece,pitch: CGFloat,plan: ExpansionPresentation?) -> some View {
        let hero = store.state.heroClass(of:piece.owner)
        let performing = plan?.caster == piece.owner && plan?.isHeroSkill == true
        if piece.kind == .hero,hero == .warrior,let image = assets.heroes[.warrior],let plate = store.warriorPlate {
            ZStack {
                P02SellUnitBase(black:piece.owner == .one,commander:false,width:pitch*0.74).offset(y:pitch*0.03)
                WarriorBodyView(original:image,plate:plate,pose:performing ? .skill(at:time,reduced:reduced,weighted:weightedWarrior) : .rest,width:pitch*0.88).offset(y:pitch*0.88*(0.5-448.0/512))
                P02SellUnitFrontRim(black:piece.owner == .one,width:pitch*0.74).offset(y:pitch*0.03)
                faction(piece,pitch:pitch)
            }
        } else if piece.kind == .hero,hero == .rogue,let image = assets.heroes[.rogue],let plate = store.roguePlate {
            ZStack {
                P02SellUnitBase(black:piece.owner == .one,commander:false,width:pitch*0.74).offset(y:pitch*0.03)
                ExpansionHeroBody(original:image,plate:plate,hero:.rogue,pose:performing ? .rogue(at:time,reduced:reduced,chained:plan?.isChainSwap == true):.rest,width:pitch*0.88).offset(y:pitch*0.88*(0.5-448.0/512))
                P02SellUnitFrontRim(black:piece.owner == .one,width:pitch*0.74).offset(y:pitch*0.03)
                faction(piece,pitch:pitch)
            }
        } else if piece.kind == .hero,hero == .priest,let image = store.priest,let plate = store.priestPlate {
            ZStack {
                P02SellUnitBase(black:piece.owner == .one,commander:false,width:pitch*0.74).offset(y:pitch*0.03)
                ExpansionHeroBody(original:image,plate:plate,hero:.priest,pose:performing ? .priest(at:time,reduced:reduced,offering:plan?.isOffering == true):.rest,width:pitch*0.98).offset(y:-pitch*0.43)
                P02SellUnitFrontRim(black:piece.owner == .one,width:pitch*0.74).offset(y:pitch*0.03)
                faction(piece,pitch:pitch)
            }
        } else {
            P02CozyToken(piece:piece,assets:assets,pitch:pitch,
                magePose:performing && hero == .mage ? .cast(at:time,timing:MagePresentationVariant.arcaneHand.timing,reduced:reduced,revision:.r2) : .rest,
                commercialStyle:true,heroClass:hero)
        }
    }
    private func monsterPose(_ kind: MonsterKind,point: Point,plan: ExpansionPresentation?) -> (x:CGFloat,y:CGFloat,tilt:Double,lift:CGFloat) {
        guard let plan,!reduced,plan.hunted.contains(point),time < plan.arrival else { return (1,1,0,0) }
        let f = MonsterHuntFrame.sample(kind:kind,at:time,arrival:plan.arrival,duration:plan.duration)
        return (f.x,f.y,f.tilt,f.lift)
    }
    private func transferCenter(_ move: CombatTransfer,receipt: ExpansionPresentation,progress t: Double,presentation: BoardPresentation,size: CGSize,pitch: CGFloat) -> CGPoint {
        let a = presentation.center(move.from,size),b = presentation.center(move.to,size)
        if case .castSwap = receipt.action {
            let offset = RogueSwapArc.offset(dx:Double(b.x-a.x),dy:Double(b.y-a.y),progress:t,pitch:Double(pitch))
            return CGPoint(x:a.x+(b.x-a.x)*t+offset.x,y:a.y+(b.y-a.y)*t+offset.y)
        }
        if case .castChainSwap(let first,_) = receipt.action {
            let middle = presentation.center(first,size)
            let point = RogueChainPath.position(from:(Double(a.x),Double(a.y)),to:(Double(b.x),Double(b.y)),via:(Double(middle.x),Double(middle.y)),progress:t,pitch:Double(pitch),hero:move.piece.kind == .hero,firstEnemy:move.from == first)
            return CGPoint(x:point.x,y:point.y)
        }
        return CGPoint(x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t)
    }
    private func faction(_ piece: Piece,pitch: CGFloat) -> some View {
        Group {
            if piece.owner == .one { Circle().fill(P02Cozy.card).overlay(Circle().fill(P02Cozy.coordinate).padding(0.7)) }
            else { Rectangle().fill(P02Cozy.ink).overlay(Rectangle().fill(P02Cozy.card).padding(1)).rotationEffect(.degrees(45)) }
        }.frame(width:max(3.5,pitch*0.1),height:max(3.5,pitch*0.1)).offset(x:-pitch*0.20,y:pitch*0.225)
    }
    private func cellName(_ p: Point) -> String {
        let board = store.state.board
        if board.monsters.contains(p) { return store.state.config.monsterBattlefield?.kind(at:p) == .slime ? "史萊姆" : "暗影狼" }
        guard let piece = board[p] else { return "空點" }
        return "\(piece.owner == .one ? "黑" : "白")方\(piece.kind == .hero ? store.state.heroClass(of:piece.owner).title : piece.kind == .commander ? "主將" : "士兵")"
    }
}
#endif

