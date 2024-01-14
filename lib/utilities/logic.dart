import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Logic {
  var url = TextEditingController();
  var apiURL = "";
  var foundVideo = false;

  Map<String, dynamic>? videoData;
  List<String> resolutions = [];

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
      Response response = await Dio().get(
        apiURL,
      );
      if (response.statusCode == 200) {
        print("RESPONSE: 200");
        videoData = json.decode(response.data);
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

  getVidQuality() async {
    final Directory tempDir = await getTemporaryDirectory();
    var response = await Dio().get(
      videoData!["source"],
    );
    extractResolutionsFromMaster(response.data);
  }

  void extractResolutionsFromMaster(String inputString) {
    resolutions = [];
    List<String> lines = inputString.split('\n');
    for (String line in lines) {
      if (line.contains("/playlist.m3u8")) {
        resolutions.add(line.replaceAll("/playlist.m3u8", ""));
      }
    }
  }

  downloadVOD(String slectedQuality, String selectedDirectory, int? startTime,
      int? endTime) async {
    print(startTime);
    print(endTime);
    var downloadURL = videoData!["source"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");
  }
}
