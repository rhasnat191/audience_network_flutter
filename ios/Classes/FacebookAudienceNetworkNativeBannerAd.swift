import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

// MARK: - Factory (NOT @MainActor)
final class FacebookAudienceNetworkNativeBannerAdFactory: NSObject, FlutterPlatformViewFactory {

    private unowned let registrar: FlutterPluginRegistrar

    init(_registrar: FlutterPluginRegistrar) {
        print("NativeBannerAd > Factory register")
        self.registrar = _registrar
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        print("NativeBannerAd > Factory createArgsCodec")
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {

        print("NativeBannerAd > Factory create")

        return FacebookAudienceNetworkNativeBannerAdView(
            frame: frame,
            viewId: viewId,
            params: args as? [String: Any] ?? [:],
            registrar: registrar
        )
    }
}

// MARK: - Native Banner Ad View
final class FacebookAudienceNetworkNativeBannerAdView: NSObject, FlutterPlatformView, FBNativeBannerAdDelegate {

    private let frame: CGRect
    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let params: [String: Any]
    private let channel: FlutterMethodChannel?
    private lazy var mainView: UIView = {
        UIView()
    }()
    private var nativeBannerAd: FBNativeBannerAd?

    private var nativeAdViewAttributes: FBNativeAdViewAttributes?

    init(frame: CGRect,
         viewId: Int64,
         params: [String: Any],
         registrar: FlutterPluginRegistrar) {

        print("NativeBannerAd > init")

        self.frame = frame
        self.viewId = viewId
        self.params = params
        self.registrar = registrar

        

        super.init()
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            let ch = FlutterMethodChannel(
                name: "\(FANConstant.NATIVE_BANNER_AD_CHANNEL)_\(viewId)",
                binaryMessenger: registrar.messenger()
            )
            
            self.channel = ch
            
            ch.setMethodCallHandler { [weak self] call, result in
                self?.handle(call, result: result)
            }
        }
        setupView()
        loadNativeAd()
    }

    func view() -> UIView { mainView }

    deinit {
        print("NativeBannerAd > deinit")
    }
}

// MARK: - Flutter Call Handler
private extension FacebookAudienceNetworkNativeBannerAdView {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialization", "init":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// MARK: - Setup Main View
private extension FacebookAudienceNetworkNativeBannerAdView {

    func setupView() {
        print("NativeBannerAd > setupView")
        mainView = UIView(frame: frame)
        mainView.backgroundColor = .white
    }
}

// MARK: - Load Native Banner Ad
private extension FacebookAudienceNetworkNativeBannerAdView {

    func loadNativeAd() {
        print("NativeBannerAd > loadNativeAd")

        guard let placementId = params["id"] as? String else {
            print("NativeBannerAd > Missing placement ID")
            return
        }

        let ad = FBNativeBannerAd(placementID: placementId)
        self.nativeBannerAd = ad

        ad.delegate = self
        ad.loadAd()
    }

    func initNativeAdViewAttributes() {
        // Optional: implement customization if needed (current code was commented out)
        nativeAdViewAttributes = FBNativeAdViewAttributes()
    }
}

// MARK: - Render Native Banner
private extension FacebookAudienceNetworkNativeBannerAdView {

    func registerTemplateView() {
        print("NativeBannerAd > registerTemplateView")

        guard let ad = nativeBannerAd else { return }

        let width = params["width"] as? CGFloat ?? UIScreen.main.bounds.width
        let height = params["height"] as? CGFloat ?? 100.0
        let viewType = resolveViewType(height)

        let bannerView = FBNativeBannerAdView(nativeBannerAd: ad, with: viewType)
        bannerView.frame = CGRect(x: 0, y: 0, width: width, height: height)

        mainView.addSubview(bannerView)
        mainView.layoutIfNeeded()
    }

    func resolveViewType(_ height: CGFloat) -> FBNativeBannerAdViewType {
        switch height {
        case 50:
            return .genericHeight50
        case 100:
            return .genericHeight100
        case 120:
            return .genericHeight120
        default:
            return .genericHeight100
        }
    }
}

// MARK: - Delegate Handlers
extension FacebookAudienceNetworkNativeBannerAdView {

    func nativeBannerAdDidLoad(_ nativeBannerAd: FBNativeBannerAd) {
        print("NativeBannerAd > Loaded")

        self.nativeBannerAd = nativeBannerAd
        initNativeAdViewAttributes()
        registerTemplateView()

        channel?.invokeMethod(FANConstant.LOADED_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeBannerAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeBannerAd.isAdValid
        ])
    }

    func nativeBannerAdDidDownloadMedia(_ nativeBannerAd: FBNativeBannerAd) {
        print("NativeBannerAd > DidDownloadMedia")
    }

    func nativeBannerAdWillLogImpression(_ nativeBannerAd: FBNativeBannerAd) {
        print("NativeBannerAd > WillLogImpression")

        channel?.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeBannerAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeBannerAd.isAdValid
        ])
    }

    func nativeBannerAd(_ nativeBannerAd: FBNativeBannerAd, didFailWithError error: Error) {
        print("NativeBannerAd > Failed: \(error.localizedDescription)")

        let details = FacebookAdErrorDetails(fromSDKError: error)

        channel?.invokeMethod(FANConstant.ERROR_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeBannerAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeBannerAd.isAdValid,
            FANConstant.ERROR_CODE_ARG: details?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: details?.message as Any
        ])
    }

    func nativeBannerAdDidClick(_ nativeBannerAd: FBNativeBannerAd) {
        print("NativeBannerAd > Clicked")

        channel?.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeBannerAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeBannerAd.isAdValid
        ])
    }

    func nativeBannerAdDidFinishHandlingClick(_ nativeBannerAd: FBNativeBannerAd) {
        print("NativeBannerAd > FinishedHandlingClick")
    }
}
