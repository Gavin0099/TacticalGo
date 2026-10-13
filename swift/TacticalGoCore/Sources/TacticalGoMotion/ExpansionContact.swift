import TacticalGoCore

/// A local contact beat, derived only from a validated immutable receipt.
public struct ExpansionContactBeat: Equatable, Sendable {
    public let at: Point
    public let from: Point?
    public let start: Double
}

public struct ExpansionContactFrame: Equatable, Sendable {
    public let opacity: Double, radius: Double, rise: Double
    public static let quiet = Self(opacity:0,radius:0.38,rise:0)
    public static func sample(at time: Double, start: Double, end: Double, reduced: Bool = false) -> Self {
        guard !reduced,time.isFinite,start.isFinite,end.isFinite,start >= 0,end > start,
              time >= start,time < end,time < start+0.18 else { return .quiet }
        let u = MotionCurves.clamp((time-start)/0.18)
        // Brief firm contact, then settle. Local radius never crosses the cell boundary.
        let fade = 1-MotionCurves.ease((u-0.16)/0.84)
        return .init(opacity:fade,radius:0.38+0.08*MotionCurves.ease(u),rise:0.22*u)
    }
}

extension ExpansionPresentation {
    public var contactBeats: [ExpansionContactBeat] {
        switch action {
        case .castChainSwap(let first,let second):
            guard let origin = hero else { return [] }
            let middleTime = (moveStart+arrival)/2
            return [.init(at:origin,from:first,start:middleTime),.init(at:first,from:origin,start:middleTime),
                    .init(at:first,from:second,start:arrival),.init(at:second,from:first,start:arrival)]
        case .castOffering:
            return sacrifices.map { .init(at:$0,from:nil,start:arrival) }
        case .castBastion,.castReformation,.castMagicHand,.castDoublePull,.castSwap,.castSanctuary:
            var points: [Point] = []
            return (placements+transfers.map(\.to)).compactMap { point in
                guard !points.contains(point) else { return nil }; points.append(point)
                let source = transfers.first { $0.to == point }?.from ?? hero
                return .init(at:point,from:source,start:arrival)
            }
        default: return []
        }
    }
}
