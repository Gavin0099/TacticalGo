#if DEBUG || TACTICALGO_V11
import SwiftUI
import TacticalGoCore
import TacticalGoContent

/// Optional, non-persistent UI input for a Core-verified two-action forecast.
/// This controller does not own a GameSession, save slot, timer, Bot or audio.
@MainActor @Observable final class TwoActionPlanningController: Identifiable {
    enum Stage: Int, CaseIterable, Identifiable { case first, second, result
        var id: Int { rawValue }
        var title: String { switch self { case .first: "第 1 手"; case .second: "第 2 手"; case .result: "完成棋形" } }
    }
    enum Mode: String, CaseIterable, Identifiable {
        case soldier = "落兵", summon = "召喚", skill = "技能", advanced = "第二技能", loot = "戰利"
        var id: String { rawValue }
        var hint: TacticalHintMode {
            switch self { case .soldier: .soldier; case .summon: .summon; case .skill: .skill
            case .advanced: .advanced; case .loot: .loot }
        }
    }
    let id = UUID()
    var forecast: TwoActionForecast
    var stage: Stage = .first
    var mode: Mode = .soldier
    var ability: MonsterAbility = .stickyBounce
    var selected: [Point] = []
    var pending: GameAction?
    var message = "請先選擇第一手，試算不會套用到正式對局。"

