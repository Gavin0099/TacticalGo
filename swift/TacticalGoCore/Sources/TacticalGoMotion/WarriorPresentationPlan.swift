import TacticalGoCore

/// Original-pixel cutout coordinates; a presentation value, never game state.
public struct WarriorBodyPose: Equatable, Sendable {
    public var body = 0.0, bodyX = 0.0, bodyY = 0.0, head = 0.0
    public var held = 0.0, heldX = 0.0, heldY = 0.0
    public var shield = 0.0, shieldX = 0.0, shieldY = 0.0, cloth = 0.0
    public var lift = 0.0, opacity = 1.0
    public static let rest = Self()
    private static func blend(_ a:Self,_ b:Self,_ t:Double) -> Self {
        let u=MotionCurves.ease(t)
        func v(_ a:Double,_ b:Double)->Double { a+(b-a)*u }
        return Self(body:v(a.body,b.body),bodyX:v(a.bodyX,b.bodyX),bodyY:v(a.bodyY,b.bodyY),head:v(a.head,b.head),held:v(a.held,b.held),heldX:v(a.heldX,b.heldX),heldY:v(a.heldY,b.heldY),shield:v(a.shield,b.shield),shieldX:v(a.shieldX,b.shieldX),shieldY:v(a.shieldY,b.shieldY),cloth:v(a.cloth,b.cloth),lift:v(a.lift,b.lift),opacity:v(a.opacity,b.opacity))
    }
    public static func skill(at time:Double,reduced:Bool=false,weighted:Bool=false) -> Self {
        guard !reduced, time.isFinite, time>=0, time<1.02 else { return .rest }
        let coil=Self(body:weighted ? -10:-7,bodyX:weighted ? 18:14,bodyY:weighted ? 30:24,head:5,held:weighted ? -22:-16,heldX:-6,heldY:-12,shield:weighted ? -32:-24,shieldX:-8,shieldY:weighted ? -104:-88,cloth:-6)
        let release=Self(body:2,bodyY:12,head:-1,held:4,heldX:-3,heldY:-4,shield:-9,shieldX:-4,shieldY:-28,cloth:1)
        let impact=Self(body:weighted ? 24:10,bodyX:weighted ? -28:-18,bodyY:weighted ? 60:34,head:weighted ? -10:-6,held:weighted ? 16:11,heldX:-6,heldY:4,shield:weighted ? 28:12,shieldX:4,shieldY:weighted ? 26:34,cloth:7)
        let recoil=Self(body:-2,bodyX:4,bodyY:12,head:2,held:-3,heldY:-3,shield:-3,shieldY:8,cloth:-5)
        let departure=Self(body:-4,bodyX:8,bodyY:22,head:2,held:-10,heldX:-4,heldY:-6,shield:-20,shieldX:-6,shieldY:-72,cloth:-3)
        // The body has visibly left the windup at receipt release .34, before
        // soldier motion .35. Contact .58 and the 60ms weight hold stay shared.
        let keys:[(Double,Self)] = weighted
            ? [(0,.rest),(0.22,coil),(0.28,coil),(0.34,departure),(0.50,release),(0.58,impact),(0.64,impact),(0.74,recoil),(0.94,.rest),(1.02,.rest)]
            : [(0,.rest),(0.20,coil),(0.27,coil),(0.34,release),(0.58,impact),(0.65,recoil),(0.92,.rest),(1.02,.rest)]
        func sample(_ t:Double)->Self {
            for i in 1..<keys.count where t<=keys[i].0 { return blend(keys[i-1].1,keys[i].1,(t-keys[i-1].0)/(keys[i].0-keys[i-1].0)) }
            return .rest
        }
        var p=sample(time);p.cloth=sample(max(0,time-0.08)).cloth;return p
    }
}

