import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

// MARK: - Banner Ad Factory

final class FacebookAudienceNetworkBannerAdFactory: NSObject, FlutterPlatformViewFactory {

    private unowned let registrar: FlutterPluginRegistrar

    init(_registrar: FlutterPluginRegistrar) {
        print("FAN > BannerAdFactory > register")
        self.registrar = _registrar
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        print("FAN > BannerAdFactory > createArgsCodec")
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {
        print("FAN > BannerAdFactory > create view")
        return FacebookAudienceNetworkBannerAdView(
            frame: frame,
            viewId: viewId,
            params: args as? [String: Any],
            registrar: registrar
        )
    }
}


// MARK: - Banner Ad View

final class FacebookAudienceNetworkBannerAdView: NSObject,
                                                 FlutterPlatformView,
                                                 FBAdViewDelegate {

    private let frame: CGRect
    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let params: [String: Any]
    // private let channel: FlutterMethodChannel
    private lazy var channel: FlutterMethodChannel = {
        FlutterMethodChannel(
            name: "\(FANConstant.BANNER_AD_CHANNEL)_\(viewId)",
            binaryMessenger: registrar.messenger()
        )
    }()
    private lazy var mainView: UIView = {
        UIView()
    }()
    private var bannerAd: FBAdView?

    init(frame: CGRect,
         viewId: Int64,
         params: [String: Any]?,
         registrar: FlutterPluginRegistrar) {

        print("FAN > BannerAdView > init")

        self.frame = frame
        self.viewId = viewId
        self.registrar = registrar
        self.params = params ?? [:]

        self.channel = FlutterMethodChannel(
            name: "\(FANConstant.BANNER_AD_CHANNEL)_\(viewId)",
            binaryMessenger: registrar.messenger()
        )

        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        setupView()
        setupFacebookAd()
    }

    deinit {
        print("FAN > BannerAdView > deinit")
    }

    func view() -> UIView {
        mainView
    }
}


// MARK: - Method Handling

extension FacebookAudienceNetworkBannerAdView {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialization":
            result(true)

        case "init":
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}


// MARK: - View Init

private extension FacebookAudienceNetworkBannerAdView {

    func setupView() {
        print("BannerAdView > setupView")
        mainView = UIView(frame: frame)
        mainView.backgroundColor = .white
    }

    func setupFacebookAd() {
        print("FAN > BannerAdView > setupFacebookAd")

        let isBanner = params["banner_ad"] as? Bool ?? false

        if isBanner {
            // TODO: Native banner logic if needed
        } else {
            initializeBannerAd()
        }
    }
}


// MARK: - Banner Ad Init

private extension FacebookAudienceNetworkBannerAdView {

    func initializeBannerAd() {
        print("FAN > BannerAdView > initializeBannerAd")

        guard let placementId = params["id"] as? String else {
            print("FAN > BannerAdView > Missing 'id' param")
            return
        }

        let height = params["height"] as? CGFloat ?? 50.0
        let adSize: FBAdSize

        switch height {
        case 250...:
            adSize = kFBAdSizeHeight250Rectangle

        case 90...:
            adSize = kFBAdSizeHeight90Banner

        default:
            adSize = kFBAdSizeHeight50Banner
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {

            print("FAN > BannerAdView > rootViewController not found")
            return
        }

        let adView = FBAdView(placementID: placementId,
                              adSize: adSize,
                              rootViewController: rootVC)

        self.bannerAd = adView
        adView?.delegate = self
        adView?.loadAd()
    }
}


// MARK: - Banner Rendering

private extension FacebookAudienceNetworkBannerAdView {

    func addBannerToView() {
        guard let bannerAd else { return }

        print("FAN > BannerAdView > addBannerToView")

        bannerAd.frame = CGRect(
            x: 0,
            y: 0,
            width: mainView.frame.width,
            height: bannerAd.frame.height
        )

        mainView.addSubview(bannerAd)
        mainView.layoutIfNeeded()
    }
}


// MARK: - FBAdViewDelegate

extension FacebookAudienceNetworkBannerAdView {

    func adViewDidClick(_ adView: FBAdView) {
        print("FAN > BannerAdView > adViewDidClick")

        channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: adView.placementID,
            FANConstant.INVALIDATED_ARG: adView.isAdValid
        ])
    }

    func adViewDidFinishHandlingClick(_ adView: FBAdView) {
        print("FAN > BannerAdView > adViewDidFinishHandlingClick")
    }

    func adViewDidLoad(_ adView: FBAdView) {
        DispatchQueue.main.async {     
            print("FAN > BannerAdView > adViewDidLoad")

            self.bannerAd = adView
            addBannerToView()

            channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: [
                FANConstant.PLACEMENT_ID_ARG: adView.placementID,
                FANConstant.INVALIDATED_ARG: adView.isAdValid
            ])
        }
        
    }

    func adView(_ adView: FBAdView, didFailWithError error: Error) {
        print("FAN > BannerAdView > didFailWithError")

        let details = FacebookAdErrorDetails(fromSDKError: error)

        channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: adView.placementID,
            FANConstant.INVALIDATED_ARG: adView.isAdValid,
            FANConstant.ERROR_CODE_ARG: details?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: details?.message as Any
        ])
    }

    func adViewWillLogImpression(_ adView: FBAdView) {
        print("FAN > BannerAdView > adViewWillLogImpression")

        channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: adView.placementID,
            FANConstant.INVALIDATED_ARG: adView.isAdValid
        ])
    }
}