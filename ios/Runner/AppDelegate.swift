import UIKit
import Flutter
import Signer

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let signerChannel = FlutterMethodChannel(name: "armob.dev/signer",
                                              binaryMessenger: controller.binaryMessenger)
    signerChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
       
        if (call.method == "sign") {
            var error: NSErrorPointer = nil
            if let args = call.arguments as? Dictionary<String, Any>,
                let rawTx = args["rawTransaction"] as? Data,
                let n = args["n"] as? String,
                let d = args["d"] as? String,
                let dp = args["dp"] as? String,
                let dq = args["dq"] as? String
                {
                    result(SignerSign(rawTx, n, d, dp, dq, error))
            }
        }
            
        else {
           result(FlutterMethodNotImplemented)
           return
         }
        
    })
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
