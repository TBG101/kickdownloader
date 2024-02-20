import 'dart:convert';
import 'dart:io';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as packagePath;

class Logic extends GetxController {
  var url = TextEditingController().obs;
  String apiURL = "";
  String _lastVideoLink = "";
  RxBool foundVideo = false.obs;
  var downloading = false;
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
  int notificationId = 0;
  RxList<Map> completedVideos = <Map>[].obs;

  // cancel token for dio()
  late CancelToken cancel;

  // Open Hive
  late Box box;

  final GlobalKey<AnimatedListState> animatedListKey =
      GlobalKey<AnimatedListState>();

  Future<void> initHive() async {
    box = Hive.box("video");
  }

  void addVideoToHive() {
    box.put("video", completedVideos.value);
  }

  @override
  void onReady() async {
    // TODO: implement onReady
    await initHive();
    var listOfVideos = box.get("video");
    selectedDirectory.value = box.get("savePath");

    if (listOfVideos != null) {
      print(listOfVideos);
      // completedVideos.addAll(iterable)
      completedVideos.value =
          (listOfVideos as List).map((e) => e as Map).toList();
      completedVideos.refresh();
    } else {
      box.put("video", <Map<dynamic, dynamic>>[]);
    }

    super.onReady();
  }

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
      apiURL =
          "https://kick.com/api/v1/video/$_id?${DateTime.now().millisecondsSinceEpoch}";
      print("API URL: $apiURL");
      var response = await Dio().get(
        apiURL,
      );
      if (response.statusCode == 200) {
        print("RESPONSE: 200");
        videoData = json.decode(response.data);
        apiURL = _id;
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
        "Thimbnail link: https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp");
    return "https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp";
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
      if (!File("$path/$element").existsSync()) {
        if (kDebugMode) {
          print("FILE $element NOT DOWNLOADED");
        }
        var r = await downloadTS(downloadPath, element, cancel);

        await saveTS(path, r?.data, "$element.ts");
      } else {
        if (kDebugMode) {
          print("File exist");
        }
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
        break;
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
    // Meaning that we are going to download the whole stream if endtime == -1
    return endTime == -1 ? -1 : overflowTime;
  }

