import Foundation

/// Art-canvas degrees/pixels. No game-state mutation, no animation callback effects.
public struct ExpansionHeroPose: Equatable, Sendable {
    public var body = 0.0, bodyX = 0.0, bodyY = 0.0, head = 0.0
    public var hand = 0.0, handX = 0.0, handY = 0.0, book = 0.0, bookY = 0.0, cloth = 0.0
    public static let rest = Self()
    private static func blend(_ a: Self,_ b: Self,_ t: Double) -> Self {
        let u = MotionCurves.ease(t)
        func v(_ x: Double,_ y: Double) -> Double { x+(y-x)*u }
        return Self(body:v(a.body,b.body),bodyX:v(a.bodyX,b.bodyX),bodyY:v(a.bodyY,b.bodyY),head:v(a.head,b.head),hand:v(a.hand,b.hand),handX:v(a.handX,b.handX),handY:v(a.handY,b.handY),book:v(a.book,b.book),bookY:v(a.bookY,b.bookY),cloth:v(a.cloth,b.cloth))
    }
    private static func sample(_ time: Double,keys: [(Double,Self)]) -> Self {
        for i in 1..<keys.count where time <= keys[i].0 {
            return blend(keys[i-1].1,keys[i].1,(time-keys[i-1].0)/(keys[i].0-keys[i-1].0))
        }
        return .rest
    }
    public static func rogue(at t: Double,reduced: Bool = false,chained: Bool = false) -> Self {
        guard !reduced,t.isFinite,t >= 0,t < 0.70 else { return .rest }
        let coil = Self(body:-9,bodyX:12,bodyY:16,head:6,hand:-20,handX:-6,handY:-8,cloth:-6)
        let release = Self(body:10,bodyX:-18,bodyY:8,head:-5,hand:19,handX:-4,handY:3,cloth:5)
        let contact = Self(body:4,bodyX:-7,bodyY:17,head:-2,hand:9,cloth:8)
        let recoil = Self(body:-3,bodyX:3,bodyY:3,head:2,hand:-4,cloth:-4)
        let keys: [(Double,Self)] = chained
            ? [(0,.rest),(0.12,coil),(0.16,release),(0.24,contact),(0.26,recoil),(0.28,coil),(0.30,release),(0.36,contact),(0.44,recoil),(0.60,.rest),(0.70,.rest)]
            : [(0,.rest),(0.12,coil),(0.16,release),(0.36,contact),(0.44,recoil),(0.60,.rest),(0.70,.rest)]
        var p = sample(t,keys:keys); p.cloth = sample(max(0,t-0.06),keys:keys).cloth; return p
    }
    public static func priest(at t: Double,reduced: Bool = false,offering: Bool = false) -> Self {
        guard !reduced,t.isFinite,t >= 0,t < 0.94 else { return .rest }
        let prayer = Self(body:-4,bodyX:5,bodyY:4,head:7,hand:-10,handX:7,handY:5,book:-9,bookY:-8,cloth:-2)
        let reach = Self(body:5,bodyX:-9,head:-4,hand:12,handX:-12,handY:-10,book:-5,bookY:-5,cloth:3)
        let bless = Self(body:3,bodyX:-6,head:-2,hand:9,handX:-9,handY:-7,book:-2,bookY:-2,cloth:5)
        let rest = Self(body:-1,head:1,hand:-2,cloth:-2)
        let letGo = Self(body:3,bodyX:-6,head:4,hand:18,handX:-14,handY:-18,book:-10,bookY:-12,cloth:5)
        let keys: [(Double,Self)] = offering
            ? [(0,.rest),(0.20,prayer),(0.32,reach),(0.42,letGo),(0.58,bless),(0.68,rest),(0.84,.rest),(0.94,.rest)]
            : [(0,.rest),(0.20,prayer),(0.32,reach),(0.58,bless),(0.68,rest),(0.84,.rest),(0.94,.rest)]
        var p = sample(t,keys:keys); p.cloth = sample(max(0,t-0.08),keys:keys).cloth; return p
    }
}
