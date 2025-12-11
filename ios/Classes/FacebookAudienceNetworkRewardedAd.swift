import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

@MainActor
final class FacebookAudienceNetworkRewardedAdPlugin: NSObject, FBRewardedVideoAdDelegate {

    private let channel: FlutterMethodChannel
    private var adsById: [Int: FBRewardedVideoAd] = [:]
    private var idsByAd: [FBRewardedVideoAd: Int] = [:]

    init(_channel: FlutterMethodChannel) {
        print("RewardedAdPlugin > init")

        self.channel = _channel
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            Task { @MainActor in
                self.handle(call, result: result)
            }
        }

        print("RewardedAdPlugin > ready")
    }
}

// MARK: - Handle Flutter Methods
private extension FacebookAudienceNetworkRewardedAdPlugin {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "loadRewardedAd":
            result(loadAd(call))

        case "showRewardedAd":
            result(showAd(call))

        case "destroyRewardedAd":
            result(destroyAd(call))

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Load Rewarded Ad
private extension FacebookAudienceNetworkRewardedAdPlugin {

    func loadAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let placementId = args["placementId"] as? String
        else {
            print("RewardedAd > Invalid load arguments")
            return false
        }

        let userId = args["userId"] as? String
        var rewardedAd = adsById[id]

        if rewardedAd == nil || !(rewardedAd?.isAdValid ?? false) {
            print("RewardedAd > Creating new rewarded ad")

            rewardedAd = FBRewardedVideoAd(
                placementID: placementId,
                withUserID: userId,
                withCurrency: nil
            )

            rewardedAd?.delegate = self
            adsById[id] = rewardedAd
            if let rewardedAd = rewardedAd {
                idsByAd[rewardedAd] = id
            }
        }

        rewardedAd?.load()
        return true
    }
}

// MARK: - Show Rewarded Ad
private extension FacebookAudienceNetworkRewardedAdPlugin {

    func showAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let delay = args["delay"] as? Int,
            let ad = adsById[id]
        else {
            print("RewardedAd > Invalid show arguments")
            return false
        }

        guard ad.isAdValid else {
            print("RewardedAd > showAd > not valid")
            return false
        }

        let showBlock = { @MainActor [weak self] in
            guard self != nil else { return }
            
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?
                .rootViewController
            else {
                print("RewardedAd > No root view controller")
                return
            }
            
            ad.show(fromRootViewController: rootVC)
        }

        if delay > 0 {
            Task {
                try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
                await showBlock()
            }
        } else {
            Task { await showBlock() }
        }

        return true
    }
}

// MARK: - Destroy Rewarded Ad
private extension FacebookAudienceNetworkRewardedAdPlugin {

    func destroyAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let ad = adsById[id]
        else { return false }

        ad.delegate = nil
        adsById.removeValue(forKey: id)
        idsByAd.removeValue(forKey: ad)

        return true
    }
}

// MARK: - FAN Delegate Methods
extension FacebookAudienceNetworkRewardedAdPlugin {

    nonisolated func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        Task { @MainActor in
            print("RewardedAd > Failed: \(error.localizedDescription)")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            let details = FacebookAdErrorDetails(fromSDKError: error)

            channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid,
                FANConstant.ERROR_CODE_ARG: details?.code as Any,
                FANConstant.ERROR_MESSAGE_ARG: details?.message as Any
            ])
        }
    }

    nonisolated func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > Loaded")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
            ])
        }
    }

    nonisolated func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > Clicked")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
            ])
        }
    }

    nonisolated func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > Impression")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
            ])
        }
    }

    nonisolated func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > Completed")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            channel.invokeMethod(FANConstant.REWARDED_VIDEO_COMPLETE_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
            ])
        }
    }

    nonisolated func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > Closed")

            guard let id = idsByAd[rewardedVideoAd] else { return }

            channel.invokeMethod(FANConstant.REWARDED_VIDEO_CLOSED_METHOD, arguments: [
                FANConstant.ID_ARG: id,
                FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
                FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
            ])
        }
    }

    nonisolated func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > WillClose")
        }
    }

    nonisolated func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > ServerRewardFail")
        }
    }

    nonisolated func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        Task { @MainActor in
            print("RewardedAd > ServerRewardSuccess")
        }
    }
}