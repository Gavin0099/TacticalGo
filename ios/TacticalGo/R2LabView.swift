import SwiftUI
import TacticalGoCore
import TacticalGoRecords

struct R2PracticeFixture: Decodable, Identifiable {
    let id: String
    let heroClass: HeroClass
    let purpose: String
    let diagram: String
    let focus: Focus
    struct Focus: Decodable {
        let kind: String
        let a: [Int]?
        let b: [Int]?
        let target: [Int]?
        let direction: String?
        var action: GameAction? {
            if kind == "bastion", let a, let b, a.count == 2, b.count == 2 { return .castBastion(Point(a[0],a[1]),Point(b[0],b[1])) }
            if let target, target.count == 2, let direction, let d = PushDirection(rawValue:direction) { return .castMagicHand(Point(target[0],target[1]),d) }
            return nil
        }
    }
    static var fixtures: [Self] {
        guard let url = Bundle.main.url(forResource:"R2Positions",withExtension:"json"), let data = try? Data(contentsOf:url) else { return [] }
        return (try? JSONDecoder().decode([Self].self,from:data)) ?? []
    }
}
extension RecordRules {
    var variant: String { switch self { case .original:"A"; case .warrior:"B"; case .mage:"C"; case .both:"D"; case .redeployment:"E" } }
    var labDescription: String {
        switch self {
        case .original: "A 原版：英雄相鄰築壘／只推入空點"
        case .warrior: "B 戰士：原棋串旁築壘／法師原版"
        case .mage: "C 法師：空點推動或異色士兵交換／戰士原版"
        case .both: "D 兩項候選：原棋串築壘＋異色士兵交換"
        case .redeployment: "沿棋群築壘＋調度己兵"
        }
    }
}
struct R2LabView: View {
    let start: (R2PracticeFixture, RecordRules) -> Void
    private let fixtures = R2PracticeFixture.fixtures
    @State private var rules: RecordRules = .original
    @State private var selectedID = "warrior-rear-frontier"
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("固定中後期局面，比較技能與反制。這是獨立試驗；不改正式對戰，也不存成正常對局。")
                }
                Section("規則對照") {
                    Picker("候選",selection:$rules) {
                        ForEach(RecordRules.allCases.filter { $0 != .redeployment },id:\.self) { value in Text(value.variant).tag(value) }
                    }.pickerStyle(.segmented).accessibilityIdentifier("r2Variant")
                    Text(rules.labDescription)
                }
                Section("固定局面") {
                    HStack {
                        Button("戰士密集") { selectedID = "warrior-rear-frontier" }.accessibilityIdentifier("r2Warrior")
                        Button("法師密集") { selectedID = "mage-dense-front" }.accessibilityIdentifier("r2Mage")
                    }.buttonStyle(.bordered)
                    Picker("選擇局面",selection:$selectedID) {
                        ForEach(fixtures) { fixture in Text(fixture.heroClass.title + "：" + fixture.purpose).tag(fixture.id) }
                    }.accessibilityIdentifier("r2Position")
                    if let fixture = fixtures.first(where:{$0.id == selectedID}) {
                        Text(fixture.purpose)
                        if let action = fixture.focus.action { Text("先比較：" + RecordedAction(action).label).foregroundStyle(.secondary) }
                        Button("開始試驗") { start(fixture,rules); dismiss() }.accessibilityIdentifier("startR2")
                    } else { Text("試驗局面尚未載入。") }
                }
                Section("觀察") {
                    Text("目標增加後，是否產生值得花 1 AP＋2 能量的選擇？對手能否預測與反制？法師是否壓縮盜賊的戰術空間？")
                    Text("戰士兩點都取自施放前的原棋串；第一子不能延伸第二子範圍。法師交換只限異色普通士兵，主將與英雄不合法。")
                }
            }.navigationTitle("後期技能試驗 R2")
                .toolbar { ToolbarItem(placement:.confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
