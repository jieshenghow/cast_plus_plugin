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
}
