import Foundation

/// Rendering/input and audio tails have separate ends. No clock, callback or game mutation.
public struct ExpansionPlaybackWindow: Equatable, Sendable {
    public let visualEnd: Double, inputEnd: Double, audioEnd: Double
    public static func make(visualEnd: Double, lastSoundEnd: Double, terminal: Bool, endingTail: Double = 0) -> Self {
        guard visualEnd.isFinite,lastSoundEnd.isFinite,endingTail.isFinite,
              visualEnd >= 0,lastSoundEnd >= 0,endingTail >= 0 else { return .init(visualEnd:0,inputEnd:0,audioEnd:0) }
        let audioEnd = max(visualEnd+endingTail,lastSoundEnd)
        guard audioEnd.isFinite else { return .init(visualEnd:0,inputEnd:0,audioEnd:0) }
        return .init(visualEnd:visualEnd,inputEnd:terminal ? audioEnd:visualEnd,audioEnd:audioEnd)
    }
}
