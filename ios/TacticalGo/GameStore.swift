import SwiftUI
import TacticalGoCore
import TacticalGoMotion
import TacticalGoBot
import TacticalGoRecords

@MainActor @Observable final class GameStore {
    enum Review: String, CaseIterable { case normal = "一般", skill = "技能預覽", danger = "危險" }
    enum Mode: String, CaseIterable { case soldier = "放士兵", summon = "召喚英雄", skill = "使用技能" }
    var savedRecords: [MatchRecord] = []
    var recordErrorMessage: String?
    var recordRules: RecordRules = .original
    var r2Fixture: R2PracticeFixture?
    var r2Rules: RecordRules = .original
    private var activeRecord: MatchRecord?
    private let records: RecordRepository
    var resumableRecord: MatchRecord? { savedRecords.first { $0.steps.last?.after.status == .ongoing || $0.steps.isEmpty } }
    func refreshRecords() {
        do {
            let result = try records.list(); savedRecords = result.records
            if result.rejected > 0 { recordErrorMessage = "有 \(result.rejected) 份棋譜無法讀取，原檔已保留。" }
        } catch { recordErrorMessage = "無法讀取存局，請稍後再試。" }
    }
    private func saveRecord() {
        guard var record = activeRecord else { return }
        record.updated = Date(); record.difficulty = botDifficulty.rawValue
        activeRecord = record
        do {
            try records.save(record)
            savedRecords.removeAll { $0.id == record.id }; savedRecords.insert(record, at: 0)
        } catch { recordErrorMessage = "這次存局未成功；先前存局已保留。" }
    }
    func resume(_ record: MatchRecord) -> Bool {
        do {
            let restored = try record.rebuild().0
            guard restored.state.status == .ongoing else { return false }
            cancelBotWork(); session = restored; activeRecord = record
            r2Fixture = nil
            size = record.size; computer = record.computer; recordRules = record.rules
            botDifficulty = BotDifficulty(rawValue: record.difficulty) ?? .easy
            botTurnsCompleted = 0; botDiscardedDecisions = 0; botLastDecision = ""
            playback = nil; selected = []; pushDirection = nil; mageOperation = .push; mode = .soldier; review = .normal
            message = "已恢復對戰；輪到\(state.current == .one ? "黑方" : "白方")。"
            return true
        } catch { recordErrorMessage = "存局驗證失敗，原檔已保留。"; return false }
    }
    func recordExport(_ record: MatchRecord) -> URL? {
        // Re-validate the exported snapshot without changing the live game.
        do {
            let data = try record.encoded(); _ = try MatchRecord.decode(data)
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("TacticalGo-" + record.id.uuidString + ".json")
            try data.write(to: url, options: .atomic); return url
        } catch { recordErrorMessage = "棋譜匯出失敗。"; return nil }
    }
    var session: GameSession
    var playback: BoardPlayback?
    let audio = CombatAudio()
    @ObservationIgnored private var audioTask: Task<Void, Never>?
    @ObservationIgnored private var audioGeneration: UInt64 = 0
    private var audioMatchActive = false
    private var audioSceneActive = true
    private var audioDuration = 0.0
    #if DEBUG
    private(set) var audioCueHistory: [String] = []
    #endif
    func cancelAudioFeedback() {
        audioGeneration &+= 1; audioTask?.cancel(); audioTask = nil
        audio.cancelEffects()
    }
    func setMatchAudioActive(_ active: Bool) {
        if active && !audioMatchActive { audio.resetBattle() }
        audio.updateState(state)
        audioMatchActive = active
        if !active { cancelAudioFeedback() }
        audio.setMatchActive(active)
    }
    func setSceneAudioActive(_ active: Bool) {
        audioSceneActive = active
        if !active { cancelAudioFeedback() }
        audio.setSceneActive(active)
    }
    func presentAudio(before: GameState, action: GameAction, outcome: ActionOutcome) {
        let plan = CombatFeedbackPlan.make(before: before, action: action, outcome: outcome)
        audioDuration = plan.duration
        // A normal end-turn has no sound and must not silence an already
        // committed skill's pending landing/capture cues.
        guard !plan.cues.isEmpty else { return }
        cancelAudioFeedback()
        guard outcome.success, audioMatchActive, audioSceneActive else { return }
        audio.updateState(outcome.state)
        let skill: Bool
        switch action {
        case .castBastion, .castMagicHand, .castFriendlyRedeploy, .castSwap, .castSeal: skill = true
        default: skill = false
        }
        if skill {
            let duration = plan.cues.filter { !["victory", "draw"].contains($0.key) }
                .map { $0.start + ($0.key == "capture" ? 0.48 : $0.key == "mage" ? 0.62 : 0.55) }.max() ?? plan.duration
            audio.duckSkill(duration: duration)
        }
        let generation = audioGeneration
        audioTask = Task { [weak self] in
            var elapsed = 0.0
            for cue in plan.cues {
                do { try await Task.sleep(for: .seconds(max(0, cue.start - elapsed))) } catch { return }
                guard let self, self.audioGeneration == generation, !Task.isCancelled else { return }
                let key = cue.key == "victory" && self.computer != nil && outcome.state.winner == self.computer ? "defeat" : cue.key
                #if DEBUG
                self.audioCueHistory.append(key)
                #endif
                self.audio.play(key)
                elapsed = cue.start
            }
        }
    }
    var review: Review = .normal
    var mode: Mode = .soldier
    var selected: [Point] = []
    var pushDirection: PushDirection?
    enum MageOperation: String, CaseIterable { case push = "推動", redeploy = "調度己兵" }
    var mageOperation: MageOperation = .push
    var message = "點棋盤預覽，再按確認。"
    enum Renderer: String, CaseIterable { case models = "3D", swiftUI = "SwiftUI", spriteKit = "SpriteKit" }
    var renderer: Renderer = .models
    var size = 7
    var computer: Player?
    var botDifficulty: BotDifficulty = .easy
    var isBotThinking = false
    var isBotActing = false
    var botAction: GameAction?
    var botActionIndex = 0
    var botActionCount = 0
    var botMotionStartedAt: Date?
    var botLastDecision = ""
    var botTurnsCompleted = 0
    var botDiscardedDecisions = 0
    #if DEBUG
    var deliverCancelledBotResult = false
    var botDelayNanoseconds: UInt64 = 0
    var botStepNanoseconds: UInt64 = 900_000_000
    var botReviewPhases = false
    @ObservationIgnored private var botReviewPermit: UInt64 = 0
    func advanceBotReviewPhase() { botReviewPermit &+= 1 }
    #else
    private let deliverCancelledBotResult = false
    private let botDelayNanoseconds: UInt64 = 0
    private let botStepNanoseconds: UInt64 = 900_000_000
    #endif
    @ObservationIgnored private var botGeneration: UInt64 = 0
    @ObservationIgnored private var botWorker: Task<BotTurnPlan?, Never>?
    @ObservationIgnored private var botDelivery: Task<Void, Never>?
    var isComputerTurn: Bool { isBotActing || (computer == state.current && state.status == .ongoing) }
    var humanPlayer: Player { computer?.opponent ?? .one }
    var canUndoHumanDecision: Bool {
        guard computer != nil else { return session.canUndo }
        var previous = session
        while previous.undo() {
            if previous.state.current != computer { return true }
        }
        return false
    }
    var botActionLabel: String {
        guard let action = botAction else { return "" }
        func c(_ p: Point) -> String { String(UnicodeScalar(65 + p.x)!) + String(p.y + 1) }
        switch action {
        case .placeSoldier(let p): return "在 \(c(p)) 放士兵"
        case .summonHero(let p): return "在 \(c(p)) 召喚\(state.heroClass(of: computer ?? .two).title)"
        case .castBastion(let a, let b): return "築壘：\(c(a))、\(c(b))"
        case .castMagicHand(let p, let d): return "魔法之手：\(c(p)) 向\(d.title)推動"
        case .castFriendlyRedeploy(let from, let to): return "調度己兵：\(c(from)) → \(c(to))"
        case .castSwap(let p): return "換位：英雄與 \(c(p))"
        case .castSeal(let p): return "封印 \(c(p))"
        case .endTurn: return "結束回合"
        }
    }

