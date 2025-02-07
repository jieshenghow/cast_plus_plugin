import 'dart:async';

import 'package:flutter/services.dart';

class CastPlusPlugin {
  static const MethodChannel _channel = MethodChannel('cast_plus_plugin');
  static const EventChannel _eventChannel =
  EventChannel('cast_plus_plugin/deviceUpdates');

  /// Returns a stream of cast device list updates.
  static Stream<List<CastDevice>> get deviceUpdateStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      List<dynamic> list = event as List<dynamic>;
      return list
          .map((item) => CastDevice.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  static Future<void> initialize() async {
    await _channel.invokeMethod('initialize');
  }

  static Future<List<CastDevice>> getAvailableCastDevices() async {
    final List<dynamic> devices =
    await _channel.invokeMethod('getAvailableCastDevices');
    return devices
        .map((device) => CastDevice.fromMap(Map<String, dynamic>.from(device)))
        .toList();
  }

  static Future<void> castToDevice(
      String url, String deviceId, String deviceUniqueId) async {
    await _channel.invokeMethod('castToDevice',
        {'url': url, 'deviceId': deviceId, 'deviceUniqueId': deviceUniqueId});
  }

  static Future<void> castToAirPlay(String url) async {
    await _channel.invokeMethod('castToAirPlay', {'url': url});
  }

  static Future<void> stopCasting() async {
    // Stop both AirPlay and device casting
    await _channel.invokeMethod('stopCasting');
    await _channel.invokeMethod('stopDeviceCasting');
  }

  // If needed, you can add showCastPicker for Android here.
  static Future<void> showCastPicker() async {
    // Add your Android implementation if required.
  }
}
class CastDevice {
  final String deviceId;
  final String deviceName;
  final String deviceUniqueId;

  CastDevice({required this.deviceId, required this.deviceName, required this.deviceUniqueId});

  factory CastDevice.fromMap(Map<String, dynamic> map) {
    return CastDevice(
      deviceId: map['deviceId'] ?? '',
      deviceName: map['deviceName'] ?? '',
      deviceUniqueId: map['deviceUniqueId'] ?? '',
    );
  }
}
