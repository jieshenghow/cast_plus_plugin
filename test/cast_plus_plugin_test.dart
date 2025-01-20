// import 'package:flutter_test/flutter_test.dart';
// import 'package:cast_plus_plugin/cast_plus_plugin.dart';
// import 'package:cast_plus_plugin/cast_plus_plugin_platform_interface.dart';
// import 'package:cast_plus_plugin/cast_plus_plugin_method_channel.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';
//
// class MockCastPlusPluginPlatform
//     with MockPlatformInterfaceMixin
//     implements CastPlusPluginPlatform {
//
//   @override
//   Future<String?> getPlatformVersion() => Future.value('42');
// }
//
// void main() {
//   final CastPlusPluginPlatform initialPlatform = CastPlusPluginPlatform.instance;
//
//   test('$MethodChannelCastPlusPlugin is the default instance', () {
//     expect(initialPlatform, isInstanceOf<MethodChannelCastPlusPlugin>());
//   });
//
//   test('getPlatformVersion', () async {
//     CastPlusPlugin castPlusPlugin = CastPlusPlugin();
//     MockCastPlusPluginPlatform fakePlatform = MockCastPlusPluginPlatform();
//     CastPlusPluginPlatform.instance = fakePlatform;
//
//     expect(await castPlusPlugin.getPlatformVersion(), '42');
//   });
// }
