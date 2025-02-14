import Flutter
import UIKit
import AVKit
import GoogleCast

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

class StatusStreamHandler: NSObject, FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        CastPlusPlugin.statusSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        CastPlusPlugin.statusSink = nil
        return nil
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

// 3) The main plugin class with EventChannel integration
public class CastPlusPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {

    // MARK: - Properties
    private var eventSink: FlutterEventSink?
    private var discoveryListener: CastDiscoveryListener?
    
    private var currentSessionListener: CastSessionListener?
    
    public static var statusSink: FlutterEventSink?
    
    private static var _sharedInstance: CastPlusPlugin?



    // MARK: - Plugin Registration
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Set up the method channel
        let channel = FlutterMethodChannel(name: "cast_plus_plugin", binaryMessenger: registrar.messenger())
        let instance = CastPlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Initialize Google Cast
        let criteria = GCKDiscoveryCriteria(applicationID: kGCKDefaultMediaReceiverApplicationID)
        let options = GCKCastOptions(discoveryCriteria: criteria)
        GCKCastContext.setSharedInstanceWith(options)

        // Register the route picker platform view, matching "AirPlayRoutePicker" from main.dart
        let factory = RoutePickerPlatformViewFactory()
        registrar.register(factory, withId: "AirPlayRoutePicker")

        // Set up the event channel for device updates
        let eventChannel = FlutterEventChannel(name: "cast_plus_plugin/deviceUpdates", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance)

        // Set up and retain the discovery listener
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        let listener = CastDiscoveryListener()
        listener.onDeviceListUpdate = {
            instance.sendDeviceListUpdate()
        }
        discoveryManager.add(listener)
        instance.discoveryListener = listener
        discoveryManager.startDiscovery()
        
        let statusChannel = FlutterEventChannel(name: "cast_plus_plugin/statusUpdates", binaryMessenger: registrar.messenger())
        statusChannel.setStreamHandler(StatusStreamHandler())
        
