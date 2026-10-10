import Foundation
import TacticalGoCore

/// Finite, deterministic burst samples in pitch units. Presentation only; no emitters or timers
/// survive their successful receipt. Authored locally after reviewing finite-lifetime emitters.
public struct SkillBurstSample: Equatable, Sendable {
    public let x: Double, y: Double, tailX: Double, tailY: Double, alpha: Double, scale: Double
    public static func samples(at age: Double, lifetime: Double = 0.26, count: Int = 18, flatten: Double = 0.48) -> [Self] {
        guard age.isFinite, lifetime.isFinite, age >= 0, lifetime > 0, age < lifetime else { return [] }
        let t = age / lifetime, n = min(28, max(0, count)), f = min(1, max(0.15, flatten))
        return (0..<n).map { i in
            let angle = Double(i) * 2.399963229728653
            let speed = 0.32 + Double((i * 7) % 11) / 30
            // Fast launch followed by damping; small gravity arc never reaches the next anchor.
            func p(_ time: Double) -> (Double, Double) {
                let r = speed * (1 - exp(-4 * time))
                return (cos(angle) * r, sin(angle) * r * f - 0.12 * sin(.pi * time))
            }
            let head = p(t), tail = p(max(0, t - 0.12))
            return Self(x: head.0, y: head.1, tailX: tail.0, tailY: tail.1,
                        alpha: pow(1-t, 1.3), scale: (0.028 + Double(i % 3) * 0.012) * (1-0.6*t))
        }
    }
}

/// Describes real successful first-skill receipts. No rule resolution or state writes.
public struct SkillVFX: Equatable, Sendable {
    public enum Kind: String, Sendable { case bastion, magicHand, swap }
    public let kind: Kind
    public let caster: Player
    public let hero: Point
    public let sources: [Point]
    public let destinations: [Point]
    public let captures: [CapturedPiece]
    public let release: Double, moveStart: Double, arrival: Double, captureStart: Double, end: Double
    public static let reducedHintDuration = 0.24
    public func isActive(at time: Double) -> Bool { time >= 0 && time < end }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome, tempo: MageTempo = .full) -> Self? {
        guard outcome.success else { return nil }
        if let clip = Anim01MagicHand.make(before:before,action:action,outcome:outcome,tempo:tempo) {
            return Self(kind:.magicHand,caster:clip.caster,hero:clip.hero,sources:[clip.from],destinations:[clip.to],captures:clip.captures,
                        release:clip.timing.release,moveStart:clip.timing.moveStart,arrival:clip.timing.arrival,captureStart:clip.timing.captureStart,end:clip.duration)
        }
        guard let body = HeroPerformance.make(before:before,action:action,outcome:outcome),!body.isSummon else { return nil }
        let t=body.timing
        let captures=outcome.events.flatMap { e -> [CapturedPiece] in if case .piecesCaptured(_,let pieces)=e {return pieces};return [] }
        switch action {
        case .castBastion:
            let targets=outcome.events.compactMap { e -> Point? in
                if case .piecePlaced(let player,let p,.soldier)=e,player==before.current {return p};return nil
            }
            guard targets.count==2,Set(targets).count==2 else {return nil}
            return Self(kind:.bastion,caster:before.current,hero:body.hero,sources:[body.hero],destinations:targets,captures:captures,
                        release:t.release,moveStart:t.moveStart,arrival:t.arrival,captureStart:t.captureStart,end:body.duration)
        case .castSwap:
            let pairs=outcome.events.compactMap { e -> [Point]? in if case .piecesSwapped(let player,let a,let b)=e,player==before.current {return [a,b]};return nil }
            guard pairs.count==1,let points=pairs.first,points.contains(body.hero) else {return nil}
            let target=points.first{$0 != body.hero}!
            return Self(kind:.swap,caster:before.current,hero:body.hero,sources:[body.hero,target],destinations:[target,body.hero],captures:captures,
                        release:t.release,moveStart:t.moveStart,arrival:t.arrival,captureStart:t.captureStart,end:body.duration)
        default:return nil
        }
    }
}

/// Reviewed, Core-validated test fixtures. Not a claim of competitive reachability.
public enum SkillVFXFixture {
    public static func state(_ hero:HeroClass,owner:Player = .one,size:Int = 7,capture:Bool = false,dense:Bool = false,enemyTarget:Bool = false) throws -> GameState {
        if hero != .mage {return try HeroBodyFixture.state(hero,owner:owner,size:size,capture:capture,dense:dense)}
        let base = try Anim01Fixture.state(size:size,caster:owner,pushedOwner:enemyTarget ? owner.opponent:owner,capture:capture)
        guard dense else{return base}
        var rows=base.board.diagram.split(separator:"\n").map{Array($0)}
        let friendly:Character=owner == .one ? "x":"o"
        for y in [0,6,8] where y<size {for x in 0..<size where rows[y][x] == "." {rows[y][x]=x%2==0 ? "x":"o"}}
        rows[0][3]="."
        for y in [2,4] {for x in [0,1,6,7,8] where x<size && rows[y][x] == "." {rows[y][x]=x%2==0 ? "x":"o"}}
        // Genuine pre-action orthogonal neighbors of the caster, not only after-state samples.
        if rows[2][3] == "." {rows[2][3]=friendly};rows[4][3]=friendly
        return try GameSetup.fromDiagram(config:base.config,diagram:rows.map{String($0)}.joined(separator:"\n"),classOne:base.heroClass(of:.one),classTwo:base.heroClass(of:.two),current:owner,manaOne:4,manaTwo:4,ap:2)
    }
    public static func action(_ hero:HeroClass) -> GameAction {hero == .mage ? Anim01Fixture.action:HeroBodyFixture.action(hero)}
}
