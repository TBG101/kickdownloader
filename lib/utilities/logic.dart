import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kickdownloader/utilities/ad_state.dart';
import 'package:kickdownloader/utilities/hive_logic.dart';
import 'package:kickdownloader/utilities/MethodChannelHandler.dart';
import 'package:kickdownloader/utilities/NotificationController.dart';
import 'package:kickdownloader/utilities/PermissionHandler.dart';
import 'package:kickdownloader/utilities/settingsLogic.dart';
import 'package:kickdownloader/utilities/static_Functions.dart';
import 'package:kickdownloader/widgets/downloadPage/videoCard.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class Logic extends GetxController {
  AdState adState;
  Logic(Future<InitializationStatus> initialization)
      : adState = AdState(initialization);

  final navigatorKey = GlobalKey<NavigatorState>();

  final NotificationController __notificationcontroller =
      NotificationController();

  final url = TextEditingController().obs;
  String apiURL = "";
  String lastVideoLink = "";
  final RxBool foundVideo = false.obs;
  final downloading = false.obs;
  Map<String, dynamic>? videoData;
  final resolutions = <String>[].obs;

  final RxDouble videoDownloadPercentage = 0.0.obs;
  var videoDownloadParts = 0.0;
  final RxInt videoDownloadSizeBytes = 0.obs;
  final RxBool fetchingData = false.obs;
  final link = "".obs;
  final RxInt pageSelector = 0.obs;
  final RxString streamer = "".obs;
  final RxString title = "".obs;
  final RxString stramDate = "".obs;
  final RxString streamLength = "".obs;
  final RxDouble gradientOpacity = 0.4.obs;
  final RxBool startValue = false.obs;
  final RxBool endValue = false.obs;

  final qualitySelector = Rxn<String>();

  // text controllers
  final startHour = TextEditingController().obs;
  final startMinute = TextEditingController().obs;
  final startSecond = TextEditingController().obs;
  final endHour = TextEditingController().obs;
  final endMinute = TextEditingController().obs;
  final endSecond = TextEditingController().obs;
  final queeVideoDownload = <Map>[].obs;
  int notificationId = 2;
  RxList<Map> completedVideos = <Map>[].obs;
  bool hasInternet = true;

  final _dio = Dio();
  // cancel token for dio()
  late CancelToken cancel;

  late final String appVersion;
  late final String appName;

  final GlobalKey<AnimatedListState> animatedListKey =
      GlobalKey<AnimatedListState>();

  final settingsController = SettingsController().obs;

  Future<void> checkNetwork() async {
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
    foundVideo.value = false;
  }

  void _getIntent() {
    ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      print(value.first.path);
      final stringSplit = value.first.path.split(" ");
      for (final item in stringSplit) {
        if (item.contains("kick.com")) {
          url.value.text = item;
        }
      }
      print(url.value.text);
      getVodData();
      ReceiveSharingIntent.instance.reset();
    });
  }

  void checkCompletedFiles() async {
    if (await PermissionHandler.getStorageStatus() == false ||
        completedVideos.isEmpty) return;

    for (var i = 0; i < completedVideos.length; i++) {
      if (completedVideos[i]["status"] == "notFound") continue;
      final directory = Directory(completedVideos[i]["path"]);
      if (!directory.existsSync()) {
        completedVideos[i]["status"] = "notFound";
        continue;
      }
      final List<FileSystemEntity> entities = directory.listSync();
      var found = false;
      // Iterate over the entities
      for (FileSystemEntity entity in entities) {
        // Check if the entity is a file and has an .mp4 extension
        if (entity is File && entity.path.endsWith('.mp4')) {
          found = true;
          break;
        }
      }
      if (found) {
        continue;
      }
      completedVideos[i]["status"] = "notFound";
    }
    completedVideos.refresh();
    print(completedVideos[0]["status"]);
  }

  @override
  void onReady() async {
    // TODO: implement onReady
    super.onReady();
    _getIntent();
    final myList = await Future.wait([
      PackageInfo.fromPlatform(),
      HiveLogic.getStoreCompletedVideos,
      HiveLogic.getStoreQueeVideos
    ]);

    settingsController.value.initSettings();

    appVersion = (myList[0] as PackageInfo).version;
    appName = (myList[0] as PackageInfo).appName;
    completedVideos.addAll(myList[1] as List<Map<dynamic, dynamic>>);
    queeVideoDownload.addAll(myList[2] as List<Map<dynamic, dynamic>>);
    checkCompletedFiles();
    checkNetwork();
    __notificationcontroller.startListener();
    adState.loadInterAd();
    adState.loadBannerAd();
    adState.loadAppOpenAd();
    print(queeVideoDownload);

    AppLifecycleListener(
      onDetach: () {
        print(("detatcheddd"));
      },
      onInactive: () {
        adState.clickedOnMyAppOpenAd = true;
        print('inactive');
      },
      onPause: () {
        adState.clickedOnMyAppOpenAd = false;
      },
      onResume: () {
        if (adState.clickedOnMyAppOpenAd == false) {
          adState.showAppOpenAd();
        } else {
          adState.clickedOnMyAppOpenAd = false;
        }
      },
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    print("Kikc Vod Downloader exited ");
    __notificationcontroller.removeNotifications();
    HiveLogic.setQueeVideos(queeVideoDownload);
    MethodChannelHandler.stopService();
  }

  Future<void> getVodData() async {
    if (!hasInternet) {
      StaticFunctions.showSnackBar(
          title: "No internet Connection", "Check your internet and try again");

      return;
    }

    if (url.value.text == lastVideoLink || url.value.text.isEmpty) return;

    foundVideo.value = false;

    final response = await getURL();

    if (response != 200) {
      return; // early reaturn if the response is diffrenet than 200
    }
    lastVideoLink = url.value.text;
    await getVidQuality();
    final duration = Duration(
        hours: 0,
        seconds: 0,
        minutes: 0,
        milliseconds: videoData!["livestream"]["duration"] as int);

    streamer.value = videoData!["livestream"]["channel"]["slug"];
    title.value = videoData!["livestream"]["session_title"];
    stramDate.value = videoData!["livestream"]["created_at"].split(" ")[0];
    streamLength.value = duration.toString().split('.')[0];

    link.value = StaticFunctions.thumbnailLink(videoData!["source"] as String);
    qualitySelector.value = resolutions.first;
    foundVideo.value = true;
  }

  Future<int> getURL() async {
    if (!StaticFunctions.validURL(url.value.text)) {
      resetAll();
      foundVideo.value = false;
      StaticFunctions.showSnackBar(
          title: "Couldn't fecth data", "Link is not valid");
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
      StaticFunctions.showSnackBar(
          title: "Couldn't fecth data", "Link is not valid");
      return 0;
    }

    if (response.statusCode == 200) {
      videoData = json.decode(response.data);
      apiURL = id;
      return 200;
    } else {
      foundVideo.value = false;
      resetAll();
      StaticFunctions.showSnackBar(
          title: "Couldn't fecth data", "Link is not valid");

      return response.statusCode ?? 0;
    }
  }

  Future<void> getVidQuality() async {
    final response = await _dio.get(
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
    final generatedFile = await file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();
    for (var element in generatedFile) {
      if (myCallback()) {
        return false;
      }
      try {
        if (!File("$path/$element").existsSync()) {
          await downloadTS(downloadPath, element, cancel, path);
        }
      } on DioExceptionType {
        // IMPLEMENT THIS
        break;
      } catch (e) {
        break;
      }
    }

    return true;
  }

  static void heavyComputeWriteGen(List args) {
    List<String> myPlaylist = args[0];
    final endTime = args[1] as int;
    final startTime = args[2] as int;
    final savepath = args[3] as String;
    final mySendPort = args[4] as SendPort;

    int? overflowTime;
    var nbOfTsFiles = 0;
    var timeMilliseconds = 0;
    final generatedFile = File("$savepath/generated.txt");
    late String line;
    for (int i = 0; i < myPlaylist.length; i++) {
      if (myPlaylist[i].contains("#EXTINF:") == false) {
        continue;
      }
      if (timeMilliseconds >= endTime && endTime != -1) {
        break;
      }
      line = myPlaylist[i];
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

    final receiverPort = ReceivePort();

    final myIsolate = await Isolate.spawn(heavyComputeWriteGen,
        [playlist, endTime, startTime, savepath, receiverPort.sendPort]);
    final mystream = cancel.whenCancel.asStream().listen((event) {
      myIsolate.kill(priority: Isolate.immediate);
      receiverPort.sendPort.send(null);
    });

    final result = await receiverPort.first as Map<String, int?>?;
    myIsolate.kill();
    receiverPort.close();
    mystream.cancel();
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
      final (size, suffix) = StaticFunctions.formatBytes(fileSizeInBytes);
      return "${size.toStringAsFixed(2)} $suffix";
    } catch (e) {
      return "Couldn't get file size";
    }
  }

  Future<List> getDownloadedSizeAndFiles(
      String path, List<String> downloadedList) async {
    final receivePort = ReceivePort();

    Isolate.spawn((message) async {
      final mySendPort = message[0] as SendPort;
      final myStreamDir = Directory(message[1] as String);
      final downloadedTs = message[2] as List<String>;
      if (myStreamDir.existsSync() == false) {
        mySendPort.send([0.0, <String>[]]);
        return;
      }
      double maxNb = 0;
      for (final ts in downloadedTs) {
        final file = File("$path/$ts");
        if (file.existsSync()) {
          final myCurrentNb =
              double.tryParse(ts.substring(0, ts.length - 3)) ?? 0;
          if (myCurrentNb > maxNb) {
            maxNb = myCurrentNb;
          }
        }
      }

      mySendPort.send([maxNb, downloadedTs]);
    }, [receivePort.sendPort, path, downloadedList]);
    final result = (await receivePort.first) as List;
    print(result);
    return [result[0], result[1]];
  }

  Future<String?> downloadVod(
      String myPath,
      List<String> playlist,
      int endTime,
      int startTime,
      int tsFileSize,
      String downloadURL,
      bool notificationEnabled) async {
    var lastNotificationUpdateTime = DateTime.now();
    late final int? nbOfTsFiles, overflowTime;
    // double percentage;
    videoDownloadParts = 0;
    Future<void> canceledLogic() async {
      if (!cancel.isCancelled) {
        cancel.cancel();
      }
      StaticFunctions.deleteDir(myPath);
    }

    final List<String> downloadedList =
        (queeVideoDownload[0]["downloadedList"] as List<String>?) ?? [];

    if (queeVideoDownload[0]["downloadedList"] == null) {
      queeVideoDownload[0]["downloadedList"] = <String>[];
    }

    final Set<int> queeList = {};
    if (notificationEnabled) {
      await __notificationcontroller.createDownloadNotifcation(
          notificationId,
          'Started downloading VOD',
          "Streamer ${queeVideoDownload[0]["username"]}");
    }
    await getDownloadedSizeAndFiles(myPath, downloadedList).then((value) {
      print("in value $value");
      // all downloadedParts in Mb (i think lol)
      videoDownloadParts = value[0] as double;
      print(videoDownloadParts);

      // the downloaded  playlist
      downloadedList.addAll(value[1] as List<String>);
    });

    try {
      if (videoDownloadParts == 0) {
        (overflowTime, nbOfTsFiles) =
            await writeGeneratedText(myPath, playlist, endTime, startTime);
        queeVideoDownload[0]["nbOfTsFiles"] = nbOfTsFiles;
        queeVideoDownload[0]["overflowTime"] = overflowTime;
      } else {
        nbOfTsFiles = queeVideoDownload[0]["nbOfTsFiles"];
        overflowTime = queeVideoDownload[0]["overflowTime"];
      }
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

    if (nbOfTsFiles == null) {
      StaticFunctions.showSnackBar(
          title: "Unhandled Exception", "error occured: number of ts is Null");
      canceledLogic();
      throw "Number of ts files is null";
    }

    if (cancel.isCancelled) {
      canceledLogic();
      return null;
    }

    videoDownloadSizeBytes.value = (nbOfTsFiles * tsFileSize);

    final (sizeVid, suffix) =
        StaticFunctions.formatBytes(videoDownloadSizeBytes.value);
    playlist.clear();

    final file = File("$myPath/generated.txt").readAsLinesSync();

    // GET the last downloaded parts if it has downloaded before else don't

    print(downloadedList);

    // LOOP ALL TS FILES
    for (final element in file) {
      // check if has been canceled
      if (downloading.isFalse) {
        return "paused";
      }
      if (cancel.isCancelled) {
        canceledLogic();
        return null;
      }
      if (downloadedList.contains(element)) {
        continue;
      }

      while (queeList.length > 3 && downloading.value && hasInternet) {
        final percentage = videoDownloadPercentage.value;
        videoDownloadPercentage.value =
            (videoDownloadParts / (file.length)) * 100;

        if (notificationEnabled && hasInternet) {
          final timeNow = DateTime.now();
          if (timeNow.isAfter(
              lastNotificationUpdateTime.add(const Duration(seconds: 1)))) {
            __notificationcontroller.updateNotification(
                notificationId,
                file,
                'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
                "Streamer ${queeVideoDownload[0]["username"]}",
                videoDownloadPercentage.value);
            lastNotificationUpdateTime = timeNow;
          }
        }

        await StaticFunctions.waitTimer();
        if (cancel.isCancelled) {
          canceledLogic();
          return null;
        }
      }

      final tsFileNb = int.parse(element.replaceAll(".ts", ""));
      queeList.add(tsFileNb);
      try {
        if (hasInternet == true) {
          downloadTS(downloadURL, element, cancel, myPath).then((tsFile) {
            queeList.remove(tsFileNb);
            queeVideoDownload[0]["downloadedList"] = [
              ...(queeVideoDownload[0]["downloadedList"] as List<String>),
              element
            ];
          });
        } else {
          throw "no internet";
        }
      } on DioException catch (e) {
        print("canceled: $e");
        if (DioExceptionType.cancel == e.type) {
          return null;
        } else {
          rethrow;
        }
      } catch (e) {
        rethrow;
      }
    }

    while (queeList.isNotEmpty) {
      await StaticFunctions.waitTimer();
      if (cancel.isCancelled) {
        canceledLogic();
        return null;
      }
      final percentage = videoDownloadPercentage.value;
      videoDownloadPercentage.value =
          (videoDownloadParts / (file.length)) * 100;

      if (notificationEnabled) {
        __notificationcontroller.updateNotification(
            notificationId,
            file,
            'Downloading ${percentage.toStringAsFixed(0)}% ${(sizeVid * percentage / 100).toStringAsFixed(2)}/${sizeVid.toStringAsFixed(2)} $suffix',
            "Streamer ${queeVideoDownload[0]["username"]}",
            videoDownloadPercentage.value);
      }
    }

    final r = await checkTSfiles(myPath, downloadURL, () {
      if (cancel.isCancelled) {
        canceledLogic();
        return true;
      }
      return false;
    });

    if (!r) return null;
    if (notificationEnabled) {
      await __notificationcontroller.updateNotificationEnd(
          notificationId,
          'Converting to MP4',
          "Streamer ${queeVideoDownload[0]["username"]}",
          true);
    }

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
    if (notificationEnabled) {
      settingsController.value.notificationComplete
          ? await __notificationcontroller.updateNotificationEnd(
              notificationId,
              'Download Completed',
              "Streamer ${queeVideoDownload[0]["username"]}",
              false)
          : __notificationcontroller.dissmissNotification(notificationId);
    }
    return path;
  }

  Future<void> downloadFirstVODQueeList() async {
    settingsController.refresh();
    cancel = CancelToken();
    videoDownloadPercentage.value = 0;
    videoDownloadParts = 0;
    notificationId++;
    downloading.value = true;
    final String saveDir = queeVideoDownload[0]["savePath"];
    final slectedQuality = queeVideoDownload[0]["quality"];
    final int startTime = queeVideoDownload[0]["start"];
    final int endTime = queeVideoDownload[0]["end"];
    final String downloadURL = queeVideoDownload[0]["downloadURL"]
        .replaceAll(RegExp(r'master\.[^/]*$'), "$slectedQuality/");
    final List<String> playlist = await getPlaylist(downloadURL);
    final tsFileSize = await getFileSize("${downloadURL}0.ts");
    queeVideoDownload[0]["downloading"] = true;

    try {
      final path = await downloadVod(saveDir, playlist, endTime, startTime,
          tsFileSize, downloadURL, settingsController.value.notificationEnable);
      if (path == "paused") {
        HiveLogic.setQueeVideos(queeVideoDownload);
        return;
      } else if (path != null && downloading.value && !cancel.isCancelled) {
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
        HiveLogic.setStoreCompletedVideos(completedVideos);
      } else {
        if (settingsController.value.notificationFailure) {
          __notificationcontroller.failedDownloadNotification(
              notificationId, "Failed to download", "Download canceled");
        }
      }
    } on DioException catch (e) {
      if (DioExceptionType.connectionError == e.type) {
        __notificationcontroller.failedDownloadNotification(
            notificationId, "Failed to download", "Internet Error");
        if (!cancel.isCancelled) {
          cancel.cancel();
        }
        return;
      }
    } catch (e) {
      print(e);
      if (e == "no internet") {
        downloading.value = false;
        __notificationcontroller.failedDownloadNotification(
            notificationId, "Failed to download", "Internet Error");
        if (!cancel.isCancelled) {
          cancel.cancel();
        }
        return;
      } else {
        __notificationcontroller.failedDownloadNotification(
            notificationId, "Failed to download", "Unhandled exception");
        print("OUTER FUNCTION ERROR IS: $e");
        StaticFunctions.deleteDir(saveDir);
        if (!cancel.isCancelled) {
          cancel.cancel();
        }
        rethrow;
      }
    }

    if (queeVideoDownload.isNotEmpty && !cancel.isCancelled) {
      final temp = queeVideoDownload.removeAt(0);
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
    MethodChannelHandler.startService();
    downloading.value = true;
    final timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      HiveLogic.setQueeVideos(queeVideoDownload);
    });
    while (queeVideoDownload.isNotEmpty && downloading.value && hasInternet) {
      try {
        await downloadFirstVODQueeList();
      } catch (e) {
        downloading.value = false;
        break;
      }

      HiveLogic.setQueeVideos(queeVideoDownload);
    }
    timer.cancel();
    MethodChannelHandler.stopService();
    downloading.value = false;
  }

  void downloadVodDataBtn() async {
    if (!hasInternet) {
      // IMPLEMENT NO INTERNET
      StaticFunctions.showSnackBar(
          title: "No internet Connection", "Check your internet and try again");
      return;
    }

    if (!foundVideo.value) return;
    adState.showInterAd();

    // NOTIFICATION PERMISSION
    // IMPLEMENT NOTIFICATION DISCLAIMER
    await PermissionHandler.notificationFullImplementation();
    // STORAGE PERMISSION
    final value = !await PermissionHandler.storageFullImplementation();

    settingsController.update((val) async {
      val!.storagePermission = value;
      val.notificationPermission =
          await PermissionHandler.getNotificationStatus() ?? false;
    });

    if (!value) return;

    if (!await settingsController.value.savePathSelector(
        selectNew: settingsController.value.askDownloadAlways)) {
      // Implement error downloading
      return;
    }
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
      starttime = StaticFunctions.convertToMillisecond(
          int.parse(startHour.value.text),
          int.parse(startMinute.value.text),
          int.parse(startSecond.value.text));
      endtime = StaticFunctions.convertToMillisecond(
          int.parse(endHour.value.text),
          int.parse(endMinute.value.text),
          int.parse(endSecond.value.text));

      if (starttime >= endtime) {
        //  Impelment error
        return;
      }
    } else if (startCondition()) {
      starttime = StaticFunctions.convertToMillisecond(
          int.parse(startHour.value.text),
          int.parse(startMinute.value.text),
          int.parse(startSecond.value.text));
    } else if (endCondition()) {
      endtime = StaticFunctions.convertToMillisecond(
          int.parse(endHour.value.text),
          int.parse(endMinute.value.text),
          int.parse(endSecond.value.text));
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
        "downloadedTS": []
      },
    );
    HiveLogic.setQueeVideos(queeVideoDownload);
    if (queeVideoDownload[0]["downloading"] == false &&
        downloading.value == false) {
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
          final returnCode = await session.getReturnCode();
          if (returnCode == null) return;
          if (returnCode.isValueSuccess()) {
            complete.complete(true);
          } else if (returnCode.isValueCancel()) {
            complete.complete(false);
          }
        },
      ); // convert the ts file into mp4

      final stream = cancel.whenCancel.asStream().listen((event) {
        if (event.type == DioExceptionType.cancel) FFmpegKit.cancel();
      });

      final returnValue = await complete.future;
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

  Future<String> downloadTS(String path, String tsFileNB, CancelToken cancel,
      String selectedDirectory) async {
    print(tsFileNB);
    try {
      int lastCount = 0;
      await _dio.download(
        path + tsFileNB,
        "$selectedDirectory/$tsFileNB",
        onReceiveProgress: (count, total) {
          videoDownloadParts += ((count - lastCount) / total);
          lastCount = count;
        },
        cancelToken: cancel,
        options: Options(
          // responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );
      // saveTS(selectedDirectory, responseBytes.data, tsFileNB);
      return tsFileNB;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw "canceled";
      } else {
        rethrow;
      }
    }
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

  String formatMilliseconds(int milliseconds) {
    // Calculate hours, minutes, seconds, and remaining milliseconds
    final int hours = (milliseconds ~/ (1000 * 60 * 60)) % 24;
    final int minutes = (milliseconds ~/ (1000 * 60)) % 60;
    final int seconds = (milliseconds ~/ 1000) % 60;
    final int remainingMilliseconds = milliseconds % 1000;

    // Format the result as "HOURS:MM:SS.MILLISECONDS"
    final String formattedTime = '$hours:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${remainingMilliseconds.toString().padLeft(3, '0')}';

    return formattedTime;
  }

  void cancelDownload() async {
    if (downloading.value == true) cancel.cancel();
    // IMPLEMENT REMOVE QUEE
  }

  Future<void> deleteFileDropdown(int index) async {
    try {
      await Directory(StaticFunctions.getDir(completedVideos[index]["path"]))
          .delete(recursive: true);
    } catch (e) {}
    completedVideos.removeAt(index);
    completedVideos.refresh();
    HiveLogic.setStoreCompletedVideos(completedVideos);
  }

  void copyLinkToClipboard(int index, BuildContext context,
      {bool compltedVideo = true}) {
    if (compltedVideo) {
      Clipboard.setData(
          ClipboardData(text: completedVideos[index]["link"] as String));
    } else {
      Clipboard.setData(
          ClipboardData(text: queeVideoDownload[index]["link"] as String));
    }

    // Coppied url here
    StaticFunctions.showSnackBar("Coppied Url");
  }

  void openDir(int index) {
    MethodChannelHandler.openDirectory(completedVideos[index]["path"]);
  }

  void showFileInfoDialog(int index, BuildContext context) async {
    const textStyle = TextStyle(fontFamily: "SpaceGrotesk");
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
