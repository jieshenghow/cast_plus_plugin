import 'package:flutter/material.dart';
import 'package:cast_plus_plugin/cast_plus_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize the casting plugin
    CastPlusPlugin.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Cast Plus Plugin Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  CastPlusPlugin.showCastPicker();
                },
                child: const Text('Show Cast / AirPlay Picker'),
              ),
              ElevatedButton(
                onPressed: () {
                  const url = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
                  CastPlusPlugin.castUrl(url);
                },
                child: const Text('Cast URL'),
              ),
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
