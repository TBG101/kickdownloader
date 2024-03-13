import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ffmpeg_kit_flutter_https_gpl/ffmpeg_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:kickdownloader/utilities/NotificationController.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as packagepath;
import 'package:http/http.dart' as http;

class Logic extends GetxController {
  final navigatorKey = GlobalKey<NavigatorState>();

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

  bool hasInternet = true;

  final _dio = Dio();
  // cancel token for dio()
  late CancelToken cancel;

  // Open Hive
  late Box box;

  final GlobalKey<AnimatedListState> animatedListKey =
      GlobalKey<AnimatedListState>();

  void checkNetwork() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        print("inter not working");
        hasInternet = false;
      } else {
        hasInternet = true;
        print("internetworking");
      }
    });
  }

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

    Connectivity().checkConnectivity().then(
      (value) {
        if (value == ConnectivityResult.none) hasInternet = false;
      },
    );
    checkNetwork();

    if (listOfVideos != null) {
      print(listOfVideos);
      // completedVideos.addAll(iterable)
      completedVideos.value =
          (listOfVideos as List).map((e) => e as Map).toList();
      completedVideos.refresh();
    } else {
      box.put("video", <Map<dynamic, dynamic>>[]);
    }

    _notificationcontroller.startListener();

    super.onReady();
  }

  (double, String) formatBytes(int bytes) {
    if (bytes <= 0) return (0, "B");
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return (((bytes / pow(1024, i))), suffixes[i]);
  }

  void getVodData(BuildContext context) {
    print(hasInternet);
    if (!hasInternet) {
      showToast("No internet Connection", context, 250);
      return;
    }

    if (url.value.text.isEmpty || url.value.text == lastVideoLink) return;
    lastVideoLink = url.value.text;
    foundVideo.value = false;
    getURL(context).then((response) async {
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
      stramDate.value = videoData!["livestream"]["created_at"].split(" ")[0];
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

  Future<int> getURL(context) async {
    if (!validURL()) {
      resetAll();
      foundVideo.value = false;
      showToast("URL is not valid", context, 300);
    }

    String _id = url.value.text.split('/').last;
    apiURL =
        "https://kick.com/api/v1/video/$_id?${DateTime.now().millisecondsSinceEpoch}";
    print("API URL: $apiURL");
    late Response response;

    try {
      response = await _dio.get(
        apiURL,
      );
    } catch (e) {
      foundVideo.value = false;
      resetAll();
      showToast("Error occured", context, 300);

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
      showToast("Error occured", context, 300);

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

  Future<String> getDownloadedSize(String path) async {
    try {
      // Replace 'path/to/your/file' with the path to your file
      File file = File(path);
      int fileSizeInBytes = await file.length();
      var (size, suffix) = formatBytes(fileSizeInBytes);
      return "${size.toStringAsFixed(2)} $suffix";
    } catch (e) {
      print('Error getting file size: $e');
      return "";
    }
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

    await _notificationcontroller.createDownloadNotifcation(
        notificationId,
        'Started downloading VOD',
        "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}");

    (overflowTime, nbOfTsFiles) = await writeGeneratedText(
        _selectedDirectory, playlist, endTime, startTime);

    // Implement error
    if (nbOfTsFiles == null) return;

    videoDownloadSizeBytes.value = (nbOfTsFiles * tsFileSize);

    var (sizeVid, suffix) = formatBytes(videoDownloadSizeBytes.value);

    playlist.clear();
    var file = File("$_selectedDirectory/generated.txt").readAsLinesSync();

    for (String element in file) {
      while (queeList.length >= 5) {
        var percentage = videoDownloadPercentage.value;
        videoDownloadPercentage.value =
            (videoDownloadParts / (file.length * 100)) * 100;

        _notificationcontroller.updateNotification(
            notificationId,
            file,
            'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
            "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}",
            videoDownloadPercentage.value);

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
      videoDownloadPercentage.value =
          (videoDownloadParts / (file.length * 100)) * 100;

      _notificationcontroller.updateNotification(
          notificationId,
          file,
          'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
          "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}",
          videoDownloadPercentage.value);
    }
    if (downloading) {
      await checkTSfiles(_selectedDirectory, downloadURL);
      await _notificationcontroller.updateNotificationEnd(
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
      await _notificationcontroller.updateNotificationEnd(
          notificationId,
          'Download Completed',
          "Streamer ${queeVideoDownload[0]["data"]["livestream"]["channel"]["user"]["username"]}",
          false);

      DateTime now = DateTime.now();
      String formattedDate = "${now.year}-${(now.month)}-${(now.day)}";
      if (path != null && downloading) {
        var fileSize = await getDownloadedSize(path);
        completedVideos.add({
          "streamDate": queeVideoDownload[0]["streamDate"],
          "streamer": queeVideoDownload[0]["data"]["livestream"]["channel"]
              ["user"]["username"],
          "title": queeVideoDownload[0]["data"]["livestream"]["session_title"],
          "path": path,
          "link": queeVideoDownload[0]["link"],
          "image": queeVideoDownload[0]["image"],
          "DownloadDate": formattedDate,
          "resolution": slectedQuality,
          "size": fileSize
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
      _notificationcontroller.dissmissNotification(notificationId);
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

  Future<void> savePathSelector(BuildContext context) async {
    if (selectedDirectory.value == null) {
      var savePath = await FilePicker.platform.getDirectoryPath();

      if (savePath != "/" && savePath != null) {
        selectedDirectory.value = savePath;
        box.put("savePath", selectedDirectory.value);
        return;
      }
      Widget openSettings = TextButton(
        child: const Text("Open settings"),
        onPressed: () {},
      );

      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: const Text("Storage Permission Denied"),
        content: const Text(
            "The app needs Storage permission to save VOD, without it the app won't work.\nOpen the settings to enable Storage Permission"),
        actions: [
          openSettings,
        ],
      );

      // show the dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          },
        );
      }
    }
  }

  void downloadVodDataBtn(BuildContext context) async {
    if (!hasInternet) {
      // IMPLEMENT NO INTERNET
      showToast("No internet Connection", context, 50);
      return;
    }
    if (!foundVideo.value && !context.mounted) return;

    await PermissionHandler.requestNotificationPermission();

    await PermissionHandler.requestStoragePermission();
    if (await PermissionHandler.getStorageStatus() != true && context.mounted) {
      _notificationcontroller.showAlertDialog(context);
    }

    await savePathSelector(context);

    if (selectedDirectory.value == null || selectedDirectory.value == "/") {
      // implement disclaimer for path is not available
      return;
    }

    if (startHour.value.text != "" &&
        startMinute.value.text != "" &&
        startSecond.value.text != "" &&
        endHour.value.text != "" &&
        endMinute.value.text != "" &&
        endSecond.value.text != "") {
      // turn all time to milliseconds
      var starttime = convertToMillisecond(int.parse(startHour.value.text),
          int.parse(startMinute.value.text), int.parse(startSecond.value.text));
      var endtime = convertToMillisecond(
        int.parse(endHour.value.text),
        int.parse(endMinute.value.text),
        int.parse(endSecond.value.text),
      );
      if (starttime == endtime) return;

      queeVideoDownload.add(
        {
          "streamDate":
              (videoData!["livestream"]["created_at"].split(" ")[0] as String)
                  .replaceAll("-", "\\"),
          "image": link.value,
          "quality": valueSelected.value,
          "downloading": false,
          "start": starttime,
          "end": endtime,
          "data": videoData,
          "link": lastVideoLink,
          "savePath":
              "${selectedDirectory.value!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] ${videoData!["livestream"]["channel"]["user"]["username"]}",
        },
      );
    } else {
      queeVideoDownload.add({
        "streamDate":
            (videoData!["livestream"]["created_at"].split(" ")[0] as String)
                .replaceAll("-", "\\"),
        "image": link.value,
        "quality": valueSelected.value,
        "downloading": false,
        "start": 0,
        "end": -1,
        "data": videoData,
        "link": lastVideoLink,
        "savePath":
            "${selectedDirectory.value!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().hour}-${DateTime.now().minute}] ${videoData!["livestream"]["channel"]["user"]["username"]}"
      });
    }

    if (queeVideoDownload[0]["downloading"] == false && downloading == false) {
      downloadVOD();
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
        "$path/[${queeVideoDownload[0]["data"]["livestream"]["created_at"].split(" ")[0]}] - ${videoData!["livestream"]["channel"]["user"]["username"]} ${videoData!["livestream"]["session_title"]}.mp4";
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
    MethodChannelHandler.openDirectory(completedVideos[index]["path"]);
  }

  void showFileInfoDialog(int index, BuildContext context) async {
    var textStyle = const TextStyle(fontFamily: "SpaceGrotesk");
    showModalBottomSheet(
        constraints: const BoxConstraints.expand(),
        elevation: 5,
        barrierColor: const Color.fromARGB(160, 0, 0, 0),
        context: context,
        builder: (context) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    'Streamer:  ${completedVideos[index]["streamer"]}',
                    style: textStyle,
                  ),
                  const Divider(),
                  SelectableText("Title:  ${completedVideos[index]["title"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText(
                      "Stream Date:  ${completedVideos[index]["streamDate"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText(
                      "Download Date:  ${completedVideos[index]["DownloadDate"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText("Path:  ${completedVideos[index]["path"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText("Size:  ${completedVideos[index]["size"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText("Link:  ${completedVideos[index]["link"]}",
                      style: textStyle),
                  const Divider(),
                  SelectableText(
                      "Resolution:  ${completedVideos[index]["resolution"]}fps",
                      style: textStyle)
                ],
              ),
            ));
  }
}
