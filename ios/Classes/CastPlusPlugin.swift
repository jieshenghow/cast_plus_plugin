import Flutter
import UIKit
import AVKit

public class CastPlusPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "cast_plus_plugin", binaryMessenger: registrar.messenger())
    let instance = CastPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      // For AirPlay, there's usually no formal "init" needed, but we might do any setup here
      result(nil)
    case "showCastPicker":
      showAirPlayPicker()
      result(nil)
    case "castUrl":
      if let args = call.arguments as? [String: Any],
         let urlString = args["url"] as? String {
        castUrlInternal(urlString)
      }
      result(nil)
    case "stopCasting":
      // Stopping AirPlay is typically user-driven
      stopAirPlayInternal()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func showAirPlayPicker() {
    // You can present an AVRoutePickerView or MPVolumeView in a popover programmatically,
    // or rely on your main UI to show it. We’ll do a quick example with AVRoutePickerView:

    guard let window = UIApplication.shared.keyWindow else { return }
    let routePickerView = AVRoutePickerView(frame: CGRect(x: 20, y: 50, width: 200, height: 50))
    routePickerView.activeTintColor = .blue
    routePickerView.tintColor = .black

    // This is a hacky approach to "show" it. Usually, you'd incorporate routePickerView in your real UI.
    window.addSubview(routePickerView)

    // There's no official "open popup" method—when the user taps the route picker icon, it shows available devices.
  }

  private func castUrlInternal(_ urlString: String) {
    // For AirPlay, the typical approach is to rely on the user picking the AirPlay device
    // once they're connected, you can play your content via an AVPlayer.
    // Example: we create an AVPlayerItem with the URL and set an AVPlayer in the background.

    guard let url = URL(string: urlString) else { return }
    let player = AVPlayer(url: url)
    let playerController = AVPlayerViewController()
    playerController.player = player

    // In a real scenario, you'd present this player controller in your app’s UI.
    // For demonstration, we can attempt to find the top-most view controller and present it:
    if let topVC = UIApplication.shared.keyWindow?.rootViewController {
      topVC.present(playerController, animated: true) {
        playerController.player?.play()
      }
    }
  }

  private func stopAirPlayInternal() {
    // You can "stop" AirPlay by stopping the AVPlayer or by letting the user unselect the route.
    // There's no direct "stop AirPlay" call. We'll pause/replace the player with nil:
    // This is highly dependent on your approach. If you have a global AVPlayer, set it to nil or pause it.

    // Example placeholder. Implement as needed in your app design:
  }
}