/// Consumes a confirmed atomic Bastion receipt. No rules or winner inference.
public struct WarriorPresentationPlan: Equatable, Sendable {
    public let before:GameState, after:GameState
    public let caster:Player, hero:Point, placements:[Point], captures:[CapturedPiece]
    public let sounds:[CombatSoundCue]
    public let original:Bool
    public var fallStart:Double { original ? 0.18 : 0.35 }
    public var arrival:Double { original ? 0.39 : 0.58 }
    public var captureStart:Double { original ? 0.48 : 0.68 }
    public var duration:Double { original ? 0.76 : 1.02 }
    public static func make(before:GameState,action:GameAction,outcome:ActionOutcome,current:GameState,original:Bool=false)->Self? {
        guard outcome.success, current==outcome.state, before.heroClass(of:before.current) == .warrior,
              case .castBastion(let a,let b)=action, a != b,
              before.board.contains(a),before.board.contains(b),before.board.isEmpty(a),before.board.isEmpty(b),
              let hero=before.board.find(before.current,.hero) else { return nil }
        let placed=outcome.events.compactMap { event -> Point? in
            if case .piecePlaced(let owner,let p,let kind)=event,owner==before.current,kind == .soldier {return p};return nil
        }
        guard placed.count==2,Set(placed)==Set([a,b]) else {return nil}
        let captures=outcome.events.flatMap { event -> [CapturedPiece] in
            if case .piecesCaptured(_,let pieces)=event {return pieces};return []
        }
        var sounds:[CombatSoundCue]=original ? [.init("warrior",at:0),.init("place",at:0.25)] : [.init("w7-brace",at:0.20),.init("w7-strike",at:0.58),.init("w7-land",at:0.58)]
        if !captures.isEmpty {sounds.append(.init("capture",at:original ? 0.48:0.68))}
        for event in outcome.events {
            switch event {
            case .gameWon: sounds.append(.init("victory",at:original ? 0.96:1.02))
            case .gameDrawn: sounds.append(.init("draw",at:original ? 0.76:1.02))
            default:break
            }
        }
        return Self(before:before,after:outcome.state,caster:before.current,hero:hero,placements:placed,captures:captures,sounds:sounds,original:original)
    }
    public func board(at time:Double,reduced:Bool=false)->Board { reduced || !time.isFinite || time>=arrival ? after.board:before.board }
    public func pose(at time:Double,reduced:Bool=false)->WarriorBodyPose {original ? .rest:WarriorBodyPose.skill(at:time,reduced:reduced)}
    public func fallProgress(at time:Double)->Double {
        guard time.isFinite else {return 1};return MotionCurves.clamp((time-fallStart)/(arrival-fallStart))
    }
}

public enum WarriorPresentationFixture {
    public static let action:GameAction = .castBastion(Point(2,3),Point(4,3))
    public static func state(owner:Player = .one,size:Int=7,capture:Bool=false,dense:Bool=false,ap:Int=2)throws->GameState {
        precondition(size==7 || size==9)
        var rows=Array(repeating:Array(repeating:Character("."),count:size),count:size)
        let friend:Character=owner == .one ? "x":"o",enemy:Character=owner == .one ? "o":"x"
        rows[5][3]=owner == .one ? "X":"O";rows[1][3]=owner == .one ? "O":"X";rows[3][3]=owner == .one ? "H":"Q"
        if capture {rows[1][3]=".";rows[2][2]=owner == .one ? "O":"X";rows[1][2]=friend;rows[2][1]=friend;rows[2][3]=friend}
        if dense {
            rows[2][3]=friend;rows[4][3]=friend
            for y in [0,6,8] where y<size {for x in 0..<size {rows[y][x]=x%2==0 ? friend:enemy}}
            rows[0][3]="."
            // On7x7 the edge pawn under the friendly commander otherwise
            // starts with zero liberties; a review fixture must begin alive.
            rows[6][3]="."
        }
        return try GameSetup.fromDiagram(config:.board(size:size),diagram:rows.map{String($0)}.joined(separator:"\n"),classOne:owner == .one ? .warrior:.mage,classTwo:owner == .two ? .warrior:.mage,current:owner,manaOne:4,manaTwo:4,ap:ap)
    }
}

/// Tangible original-shield echoes follow the same successful receipt clock.
/// They disappear after the two summons and never imply a lasting gameplay buff.
public struct WarriorBastionEffectFrame:Equatable,Sendable {
    public enum Phase:Sendable {case forge,deploy,impact,dissolve,ended}
    public let phase:Phase,alpha:Double,travel:Double,scale:Double,lift:Double,impact:Double
    public static func sample(at time:Double,reduced:Bool=false)->Self {
        func u(_ a:Double,_ b:Double)->Double {MotionCurves.clamp((time-a)/(b-a))}
        guard !reduced,time.isFinite,time>=0.16,time<0.98 else {return Self(phase:.ended,alpha:0,travel:0,scale:0,lift:0,impact:0)}
        if time<0.30 {let t=u(0.16,0.30);return Self(phase:.forge,alpha:0.50*t,travel:0,scale:0.25+0.45*t,lift:0.15,impact:0)}
        if time<0.58 {let t=MotionCurves.ease(u(0.30,0.58));return Self(phase:.deploy,alpha:0.50,travel:t,scale:0.70+0.26*t,lift:0.15*(1-t),impact:0)}
        // The real soldier owns contact: no expanding opaque shield over its face.
        // Keep a brief echo, then clear it before the body has recovered.
        if time<0.70 {let t=u(0.58,0.70);return Self(phase:.impact,alpha:0.50-0.38*t,travel:1,scale:0.96-0.10*t,lift:0,impact:1-u(0.58,0.84))}
        let t=u(0.70,0.78);return Self(phase:.dissolve,alpha:0.12*(1-t),travel:1,scale:0.86,lift:0,impact:1-u(0.58,0.84))
    }
}
