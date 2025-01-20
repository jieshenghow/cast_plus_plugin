import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cast_plus_plugin_platform_interface.dart';

/// An implementation of [CastPlusPluginPlatform] that uses method channels.
class MethodChannelCastPlusPlugin extends CastPlusPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cast_plus_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
