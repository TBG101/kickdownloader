import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kickdownloader/utilities/hive_logic.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:kickdownloader/utilities/NotificationController.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:kickdownloader/utilities/settingsLogic.dart';
import 'package:kickdownloader/widgets/downloadPage/videoCard.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

  var qualitySelector = Rxn<String>();

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

  late final String appVersion;
  late final String appName;

  final GlobalKey<AnimatedListState> animatedListKey =
      GlobalKey<AnimatedListState>();

  var settingsController = SettingsController().obs;

  void checkNetwork() async {
    await Connectivity().checkConnectivity().then(
      (value) {
        if (value == ConnectivityResult.none) hasInternet = false;
      },
    );
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        hasInternet = false;
      } else {
        hasInternet = true;
      }
    });
  }

  void addVideoToHive() {
    HiveLogic.setStoreCompletedVideos(completedVideos);
  }

  void resetAll() {
    startHour.value.clear();
    startMinute.value.clear();
    startSecond.value.clear();
    endHour.value.clear();
    endMinute.value.clear();
    endSecond.value.clear();
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
    settingsController.value
        .initSettings()
        .then((value) => settingsController.refresh());

    appVersion = (await PackageInfo.fromPlatform()).version;
    appName = (await PackageInfo.fromPlatform()).appName;

    checkNetwork();
    completedVideos.addAll(await HiveLogic.getStoreCompletedVideos);

    _notificationcontroller.startListener();

    queeVideoDownload.listen((p0) {});
    super.onReady();
  }

  (double, String) formatBytes(int bytes) {
    if (bytes <= 0) return (0, "B");
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(bytes) / log(1024)).floor();
    return (((bytes / pow(1024, i))), suffixes[i]);
  }

  void getVodData(BuildContext context) async {
    if (!hasInternet) {
      showToast("No internet Connection", context, 250);
      return;
    }
    if (url.value.text.isEmpty || url.value.text == lastVideoLink) {
      showToast("Link not valid", context, 250);
      return;
    }

    foundVideo.value = false;

    var response = await getURL(context);

    if (response != 200) {
      return; // early reaturn if the response is diffrenet than 200
    }
    lastVideoLink = url.value.text;
    await getVidQuality();
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
    qualitySelector.value = resolutions.first;
    foundVideo.value = true;
  }

  bool validURL() {
    RegExp validLinkPattern =
        RegExp(r'^(kick.com|https://kick.com)/video/[a-zA-Z0-9-]+$');
    return validLinkPattern.hasMatch(url.value.text);
  }

  Future<int> getURL(context) async {
    if (!validURL()) {
      resetAll();
      foundVideo.value = false;
      showToast("URL is not valid", context, 300);
    }

    String id = url.value.text.split('/').last;
    apiURL =
        "https://kick.com/api/v1/video/$id?${DateTime.now().millisecondsSinceEpoch}";
    late Response response;

    try {
      response = await _dio.get(
        apiURL,
      );
    } catch (e) {
      foundVideo.value = false;
      resetAll();
      showToast("Wrong URL", context, 300);
      return 0;
    }

    if (response.statusCode == 200) {
      videoData = json.decode(response.data);
      apiURL = id;
      return 200;
    } else {
      foundVideo.value = false;
      resetAll();
      showToast("Error occured", context, 300);

      // implement exception
      return response.statusCode ?? 0;
    }
  }

  String thumbnailLink() {
    var x = (videoData!["source"] as String).split("\/");
    return "https://images.kick.com/video_thumbnails/${x[6]}/${x[12]}/480.webp";
  }

  Future<void> getVidQuality() async {
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

  Future<bool> checkTSfiles(
      String path, String downloadPath, Function myCallback) async {
    // IMPLEMENT CHECK TS FILES
    File file = File("$path/generated.txt");
    var x = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    for (var element in x) {
      if (myCallback()) {
        return false;
      }

      if (!File("$path/$element").existsSync()) {
        await downloadTS(downloadPath, element, cancel, path);
      }
    }

    return true;
  }

  static void heavyComputeWriteGen(List args) {
    List<String> myPlaylist = args[0];
    var endTime = args[1] as int;
    var startTime = args[2] as int;
    var savepath = args[3] as String;
    var mySendPort = args[4] as SendPort;

    int? overflowTime;
    var nbOfTsFiles = 0;
    var timeMilliseconds = 0;
    var generatedFile = File("$savepath/generated.txt");

    for (int i = 0; i < myPlaylist.length; i++) {
      if (myPlaylist[i].contains("#EXTINF:") == false) {
        continue;
      }
      if (timeMilliseconds >= endTime && endTime != -1) {
        break;
      }
      var line = myPlaylist[i];
      line = line.replaceAll("#EXTINF:", "");
      line = line.replaceAll(",", "");
      if (timeMilliseconds >= startTime ||
          timeMilliseconds + double.parse(line) * 1000 > startTime) {
        overflowTime ??= startTime - timeMilliseconds;
        generatedFile.writeAsStringSync("${myPlaylist[i + 1]}\n",
            mode: FileMode.append);

        print(myPlaylist[i + 1]);
        nbOfTsFiles++;
      }
      timeMilliseconds = timeMilliseconds + (double.parse(line) * 1000).toInt();
    }

    mySendPort.send({
      "nbOfTsFiles": nbOfTsFiles,
      "overflowTime": overflowTime,
      "timeMilliseconds": timeMilliseconds
    });
  }

  Future<(int?, int?)> writeGeneratedText(String savepath,
      List<String> playlist, int endTime, int startTime) async {
    try {
      File("$savepath/generated.txt").createSync(recursive: true);
    } catch (e) {
      throw ("Got error on generating text file $e");
    }

    if (endTime == -1) {
      playlist[playlist.length - 2];
    }

    var receiverPort = ReceivePort();

    var myIsolate = await Isolate.spawn(heavyComputeWriteGen,
        [playlist, endTime, startTime, savepath, receiverPort.sendPort]);
    cancel.whenCancel.asStream().listen((event) {
      myIsolate.kill(priority: Isolate.immediate);
      receiverPort.sendPort.send(null);
    });
    var result = await receiverPort.first as Map<String, int?>?;
    myIsolate.kill();
    receiverPort.close();
    if (result == null) return (null, null);
    // Meaning that we are going to download the whole stream if endtime == -1
    return (
      (endTime == -1 ? -1 : result["overflowTime"]),
      result["nbOfTsFiles"]
    );
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
      return -1;
    }
    return -1;
  }

  Future<String> getDownloadedSize(String path) async {
    try {
      File file = File(path);
      int fileSizeInBytes = await file.length();
      var (size, suffix) = formatBytes(fileSizeInBytes);
      return "${size.toStringAsFixed(2)} $suffix";
    } catch (e) {
      return "Couldn't get file size";
    }
  }

  Future<void> deleteDir(String path) async {
    try {
      await Directory(path).delete(recursive: true);
    } catch (_) {}
  }

  Future<String?> downloadVod(String myPath, List<String> playlist, int endTime,
      int startTime, int tsFileSize, List queeList, String downloadURL) async {
    int? nbOfTsFiles, overflowTime;
    canceledLogic() {
      deleteDir(myPath);
      if (!cancel.isCancelled) {
        cancel.cancel();
      }
    }

    await _notificationcontroller.createDownloadNotifcation(
        notificationId,
        'Started downloading VOD',
        "Streamer ${queeVideoDownload[0]["username"]}");

    try {
      (overflowTime, nbOfTsFiles) =
          await writeGeneratedText(myPath, playlist, endTime, startTime);
    } catch (e) {
      // IMPLEMENT ERROR GENERATING TEXT FILE
      canceledLogic();
      throw "Couldn't write file : $e";
    }
    // Implemetn canceled error
    if (overflowTime == null) {
      canceledLogic();
      return null;
    }

    // Implement error
    if (nbOfTsFiles == null) {
      Get.snackbar("error", "Error occured");
      canceledLogic();
      throw "Number of ts files is null";
    }

    if (cancel.isCancelled) {
      canceledLogic();
      return null;
    }

    videoDownloadSizeBytes.value = (nbOfTsFiles * tsFileSize);

    var (sizeVid, suffix) = formatBytes(videoDownloadSizeBytes.value);
    playlist.clear();

    var file = File("$myPath/generated.txt").readAsLinesSync();

    for (String element in file) {
      if (cancel.isCancelled) {
        canceledLogic();
        return null;
      }
      while (queeList.length >= 5 && downloading) {
        var percentage = videoDownloadPercentage.value;
        videoDownloadPercentage.value =
            (videoDownloadParts / (file.length * 100)) * 100;

        _notificationcontroller.updateNotification(
            notificationId,
            file,
            'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
            "Streamer ${queeVideoDownload[0]["username"]}",
            videoDownloadPercentage.value);

        await waitTimer();
        if (cancel.isCancelled) {
          canceledLogic();
          return null;
        }
      }
      queeList.add(int.parse(element.replaceAll(".ts", "")));

      try {
        downloadTS(downloadURL, element, cancel, myPath).then((tsFile) {
          queeList.remove(int.parse(element.replaceAll(".ts", "")));
        });
      } on DioException catch (e) {
        print("canceled: $e");
        throw "canceled";
      } catch (e) {
        rethrow;
      }
    }

    while (queeList.isNotEmpty) {
      await waitTimer();
      if (cancel.isCancelled) {
        canceledLogic();
        return null;
      }
      var percentage = videoDownloadPercentage.value;
      videoDownloadPercentage.value =
          (videoDownloadParts / (file.length * 100)) * 100;

      _notificationcontroller.updateNotification(
          notificationId,
          file,
          'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
          "Streamer ${queeVideoDownload[0]["username"]}",
          videoDownloadPercentage.value);
    }

    var r = await checkTSfiles(myPath, downloadURL, () {
      if (cancel.isCancelled) {
        canceledLogic();
        return true;
      }
    });
    if (!r) return null;

    await _notificationcontroller.updateNotificationEnd(
        notificationId,
        'Converting to MP4',
        "Streamer ${queeVideoDownload[0]["username"]}",
        true);

    String? path;
    try {
      if (endTime == -1) {
        path = await mergeToMp4(myPath, overflowTime, null);
      } else {
        path = await mergeToMp4(myPath, overflowTime, (endTime - startTime));
      }
    } catch (e) {
      canceledLogic();
      return null;
    }
    if (path == null) {
      // IMPELMENT ERROR IF THE PATH HAS NOT BEEN RETURNED MEANING THAT THE
      canceledLogic();
      return null;
    }

    await _notificationcontroller.updateNotificationEnd(
        notificationId,
        'Download Completed',
        "Streamer ${queeVideoDownload[0]["username"]}",
        false);
    return path;
  }

  Future<void> downloadFirstVODQueeList() async {
    cancel = CancelToken();
    videoDownloadPercentage.value = 0;
    videoDownloadParts = 0;
    notificationId++;
    downloading = true;
    // ignore: no_leading_underscores_for_local_identifiers
    String saveDir = queeVideoDownload[0]["savePath"];
    List<int> queeList = [];
    var slectedQuality = queeVideoDownload[0]["quality"];
    int startTime = queeVideoDownload[0]["start"];
    int endTime = queeVideoDownload[0]["end"];
    var downloadURL = queeVideoDownload[0]["downloadURL"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");
    List<String> playlist = await getPlaylist(downloadURL);

    var tsFileSize = await getFileSize(downloadURL + "0.ts");

    queeVideoDownload[0]["downloading"] = true;

    try {
      await downloadVod(saveDir, playlist, endTime, startTime, tsFileSize,
              queeList, downloadURL)
          .then((path) async {
        if (path != null && downloading && !cancel.isCancelled) {
          DateTime now = DateTime.now();
          String formattedDate = "${now.year}-${(now.month)}-${(now.day)}";
          var fileSize = await getDownloadedSize(path);

          completedVideos.insert(0, {
            "streamDate": queeVideoDownload[0]["streamDate"],
            "streamer": queeVideoDownload[0]["username"],
            "title": queeVideoDownload[0]["title"],
            "path": path,
            "link": queeVideoDownload[0]["link"],
            "image": queeVideoDownload[0]["image"],
            "DownloadDate": formattedDate,
            "resolution": slectedQuality,
            "size": fileSize,
            "hourDate": DateTime.now().toIso8601String()
          });

          completedVideos.refresh();
          if (queeVideoDownload.length != 1) {
            animatedListKey.currentState!.insertItem(queeVideoDownload.length);
          }
          addVideoToHive();
        } else {
          _notificationcontroller.dissmissNotification(notificationId);
        }
      });
    } catch (e) {
      _notificationcontroller.dissmissNotification(notificationId);
      print("OUTER FUNCTION ERROR IS: $e");
      deleteDir(saveDir);
      if (!cancel.isCancelled) {
        cancel.cancel();
      }
    }

    if (queeVideoDownload.isNotEmpty && !cancel.isCancelled) {
      var temp = queeVideoDownload.removeAt(0);
      queeVideoDownload.refresh();
      animatedListKey.currentState!.removeItem(
        0,
        duration: const Duration(milliseconds: 250),
        (context, animation) => SizeTransition(
            axis: Axis.vertical,
            axisAlignment: -1,
            sizeFactor:
                CurvedAnimation(curve: Curves.easeIn, parent: animation),
            child: VideoCard(
              title: "${temp["username"]} - ${temp["title"]}",
              image: temp["image"],
              subtitle: "Completed",
              download: true,
              cancelDownload: () {},
              copyLink: null,
              vodData: null,
              deleteVOD: null,
              openPath: null,
            )
                .animate()
                .fadeOut(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeIn)
                .scaleY(
                    begin: 1,
                    end: 0,
                    alignment: Alignment.topCenter,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn)),
      );
    }
  }

  Future<void> startQueeDownloadVOD() async {
    downloading = true;
    while (queeVideoDownload.isNotEmpty && downloading) {
      await downloadFirstVODQueeList();
    }

    downloading = false;
  }

  int convertToMillisecond(int h, int m, int s) {
    return (h * 60 * 60 + m * 60 + s) * 1000;
  }

  void downloadVodDataBtn(BuildContext context) async {
    if (!hasInternet) {
      // IMPLEMENT NO INTERNET
      showToast("No internet Connection", context, 50);
      return;
    }

    if (!foundVideo.value) return;

    // NOTIFICATION PERMISSION
    // IMPLEMENT NOTIFICATION DISCLAIMER
    await PermissionHandler.notificationFullImplementation();
    // STORAGE PERMISSION
    var value = !await PermissionHandler.storageFullImplementation();

    settingsController.update((val) async {
      val!.storagePermission = value;
      val.notificationEnable =
          await PermissionHandler.getNotificationStatus() ?? false;
    });

    if (value) return;

    if (!await settingsController.value.savePathSelector()) return;
    settingsController.refresh();
    int? starttime;
    int? endtime;
    bool startCondition() =>
        startHour.value.text.isNotEmpty &&
        startMinute.value.text.isNotEmpty &&
        startSecond.value.text.isNotEmpty;

    bool endCondition() =>
        endHour.value.text.isNotEmpty &&
        endMinute.value.text.isNotEmpty &&
        endSecond.value.text.isNotEmpty;

    if (startCondition() && endCondition()) {
      // turn all time to milliseconds
      starttime = convertToMillisecond(int.parse(startHour.value.text),
          int.parse(startMinute.value.text), int.parse(startSecond.value.text));
      endtime = convertToMillisecond(int.parse(endHour.value.text),
          int.parse(endMinute.value.text), int.parse(endSecond.value.text));

      if (starttime >= endtime) {
        //  Impelment error
        return;
      }
    } else if (startCondition()) {
      starttime = convertToMillisecond(int.parse(startHour.value.text),
          int.parse(startMinute.value.text), int.parse(startSecond.value.text));
    } else if (endCondition()) {
      endtime = convertToMillisecond(int.parse(endHour.value.text),
          int.parse(endMinute.value.text), int.parse(endSecond.value.text));
    }
    queeVideoDownload.add(
      {
        "downloading": false,
        "streamDate": (videoData!["livestream"]["created_at"].split(" ")[0]),
        "image": link.value,
        "quality": qualitySelector.value,
        "start": starttime ?? 0,
        "end": endtime ?? -1,
        "data": videoData,
        "link": lastVideoLink,
        "title": videoData!["livestream"]["session_title"],
        "downloadURL": videoData!["source"],
        "username": videoData!["livestream"]["channel"]["user"]["username"],
        "savePath":
            "${settingsController.value.savedDir!}/[${videoData!["livestream"]["created_at"].split(" ")[0]} - ${DateTime.now().hour}h ${DateTime.now().minute}m ${DateTime.now().second}s] ${videoData!["livestream"]["channel"]["user"]["username"]}",
      },
    );

    if (queeVideoDownload[0]["downloading"] == false && downloading == false) {
      startQueeDownloadVOD();
    }
  }

  Future<String?> mergeToMp4(
      String path, int overflowStart, int? overflowEnd) async {
    var directory = Directory(path);

    List<File> tsFiles = directory
        .listSync()
        .where((file) => file.path.endsWith('.ts'))
        .cast<File>()
        .toList();
    tsFiles.sort((a, b) => a.path.compareTo(b.path));
    File outputFile = File('$path/all.ts');

    try {
      RandomAccessFile outputRandomAccessFile =
          outputFile.openSync(mode: FileMode.write);
      for (File tsFile in tsFiles) {
        if (cancel.isCancelled) {
          return null;
        }

        RandomAccessFile inputRandomAccessFile =
            tsFile.openSync(mode: FileMode.read);
        outputRandomAccessFile.writeFromSync(
            inputRandomAccessFile.readSync(inputRandomAccessFile.lengthSync()));
        inputRandomAccessFile.closeSync();
      }
      await outputRandomAccessFile.close();
    } catch (e) {
      throw "Error during concatenation: $e";
    }
    // convert to mp4
    var x = "";
    if (overflowEnd != null) {
      x = "-ss ${formatMilliseconds(overflowStart)} -t ${formatMilliseconds(overflowEnd)}";
    } else {
      x = "-ss ${formatMilliseconds(overflowStart)} ";
    }

    var validFileName = RegExp(r'[\"*\/:<>?\\|]');
    String filename =
        "$path/[${queeVideoDownload[0]["streamDate"]}] - ${queeVideoDownload[0]["username"]} ${(queeVideoDownload[0]["title"] as String).replaceAll(validFileName, '-')}.mp4";

    String ffmpegCommand = '-y -i "$path/all.ts" $x -c copy "$filename"';

    try {
      var complete = Completer<bool>();

      FFmpegKit.executeAsync(
        ffmpegCommand,
        (session) async {
          var returnCode = await session.getReturnCode();
          if (returnCode == null) return;
          if (returnCode.isValueSuccess()) {
            complete.complete(true);
          } else if (returnCode.isValueCancel()) {
            complete.complete(false);
          }
        },
      ); // convert the ts file into mp4

      var stream = cancel.whenCancel.asStream().listen((event) {
        if (event.type == DioExceptionType.cancel) FFmpegKit.cancel();
      });

      var returnValue = await complete.future;
      stream.cancel();

      if (returnValue == false) {
        throw "canceled";
      }
      await deleteTs(tsFiles, path);
      MediaScanner.loadMedia(path: filename);

      return cancel.isCancelled ? null : filename;
    } catch (e) {
      throw "error on converting to mp4 : $e";
    }
  }

  Future downloadTS(String path, String tsFileNB, CancelToken cancel,
      String selectedDirectory) async {
    print(tsFileNB);
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
      saveTS(selectedDirectory, responseBytes.data, tsFileNB);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw "canceled";
      } else {
        throw "error";
      }
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
  }

  Future<List<String>> getPlaylist(String downloadURL) async {
    return (await _dio.get("${downloadURL}playlist.m3u8")).data.split("\n");
  }

  Future<void> deleteTs(List<File> tsFiles, path) async {
    for (var file in tsFiles) {
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (e) {
          // IMLEMENT COULDNT DELETE
        }
      }
    }
    try {
      await File("$path/all.ts").delete();
      await File("$path/generated.txt").delete();
    } catch (e) {
      // IMPLEMENT COULDNT DELETE
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

  void cancelDownload() async {
    cancel.cancel();
    // IMPLEMENT REMOVE QUEE
  }

  Future<void> deleteFileDropdown(int index) async {
    try {
      await Directory(getDir(completedVideos[index]["path"]))
          .delete(recursive: true);
    } catch (e) {}
    completedVideos.removeAt(index);
    completedVideos.refresh();
    addVideoToHive();
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

  String getDir(String path) {
    var x = path.split("/");
    x.removeLast();
    return "${x.join("/")}/";
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
