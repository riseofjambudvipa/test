import Flutter
import UIKit
import Photos

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
      
      // Setup Native Channel (PhotoKit Camera Roll & platform methods)
      let nativeChannel = FlutterMethodChannel(
          name: "com.capstudio/native",
          binaryMessenger: controller.binaryMessenger
      )
      nativeChannel.setMethodCallHandler { (call, result) in
          switch call.method {
          case "saveVideoToGallery", "saveToGallery":
              let args = call.arguments as? [String: Any]
              guard let path = args?["path"] as? String ?? args?["filePath"] as? String else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Video path is required", details: nil))
                  return
              }
              AppDelegate.saveVideoToCameraRoll(path: path, result: result)
          default:
              result(FlutterMethodNotImplemented)
          }
      }

      // Setup Share Channel
      let shareChannel = FlutterMethodChannel(
          name: "com.capstudio/share",
          binaryMessenger: controller.binaryMessenger
      )
      shareChannel.setMethodCallHandler { [weak controller] (call, result) in
          switch call.method {
          case "shareFile":
              guard let args = call.arguments as? [String: Any],
                    let path = args["path"] as? String else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Path is required", details: nil))
                  return
              }
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
          case "saveVideoToGallery", "saveToGallery":
              let args = call.arguments as? [String: Any]
              guard let path = args?["path"] as? String ?? args?["filePath"] as? String else {
                  result(FlutterError(code: "INVALID_ARGS", message: "Video path is required", details: nil))
                  return
              }
              AppDelegate.saveVideoToCameraRoll(path: path, result: result)
          default:
              result(FlutterMethodNotImplemented)
          }
      }
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Saves an exported video file directly into the iOS Camera Roll / Photos Library.
  /// Handles PHPhotoLibrary authorization checks and PHAssetChangeRequest creation.
  private static func saveVideoToCameraRoll(path: String, result: @escaping FlutterResult) {
      let fileURL = URL(fileURLWithPath: path)
      guard FileManager.default.fileExists(atPath: fileURL.path) else {
          result(FlutterError(code: "FILE_NOT_FOUND", message: "Video file does not exist at path: \(path)", details: nil))
          return
      }

      let performSave = {
          PHPhotoLibrary.shared().performChanges({
              PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
          }) { success, error in
              DispatchQueue.main.async {
                  if success {
                      result(true)
                  } else {
                      result(FlutterError(
                          code: "SAVE_FAILED",
                          message: error?.localizedDescription ?? "Failed to save video to Photos library",
                          details: nil
                      ))
                  }
              }
          }
      }

      let currentStatus: PHAuthorizationStatus
      if #available(iOS 14, *) {
          currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
      } else {
          currentStatus = PHPhotoLibrary.authorizationStatus()
      }

      switch currentStatus {
      case .authorized, .limited:
          performSave()
      case .notDetermined:
          if #available(iOS 14, *) {
              PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                  DispatchQueue.main.async {
                      if newStatus == .authorized || newStatus == .limited {
                          performSave()
                      } else {
                          result(FlutterError(
                              code: "PERMISSION_DENIED",
                              message: "Photo library authorization was denied by the user",
                              details: nil
                          ))
                      }
                  }
              }
          } else {
              PHPhotoLibrary.requestAuthorization { newStatus in
                  DispatchQueue.main.async {
                      if newStatus == .authorized {
                          performSave()
                      } else {
                          result(FlutterError(
                              code: "PERMISSION_DENIED",
                              message: "Photo library authorization was denied by the user",
                              details: nil
                          ))
                      }
                  }
              }
          }
      case .denied, .restricted:
          result(FlutterError(
              code: "PERMISSION_DENIED",
              message: "Photo library access is denied or restricted on this device",
              details: nil
          ))
      @unknown default:
          result(FlutterError(
              code: "UNKNOWN_STATUS",
              message: "Unknown photo library authorization status",
              details: nil
          ))
      }
  }
}
