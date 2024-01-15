import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
    var downloadURL = videoData!["source"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");

    print(downloadURL + "playlist.m3u8");
    List<String> playlist = await getPlaylist(downloadURL);

    if (startTime == null && endTime == null) {
      for (var i = 0; i < playlist.length; i++) {
        if (playlist[i].contains("#EXTINF")) {
          var line = playlist[i];
          line = line.replaceAll("#EXTINF:", "");
          line = line.replaceAll(",", "");

          print(playlist[i + 1]);
          Response tsFile = await downloadTS(downloadURL + playlist[i + 1]);
          saveTS("$selectedDirectory/${playlist[i + 1]}", tsFile.data);
        }
        // IMPLEMENT TS MERGE TO MP4
      }
      print("DONE DOWNLOADING TS ");
    } else {
      var timeMilliseconds = 0;
      for (int i = 0; i < playlist.length; i++) {
        if (playlist[i].contains("#EXTINF:")) {
          if (timeMilliseconds >= endTime!) {
            print("ENDED TS WITH: $timeMilliseconds");
            // IMPLEMENT TS MERGE TO MP4
            break;
          }
          var line = playlist[i];
          line = line.replaceAll("#EXTINF:", "");
          line = line.replaceAll(",", "");

          if (timeMilliseconds >= startTime! ||
              timeMilliseconds + double.parse(line) * 60 > startTime) {
            print("Downloading ${playlist[i + 1]}");
            Response tsFile = await downloadTS(downloadURL + playlist[i + 1]);
            saveTS("$selectedDirectory/${playlist[i + 1]}", tsFile.data);
          }

          timeMilliseconds =
              timeMilliseconds + (double.parse(line) * 60).toInt();
        }
      }
    }
  }

  downloadTS(path) async {
    return await Dio().get(
      path,
      onReceiveProgress: (count, total) {
        if (total != -1) {
          print("${(count / total * 100).toStringAsFixed(0)}%");
        }
      },
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: false,
      ),
    );
  }

  saveTS(String savePath, List<int> data) {
    File file = File(savePath);
    var raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(data);
  }

  getPlaylist(downloadURL) async {
    return (await Dio().get(downloadURL + "playlist.m3u8")).data.split("\n");
  }

  requestPermission() async {
    await Permission.manageExternalStorage.request();
  }
}
