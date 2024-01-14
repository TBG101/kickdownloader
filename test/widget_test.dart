// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  var apiURL =
      "https://kick.com/api/v1/video/cb428424-698f-485c-969b-587057150a63?${DateTime.now().millisecondsSinceEpoch}";
  print("API URL: $apiURL");
  Response response = await Dio().get(
    apiURL,
  );
  print((response));
}
