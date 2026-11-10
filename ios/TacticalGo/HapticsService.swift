import CoreHaptics
import Foundation
import Observation
import SwiftUI
import TacticalGoMotion
import UIKit

/// The only Core Haptics owner. Match code passes a `GameHapticEvent`; this type picks the pattern,
/// honors the in-app switch, and shortens choreography when Reduce Motion is on.
///
/// Core Haptics does not observe Settings → Sounds & Haptics → System Haptics, so `isEnabled` is the
/// user control. Reduce Motion keeps the same peak and drops extra hits and rumbles.
@MainActor @Observable final class HapticsService {
    var isEnabled: Bool {
        didSet {
            defaults.set(isEnabled, forKey: HapticPreference.defaultsKey)
            if !isEnabled { stopEngine() }
        }
    }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let supportsHaptics: Bool
    @ObservationIgnored private var engine: CHHapticEngine?
    @ObservationIgnored private var sceneActive = true

    init(defaults: UserDefaults = .standard, supportsHaptics: Bool? = nil) {
        self.defaults = defaults
        let stored = defaults.object(forKey: HapticPreference.defaultsKey) as? Bool
        isEnabled = HapticPreference(storedFlag: stored).enabled
        self.supportsHaptics = supportsHaptics ?? CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    func setSceneActive(_ active: Bool) {
        sceneActive = active
        if !active { stopEngine() }
    }

    func fire(_ event: GameHapticEvent, reduceMotion: Bool = false) {
        let reduced = reduceMotion || UIAccessibility.isReduceMotionEnabled
        let gate = HapticGate(enabled: isEnabled, reduceMotion: reduced)
        guard sceneActive, let pattern = gate.pattern(for: event), supportsHaptics else { return }
        startEngineIfNeeded()
        play(pattern)
    }

    private func startEngineIfNeeded() {
        guard engine == nil else { return }
        guard let created = try? CHHapticEngine() else { return }
        created.stoppedHandler = { [weak self] _ in
            Task { @MainActor in self?.engine = nil }
        }
        created.resetHandler = { [weak self] in
            Task { @MainActor in self?.engine = nil }
        }
        engine = created
        do { try created.start() } catch { engine = nil }
    }

    private func stopEngine() {
        engine?.stop(completionHandler: nil)
        engine = nil
    }

    private func play(_ pattern: HapticPattern) {
        guard let engine else { return }
        var events: [CHHapticEvent] = pattern.transients.map { hit in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: hit.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: hit.sharpness)
            ], relativeTime: hit.time)
        }
        events += pattern.continuous.map { rumble in
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: rumble.intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: rumble.sharpness)
            ], relativeTime: rumble.time, duration: rumble.duration)
        }
        guard !events.isEmpty else { return }
        do {
            let hapticPattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: hapticPattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            self.engine = nil
        }
    }
}

struct HapticSettingsToggle: View {
    @Bindable var haptics: HapticsService
    var body: some View {
        Section("觸覺") {
            Toggle("觸覺回饋", isOn: $haptics.isEnabled).accessibilityIdentifier("hapticsEnabled")
            Text("與靜音分開。降低動態時仍保留同一強度的短震，並拿掉連續震動。系統觸覺開關不會作用於這組回饋，請用這個開關。")
                .font(.footnote)
        }
    }
}