    init(origin: GameState) { forecast = TwoActionForecast(origin: origin) }
    var origin: GameState { forecast.origin }
    var stageState: GameState {
        switch stage {
        case .first: origin
        case .second: forecast.secondBase ?? forecast.projectedState
        case .result: forecast.projectedState
        }
    }
    var canEdit: Bool {
        stage != .result && (stage == .first || forecast.secondBase != nil)
    }
    var preview: ActionOutcome? {
        guard canEdit,let pending else { return nil }
        return GameEngine.apply(stageState,pending)
    }
    var legalTargets: Set<Point> {
        guard canEdit else { return [] }
        if mode == .soldier && !stageState.board.monsters.isEmpty {
            // A monster requires a dedicated hunt action; tapping it is legal only
            // when the current Core validates its capture.
            let monsterTargets = Set(stageState.board.monsters.filter {
                GameEngine.apply(stageState,.huntMonster($0)).success
            })
            return TacticalHints.targets(stageState,mode:.soldier,selected:selected).union(monsterTargets)
        }
        if mode == .skill && !stageState.config.experimentalFriendlyRedeploy &&
           stageState.heroClass(of:stageState.current) == .mage &&
           stageState.config.mageSkill == .seal {
            return Set(GameEngine.legalActions(stageState).compactMap {
                if case .castSeal(let p) = $0 { return p }
                return nil
            })
        }
        return TacticalHints.targets(stageState,mode:mode.hint,selected:selected,ability:ability)
    }
    var modes: [Mode] {
        var available:[Mode] = [.soldier,.summon,.skill]
        if origin.config.expansionSkills { available.append(.advanced) }
        if !stageState.lootInventory(of:origin.current).isEmpty { available.append(.loot) }
        return available
    }
    func show(_ next:Stage) {
        if next == .second && forecast.secondBase == nil { return }
        if next == .result && forecast.firstStep == nil { return }
        stage = next;selected = [];pending = nil;mode = .soldier
        message = next == .result ? "已試算的棋形；不是敵方下一手的預測。" : "選擇格點，按「加入試算」，不會修改正式對局。"
    }
    func changeMode(_ next:Mode) {
        mode=next;selected=[];pending=nil;message="請選擇合法目標。"
    }
    func select(_ p:Point) {
        guard canEdit else { return }
        guard legalTargets.contains(p) else {
            message = "這格不是當前試算的合法目標。";return
        }
        if stageState.board.monsters.contains(p) {
            selected=[p];pending = .huntMonster(p);return
        }
        let hero=stageState.heroClass(of:stageState.current)
        let count:Int
        switch mode {
        case .soldier: selected=[p];pending = .placeSoldier(p);return
        case .summon: selected=[p];pending = .summonHero(p);return
        case .skill:
            if hero == .mage && !stageState.config.experimentalFriendlyRedeploy &&
               stageState.config.mageSkill == .seal {
                selected=[p];pending = .castSeal(p);return
            }
            count = hero == .warrior || (hero == .mage && stageState.config.experimentalFriendlyRedeploy) ? 2 : 1
        case .advanced: count = hero == .warrior || hero == .mage ? 4 : 2
        case .loot: count = ability == .stickyBounce ? 2 : 1
        }
        if selected.count >= count { selected=[] }
        selected.append(p);pending=nil
        guard selected.count == count else { return }
        switch mode {
        case .skill:
            switch hero {
            case .warrior: pending = .castBastion(selected[0],selected[1])
            case .mage:
                if stageState.config.experimentalFriendlyRedeploy {
                    pending = .castFriendlyRedeploy(selected[0],selected[1])
                } else { message = "選擇推動方向後才能加入試算。" }
            case .rogue: pending = .castSwap(selected[0])
            case .priest: pending = .castOffering(selected[0])
            case .none: break
            }
        case .advanced:
            switch hero {
            case .warrior: pending = .castReformation(
                SoldierShift(selected[0],selected[1]),SoldierShift(selected[2],selected[3]))
            case .mage: pending = .castDoublePull(
                SoldierShift(selected[0],selected[1]),SoldierShift(selected[2],selected[3]))
            case .rogue: pending = .castChainSwap(first:selected[0],second:selected[1])
            case .priest: pending = .castSanctum(sacrifice:selected[0],destination:selected[1])
            case .none: break
            }
        case .loot:
            pending = ability == .stickyBounce ?
                .useStickyBounce(anchor:selected[0],target:selected[1]) : .useShadowStep(selected[0])
        default: break
        }
        if preview?.success != true { message = "目標未成立；可取消重新選擇。" }
    }
    var needsDirection: Bool {
        canEdit && mode == .skill && stageState.heroClass(of:stageState.current) == .mage &&
        !stageState.config.experimentalFriendlyRedeploy && stageState.config.mageSkill == .magicHand &&
        selected.count == 1
    }
    func push(_ direction:PushDirection) {
        guard needsDirection,let point=selected.first else { return }
        pending = .castMagicHand(point,direction)
        message = preview?.success == true ? "這個方向合法，可加入試算。" : "此方向不合法；請重選。"
    }
    func clearSelection() { selected=[];pending=nil;message="已取消這次選點，先前試算仍保留。" }
    func clearCurrent() {
        if stage == .first { _ = forecast.chooseFirst(nil) }
        if stage == .second { _ = forecast.chooseSecond(nil) }
        selected=[];pending=nil
        if stage == .second && forecast.secondBase == nil { stage = .first }
        message="已清除此手試算，正式對局未改動。"
    }
    func addPending() {
        guard canEdit,let pending,preview?.success == true else { return }
        let accepted = stage == .first ? forecast.chooseFirst(pending) : forecast.chooseSecond(pending)
        guard accepted else { message="這一步目前無法執行；請重新選擇。";return }
        selected=[];self.pending=nil;mode = .soldier
        if stage == .first && forecast.secondBase != nil {
            stage = .second
            message = "第一手只是試算；請繼續選第二手。"
        } else {
            stage = .result
            message = "\(forecast.hasTwoActions ? "兩手" : "這一手")試算已完成，正式棋局與資源尚未改動。"
        }
    }
    static func coordinate(_ p:Point) -> String { "\(String(UnicodeScalar(65+p.x)!))\(p.y+1)" }
    static func title(_ action:GameAction) -> String {
        func c(_ p:Point) -> String { coordinate(p) }
        switch action {
        case .placeSoldier(let p): return "落兵 \(c(p))"
        case .summonHero(let p): return "召喚 \(c(p))"
        case .castBastion(let a,let b): return "築壘 \(c(a))、\(c(b))"
        case .castSwap(let p): return "換位 \(c(p))"
        case .castChainSwap(let a,let b): return "連鎖換位 \(c(a)) → \(c(b))"
        case .castOffering(let p): return "奉獻 \(c(p))"
        case .castSanctum(let a,let b): return "聖所 \(c(a)) → \(c(b))"
        case .castFriendlyRedeploy(let a,let b): return "調度 \(c(a)) → \(c(b))"
        case .castMagicHand(let p,let direction): return "魔法之手 \(c(p)) 向 \(direction.rawValue)"
        case .castSeal(let p): return "封印 \(c(p))"
        case .castReformation(let a,let b): return "戰線重整 \(c(a.from)) → \(c(a.to))、\(c(b.from)) → \(c(b.to))"
        case .castDoublePull(let a,let b): return "雙重牽引 \(c(a.from)) → \(c(a.to))、\(c(b.from)) → \(c(b.to))"
        case .useStickyBounce(let a,let b): return "黏彈 \(c(a)) → \(c(b))"
        case .useShadowStep(let p): return "影步 \(c(p))"
        case .huntMonster(let p): return "討伐 \(c(p))"
        case .castSanctuary(let a,let b): return "歷史聖所 \(c(a)) → \(c(b))"
        case .endTurn: return "結束回合"
        }
    }
    static func liveInput(_ action:GameAction) -> (mode:ExpansionLabStore.Mode,points:[Point])? {
        switch action {
        case .placeSoldier(let p): return (.soldier,[p])
        case .summonHero(let p): return (.summon,[p])
        case .castBastion(let a,let b): return (.skill,[a,b])
        case .castMagicHand(let p,_),.castSwap(let p),.castSeal(let p),.castOffering(let p): return (.skill,[p])
        case .castFriendlyRedeploy(let a,let b): return (.skill,[a,b])
        case .castSanctum(let a,let b),.castChainSwap(let a,let b): return (.advanced,[a,b])
        case .castDoublePull(let a,let b),.castReformation(let a,let b):
            return (.advanced,[a.from,a.to,b.from,b.to])
        case .useStickyBounce(let a,let b): return (.loot,[a,b])
        case .useShadowStep(let p): return (.loot,[p])
        case .huntMonster(let p): return (.soldier,[p])
        default: return nil
        }
    }
}

