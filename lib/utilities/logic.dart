import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/session_state.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class Logic {
  var url = TextEditingController();
  var apiURL = "";
  var foundVideo = false;

  Map<String, dynamic>? videoData;
  List<String> resolutions = [];
  double videoDownloadPercentage = 0;
  bool downloadingVideo = false;

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
    List<int> queeList = [];
    var downloadURL = videoData!["source"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");

    print(downloadURL + "playlist.m3u8");
    List<String> playlist = await getPlaylist(downloadURL);
    int? overflowTime;

    File("$selectedDirectory/generated.txt").createSync(recursive: true);
    downloadingVideo = true;
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
        await Future.delayed(const Duration(milliseconds: 100));
      }
      print("DONE DOWNLOADING TS ");
    } else {
      var timeMilliseconds = 0;
      for (int i = 0; i < playlist.length; i++) {
        if (playlist[i].contains("#EXTINF:")) {
          videoDownloadPercentage = (timeMilliseconds / endTime!) * 100;
          if (timeMilliseconds >= endTime!) {
            while (queeList.isNotEmpty) {
              await waitTimer(); // wait for a download thread to finish
            }
            print("ENDED TS WITH: $timeMilliseconds");
            videoDownloadPercentage = 100;
            break;
          }
          var line = playlist[i];
          line = line.replaceAll("#EXTINF:", "");
          line = line.replaceAll(",", "");

          if (timeMilliseconds >= startTime! ||
              timeMilliseconds + double.parse(line) * 1000 > startTime) {
            overflowTime ??= startTime - timeMilliseconds;
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
              timeMilliseconds + (double.parse(line) * 1000).toInt();
        }
      }
    }
    await checkTSfiles(selectedDirectory, downloadURL);

    if (endTime == null && startTime == null) {
      await mergeToMp4(selectedDirectory, null, null);
    } else {
      await mergeToMp4(
          selectedDirectory, overflowTime ?? 0, (endTime! - startTime!));
    }
  }

  Future<void> mergeToMp4(
      String path, int? overflowStart, int? overflowEnd) async {
    var directory = Directory(path);
    List<File> tsFiles = directory
        .listSync()
        .where((file) => file.path.endsWith('.ts'))
        .cast<File>()
        .toList();
    tsFiles.sort((a, b) => a.path.compareTo(b.path));
    print(tsFiles);
    File outputFile = File('$path/all.ts');
    try {
      RandomAccessFile outputRandomAccessFile =
          outputFile.openSync(mode: FileMode.write);

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
      // implement the cut video
      var x = "";
      if (overflowStart != null && overflowEnd != null) {
        x = "-ss ${formatMilliseconds(overflowStart)} -t ${formatMilliseconds(overflowEnd)}";
      }
      // using this -ss 00:05:10 -to 00:15:30

      String filename =
          "$path/[${videoData!["livestream"]["created_at"].split(" ")[0]}] ${videoData!["livestream"]["channel"]["user"]["username"]} - ${videoData!["livestream"]["channel"]["user"]["username"]} - ${videoData!["livestream"]["channel"]["user"]["username"]} ${videoData!["livestream"]["session_title"]} - ${DateTime.now().millisecondsSinceEpoch}.mp4";
      String ffmpegCommand =
          '-y -i "$path/all.ts" $x -c:v libx264 -c:a copy "$filename"';

      await FFmpegKit.executeAsync(
        ffmpegCommand,
        (session) {
          session.getState().then((value) async {
            print(value);
            if (value == SessionState.completed) {
              await deleteTs(tsFiles, path);
              print("done deleting");
            }
          });
        },
        (log) => print((log.getMessage())),
      );
    } catch (e) {
      print('Error during concatenation: $e');
    }
  }

  Future<Response?> downloadTS(String path, String tsFileNB) async {
    try {
      var responseBytes = await Dio().get(
        path + tsFileNB,
        onReceiveProgress: (count, total) {},
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      return responseBytes;
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
    File file = File(savePath + tsFileName);
    var raf = file.openSync(mode: FileMode.write);
    await raf.writeFrom(data);
    await File("${savePath}generated.txt").writeAsString("$tsFileName d\n");
    print("saving $tsFileName");
  }

  getPlaylist(downloadURL) async {
    return (await Dio().get(downloadURL + "playlist.m3u8")).data.split("\n");
  }

  requestPermission() async {
    await Permission.manageExternalStorage.request();
  }

  deleteTs(List<File> tsFiles, path) async {
    print(tsFiles);
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
      await File("$path/all.ts").delete();
      await File("$path/generated.txt").delete();
    } catch (e) {
      debugPrint("bug on all.ts deletion");
    }
  }

  Future waitTimer() async {
    return await Future.delayed(const Duration(seconds: 1));
  }

  checkTSfiles(String path, String downloadPath) async {
    File file = File("$path/generated.txt");
    final lines = await file.readAsLines(encoding: utf8);
    for (var line in lines) {
      if (line.contains("e")) {
        print("FILE $line NOT DOWNLOADED");
        var name = line.split(" ")[0];
        var r = await downloadTS(downloadPath, name);
        await saveTS(path, r?.data, name);
      }
    }
  }

  String formatMilliseconds(int milliseconds) {
    // Calculate hours, minutes, seconds, and remaining milliseconds
    int hours = (milliseconds ~/ (1000 * 60 * 60)) % 24;
    int minutes = (milliseconds ~/ (1000 * 60)) % 60;
    int seconds = (milliseconds ~/ 1000) % 60;
    int remainingMilliseconds = milliseconds % 1000;

    // Format the result as "HOURS:MM:SS.MILLISECONDS"
    String formattedTime = '$hours:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${remainingMilliseconds.toString().padLeft(3, '0')}';

    return formattedTime;
  }
}
