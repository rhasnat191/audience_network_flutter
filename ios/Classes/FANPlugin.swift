// import Flutter
// import UIKit

// public class FANPlugin: NSObject, FlutterPlugin {

//     public static func register(with registrar: FlutterPluginRegistrar) {
//         print(">> FAN Plugin register")

//         // Factories CAN be registered from main actor safely
//         registrar.register(
//             FacebookAudienceNetworkBannerAdFactory(_registrar: registrar),
//             withId: FANConstant.BANNER_AD_CHANNEL
//         )

//         registrar.register(
//             FacebookAudienceNetworkNativeAdFactory(_registrar: registrar),
//             withId: FANConstant.NATIVE_AD_CHANNEL
//         )

//         registrar.register(
//             FacebookAudienceNetworkNativeBannerAdFactory(_registrar: registrar),
//             withId: FANConstant.NATIVE_BANNER_AD_CHANNEL
//         )

//         // Main plugin channel
//         let pluginChannel = FlutterMethodChannel(
//             name: FANConstant.MAIN_CHANNEL,
//             binaryMessenger: registrar.messenger()
//         )
//         FANPluginFactory(_channel: pluginChannel)

//         // Interstitial
//         let interstitialChannel = FlutterMethodChannel(
//             name: FANConstant.INTERSTITIAL_AD_CHANNEL,
//             binaryMessenger: registrar.messenger()
//         )
//         _ = FacebookAudienceNetworkInterstitialAdPlugin(_channel: interstitialChannel)

//         // Rewarded
//         let rewardedChannel = FlutterMethodChannel(
//             name: FANConstant.REWARDED_VIDEO_CHANNEL,
//             binaryMessenger: registrar.messenger()
//         )
//         _ = FacebookAudienceNetworkRewardedAdPlugin(_channel: rewardedChannel)
//     }
// }

import Flutter
import UIKit

public class FANPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        print(">> FAN Plugin register")

        // Register factories (safe, not actor isolated)
        registrar.register(
            FacebookAudienceNetworkBannerAdFactory(_registrar: registrar),
            withId: FANConstant.BANNER_AD_CHANNEL
        )

        registrar.register(
            FacebookAudienceNetworkNativeAdFactory(_registrar: registrar),
            withId: FANConstant.NATIVE_AD_CHANNEL
        )

        registrar.register(
            FacebookAudienceNetworkNativeBannerAdFactory(_registrar: registrar),
            withId: FANConstant.NATIVE_BANNER_AD_CHANNEL
        )

        // Hop to MainActor for plugin initialization
        Task { @MainActor in
            print(">> FAN Plugin initializing components on MainActor")

            // Main plugin channel
            let pluginChannel = FlutterMethodChannel(
                name: FANConstant.MAIN_CHANNEL,
                binaryMessenger: registrar.messenger()
            )
            _ = FANPluginFactory(_channel: pluginChannel)

            // Interstitial
            let interstitialChannel = FlutterMethodChannel(
                name: FANConstant.INTERSTITIAL_AD_CHANNEL,
                binaryMessenger: registrar.messenger()
            )
            _ = FacebookAudienceNetworkInterstitialAdPlugin(_channel: interstitialChannel)

            // Rewarded
            let rewardedChannel = FlutterMethodChannel(
                name: FANConstant.REWARDED_VIDEO_CHANNEL,
                binaryMessenger: registrar.messenger()
            )
            _ = FacebookAudienceNetworkRewardedAdPlugin(_channel: rewardedChannel)
        }
    }
}