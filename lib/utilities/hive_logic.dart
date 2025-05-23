import 'dart:isolate';
import 'package:hive/hive.dart';

class HiveLogic {
  static final __box = Hive.box("video");

  // Notification Enable
  static void setStoreNotificationEnable(bool value) {
    __box.put("notificationEnable", value);
  }

  static bool get getStoreNotificationEnable =>
      __box.get("notificationEnable", defaultValue: false);

  // Notification complete
  static void setStoreNotificationComplete(bool value) {
    __box.put("notificationComplete", value);
  }

  static bool get getStoreNotificationComplete =>
      __box.get("notificationComplete", defaultValue: false);

  // Notification failure
  static void setStoreNotificationFailure(bool value) {
    __box.put("notificationFailure", value);
  }

// Set notification Failute Notify
  static bool get getStoreNotificationFailure =>
      __box.get("notificationFailure", defaultValue: false);

  // AskDownloadAlways
  static void setStoreAskDownloadAlways(bool value) {
    __box.put("askDownloadAlways", value);
  }

  static bool get getStoreAskDownloadAlways =>
      __box.get("askDownloadAlways", defaultValue: false);

  // Set Save path
  static void setStoreSavePath(String path) {
    __box.put("savePath", path);
  }

  // getSavePath
  static String? get getSavePath => __box.get("savePath");

  // setStoreCompletedVideos
  static void setStoreCompletedVideos(List<Map> videos) {
    __box.put("video", videos);
  }

  // Get all Stored Completed videos
  static Future<List<Map>> get getStoreCompletedVideos async {
    var videos = __box.get("video", defaultValue: <Map<dynamic, dynamic>>[]);
    var video = await Isolate.run(() {
      videos = (videos as List).map((e) => e as Map).toList();
      videos.sort((b, a) {
        return (DateTime.parse(a["hourDate"]))
            .compareTo(DateTime.parse(b["hourDate"]));
      });
      return videos as List<Map>;
    });
    return video;
  }

  // Set Queevideos
  static void setQueeVideos(List<Map> videos) {
    __box.put("queeVideo", videos);
  }

  // Get all queed videos
  static Future<List<Map>> get getStoreQueeVideos async {
    var videos =
        __box.get("queeVideo", defaultValue: <Map<dynamic, dynamic>>[]);

    var video = await Isolate.run(() {
      videos = (videos as List).map((e) => e as Map).toList();
      videos.sort((b, a) {
        return (DateTime.parse(a["hourDate"]))
            .compareTo(DateTime.parse(b["hourDate"]));
      });
      return videos as List<Map>;
    });
    return video;
  }
}
