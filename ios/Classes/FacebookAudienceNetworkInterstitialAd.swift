import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

final class FacebookAudienceNetworkInterstitialAdPlugin: NSObject, FBInterstitialAdDelegate {

    private let channel: FlutterMethodChannel
    private var adsById: [Int: FBInterstitialAd] = [:]
    private var idsByAd: [FBInterstitialAd: Int] = [:]

    @MainActor
    init(_channel: FlutterMethodChannel) {
        print("InterstitialPlugin > init")

        self.channel = _channel
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            self.handle(call, result: result)
        }

        print("InterstitialPlugin > ready")
    }
}

// MARK: - Flutter Call Handler

@MainActor
private extension FacebookAudienceNetworkInterstitialAdPlugin {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        switch call.method {

        case "loadInterstitialAd":
            result(loadAd(call))

        case "showInterstitialAd":
            result(showAd(call))

        case "destroyInterstitialAd":
            result(destroyAd(call))

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Load Interstitial
private extension FacebookAudienceNetworkInterstitialAdPlugin {

    func loadAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let placementId = args["placementId"] as? String
        else {
            print("InterstitialPlugin > loadAd > invalid args")
            return false
        }

        let interstitial = adsById[id]

        if interstitial == nil || !(interstitial?.isAdValid ?? false) {
            print("InterstitialPlugin > loadAd > creating new ad")

            let newAd = FBInterstitialAd(placementID: placementId)
            newAd.delegate = self

            adsById[id] = newAd
            idsByAd[newAd] = id

            newAd.load()
        } else {
            print("InterstitialPlugin > loadAd > already loaded or valid")
            interstitial?.load()
        }

        return true
    }
}

// MARK: - Show Ad
private extension FacebookAudienceNetworkInterstitialAdPlugin {

    func showAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let delay = args["delay"] as? Int,
            let ad = adsById[id]
        else {
            print("InterstitialPlugin > showAd > invalid args")
            return false
        }

        guard ad.isAdValid else {
            print("InterstitialPlugin > showAd > ad not valid")
            return false
        }

        let show = {
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else {

                print("InterstitialPlugin > showAd > no rootViewController")
                return
            }

            ad.show(fromRootViewController: rootVC)
        }

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: show)
        } else {
            show()
        }

        return true
    }
}

// MARK: - Destroy
private extension FacebookAudienceNetworkInterstitialAdPlugin {

    func destroyAd(_ call: FlutterMethodCall) -> Bool {
        guard
            let args = call.arguments as? [String: Any],
            let id = args["id"] as? Int,
            let ad = adsById[id]
        else {
            return false
        }

        ad.delegate = nil
        adsById.removeValue(forKey: id)
        idsByAd.removeValue(forKey: ad)

        print("InterstitialPlugin > destroyAd > destroyed")
        return true
    }
}

// MARK: - Delegate Callbacks
extension FacebookAudienceNetworkInterstitialAdPlugin {

    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        print("Interstitial > didClick")

        guard let id = idsByAd[interstitialAd] else { return }

        channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: interstitialAd.placementID,
            FANConstant.INVALIDATED_ARG: interstitialAd.isAdValid
        ])
    }

    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        print("Interstitial > didClose")

        guard let id = idsByAd[interstitialAd] else { return }

        channel.invokeMethod(FANConstant.DISMISSED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: interstitialAd.placementID,
            FANConstant.INVALIDATED_ARG: interstitialAd.isAdValid
        ])
    }

    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        print("Interstitial > didLoad")

        guard let id = idsByAd[interstitialAd] else { return }

        channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: interstitialAd.placementID,
            FANConstant.INVALIDATED_ARG: interstitialAd.isAdValid
        ])
    }

    func interstitialAd(_ interstitialAd: FBInterstitialAd, didFailWithError error: Error) {
        print("Interstitial > failed: \(error.localizedDescription)")

        guard let id = idsByAd[interstitialAd] else { return }

        let details = FacebookAdErrorDetails(fromSDKError: error)

        channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: interstitialAd.placementID,
            FANConstant.INVALIDATED_ARG: interstitialAd.isAdValid,
            FANConstant.ERROR_CODE_ARG: details?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: details?.message as Any
        ])
    }

    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        print("Interstitial > willLogImpression")

        guard let id = idsByAd[interstitialAd] else { return }

        channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: interstitialAd.placementID,
            FANConstant.INVALIDATED_ARG: interstitialAd.isAdValid
        ])
    }
}