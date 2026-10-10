import TacticalGoCore

/// Warrior/rogue cutout presentation. Coordinates use the immutable 512px portrait.
public struct HeroBodyPose: Equatable, Sendable {
    public var body = 0.0, bodyX = 0.0, bodyY = 0.0, head = 0.0
    public var held = 0.0, heldX = 0.0, heldY = 0.0
    public var shield = 0.0, shieldX = 0.0, shieldY = 0.0, cloth = 0.0
    public var lift = 0.0, opacity = 1.0
    public static let rest = Self()
    private static func blend(_ a: Self,_ b: Self,_ t: Double) -> Self {
        let u = MotionCurves.ease(t)
        func v(_ a: Double,_ b: Double) -> Double { a+(b-a)*u }
        return Self(body:v(a.body,b.body),bodyX:v(a.bodyX,b.bodyX),bodyY:v(a.bodyY,b.bodyY),head:v(a.head,b.head),held:v(a.held,b.held),heldX:v(a.heldX,b.heldX),heldY:v(a.heldY,b.heldY),shield:v(a.shield,b.shield),shieldX:v(a.shieldX,b.shieldX),shieldY:v(a.shieldY,b.shieldY),cloth:v(a.cloth,b.cloth),lift:v(a.lift,b.lift),opacity:v(a.opacity,b.opacity))
    }
    public static func skill(_ hero: HeroClass, at time: Double, reduced: Bool = false, direction: Double = 1) -> Self {
        let t = HeroBodyTiming.skill(hero)
        guard !reduced, (hero == .warrior || hero == .rogue), time >= 0, time < t.recoveryEnd else { return .rest }
        let d = direction < 0 ? -1.0 : 1.0
        let coil = hero == .warrior
            ? Self(body:-7,bodyX:14,bodyY:24,head:5,held:-16,heldX:-6,heldY:-12,shield:-24,shieldX:-8,shieldY:-88,cloth:-6)
            : Self(body:-5*d,bodyX:-22*d,bodyY:34,head:3*d,held:-12,heldX:10,heldY:14,cloth:4)
        let release = hero == .warrior
            ? Self(body:2,bodyX:0,bodyY:12,head:-1,held:4,heldX:-3,heldY:-4,shield:-9,shieldX:-4,shieldY:-28,cloth:1)
            : Self(body:7*d,bodyX:22*d,bodyY:14,head:-3*d,held:10,heldX:-16,heldY:-8,cloth:-7)
        let landed = hero == .warrior
            ? Self(body:-2,bodyX:4,bodyY:12,head:2,held:-3,heldY:-3,shield:-3,shieldY:8,cloth:-5)
            : Self(body:-3*d,bodyX:6*d,bodyY:20,head:1*d,held:3,cloth:6)
        // Warrior's lowest shield pose coincides with BOTH soldier landings.
        // A readable hold precedes the final quick downstroke; recoil follows
        // contact, rather than finishing while the soldiers are still falling.
        let impact = Self(body:10,bodyX:-18,bodyY:34,head:-6,held:11,heldX:-6,heldY:4,shield:12,shieldX:4,shieldY:34,cloth:7)
        let keys: [(Double,Self)] = hero == .warrior
            ? [(0,.rest),(t.anticipationEnd,coil),(t.anticipationEnd+0.07,coil),(t.release,release),(t.arrival,impact),(t.arrival+0.07,landed),(t.recoveryEnd-0.10,.rest),(t.recoveryEnd,.rest)]
            : [(0,.rest),(t.anticipationEnd,coil),(t.release,release),(t.arrival,landed),(t.recoveryEnd-0.10,.rest),(t.recoveryEnd,.rest)]
        func sample(_ time: Double) -> Self {
            for i in 1..<keys.count where time <= keys[i].0 {
                return blend(keys[i-1].1,keys[i].1,(time-keys[i-1].0)/(keys[i].0-keys[i-1].0))
            }
            return .rest
        }
        var p = sample(time); p.cloth = sample(max(0,time-0.08)).cloth
        return p
    }
    public static func summon(_ hero: HeroClass, at time: Double, reduced: Bool = false) -> Self {
        let end = hero == .warrior ? 0.64 : 0.58
        guard !reduced, (hero == .warrior || hero == .rogue), time >= 0, time < end else { return .rest }
        if hero == .warrior {
            let approach = Self(body:-4,head:2,held:-8,shield:-15,shieldY:-48,cloth:-4,lift:-12,opacity:0)
            let contact = Self(body:5,bodyY:28,head:-3,held:7,heldY:4,shield:8,shieldY:24,cloth:5)
            let brace = Self(body:1,bodyY:10,head:-1,held:2,shield:2,shieldY:6,cloth:-4)
            if time < 0.21 { return blend(approach,contact,time/0.21) }
            if time < 0.30 { return blend(contact,brace,(time-0.21)/0.09) }
            return blend(brace,.rest,(time-0.30)/(end-0.30))
        }
        let approach = Self(held:hero == .rogue ? -10 : -3,shield:-8,shieldY:-24,cloth:-3,lift:-18,opacity:0)
        let land = hero == .warrior ? Self(body:-3,bodyY:14,held:4,shield:7,shieldY:12,cloth:5) : Self(body:-5,bodyY:24,held:8,heldY:8,cloth:-6)
        if time < 0.26 { return blend(approach,land,time/0.26) }
        return blend(land,.rest,(time-0.26)/(end-0.26))
    }
}

