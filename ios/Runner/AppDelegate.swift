import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let controller = self.window?.rootViewController as? FlutterViewController
    let shareChannel = FlutterMethodChannel(
      name: "shopliist_pro/native_share",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "NativeShare").messenger()
    )

    shareChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "shareText" {
        guard let args = call.arguments as? [String: Any],
              let text = args["text"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "Text is required", details: nil))
          return
        }

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        if let rootVC = controller ?? UIApplication.shared.keyWindow?.rootViewController {
          if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
          }
          rootVC.present(activityVC, animated: true) {
            result(true)
          }
        } else {
          result(false)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
