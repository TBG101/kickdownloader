import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:kickdownloader/utilities/NotificationController.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as packagepath;
import 'package:http/http.dart' as http;
import 'package:dio/src/response.dart' as dioresponse;

class Logic extends GetxController {
  final NotificationController _notificationcontroller =
      NotificationController();
  var url = TextEditingController().obs;
  String apiURL = "";
  String lastVideoLink = "";
  RxBool foundVideo = false.obs;
  var downloading = false;
  Map<String, dynamic>? videoData;
  var resolutions = <String>[].obs;

  RxDouble videoDownloadPercentage = 0.0.obs;
  var videoDownloadParts = 0.0;
  RxInt videoDownloadSizeBytes = 0.obs;

  var link = "".obs;
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
  late bool notificationAllowed;

  final _dio = Dio();
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

  void resetAll() {
    startHour.value.text = "";
    startMinute.value.text = "";
    startSecond.value.text = "";
    endHour.value.text = "";
    endMinute.value.text = "";
    endSecond.value.text = "";
    endValue.value = false;
    startValue.value = false;
    streamer.value = "";
    title.value = "";
    stramDate.value = "";
    streamLength.value = "";
    resolutions.clear();
    apiURL = "";
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

  (double, String) formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return (0, "B");
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return (((bytes / pow(1024, i))), suffixes[i]);
  }

  void getVodData() {
    if (url.value.text.isEmpty || url.value.text == lastVideoLink) return;
    lastVideoLink = url.value.text;
    foundVideo.value = false;
    getURL().then((response) async {
      if (response != 200) return;
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

  Future<int> getURL() async {
    if (!validURL()) {
      resetAll();
      foundVideo.value = false;
    }

    String _id = url.value.text.split('/').last;
    apiURL =
        "https://kick.com/api/v1/video/$_id?${DateTime.now().millisecondsSinceEpoch}";
    print("API URL: $apiURL");
    late dioresponse.Response response;

    try {
      response = await _dio.get(
        apiURL,
      );
    } catch (e) {
      foundVideo.value = false;
      resetAll();
      // implement exception
      return 0;
    }

    if (response.statusCode == 200) {
      print("RESPONSE: 200");
      videoData = json.decode(response.data);
      apiURL = _id;
      return 200;
    } else {
      foundVideo.value = false;
      resetAll();
      // implement exception
      return response.statusCode ?? 0;
    }
  }

  thumbnailLink() {
    var x = (videoData!["source"] as String).split("\/");
    print(
        "Thimbnail link: https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp");
    foundVideo.value = true;
    return "https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp";
  }

  Future<void> getVidQuality() async {
    final Directory tempDir = await getTemporaryDirectory();
    var response = await _dio.get(
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

  Future<void> checkTSfiles(String path, String downloadPath) async {
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

  Future<(int?, int?)> writeGeneratedText(String savepath,
      List<String> playlist, int? endTime, int? startTime) async {
    if (endTime == null || startTime == null) return (null, null);
    File("$savepath/generated.txt").createSync(recursive: true);
    var timeMilliseconds = 0;
    int? overflowTime;
    int nbOfTsFiles = 0;
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
        nbOfTsFiles++;
      }
      timeMilliseconds = timeMilliseconds + (double.parse(line) * 1000).toInt();
    }
    // Meaning that we are going to download the whole stream if endtime == -1
    return (endTime == -1 ? -1 : overflowTime, nbOfTsFiles);
  }

  Future<void> createDownloadNotifcation(
      int id, String title, String body) async {
    notificationAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (notificationAllowed) {
      AwesomeNotifications().createNotification(
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
  }

  Future<void> updateNotification(
      int id, List file, String title, String body) async {
    videoDownloadPercentage.value =
        (videoDownloadParts / (file.length * 100)) * 100;
    if (!notificationAllowed) return;

    AwesomeNotifications().createNotification(
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
    if (!notificationAllowed) return;
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

  Future<int> getFileSize(String url) async {
    try {
      http.Response r = await http.head(Uri.parse(url));
      if (r.statusCode == 200) {
        final contentLength = r.headers['content-length'];
        if (contentLength != null) {
          return int.parse(contentLength);
        }
      }
    } catch (e) {
      print("error");
      return -1;
    }
    return -1;
  }

  Future<void> downloadVOD() async {
    videoDownloadPercentage.value = 0;
    videoDownloadParts = 0;
    int? overflowTime;
    int? nbOfTsFiles;
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

    var tsFileSize = await getFileSize(downloadURL + "1.ts");

    queeVideoDownload[0]["downloading"] = true;
    cancel = CancelToken();

    await createDownloadNotifcation(notificationId, 'Started downloading VOD',
        "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}");

    (overflowTime, nbOfTsFiles) = await writeGeneratedText(
        _selectedDirectory, playlist, endTime, startTime);

    // Implement error
    if (nbOfTsFiles == null) return;

    videoDownloadSizeBytes.value = (nbOfTsFiles * tsFileSize);

    var (sizeVid, suffix) = formatBytes(videoDownloadSizeBytes.value, 2);

    playlist.clear();
    var file = File("$_selectedDirectory/generated.txt").readAsLinesSync();

    for (String element in file) {
      while (queeList.length >= 5) {
        var percentage = videoDownloadPercentage.value;
        updateNotification(
            notificationId,
            file,
            'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
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
      var percentage = videoDownloadPercentage.value;

      updateNotification(
          notificationId,
          file,
          'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
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
          "link": queeVideoDownload[0]["link"],
          "image": queeVideoDownload[0]["image"],
        });
        completedVideos.refresh();
        addVideoToHive();
      }
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
    await _notificationcontroller.requestNotification();
    if (_notificationcontroller.status == MyPermissionStatus.deniedForever) {
      // Implement denied
    }

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
        if (starttime == endtime) return;

        queeVideoDownload.add(
          {
            "image": link.value,
            "quality": valueSelected.value,
            "downloading": false,
            "start": starttime,
            "end": endtime,
            "data": videoData,
            "link": lastVideoLink,
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
          "link": lastVideoLink,
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

      var responseBytes = await _dio.get(
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
    return (await _dio.get(downloadURL + "playlist.m3u8")).data.split("\n");
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

  void cancelDownload() {
    downloading = false;
  }

  Map<dynamic, dynamic> deleteFileDropdown(int index) {
    try {
      Directory(packagepath.dirname(completedVideos[index]["path"]))
          .delete(recursive: true);
    } catch (e) {
      throw "error on deleted video : $e";
    }
    var deletedElement = completedVideos.removeAt(index);
    completedVideos.refresh();
    addVideoToHive();
    return deletedElement;
  }

  void showToast(String msg, BuildContext context, double toastWidth) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(180))),
      behavior: SnackBarBehavior.floating,
      width: toastWidth,
    ));
  }

  void copyLinkToClipboard(int index, BuildContext context) {
    Clipboard.setData(
        ClipboardData(text: completedVideos[index]["link"] as String));
    showToast("Coppied URL", context, 140);
  }

  void openDir(int index) {
    print("-----------");
    print(packagepath.dirname(completedVideos[index]["path"]));
    MethodChannelHandler()
        .openDirectory(packagepath.dirname(completedVideos[index]["path"]));
  }
}
