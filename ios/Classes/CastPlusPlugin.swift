import Flutter
import UIKit
import AVKit

// 1) The custom platform view that holds an AVRoutePickerView
class RoutePickerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView

    init(frame: CGRect) {
        containerView = UIView(frame: frame)
        super.init()

        // Create the actual AVRoutePickerView
        let routePickerView = AVRoutePickerView(frame: containerView.bounds)
        routePickerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Customize colors, etc., if desired
        routePickerView.tintColor = .systemBlue
        routePickerView.activeTintColor = .systemRed

        // Add to container
        containerView.addSubview(routePickerView)
    }

    func view() -> UIView {
        return containerView
    }
}

// 2) The factory that Flutter uses to create RoutePickerPlatformView instances
class RoutePickerPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return RoutePickerPlatformView(frame: frame)
    }
}

// 3) The main plugin class
public class CastPlusPlugin: NSObject, FlutterPlugin {

  // Register the plugin with the Flutter engine
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Set up the method channel
    let channel = FlutterMethodChannel(name: "cast_plus_plugin", binaryMessenger: registrar.messenger())
    let instance = CastPlusPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register the route picker platform view, matching "AirPlayRoutePicker" from main.dart
    let factory = RoutePickerPlatformViewFactory()
    registrar.register(factory, withId: "AirPlayRoutePicker")
  }

  // A reference to an AVPlayer/AVPlayerViewController if you want to control playback
  private var player: AVPlayer?
  private var playerController: AVPlayerViewController?

  // Handle method calls from Dart
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":
      // Nothing special to do for AirPlay initialization
      result(nil)

    case "castUrl":
      if let args = call.arguments as? [String: Any],
         let urlString = args["url"] as? String {
        castUrlInternal(urlString)
      }
      result(nil)

    case "stopCasting":
      stopAirPlayInternal()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Private Methods
  private var backgroundPlayer: AVPlayer?


  private func castUrlInternal(_ urlString: String) {
       guard let url = URL(string: urlString) else { return }

    // Create an AVPlayer in code only
    backgroundPlayer = AVPlayer(url: url)

    // This plays in the background, with no visible UI on the phone
    backgroundPlayer?.play()
  }

  private func stopAirPlayInternal() {
    backgroundPlayer?.pause()
    backgroundPlayer = nil
  }
}
