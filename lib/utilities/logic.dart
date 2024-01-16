import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
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
    List<int> queeList = [];
    File("$selectedDirectory/generated.txt").createSync(recursive: true);
    if (startTime == null && endTime == null) {
      for (var i = 0; i < playlist.length; i++) {
        if (playlist[i].contains("#EXTINF")) {
          var line = playlist[i];
          line = line.replaceAll("#EXTINF:", "");
          line = line.replaceAll(",", "");

          print(playlist[i + 1]);
          if (queeList.length < 5) {
            queeList.add(int.parse(playlist[i + 1].replaceAll(".ts", "")));
          } else {
            while (queeList.length >= 5) {
              await waitTimer(); // wait for a download thread to finish
              print('Waiting for the list length to become smaller than 5...');
            }
          }
          downloadTS(downloadURL, playlist[i + 1]).then((tsFile) {
            queeList.remove(int.parse(playlist[i + 1].replaceAll(".ts", "")));
            saveTS("$selectedDirectory/", tsFile?.data, playlist[i + 1]);
          });
        }
        // IMPLEMENT TS MERGE TO MP4
      }
      print("DONE DOWNLOADING TS ");
    } else {
      var timeMilliseconds = 0;
      for (int i = 0; i < playlist.length; i++) {
        if (playlist[i].contains("#EXTINF:")) {
          if (timeMilliseconds >= endTime!) {
            while (queeList.isNotEmpty) {
              await waitTimer(); // wait for a download thread to finish
            }
            print("ENDED TS WITH: $timeMilliseconds");

            break;
          }
          var line = playlist[i];
          line = line.replaceAll("#EXTINF:", "");
          line = line.replaceAll(",", "");

          if (timeMilliseconds >= startTime! ||
              timeMilliseconds + double.parse(line) * 60 > startTime) {
            print("Downloading ${playlist[i + 1]}");
            if (queeList.length < 5) {
              queeList.add(int.parse(playlist[i + 1].replaceAll(".ts", "")));
            } else {
              while (queeList.length >= 5) {
                await waitTimer();
              }
            }

            downloadTS(downloadURL, playlist[i + 1]).then((tsFile) async {
              await saveTS(
                  "$selectedDirectory/", tsFile?.data, playlist[i + 1]);
              queeList.remove(int.parse(playlist[i + 1].replaceAll(".ts", "")));
            });
          }

          timeMilliseconds =
              timeMilliseconds + (double.parse(line) * 60).toInt();
        }
      }
    }
  }

  Future<void> mergeToMp4(path) async {
    var directory = Directory(path);
    List<File> tsFiles = directory
        .listSync()
        .where((file) => file.path.endsWith('.ts'))
        .cast<File>()
        .toList(growable: false);
    tsFiles.sort((a, b) => a.path.compareTo(b.path));
    print(tsFiles);
    File outputFile =
        File('$path/all.ts'); // Replace with the desired output path
    try {
      // Open the output file in write mode (create if not exists)
      RandomAccessFile outputRandomAccessFile =
          outputFile.openSync(mode: FileMode.write);

      // Iterate through each .ts file and append its content to the output file
      for (File tsFile in tsFiles) {
        RandomAccessFile inputRandomAccessFile =
            tsFile.openSync(mode: FileMode.read);
        outputRandomAccessFile.writeFromSync(
            inputRandomAccessFile.readSync(inputRandomAccessFile.lengthSync()));
        inputRandomAccessFile.closeSync();
      }

      await outputRandomAccessFile.close();

      print('Concatenation successful!');

      // convert to mp4
      String ffmpegCommand =
          '-i "$path/all.ts" -c:v libx264 -c:a copy "$path/${videoData!["livestream"]["channel"]["user"]["username"]}-${videoData!["livestream"]["created_at"].split(" ")[0]}.mp4"';

      await FFmpegKit.executeAsync(
        ffmpegCommand,
        (session) {
          session.getState().then((value) => print(value));
        },
        (log) => print((log.getMessage())),
      );
      deleteTs(tsFiles, path);
    } catch (e) {
      print('Error during concatenation: $e');
    }
  }

  Future<Response?> downloadTS(String path, String tsFileNB) async {
    try {
      var r = await Dio().get(
        path + tsFileNB,
        onReceiveProgress: (count, total) {},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      return r;
    } catch (e) {
      print("object");
      return null;
    }
  }

  Future<void> saveTS(
      String savePath, List<int>? data, String tsFileName) async {
    if (data == null) {
      File("${savePath}generated.txt").writeAsString("$tsFileName e\n");
      return;
    }
    File("${savePath}generated.txt").writeAsString("$tsFileName d\n");
    File file = File(savePath + tsFileName);
    var raf = file.openSync(mode: FileMode.write);
    await raf.writeFrom(data);
  }

  getPlaylist(downloadURL) async {
    return (await Dio().get(downloadURL + "playlist.m3u8")).data.split("\n");
  }

  requestPermission() async {
    await Permission.manageExternalStorage.request();
  }

  deleteTs(List<File> tsFiles, path) async {
    for (var file in tsFiles) {
      if (file.existsSync()) {
        print("deleting ${file.path}");
        try {
          await file.delete();
        } catch (e) {
          debugPrint("bug on fileTs list deletion");
        }
      }
    }
    try {
      File("$path/all.ts").delete();
    } catch (e) {
      debugPrint("bug on all.ts deletion");
    }
  }

  Future waitTimer() async {
    return await Future.delayed(const Duration(seconds: 1));
  }
}