        _sharedInstance = instance

    }

    // MARK: - Method Channel Handler
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

        case "castToDevice":
            if let args = call.arguments as? [String: Any],
               let deviceId = args["deviceId"] as? String,
               let urlString = args["url"] as? String,
               let deviceUniqueId = args["deviceUniqueId"] as? String,
               let videoTitle = args["videoTitle"] as? String,
               let url = URL(string: urlString) {
                castToDevice(deviceId: deviceId, url: url, deviceUniqueId: deviceUniqueId, videoTitle: videoTitle, result: result)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "deviceId and url are required", details: nil))
            }

        case "stopDeviceCasting":
            stopDeviceCasting()
            result(nil)

        case "getAvailableCastDevices":
            let devicesArray = getAvailableDevices()
            print(GCKCastContext.sharedInstance().discoveryManager.hasDiscoveredDevices)
            print(devicesArray)
            result(devicesArray)

        case "castToAirPlay":
            if let args = call.arguments as? [String: Any],
               let urlString = args["url"] as? String,
               let url = URL(string: urlString) {
                castToAirPlay(url: url, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "url is required", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - FlutterStreamHandler Methods
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        // Optionally, send an initial update
        sendDeviceListUpdate()
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        GCKCastContext.sharedInstance().discoveryManager.stopDiscovery()
        return nil
    }

    // MARK: - Helper to Get Available Devices
    private func getAvailableDevices() -> [[String: Any]] {
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        var devicesArray: [[String: Any]] = []
        let count = discoveryManager.deviceCount
        for index in 0..<Int(count) {
            let deviceInfo = discoveryManager.device(at: UInt(index))
            var deviceDict: [String: Any] = [:]
            deviceDict["deviceId"] = deviceInfo.deviceID
            deviceDict["deviceName"] = deviceInfo.friendlyName
            deviceDict["deviceUniqueId"] = deviceInfo.uniqueID
            devicesArray.append(deviceDict)
        }
        return devicesArray
    }

    // MARK: - Sending Device Updates to Flutter
    private func sendDeviceListUpdate() {
        guard let eventSink = self.eventSink else { return }
        let devicesArray = getAvailableDevices()
        eventSink(devicesArray)
    }

    // MARK: - Private Methods
    private var backgroundPlayer: AVPlayer?

    private func castUrlInternal(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        // Create an AVPlayer in code only (background playback)
        backgroundPlayer = AVPlayer(url: url)
        backgroundPlayer?.play()
    }

    private func stopAirPlayInternal() {
        backgroundPlayer?.pause()
        backgroundPlayer = nil
    }

    private func castToDevice(deviceId: String, url: URL, deviceUniqueId: String, videoTitle: String, result: @escaping FlutterResult) {
        // 1. Get the GCKDevice object for the device ID.
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        print("Discovery is running: \(discoveryManager.discoveryState)")
        guard let device = discoveryManager.device(withUniqueID: deviceUniqueId) else {
            result(FlutterError(code: "device_not_found",
                                message: "Device with ID \(deviceId) not found.",
                                details: nil))
            return
        }

        // 2. Set up a session listener to handle session events.
        let sessionManager = GCKCastContext.sharedInstance().sessionManager
        let sessionListener = CastSessionListener(deviceId: deviceId, url: url, videoTitle: videoTitle, flutterResult: result) // Helper class below
        self.currentSessionListener = sessionListener
        sessionManager.add(sessionListener)

        // 3. Attempt to connect to the device and start a session.
        sessionManager.startSession(with: device)

    }
    
    private func stopDeviceCasting() {
        GCKCastContext.sharedInstance().sessionManager.endSessionAndStopCasting(true)
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.dismiss(animated: true, completion: nil)
        }
    }

    private func createMetData(videoTitle: String) -> GCKMediaMetadata {
        let metaData = GCKMediaMetadata(metadataType: .movie)
        metaData.setString(videoTitle, forKey: kGCKMetadataKeyTitle)
        return metaData
    }

    private func castToAirPlay(url: URL, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            playerViewController.player?.allowsExternalPlayback = true
            playerViewController.updatesNowPlayingInfoCenter = true

            if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                rootVC.present(playerViewController, animated: true) {
                    player.play()
                }
            } else {
                result(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "Cannot find root view controller", details: nil))
            }
        }
    }
    
    func sendStatusUpdate(_ status: [String: Any]){
        CastPlusPlugin.statusSink?(status)
    }
    
    public static func sharedInstance() -> CastPlusPlugin? {
        // In many cases, you might store your instance in a static property when registering.
        // For simplicity, you can also use a singleton pattern.
        return _sharedInstance
    }
    
}

// Custom discovery listener that uses a closure callback to notify updates.
class CastDiscoveryListener: NSObject, GCKDiscoveryManagerListener {
    var onDeviceListUpdate: (() -> Void)?

    func didUpdateDeviceList() {
        print("Device list updated (didUpdateDeviceList called)") // Keep this
        let discoveryManager = GCKCastContext.sharedInstance().discoveryManager
        print("Currently discovered devices:")
        for i in 0..<discoveryManager.deviceCount {
            let device = discoveryManager.device(at: UInt(i))
            print("  Device \(i): ID=\(device.deviceID), Name=\(String(describing: device.friendlyName))")
        }
        onDeviceListUpdate?() // This triggers the Flutter EventChannel
    }
}

// Helper Class: CastSessionListener (Crucial for handling asynchronous events)
class CastSessionListener: NSObject, GCKSessionManagerListener {
    let deviceId: String
    let url: URL
    let videoTitle: String
    let flutterResult: FlutterResult
    var hasAttemptedLoad = false // Important flag to prevent double loading

    init(deviceId: String, url: URL, videoTitle: String, flutterResult: @escaping FlutterResult) {
        self.deviceId = deviceId
        self.url = url
        self.videoTitle = videoTitle
        self.flutterResult = flutterResult
    }

