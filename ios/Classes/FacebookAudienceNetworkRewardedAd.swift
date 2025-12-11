// //
// //  FacebookAudienceNetworkRewardedAd.swift
// //  audience_network
// //
// //  Created by Leonardo da Silva on 18/12/21.
// //

// import Foundation
// import Flutter
// import FBAudienceNetwork

// class FacebookAudienceNetworkRewardedAdPlugin: NSObject, FBRewardedVideoAdDelegate {
//     let channel: FlutterMethodChannel
//     private var adsById: [Int: FBRewardedVideoAd] = [:]
//     private var idsByAd: [FBRewardedVideoAd: Int] = [:]
    
//     init(_channel: FlutterMethodChannel) {
//         print("FacebookAudienceNetworkRewardedAdPluginPlugin > init")
        
//         channel = _channel
        
//         super.init()
        
//         channel.setMethodCallHandler { (call, result) in
//             switch call.method {
//             case "loadRewardedAd":
//                 print("FacebookAudienceNetworkRewardedAdPlugin > loadRewardedAd")
//                 result(self.loadAd(call))
//             case "showRewardedAd":
//                 print("FacebookAudienceNetworkRewardedAdPlugin > showRewardedAd")
//                 result(self.showAd(call))
//             case "destroyRewardedAd":
//                 print("FacebookAudienceNetworkRewardedAdPlugin> destroyRewardedAd")
//                 result(self.destroyAd(call))
//             default:
//                 DispatchQueue.main.async {
//                     result(FlutterMethodNotImplemented)
//                 }
//             }
//         }
        
//         print("FacebookAudienceNetworkRewardedAdPluginPlugin > init > end")
//     }
    
//     func loadAd(_ call: FlutterMethodCall) -> Bool {
//         let args: NSDictionary = call.arguments as! NSDictionary
//         let id = args["id"] as! Int
//         let placementId = args["placementId"] as! String
//         let userId = args["userId"] as? String
        
//         var rewardedVideoAd: FBRewardedVideoAd! = adsById[id]
        
//         if rewardedVideoAd == nil || !rewardedVideoAd.isAdValid {
//             print("FacebookAudienceNetworkRewardedAdPlugin > loadAd > create")
            
//             rewardedVideoAd = FBRewardedVideoAd(
//                 placementID: placementId,
//                 withUserID: userId,
//                 withCurrency: nil)
//             rewardedVideoAd.delegate = self
//             adsById[id] = rewardedVideoAd
//             idsByAd[rewardedVideoAd] = id
//         }
        
//         rewardedVideoAd.load()
        
//         return true
//     }
    
//     func showAd(_ call: FlutterMethodCall) -> Bool {
//         let args: NSDictionary = call.arguments as! NSDictionary
//         let id: Int = args["id"] as! Int
//         let delay: Int = args["delay"] as! Int
        
//         let rewardedVideoAd = adsById[id]!
        
//         if !rewardedVideoAd.isAdValid {
//             print("FacebookAudienceNetworkRewardedAdPlugin > showAd > not AdValid")
//             return false
//         }
        
//         print("@@@ delay %d", delay)
        
//         guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
//             return false
//         }
        
//         func show() {
//             rewardedVideoAd.show(fromRootViewController: rootViewController)
//         }
        
//         if 0 < delay {
//             let time = DispatchTime.now() + .seconds(delay)
//             DispatchQueue.main.asyncAfter(deadline: time, execute: show)
//         } else {
//             show()
//         }
//         return true
//     }
    
//     func destroyAd(_ call: FlutterMethodCall) -> Bool {
//         let args: NSDictionary = call.arguments as! NSDictionary
//         let id: Int = args["id"] as! Int
        
//         let rewardedVideoAd = adsById[id]
        
//         if let rewardedVideoAd = rewardedVideoAd {
//             rewardedVideoAd.delegate = nil
//             adsById.removeValue(forKey: id)
//             idsByAd.removeValue(forKey: rewardedVideoAd)
//             return true
//         }
//         return false
//     }
    
//     func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
//         print("RewardedAdView > rewardedAd failed")
//         print(error.localizedDescription)
        
//         let id = idsByAd[rewardedVideoAd]!
//         let errorDetails = FacebookAdErrorDetails(fromSDKError: error)
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//             FANConstant.ERROR_CODE_ARG: errorDetails?.code as Any,
//             FANConstant.ERROR_MESSAGE_ARG: errorDetails?.message as Any,
//         ]
//         self.channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdDidLoad")
        
//         let id = idsByAd[rewardedVideoAd]!
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdDidClick")
        
//         let id = idsByAd[rewardedVideoAd]!
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdWillLogImpression")
        
//         let id = idsByAd[rewardedVideoAd]!
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdComplete")
        
//         let id = idsByAd[rewardedVideoAd]!
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.REWARDED_VIDEO_COMPLETE_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdDidClose")
        
//         let id = idsByAd[rewardedVideoAd]!
//         let placement_id: String = rewardedVideoAd.placementID
//         let invalidated: Bool = rewardedVideoAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.REWARDED_VIDEO_CLOSED_METHOD, arguments: arg)
//     }
    
//     func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdWillClose")
//     }
    
//     func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedAdView > rewardedAdServerDidFail")
//     }
    
//     func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
//         print("RewardedADView > rewardedADServerDidSucceed")
//     }
// }

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
            self.handle(call, result: result)
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

        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController

        guard let rootVC else {
            print("RewardedAd > No root view controller")
            return false
        }

        let showBlock = { ad.show(fromRootViewController: rootVC) }

        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delay), execute: showBlock)
        } else {
            showBlock()
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

    func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
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

    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > Loaded")

        guard let id = idsByAd[rewardedVideoAd] else { return }

        channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
        ])
    }

    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > Clicked")

        guard let id = idsByAd[rewardedVideoAd] else { return }

        channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
        ])
    }

    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > Impression")

        guard let id = idsByAd[rewardedVideoAd] else { return }

        channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
        ])
    }

    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > Completed")

        guard let id = idsByAd[rewardedVideoAd] else { return }

        channel.invokeMethod(FANConstant.REWARDED_VIDEO_COMPLETE_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
        ])
    }

    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > Closed")

        guard let id = idsByAd[rewardedVideoAd] else { return }

        channel.invokeMethod(FANConstant.REWARDED_VIDEO_CLOSED_METHOD, arguments: [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: rewardedVideoAd.placementID,
            FANConstant.INVALIDATED_ARG: rewardedVideoAd.isAdValid
        ])
    }

    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > WillClose")
    }

    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > ServerRewardFail")
    }

    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAd > ServerRewardSuccess")
    }
}