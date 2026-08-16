import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller = window?.rootViewController as? FlutterViewController
    if let controller = controller {
      // Register WhisperBridge
      if let registrar = self.registrar(forPlugin: "WhisperBridge") {
        WhisperBridge.register(with: registrar)
      }
      
      // Setup Share Channel
      let shareChannel = FlutterMethodChannel(
          name: "com.capstudio/share",
          binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { [weak controller] (call, result) in
          if call.method == "shareFile",
             let args = call.arguments as? [String: Any],
             let path = args["path"] as? String {
              let url = URL(fileURLWithPath: path)
              let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
              
              if let popover = activityVC.popoverPresentationController {
                  popover.sourceView = controller?.view
                  popover.sourceRect = CGRect(x: controller?.view.bounds.midX ?? 0,
                                              y: controller?.view.bounds.midY ?? 0,
                                              width: 0, height: 0)
                  popover.permittedArrowDirections = []
              }
              controller?.present(activityVC, animated: true)
              result(nil)
          } else {
              result(FlutterMethodNotImplemented)
          }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