    // Called when a session has started successfully.
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        print("Session started with device: \(session.device.friendlyName ?? "")")
        CastPlusPlugin.sharedInstance()?.sendStatusUpdate([
            "status": "sessionStarted",
            "deviceName": session.device.friendlyName ?? ""
        ])
        loadMedia(session: session)
    }

    // Called when an existing session is resumed.
    func sessionManager(_ sessionManager: GCKSessionManager, didResume session: GCKSession) {
        print("Session resumed with device: \(session.device.friendlyName ?? "")")
        CastPlusPlugin.sharedInstance()?.sendStatusUpdate([
            "status": "sessionResumed",
            "deviceName": session.device.friendlyName ?? ""
        ])
        loadMedia(session: session)
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        print("Failed to start session: \(error)")
        CastPlusPlugin.sharedInstance()?.sendStatusUpdate(["status": "sessionStartFailed", "error":error.localizedDescription])
        cleanup()  // remove self from listeners
        flutterResult(FlutterError(code: "session_start_failed",
                                  message: "Failed to start session: \(error.localizedDescription)",
                                  details: nil))
    }

    func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
       if let error = error {
           print("Session ended with error: \(error)")
           CastPlusPlugin.sharedInstance()?.sendStatusUpdate([
            "status": "sessionEnded",
            "error": error.localizedDescription
           ])
           flutterResult(FlutterError(code: "session_ended", message: "Session Ended: \(error.localizedDescription)", details: nil))
       } else {
           print("Session ended normally")
           CastPlusPlugin.sharedInstance()?.sendStatusUpdate(["status": "sessionEnded"])
           flutterResult(nil) // or a success message as appropriate
       }
        cleanup() //remove self from listeners
    }


    // Function to load media (called after a successful session start/resume).
    private func loadMedia(session: GCKSession) {
        // Prevent loading media multiple times if both didStart and didResume are called
        guard !hasAttemptedLoad else { return }
        hasAttemptedLoad = true

        let builder = GCKMediaInformationBuilder(contentURL: url)
        builder.streamType = .buffered
        builder.contentType = "video/mp4" // Adjust if necessary
        builder.metadata = createMetData() // Your existing function
        let mediaInformation = builder.build()
        
        CastPlusPlugin.sharedInstance()?.sendStatusUpdate([
            "status": "mediaLoading",
            "videoTitle": videoTitle
        ])


        // Set up a media listener (optional, but good for progress updates/errors)
        let mediaStatusListener = MediaStatusListener(flutterResult: flutterResult)  //Another Helper
        session.remoteMediaClient?.add(mediaStatusListener)

        let request = session.remoteMediaClient?.loadMedia(mediaInformation)
        request?.delegate = mediaStatusListener  // Connect the delegate.
        
        CastPlusPlugin.sharedInstance()?.sendStatusUpdate(["status": "mediaLoadRequestSent"])
        // Cleanup is essential to avoid memory leaks.  Remove the listener when done.
        GCKCastContext.sharedInstance().sessionManager.remove(self)

    }

    private func cleanup() {
          GCKCastContext.sharedInstance().sessionManager.remove(self)
      }

    // Your createMetData function (placeholder - adapt as needed)
    private func createMetData() -> GCKMediaMetadata {
        let metadata = GCKMediaMetadata(metadataType: .movie) // Or .tvShow, .musicTrack, etc.
        metadata.setString(videoTitle, forKey: kGCKMetadataKeyTitle)
        // Add more metadata as needed (images, etc.)
        return metadata
    }
}

// Helper for Media Status Updates (Optional, but very useful)
class MediaStatusListener: NSObject, GCKRequestDelegate, GCKRemoteMediaClientListener {
    let flutterResult: FlutterResult
    
    init(flutterResult: @escaping FlutterResult) {
        self.flutterResult = flutterResult
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        // Handle media status updates (playing, paused, buffering, etc.)
        // You can send updates to Flutter here if needed.
        if let mediaStatus = mediaStatus, mediaStatus.idleReason == .finished {
             print("Media playback finished.")
             //send message to flutter that media is finished
            flutterResult(nil) //Or send message
        }
    }

    func requestDidComplete(_ request: GCKRequest) {
        print("Request completed: \(request.requestID)")
        // Media load was successful (usually).  You might send a success message to Flutter here.
         flutterResult(nil)
    }

    func request(_ request: GCKRequest, didFailWithError error: GCKError) {
        print("Request \(request.requestID) failed: \(error)")
         flutterResult(FlutterError(code: "media_load_failed",
                                   message: "Media load failed: \(error.localizedDescription)",
                                   details: nil))
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdateQueue queue: [GCKMediaQueueItem]) {
        // Handle queue updates, you can send update to flutter here
    }

}
