import Foundation
import Flutter
import FBAudienceNetwork

@MainActor
final class FANPluginFactory: NSObject {

    private let channel: FlutterMethodChannel

    init(_channel: FlutterMethodChannel) {
        print("FANPluginFactory > init")

        self.channel = _channel
        super.init()

        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { return }
            self.handle(call: call, result: result)
        }

        print("FANPluginFactory > ready")
    }
}

// MARK: - Method Handler
@MainActor
private extension FANPluginFactory {

    func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "init":
            handleInitialization(call, result: result)

        default:
            Task { @MainActor in
               result(FlutterMethodNotImplemented)
            }
        }
    }
}

// MARK: - Initialization Logic
@MainActor
private extension FANPluginFactory {

    func handleInitialization(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard let args = call.arguments as? [String: Any] else {
            print("FANPluginFactory > Invalid args")
            result(false)
            return
        }

        let testingId = args["testingId"] as? String
        let testMode = args["testMode"] as? Bool ?? false
        let deviceHash = FBAdSettings.testDeviceHash()

        // Register test device(s)
        if let testingId = testingId {
            FBAdSettings.addTestDevice(testingId)
        }

        if testMode && testingId != deviceHash {
            FBAdSettings.addTestDevice(deviceHash)
        }

        if testingId == nil && !testMode {
            print("FANPluginFactory > Test Device Hash: \(deviceHash)")
        }

        // iOS14+ ATT tracking enable
        if #available(iOS 14.0, *) {
            let trackingEnabled = args["iOSAdvertiserTrackingEnabled"] as? Bool ?? false
            print("FANPluginFactory > AdvertiserTrackingEnabled = \(trackingEnabled)")
            FBAdSettings.setAdvertiserTrackingEnabled(trackingEnabled)
        }

        // Initialize FAN SDK
        FBAudienceNetworkAds.initialize(with: nil) { results in
            print("FANPluginFactory > init completed: \(results.isSuccess)")
            result(results.isSuccess)
        }
    }
}