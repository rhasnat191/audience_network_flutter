// import Foundation
// import Flutter
// import FBAudienceNetwork

// class FacebookAudienceNetworkInterstitialAdPlugin: NSObject, FBInterstitialAdDelegate {
//     let channel: FlutterMethodChannel
//     private var adsById: [Int: FBInterstitialAd] = [:]
//     private var idsByAd: [FBInterstitialAd: Int] = [:]
    
//     init(_channel: FlutterMethodChannel) {
//         print("FacebookAudienceNetworkInterstitialAdPlugin > init")
        
//         channel = _channel
        
//         super.init()
        
//         channel.setMethodCallHandler { (call, result) in
//             switch call.method{
//             case "loadInterstitialAd":
//                 print("FacebookAudienceNetworkInterstitialAdPlugin > loadInterstitialAd")
//                 result(self.loadAd(call))
//             case "showInterstitialAd":
//                 print("FacebookAudienceNetworkInterstitialAdPlugin > showInterstitialAd")
//                 result(self.showAD(call))
//             case "destroyInterstitialAd":
//                 print("FacebookAudienceNetworkInterstitialAdPlugin > destroyInterstitialAd")
//                 result(self.destroyAd(call))
//             default:
//                 DispatchQueue.main.async {
//                     result(FlutterMethodNotImplemented)
//                 }
//             }
//         }
        
//         print("FacebookAudienceNetworkInterstitialAdPlugin > init > end")
//     }
    
    
//     func loadAd(_ call: FlutterMethodCall) -> Bool {
//         let args: NSDictionary = call.arguments as! NSDictionary
//         let id = args["id"] as! Int
//         let placementId = args["placementId"] as! String
        
//         var interstitialAd: FBInterstitialAd! = adsById[id]
        
//         if interstitialAd == nil || !interstitialAd.isAdValid {
//             print("FacebookAudienceNetworkInterstitialAdPlugin > loadAd > create")
            
//             interstitialAd = FBInterstitialAd.init(placementID: placementId)
//             interstitialAd.delegate = self
//             adsById[id] = interstitialAd
//             idsByAd[interstitialAd] = id
//         }
        
//         interstitialAd.load()
        
//         return true
//     }
    
//     func showAD(_ call: FlutterMethodCall) -> Bool {
//         let args: NSDictionary = call.arguments as! NSDictionary
//         let id: Int = args["id"] as! Int
//         let delay: Int = args["delay"] as! Int
        
//         let interstitialAd = adsById[id]!
        
//         if !interstitialAd.isAdValid {
//             print("FacebookAudienceNetworkInterstitialAdPlugin > showAD > not AdVaild")
//             return false
//         }
        
        
//         print("@@@ delay %d", delay)
        
//         func show() {
//             let rootViewController = UIApplication.shared.keyWindow?.rootViewController
//             interstitialAd.show(fromRootViewController: rootViewController)
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
        
//         let interstitialAd = adsById[id]
        
//         if let interstitialAd = interstitialAd {
//             interstitialAd.delegate = nil
//             adsById.removeValue(forKey: id)
//             idsByAd.removeValue(forKey: interstitialAd)
//             return true
//         }
//         return false
//     }
    
    
//     /**
//      Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or
//      app browser will be launched.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      */
//     func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
//         print("InterstitialAdView > interstitialAdDidClick")
        
//         let id = idsByAd[interstitialAd]!
//         let placement_id: String = interstitialAd.placementID
//         let invalidated: Bool = interstitialAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: arg)
//     }
    
//     /**
//      Sent after an FBInterstitialAd object has been dismissed from the screen, returning control
//      to your application.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      */
//     func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
//         print("InterstitialAdView > interstitialAdDidClose")
        
//         let id = idsByAd[interstitialAd]!
//         let placement_id: String = interstitialAd.placementID
//         let invalidated: Bool = interstitialAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.DISMISSED_METHOD, arguments: arg)
//     }
    
//     /**
//      Sent immediately before an FBInterstitialAd object will be dismissed from the screen.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      */
//     func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
//         print("InterstitialAdView > interstitialAdWillClose")
//     }
    
//     /**
//      Sent when an FBInterstitialAd successfully loads an ad.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      */
//     func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
//         print("InterstitialAdView > interstitialAdDidLoad")
        
//         let id = idsByAd[interstitialAd]!
//         let placement_id: String = interstitialAd.placementID
//         let invalidated: Bool = interstitialAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
//     }
    
//     /**
//      Sent when an FBInterstitialAd failes to load an ad.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      @param error An error object containing details of the error.
//      */
//     func interstitialAd(_ interstitialAd :FBInterstitialAd, didFailWithError error: Error) {
//         print("InterstitialAdView > interstitialAd failed")
//         print(error.localizedDescription)
        
//         let id = idsByAd[interstitialAd]!
//         let errorDetails = FacebookAdErrorDetails(fromSDKError: error)
//         let placement_id: String = interstitialAd.placementID
//         let invalidated: Bool = interstitialAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//             FANConstant.ERROR_CODE_ARG: errorDetails?.code as Any,
//             FANConstant.ERROR_MESSAGE_ARG: errorDetails?.message as Any,
//         ]
//         self.channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: arg)
//     }
    
//     /**
//      Sent immediately before the impression of an FBInterstitialAd object will be logged.
     
//      @param interstitialAd An FBInterstitialAd object sending the message.
//      */
//     func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
//         print("InterstitialAdView > interstitialAdWillLogImpression")
        
//         let id = idsByAd[interstitialAd]!
//         let placement_id: String = interstitialAd.placementID
//         let invalidated: Bool = interstitialAd.isAdValid
//         let arg: [String: Any] = [
//             FANConstant.ID_ARG: id,
//             FANConstant.PLACEMENT_ID_ARG: placement_id,
//             FANConstant.INVALIDATED_ARG: invalidated,
//         ]
//         self.channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: arg)
//     }
// }

import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

@MainActor
final class FacebookAudienceNetworkInterstitialAdPlugin: NSObject, FBInterstitialAdDelegate {

    private let channel: FlutterMethodChannel
    private var adsById: [Int: FBInterstitialAd] = [:]
    private var idsByAd: [FBInterstitialAd: Int] = [:]

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

@MainActor
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

@MainActor
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

@MainActor
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

@MainActor
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