  Future<void> createDownloadNotifcation(
      int id, String title, String body) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: id,
      autoDismissible: false,
      channelKey: "channel",
      title: title,
      body: body,
      category: NotificationCategory.Progress,
      notificationLayout: NotificationLayout.ProgressBar,
      progress: 0,
      locked: true,
    ));
  }

  Future<void> updateNotification(
      int id, List file, String title, String body) async {
    videoDownloadPercentage.value =
        (videoDownloadParts / (file.length * 100)) * 100;
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: title,
            body: body,
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: videoDownloadPercentage.value,
            locked: true,
            autoDismissible: false));
  }

  Future<void> updateNotificationEnd(
      int id, String title, String body, bool locked) async {
    await AwesomeNotifications().createNotification(
        content: NotificationContent(
            id: id,
            channelKey: "channel",
            title: title,
            body: body,
            category: NotificationCategory.Progress,
            notificationLayout: NotificationLayout.ProgressBar,
            progress: 100,
            locked: locked));
  }

  Future<void> downloadVOD() async {
    videoDownloadPercentage.value = 0;
    videoDownloadParts = 0;
    notificationId++;
    downloading = true;
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
    cancel = CancelToken();

    await createDownloadNotifcation(notificationId, 'Started downloading VOD',
        "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}");

    int? overflowTime = await writeGeneratedText(
        _selectedDirectory, playlist, endTime, startTime);
    playlist.clear();
    var file = File("$_selectedDirectory/generated.txt").readAsLinesSync();

    for (String element in file) {
      while (queeList.length >= 5) {
        updateNotification(
            notificationId,
            file,
            'Downloading VOD ${videoDownloadPercentage.value.toStringAsFixed(0)}%',
            "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}");
        if (!downloading) {
          break;
        }
        await waitTimer();
      }
      if (!downloading) {
        cancel.cancel();
        break;
      }
      queeList.add(int.parse(element.replaceAll(".ts", "")));
      print("downloading $element");
      downloadTS(downloadURL, element, cancel).then((tsFile) {
        queeList.remove(int.parse(element.replaceAll(".ts", "")));
        saveTS("$_selectedDirectory/", tsFile?.data, element);
      });
    }

    while (queeList.isNotEmpty) {
      if (!downloading) {
        cancel.cancel();
        break;
      }
      await waitTimer();
      updateNotification(
          notificationId,
          file,
          'Downloading VOD ${videoDownloadPercentage.value.toStringAsFixed(0)}%',
          "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}");
    }
    if (downloading) {
      await checkTSfiles(_selectedDirectory, downloadURL);
      await updateNotificationEnd(
          notificationId,
          'Converting to MP4',
          "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}",
          true);
      String? path;
      if (endTime == -1) {
        path = await mergeToMp4(_selectedDirectory, null, null);
      } else {
        path = await mergeToMp4(
            _selectedDirectory, overflowTime ?? 0, (endTime! - startTime!));
      }
      await updateNotificationEnd(
          notificationId,
          'Download Completed',
          "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}",
          false);
      if (path != null && downloading) {
        completedVideos.add({
          "streamer": queeVideoDownload[0]["data"]["livestream"]["channel"]
              ["user"]["username"],
          "title": queeVideoDownload[0]["data"]["livestream"]["session_title"],
          "path": path,
          "image": queeVideoDownload[0]["image"],
        });
      }
      completedVideos.refresh();
      addVideoToHive();
    } else {
      try {
        Directory(_selectedDirectory).deleteSync(recursive: true);
      } catch (e) {
        print("error on deletion of folder error is : $e");
      }
      downloading = true;
      AwesomeNotifications().dismiss(notificationId);
    }

    queeVideoDownload.removeAt(0);
    if (queeVideoDownload.isNotEmpty && downloading) {
      downloadVOD();
    } else {
      downloading = false;
    }
  }

  int convertToMillisecond(int h, int m, int s) {
    return (h * 60 * 60 + m * 60 + s) * 1000;
  }

  void downloadVodDataBtn() async {
    requestPermission();
    if (foundVideo.value) {
      if (selectedDirectory.value == null) {
        selectedDirectory.value = await FilePicker.platform.getDirectoryPath();
        box.put("savePath", selectedDirectory.value);
      }

      if (startHour.value.text != "" &&
          startMinute.value.text != "" &&
          startSecond.value.text != "" &&
          endHour.value.text != "" &&
          endMinute.value.text != "" &&
          endSecond.value.text != "") {
        // turn all time to milliseconds
        var starttime = convertToMillisecond(
            int.parse(startHour.value.text),
            int.parse(startMinute.value.text),
            int.parse(startSecond.value.text));
        var endtime = convertToMillisecond(
          int.parse(endHour.value.text),
          int.parse(endMinute.value.text),
          int.parse(endSecond.value.text),
        );
        queeVideoDownload.add(
          {
            "image": link.value,
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
          "image": link.value,
          "quality": valueSelected.value,
          "downloading": false,
          "start": 0,
          "end": -1,
          "data": videoData,
          "savePath":
              "${selectedDirectory.value!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().millisecondsSinceEpoch}] ${videoData!["livestream"]["channel"]["user"]["username"]}"
        });
      }

      if (queeVideoDownload[0]["downloading"] == false &&
          downloading == false) {
        downloadVOD();
      }
    }
  }

  Future<String?> mergeToMp4(
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
      return filename;
    } catch (e) {
      print("error on converting to mp4 : $e");
    }
    return null;
  }

  Future downloadTS(String path, String tsFileNB, CancelToken cancel) async {
    try {
      int lastCount = 0;
      var responseBytes = await Dio().get(
        path + tsFileNB,
        onReceiveProgress: (count, total) {
          videoDownloadParts += ((count - lastCount) / total) * 100;
          lastCount = count;
        },
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      return responseBytes;
    } catch (e) {
      print("problem downloding ts error is: $e");
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

  void requestPermission() async {
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
    if (url.value.text.isEmpty || url.value.text == _lastVideoLink) return;
    _lastVideoLink = url.value.text;
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

  cancelDownload() {
    downloading = false;
  }

  Map<dynamic, dynamic> deleteFileDropdown(int index) {
    try {
      Directory(packagePath.dirname(completedVideos[index]["path"]))
          .delete(recursive: true);
    } catch (e) {
      throw "error on deleted video : $e";
    }
    var deletedElement = completedVideos.removeAt(index);
    completedVideos.refresh();
    addVideoToHive();
    return deletedElement;
  }
}
