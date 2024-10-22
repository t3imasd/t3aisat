import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let saveImageChannel = FlutterMethodChannel(name: "com.t3aisat/save_to_gallery",
                                                binaryMessenger: controller.binaryMessenger)
    saveImageChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "saveImageWithExif" {
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments are null", details: nil))
          return
        }

        if let imagePath = args["imagePath"] as? String, !imagePath.isEmpty {
          self.saveImageWithExif(imagePath: imagePath, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENTS", message: "Image path not provided or is empty", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func saveImageWithExif(imagePath: String, result: @escaping FlutterResult) {
    let imageUrl = URL(fileURLWithPath: imagePath)
    do {
      let imageData = try Data(contentsOf: imageUrl)

      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          PHPhotoLibrary.shared().performChanges({
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = (imageUrl.lastPathComponent) // Use the original filename for saving
            creationRequest.addResource(with: .photo, data: imageData, options: options)
          }) { success, error in
            if success {
              result(true)
            } else {
              result(FlutterError(code: "SAVE_FAILED", message: "Failed to save image to gallery", details: error?.localizedDescription))
            }
          }
        } else {
          result(FlutterError(code: "PERMISSION_DENIED", message: "Photo library access denied", details: nil))
        }
      }
    } catch {
      result(FlutterError(code: "FILE_READ_ERROR", message: "Could not read image file", details: error.localizedDescription))
    }
  }
}
