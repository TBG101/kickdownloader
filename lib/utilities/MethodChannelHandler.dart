import 'package:flutter/services.dart';

class MethodChannelHandler {
  final platform = const MethodChannel('samples.flutter.dev/battery');

  Future<void> openDirectory(String path) async {
    try {
      await platform.invokeMethod('openDir', {"path": path});
    } catch (e) {
      throw "Couldn't open file: $e";
    }
  }
}
