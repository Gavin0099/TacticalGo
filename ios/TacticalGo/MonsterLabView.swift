#if DEBUG || TACTICALGO_V11
import SwiftUI
import UIKit
import TacticalGoCore

/// Loose candidate PNG resources are loaded explicitly, independently of the shipping asset catalog.
@MainActor private enum MonsterLabArt {
    static let images: [MonsterKind: UIImage] = {
        var images: [MonsterKind: UIImage] = [:]
        for kind in MonsterKind.allCases {
            let name = kind == .slime ? "slime-token-v02" : "shadow-wolf-preview-v02"
            if let url = Bundle.main.url(forResource: name, withExtension: "png"),
               let image = UIImage(contentsOfFile: url.path) { images[kind] = image }
        }
        return images
    }()
}

/// Independent research session: no normal records, bot, audio or release menu wiring.
@MainActor @Observable final class MonsterLabStore {
    enum Mode: String, CaseIterable { case soldier = "落子", summon = "召喚", skill = "英雄技能", loot = "戰利能力" }
    var cost = 1
    var awardsLoot = true
    var monsterKind: MonsterKind = .slime
    var offset = false
    var dual = false
    var selectedAbility: MonsterAbility = .stickyBounce
    var one: HeroClass = .warrior
    var two: HeroClass = .mage
    var mode: Mode = .soldier
    var selected: [Point] = []
    var pending: GameAction?
    var message = "先選格點，再確認。"
    var session: GameSession?
    var state: GameState { session!.state }
    var preview: ActionOutcome? { pending.map { GameEngine.apply(state, $0) } }
    var monsterPoint: Point { Point(offset ? 3 : 4, 4) }
    var monsterName: String { dual ? "史萊姆＋暗影狼" : name(monsterKind) }
    func name(_ kind: MonsterKind) -> String { kind == .slime ? "史萊姆" : "暗影狼" }
    func name(at point: Point) -> String { name(state.config.monsterBattlefield!.kind(at: point)!) }
    var spawns: [MonsterSpawn] { dual ? [MonsterSpawn(.slime, at: Point(2,4)), MonsterSpawn(.shadowWolf, at: Point(6,4))] : [MonsterSpawn(monsterKind, at: monsterPoint)] }
    init() { restart() }
    func restart() {
        var c = RuleConfig.board(size: 9)
        c.monsterBattlefield = MonsterBattlefield(monsters: spawns, huntAPCost: cost, awardsLoot: awardsLoot)
        do { session = GameSession(try GameSetup.newGame(config: c, classOne: one, classTwo: two)) }
        catch { message = "開局失敗：\(error)"; return }
        cancel(); mode = .soldier; selectedAbility = monsterKind == .slime ? .stickyBounce : .shadowStep
        message = "新對局：\(monsterName)占位；討伐 \(cost) AP。\(awardsLoot ? "有一次性戰利能力。" : "無戰利能力對照。")"
    }
    func loadReachableComparison() {
        restart()
        let actions: [GameAction] = dual
            ? [.placeSoldier(Point(1,4)), .placeSoldier(Point(0,0)), .endTurn,
               .placeSoldier(Point(3,4)), .placeSoldier(Point(5,5)), .endTurn,
               .summonHero(Point(5,4)), .placeSoldier(Point(7,4)), .endTurn]
            : monsterKind == .slime
            ? [.placeSoldier(Point(monsterPoint.x - 1, 4)), .placeSoldier(Point(0, 0)), .endTurn, .placeSoldier(Point(monsterPoint.x + 1, 4))]
            : [.placeSoldier(Point(monsterPoint.x - 1, 5)), .placeSoldier(Point(0, 0)), .endTurn, .summonHero(Point(monsterPoint.x - 1, 4)), .endTurn, .endTurn, .placeSoldier(Point(monsterPoint.x + 1, 4))]
        for action in actions {
            if dual && action == .endTurn && state.awaitingFreeHunt {
                guard session!.apply(.endTurn).success else { message = "略過討伐失敗。"; return }
            }
            let outcome = session!.apply(action)
            guard outcome.success else { message = "比較局面重播失敗：\(outcome.reason.rawValue)"; return }
        }
        cancel(); message = "已重播 \(session!.log.count) 個合法行動。\(dual ? "黑方可分別討伐兩隻魔物。" : "黑方剩 1 AP，可比較討伐與直接落子。")"
    }
    func loadLootComparison() {
        guard awardsLoot else { return }
        loadReachableComparison()
        var actions: [GameAction] = dual ? [.huntMonster(Point(2,4)), .huntMonster(Point(6,4))] : [.huntMonster(monsterPoint)]
        if cost == 0 { actions.append(.endTurn) }
        actions.append(.endTurn)
        if dual { actions += [.placeSoldier(Point(1,5)), .endTurn, .endTurn] }
        else if monsterKind == .slime { actions.append(.placeSoldier(monsterPoint)) }
        for action in actions {
            guard session!.apply(action).success else { message = "能力局面重播失敗。"; return }
        }
        cancel(); mode = .loot; selectedAbility = dual || monsterKind == .slime ? .stickyBounce : .shadowStep
        message = "已從合法開局討伐並等到下一己方回合。\(dual ? "兩份能力分別保留；選黏彈或影步再點棋盤。" : monsterKind == .slime ? "先點中央黑子作支點，再點右側黑兵。" : "點英雄同列的空點，最多移動兩格。")"
    }
    func cancel() { selected = []; pending = nil }
    func select(_ p: Point) {
        guard state.status == .ongoing else { return }
        if state.board.monsters.contains(p) { selected = [p]; pending = .huntMonster(p); return }
        switch mode {
        case .loot:
            if selectedAbility == .stickyBounce {
                if selected.count == 1, selected[0] != p { selected.append(p); pending = .useStickyBounce(anchor: selected[0], target: p) }
                else { selected = [p]; pending = nil }
            } else { selected = [p]; pending = .useShadowStep(p) }
        case .soldier: selected = [p]; pending = .placeSoldier(p)
        case .summon: selected = [p]; pending = .summonHero(p)
        case .skill:
            switch state.heroClass(of: state.current) {
            case .warrior:
                if selected.count == 1, selected[0] != p { selected.append(p); pending = .castBastion(selected[0], p) }
                else { selected = [p]; pending = nil }
            case .mage: selected = [p]; pending = nil
            case .rogue: selected = [p]; pending = .castSwap(p)
            case .priest, .none: selected = [p]; pending = nil
            }
        }
    }
    func push(_ direction: PushDirection) {
        guard let target = selected.first else { return }
        pending = .castMagicHand(target, direction)
    }
    func confirm() {
        guard let action = pending, preview?.success == true else { return }
        let outcome = session!.apply(action)
        guard outcome.success else { message = explanation(outcome.reason); return }
        if case .huntMonster(let p) = action { message = "已討伐\(name(at: p))，原位置成為空點。\(awardsLoot ? "能力將在下一己方回合解鎖。" : "無獎勵對照。")" }
        else if case .useStickyBounce = action { message = "已使用一次黏彈。" }
        else if case .useShadowStep = action { message = "已使用一次影步。" }
        else { message = "行動已確認。" }
        cancel()
    }
    func endTurn() {
        let skipped = state.awaitingFreeHunt
        let outcome = session!.apply(.endTurn)
        if outcome.success { cancel(); message = skipped ? "已略過免費討伐，交給對手。" : "已結束回合。" }
    }
    func undo() { if session!.undo() { cancel(); message = "已完整復原盤面、怪物、行動與歷史。" } }
    func explanation(_ reason: IllegalReason) -> String {
        switch reason {
        case .insufficientMonsterControl: "需要正鄰友軍至少 2 格，且多於敵方；2：2 不能討伐。"
        case .monsterModeDisabled: "這個對局未啟用魔物戰場。"
        case .noHeroOnBoard: "暗影狼討伐需要正鄰己方英雄；影步也需要己方英雄在場。"
        default: GameStore.reason(reason)
        }
    }
    var previewText: String {
        guard let preview else {
            if mode == .loot { return selectedAbility == .stickyBounce ? "黏彈：先選己方支點，再選正鄰普通士兵；沿接觸方向推開一格。" : "影步：點己方英雄同列或同行的空點，最多兩格，路徑不可有棋子。" }
            return "選擇目標；點\(monsterName)可預覽討伐。"
        }
        guard preview.success else { return explanation(preview.reason) }
        if case .huntMonster(let p)? = pending { return "預覽：\(name(at: p))將移除，花 \(cost) AP。确认前不改實際對局。" }
        let count = preview.events.reduce(0) { total, event in
            if case .piecesCaptured(_, let pieces) = event { return total + pieces.count }; return total
        }
        return "合法預覽：將提 \(count) 顆；\(mode == .loot ? "1 AP／0 能量，能力用一次。" : "")確認前不扣資源。"
    }
    func lootText(_ player: Player) -> String {
        let name = player == .one ? "黑方" : "白方"
        let inventory = state.lootInventory(of: player)
        guard !inventory.isEmpty else { return "\(name)：無可用戰利能力" }
        return "\(name)：" + inventory.map { loot in
            let ability = loot.ability == .stickyBounce ? "黏彈" : "影步"
            let availability = state.ply < loot.unlockPly ? "第 \(loot.unlockPly) 回合解鎖" : "可用一次"
            return "\(ability) · \(availability)"
        }.joined(separator: "；") + " · 1 AP／0 能量"
    }
}

