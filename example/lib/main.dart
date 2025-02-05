// example/lib/main.dart

import 'dart:io' show Platform;

import 'package:cast_plus_plugin/cast_plus_plugin.dart';
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
  List<CastDevice> _devices = [];
  bool _isCasting = false;

  @override
  void initState() {
    super.initState();
    CastPlusPlugin.initialize();
    _fetchAvailableDevices();
  }

  Future<void> _fetchAvailableDevices() async {
    List<CastDevice> devices = await CastPlusPlugin.getAvailableCastDevices();
    setState(() {
      _devices = devices;
    });
  }

  void _castToDevice(CastDevice device) {
    const sampleVideoUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'; // Replace with your video URL
    // Note: URL is the first parameter, device.id is the second.
    CastPlusPlugin.castToDevice(sampleVideoUrl, device.id);
    setState(() {
      _isCasting = true;
    });
  }

  void _castToAirPlay() {
    const sampleVideoUrl = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8'; // Replace with your video URL
    CastPlusPlugin.castToAirPlay(sampleVideoUrl);
    setState(() {
      _isCasting = true;
    });
  }

  void _stopCasting() {
    CastPlusPlugin.stopCasting();
    setState(() {
      _isCasting = false;
    });
  }

  void _showCastPicker() {
    CastPlusPlugin.showCastPicker();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Cast Plugin Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cast Video Example'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Cast Device List
                const Text(
                  'Available Cast Devices:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                _devices.isEmpty
                    ? const Text('No devices found.')
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    return ListTile(
                      title: Text(device.name),
                      onTap: () => _castToDevice(device),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // AirPlay Button (iOS only)
                if (Platform.isIOS)
                  ElevatedButton(
                    onPressed: _castToAirPlay,
                    child: const Text('Cast to AirPlay'),
                  ),

                // Show Cast Picker (Android only)
                if (Platform.isAndroid)
                  ElevatedButton(
                    onPressed: _showCastPicker,
                    child: const Text('Show Cast Picker'),
                  ),

                const SizedBox(height: 20),

                // Stop Casting Button
                ElevatedButton(
                  onPressed: _isCasting ? _stopCasting : null,
                  child: const Text('Stop Casting'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