    var state: GameState { session.state }
    var selectedAction: GameAction? {
        guard let p = selected.first else { return nil }
        switch mode {
        case .soldier: return .placeSoldier(p)
        case .summon: return .summonHero(p)
        case .skill:
            switch state.heroClass(of: state.current) {
            case .warrior: return selected.count == 2 ? .castBastion(selected[0], selected[1]) : nil
            case .mage:
                if state.config.mageSkill == .seal { return .castSeal(p) }
                if state.config.experimentalFriendlyRedeploy && mageOperation == .redeploy {
                    return selected.count == 2 ? .castFriendlyRedeploy(p, selected[1]) : nil
                }
                return pushDirection.map { .castMagicHand(p, $0) }
            case .rogue: return .castSwap(p)
            case .none: return nil
            }
        }
    }
    var preview: ActionOutcome? { selectedAction.map { GameEngine.apply(state, $0) } }
    var legalTargets: Set<Point> {
        guard !isComputerTurn else { return [] }
        let actions = GameEngine.legalActions(state)
        return Set(actions.flatMap { action -> [Point] in
            switch (mode, action) {
            case (.soldier, .placeSoldier(let p)), (.summon, .summonHero(let p)): return [p]
            case (.skill, .castSeal(let p)), (.skill, .castSwap(let p)): return [p]
            case (.skill, .castMagicHand(let p, _)): return mageOperation == .push ? [p] : []
            case (.skill, .castFriendlyRedeploy(let from, let to)):
                guard mageOperation == .redeploy else { return [] }
                return selected.first.map { $0 == from ? [to] : [] } ?? [from]
            case (.skill, .castBastion(let a, let b)):
                if let first = selected.first { return a == first || b == first ? [a, b] : [] }
                return [a, b]
            default: return []
            }
        })
    }
    init() {
        var directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/Records-v1", isDirectory: true)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "--record-isolation"), args.indices.contains(i + 1), let id = UUID(uuidString: args[i + 1]) {
            directory = URL.applicationSupportDirectory.appendingPathComponent("TacticalGo/TestRecords/" + id.uuidString, isDirectory: true)
        }
        #endif
        records = RecordRepository(directory: directory)
        session = GameSession(Self.scenario(size: 7, review: .normal))
        audio.onInterruption = { [weak self] in self?.cancelAudioFeedback() }
        refreshRecords()
    }
    func load(_ review: Review? = nil, size: Int? = nil) {
        leaveMatch()
        if let review { self.review = review }
        if let size { self.size = size }
        session = GameSession(Self.scenario(size: self.size, review: self.review))
        playback = nil
        mode = self.review == .skill ? .skill : .soldier
        selected = self.review == .skill ? [Point(4, 3)] : []
        message = self.review == .danger ? "主將棋串只剩 1 個生存空格。" : "點棋盤預覽，再按確認。"
    }
    func select(_ p: Point) {
        guard !isComputerTurn else { return }
        audio.play("selection")
        if mode == .skill && (state.heroClass(of: state.current) == .warrior ||
            (state.heroClass(of: state.current) == .mage && state.config.experimentalFriendlyRedeploy && mageOperation == .redeploy)) {
            if selected.count != 1 || selected[0] == p { selected = [p] } else { selected.append(p) }
        } else { selected = [p]; pushDirection = nil }
        if let preview { message = preview.success ? "預覽不扣資源；確認後才生效。" : Self.reason(preview.reason) }
        else { message = state.heroClass(of: state.current) == .mage ? (mageOperation == .redeploy ? "調度己兵：再選原棋群旁空點。" : "魔法之手：選擇推動方向。") : (state.config.bastionScope == .connectedGroup ? "築壘：再選原棋串旁另一個空點。" : "築壘：再選另一個相鄰空點。") }
    }
    func changeMode(_ value: Mode) { guard !isComputerTurn else { return }; mode = value; selected = []; pushDirection = nil; message = "選擇目標後再確認。" }
    func confirm() {
        guard !isComputerTurn, let action = selectedAction else { return }
        commit(action)
        scheduleComputerTurn()
    }
    private func commit(_ action: GameAction) {
        let before = state
        let o = session.apply(action)
        if o.success {
            if var record = activeRecord {
                record.steps.append(RecordStep(action: action, before: before, outcome: o,
                    difficulty: botDifficulty.rawValue, decision: before.current == computer ? botLastDecision : nil))
                activeRecord = record; saveRecord()
            }
            audio.updateState(o.state)
            presentAudio(before: before, action: action, outcome: o)
            playback = BoardPlayback(before: before, action: action, outcome: o)
            selected = []; pushDirection = nil
            if before.current != state.current { mode = .soldier }
            let actor = (state.current == .one ? "黑方" : "白方") + state.heroClass(of: state.current).title
            message = terminalMessage ?? (before.current != state.current ? "已換手，輪到" + actor + "，\(state.apRemaining) AP。" : actor + "還能行動 \(state.apRemaining) 次。")
        } else { message = Self.reason(o.reason) }
    }
    func undo() {
        guard canUndoHumanDecision else { return }
        cancelBotWork()
        var undone = false
        // Solo undo crosses the computer replies and returns to the last human decision.
        repeat {
            guard session.undo() else { break }
            undone = true
        } while computer == state.current
        if undone {
            audio.updateState(state)
            if var record = activeRecord {
                record.steps = Array(record.steps.prefix(session.log.count)); activeRecord = record; saveRecord()
            }
            playback = nil; selected = []; pushDirection = nil
            if computer != nil { mode = .soldier }
            message = "已復原；輪到\(state.current == .one ? "黑方" : "白方")\(state.heroClass(of: state.current).title)。"
        } else { scheduleComputerTurn() }
    }
    func endTurn() {
        guard !isComputerTurn else { return }
        commit(.endTurn)
        mode = .soldier
        scheduleComputerTurn()
    }
    /// Also called when leaving or backgrounding. Cancellation alone is not the commit guard.
    func cancelBotWork() {
        cancelAudioFeedback()
        botGeneration &+= 1
        botWorker?.cancel(); botDelivery?.cancel()
        if isBotActing {
            playback = nil
            if state.current != computer || state.status != .ongoing {
                botTurnsCompleted += 1
                message = terminalMessage ?? "電腦完成回合，輪到你。"
            } else { message = "電腦行動已暫停。" }
        }
        botWorker = nil; botDelivery = nil; isBotThinking = false
        isBotActing = false; botAction = nil; botMotionStartedAt = nil
    }
    func leaveMatch() { cancelBotWork(); saveRecord(); activeRecord = nil; r2Fixture = nil; recordRules = .original; mageOperation = .push; setMatchAudioActive(false); computer = nil }
    func startR2(_ fixture: R2PracticeFixture, rules: RecordRules) -> Bool {
        do {
            let initial = try GameSetup.fromDiagram(config:rules.config(size:7),diagram:fixture.diagram,
                classOne:fixture.heroClass,classTwo:.rogue,manaOne:4,manaTwo:4,ap:2,ply:30)
            leaveMatch(); size = 7; session = GameSession(initial); r2Fixture = fixture; r2Rules = rules
            playback = nil; selected = []; pushDirection = nil; mode = .skill
            message = "R2 \(rules.variant)：" + (fixture.focus.action.map { RecordedAction($0).label } ?? fixture.purpose)
            return true
        } catch { recordErrorMessage = "無法載入試驗局面。"; return false }
    }
    func setBotDifficulty(_ difficulty: BotDifficulty) {
        guard difficulty != botDifficulty else { return }
        cancelBotWork()
        botDifficulty = difficulty
        saveRecord()
        message = "電腦難度已改為\(difficulty == .easy ? "簡單" : "標準")。"
        scheduleComputerTurn()
    }
    private func waitForBotPresentationPhase(minimumDuration: Double = 0) async throws {
        #if DEBUG
        if botReviewPhases {
            let permit = botReviewPermit, generation = botGeneration
            while botReviewPermit == permit {
                try await Task.sleep(nanoseconds: 10_000_000)
                guard botGeneration == generation else { throw CancellationError() }
            }
            return
        }
        #endif
        try await Task.sleep(nanoseconds: max(botStepNanoseconds, UInt64(minimumDuration * 1_000_000_000)))
    }
    func scheduleComputerTurn() {
        guard isComputerTurn, !isBotThinking, !isBotActing else { return }
        let snapshot = state, generation = botGeneration, actor = state.current
        let delay = botDelayNanoseconds, deliverLate = deliverCancelledBotResult
        let difficulty = botDifficulty
        let planningStart = Date()
        isBotThinking = true; selected = []; pushDirection = nil
        message = "電腦思考中，你可以復原或重新開始。"
        let worker = Task.detached(priority: .userInitiated) { () -> BotTurnPlan? in
            if delay > 0 {
                // A non-cooperative DEBUG job deliberately returns late to test the commit guard.
                if deliverLate {
                    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                        DispatchQueue.global().asyncAfter(deadline: .now() + Double(delay) / 1_000_000_000) { continuation.resume() }
                    }
                } else { try? await Task.sleep(nanoseconds: delay) }
            }
            guard deliverLate || !Task.isCancelled else { return nil }
            return BotPlanner.planTurn(snapshot, difficulty: difficulty, cancelled: { !deliverLate && Task.isCancelled })
        }
        botWorker = worker
        botDelivery = Task { [weak self] in
            let plan = await worker.value
            guard let self else { return }
            guard !Task.isCancelled, self.botGeneration == generation,
                  self.state == snapshot, self.computer == actor, self.isComputerTurn else {
                self.botDiscardedDecisions += 1; return
            }
            self.botWorker = nil; self.isBotThinking = false
            guard let plan, !plan.actions.isEmpty else {
                self.botLastDecision = "電腦未產生計畫，安全結束回合。"
                self.commit(.endTurn); return
            }
            // Atomic validation before any visual/session commit, entirely through Domain.
            var expected = snapshot
            guard plan.actions.count <= snapshot.apRemaining + 1 else {
                self.botLastDecision = "拒絕超過回合長度的計畫。"; self.commit(.endTurn); return
            }
            for action in plan.actions {
                guard expected.current == actor, expected.status == .ongoing else {
                    self.botLastDecision = "拒絕跨越電腦回合的計畫。"; self.commit(.endTurn); return
                }
                let result = GameEngine.apply(expected, action)
                guard result.success else {
                    self.botLastDecision = "拒絕非法電腦計畫：\(result.reason)。"; self.commit(.endTurn); return
                }
                expected = result.state
            }
            guard expected.current != actor || expected.status != .ongoing else {
                self.botLastDecision = "拒絕不完整電腦回合。"; self.commit(.endTurn); return
            }
            self.botLastDecision = "難度：\(difficulty == .easy ? "簡單" : "標準")\n" + plan.actions.map(botActionDescription).joined(separator: " → ") + "\n"
                + plan.reasons.joined(separator: "\n")
                + "\n顯式結算 \(plan.stats.domainTransitions)，合法枚舉 \(plan.stats.legalEnumerations)。"
                + "\n背景規劃耗時 \(Int(Date().timeIntervalSince(planningStart) * 1000)) ms。"
            self.isBotActing = true
            self.botActionCount = plan.actions.count
            var executionState = snapshot
            for (index, action) in plan.actions.enumerated() {
                guard !Task.isCancelled, self.botGeneration == generation,
                      self.computer == actor, self.state == executionState else { return }
                self.botActionIndex = index + 1; self.botAction = action
                self.botMotionStartedAt = nil; self.playback = nil
                self.message = "電腦第 \(index + 1) 步：\(self.botActionLabel)"
                UIAccessibility.post(notification: .announcement, argument: self.message)
                do { try await self.waitForBotPresentationPhase() } catch { return }
                // Every visible step has its own generation/state check after the suspension.
                guard !Task.isCancelled, self.botGeneration == generation,
                      self.computer == actor, self.state == executionState else { return }
                self.commit(action)
                executionState = self.state
                self.botMotionStartedAt = Date()
                self.message = "電腦第 \(index + 1) 步：\(self.botActionLabel)"
                do { try await self.waitForBotPresentationPhase(minimumDuration: self.audioDuration) } catch { return }
            }
            guard !Task.isCancelled, self.botGeneration == generation,
                  self.computer == actor, self.state == executionState else { return }
            self.isBotActing = false; self.botAction = nil; self.botMotionStartedAt = nil
            self.botDelivery = nil
            self.botTurnsCompleted += 1
            self.mode = .soldier
            self.message = self.terminalMessage ?? "電腦完成回合，輪到你。"
            UIAccessibility.post(notification: .announcement, argument: self.message)
        }
    }
    var resultTitle: String? {
        switch state.status {
        case .ongoing: nil
        case .won: "\(state.winner == .one ? "黑方" : "白方")獲勝"
        case .drawn: "和局"
        }
    }
    var terminalMessage: String? {
        switch state.status {
        case .ongoing: nil
        case .won: "\(state.winner == .one ? "黑方" : "白方")獲勝！主將已被包圍。"
        case .drawn: "已達 \(state.config.maxPlies) 回合上限，對戰以和局結束。"
        }
    }
    #if DEBUG
    func loadBotMageMotionReview() {
        activeRecord = nil
        cancelBotWork(); computer = .two; size = 7
        session = GameSession(try! GameSetup.fromDiagram(config: .board(size: 7), diagram: """
        ...o...
        ..oXo..
        .Q.x...
        .......
        .......
        ...O...
        .......
        """, classOne: .warrior, classTwo: .mage, current: .two, manaOne: 4, manaTwo: 5, ap: 2))
        playback = nil; selected = []; mode = .soldier; scheduleComputerTurn()
    }
    func loadWinningTurn() {
        leaveMatch()
        size = 7; review = .normal
        session = GameSession(try! MotionExample.victory.initialState())
        playback = nil; selected = []; mode = .soldier
        message = "主將只剩一個生存空格：在中央落子檢查勝負回饋。"
    }
    func loadLastTurn() {
        leaveMatch()
        let initial = Self.scenario(size: size, review: .normal)
        session = GameSession(try! GameSetup.fromDiagram(config: initial.config, diagram: initial.board.diagram,
            classOne: initial.heroClass(of: .one), classTwo: initial.heroClass(of: .two),
            manaOne: initial.mana(of: .one), manaTwo: initial.mana(of: .two), ap: 1, ply: initial.config.maxPlies))
        playback = nil; selected = []; mode = .soldier; message = "最後一回合：結束後依既有規則判定和局。"
    }
    #endif
    func newMatch(classOne: HeroClass = .warrior, classTwo: HeroClass = .mage, computer: Player? = nil, rules: RecordRules = .original) {
        recordRules = rules; r2Fixture = nil
        cancelBotWork(); self.computer = computer; botTurnsCompleted = 0; botDiscardedDecisions = 0; botLastDecision = ""
        session = GameSession(try! GameSetup.newGame(config: recordRules.config(size: size), classOne: classOne, classTwo: classTwo))
        activeRecord = MatchRecord(size: size, one: classOne, two: classTwo, computer: computer, difficulty: botDifficulty.rawValue, rules: recordRules)
        saveRecord()
        audio.resetBattle(); audio.updateState(state)
        playback = nil; review = .normal
        selected = []; pushDirection = nil; mageOperation = .push; mode = .soldier
        message = computer == nil ? "本機雙人：黑方先手，首回合 1 次行動。" : "你執\(humanPlayer == .one ? "黑" : "白")、電腦執\(computer == .one ? "黑" : "白")；黑方首回合 1 次行動。"
    }
    var canCreateCandidateCopy: Bool {
        activeRecord != nil && recordRules != .redeployment && state.status == .ongoing && !isComputerTurn
    }
    @discardableResult func createCandidateCopy() -> Bool {
        guard canCreateCandidateCopy, let original = activeRecord else { return false }
        do {
            let candidate = try original.candidateCopy()
            // Validate and durably save the new identity before replacing the live session.
            try records.save(candidate)
            guard resume(candidate) else { return false }
            refreshRecords(); audio.resetBattle(); audio.updateState(state)
            mageOperation = .push
            message = "已建立候選技能副本；原局保留在存局與棋譜。"
            scheduleComputerTurn()
            return true
        } catch { recordErrorMessage = "候選副本無法驗證或儲存；原局仍保留。"; return false }
    }
    func changeMageOperation(_ operation: MageOperation) {
        guard !isComputerTurn else { return }
        mageOperation = operation; selected = []; pushDirection = nil
        message = operation == .redeploy ? "先選英雄射程內、相連棋群中的己方士兵。" : "選普通士兵，再選推動方向。"
    }
    #if DEBUG
    func loadSkillScreenshot(candidate: Bool, mage: Bool) {
        leaveMatch()
        let rules: RecordRules = candidate ? .redeployment : .original
        let diagram = mage ? "O..x...\n..xxx..\n.xxxxx.\nxxxHxxx\n.xxxxx.\n..xxx..\n...x..X"
            : "...x...\n..xOx..\n..xoox.\n...xoox\n..x.xo.\n..HXoox\n..xoQo."
        session = GameSession(try! GameSetup.fromDiagram(config: rules.config(size: 7), diagram: diagram,
            classOne: mage ? .mage : .warrior, classTwo: .warrior,
            current: mage ? .one : .two, manaOne: 4, manaTwo: 4, ap: 2, ply: mage ? 30 : 12))
        recordRules = rules; mode = .skill; mageOperation = mage ? .redeploy : .push
        selected = []; pushDirection = nil; size = 7
        message = "截圖重建／固定試驗，沒有原局 Ko 歷史。"
    }
    #endif
    static func scenario(size: Int, review: Review) -> GameState {
        var rows = Array(repeating: Array(repeating: Character("."), count: size), count: size)
        rows[1][size / 2] = "O"; rows[size - 2][size / 2] = "X"
        rows[3][3] = "H"; rows[2][2] = "o"; rows[2][3] = "o"; rows[3][2] = "x"; rows[4][2] = "x"
        rows[1][size / 2 + 1] = "Q"
        if review == .danger {
            let y = size - 2, x = size / 2
            rows[y - 1][x] = "o"; rows[y][x - 1] = "o"; rows[y][x + 1] = "o"
        }
        var config = RuleConfig.board(size: size); config.mageSkill = .seal
        return try! GameSetup.fromDiagram(config: config, diagram: rows.map { String($0) }.joined(separator: "\n"),
            classOne: .mage, classTwo: .rogue, manaOne: 4, manaTwo: 3, ap: 2)
    }
    func cancelSelection() { selected = []; pushDirection = nil; message = "已取消預覽，沒有扣除資源。" }
    func chooseDirection(_ direction: PushDirection) {
        guard !isComputerTurn else { return }
        pushDirection = direction
        if let preview { message = preview.success ? "預覽不扣資源；確認後才生效。" : Self.reason(preview.reason) }
    }
    var availableDirections: Set<PushDirection> {
        guard let p = selected.first else { return [] }
        return Set(PushDirection.allCases.filter { GameEngine.validate(state, .castMagicHand(p, $0)) == .none })
    }
    func startPractice(_ lesson: PracticeLesson) {
        leaveMatch()
        size = 7; session = GameSession(lesson.initialState)
        playback = nil; selected = []; pushDirection = nil
        mode = lesson == .capture ? .soldier : .skill; message = lesson.instruction
    }
    static func reason(_ r: IllegalReason) -> String {
        switch r {
        case .skillNotSelected: "這個法師技能未啟用。"
        case .invalidDirection: "請選擇上、右、下或左。"
        case .none: "合法"
        case .gameOver: "對戰已結束。"
        case .noActionPoints: "本回合沒有行動次數。"
        case .outOfBounds: "目標在棋盤外。"
        case .occupied: "這裡已有棋子。"
        case .sealed: "這個點本回合被封印。"
        case .suicide: "行動後己方棋串會沒有生存空格。"
        case .ko: "不能重複先前的盤面。"
        case .notEnoughMana: "能量不足。"
        case .noHeroClass: "請先選擇職業。"
        case .heroAlreadyOnBoard: "英雄已在棋盤上。"
        case .heroAlreadySummoned: "英雄已退場，本局不能重召。"
        case .notAdjacentToFriend: "英雄必須召喚在己方棋子旁。"
        case .wrongClass: "這不是目前職業的技能。"
        case .noHeroOnBoard: "先召喚英雄才能使用技能。"
        case .skillAlreadyUsed: "本回合已使用技能。"
        case .outOfRange: "超出英雄的施放範圍。"
        case .invalidTarget: "請選擇符合技能條件的目標。"
        case .duplicateTarget: "築壘需要兩個不同的空點。"
        }
    }
}
