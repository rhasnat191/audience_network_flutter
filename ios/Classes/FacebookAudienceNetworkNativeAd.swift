import Foundation
import Flutter
import FBAudienceNetwork
import UIKit

// MARK: - Native Ad Factory (NOT @MainActor)
final class FacebookAudienceNetworkNativeAdFactory: NSObject, FlutterPlatformViewFactory {

    private unowned let registrar: FlutterPluginRegistrar

    init(_registrar: FlutterPluginRegistrar) {
        print("NativeAd > Factory register")
        self.registrar = _registrar
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        print("NativeAd > Factory createArgsCodec")
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect,
                viewIdentifier viewId: Int64,
                arguments args: Any?) -> FlutterPlatformView {

        print("NativeAd > Factory create")

        return FacebookAudienceNetworkNativeAdView(
            frame: frame,
            viewId: viewId,
            params: args as? [String: Any] ?? [:],
            registrar: registrar
        )
    }
}


// MARK: - Layout Holder
final class FacebookAudienceNetworkNativeAdLayout {
    var adView = CGRect.zero
    var adIconRect = CGRect.zero
    var adTitleLabelRect = CGRect.zero
    var adSponsoredRect = CGRect.zero
    var adOptionsRect = CGRect.zero
    var adMediaRect = CGRect.zero
    var adCoverRect = CGRect.zero
    var adCallToActionRect = CGRect.zero
    var adBodyLabelRect = CGRect.zero
}


