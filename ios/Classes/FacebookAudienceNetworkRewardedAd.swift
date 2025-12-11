//
//  FacebookAudienceNetworkRewardedAd.swift
//  audience_network
//
//  Created by Leonardo da Silva on 18/12/21.
//

import Foundation
import Flutter
import FBAudienceNetwork

class FacebookAudienceNetworkRewardedAdPlugin: NSObject, FBRewardedVideoAdDelegate {
    let channel: FlutterMethodChannel
    private var adsById: [Int: FBRewardedVideoAd] = [:]
    private var idsByAd: [FBRewardedVideoAd: Int] = [:]
    
    init(_channel: FlutterMethodChannel) {
        print("FacebookAudienceNetworkRewardedAdPluginPlugin > init")
        
        channel = _channel
        
        super.init()
        
        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "loadRewardedAd":
                print("FacebookAudienceNetworkRewardedAdPlugin > loadRewardedAd")
                result(self.loadAd(call))
            case "showRewardedAd":
                print("FacebookAudienceNetworkRewardedAdPlugin > showRewardedAd")
                result(self.showAd(call))
            case "destroyRewardedAd":
                print("FacebookAudienceNetworkRewardedAdPlugin> destroyRewardedAd")
                result(self.destroyAd(call))
            default:
                DispatchQueue.main.async {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        print("FacebookAudienceNetworkRewardedAdPluginPlugin > init > end")
    }
    
    func loadAd(_ call: FlutterMethodCall) -> Bool {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id = args["id"] as! Int
        let placementId = args["placementId"] as! String
        let userId = args["userId"] as? String
        
        var rewardedVideoAd: FBRewardedVideoAd! = adsById[id]
        
        if rewardedVideoAd == nil || !rewardedVideoAd.isAdValid {
            print("FacebookAudienceNetworkRewardedAdPlugin > loadAd > create")
            
            rewardedVideoAd = FBRewardedVideoAd(
                placementID: placementId,
                withUserID: userId,
                withCurrency: nil)
            rewardedVideoAd.delegate = self
            adsById[id] = rewardedVideoAd
            idsByAd[rewardedVideoAd] = id
        }
        
        rewardedVideoAd.load()
        
        return true
    }
    
    func showAd(_ call: FlutterMethodCall) -> Bool {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id: Int = args["id"] as! Int
        let delay: Int = args["delay"] as! Int
        
        let rewardedVideoAd = adsById[id]!
        
        if !rewardedVideoAd.isAdValid {
            print("FacebookAudienceNetworkRewardedAdPlugin > showAd > not AdValid")
            return false
        }
        
        print("@@@ delay %d", delay)
        
        guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else {
            return false
        }
        
        func show() {
            rewardedVideoAd.show(fromRootViewController: rootViewController)
        }
        
        if 0 < delay {
            let time = DispatchTime.now() + .seconds(delay)
            DispatchQueue.main.asyncAfter(deadline: time, execute: show)
        } else {
            show()
        }
        return true
    }
    
    func destroyAd(_ call: FlutterMethodCall) -> Bool {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id: Int = args["id"] as! Int
        
        let rewardedVideoAd = adsById[id]
        
        if let rewardedVideoAd = rewardedVideoAd {
            rewardedVideoAd.delegate = nil
            adsById.removeValue(forKey: id)
            idsByAd.removeValue(forKey: rewardedVideoAd)
            return true
        }
        return false
    }
    
    func rewardedVideoAd(_ rewardedVideoAd: FBRewardedVideoAd, didFailWithError error: Error) {
        print("RewardedAdView > rewardedAd failed")
        print(error.localizedDescription)
        
        let id = idsByAd[rewardedVideoAd]!
        let errorDetails = FacebookAdErrorDetails(fromSDKError: error)
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
            FANConstant.ERROR_CODE_ARG: errorDetails?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: errorDetails?.message as Any,
        ]
        self.channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdDidLoad(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdDidLoad")
        
        let id = idsByAd[rewardedVideoAd]!
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdDidClick(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdDidClick")
        
        let id = idsByAd[rewardedVideoAd]!
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdWillLogImpression(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdWillLogImpression")
        
        let id = idsByAd[rewardedVideoAd]!
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdVideoComplete(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdComplete")
        
        let id = idsByAd[rewardedVideoAd]!
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.REWARDED_VIDEO_COMPLETE_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdDidClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdDidClose")
        
        let id = idsByAd[rewardedVideoAd]!
        let placement_id: String = rewardedVideoAd.placementID
        let invalidated: Bool = rewardedVideoAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.REWARDED_VIDEO_CLOSED_METHOD, arguments: arg)
    }
    
    func rewardedVideoAdWillClose(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdWillClose")
    }
    
    func rewardedVideoAdServerRewardDidFail(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedAdView > rewardedAdServerDidFail")
    }
    
    func rewardedVideoAdServerRewardDidSucceed(_ rewardedVideoAd: FBRewardedVideoAd) {
        print("RewardedADView > rewardedADServerDidSucceed")
    }
}