public struct HeroBodyTiming: Equatable, Sendable {
    public let anticipationEnd: Double, release: Double, moveStart: Double, arrival: Double, captureStart: Double, recoveryEnd: Double
    public static func skill(_ hero: HeroClass) -> Self {
        hero == .warrior
            ? Self(anticipationEnd:0.20,release:0.34,moveStart:0.35,arrival:0.48,captureStart:0.54,recoveryEnd:0.78)
            : Self(anticipationEnd:0.12,release:0.20,moveStart:0.22,arrival:0.42,captureStart:0.48,recoveryEnd:0.72)
    }
}

/// Typed successful receipt adapter; no rule resolution, candidate target expansion or resource writes.
public struct HeroPerformance: Equatable, Sendable {
    public let heroClass: HeroClass, hero: Point
    public let isSummon: Bool
    public let timing: HeroBodyTiming
    public let plan: MotionPlan
    public let audio: CombatFeedbackPlan
    public var duration: Double { max(plan.duration,isSummon ? (heroClass == .warrior ? 0.64 : 0.58) : timing.recoveryEnd) }
    public static func make(before: GameState, action: GameAction, outcome: ActionOutcome) -> Self? {
        guard outcome.success else { return nil }
        let h = before.heroClass(of:before.current)
        guard h == .warrior || h == .rogue else { return nil }
        let summon: Bool, hero: Point
        switch action {
        case .summonHero(let at):
            guard outcome.events.contains(where:{ if case .piecePlaced(let owner,let p,let kind) = $0 { return owner == before.current && p == at && kind == .hero };return false }) else { return nil }
            summon = true; hero = at
        case .castBastion where h == .warrior:
            guard let at = before.board.find(before.current,.hero), outcome.events.contains(where:{ if case .piecePlaced = $0 {return true};return false }) else {return nil}
            summon = false; hero = at
        case .castSwap where h == .rogue:
            guard let at = before.board.find(before.current,.hero),outcome.events.contains(where:{ if case .piecesSwapped = $0 {return true};return false }) else {return nil}
            summon = false; hero = at
        default:return nil
        }
        let t = HeroBodyTiming.skill(h), old = MotionPlan.make(before:before,action:action,outcome:outcome)
        let captures = old.cues.contains { if case .capture = $0.kind {return true};return false }
        let resultTime = captures ? t.captureStart+0.28 : t.arrival
        let cues = old.cues.map { c -> MotionCue in
            guard !summon else { return c }
            switch c.kind {
            case .bastion: return MotionCue(c.kind,c.points,start:0,duration:t.arrival)
            case .drop,.swap:return MotionCue(c.kind,c.points,start:t.moveStart,duration:t.arrival-t.moveStart)
            case .capture:return MotionCue(c.kind,c.points,start:t.captureStart,duration:c.duration)
            case .win:return MotionCue(c.kind,c.points,start:t.captureStart+0.28,duration:c.duration)
            case .draw:return MotionCue(c.kind,c.points,start:resultTime,duration:c.duration)
            case .turn:return MotionCue(c.kind,c.points,start:max(resultTime,t.recoveryEnd),duration:c.duration)
            default:return c
            }
        }
        let plan = MotionPlan(cues:cues,duration:max(cues.map{$0.start+$0.duration}.max() ?? 0,summon ? 0 : t.recoveryEnd))
        let oldAudio = CombatFeedbackPlan.make(before:before,action:action,outcome:outcome)
        let sounds = oldAudio.cues.map { c -> CombatSoundCue in
            guard !summon else {return c}
            switch c.key {
            case "warrior","rogue":return CombatSoundCue(c.key,at:t.release)
            case "place":return CombatSoundCue(c.key,at:t.arrival)
            case "capture":return CombatSoundCue(c.key,at:t.captureStart)
            case "victory":return CombatSoundCue(c.key,at:max(t.recoveryEnd,t.captureStart+0.34))
            case "draw":return CombatSoundCue(c.key,at:resultTime)
            case "danger":return CombatSoundCue(c.key,at:captures ? resultTime : t.arrival+0.12)
            default:return c
            }
        }
        let soundEnd = sounds.map { $0.start + ($0.key == "victory" ? 0.59 : $0.key == "draw" ? 0.4 : 0) }.max() ?? 0
        return Self(heroClass:h,hero:hero,isSummon:summon,timing:t,plan:plan,audio:CombatFeedbackPlan(cues:sounds.sorted{$0.start<$1.start},duration:max(oldAudio.duration,plan.duration,soundEnd)))
    }
}

