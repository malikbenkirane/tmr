import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private let appGroupId = "group.com.example.tooManyTabs"
    private var shareChannel: FlutterMethodChannel?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Flutter Local Notifications setup
        FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
            GeneratedPluginRegistrant.register(with: registry)
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
        }
        
        GeneratedPluginRegistrant.register(with: self)
        
        // Setup Share Extension Method Channel
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }
        
        shareChannel = FlutterMethodChannel(
            name: "com.example.tooManyTabs/share",
            binaryMessenger: controller.binaryMessenger
        )
        
        shareChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate not available", details: nil))
                return
            }
            
            switch call.method {
            case "getSharedDatabasePath":
                if let args = call.arguments as? [String: String],
                   let appGroupId = args["appGroupId"],
                   let key = args["key"] {
                    let path = self.getSharedDatabasePath(appGroupId: appGroupId, key: key)
                    result(path)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }
                
            case "clearSharedDatabasePath":
                if let args = call.arguments as? [String: String],
                   let appGroupId = args["appGroupId"],
                   let key = args["key"] {
                    self.clearSharedDatabasePath(appGroupId: appGroupId, key: key)
                    result(nil as Any?)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // Handle URL scheme (when opened from Share Extension)
    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
        if url.scheme == "toomanytabs" && url.host == "import-database" {
            // Notify Flutter about the shared database
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.shareChannel?.invokeMethod("handleSharedDatabase", arguments: nil)
            }
            return true
        }
        
        return super.application(app, open: url, options: options)
    }
    
    // MARK: - Share Extension Helper Methods
    
    private func getSharedDatabasePath(appGroupId: String, key: String) -> String? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            return nil
        }
        return sharedDefaults.string(forKey: key)
    }
    
    private func clearSharedDatabasePath(appGroupId: String, key: String) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId) else {
            return
        }
        sharedDefaults.removeObject(forKey: key)
        sharedDefaults.removeObject(forKey: "shared_database_timestamp")
        sharedDefaults.synchronize()
    }
}
