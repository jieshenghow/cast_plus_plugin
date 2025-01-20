// example/lib/main.dart

import 'dart:io' show Platform;

import 'package:cast_plus_plugin/cast_plus_plugin.dart'; // Import your plugin's Dart file
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// Example root widget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the plugin (does nothing on iOS by default, but good practice).
    CastPlusPlugin.initialize();
  }

  @override
  Widget build(BuildContext context) {
    const sampleHlsUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // Ensure you're using a Material theme for proper styling
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Cast Route Picker Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom Cast Route Picker
              const CastRoutePickerView(),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  CastPlusPlugin.castUrl(sampleHlsUrl);
                },
                child: const Text('Cast HLS Stream'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  CastPlusPlugin.stopCasting();
                },
                child: const Text('Stop Casting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CastRoutePickerView extends StatelessWidget {
  const CastRoutePickerView({super.key});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      // iOS: Show the AVRoutePickerView as a UiKitView
      return const SizedBox(
        width: 44,
        height: 44,
        child: UiKitView(
          viewType: 'AirPlayRoutePicker', // Matches the Swift registration
        ),
      );
    } else if (Platform.isAndroid) {
      // Show a custom Flutter IconButton on Android
      return IconButton(
        icon: const Icon(Icons.cast, size: 28),
        onPressed: () {
          // This calls a custom method in your plugin that handles route selection manually
          CastPlusPlugin.showCastPicker();
        },
      );
    } else {
      // Fallback for other platforms (Windows, macOS, etc.)
      return const SizedBox.shrink();
    }
  }
}