final class FacebookAudienceNetworkNativeAdView: NSObject,
                                                 FlutterPlatformView,
                                                 FBNativeAdDelegate {

    private let frame: CGRect
    private let viewId: Int64
    private let registrar: FlutterPluginRegistrar
    private let params: [String: Any]
    private let channel: FlutterMethodChannel?
    private lazy var mainView: UIView = {
        UIView()
    }()
    private var nativeAd: FBNativeAd?

    // Layout
    private var nativeAdLayout: FacebookAudienceNetworkNativeAdLayout!
    private var nativeAdViewAttributes: FBNativeAdViewAttributes!

    // Components
    private var adView: UIView?
    private var adIconView: FBAdIconView?
    private var adMediaView: FBMediaView?
    private var adCoverView: UIView?
    private var adTitleLabel: UILabel?
    private var adBodyLabel: UILabel?
    private var adCallToActionButton: UIButton?
    private var adSponsoredLabel: UILabel?
    private var adOptionsView: FBAdOptionsView?

    private var sponsoredColor = UIColor.gray
    private var sponsoredFont = UIFont.systemFont(ofSize: 10)
    private var descriptionLabelLines = 2

    init(frame: CGRect,
         viewId: Int64,
         params: [String: Any],
         registrar: FlutterPluginRegistrar) {

        print("NativeAd > init")

        self.frame = frame
        self.viewId = viewId
        self.params = params
        self.registrar = registrar

        

        super.init()
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            let ch = FlutterMethodChannel(
                name: "\(FANConstant.NATIVE_AD_CHANNEL)_\(viewId)",
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

    deinit { print("NativeAd > deinit") }
}


// MARK: - Flutter Method Handler
private extension FacebookAudienceNetworkNativeAdView {

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialization", "init":
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}


// MARK: - Setup Base View

private extension FacebookAudienceNetworkNativeAdView {

    func setupView() {
        print("NativeAd > setupView")
        mainView = UIView(frame: frame)
        mainView.backgroundColor = .clear
    }
}


// MARK: - Load FAN Ad

private extension FacebookAudienceNetworkNativeAdView {

    func loadNativeAd() {
        print("NativeAd > loadNativeAd")

        guard let placementId = params["id"] as? String else {
            print("NativeAd > Missing placement id")
            return
        }

        let ad = FBNativeAd(placementID: placementId)
        self.nativeAd = ad
        ad.delegate = self
        ad.loadAd()
    }
}


// MARK: - Common Attribute Setup

private extension FacebookAudienceNetworkNativeAdView {

    func buildNativeAdViewAttributes() {
        nativeAdViewAttributes = FBNativeAdViewAttributes()

        func c(_ key: String, default d: String) -> UIColor {
            UIColor(hexString: params[key] as? String ?? d)
        }

        nativeAdViewAttributes.buttonColor = c("button_color", default: "0xFFF8D000")
        nativeAdViewAttributes.buttonBorderColor = c("button_border_color", default: "0xFFF8D000")
        nativeAdViewAttributes.buttonTitleColor = c("button_title_color", default: "0xFF001E31")
        nativeAdViewAttributes.backgroundColor = c("bg_color", default: "0xFFFFFFFF")
        nativeAdViewAttributes.titleColor = c("title_color", default: "0xFF001E31")
        nativeAdViewAttributes.descriptionColor = c("desc_color", default: "0xFF001E31")

        sponsoredColor = UIColor(hexString: "0xFFA1ACC0")
        sponsoredFont = UIFont.systemFont(ofSize: 10)

        nativeAdViewAttributes.titleFont = UIFont.systemFont(ofSize: 12)
        nativeAdViewAttributes.descriptionFont = UIFont.systemFont(ofSize: 14)
        nativeAdViewAttributes.buttonTitleFont = UIFont.systemFont(ofSize: 13)
    }
}


// MARK: - Native Ad Did Load

extension FacebookAudienceNetworkNativeAdView {

    func nativeAdDidLoad(_ nativeAd: FBNativeAd) {
        print("NativeAd > nativeAdDidLoad")
        self.nativeAd = nativeAd

        registerAdLayout()

        let arg: [String: Any] = [
            FANConstant.PLACEMENT_ID_ARG: nativeAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeAd.isAdValid
        ]
        channel.invokeMethod(FANConstant.LOADED_METHOD, arguments: arg)
    }
}


// MARK: - Choose Layout (Template / Horizontal / Vertical)

private extension FacebookAudienceNetworkNativeAdView {

    func registerAdLayout() {
        let type = params["ad_type"] as? Int ?? FANConstant.NATIVE_AD_TEMPLATE

        buildNativeAdViewAttributes()

        switch type {
        case FANConstant.NATIVE_AD_HORIZONTAL:
            buildHorizontalLayout()
            buildHorizontalView()

        case FANConstant.NATIVE_AD_VERTICAL:
            buildVerticalLayout()
            buildVerticalView()

        default:
            buildTemplateView()
        }
    }
}


// MARK: - TEMPLATE LAYOUT

private extension FacebookAudienceNetworkNativeAdView {

    func buildTemplateView() {
        print("NativeAd > Template")

        guard
            let ad = nativeAd,
            let view = FBNativeAdView(
                nativeAd: ad,
                with: .dynamic,
                with: nativeAdViewAttributes
            )
        else { return }

        view.frame = mainView.bounds
        mainView.addSubview(view)
        mainView.layoutIfNeeded()
    }
}


// MARK: - HORIZONTAL LAYOUT + VIEW

private extension FacebookAudienceNetworkNativeAdView {

    func buildHorizontalLayout() {
        print("NativeAd > buildHorizontalLayout")

        nativeAdLayout = FacebookAudienceNetworkNativeAdLayout()

        let width = mainView.bounds.width
        let height = mainView.bounds.height

        let iconSize: CGFloat = 30
        let ctaSize = CGSize(width: 100, height: 30)

        nativeAdLayout.adView = CGRect(x: 0, y: 0, width: width, height: height)
        nativeAdLayout.adIconRect = CGRect(x: 5, y: 10, width: iconSize, height: iconSize)
        nativeAdLayout.adTitleLabelRect = CGRect(x: 50, y: 10, width: width - 160, height: 16)
        nativeAdLayout.adSponsoredRect = CGRect(x: 50, y: 26, width: 80, height: 14)
        nativeAdLayout.adOptionsRect = CGRect(x: width - 40, y: 10, width: 40, height: 20)
        nativeAdLayout.adMediaRect = CGRect(x: 0, y: 50, width: width, height: height - 120)
        nativeAdLayout.adCoverRect = nativeAdLayout.adMediaRect
        nativeAdLayout.adCallToActionRect = CGRect(x: width - ctaSize.width - 5,
                                                   y: 10,
                                                   width: ctaSize.width,
                                                   height: ctaSize.height)
        nativeAdLayout.adBodyLabelRect = CGRect(x: 5,
                                                y: height - 60,
                                                width: width - 10,
                                                height: 50)
    }

    func buildHorizontalView() {
        print("NativeAd > buildHorizontalView")

        guard let ad = nativeAd else { return }

        let view = UIView(frame: nativeAdLayout.adView)
        view.backgroundColor = nativeAdViewAttributes.backgroundColor
        adView = view

        // Media
        let media = FBMediaView(frame: nativeAdLayout.adMediaRect)
        adMediaView = media
        view.addSubview(media)

        // Icon
        let icon = FBAdIconView(frame: nativeAdLayout.adIconRect)
        icon.layer.cornerRadius = nativeAdLayout.adIconRect.width / 2
        adIconView = icon
        view.addSubview(icon)

        // Title
        let title = UILabel(frame: nativeAdLayout.adTitleLabelRect)
        title.text = ad.advertiserName ?? ""
        title.font = nativeAdViewAttributes.titleFont
        title.textColor = nativeAdViewAttributes.titleColor
        adTitleLabel = title
        view.addSubview(title)

        // Sponsored
        let sponsored = UILabel(frame: nativeAdLayout.adSponsoredRect)
        sponsored.text = ad.sponsoredTranslation ?? ""
        sponsored.font = sponsoredFont
        sponsored.textColor = sponsoredColor
        adSponsoredLabel = sponsored
        view.addSubview(sponsored)

        // CTA
        let cta = UIButton(frame: nativeAdLayout.adCallToActionRect)
        cta.backgroundColor = nativeAdViewAttributes.buttonColor
        cta.setTitle(ad.callToAction ?? "", for: .normal)
        cta.setTitleColor(nativeAdViewAttributes.buttonTitleColor, for: .normal)
        cta.titleLabel?.font = nativeAdViewAttributes.buttonTitleFont
        adCallToActionButton = cta
        view.addSubview(cta)

        // Body
        let body = UILabel(frame: nativeAdLayout.adBodyLabelRect)
        body.text = ad.bodyText ?? ""
        body.textColor = nativeAdViewAttributes.descriptionColor
        body.font = nativeAdViewAttributes.descriptionFont
        body.numberOfLines = descriptionLabelLines
        adBodyLabel = body
        view.addSubview(body)

        // Options
        let opt = FBAdOptionsView(frame: nativeAdLayout.adOptionsRect)
        opt.nativeAd = ad
        adOptionsView = opt
        view.addSubview(opt)

        // Register interaction
        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        ad.unregisterView()
        ad.registerView(
            forInteraction: view,
            mediaView: media,
            iconView: icon,
            viewController: rootVC,
            clickableViews: [cta, media]
        )

        mainView.addSubview(view)
        mainView.layoutIfNeeded()
    }
}


// MARK: - VERTICAL LAYOUT + VIEW

private extension FacebookAudienceNetworkNativeAdView {

    func buildVerticalLayout() {
        print("NativeAd > buildVerticalLayout")

        nativeAdLayout = FacebookAudienceNetworkNativeAdLayout()

        let width = mainView.bounds.width
        let height = mainView.bounds.height

        nativeAdLayout.adView = CGRect(x: 0, y: 0, width: width, height: height)
        nativeAdLayout.adMediaRect = CGRect(x: 0, y: 0, width: width, height: height * 0.5)
        nativeAdLayout.adCoverRect = nativeAdLayout.adMediaRect
        nativeAdLayout.adOptionsRect = CGRect(x: width - 40, y: height * 0.5, width: 40, height: 20)
        nativeAdLayout.adTitleLabelRect = CGRect(x: 5, y: height * 0.5 + 10, width: width - 50, height: 20)
        nativeAdLayout.adSponsoredRect = CGRect(x: 5, y: height * 0.5 + 30, width: width - 10, height: 16)
        nativeAdLayout.adBodyLabelRect = CGRect(x: 5, y: height * 0.5 + 50, width: width - 10, height: 60)
        nativeAdLayout.adCallToActionRect = CGRect(x: 10, y: height - 50, width: width - 20, height: 40)
    }

    func buildVerticalView() {
        print("NativeAd > buildVerticalView")

        guard let ad = nativeAd else { return }

        let view = UIView(frame: nativeAdLayout.adView)
        view.backgroundColor = nativeAdViewAttributes.backgroundColor
        adView = view

        // Media
        let media = FBMediaView(frame: nativeAdLayout.adMediaRect)
        adMediaView = media
        view.addSubview(media)

        let cover = UIView(frame: nativeAdLayout.adCoverRect)
        adCoverView = cover
        view.addSubview(cover)

        // Options
        let opt = FBAdOptionsView(frame: nativeAdLayout.adOptionsRect)
        opt.nativeAd = ad
        adOptionsView = opt
        view.addSubview(opt)

        // Title
        let title = UILabel(frame: nativeAdLayout.adTitleLabelRect)
        title.text = ad.advertiserName ?? ""
        title.font = nativeAdViewAttributes.titleFont
        title.textColor = nativeAdViewAttributes.titleColor
        adTitleLabel = title
        view.addSubview(title)

        // Sponsored
        let sponsored = UILabel(frame: nativeAdLayout.adSponsoredRect)
        sponsored.text = ad.sponsoredTranslation ?? ""
        sponsored.font = sponsoredFont
        sponsored.textColor = sponsoredColor
        adSponsoredLabel = sponsored
        view.addSubview(sponsored)

        // Body
        let body = UILabel(frame: nativeAdLayout.adBodyLabelRect)
        body.text = ad.bodyText ?? ""
        body.font = nativeAdViewAttributes.descriptionFont
        body.textColor = nativeAdViewAttributes.descriptionColor
        body.numberOfLines = descriptionLabelLines
        adBodyLabel = body
        view.addSubview(body)

        // CTA
        let cta = UIButton(frame: nativeAdLayout.adCallToActionRect)
        cta.backgroundColor = nativeAdViewAttributes.buttonColor
        cta.setTitle(ad.callToAction ?? "", for: .normal)
        cta.setTitleColor(nativeAdViewAttributes.buttonTitleColor, for: .normal)
        cta.titleLabel?.font = nativeAdViewAttributes.buttonTitleFont
        adCallToActionButton = cta
        view.addSubview(cta)

        let rootVC = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        ad.unregisterView()
        ad.registerView(
            forInteraction: view,
            mediaView: media,
            iconView: nil,
            viewController: rootVC,
            clickableViews: [cta, media]
        )

        mainView.addSubview(view)
        mainView.layoutIfNeeded()
    }
}


// MARK: - Ad Events

extension FacebookAudienceNetworkNativeAdView {

    func nativeAd(_ nativeAd: FBNativeAd, didFailWithError error: Error) {
        print("NativeAd > Failed: \(error.localizedDescription)")
        let details = FacebookAdErrorDetails(fromSDKError: error)

        channel.invokeMethod(FANConstant.ERROR_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeAd.isAdValid,
            FANConstant.ERROR_CODE_ARG: details?.code as Any,
            FANConstant.ERROR_MESSAGE_ARG: details?.message as Any
        ])
    }

    func nativeAdWillLogImpression(_ nativeAd: FBNativeAd) {
        print("NativeAd > WillLogImpression")

        channel.invokeMethod(FANConstant.LOGGING_IMPRESSION_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeAd.isAdValid
        ])
    }

    func nativeAdDidClick(_ nativeAd: FBNativeAd) {
        print("NativeAd > Click")

        channel.invokeMethod(FANConstant.CLICKED_METHOD, arguments: [
            FANConstant.PLACEMENT_ID_ARG: nativeAd.placementID,
            FANConstant.INVALIDATED_ARG: nativeAd.isAdValid
        ])
    }
}
