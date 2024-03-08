import 'package:flutter/services.dart';

class MethodChannelHandler {
  static const platform = MethodChannel('samples.flutter.dev/battery');

  static Future<void> openDirectory(String path) async {
    try {
      await platform.invokeMethod('openDir', {"path": path});
    } catch (e) {
      throw "Couldn't open file: $e";
    }
  }

  static Future<int> getDeviceVersion() async {
    try {
      var x = await platform.invokeMethod('deviceVersion');
      return x ?? -1;
    } catch (e) {
      throw "Error getting andorid verions: $e";
    }
  }
}