struct TwoActionPlanningSheet: View {
    @Bindable var planner: TwoActionPlanningController
    let match: ExpansionLabStore
    let onUseFirst: (TwoActionForecast) -> Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReducedMotion

    @State private var showsDetails = false

    /// The board and essential controls are outside the scroll region.
    /// Only explanations and optional detail rows scroll on smaller devices.
    var body: some View {
        NavigationStack {
            GeometryReader { screen in
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        ForEach(TwoActionPlanningController.Stage.allCases) { stage in
                            Button(stage.title) { planner.show(stage) }
                                .font(.system(size: 12, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(planner.stage == stage ? Color.orange.opacity(0.3) : Color.gray.opacity(0.15),
                                            in: RoundedRectangle(cornerRadius: 8))
                                .disabled(stage == .second && planner.forecast.secondBase == nil ||
                                          stage == .result && planner.forecast.firstStep == nil)
                                .accessibilityIdentifier("forecastStage\(stage.rawValue)")
                        }
                    }

                    if let assets = match.assets {
                        ExpansionBoard(store: match, assets: assets, time: 2, reduced: true,
                                       identityPrefix: "forecast-cell", planning: planner)
                            .aspectRatio(1, contentMode: .fit)
                            .frame(width: min(screen.size.width - 24, min(screen.size.height * 0.42, 420)))
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("forecastBoard")
                    } else {
                        Text("棋盤素材尚未載入，正式對局保持不變。").foregroundStyle(.red)
                    }

                    Text(forecastStatus)
                        .font(.caption).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("forecastResources")

                    if planner.canEdit { modeBar }

                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if planner.forecast.firstStep == nil {
                                Text("試算不會落子或扣資源，也不預測對手。")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let a = planner.forecast.firstStep { summary(a, number: 1) }
                            if let b = planner.forecast.secondStep { summary(b, number: 2) }
                            if planner.forecast.firstStep != nil {
                                Button(showsDetails ? "收合詳細數字" : "查看詳細數字") {
                                    showsDetails.toggle()
                                }
                                .font(.caption).frame(minHeight: 44)
                                .accessibilityIdentifier("forecastDetailsToggle")
                            }
                            Text(planner.message).font(.caption).foregroundStyle(.secondary)
                            if planner.forecast.first != nil {
                                Text("帶入只會選好第一手；每手仍須在正式對局按「確認」。")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                    }
                    .accessibilityIdentifier("forecastScroll")

                    commandDock
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            .navigationTitle("兩手試算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("關閉（不落子）") { dismiss() }
                        .accessibilityIdentifier("forecastClose")
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var forecastStatus: String {
        let state = planner.stageState
        let turn: String
        if state.status != .ongoing {
            turn = "已終局"
        } else if state.current == planner.origin.current {
            turn = "\(state.apRemaining) AP"
        } else {
            turn = "己方已交棒"
        }
        return "檢視：\(planner.stage.title) · \(turn) · 己方能量 \(state.mana(of: planner.origin.current))"
    }

    private var modeBar: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(planner.modes) { mode in
                        Button(mode.rawValue) { planner.changeMode(mode) }
                            .font(.system(size: 13, weight: .semibold))
                            .frame(minWidth: 58, minHeight: 44)
                            .background(planner.mode == mode ? Color.orange.opacity(0.3) : Color.gray.opacity(0.15),
                                        in: RoundedRectangle(cornerRadius: 8))
                            .accessibilityIdentifier("forecastMode\(mode.id)")
                    }
                    if planner.mode == .loot {
                        Button(planner.ability == .stickyBounce ? "黏彈" : "影步") {
                            planner.ability = planner.ability == .stickyBounce ? .shadowStep : .stickyBounce
                            planner.clearSelection()
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            if planner.needsDirection {
                HStack {
                    ForEach(PushDirection.allCases, id: \.self) { direction in
                        Button(direction.rawValue) { planner.push(direction) }
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .accessibilityIdentifier("forecastDirection\(direction.rawValue)")
                    }
                }
            }
        }
    }

    private var commandDock: some View {
        VStack(spacing: 6) {
            if planner.canEdit {
                HStack(spacing: 6) {
                    Text(planner.pending.map(TwoActionPlanningController.title) ?? "選擇棋盤綠圈")
                        .font(.caption).lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button("取消選點") { planner.clearSelection() }
                        .font(.caption).frame(minHeight: 44)
                }
                if let preview = planner.preview {
                    Text(preview.success ? "合法試算 · 尚未提交" : "目前不合法：\(preview.reason.rawValue)")
                        .font(.caption).foregroundStyle(preview.success ? Color.green : Color.orange)
                        .accessibilityIdentifier("forecastLegal")
                }
                Button("加入\(planner.stage == .first ? "第一手" : "第二手")試算") {
                    planner.addPending()
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .buttonStyle(.borderedProminent)
                .disabled(planner.preview?.success != true)
                .accessibilityIdentifier("forecastAddStep")
            }
            if planner.forecast.first != nil {
                HStack(spacing: 8) {
                    if planner.stage != .result {
                        Button("清除此手") { planner.clearCurrent() }
                            .font(.caption).frame(minHeight: 44)
                    }
                    Button("帶入第一手，仍需按確認") {
                        if onUseFirst(planner.forecast) {
                            dismiss()
                        } else {
                            planner.message = "正式對局已變化或正在演出；本次試算未套用，請關閉後重新開啟。"
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .disabled(!planner.forecast.matches(match.state) || match.controlsLocked)
                    .accessibilityIdentifier("forecastLoadFirst")
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityIdentifier("forecastCommandDock")
    }

    private func summary(_ step: TwoActionForecast.Step, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("第 \(number) 手 · \(TwoActionPlanningController.title(step.action))")
                .font(.subheadline).bold()
            Text("提敵兵 \(step.enemySoldiersCaptured) · 能量 \(step.manaBefore) → \(step.manaAfter) · AP \(step.apBefore) → \(step.after.status != .ongoing ? "已終局" : step.apAfter.map(String.init) ?? "交給對手")")
            if showsDetails {
                Text("犧牲己兵 \(step.ownSoldiersSacrificed) · 己主帥氣 \(step.myCommanderLibertiesBefore) → \(step.myCommanderLibertiesAfter) · 敵主帥氣 \(step.enemyCommanderLibertiesBefore) → \(step.enemyCommanderLibertiesAfter)")
                Text("以上是本回合試算，不保證對方下一手或下回合的安全。")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("forecastSummary\(number)")
    }

}
#endif
