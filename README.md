# cast_plus_plugin

Flutter plugin for casting videos

## Getting started
 
**For iOS**

Add permission to your ios/Runner/Info.plist:

```xml
<key>NSLocalNetworkUsageDescription</key>
    <string>${PRODUCT_NAME} uses the local network to discover Cast-enabled devices on your WiFi network.</string>
<key>NSBonjourServices</key>
    <array>
        <string>_googlecast._tcp</string>
        <string>_CC1AD845._googlecast._tcp</string>
    </array>
```

**For Android**

nothing to do

### Usage Instruction

Call initialize() in the iniState() method:

```dart
@override
void initState() {
  super.initState();
  CastPlusPlugin.initialize();
}
```

To retrieve a list of available cast devices:

```dart
Future<void> _fetchDevices() async {
  List<CastDevice> devices = await CastPlusPlugin.getAvailableCastDevices();
  setState(() {
    _devices = devices;
  });
}
```

Use a stream to listen for cast devices:

```dart
StreamSubscription<List<CastDevice>>? _deviceSub;

void _listenForDevices() {
  _deviceSub = CastPlusPlugin.deviceUpdateStream.listen((devices) {
    setState(() {
      _devices = devices;
    });
  });
}
```

To cast a video to a selected device:

```dart
void _castToDevice(CastDevice device) async {
  const videoUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
  try {
    await CastPlusPlugin.castToDevice(
      url: videoUrl,
      deviceId: device.deviceId,
      deviceUniqueId: device.deviceUniqueId,
      videoTitle: "Sample Video"
    );
    setState(() {
      _isCasting = true;
    });
  } catch (e) {
    print("Error: $e");
  }
}
```

For Airplay support on iOS:

```dart
void _castToAirPlay() {
  const videoUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
  CastPlusPlugin.castToAirPlay(videoUrl);
}
```

To stop casting a video:

```dart
void _stopCasting() {
  CastPlusPlugin.stopCasting();
  setState(() {
    _isCasting = false;
  });
}
```
