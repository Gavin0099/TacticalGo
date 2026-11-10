import CoreHaptics
import SwiftUI
import TacticalGoMotion
import UIKit

/// The only type that calls UIKit or Core Haptics. Game events enter as `HapticImpulse` values.
@MainActor @Observable final class GameHaptics {
    static let shared = GameHaptics()
    private let defaults: UserDefaults
    var enabled: Bool {
        didSet { defaults.set(enabled, forKey: HapticPreference.storageKey) }
    }
    @ObservationIgnored private var generation: UInt64 = 0
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private let soft = UIImpactFeedbackGenerator(style: .soft)
    @ObservationIgnored private let light = UIImpactFeedbackGenerator(style: .light)
    @ObservationIgnored private let medium = UIImpactFeedbackGenerator(style: .medium)
    @ObservationIgnored private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    @ObservationIgnored private let notify = UINotificationFeedbackGenerator()

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        enabled = HapticPreference(stored: defaults.object(forKey: HapticPreference.storageKey)).enabled
    }

    func schedule(_ impulses: [HapticImpulse]) {
        cancel()
        // System Haptics remains enforced by UIFeedbackGenerator. Hardware support is checked here.
        let gate = HapticGate(enabled: enabled, hardwareSupported: Self.hardwareSupported, systemHapticsEnabled: true)
        let playback = HapticPlayback.audible(impulses, gate: gate)
        guard !playback.isEmpty else { return }
        let token = generation
        let started = ProcessInfo.processInfo.systemUptime
        task = Task { @MainActor [weak self] in
            for impulse in playback {
                let delay = started + impulse.at - ProcessInfo.processInfo.systemUptime
                if delay > 0 {
                    do { try await Task.sleep(for: .seconds(delay)) } catch { return }
                }
                guard let self, self.generation == token, self.enabled, !Task.isCancelled else { return }
                self.fire(impulse)
            }
        }
    }

    func cancel() {
        generation &+= 1
        task?.cancel()
        task = nil
    }

    private func fire(_ impulse: HapticImpulse) {
        let intensity = CGFloat(impulse.intensity)
        switch impulse.feel {
        case .soft:
            soft.prepare(); soft.impactOccurred(intensity: intensity)
        case .light:
            light.prepare(); light.impactOccurred(intensity: intensity)
        case .medium:
            medium.prepare(); medium.impactOccurred(intensity: intensity)
        case .heavy:
            heavy.prepare(); heavy.impactOccurred(intensity: intensity)
        case .success:
            notify.prepare(); notify.notificationOccurred(.success)
        case .error:
            notify.prepare(); notify.notificationOccurred(.error)
        }
    }

    private static var hardwareSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
}

struct HapticSettingsToggle: View {
    @State private var enabled = GameHaptics.shared.enabled
    var body: some View {
        Toggle("觸覺回饋", isOn: $enabled)
            .accessibilityIdentifier("hapticsEnabled")
            .onChange(of: enabled) { _, value in GameHaptics.shared.enabled = value }
        Text("預設開啟。系統關閉觸覺時不會震動。減少動態時，放置與接觸減輕，連鎖改為一下；擊殺與勝負仍各一下。")
            .font(.caption)
    }
}
