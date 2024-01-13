import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';

class Logic {
  var url = TextEditingController();
  var apiURL = "";
  var foundVideo = false;
  Map<String, dynamic>? videoData;

  bool validURL() {
    RegExp validLinkPattern = RegExp(r'^https://kick.com/video/[a-zA-Z0-9-]+$');

    if (validLinkPattern.hasMatch(url.text)) {
      print("LINK IS VALID");
      return true;
    } else {
      print("LINK NOT VALID");
      return false;
    }
  }

  Future<void> getURL() async {
    if (validURL()) {
      String _id = url.text.split('/').last;
      apiURL =
          "https://kick.com/api/v1/video/$_id?${DateTime.now().millisecondsSinceEpoch}";
      print("API URL: $apiURL");
      Response response = await http.get(Uri.parse(apiURL));
      if (response.statusCode == 200) {
        print("RESPONSE: 200");
        videoData = json.decode(response.body);
        apiURL = _id;
        foundVideo = true;
      } else {
        foundVideo = false;
        // implement exception
        throw Exception('Failed to load data');
      }
    } else {
      foundVideo = false;
      throw Exception('Invalid URL');
    }
  }

  thumbnailLink() {
    var x = (videoData!["source"] as String).split("\/");
    print(
        "Thimbnail link: https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/720.webp");
    return "https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/720.webp";
  }
}
