import 'dart:async';

import 'package:flutter/services.dart';

class CastPlusPlugin {
  static const MethodChannel _channel = MethodChannel('cast_plus_plugin');

  /// Initialize the cast environment.
  static Future<void> initialize() async {
    await _channel.invokeMethod('initialize');
  }

  /// Shows the cast picker (Android uses a Cast button; iOS can pop up an AirPlay picker).
  static Future<void> showCastPicker() async {
    await _channel.invokeMethod('showCastPicker');
  }

  /// Cast a media URL.
  static Future<void> castUrl(String url) async {
    await _channel.invokeMethod('castUrl', {
      'url': url,
    });
  }

  /// Stop casting.
  static Future<void> stopCasting() async {
    await _channel.invokeMethod('stopCasting');
  }

  static Future<List<CastDevice>> getAvailableCastDevices() async {
    final List<dynamic> devices =
        await _channel.invokeMethod("getAvailableCastDevices");
    return devices.map((devices) => CastDevice.fromMap(Map<String, dynamic>.from(devices))).toList();
  }

  static Future<void> castToDevice(String url, String deviceId) async {
    await _channel
        .invokeMethod("castToDevice", {'url': url, 'deviceId': deviceId});
  }

  static Future<void> stopDeviceCasting() async {
    await _channel.invokeMethod("stopDeviceCasting");
  }

  static Future<void> castToAirPlay(String url) async {
    await _channel.invokeMethod("castToAirPlay", {'url': url});
  }
}

class CastDevice {
  final String id;
  final String name;

  CastDevice({required this.id, required this.name});

  factory CastDevice.fromMap(Map<String, dynamic> map) {
    return CastDevice(
      id: map['id'],
      name: map['name'],
    );
  }
}
