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
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showDetails = false
    @State private var showGrid = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing:8) {
                    stages
                    GeometryReader { board in
                        let edge = max(0,min(420,board.size.width,board.size.height))
                        if let assets=match.assets {
                            ExpansionBoard(store:match,assets:assets,time:2,reduced:true,
                                           identityPrefix:"forecast-cell",planning:planner)
                                .frame(width:edge,height:edge)
                                .position(x:board.size.width/2,y:board.size.height/2)
                                .accessibilityElement(children:.contain)
                                .accessibilityIdentifier("forecastBoard")
                        } else {
                            Text("棋盤素材尚未載入，正式對局保持不變。").foregroundStyle(.red)
                        }
                    }
                    Text(resources)
                        .font(.caption).foregroundStyle(GameChrome.cream)
                        .frame(maxWidth:.infinity,alignment:.leading)
                        .accessibilityIdentifier("forecastResources")
                    controls
                        .frame(height:min(typeSize.isAccessibilitySize ? 308 : 236,
                                          max(208,geometry.size.height*0.56)),alignment:.top)
                }
                .padding(.horizontal,12).padding(.vertical,8)
            }
            .background(GameBackdrop())
            .foregroundStyle(GameChrome.cream)
            .navigationTitle("兩手試算")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement:.topBarLeading) {
                    HStack(spacing:0) { Button { showDetails = true } label: {
                        Label("詳細",systemImage:"info.circle").frame(minWidth:44,minHeight:44)
                    }.accessibilityIdentifier("forecastDetails")
                        Button { showGrid = true } label: {
                            Image(systemName:"square.grid.3x3").frame(width:44,height:44)
                        }.disabled(!planner.canEdit).accessibilityLabel("以大按鍵選擇試算格點")
                            .accessibilityIdentifier("forecastGrid")
                    }
                }
                ToolbarItem(placement:.confirmationAction) {
                    Button("關閉") { dismiss() }.frame(minWidth:44,minHeight:44)
                        .accessibilityLabel("關閉（不落子）").accessibilityIdentifier("forecastClose")
                }
            }
            .sheet(isPresented:$showDetails) { details }
            .sheet(isPresented:$showGrid) { grid }
            .preferredColorScheme(.dark)
        }
    }
    private var resources: String {
        let state=planner.stageState
        let ap = state.status != .ongoing ? "已終局" : state.current == planner.origin.current ? "\(state.apRemaining) AP" : "己方已交棒"
        return "\(ap) · 己方能量 \(state.mana(of:planner.origin.current))"
    }
    private var stages: some View {
        HStack(spacing:6) {
            ForEach(TwoActionPlanningController.Stage.allCases) { stage in
                Button { planner.show(stage) } label: {
                    Text(stage.title).font(.system(size:13,weight:.semibold))
                        .frame(maxWidth:.infinity,minHeight:44)
                }
                .background(planner.stage == stage ? GameChrome.gold.opacity(0.28) : Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:10))
                .overlay(RoundedRectangle(cornerRadius:10).stroke(planner.stage == stage ? GameChrome.gold : Color.clear,lineWidth:1))
                .disabled(stage == .second && planner.forecast.secondBase == nil || stage == .result && planner.forecast.firstStep == nil)
                .accessibilityIdentifier("forecastStage\(stage.rawValue)")
            }
        }
    }
    private var controls: some View {
        VStack(spacing:6) {
            if planner.canEdit {
                modes
                if planner.needsDirection {
                    HStack(spacing:4) {
                        ForEach(PushDirection.allCases,id:\.self) { direction in
                            Button(direction.rawValue) { planner.push(direction) }
                                .frame(maxWidth:.infinity,minHeight:44)
                                .accessibilityIdentifier("forecastDirection\(direction.rawValue)")
                        }
                    }.frame(minHeight:44)
                } else { HStack(spacing:6) {
                    Text(planner.pending.map(TwoActionPlanningController.title) ??
                         (planner.selected.isEmpty ? "選擇棋盤目標，只加入試算" : "已選 \(planner.selected.count) 點，繼續選目標"))
                        .font(.caption).lineLimit(2).frame(maxWidth:.infinity,alignment:.leading)
                    Button { planner.clearSelection() } label: {
                        Image(systemName:"xmark").frame(width:44,height:44)
                    }.accessibilityLabel("取消選點").accessibilityIdentifier("forecastCancelSelection")
                }.frame(minHeight:44) }
            } else {
                Text("試算完成 · 正式棋局尚未改動")
                    .font(.subheadline.bold()).frame(maxWidth:.infinity,alignment:.leading)
            }
            HStack(spacing:6) {
                if let step=planner.forecast.firstStep { compact(step,number:1) }
                if let step=planner.forecast.secondStep { compact(step,number:2) }
                if planner.forecast.firstStep == nil {
                    Text("可試不同走法；這裡不預測敵方反擊。")
                        .font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.leading)
                }
            }.frame(height:typeSize.isAccessibilitySize ? 72 : 46)
            if planner.canEdit {
                HStack(spacing:6) {
                    Button { planner.addPending() } label: {
                        Text(planner.stage == .first ? "加入第一手試算" : "加入第二手試算")
                            .font(.callout.bold()).frame(maxWidth:.infinity,minHeight:44)
                    }
                        .buttonStyle(GameButtonStyle(kind:.primary))
                        .disabled(planner.preview?.success != true)
                        .accessibilityIdentifier("forecastAddStep")
                    if planner.forecast.first != nil {
                        Button { loadFirst() } label: {
                            Image(systemName:"arrow.uturn.backward.circle").frame(width:44,height:44)
                        }.buttonStyle(GameButtonStyle())
                            .accessibilityLabel("先帶入第一手，仍需按確認")
                            .disabled(!canLoad).accessibilityIdentifier("forecastLoadFirst")
                    }
                }
                Text(planner.preview.map { $0.success ? "合法試算 · 尚未提交" : "目前不合法：\($0.reason.rawValue)" } ?? "加入試算不會扣正式資源")
                        .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                        .accessibilityIdentifier("forecastLegal")
            } else {
                Spacer(minLength:0)
                Button { loadFirst() } label: {
                    Text("帶入第一手").font(.callout.bold()).frame(maxWidth:.infinity,minHeight:44)
                }.buttonStyle(GameButtonStyle(kind:.primary))
                    .accessibilityLabel("帶入第一手，仍需按確認")
                    .disabled(!canLoad).accessibilityIdentifier("forecastLoadFirst")
                Text("回到對局後，兩手仍各自按確認。")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(10)
        .background(Color(red:0.10,green:0.16,blue:0.17),in:RoundedRectangle(cornerRadius:14))
        .overlay(RoundedRectangle(cornerRadius:14).stroke(GameChrome.gold.opacity(0.4),lineWidth:1))
    }
    private var canLoad: Bool { planner.forecast.matches(match.state) && !match.controlsLocked }
    private func loadFirst() {
        if onUseFirst(planner.forecast) { dismiss() }
        else { planner.message="正式棋局已變化，請關閉後重新試算。";showDetails=true }
    }
    private var modes: some View {
        ScrollView(.horizontal,showsIndicators:false) {
            HStack(spacing:6) {
                ForEach(planner.modes) { mode in
                    Button(mode.rawValue) { planner.changeMode(mode) }
                        .font(.system(size:13,weight:.semibold)).frame(minWidth:58,minHeight:44)
                        .background(planner.mode == mode ? GameChrome.gold.opacity(0.28) : Color.white.opacity(0.07),in:RoundedRectangle(cornerRadius:8))
                        .accessibilityIdentifier("forecastMode\(mode.id)")
                }
                if planner.mode == .loot {
                    Button(planner.ability == .stickyBounce ? "黏彈" : "影步") {
                        planner.ability = planner.ability == .stickyBounce ? .shadowStep : .stickyBounce;planner.clearSelection()
                    }.frame(minHeight:44)
                }
            }
        }.frame(height:44)
    }
    private func fullSummary(_ step:TwoActionForecast.Step,number:Int) -> String {
        let ap=step.after.status != .ongoing ? "已終局" : step.apAfter.map(String.init) ?? "交給對手"
        return "第 \(number) 手 · \(TwoActionPlanningController.title(step.action))。AP \(step.apBefore) → \(ap) · 能量 \(step.manaBefore) → \(step.manaAfter)。提敵兵 \(step.enemySoldiersCaptured) · 犧牲己兵 \(step.ownSoldiersSacrificed) · 己主帥氣 \(step.myCommanderLibertiesBefore) → \(step.myCommanderLibertiesAfter) · 敵主帥氣 \(step.enemyCommanderLibertiesBefore) → \(step.enemyCommanderLibertiesAfter)"
    }
    private func compact(_ step:TwoActionForecast.Step,number:Int) -> some View {
        VStack(alignment:.leading,spacing:2) {
            Text("\(number). \(TwoActionPlanningController.title(step.action))").font(.caption.bold()).lineLimit(1)
            Text("提敵兵 \(step.enemySoldiersCaptured) · 能量 \(step.manaBefore)→\(step.manaAfter)").font(.caption2).lineLimit(1)
        }.frame(maxWidth:.infinity,alignment:.leading)
            .accessibilityElement(children:.ignore).accessibilityLabel(fullSummary(step,number:number))
            .accessibilityIdentifier("forecastSummary\(number)")
    }
    private var details: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment:.leading,spacing:16) {
                    Text("正式棋局與資源尚未改動。預覽、加入試算、正式確認是不同步驟。")
                    if let first=planner.forecast.firstStep { Text(fullSummary(first,number:1)) }
                    if let second=planner.forecast.secondStep { Text(fullSummary(second,number:2)) }
                    Text(planner.message)
                    Text("這些是本回合的確定結果；氣數增加不保證下回合安全，也不預測敵方下一手。")
                    Text("帶入只會選好第一手，不會扣資源或自動執行第二手；兩手仍須回對局逐手確認。")
                    if planner.canEdit {
                        Button("清除此手試算") { planner.clearCurrent();showDetails=false }.frame(minHeight:44)
                    }
                }.padding()
            }.background(GameBackdrop()).navigationTitle("試算詳細")
                .toolbar { ToolbarItem(placement:.confirmationAction) {
                    Button("完成") { showDetails=false }.frame(minWidth:44,minHeight:44).accessibilityIdentifier("forecastDetailsDone")
                }}
        }.preferredColorScheme(.dark)
    }
    private var grid: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns:Array(repeating:GridItem(.flexible()),count:3),spacing:8) {
                    ForEach(planner.legalTargets.sorted { $0.y == $1.y ? $0.x < $1.x : $0.y < $1.y },id:\.self) { point in
                        Button {
                            planner.select(point)
                            if planner.pending != nil || planner.needsDirection { showGrid=false }
                        } label: {
                            Text(TwoActionPlanningController.coordinate(point)).frame(maxWidth:.infinity,minHeight:44)
                        }.buttonStyle(.bordered)
                            .accessibilityIdentifier("forecast-grid-\(point.x)-\(point.y)")
                    }
                }.padding()
            }.navigationTitle("試算格點")
                .toolbar { ToolbarItem(placement:.confirmationAction) {
                    Button("完成") { showGrid=false }.frame(minWidth:44,minHeight:44)
                        .accessibilityIdentifier("forecastGridDone")
                }}
        }.preferredColorScheme(.dark)
    }
}
#endif
