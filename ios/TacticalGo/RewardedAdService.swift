import Combine
import UIKit
@preconcurrency import GoogleMobileAds
@preconcurrency import UserMessagingPlatform

/// The SDK completion is the only reward source. This service never changes a game state.
@MainActor
final class RewardedAdService: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = RewardedAdService()

    enum Status: Equatable {
        case idle, consent, loading, presenting, interrupted, privacyOptions
    }

    enum Result: Equatable, Sendable {
        case earned(UUID)
        case dismissedWithoutReward
        case cancelled
        case unavailable(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var isBusy = false
    @Published private(set) var isPresentingSDKContent = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var lastError: String?
    @Published private(set) var lastSDKErrorCode: String?

    var isConfigured: Bool { configuredAdUnitID != nil }
    var isTestConfiguration: Bool {
        #if DEBUG
        return Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
            == Self.testApplicationID
        #else
        return false
        #endif
    }

    private static let testApplicationID = "ca-app-pub-3940256099942544~1458002511"
    private static let testRewardedUnitID = "ca-app-pub-3940256099942544/1712485313"

    private var configuredAdUnitID: String? {
        let appID = Bundle.main.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String ?? ""
        #if DEBUG
        // A Debug build must also have Google's sample application ID explicitly in its plist.
        if appID == Self.testApplicationID { return Self.testRewardedUnitID }
        #endif
        let unitID = Bundle.main.object(forInfoDictionaryKey: "CrownTacticsRewardedAdUnitID") as? String ?? ""
        guard appID.range(of: #"^ca-app-pub-[0-9]{16}~[0-9]{10}$"#, options: .regularExpression) != nil,
              unitID.range(of: #"^ca-app-pub-[0-9]{16}/[0-9]{10}$"#, options: .regularExpression) != nil,
              !appID.contains("3940256099942544"), !unitID.contains("3940256099942544") else { return nil }
        return unitID
    }

    @MainActor
    private final class Attempt {
        let id: UUID
        let grant: @MainActor (UUID) throws -> Void
        let presentationChanged: @MainActor (Bool) -> Void
        var continuation: CheckedContinuation<Result, Never>?
        var rewardCallbackHandled = false
        var earnedID: UUID?
        var rewardSaveFailed = false

        init(id: UUID, grant: @escaping @MainActor (UUID) throws -> Void,
             presentationChanged: @escaping @MainActor (Bool) -> Void,
             continuation: CheckedContinuation<Result, Never>) {
            self.id = id
            self.grant = grant
            self.presentationChanged = presentationChanged
            self.continuation = continuation
        }
    }

    private var attempt: Attempt?
    private var preparingID: UUID?
    private var privacyRefreshID: UUID?
    private var preparingTask: Task<Void, Never>?
    private var presentationID: UUID?
    private var presentationChanged: (@MainActor (Bool) -> Void)?
    private var needsAudioRestore = false
    private var rewardedAd: RewardedAd?
    private var startedSDK = false

    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    /// Invoke only after the user explicitly selects “watch an ad for one game”.
    /// The grant closure must atomically persist the unique reward ID and throw if saving fails.
    /// An earned result returns after dismissal, so a new game cannot open underneath the ad.
    func watchForOneMatch(
        onEarnedReward: @escaping @MainActor (UUID) throws -> Void,
        onPresentationChanged: @escaping @MainActor (Bool) -> Void
    ) async -> Result {
        guard !isBusy else { return .unavailable("上一段廣告仍在處理，請稍候。") }
        guard let unitID = configuredAdUnitID else {
            return fail("廣告尚未設定，請稍後再試；你仍可續玩已開始的棋局。")
        }
        guard UIApplication.shared.applicationState == .active else { return .cancelled }
        let id = UUID()
        lastError = nil
        lastSDKErrorCode = nil
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                attempt = Attempt(id: id, grant: onEarnedReward,
                                  presentationChanged: onPresentationChanged, continuation: continuation)
                preparingID = id
                status = .consent
                updateBusy()
                preparingTask = Task { [weak self] in await self?.prepareAndPresent(id: id, unitID: unitID) }
            }
        } onCancel: {
            Task { @MainActor [weak self] in self?.cancelPendingRequest(id: id) }
        }
    }

    /// Safe on paywall exit, a purchase completing, a new navigation context, or scene background.
    /// SDK-owned screens must close through their own UI; they are never forcibly dismissed.
    func cancelPendingRequest() {
        if let id = attempt?.id { cancelPendingRequest(id: id) }
        // Keep the uncancellable SDK update in the busy gate until its callback returns,
        // but reject that callback's old navigation context after exit/background.
        privacyRefreshID = nil
    }

    private func cancelPendingRequest(id: UUID) {
        guard let current = attempt, current.id == id else { return }
        attempt = nil
        preparingTask?.cancel()
        current.continuation?.resume(returning: .cancelled)
        current.continuation = nil
        // A reward already saved by the SDK callback remains owned by the player.
        status = presentationID == nil ? .idle : .interrupted
        updateBusy()
    }

    private func isCurrent(_ id: UUID) -> Bool {
        attempt?.id == id && !Task.isCancelled
            && UIApplication.shared.applicationState == .active
    }

    private func prepareAndPresent(id: UUID, unitID: String) async {
        defer {
            if preparingID == id { preparingID = nil; preparingTask = nil }
            updateBusy()
        }
        do {
            let parameters = RequestParameters()
            // UMP owns the consent state. No local cached-consent boolean is trusted.
            let consentError: Error? = await withCheckedContinuation { continuation in
                ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                    continuation.resume(returning: error)
                }
            }
            guard isCurrent(id) else { return }
            refreshPrivacyOptions()
            if let consentError {
                recordSDKError(consentError)
                guard ConsentInformation.shared.canRequestAds else {
                    finish(id: id, result: fail("無法確認廣告隱私選擇，請連線後重試。"))
                    return
                }
            } else if ConsentInformation.shared.consentStatus == .required {
                do {
                    // Match UMP's official required-form condition, but keep loading separate:
                    // the user may exit while there is still no SDK screen to dismiss.
                    let form = try await ConsentForm.load()
                    guard isCurrent(id), let current = attempt else { return }
                    beginPresentation(id: id, changed: current.presentationChanged)
                    try await form.present(from: nil)
                }
                catch {
                    recordSDKError(error)
                    if !ConsentInformation.shared.canRequestAds {
                        endPresentation(id: id)
                        finish(id: id, result: fail("目前無法播放廣告。你可以調整隱私選擇或稍後再試。"))
                        return
                    }
                }
                endPresentation(id: id)
            }
            guard isCurrent(id) else { return }
            refreshPrivacyOptions()
            guard ConsentInformation.shared.canRequestAds else {
                finish(id: id, result: fail("目前無法播放廣告。你可以調整隱私選擇或稍後再試。"))
                return
            }
            status = .loading
            if !startedSDK {
                // Prefer non-personalized requests, without requesting ATT or using a publisher ID.
                // This does not mean that the SDK collects no data.
                MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
                MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
                _ = await MobileAds.shared.start()
                startedSDK = true
            }
            guard isCurrent(id) else { return }
            // PPT disables personalization, but is not the same signal as Google's NPA mode.
            // Also send an explicit NPA request, as Google's iOS Flutter adapter does.
            // Neither flag proves that the SDK or served creative collects/tracks no data.
            let request = Request()
            let extras = Extras()
            extras.additionalParameters = ["npa": "1"]
            request.register(extras)
            let loadedAd = try await RewardedAd.load(with: unitID, request: request)
            guard isCurrent(id), let current = attempt else { return }
            try loadedAd.canPresent(from: nil)
            rewardedAd = loadedAd
            loadedAd.fullScreenContentDelegate = self
            beginPresentation(id: id, changed: current.presentationChanged)
            status = .presenting
            loadedAd.present(from: nil) { [weak self] in self?.earnedReward(id: id) }
        } catch {
            guard attempt?.id == id else { return }
            recordSDKError(error)
            endPresentation(id: id)
            rewardedAd = nil
            finish(id: id, result: fail("廣告暫時無法載入或播放，請確認連線後再試。"))
        }
    }

    private func earnedReward(id: UUID) {
        guard let current = attempt, current.id == id,
              presentationID == id, !current.rewardCallbackHandled else { return }
        current.rewardCallbackHandled = true
        do {
            try current.grant(id)
            current.earnedID = id
        } catch {
            current.rewardSaveFailed = true
            recordSDKError(error)
            lastError = "廣告已完成，但遊玩額度未能保存。請保留此畫面並稍後重試。"
        }
    }

    private func finish(id: UUID, result: Result) {
        guard let current = attempt, current.id == id else { return }
        attempt = nil
        current.continuation?.resume(returning: result)
        current.continuation = nil
        status = presentationID == nil ? .idle : .interrupted
        updateBusy()
    }

    private func beginPresentation(id: UUID, changed: @escaping @MainActor (Bool) -> Void) {
        presentationID = id
        presentationChanged = changed
        needsAudioRestore = true
        changed(true)
        updateBusy()
    }

    private func endPresentation(id: UUID) {
        guard presentationID == id else { return }
        presentationID = nil
        restoreAudioIfSafe()
        if attempt == nil { status = .idle }
        updateBusy()
    }

    private func restoreAudioIfSafe() {
        guard presentationID == nil, needsAudioRestore,
              UIApplication.shared.applicationState == .active else { return }
        needsAudioRestore = false
        presentationChanged?(false)
        presentationChanged = nil
    }

    private func updateBusy() {
        isBusy = attempt != nil || preparingID != nil || presentationID != nil
        isPresentingSDKContent = presentationID != nil
    }

    private func fail(_ message: String) -> Result {
        lastError = message
        return .unavailable(message)
    }

    private func recordSDKError(_ error: Error) {
        let value = error as NSError
        // Avoid recording network URLs, ad response identifiers, or personal data.
        lastSDKErrorCode = "\(value.domain):\(value.code)"
    }

    private func refreshPrivacyOptions() {
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    /// Only call after the user explicitly chooses to inspect/manage advertising privacy.
    /// nil means refreshed; a nonnil message explains failure/cancellation to the caller.
    /// This does not initialize MobileAds, load an ad, or present a consent form.
    func refreshPrivacyChoices() async -> String? {
        guard !isBusy else { return "上一個廣告或隱私請求仍在處理，請稍候。" }
        guard !Task.isCancelled, UIApplication.shared.applicationState == .active else {
            return "已中止隱私選擇更新；你可以重新開啟管理。"
        }
        let id = UUID()
        preparingID = id
        privacyRefreshID = id
        status = .consent
        lastError = nil
        lastSDKErrorCode = nil
        updateBusy()
        defer {
            if preparingID == id { preparingID = nil }
            if privacyRefreshID == id { privacyRefreshID = nil }
            status = .idle
            updateBusy()
        }
        return await withTaskCancellationHandler {
            let error: Error? = await withCheckedContinuation { continuation in
                ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters()) { error in
                    continuation.resume(returning: error)
                }
            }
            guard privacyRefreshID == id, !Task.isCancelled,
                  UIApplication.shared.applicationState == .active else {
                return "已中止隱私選擇更新；你可以重新開啟管理。"
            }
            // Always query the SDK after an actual update attempt, never our own saved consent.
            refreshPrivacyOptions()
            if let error {
                recordSDKError(error)
                lastError = "無法更新廣告隱私選擇。請確認連線與廣告設定後重試。"
                return lastError
            }
            return nil
        } onCancel: {
            Task { @MainActor [weak self] in
                if self?.privacyRefreshID == id { self?.privacyRefreshID = nil }
            }
        }
    }

    /// Expose a visible settings entry when privacyOptionsRequired is true.
    func presentPrivacyOptions(onPresentationChanged: @escaping @MainActor (Bool) -> Void) async {
        // Managing an existing consent choice does not require a rewarded ad unit ID.
        guard !isBusy, privacyOptionsRequired,
              UIApplication.shared.applicationState == .active else { return }
        let id = UUID()
        preparingID = id
        status = .privacyOptions
        beginPresentation(id: id, changed: onPresentationChanged)
        defer {
            endPresentation(id: id)
            if preparingID == id { preparingID = nil }
            status = .idle
            updateBusy()
        }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            refreshPrivacyOptions()
        } catch {
            recordSDKError(error)
            lastError = "隱私選擇暫時無法開啟，請稍後重試。"
        }
    }

    @objc private func didEnterBackground() { cancelPendingRequest() }

    @objc private func didBecomeActive() { restoreAudioIfSafe() }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        guard let currentAd = rewardedAd, (ad as AnyObject) === currentAd,
              let id = presentationID else { return }
        rewardedAd = nil
        let result: Result
        if let current = attempt, current.id == id, current.rewardSaveFailed {
            result = .unavailable(lastError ?? "遊玩額度未能保存。")
        } else if let earned = attempt?.earnedID {
            result = .earned(earned)
        } else { result = .dismissedWithoutReward }
        endPresentation(id: id)
        finish(id: id, result: result)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        guard let currentAd = rewardedAd, (ad as AnyObject) === currentAd,
              let id = presentationID else { return }
        recordSDKError(error)
        rewardedAd = nil
        endPresentation(id: id)
        finish(id: id, result: fail("廣告未能播放；沒有扣除遊玩額度。"))
    }
}
