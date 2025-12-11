import Foundation
import Flutter
import FBAudienceNetwork

class FacebookAudienceNetworkInterstitialAdPlugin: NSObject, FBInterstitialAdDelegate {
    let channel: FlutterMethodChannel
    private var adsById: [Int: FBInterstitialAd] = [:]
    private var idsByAd: [FBInterstitialAd: Int] = [:]
    
    init(_channel: FlutterMethodChannel) {
        print("FacebookAudienceNetworkInterstitialAdPlugin > init")
        
        channel = _channel
        
        super.init()
        
        channel.setMethodCallHandler { (call, result) in
            switch call.method{
            case "loadInterstitialAd":
                print("FacebookAudienceNetworkInterstitialAdPlugin > loadInterstitialAd")
                result(self.loadAd(call))
            case "showInterstitialAd":
                print("FacebookAudienceNetworkInterstitialAdPlugin > showInterstitialAd")
                result(self.showAD(call))
            case "destroyInterstitialAd":
                print("FacebookAudienceNetworkInterstitialAdPlugin > destroyInterstitialAd")
                result(self.destroyAd(call))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        print("FacebookAudienceNetworkInterstitialAdPlugin > init > end")
    }
    
    
    func loadAd(_ call: FlutterMethodCall) -> Bool {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id = args["id"] as! Int
        let placementId = args["placementId"] as! String
        
        var interstitialAd: FBInterstitialAd! = adsById[id]
        
        if interstitialAd == nil || !interstitialAd.isAdValid {
            print("FacebookAudienceNetworkInterstitialAdPlugin > loadAd > create")
            
            interstitialAd = FBInterstitialAd.init(placementID: placementId)
            interstitialAd.delegate = self
            adsById[id] = interstitialAd
            idsByAd[interstitialAd] = id
        }
        
        interstitialAd.load()
        
        return true
    }
    
    func showAD(_ call: FlutterMethodCall) -> Bool {
        let args: NSDictionary = call.arguments as! NSDictionary
        let id: Int = args["id"] as! Int
        let delay: Int = args["delay"] as! Int
        
        let interstitialAd = adsById[id]!
        
        if !interstitialAd.isAdValid {
            print("FacebookAudienceNetworkInterstitialAdPlugin > showAD > not AdVaild")
            return false
        }
        
        
        print("@@@ delay %d", delay)
        
        func show() {
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController
            interstitialAd.show(fromRootViewController: rootViewController)
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
        
        let interstitialAd = adsById[id]
        
        if let interstitialAd = interstitialAd {
            interstitialAd.delegate = nil
            adsById.removeValue(forKey: id)
            idsByAd.removeValue(forKey: interstitialAd)
            return true
        }
        return false
    }
    
    
    /**
     Sent after an ad in the FBInterstitialAd object is clicked. The appropriate app store view or
     app browser will be launched.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     */
    func interstitialAdDidClick(_ interstitialAd: FBInterstitialAd) {
        print("InterstitialAdView > interstitialAdDidClick")
        
        let id = idsByAd[interstitialAd]!
        let placement_id: String = interstitialAd.placementID
        let invalidated: Bool = interstitialAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: arg)
    }
    
    /**
     Sent after an FBInterstitialAd object has been dismissed from the screen, returning control
     to your application.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     */
    func interstitialAdDidClose(_ interstitialAd: FBInterstitialAd) {
        print("InterstitialAdView > interstitialAdDidClose")
        
        let id = idsByAd[interstitialAd]!
        let placement_id: String = interstitialAd.placementID
        let invalidated: Bool = interstitialAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.DISMISSED_METHOD, arguments: arg)
    }
    
    /**
     Sent immediately before an FBInterstitialAd object will be dismissed from the screen.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     */
    func interstitialAdWillClose(_ interstitialAd: FBInterstitialAd) {
        print("InterstitialAdView > interstitialAdWillClose")
    }
    
    /**
     Sent when an FBInterstitialAd successfully loads an ad.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     */
    func interstitialAdDidLoad(_ interstitialAd: FBInterstitialAd) {
        print("InterstitialAdView > interstitialAdDidLoad")
        
        let id = idsByAd[interstitialAd]!
        let placement_id: String = interstitialAd.placementID
        let invalidated: Bool = interstitialAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
    }
    
    /**
     Sent when an FBInterstitialAd failes to load an ad.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     @param error An error object containing details of the error.
     */
    func interstitialAd(_ interstitialAd :FBInterstitialAd, didFailWithError error: Error) {
        print("InterstitialAdView > interstitialAd failed")
        print(error.localizedDescription)
        
        let id = idsByAd[interstitialAd]!
        let errorDetails = FacebookAdErrorDetails(fromSDKError: error)
        let placement_id: String = interstitialAd.placementID
        let invalidated: Bool = interstitialAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
            FANConstant.ERROR_CODE_ARG: errorDetails?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: errorDetails?.message as Any,
        ]
        self.channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: arg)
    }
    
    /**
     Sent immediately before the impression of an FBInterstitialAd object will be logged.
     
     @param interstitialAd An FBInterstitialAd object sending the message.
     */
    func interstitialAdWillLogImpression(_ interstitialAd: FBInterstitialAd) {
        print("InterstitialAdView > interstitialAdWillLogImpression")
        
        let id = idsByAd[interstitialAd]!
        let placement_id: String = interstitialAd.placementID
        let invalidated: Bool = interstitialAd.isAdValid
        let arg: [String: Any] = [
            FANConstant.ID_ARG: id,
            FANConstant.PLACEMENT_ID_ARG: placement_id,
            FANConstant.INVALIDATED_ARG: invalidated,
        ]
        self.channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: arg)
    }
}
