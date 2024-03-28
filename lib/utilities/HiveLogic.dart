import 'dart:isolate';

import 'package:hive/hive.dart';

class HiveLogic {
  static final __box = Hive.box("video");

  static void setStoreSavePath(String path) {
    __box.put("savePath", path);
  }

  static String? get getSavePath => __box.get("savePath");

  static void setStoreCompletedVideos(List<Map> videos) {
    __box.put("video", videos);
  }

  static Future<List<Map>> getStoreCompletedVideos() async {
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
}