/// Fixed Core-validated review fixtures, not a claim of competitive reachability.
public enum HeroBodyFixture {
    public static func state(_ hero: HeroClass, owner: Player = .one, size: Int = 7, capture: Bool = false, dense: Bool = false, summon: Bool = false) throws -> GameState {
        precondition(hero == .warrior || hero == .rogue)
        precondition(size == 7 || size == 9)
        var rows = Array(repeating:Array(repeating:Character("."),count:size),count:size)
        let friendly: Character = owner == .one ? "x" : "o", enemy: Character = owner == .one ? "o" : "x"
        rows[5][3] = owner == .one ? "X" : "O"
        rows[1][3] = owner == .one ? "O" : "X"
        if !summon {
            rows[3][3] = owner == .one ? "H" : "Q"
            if hero == .rogue { rows[3][4] = enemy }
            if capture {
                rows[1][3] = "."
                let x = hero == .warrior ? 2 : 4
                rows[2][x] = owner == .one ? "O" : "X"
                rows[1][x] = friendly; rows[2][x-1] = friendly;rows[2][x+1] = friendly
            }
            if dense {
                for y in [0,6,8] where y < size { for x in 0..<size where rows[y][x] == "." { rows[y][x] = x % 2 == 0 ? friendly : enemy } }
                rows[0][3] = "."
                for y in [2,4] { for x in [0,1,6,7,8] where x < size && rows[y][x] == "." { rows[y][x] = x % 2 == 0 ? friendly : enemy } }
                // Actual pre-action orthogonal neighbors, not only sparse final frames.
                rows[2][3] = friendly;rows[4][3] = friendly
                if hero == .rogue { rows[3][2] = friendly }
            }
        }
        return try GameSetup.fromDiagram(config:.board(size:size),diagram:rows.map{String($0)}.joined(separator:"\n"),classOne:hero,classTwo:hero,current:owner,manaOne:4,manaTwo:4,ap:2)
    }
    public static func action(_ hero: HeroClass, summon: Bool = false) -> GameAction {
        if summon {return .summonHero(Point(3,4))}
        return hero == .warrior ? .castBastion(Point(2,3),Point(4,3)) : .castSwap(Point(4,3))
    }
}
