import Foundation

/// Voluntary, in-memory observation. Time is supplied by the UI; no clock, network or identity here.
/// Reports describe only this open playtest window, never population retention.
public struct PlaytestObservation: Sendable {
    public struct Event: Codable, Equatable, Sendable {
        public let scenario: String
        public let kind: String
        public let activeSeconds: Double
        public let detail: String
    }
    public private(set) var events: [Event] = []
    private var scenario: String?
    private var started: Double?
    private var elapsed: Double = 0
    private var terminal = false
    public init() {}
    private func total(_ now: Double) -> Double { elapsed + (started.map { max(0, now - $0) } ?? 0) }
    private mutating func add(_ kind: String, at now: Double, detail: String = "") {
        guard let scenario, now.isFinite else { return }
        // Bound memory for an unattended test. Exports state the cap explicitly.
        guard events.count < 500 else { return }
        events.append(Event(scenario: scenario, kind: kind, activeSeconds: total(now), detail: detail))
    }
    public mutating func begin(_ id: String, at now: Double, retry: Bool = false) {
        guard now.isFinite else { return }
        if scenario != nil { leave(at: now, reason: retry ? "retry" : "switch") }
        scenario = id; started = now; elapsed = 0; terminal = false
        add(retry ? "retry" : "start", at: now)
    }
    public mutating func record(_ kind: String, at now: Double, detail: String = "") { add(kind, at: now, detail: detail) }
    public mutating func finish(_ result: String, at now: Double) {
        guard !terminal, now.isFinite else { return }
        add("result", at: now, detail: result); elapsed = total(now); started = nil; terminal = true
    }
    public mutating func undo(at now: Double) {
        guard now.isFinite else { return }
        add("undo", at: now)
        if terminal { terminal = false; started = now }
    }
    public mutating func pause(at now: Double) {
        guard started != nil, now.isFinite else { return }
        add("pause", at: now); elapsed = total(now); started = nil
    }
    public mutating func resume(at now: Double) {
        guard scenario != nil, started == nil, !terminal, now.isFinite else { return }
        started = now; add("resume", at: now)
    }
    public mutating func leave(at now: Double, reason: String) {
        add("leave", at: now, detail: reason)
        scenario = nil; started = nil; elapsed = 0; terminal = false
    }
    public func report() throws -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(events), as: UTF8.self)
    }
}
