import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/session_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class Logic extends GetxController {
  var url = TextEditingController().obs;
  RxString apiURL = "".obs;
  RxBool foundVideo = false.obs;

  Map<String, dynamic>? videoData;
  var resolutions = <String>[].obs;
  RxDouble videoDownloadPercentage = 0.0.obs;
  var videoDownloadParts = 0.0;

  var link =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Aspect_ratio_-_16x9.svg/1200px-Aspect_ratio_-_16x9.svg.png"
          .obs;
  RxInt pageSelector = 0.obs;
  RxString streamer = "".obs;
  RxString title = "".obs;
  RxString stramDate = "".obs;
  RxString streamLength = "".obs;
  RxDouble gradientOpacity = 0.4.obs;
  RxBool startValue = false.obs;
  RxBool endValue = false.obs;
  var valueSelected = Rxn<String>();
  Rx<String?> selectedDirectory = Rxn<String>();

  // text controllers
  var startHour = TextEditingController().obs;
  var startMinute = TextEditingController().obs;
  var startSecond = TextEditingController().obs;
  var endHour = TextEditingController().obs;
  var endMinute = TextEditingController().obs;
  var endSecond = TextEditingController().obs;
  var queeVideoDownload = [].obs;

  bool validURL() {
    RegExp validLinkPattern = RegExp(r'^https://kick.com/video/[a-zA-Z0-9-]+$');
    if (validLinkPattern.hasMatch(url.value.text)) {
      print("LINK IS VALID");
      return true;
    } else {
      print("LINK NOT VALID");
      return false;
    }
  }

  Future<void> getURL() async {
    if (validURL()) {
      String _id = url.value.text.split('/').last;
      apiURL.value =
          "https://kick.com/api/v1/video/$_id?${DateTime.now().millisecondsSinceEpoch}";
      print("API URL: $apiURL");
      var response = await Dio().get(
        apiURL.value,
      );
      if (response.statusCode == 200) {
        print("RESPONSE: 200");
        videoData = json.decode(response.data);
        apiURL.value = _id;
        foundVideo.value = true;
      } else {
        foundVideo.value = false;
        // implement exception
        throw Exception('Failed to load data');
      }
    } else {
      foundVideo.value = false;
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
    resolutions.clear();
    List<String> lines = inputString.split('\n');
    for (String line in lines) {
      if (line.contains("/playlist.m3u8")) {
        resolutions.add(line.replaceAll("/playlist.m3u8", ""));
      }
    }
    resolutions.refresh();
  }

  checkTSfiles(String path, String downloadPath) async {
    // IMPLEMENT CHECK TS FILES
    File file = File("$path/generated.txt");
    file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((element) async {
      if (!File("$path/$element.ts").existsSync()) {
        print("FILE $element.ts NOT DOWNLOADED");
        var r = await downloadTS(downloadPath, "$element.ts");
        await saveTS(path, r?.data, "$element.ts");
      }
    });
  }

  Future<int?> writeGeneratedText(String savepath, List<String> playlist,
      int? endTime, int? startTime) async {
    if (endTime == null || startTime == null) return null;
    File("$savepath/generated.txt").createSync(recursive: true);
    var timeMilliseconds = 0;
    int? overflowTime;
    for (int i = 0; i < playlist.length; i++) {
      if (playlist[i].contains("#EXTINF:") == false) {
        // Go to the iteration
        continue;
      }
      if (timeMilliseconds >= endTime) {
        print("ENDED TS WITH: $timeMilliseconds");
        return overflowTime;
      }
      var line = playlist[i];
      line = line.replaceAll("#EXTINF:", "");
      line = line.replaceAll(",", "");
      if (timeMilliseconds >= startTime ||
          timeMilliseconds + double.parse(line) * 1000 > startTime) {
        overflowTime ??= startTime - timeMilliseconds;
        await File("$savepath/generated.txt")
            .writeAsString("${playlist[i + 1]}\n", mode: FileMode.append);
      }
      timeMilliseconds = timeMilliseconds + (double.parse(line) * 1000).toInt();
    }
    return null;
  }

  Future<void> createDownloadNotifcation(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: 'Started downloading VOD',
            body: 'VOD',
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: 0,
            locked: true));
  }

  Future<void> updateNotification(int id, List file) async {
    videoDownloadPercentage.value =
        (videoDownloadParts / (file.length * 100)) * 100;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title:
                'Started downloading VOD ${videoDownloadPercentage.value.toStringAsFixed(0)}%',
            body: 'VOD',
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: videoDownloadPercentage.value,
            locked: true));
  }

  Future<void> updateNotificationEnd(int id) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: 'Download Completed',
            body: 'VOD',
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: 100,
            locked: true));
  }

  downloadVOD() async {
    // ignore: no_leading_underscores_for_local_identifiers
    String _selectedDirectory = queeVideoDownload[0]["savePath"];
    List<int> queeList = [];
    var slectedQuality = queeVideoDownload[0]["quality"];
    int? startTime = queeVideoDownload[0]["start"];
    int? endTime = queeVideoDownload[0]["end"];
    var downloadURL = queeVideoDownload[0]["data"]["source"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");
    print(downloadURL + "playlist.m3u8");
    List<String> playlist = await getPlaylist(downloadURL);

    queeVideoDownload[0]["downloading"] = true;
    videoDownloadPercentage.value = 0;
    videoDownloadParts = 0;

    await createDownloadNotifcation(1);

    int? overflowTime = await writeGeneratedText(
        _selectedDirectory, playlist, endTime, startTime);
    playlist.clear();
    var file = File("$_selectedDirectory/generated.txt").readAsLinesSync();
    file.forEach((element) async {
      while (queeList.length >= 5) {
        updateNotification(1, file);
        await waitTimer();
      }
      queeList.add(int.parse(element.replaceAll(".ts", "")));
      print("downloading $element");
      downloadTS(downloadURL, element).then((tsFile) {
        queeList.remove(int.parse(element.replaceAll(".ts", "")));
        saveTS("$_selectedDirectory/", tsFile?.data, element);
      });
    });
    while (queeList.isNotEmpty) {
      await waitTimer();
      updateNotification(1, file);
    }
    await checkTSfiles(_selectedDirectory, downloadURL);
    await updateNotificationEnd(10);

    if (endTime == null && startTime == null) {
      await mergeToMp4(_selectedDirectory, null, null);
    } else {
      await mergeToMp4(
          _selectedDirectory, overflowTime ?? 0, (endTime! - startTime!));
    }
    queeVideoDownload.removeAt(0);
    if (queeVideoDownload.isNotEmpty) {
      downloadVOD();
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
    } catch (e) {
      print('Error during concatenation: $e');
    }
    // convert to mp4
    var x = "";
    if (overflowStart != null && overflowEnd != null) {
      x = "-ss ${formatMilliseconds(overflowStart)} -t ${formatMilliseconds(overflowEnd)}";
    }

    String filename =
        "$path/[${queeVideoDownload[0]["data"]["livestream"]["created_at"].split(" ")[0]}] - ${videoData!["livestream"]["channel"]["user"]["username"]} ${videoData!["livestream"]["session_title"]} - ${DateTime.now().millisecondsSinceEpoch}.mp4";
    String ffmpegCommand =
        '-y -i "$path/all.ts" $x -c:v libx264 -c:a copy "$filename"';
    try {
      await FFmpegKit.execute(ffmpegCommand); // convert the ts file into mp4
      print("done converting");
      await deleteTs(tsFiles, path);
      print("done deleting");
      MediaScanner.loadMedia(path: filename);
    } catch (e) {
      print("error on converting to mp4 : $e");
    }
  }

  Future downloadTS(String path, String tsFileNB) async {
    try {
      int lastCount = 0;
      var responseBytes = await Dio().get(
        path + tsFileNB,
        onReceiveProgress: (count, total) {
          videoDownloadParts += ((count - lastCount) / total) * 100;
          lastCount = count;
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      return responseBytes;
    } catch (e) {
      print("problem downloding ts $e");
      return null;
    }
  }

  Future<void> saveTS(
      String savePath, List<int>? data, String tsFileName) async {
    if (data == null) {
      return;
    }
    File file = File(savePath + tsFileName);
    var raf = file.openSync(mode: FileMode.write);
    await raf.writeFrom(data);
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

  void getVodData() {
    if (url.value.text.isEmpty) return;

    foundVideo.value = false;
    getURL().then((_) async {
      await getVidQuality();
      print(resolutions);
      var duration = Duration(
          hours: 0,
          seconds: 0,
          minutes: 0,
          milliseconds: videoData!["livestream"]["duration"] as int);

      streamer.value = videoData!["livestream"]["channel"]["slug"];
      title.value = videoData!["livestream"]["session_title"];
      stramDate.value = videoData!["livestream"]["start_time"].split(" ")[0];
      streamLength.value = duration.toString().split('.')[0];

      link.value = thumbnailLink();
      print(resolutions.first);
      valueSelected.value = resolutions.first;
      print(videoData);
    });
  }

  void downloadVodDataBtn() async {
    requestPermission();
    if (foundVideo.value) {
      selectedDirectory.value ??= await FilePicker.platform.getDirectoryPath();
      if (startHour.value.text != "" &&
          startMinute.value.text != "" &&
          startSecond.value.text != "" &&
          endHour.value.text != "" &&
          endMinute.value.text != "" &&
          endSecond.value.text != "") {
        // turn all time to milliseconds
        var starttime = (int.parse(startHour.value.text) * 60 * 60 +
                int.parse(startMinute.value.text) * 60 +
                int.parse(startSecond.value.text)) *
            1000;
        var endtime = (int.parse(endHour.value.text) * 60 * 60 +
                int.parse(endMinute.value.text) * 60 +
                int.parse(endSecond.value.text)) *
            1000;
        queeVideoDownload.add(
          {
            "quality": valueSelected.value,
            "downloading": false,
            "start": starttime,
            "end": endtime,
            "data": videoData,
            "savePath":
                "${selectedDirectory.value!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().millisecondsSinceEpoch}] ${videoData!["livestream"]["channel"]["user"]["username"]}"
          },
        );
      } else {
        queeVideoDownload.add({
          "quality": valueSelected.value,
          "downloading": false,
          "start": null,
          "end": null,
          "data": videoData,
          "savePath":
              "${selectedDirectory.value!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().millisecondsSinceEpoch}] ${videoData!["livestream"]["channel"]["user"]["username"]}"
        });
      }
      queeVideoDownload.refresh();
      if (queeVideoDownload.isEmpty) await downloadVOD();
    }
  }
}