struct MonsterLabView: View {
    @State private var store = MonsterLabStore()
    @State private var showRules = false
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("魔物戰場").font(.title2.bold()).accessibilityIdentifier("mobTitle")
                        Text("\(store.monsterName) · 魔物能力試玩").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("規則", systemImage: "info.circle") { showRules = true }
                }
                Toggle("雙怪同場", isOn: $store.dual).accessibilityIdentifier("mobDual")
                HStack {
                    Picker("魔物", selection: $store.monsterKind) {
                        Text("史萊姆").tag(MonsterKind.slime); Text("暗影狼").tag(MonsterKind.shadowWolf)
                    }.pickerStyle(.segmented).accessibilityIdentifier("mobKind").disabled(store.dual)
                    Toggle("戰利能力", isOn: $store.awardsLoot).accessibilityIdentifier("mobAwards")
                }
                HStack {
                    Picker("討伐成本", selection: $store.cost) {
                        Text("0 AP").tag(0); Text("1 AP").tag(1)
                    }.pickerStyle(.segmented).accessibilityIdentifier("mobCost")
                    Picker("怪物位置", selection: $store.offset) {
                        Text("中心").tag(false); Text("偏中心").tag(true)
                    }.pickerStyle(.segmented).accessibilityIdentifier("mobPosition").disabled(store.dual)
                }
                HStack {
                    heroPicker("黑方", selection: $store.one)
                    heroPicker("白方", selection: $store.two)
                }
                Text("變更設定會開新局；本機雙人輪流操作。")
                    .font(.caption).foregroundStyle(.secondary)
                Text(status).font(.subheadline.bold()).accessibilityIdentifier("mobStatus")
                if store.state.awaitingFreeHunt {
                    Text("行動已用完：可免費討伐，或略過並換手。")
                        .font(.subheadline.bold()).foregroundStyle(.purple).accessibilityIdentifier("mobFreeWindow")
                }
                if !store.state.board.monsters.isEmpty {
                    ForEach(store.spawns.filter { store.state.board.monsters.contains($0.position) }, id: \.position) { monster in
                        let c = GameEngine.monsterControl(store.state, at: monster.position, for: .one)
                        Text("\(store.name(monster.kind))四鄰：黑 \(c.friendly) · 白 \(c.enemy)；至少 2 格且占優勢\(monster.kind == .shadowWolf ? "，含己方英雄" : "")")
                            .font(.caption).accessibilityIdentifier("mobControl_\(monster.position.x)_\(monster.position.y)")
                    }
                } else { Text("\(store.monsterName)已討伐 · 原位置可落子").font(.caption).accessibilityIdentifier("mobHunted") }
                if store.awardsLoot {
                    Text(store.lootText(.one)).font(.caption).accessibilityIdentifier("mobLootBlack")
                    Text(store.lootText(.two)).font(.caption).accessibilityIdentifier("mobLootWhite")
                }
                board
                Picker("操作", selection: $store.mode) {
                    ForEach(MonsterLabStore.Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.pickerStyle(.segmented).accessibilityIdentifier("mobMode")
                if store.mode == .loot && store.dual {
                    Picker("戰利能力", selection: $store.selectedAbility) {
                        Text("黏彈").tag(MonsterAbility.stickyBounce); Text("影步").tag(MonsterAbility.shadowStep)
                    }.pickerStyle(.segmented).accessibilityIdentifier("mobAbility")
                }
                if store.mode == .skill && store.state.heroClass(of: store.state.current) == .mage {
                    HStack {
                        ForEach(PushDirection.allCases, id: \.self) { d in
                            Button(d.title) { store.push(d) }.frame(maxWidth: .infinity, minHeight: 44)
                        }
                    }.buttonStyle(.bordered)
                }
                if let p = store.selected.last, let piece = store.state.board[p] {
                    Text("\(coordinate(p)) · \(piece.owner == .one ? "黑" : "白")方 · 棋串 \(store.state.board.group(at: p).count) 子 · \(store.state.board.liberties(at: p).count) 氣")
                        .font(.caption).accessibilityIdentifier("mobInspection")
                }
                Text(store.previewText).font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("mobPreview")
                HStack {
                    Button("確認") { store.confirm() }.disabled(store.preview?.success != true).accessibilityIdentifier("mobConfirm")
                    Button("取消") { store.cancel() }.accessibilityIdentifier("mobCancel")
                    Button("復原") { store.undo() }.disabled(store.session?.canUndo != true).accessibilityIdentifier("mobUndo")
                    Button(store.state.awaitingFreeHunt ? "略過換手" : "結束回合") { store.endTurn() }
                        .disabled(store.state.status != .ongoing).accessibilityIdentifier("mobEndTurn")
                }.buttonStyle(.bordered).controlSize(.regular)
                Text(store.message).font(.caption).frame(maxWidth: .infinity, alignment: .leading).accessibilityIdentifier("mobMessage")
                HStack {
                    Button("重開") { store.restart() }.accessibilityIdentifier("mobRestart")
                    Button("載入可達比較局面") { store.loadReachableComparison() }.accessibilityIdentifier("mobReachable")
                }.buttonStyle(.bordered)
                Button("載入能力比較局面") { store.loadLootComparison() }.buttonStyle(.bordered).disabled(!store.awardsLoot).accessibilityIdentifier("mobLootReachable")
            }.padding(16).frame(maxWidth: 620)
        }
        .background(Color(red: 0.96, green: 0.94, blue: 0.89))
        .onChange(of: store.dual) { store.restart() }
        .onChange(of: store.selectedAbility) { store.cancel() }
        .onChange(of: store.cost) { store.restart() }
        .onChange(of: store.offset) { store.restart() }
        .onChange(of: store.one) { store.restart() }
        .onChange(of: store.two) { store.restart() }
        .onChange(of: store.mode) { store.cancel() }
        .onChange(of: store.monsterKind) { store.restart() }
        .onChange(of: store.awardsLoot) { store.restart() }
        .sheet(isPresented: $showRules) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("魔物戰場試玩規則").font(.title2.bold())
                    Text("每隻魔物各占一點，不算氣，不連接棋串，也不會被一般提子移除。")
                    Text("四正鄰友軍至少 2 格，且多於敵方，才可主動討伐。主將、英雄與士兵各算一格；斜角不算；2：2 可僵持。")
                    Text("討伐成本依本局設定為 0 或 1 AP，不花能量，也不占英雄技能次數。討伐後原位置成為空點，雙方相鄰棋串都可能增加氣。")
                    Text("0 AP 版用完行動後，若能合法討伐，仍可討伐或略過換手；不能再做普通行動。")
                    Text("暗影狼討伐另需一名正鄰己方英雄。戰利能力為一次性，下一己方回合解鎖，花 1 AP／0 能量，与英雄技能共用每回合一次。")
                    Text("黏彈：己方棋子接觸普通士兵，沿接觸方向推開一格；士兵敵我皆可，終點需空。影步：己方英雄直線移動一至兩格，路徑需空。正常結算提子。")
                    Text("雙怪版為一隻史萊姆與一隻暗影狼。討伐與能力各自保留、分別解鎖，使用只消耗選定的能力；兩份能力仍不能同回合連用。")
                    Text("可關閉戰利能力比較。勝利仍是包圍敵方主將；能力強弱與討伐成本尚未平衡驗收。")
                    Button("返回棋盤") { showRules = false }.buttonStyle(.borderedProminent)
                }.padding(24)
            }
        }
    }
    private var status: String {
        let s = store.state
        if let winner = s.winner { return "\(winner == .one ? "黑" : "白")方獲勝" }
        if s.status == .drawn { return "回合上限 · 和局" }
        return "\(s.current == .one ? "黑" : "白")方 · 第 \(s.ply) 回合 · \(s.apRemaining) AP · \(s.mana(of: s.current)) 能量"
    }
    private func heroPicker(_ title: String, selection: Binding<HeroClass>) -> some View {
        Picker(title, selection: selection) {
            ForEach([HeroClass.warrior, .mage, .rogue], id: \.self) { Text("\(title) \($0.title)").tag($0) }
        }.pickerStyle(.menu).frame(maxWidth: .infinity)
    }
    private var board: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<9, id: \.self) { y in
                GridRow {
                    ForEach(0..<9, id: \.self) { x in cell(Point(x, y)) }
                }
            }
        }.padding(5).background(Color(red: 0.80, green: 0.68, blue: 0.47), in: RoundedRectangle(cornerRadius: 12))
    }
    private func cell(_ p: Point) -> some View {
        let s = store.state
        let displayed = store.preview?.success == true ? store.preview!.state.board : s.board
        return Button { store.select(p) } label: {
            ZStack {
                Rectangle().fill(.black.opacity(0.25)).frame(height: 1)
                Rectangle().fill(.black.opacity(0.25)).frame(width: 1)
                if displayed.monsters.contains(p) {
                    // Neutral ring belongs to the board UI, never baked into candidate artwork.
                    Circle().fill(Color(red: 0.96, green: 0.94, blue: 0.87)).padding(1)
                        .overlay(Circle().stroke(Color(red: 0.26, green: 0.43, blue: 0.30), lineWidth: 1.5).padding(1))
                    if let kind = store.state.config.monsterBattlefield?.kind(at: p), let art = MonsterLabArt.images[kind] {
                        GeometryReader { geometry in
                            Image(uiImage: art).renderingMode(.original).resizable().interpolation(.high).scaledToFit()
                                .frame(width: max(0, geometry.size.width - 6), height: max(0, geometry.size.height - 6))
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }.accessibilityHidden(true)
                    } else { Text("圖樣缺失").font(.caption2).foregroundStyle(.red) }
                } else if let piece = displayed[p] {
                    Circle().fill(piece.owner == .one ? Color.black : Color.white).padding(2)
                        .overlay(Circle().stroke(.black.opacity(0.3), lineWidth: 1).padding(2))
                    Text(piece.kind == .commander ? "將" : piece.kind == .hero ? "英" : "")
                        .font(.caption.bold()).foregroundStyle(piece.owner == .one ? .white : .black)
                }
                if store.selected.contains(p) { RoundedRectangle(cornerRadius: 4).stroke(.purple, lineWidth: 3) }
            }.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityIdentifier("mobCell_\(p.x)_\(p.y)")
            .accessibilityLabel("\(coordinate(p))，\(cellName(s.board, at: p))")
            .accessibilityValue(s.board.monsters.contains(p)
                ? (MonsterLabArt.images[store.state.config.monsterBattlefield!.kind(at: p)!] != nil ? "候選圖樣已載入" : "圖樣缺失") : "")
    }
    private func cellName(_ board: Board, at p: Point) -> String {
        if board.monsters.contains(p) { return store.name(at: p) }
        guard let piece = board[p] else { return "空點" }
        return "\(piece.owner == .one ? "黑" : "白")方\(piece.kind == .commander ? "主將" : piece.kind == .hero ? "英雄" : "士兵")"
    }
    private func coordinate(_ p: Point) -> String { "\(String(UnicodeScalar(65 + p.x)!))\(p.y + 1)" }
}
#endif
