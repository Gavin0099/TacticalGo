import Foundation
import TacticalGoCore

/// Presentation policy; never changes legality or game resources.
public enum BattleMusicLevel: Int, Sendable { case normal, focus, danger }
public struct BattleMusicMix: Sendable {
    public private(set) var level: BattleMusicLevel = .normal
    public private(set) var ended = false
    private var desired: BattleMusicLevel = .normal
    private var desiredSince = 0.0
    private var rampStart = 0.0
    private var from = [1.0, 0.0, 0.0]
    private var to = [1.0, 0.0, 0.0]
    private var duckStart: Double?
    private var duckFrom = 1.0
    private var duckHold = 0.0
    private var endStart: Double?
    public init() {}
    public static func threat(_ state: GameState) -> BattleMusicLevel {
        let minimum = Player.allCases.compactMap { player -> Int? in
            state.board.find(player, .commander).map { state.board.liberties(at: $0).count }
        }.min() ?? 4
        return minimum <= 1 ? .danger : minimum <= 2 ? .focus : .normal
    }
    public mutating func request(_ target: BattleMusicLevel, at now: Double) {
        if target != desired { desired = target; desiredSince = now }
        advance(at: now)
    }
    public mutating func advance(at now: Double) {
        guard !ended, desired != level else { return }
        // Escalate immediately; require stability before relaxing the atmosphere.
        guard desired.rawValue > level.rawValue || now - desiredSince >= 1.2 else { return }
        from = layers(at: now); level = desired; rampStart = now
        to = [1, level.rawValue >= 1 ? 1 : 0, level == .danger ? 1 : 0]
    }
    public func layers(at now: Double) -> [Double] {
        let fraction = min(1, max(0, (now - rampStart) / 4.8))
        return zip(from, to).map { $0 + ($1 - $0) * fraction }
    }
    public mutating func duck(through deadline: Double, at now: Double) {
        duckFrom = duckGain(at: now); duckStart = now
        duckHold = max(deadline, now + 0.12)
    }
    public func duckGain(at now: Double) -> Double {
        guard let start = duckStart else { return 1 }
        let target = pow(10.0, -5.0 / 20.0)
        if now < start + 0.12 { return duckFrom + (target - duckFrom) * max(0, now - start) / 0.12 }
        if now <= duckHold { return target }
        return target + (1 - target) * min(1, (now - duckHold) / 0.75)
    }
    public mutating func cancelDuck() { duckStart = nil }
    public mutating func finish(at now: Double) {
        guard !ended else { return }
        ended = true; endStart = now
    }
    public func loopGain(at now: Double) -> Double {
        guard let start = endStart else { return 1 }
        return max(0, 1 - max(0, now - start) / 1.2)
    }
}
