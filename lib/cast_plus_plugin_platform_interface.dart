import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cast_plus_plugin_method_channel.dart';

abstract class CastPlusPluginPlatform extends PlatformInterface {
  /// Constructs a CastPlusPluginPlatform.
  CastPlusPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static CastPlusPluginPlatform _instance = MethodChannelCastPlusPlugin();

  /// The default instance of [CastPlusPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelCastPlusPlugin].
  static CastPlusPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CastPlusPluginPlatform] when
  /// they register themselves.
  static set instance(CastPlusPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
